import ArgumentParser
import Foundation

@main
struct CreateVeloxApp: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-velox-app",
    abstract: "Rapidly scaffold out a new Velox app project.",
    version: "0.1.0"
  )

  @Argument(help: "Specify project name which is used for the directory and Swift package.")
  var projectName: String?

  @Option(name: .shortAndLong, help: "Specify the UI template to use. Available: \(Template.helpList).")
  var template: Template = .vanilla

  @Option(help: "Specify a unique identifier for your application.")
  var identifier: String?

  @Flag(name: [.customShort("y"), .long], help: "Skip prompts and use defaults where applicable.")
  var yes: Bool = false

  @Flag(name: [.customShort("f"), .long], help: "Force create the directory even if it is not empty.")
  var force: Bool = false

  @Option(help: "Use a local Velox checkout (path) instead of the GitHub dependency.")
  var veloxPath: String?

  mutating func run() throws {
    let defaults = Defaults()

    let resolvedProjectName: String
    if let projectName {
      resolvedProjectName = projectName
    } else if yes {
      resolvedProjectName = defaults.projectName
    } else {
      resolvedProjectName = Prompts.text("Project name", defaultValue: defaults.projectName)
    }

    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let isCurrentDir = resolvedProjectName == "."
    let projectDir = isCurrentDir ? cwd : cwd.appendingPathComponent(resolvedProjectName)
    let displayName = isCurrentDir ? cwd.lastPathComponent : resolvedProjectName

    let packageName = Utils.isValidPackageName(displayName)
      ? displayName
      : Utils.toValidPackageName(displayName)

    let resolvedIdentifier: String
    if let identifier {
      resolvedIdentifier = identifier
    } else {
      let defaultIdentifier = defaults.identifier(packageName: packageName)
      resolvedIdentifier = yes
        ? defaultIdentifier
        : Prompts.text("Identifier", defaultValue: defaultIdentifier)
    }

    if try shouldAbortOverwrite(targetDir: projectDir) {
      print("\(Colors.bold)\(Colors.red)x\(Colors.reset) Directory is not empty, operation cancelled")
      throw ExitCode.failure
    }

    try prepareTargetDirectory(projectDir)

    let swiftModuleName = Utils.toPascalCase(displayName)
    let veloxDependency = makeVeloxDependency()

    let templateData: [String: String] = [
      "project_name": displayName,
      "package_name": packageName,
      "identifier": resolvedIdentifier,
      "swift_module_name": swiftModuleName,
      "velox_dependency": veloxDependency
    ]

    try TemplateRenderer.render(template: template, to: projectDir, data: templateData)

    let bootstrapSucceeded = runBootstrapIfNeeded(projectDir)

    print("\nTemplate created! To get started run:")
    if projectDir != cwd {
      let cdCommand = displayName.contains(" ") ? "cd \"\(displayName)\"" : "cd \(displayName)"
      print("  \(cdCommand)")
    }
    if !bootstrapSucceeded {
      print("  make bootstrap")
    }
    print("  swift build")
    print("  swift run \(swiftModuleName)")

    if !printMissingDeps() {
      print("\nTip: set VELOX_DEV_URL to load a dev server instead of the built-in UI.")
      if !bootstrapSucceeded {
        print("Important: on macOS run `make bootstrap` before the first build or it will fail.")
      }
    }
  }

  private func makeVeloxDependency() -> String {
    if let veloxPath {
      return ".package(path: \"\(veloxPath)\")"
    }
    return ".package(url: \"https://github.com/velox-apps/velox\", branch: \"main\")"
  }

  private func shouldAbortOverwrite(targetDir: URL) throws -> Bool {
    let fm = FileManager.default
    guard fm.fileExists(atPath: targetDir.path) else {
      return false
    }

    let contents = try fm.contentsOfDirectory(atPath: targetDir.path)
    if contents.isEmpty {
      return false
    }

    if force {
      return false
    }

    if yes {
      return true
    }

    let name = targetDir == URL(fileURLWithPath: fm.currentDirectoryPath)
      ? "Current"
      : targetDir.lastPathComponent
    let prompt = "\(name) directory is not empty, do you want to overwrite?"
    return !Prompts.confirm(prompt, defaultValue: false)
  }

  private func prepareTargetDirectory(_ targetDir: URL) throws {
    let fm = FileManager.default
    if !fm.fileExists(atPath: targetDir.path) {
      try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
      return
    }

    try cleanDirectory(targetDir)
  }

  private func cleanDirectory(_ directory: URL) throws {
    let fm = FileManager.default
    let entries = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey])

    for entry in entries {
      if entry.lastPathComponent == ".git" {
        continue
      }

      let resourceValues = try entry.resourceValues(forKeys: [.isDirectoryKey])
      if resourceValues.isDirectory == true {
        try cleanDirectory(entry)
        try fm.removeItem(at: entry)
      } else {
        try fm.removeItem(at: entry)
      }
    }
  }

  private func printMissingDeps() -> Bool {
    let swiftInstalled = isCLIInstalled("swift", arg: "--version")
    guard !swiftInstalled else { return false }

    let missing = [
      ("Swift", "Install Xcode Command Line Tools: `xcode-select --install`")
    ]

    print("\nYour system is \(Colors.yellow)missing dependencies\(Colors.reset):")
    for (name, instruction) in missing {
      print("- \(name): \(instruction)")
    }
    return true
  }

  private func isCLIInstalled(_ tool: String, arg: String) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [tool, arg]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    do {
      try process.run()
    } catch {
      return false
    }

    process.waitUntilExit()
    return process.terminationStatus == 0
  }

  private func runBootstrapIfNeeded(_ projectDir: URL) -> Bool {
    #if os(macOS)
    let makefile = projectDir.appendingPathComponent("Makefile")
    guard FileManager.default.fileExists(atPath: makefile.path) else {
      return false
    }

    print("\nRunning macOS bootstrap (make bootstrap)...")

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["make", "bootstrap"]
    process.currentDirectoryURL = projectDir
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError

    do {
      try process.run()
    } catch {
      print("Bootstrap failed to start: \(error.localizedDescription)")
      return false
    }

    process.waitUntilExit()
    if process.terminationStatus != 0 {
      print("Bootstrap failed. See README.md for manual steps.")
      return false
    }

    return true
    #else
    return false
    #endif
  }
}

struct Defaults {
  let projectName = "velox-app"

  func identifier(packageName: String) -> String {
    let user = Utils.toValidPackageName(NSUserName())
    return "com.\(user).\(packageName)"
  }
}
