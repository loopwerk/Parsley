public struct Document {
  /// The inferred title of the document, from any top-level
  /// heading found when parsing. If the Markdown text contained
  /// two top-level headings, then this property will contain
  /// the first one.
  public let title: String?

  /// The raw body, not parsed. Stripped from the initial title.
  public let rawBody: String

  /// The HTML representation of the Markdown, ready to
  /// be rendered in a web browser. Stripped from the initial title.
  public let body: String

  /// Any metadata values found at the top of the Markdown document.
  /// See https://python-markdown.github.io/extensions/meta_data/ for more information.
  /// You'll need to use the `meta` extension for this to work.
  public let metadata: [String : String]

  internal init(title: String?, rawBody: String, body: String, metadata: [String : String]) {
    self.title = title
    self.rawBody = rawBody
    self.body = body
    self.metadata = metadata
  }
}
