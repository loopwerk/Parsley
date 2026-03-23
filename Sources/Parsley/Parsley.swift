import cmark_gfm
import Foundation

private extension CharacterSet {
  static let attributeNameChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
  static let idChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_:."))
}

public enum MarkdownError: Error {
  case conversionFailed
}

public enum Parsley {
  /// This parses a String into HTML, without parsing Metadata or the document title.
  public static func html(
    _ content: String,
    options: MarkdownOptions = [],
    syntaxExtensions: [SyntaxExtension] = SyntaxExtension.defaultExtensions
  ) throws -> String {
    let enableAttributes = options.contains(.markdownAttributes)
    let cmarkOptions = options.subtracting(.markdownAttributes)

    // Create parser
    guard let parser = cmark_parser_new(cmarkOptions.rawValue) else {
      throw MarkdownError.conversionFailed
    }

    // Register syntax extensions
    for syntaxExtension in syntaxExtensions {
      if let ext = syntaxExtension.createPointer() {
        cmark_parser_attach_syntax_extension(parser, ext)
      }
    }

    // Normalize old code fence title syntax: ```lang title="foo" → ```lang {data-title="foo"}
    var processedContent = normalizeCodeFenceTitles(content)

    // Pre-process markdown: strip attributes and record them
    let attributeStore: AttributeStore
    (processedContent, attributeStore) = preprocessAttributes(processedContent, includeBlockAttributes: enableAttributes)

    // Parse into an ast
    processedContent.withCString {
      let stringLength = Int(strlen($0))
      cmark_parser_feed(parser, $0, stringLength)
    }

    guard let ast = cmark_parser_finish(parser) else {
      throw MarkdownError.conversionFailed
    }

    // Render the ast into an html string
    guard let htmlCString = cmark_render_html(&ast.pointee, cmarkOptions.rawValue, cmark_parser_get_syntax_extensions(parser)) else {
      throw MarkdownError.conversionFailed
    }

    // Free memory
    cmark_parser_free(parser)
    cmark_node_free(ast)

    defer {
      free(htmlCString)
    }

    // Convert resulting c string to a Swift string
    guard let html = String(cString: htmlCString, encoding: String.Encoding.utf8) else {
      throw MarkdownError.conversionFailed
    }

    // Post-process HTML: apply recorded attributes to elements
    return applyAttributes(attributeStore, html)
  }

  /// This parses a String into a Document, which contains parsed Metadata and the document title.
  public static func parse(
    _ content: String,
    options: MarkdownOptions = [.safe],
    syntaxExtensions: [SyntaxExtension] = SyntaxExtension.defaultExtensions
  ) throws -> Document {
    let (header, title, rawBody) = Parsley.parts(from: content)

    let metadata = Parsley.metadata(from: header)
    let bodyHtml = try Parsley.html(
      rawBody,
      options: options,
      syntaxExtensions: syntaxExtensions
    ).trimmingCharacters(in: .newlines)

    return Document(title: title, rawBody: rawBody, body: bodyHtml, metadata: metadata)
  }
}

private extension Parsley {
  enum AttributeTarget {
    case codeFence(Int)    // absolute index among all code fences
    case heading(Int, Int) // (level, absolute index among headings of that level)
    case block(Int)        // absolute index among all block-level elements
  }

  struct AttributeStore {
    var entries: [(target: AttributeTarget, attrs: String)] = []
  }

  /// Parses attribute content like `.foo .bar #baz key="value"` into an HTML attribute string.
  static func parseAttributes(_ input: String) -> String {
    var classes: [String] = []
    var parts: [String] = []

    let scanner = Scanner(string: input)
    scanner.charactersToBeSkipped = .whitespaces

    while !scanner.isAtEnd {
      if scanner.scanString(".") != nil {
        if let name = scanner.scanCharacters(from: .attributeNameChars) {
          classes.append(name)
        }
      } else if scanner.scanString("#") != nil {
        if let name = scanner.scanCharacters(from: .idChars) {
          parts.append("id=\"\(name)\"")
        }
      } else if let key = scanner.scanCharacters(from: .attributeNameChars) {
        if scanner.scanString("=") != nil {
          if scanner.scanString("\"") != nil {
            let value = scanQuotedValue(scanner)
            if key == "class" {
              classes.append(contentsOf: value.split(separator: " ").map(String.init))
            } else {
              let escaped = value.replacingOccurrences(of: "\"", with: "&quot;")
              parts.append("\(key)=\"\(escaped)\"")
            }
          } else if let value = scanner.scanCharacters(from: .attributeNameChars) {
            if key == "class" {
              classes.append(value)
            } else {
              parts.append("\(key)=\"\(value)\"")
            }
          }
        }
      } else {
        // Skip unknown character
        scanner.currentIndex = scanner.string.index(after: scanner.currentIndex)
      }
    }

    var result: [String] = []
    if !classes.isEmpty {
      result.append("class=\"\(classes.joined(separator: " "))\"")
    }
    result.append(contentsOf: parts)
    return result.joined(separator: " ")
  }

