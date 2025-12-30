import Foundation

enum TemplateError: Error, CustomStringConvertible {
  case message(String)

  var description: String {
    switch self {
    case let .message(value):
      return "Failed to parse template: \(value)"
    }
  }
}

enum LTE {
  enum Token: Equatable, CustomStringConvertible {
    case openBracket
    case closeBracket
    case bang
    case keywordIf
    case keywordElse
    case keywordEndIf
    case variable(String)
    case text(String)
    case invalid(Int, Character)

    var description: String {
      switch self {
      case .openBracket:
        return "{%"
      case .closeBracket:
        return "%}"
      case .bang:
        return "!"
      case .keywordIf:
        return "if"
      case .keywordElse:
        return "else"
      case .keywordEndIf:
        return "endif"
      case let .variable(name):
        return "\(name) (variable)"
      case .text:
        return "(text)"
      case let .invalid(col, token):
        return "invalid token \(token) at \(col)"
      }
    }
  }

  struct Lexer: IteratorProtocol {
    private let bytes: [UInt8]
    private let length: Int
    private var cursor: Int = 0
    private var inBracket = false

    init(_ template: String) {
      self.bytes = Array(template.utf8)
      self.length = bytes.count
    }

    private func currentChar() -> Character {
      Character(UnicodeScalar(bytes[cursor]))
    }

    private func nextChar() -> Character {
      Character(UnicodeScalar(bytes[cursor + 1]))
    }

    private mutating func skipWhitespace() {
      while cursor < length && currentChar().isWhitespace {
        cursor += 1
      }
    }

    private func isSymbolStart(_ char: Character) -> Bool {
      char.isLetter || char == "_"
    }

    private func isSymbol(_ char: Character) -> Bool {
      char.isLetter || char.isNumber || char == "_"
    }

    private mutating func readSymbol() -> String {
      let start = cursor
      while cursor < length && isSymbol(currentChar()) {
        cursor += 1
      }
      let end = max(start, cursor - 1)
      return String(bytes: bytes[start...end], encoding: .utf8) ?? ""
    }

    mutating func next() -> Token? {
      if inBracket {
        skipWhitespace()
      }

      if cursor >= length {
        return nil
      }

      if currentChar() == "{" && cursor + 1 < length && nextChar() == "%" {
        inBracket = true
        cursor += 2
        return .openBracket
      }

      if currentChar() == "%" && cursor + 1 < length && nextChar() == "}" {
        inBracket = false
        cursor += 2
        return .closeBracket
      }

    if inBracket {
      if currentChar() == "!" {
        cursor += 1
        return .bang
      }
        let char = currentChar()
        if isSymbolStart(char) {
          let symbol = readSymbol()
          switch symbol {
          case "if":
            return .keywordIf
          case "else":
            return .keywordElse
          case "endif":
            return .keywordEndIf
          default:
            return .variable(symbol)
          }
        } else {
          let invalid = currentChar()
          cursor += 1
          return .invalid(cursor, invalid)
        }
      }

      if !inBracket {
        let start = cursor
        while cursor < length {
          if currentChar() == "{" && cursor + 1 < length && nextChar() == "%" {
            break
          }
          cursor += 1
        }
        let end = max(start, cursor - 1)
        let text = String(bytes: bytes[start...end], encoding: .utf8) ?? ""
        return .text(text)
      }

      return nil
    }
  }

  enum Statement: Comparable {
    case text(String)
    case variable(String)
    case conditional(varName: String, negated: Bool, truthy: [Statement], falsy: [Statement]?)

    static func < (lhs: Statement, rhs: Statement) -> Bool {
      String(describing: lhs) < String(describing: rhs)
    }
  }

  struct Parser {
    private let tokens: [Token]
    private var cursor: Int = 0

    init(tokens: [Token]) {
      self.tokens = tokens
    }

    private var currentToken: Token? {
      guard cursor < tokens.count else { return nil }
      return tokens[cursor]
    }

    private mutating func skipBrackets() {
      while let token = currentToken, token == .openBracket || token == .closeBracket {
        cursor += 1
      }
    }

    private mutating func consumeText() -> String? {
      guard case let .text(text)? = currentToken else { return nil }
      cursor += 1
      return text
    }

    private mutating func consumeVariable() -> String? {
      guard case let .variable(name)? = currentToken else { return nil }
      cursor += 1
      return name
    }

    private mutating func consumeIf() throws -> Statement? {
      guard currentToken == .keywordIf else { return nil }
      cursor += 1

      let negated: Bool
      if currentToken == .bang {
        cursor += 1
        negated = true
      } else {
        negated = false
      }

      guard let varName = consumeVariable() else {
        throw TemplateError.message("expected variable after if, found: \(String(describing: currentToken))")
      }

      var truthy: [Statement] = []
      while let token = currentToken, token != .keywordElse && token != .keywordEndIf {
        if let stmt = try nextStatement() {
          truthy.append(stmt)
        } else {
          break
        }
      }

      var falsy: [Statement]? = nil
      if currentToken == .keywordElse {
        cursor += 1
        var elseStatements: [Statement] = []
        while let token = currentToken, token != .keywordEndIf {
          if let stmt = try nextStatement() {
            elseStatements.append(stmt)
          } else {
            break
          }
        }
        falsy = elseStatements
      }

      if currentToken == .keywordEndIf {
        cursor += 1
      } else {
        throw TemplateError.message("expected endif, found: \(String(describing: currentToken))")
      }

      return .conditional(varName: varName, negated: negated, truthy: truthy, falsy: falsy)
    }

    mutating func nextStatement() throws -> Statement? {
      skipBrackets()
      guard let token = currentToken else { return nil }

      if case .invalid = token {
        throw TemplateError.message(token.description)
      }

      if let text = consumeText() {
        return .text(text)
      }

      if let variable = consumeVariable() {
        return .variable(variable)
      }

      if let condition = try consumeIf() {
        return condition
      }

      return nil
    }
  }

  private static func isTruthy(_ value: String) -> Bool {
    switch value {
    case "true":
      return true
    case "false":
      return false
    default:
      return !value.isEmpty
    }
  }

  static func render(_ template: String, data: [String: String]) throws -> String {
    var lexer = Lexer(template)
    var tokens: [Token] = []
    while let token = lexer.next() {
      tokens.append(token)
    }

    var parser = Parser(tokens: tokens)
    var statements: [Statement] = []
    while let stmt = try parser.nextStatement() {
      statements.append(stmt)
    }

    var output = ""
    for stmt in statements {
      output += try execute(stmt, data: data)
    }

    return output
  }

  private static func execute(_ statement: Statement, data: [String: String]) throws -> String {
    switch statement {
    case let .text(text):
      return text
    case let .variable(name):
      guard let value = data[name] else {
        throw TemplateError.message("Unrecognized variable: \(name)")
      }
      return value
    case let .conditional(varName, negated, truthy, falsy):
      guard let value = data[varName] else {
        throw TemplateError.message("Unrecognized variable: \(varName)")
      }

      let truthyValue = isTruthy(value)
      let shouldUseTruthy = (truthyValue && !negated) || (!truthyValue && negated)
      let branch = shouldUseTruthy ? truthy : (falsy ?? [])

      var rendered = ""
      for stmt in branch {
        rendered += try execute(stmt, data: data)
      }
      return rendered
    }
  }
}
