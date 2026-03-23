public struct MarkdownOptions: OptionSet {
  public let rawValue: Int32

  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }

  /// Include source position information in the rendered output.
  public static let sourcePosition = MarkdownOptions(rawValue: 1 << 1)

  /// Render newlines as hard line breaks (`<br />`).
  public static let hardBreaks = MarkdownOptions(rawValue: 1 << 2)

  /// No-op: safe mode is enabled by default. Raw HTML is stripped unless `.unsafe` is set.
  public static let safe = MarkdownOptions(rawValue: 1 << 3)

  /// Render softbreaks (newlines) as spaces instead of newlines.
  public static let noBreaks = MarkdownOptions(rawValue: 1 << 4)

  /// Normalize the document by consolidating adjacent text nodes.
  public static let normalize = MarkdownOptions(rawValue: 1 << 8)

  /// Replace invalid UTF-8 sequences with the replacement character (U+FFFD).
  public static let validateUTF8 = MarkdownOptions(rawValue: 1 << 9)

  /// Convert straight quotes to curly quotes.
  public static let smartQuotes = MarkdownOptions(rawValue: 1 << 10)

  /// Allow raw HTML to pass through to the output instead of being stripped.
  public static let unsafe = MarkdownOptions(rawValue: 1 << 17)

  /// Enables markdown attributes: `{.class #id key="value"}` on headings, paragraphs, and other block elements.
  public static let markdownAttributes = MarkdownOptions(rawValue: 1 << 30)
}
