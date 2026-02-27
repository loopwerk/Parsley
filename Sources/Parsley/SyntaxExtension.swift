import cmark_gfm
import cmark_gfm_extensions

/// An unsafe pointer to a syntax extension. Can only be used with one parser.
public typealias SyntaxExtensionPointer = UnsafeMutablePointer<cmark_syntax_extension>
/// A function that can create instances of a syntax extension.
public typealias SyntaxExtensionInitializer = () -> SyntaxExtensionPointer

/// A cmark-gfm syntax extension.
public enum SyntaxExtension {
  /// Automatically turns plaintext URLs into links
  case autolink
  /// Adds the `~text~` syntax for adding the strikethrough style to text.
  case strikethrough
  /// Enables the creation of tables.
  case table
  /// Filters out the following HTML tags: `["title", "textarea", "style", "xmp", "iframe", "noembed", "noframes", "script", "plaintext"]`.
  case tagfilter
  /// Adds the `- [ ] This is a task` syntax for creating tasklists.
  case tasklist
  /// A custom syntax extension looked up by name from the cmark-gfm registry.
  case custom(String)

  /// The extensions enabled by default (all built-in GFM extensions).
  public static var defaultExtensions: [SyntaxExtension] {
    [.autolink, .strikethrough, .table, .tagfilter, .tasklist]
  }

  /// The extension name used for registry lookup.
  var extensionName: String {
    switch self {
      case .autolink: return "autolink"
      case .strikethrough: return "strikethrough"
      case .table: return "table"
      case .tagfilter: return "tagfilter"
      case .tasklist: return "tasklist"
      case .custom(let name): return name
    }
  }

  /// Ensures GFM core extensions are registered. Safe to call multiple times.
  static func ensureRegistered() {
    cmark_gfm_core_extensions_ensure_registered()
  }

  /// Creates a pointer to an instance of the syntax extension.
  ///
  /// This pointer can only be used for a single parser because it gets freed along with the parser.
  func createPointer() -> SyntaxExtensionPointer? {
    SyntaxExtension.ensureRegistered()
    return cmark_find_syntax_extension(extensionName)
  }
}
