public struct MarkdownOptions: OptionSet {
  public let rawValue: Int32

  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }

  static public let sourcePosition = MarkdownOptions(rawValue: 1 << 1)
  static public let hardBreaks = MarkdownOptions(rawValue: 1 << 2)
  static public let safe = MarkdownOptions(rawValue: 1 << 3)
  static public let noBreaks = MarkdownOptions(rawValue: 1 << 4)
  static public let normalize = MarkdownOptions(rawValue: 1 << 8)
  static public let validateUTF8 = MarkdownOptions(rawValue: 1 << 9)
  static public let smartQuotes = MarkdownOptions(rawValue: 1 << 10)
  static public let unsafe = MarkdownOptions(rawValue: 1 << 17)
}
