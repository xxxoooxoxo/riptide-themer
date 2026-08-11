import Darwin
import Foundation

@main
struct RiptideRoundedPatcher {
  static func main() {
    guard
      let scriptPath = Bundle.main.object(forInfoDictionaryKey: "RiptidePatchScript") as? String,
      FileManager.default.isExecutableFile(atPath: scriptPath)
    else {
      FileHandle.standardError.write(
        Data("[riptide-rounded-patcher] patch script is missing or not executable\n".utf8)
      )
      Darwin.exit(1)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = [scriptPath]
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError

    do {
      try process.run()
      process.waitUntilExit()
      Darwin.exit(process.terminationStatus)
    } catch {
      FileHandle.standardError.write(
        Data("[riptide-rounded-patcher] failed to start patch script: \(error)\n".utf8)
      )
      Darwin.exit(1)
    }
  }
}
