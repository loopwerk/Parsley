public struct MarkdownOptions: OptionSet {
  public let rawValue: Int32

  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }

  public static let sourcePosition = MarkdownOptions(rawValue: 1 << 1)
  public static let hardBreaks = MarkdownOptions(rawValue: 1 << 2)
  public static let safe = MarkdownOptions(rawValue: 1 << 3)
  public static let noBreaks = MarkdownOptions(rawValue: 1 << 4)
  public static let normalize = MarkdownOptions(rawValue: 1 << 8)
  public static let validateUTF8 = MarkdownOptions(rawValue: 1 << 9)
  public static let smartQuotes = MarkdownOptions(rawValue: 1 << 10)
  public static let unsafe = MarkdownOptions(rawValue: 1 << 17)
}
