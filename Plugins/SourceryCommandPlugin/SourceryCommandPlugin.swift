import PackagePlugin
import Foundation

@main
struct SourceryCommandPlugin {
    @discardableResult
    private func run(_ context: CommonPluginContext, withConfig configFilePath: String, cacheBasePath: String) throws -> Command{
        let sourcery = try context.tool(named: "SourceryExecutable").path.string
        let executable = try context.tool(named: "SourceryExecutable")
        let arguments = [
            "--config",
            configFilePath,
            "--cacheBasePath",
            cacheBasePath
        ]

        let pluginWorkDirectory = context.pluginWorkDirectory
        let outputPath: Path = pluginWorkDirectory.appending("Output")

        let sourceryURL = URL(fileURLWithPath: sourcery)
        
        let process = Process()
        process.executableURL = sourceryURL
        process.arguments = arguments

        try process.run()
        process.waitUntilExit()

        let gracefulExit = process.terminationReason == .exit && process.terminationStatus == 0
        if !gracefulExit {
            throw "🛑 The plugin execution failed with reason: \(process.terminationReason.rawValue) and status: \(process.terminationStatus) "
        }

        return Command.prebuildCommand(
                displayName: "SwiftLint",
                executable: executable.path,
                arguments: arguments,
                environment: [:],
                outputFilesDirectory: outputPath
        )
    }
}

// MARK: - CommandPlugin

extension SourceryCommandPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        // Run one per target
        for target in context.package.targets {
            let configFilePath = target.directory.appending(subpath: ".sourcery.yml").string

            guard FileManager.default.fileExists(atPath: configFilePath) else {
                Diagnostics.warning("⚠️ Could not find `.sourcery.yml` for target \(target.name)")
                continue
            }
            
            try run(context, withConfig: configFilePath, cacheBasePath: context.pluginWorkDirectory.string)
        }
    }
}

// MARK: - BuildToolPlugin

extension SourceryCommandPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        var commands = [Command]()
        // Run one per target
        for target in context.package.targets {
            let configFilePath = target.directory.appending(subpath: ".sourcery.yml").string
            guard FileManager.default.fileExists(atPath: configFilePath) else {
                Diagnostics.warning("⚠️ Could not find `.sourcery.yml` for target \(target.name)")
                continue
            }
            
            commands.append(try run(context, withConfig: configFilePath, cacheBasePath: context.pluginWorkDirectory.string))
        }

        return commands
    }
}

// MARK: - XcodeProjectPlugin

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SourceryCommandPlugin: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        for target in context.xcodeProject.targets {
            guard let configFilePath = target
                .inputFiles
                .filter({ $0.path.lastComponent == ".sourcery.yml" })
                .first?
                .path
                .string else {
                Diagnostics.warning("⚠️ Could not find `.sourcery.yml` in Xcode's input file list")
                return
            }
            try run(context, withConfig: configFilePath, cacheBasePath: context.pluginWorkDirectory.string)
        }
    }
}
#endif

protocol CommonPluginContext {
    func tool(named name: String) throws -> PluginContext.Tool
    var pluginWorkDirectory: Path { get }
}
extension XcodePluginContext: CommonPluginContext {}
extension PluginContext: CommonPluginContext {}


extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
