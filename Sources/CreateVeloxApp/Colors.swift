import Foundation

enum Colors {
  static let black = "\u{001B}[30m"
  static let red = "\u{001B}[31m"
  static let green = "\u{001B}[32m"
  static let yellow = "\u{001B}[33m"
  static let blue = "\u{001B}[34m"
  static let white = "\u{001B}[37m"
  static let reset = "\u{001B}[0m"
  static let bold = "\u{001B}[1m"
  static let italic = "\u{001B}[3m"
  static let dim = "\u{001B}[2m"
  static let dimReset = "\u{001B}[22m"

  static func strip(_ value: String) -> String {
    value
      .replacingOccurrences(of: black, with: "")
      .replacingOccurrences(of: red, with: "")
      .replacingOccurrences(of: green, with: "")
      .replacingOccurrences(of: yellow, with: "")
      .replacingOccurrences(of: blue, with: "")
      .replacingOccurrences(of: white, with: "")
      .replacingOccurrences(of: reset, with: "")
      .replacingOccurrences(of: bold, with: "")
      .replacingOccurrences(of: italic, with: "")
      .replacingOccurrences(of: dim, with: "")
      .replacingOccurrences(of: dimReset, with: "")
  }
}
