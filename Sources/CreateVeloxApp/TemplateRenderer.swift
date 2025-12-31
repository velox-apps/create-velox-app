import Foundation
import ArgumentParser

enum Template: String, CaseIterable, ExpressibleByArgument, CustomStringConvertible {
  case vanilla
  case hummingbird
  case svelte
  case svelteTs = "svelte-ts"

  var description: String {
    rawValue
  }

  static var helpList: String {
    allCases.map(\.rawValue).joined(separator: ", ")
  }
}

enum TemplateRenderer {
  static func render(template: Template, to targetDir: URL, data: [String: String]) throws {
    guard let resourcesURL = Bundle.module.resourceURL else {
      throw TemplateError.message("Failed to locate bundled templates")
    }

    let templateRoot = resourcesURL.appendingPathComponent("Templates")
    let templateDir = templateRoot.appendingPathComponent("template-\(template.rawValue)")

    guard FileManager.default.fileExists(atPath: templateDir.path) else {
      throw TemplateError.message("Template not found: \(templateDir.path)")
    }

    try renderDirectory(templateDir, to: targetDir, data: data)
  }

  private static func renderDirectory(_ directory: URL, to targetDir: URL, data: [String: String]) throws {
    try renderDirectoryContents(directory, root: directory, to: targetDir, data: data)
  }

  private static func renderDirectoryContents(_ directory: URL, root: URL, to targetDir: URL, data: [String: String]) throws {
    let entries = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [])
    for entry in entries {
      let resourceValues = try entry.resourceValues(forKeys: [.isDirectoryKey])
      if resourceValues.isDirectory == true {
        try renderDirectoryContents(entry, root: root, to: targetDir, data: data)
        continue
      }

      if entry.lastPathComponent == ".DS_Store" {
        continue
      }

      let prefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
      let relativePath = entry.path.replacingOccurrences(of: prefix, with: "")
      let relativeDir = (relativePath as NSString).deletingLastPathComponent
      let renderedDir: String
      if relativeDir.isEmpty {
        renderedDir = ""
      } else {
        let components = relativeDir.split(separator: "/").map { String($0) }
        renderedDir = try components.map { try renderPathComponent($0, data: data) }.joined(separator: "/")
      }
      var fileName = entry.lastPathComponent

      if fileName == "_gitignore" {
        fileName = ".gitignore"
      }

      let isTemplate = fileName.hasSuffix(".lte")
      if isTemplate {
        fileName = String(fileName.dropLast(4))
      }

      let renderedFileName = try renderPathComponent(fileName, data: data)

      let destinationDir = renderedDir.isEmpty ? targetDir : targetDir.appendingPathComponent(renderedDir)
      let destinationURL = destinationDir.appendingPathComponent(renderedFileName)

      try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)

      if isTemplate {
        let contents = try String(contentsOf: entry, encoding: .utf8)
        let rendered = try LTE.render(contents, data: data)
        guard let renderedData = rendered.data(using: .utf8) else {
          throw TemplateError.message("Failed to encode rendered template for \(relativePath)")
        }
        try renderedData.write(to: destinationURL)
      } else {
        try FileManager.default.copyItem(at: entry, to: destinationURL)
      }
    }
  }

  private static func renderPathComponent(_ value: String, data: [String: String]) throws -> String {
    let replaced = value.replacingOccurrences(
      of: "__swift_module_name__",
      with: data["swift_module_name"] ?? "__swift_module_name__"
    )
    return try LTE.render(replaced, data: data)
  }
}
