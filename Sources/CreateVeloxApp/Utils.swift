import Foundation

enum Utils {
  static func isValidPackageName(_ name: String) -> Bool {
    guard !name.isEmpty else { return false }
    guard let first = name.unicodeScalars.first, !CharacterSet.decimalDigits.contains(first) else {
      return false
    }

    for scalar in name.unicodeScalars {
      if CharacterSet.uppercaseLetters.contains(scalar) {
        return false
      }

      let isAllowed = CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "_"
      if !isAllowed {
        return false
      }
    }

    return true
  }

  static func toValidPackageName(_ name: String) -> String {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let lowered = trimmed.lowercased()

    var replaced = lowered
      .replacingOccurrences(of: ":", with: "-")
      .replacingOccurrences(of: ";", with: "-")
      .replacingOccurrences(of: " ", with: "-")
      .replacingOccurrences(of: "~", with: "-")

    replaced = replaced
      .replacingOccurrences(of: ".", with: "")
      .replacingOccurrences(of: "\\", with: "")
      .replacingOccurrences(of: "/", with: "")

    let stripped = replaced.drop { char in
      char.isNumber || char == "-"
    }

    if stripped.isEmpty {
      return "velox-app"
    }

    return String(stripped)
  }

  static func toPascalCase(_ name: String) -> String {
    var result = ""
    var capitalizeNext = true

    for scalar in name.unicodeScalars {
      if CharacterSet.alphanumerics.contains(scalar) {
        let char = Character(scalar)
        if capitalizeNext {
          result.append(String(char).uppercased())
          capitalizeNext = false
        } else {
          result.append(String(char))
        }
      } else {
        capitalizeNext = true
      }
    }

    if result.isEmpty {
      return "VeloxApp"
    }

    if let first = result.unicodeScalars.first, CharacterSet.decimalDigits.contains(first) {
      return "VeloxApp" + result
    }

    return result
  }
}
