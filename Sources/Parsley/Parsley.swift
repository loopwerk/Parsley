import Foundation
import cmark

public enum MarkdownError: Error {
  case conversionFailed
}

public struct Parsley {
  /// This parses a String into HTML, without parsing Metadata or the document title.
  public static func html(_ content: String, options: MarkdownOptions = [.safe]) throws -> String {
    var tree: UnsafeMutablePointer<cmark_node>?

    content.withCString {
      let stringLength = Int(strlen($0))
      tree = cmark_parse_document($0, stringLength, options.rawValue)
    }

    guard let ast = tree else {
      throw MarkdownError.conversionFailed
    }

    guard let cHTMLString = cmark_render_html(&ast.pointee, options.rawValue, nil) else {
      throw MarkdownError.conversionFailed
    }

    defer {
      free(cHTMLString)
    }

    guard let htmlString = String(cString: cHTMLString, encoding: String.Encoding.utf8) else {
      throw MarkdownError.conversionFailed
    }

    return htmlString
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
