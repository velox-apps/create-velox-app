import Foundation

enum Prompts {
  static func text(_ prompt: String, defaultValue: String?) -> String {
    if let defaultValue {
      print("? \(prompt) (\(defaultValue)) ", terminator: "")
    } else {
      print("? \(prompt) ", terminator: "")
    }

    if let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !input.isEmpty {
      return input
    }

    return defaultValue ?? ""
  }

  static func confirm(_ prompt: String, defaultValue: Bool) -> Bool {
    let choice = defaultValue ? "Y/n" : "y/N"
    print("? \(prompt) (\(choice)) ", terminator: "")

    guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !input.isEmpty else {
      return defaultValue
    }

    switch input.lowercased() {
    case "y", "yes":
      return true
    case "n", "no":
      return false
    default:
      return defaultValue
    }
  }
}
