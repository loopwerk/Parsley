import Foundation
import CMarkGFM

public enum MarkdownError: Error {
  case conversionFailed
}

public struct Parsley {
  /// This parses a String into HTML, without parsing Metadata or the document title.
  public static func html(_ content: String, options: MarkdownOptions = [.safe], additionalExtensions: [UnsafeMutablePointer<cmark_syntax_extension>] = []) throws -> String {
    // Create parser
    guard let parser = cmark_parser_new(options.rawValue) else {
      throw MarkdownError.conversionFailed
    }

    // Register user-defined extensions
    for additionalExtension in additionalExtensions {
      cmark_parser_attach_syntax_extension(parser, additionalExtension)
    }
    
    // Register default extensions
    cmark_parser_attach_syntax_extension(parser, create_autolink_extension())
    cmark_parser_attach_syntax_extension(parser, create_strikethrough_extension())
    cmark_parser_attach_syntax_extension(parser, create_table_extension())
    cmark_parser_attach_syntax_extension(parser, create_tagfilter_extension())
    cmark_parser_attach_syntax_extension(parser, create_tasklist_extension())
    
    // Parse into an ast
    content.withCString {
      let stringLength = Int(strlen($0))
      cmark_parser_feed(parser, $0, stringLength)
    }
    
    guard let ast = cmark_parser_finish(parser) else {
      throw MarkdownError.conversionFailed
    }
    
    // Render the ast into an html string
    guard let htmlCString = cmark_render_html(&ast.pointee, options.rawValue, parser.pointee.syntax_extensions) else {
      throw MarkdownError.conversionFailed
    }
    
    // Free memory
    cmark_parser_free(parser)
    cmark_node_free(ast)
    cmark_release_plugins()

    defer {
      free(htmlCString)
    }
    
    // Convert resulting c string to a Swift string
    guard let html = String(cString: htmlCString, encoding: String.Encoding.utf8) else {
      throw MarkdownError.conversionFailed
    }

    return html
  }

  /// This parses a String into a Document, which contains parsed Metadata and the document title.
  public static func parse(_ content: String, options: MarkdownOptions = [.safe]) throws -> Document {
    let (header, title, rawBody) = Parsley.parts(from: content)

    let metadata = Parsley.metadata(from: header)
    let bodyHtml = try Parsley.html(rawBody, options: options).trimmingCharacters(in: .newlines)

    return Document(title: title, rawBody: rawBody, body: bodyHtml, metadata: metadata)
  }
}

private extension Parsley {
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
