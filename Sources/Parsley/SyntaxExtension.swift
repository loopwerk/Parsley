import CMarkGFM

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
  /// A custom syntax extension (currently it is easiest to make these in C and import them into Swift).
  case custom(SyntaxExtensionInitializer)

  /// The extensions enabled by default (all built-in GFM extensions).
  public static var defaultExtensions: [SyntaxExtension] {
    [.autolink, .strikethrough, .table, .tagfilter, .tasklist]
  }

  /// Creates a pointer to an instance of the syntax extension.
  ///
  /// This pointer can only be used for a single parser because it gets freed along with the parser.
  func createPointer() -> SyntaxExtensionPointer {
    switch self {
      case .autolink:
        return create_autolink_extension()
      case .strikethrough:
        return create_strikethrough_extension()
      case .table:
        return create_table_extension()
      case .tagfilter:
        return create_tagfilter_extension()
      case .tasklist:
        return create_tasklist_extension()
      case .custom(let syntaxExtensionInitializer):
        return syntaxExtensionInitializer()
    }
  }
}