  /// Scans a quoted value, handling escaped quotes (`\"`).
  static func scanQuotedValue(_ scanner: Scanner) -> String {
    var value = ""
    while !scanner.isAtEnd {
      if let chunk = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "\"\\")) {
        value += chunk
      }
      if scanner.scanString("\\") != nil {
        // Escaped character — take the next character literally
        if !scanner.isAtEnd {
          let next = scanner.string[scanner.currentIndex]
          value.append(next)
          scanner.currentIndex = scanner.string.index(after: scanner.currentIndex)
        }
      } else {
        // Hit a quote — consume it and stop
        _ = scanner.scanString("\"")
        break
      }
    }
    return value
  }

  /// Normalizes old `title="..."` syntax on code fences to `{data-title="..."}`.
  static func normalizeCodeFenceTitles(_ markdown: String) -> String {
    let pattern = #"```(\S+)\h+title="([^"]+)""#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return markdown }
    return regex.stringByReplacingMatches(
      in: markdown,
      range: NSRange(markdown.startIndex..., in: markdown),
      withTemplate: "```$1 {data-title=\"$2\"}"
    )
  }

  // Regex patterns used during preprocessing
  static let codeFenceAttrPattern = try! NSRegularExpression(pattern: #"^```(\S+)\h+\{([^}]+)\}$"#)
  static let codeFencePattern = try! NSRegularExpression(pattern: #"^```"#)
  static let headingAttrPattern = try! NSRegularExpression(pattern: #"^(>?\s*)(#{1,6})\s+(.+?)\s+\{([^}]+)\}\s*$"#)
  static let headingPattern = try! NSRegularExpression(pattern: #"^>?\s*(#{1,6})\s+"#)
  static let rawHtmlHeadingPattern = try! NSRegularExpression(pattern: #"^>?\s*<h([1-6])[\s>]"#)
  static let blockAttrPattern = try! NSRegularExpression(pattern: #"^\{([^}]+)\}\s*$"#)

  /// Single-pass preprocessor: walks markdown line by line, strips `{...}` attributes,
  /// and records what they apply to. Code fence attributes are always processed.
  /// Heading and block attributes are only processed when `includeBlockAttributes` is true.
  static func preprocessAttributes(_ markdown: String, includeBlockAttributes: Bool) -> (String, AttributeStore) {
    var store = AttributeStore()
    var lines = markdown.components(separatedBy: "\n")
    var inCodeFence = false
    var codeFenceCount = 0
    var headingCounts: [Int: Int] = [:]
    var blockCount = 0
    var inBlock = false
    var indicesToRemove: [Int] = []

    for (i, line) in lines.enumerated() {
      let nsLine = line as NSString
      let range = NSRange(location: 0, length: nsLine.length)

      // Code fence opening/closing
      if codeFencePattern.firstMatch(in: line, range: range) != nil {
        if !inCodeFence {
          if let match = codeFenceAttrPattern.firstMatch(in: line, range: range) {
            let lang = nsLine.substring(with: match.range(at: 1))
            let attrsContent = nsLine.substring(with: match.range(at: 2))
            store.entries.append((target: .codeFence(codeFenceCount), attrs: parseAttributes(attrsContent)))
            lines[i] = "```\(lang)"
          }
          codeFenceCount += 1
          blockCount += 1
          inBlock = false
        }
        inCodeFence = !inCodeFence
        continue
      }

      if inCodeFence { continue }

      if includeBlockAttributes {
        // Heading with attributes: ## Title {.foo} (optionally inside > blockquote)
        if let match = headingAttrPattern.firstMatch(in: line, range: range) {
          let prefix = nsLine.substring(with: match.range(at: 1))
          let hashes = nsLine.substring(with: match.range(at: 2))
          let level = hashes.count
          let title = nsLine.substring(with: match.range(at: 3))
          let attrsContent = nsLine.substring(with: match.range(at: 4))
          let index = headingCounts[level, default: 0]
          store.entries.append((target: .heading(level, index), attrs: parseAttributes(attrsContent)))
          headingCounts[level] = index + 1
          lines[i] = "\(prefix)\(hashes) \(title)"
          if !inBlock { blockCount += 1 }
          inBlock = false
          continue
        }

        // Heading without attributes (still need to count it)
        if headingPattern.firstMatch(in: line, range: range) != nil {
          let stripped = line.drop(while: { $0 == ">" || $0 == " " })
          let level = stripped.prefix(while: { $0 == "#" }).count
          headingCounts[level] = headingCounts[level, default: 0] + 1
          if !inBlock { blockCount += 1 }
          inBlock = false
          continue
        }

        // Raw HTML heading (count it so indices stay correct)
        if let match = rawHtmlHeadingPattern.firstMatch(in: line, range: range) {
          let level = Int(nsLine.substring(with: match.range(at: 1)))!
          headingCounts[level] = headingCounts[level, default: 0] + 1
          if !inBlock { blockCount += 1 }
          inBlock = false
          continue
        }

        // Block attribute: {.foo} on its own line
        if let match = blockAttrPattern.firstMatch(in: line, range: range) {
          let attrsContent = nsLine.substring(with: match.range(at: 1))
          store.entries.append((target: .block(blockCount - 1), attrs: parseAttributes(attrsContent)))
          indicesToRemove.append(i)
          inBlock = false
          continue
        }

        // Track block elements for block attribute indexing
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
          inBlock = false
        } else if !inBlock {
          blockCount += 1
          inBlock = true
        }
      }
    }

    for i in indicesToRemove.reversed() {
      lines.remove(at: i)
    }

    return (lines.joined(separator: "\n"), store)
  }

  /// Applies recorded attributes to HTML elements.
  static func applyAttributes(_ store: AttributeStore, _ html: String) -> String {
    var result = html

    for entry in store.entries {
      switch entry.target {
      case .codeFence(let index):
        result = applyNthAttribute(result, tag: "pre", n: index, attrs: entry.attrs)

      case .heading(let level, let index):
        result = applyNthAttribute(result, tag: "h\(level)", n: index, attrs: entry.attrs)

      case .block(let index):
        result = applyNthBlockAttribute(result, n: index, attrs: entry.attrs)
      }
    }
    return result
  }

  /// Adds attributes to the Nth occurrence of a tag in HTML.
  static func applyNthAttribute(_ html: String, tag: String, n: Int, attrs: String) -> String {
    let pattern = "<\(tag)([ >])"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return html }
    let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
    guard n < matches.count else { return html }
    let match = matches[n]
    let range = Range(match.range, in: html)!
    let suffix = String(html[Range(match.range(at: 1), in: html)!])
    return html.replacingCharacters(in: range, with: "<\(tag) \(attrs)\(suffix)")
  }

  /// Applies attributes to the Nth block-level element in HTML.
  /// For `<p>` tags containing only a standalone `<img>`, attributes are applied to the `<img>` instead.
  static func applyNthBlockAttribute(_ html: String, n: Int, attrs: String) -> String {
    let blockPattern = #"<(p|blockquote|ul|ol|table|hr)([ >])"#
    guard let regex = try? NSRegularExpression(pattern: blockPattern) else { return html }
    let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
    guard n >= 0, n < matches.count else { return html }
    let match = matches[n]
    let tag = String(html[Range(match.range(at: 1), in: html)!])

    // Check if this is a <p> containing only a standalone <img>
    if tag == "p" {
      let standaloneImgPattern = #"<p>(<img [^>]+/>)</p>"#
      if let imgRegex = try? NSRegularExpression(pattern: standaloneImgPattern) {
        let searchStart = Range(match.range, in: html)!.lowerBound
        let searchRange = NSRange(searchStart..., in: html)
        if let imgMatch = imgRegex.firstMatch(in: html, range: searchRange),
           imgMatch.range.location == match.range.location {
          let imgTag = (html as NSString).substring(with: imgMatch.range(at: 1))
          let newImg = imgTag.replacingOccurrences(of: " />", with: " \(attrs) />")
          let fullRange = Range(imgMatch.range, in: html)!
          return html.replacingCharacters(in: fullRange, with: "<p>\(newImg)</p>")
        }
      }
    }

    let range = Range(match.range, in: html)!
    let suffix = String(html[Range(match.range(at: 2), in: html)!])
    return html.replacingCharacters(in: range, with: "<\(tag) \(attrs)\(suffix)")
  }

  /// Turns a string like `author: Kevin\ntags: Swift` into a dictionary:
  /// ["author": "Kevin", "tags": "Swift"]
  static func metadata(from content: String?) -> [String: String] {
    guard let content = content else {
      return [:]
    }

    let pairs = content
      .split(separator: "\n")
      .map { lines in
        lines
          .split(separator: ":", maxSplits: 1)
          .map {
            $0.trimmingCharacters(in: .whitespaces)
          }
      }
      .filter {
        $0.count == 2
      }
      .map {
        ($0[0], $0[1])
      }

    return Dictionary(pairs) { a, _ in a }
  }

  /// Grabs the metadata (wrapped within `---`), the first title, and the body of the document.
  static func parts(from content: String) -> (String?, String?, String) {
    let scanner = Scanner(string: content)

    var header: String? = nil
    var title: String? = nil

    if scanner.scanString("---") == "---" {
      header = scanner.scanUpToString("---")
      _ = scanner.scanString("---")
    }

    if scanner.scanString("# ") == "# " {
      title = scanner.scanUpToString("\n")
    }

    let body = String(scanner.string[scanner.currentIndex...])

    return (header, title, body)
  }
}
