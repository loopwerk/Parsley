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
    options: MarkdownOptions = [.safe],
    syntaxExtensions: [SyntaxExtension] = SyntaxExtension.defaultExtensions
  ) throws -> String {
    // Create parser
    guard let parser = cmark_parser_new(options.rawValue) else {
      throw MarkdownError.conversionFailed
    }

    // Register syntax extensions
    for syntaxExtension in syntaxExtensions {
      if let ext = syntaxExtension.createPointer() {
        cmark_parser_attach_syntax_extension(parser, ext)
      }
    }

    // Normalize old code fence title syntax to attribute syntax
    var processedContent = normalizeCodeFenceTitles(content)

    // Pre-process markdown: strip attributes and record them
    var attributeStore = AttributeStore()
    processedContent = preprocessCodeFenceAttributes(&attributeStore, processedContent)
    processedContent = preprocessHeadingAttributes(&attributeStore, processedContent)
    processedContent = preprocessBlockAttributes(&attributeStore, processedContent)

    // Parse into an ast
    processedContent.withCString {
      let stringLength = Int(strlen($0))
      cmark_parser_feed(parser, $0, stringLength)
    }

    guard let ast = cmark_parser_finish(parser) else {
      throw MarkdownError.conversionFailed
    }

    // Render the ast into an html string
    guard let htmlCString = cmark_render_html(&ast.pointee, options.rawValue, cmark_parser_get_syntax_extensions(parser)) else {
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

  /// Strips `{...}` from code fence info lines and records attributes.
  /// Counts all code fences to track absolute indices.
  static func preprocessCodeFenceAttributes(_ store: inout AttributeStore, _ markdown: String) -> String {
    let fencePattern = #"```(\S+)"#
    let attrPattern = #"```(\S+)\h+\{([^}]+)\}"#
    guard let fenceRegex = try? NSRegularExpression(pattern: fencePattern),
          let attrRegex = try? NSRegularExpression(pattern: attrPattern) else { return markdown }

    let nsString = markdown as NSString
    let allFences = fenceRegex.matches(in: markdown, range: NSRange(location: 0, length: nsString.length))
    let attrFences = attrRegex.matches(in: markdown, range: NSRange(location: 0, length: nsString.length))

    // Build a set of locations that have attributes
    let attrLocations = Set(attrFences.map { $0.range.location })

    // Record absolute index for each attributed fence
    for (index, fence) in allFences.enumerated() {
      if attrLocations.contains(fence.range.location) {
        let attrMatch = attrFences.first { $0.range.location == fence.range.location }!
        let attrsContent = nsString.substring(with: attrMatch.range(at: 2))
        store.entries.append((target: .codeFence(index), attrs: parseAttributes(attrsContent)))
      }
    }

    // Strip attributes from markdown (in reverse to preserve indices)
    var result = markdown
    for match in attrFences.reversed() {
      let fullRange = Range(match.range, in: result)!
      let lang = nsString.substring(with: match.range(at: 1))
      result.replaceSubrange(fullRange, with: "```\(lang)")
    }
    return result
  }

  /// Strips `{...}` from heading lines and records attributes.
  /// Counts all headings per level (including raw HTML headings) to track absolute indices.
  static func preprocessHeadingAttributes(_ store: inout AttributeStore, _ markdown: String) -> String {
    let mdPattern = #"(#{1,6})\s+(.+?)$"#
    let attrPattern = #"(#{1,6})\s+(.+?)\s+\{([^}]+)\}\s*$"#
    let rawHtmlPattern = #"<h([1-6])[\s>]"#
    guard let mdRegex = try? NSRegularExpression(pattern: mdPattern, options: .anchorsMatchLines),
          let attrRegex = try? NSRegularExpression(pattern: attrPattern, options: .anchorsMatchLines),
          let rawHtmlRegex = try? NSRegularExpression(pattern: rawHtmlPattern, options: .anchorsMatchLines) else { return markdown }

    let nsString = markdown as NSString
    let mdHeadings = mdRegex.matches(in: markdown, range: NSRange(location: 0, length: nsString.length))
    let attrHeadings = attrRegex.matches(in: markdown, range: NSRange(location: 0, length: nsString.length))
    let rawHtmlHeadings = rawHtmlRegex.matches(in: markdown, range: NSRange(location: 0, length: nsString.length))

    // Merge all headings by location so we can compute absolute indices
    struct HeadingInfo: Comparable {
      let location: Int
      let level: Int
      let isAttributed: Bool
      static func < (lhs: HeadingInfo, rhs: HeadingInfo) -> Bool { lhs.location < rhs.location }
    }

    let attrLocations = Set(attrHeadings.map { $0.range.location })

    var allHeadings: [HeadingInfo] = []
    for match in mdHeadings {
      let level = nsString.substring(with: match.range(at: 1)).count
      allHeadings.append(HeadingInfo(location: match.range.location, level: level, isAttributed: attrLocations.contains(match.range.location)))
    }
    for match in rawHtmlHeadings {
      let level = Int(nsString.substring(with: match.range(at: 1)))!
      allHeadings.append(HeadingInfo(location: match.range.location, level: level, isAttributed: false))
    }
    allHeadings.sort()

    // Count per level and record absolute index for attributed ones
    var levelCounts: [Int: Int] = [:]
    for heading in allHeadings {
      let index = levelCounts[heading.level, default: 0]
      levelCounts[heading.level] = index + 1

      if heading.isAttributed {
        let attrMatch = attrHeadings.first { $0.range.location == heading.location }!
        let attrsContent = nsString.substring(with: attrMatch.range(at: 3))
        store.entries.append((target: .heading(heading.level, index), attrs: parseAttributes(attrsContent)))
      }
    }

    // Strip attributes from markdown (in reverse to preserve indices)
    var result = markdown
    for match in attrHeadings.reversed() {
      let hashes = nsString.substring(with: match.range(at: 1))
      let title = nsString.substring(with: match.range(at: 2))
      let fullRange = Range(match.range, in: result)!
      result.replaceSubrange(fullRange, with: "\(hashes) \(title)")
    }
    return result
  }

  /// Strips `{...}` from block elements (on its own line) and records attributes.
  /// Skips lines inside code fences. Tracks which block-level element each attribute applies to.
  static func preprocessBlockAttributes(_ store: inout AttributeStore, _ markdown: String) -> String {
    let attrPattern = try? NSRegularExpression(pattern: #"^\{([^}]+)\}\s*$"#)
    var lines = markdown.components(separatedBy: "\n")
    var inCodeFence = false
    var indicesToRemove: [Int] = []
    var blockCount = 0
    var inBlock = false

    for (i, line) in lines.enumerated() {
      if line.hasPrefix("```") {
        if !inCodeFence {
          blockCount += 1
          inBlock = false
        }
        inCodeFence = !inCodeFence
        continue
      }
      if inCodeFence { continue }

      let trimmed = line.trimmingCharacters(in: .whitespaces)

      // Check if this line is an attribute
      let range = NSRange(line.startIndex..., in: line)
      if let match = attrPattern?.firstMatch(in: line, range: range),
         let attrsRange = Range(match.range(at: 1), in: line) {
        // This attribute applies to the block element that precedes it
        store.entries.append((target: .block(blockCount - 1), attrs: parseAttributes(String(line[attrsRange]))))
        indicesToRemove.append(i)
        inBlock = false
        continue
      }

      if trimmed.isEmpty {
        inBlock = false
      } else if !inBlock {
        blockCount += 1
        inBlock = true
      }
    }

    for i in indicesToRemove.reversed() {
      lines.remove(at: i)
    }

    return lines.joined(separator: "\n")
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
  static func applyNthBlockAttribute(_ html: String, n: Int, attrs: String) -> String {
    let blockPattern = #"<(p|blockquote|ul|ol|table|hr)([ >])"#
    guard let regex = try? NSRegularExpression(pattern: blockPattern) else { return html }
    let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
    guard n >= 0, n < matches.count else { return html }
    let match = matches[n]
    let range = Range(match.range, in: html)!
    let tag = String(html[Range(match.range(at: 1), in: html)!])
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
