import AppKit
import SwiftUI

@main
struct SreeportMacApp: App {
    @StateObject private var model = SreeportModel()

    var body: some Scene {
        MenuBarExtra {
            SreeportMenu(model: model)
                .frame(width: 460, height: 640)
                .onAppear {
                    model.refresh()
                }
        } label: {
            Image(nsImage: SreeportIcon.menuBarImage())
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}

struct SreeportMenu: View {
    @ObservedObject var model: SreeportModel
    @State private var query = ""
    @State private var showWorkspaceTools = false

    private var filteredProjects: [ProjectStatus] {
        if query.isEmpty { return model.projects }
        return model.projects.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.domain.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(model: model)

            HStack(spacing: 10) {
                MetricTile(title: "Running", value: "\(model.runningCount)", tone: .green)
                MetricTile(title: "Projects", value: "\(model.projects.count)", tone: .blue)
                MetricTile(title: "Issues", value: "\(model.issueCount)", tone: model.issueCount == 0 ? .secondary : .orange)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search projects", text: $query)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

            ActionBar(model: model, showWorkspaceTools: $showWorkspaceTools)

            if showWorkspaceTools {
                WorkspaceToolsPanel(model: model)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack {
                Text("Projects")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(model.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                LazyVStack(spacing: 10) {
                    if filteredProjects.isEmpty {
                        EmptyState(query: query)
                    } else {
                        ForEach(filteredProjects) { project in
                            ProjectRow(project: project, model: model)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(minHeight: 260, maxHeight: 330)

            OutputPanel(model: model)
        }
        .padding(18)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct HeaderView: View {
    @ObservedObject var model: SreeportModel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Color.teal.opacity(0.22), Color.blue.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(nsImage: SreeportIcon.menuBarImage())
                    .resizable()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.primary)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text("Sreeport")
                    .font(.title3.weight(.bold))
                Text(model.workspaceLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            IconButton(systemName: "arrow.clockwise", help: "Refresh") {
                model.refresh()
            }
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let tone: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Circle()
                    .fill(tone)
                    .frame(width: 7, height: 7)
                Text(value)
                    .font(.headline.monospacedDigit())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct ActionBar: View {
    @ObservedObject var model: SreeportModel
    @Binding var showWorkspaceTools: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                PrimaryActionButton(title: "Start All", systemName: "play.fill", tone: .green) {
                    model.run("start", "all")
                }
                PrimaryActionButton(title: "Stop All", systemName: "stop.fill", tone: .red) {
                    model.run("stop", "all")
                }
            }

            HStack(spacing: 8) {
                Button {
                    model.run("proxy", "restart")
                    model.refreshProxy()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "point.3.connected.trianglepath.dotted")
                            .font(.system(size: 14, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Restart Proxy")
                                .font(.caption.weight(.semibold))
                            Text(model.proxyLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Circle()
                            .fill(model.proxyRunning ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 11))
                .help("Regenerate and restart the Caddy proxy")

                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        showWorkspaceTools.toggle()
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: showWorkspaceTools ? "xmark" : "slider.horizontal.3")
                            .font(.system(size: 15, weight: .semibold))
                        Text(showWorkspaceTools ? "Close" : "Tools")
                            .font(.caption2.weight(.medium))
                    }
                    .frame(width: 70, height: 48)
                }
                .buttonStyle(.plain)
                .background(showWorkspaceTools ? Color.accentColor.opacity(0.15) : Color(nsColor: .quaternaryLabelColor).opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                .help("Show workspace tools")
            }
        }
    }
}

struct WorkspaceToolsPanel: View {
    @ObservedObject var model: SreeportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Workspace Tools", systemImage: "folder.badge.gearshape")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(model.workspaceLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack(spacing: 8) {
                UtilityButton(title: "Open Folder", systemName: "folder") {
                    model.openWorkspace()
                }
                UtilityButton(title: "Config", systemName: "doc.text") {
                    model.openConfig()
                }
                UtilityButton(title: "Doctor", systemName: "stethoscope") {
                    model.capture("doctor")
                    model.refreshProxy()
                }
                UtilityButton(title: "Copy Status", systemName: "doc.on.doc") {
                    model.copyStatus()
                }
            }

            HStack(spacing: 8) {
                UtilityButton(title: "Write Proxy", systemName: "square.and.arrow.down") {
                    model.capture("proxy", "write")
                    model.refreshProxy()
                }
                UtilityButton(title: "Proxy Status", systemName: "wave.3.right") {
                    model.capture("proxy", "status")
                    model.refreshProxy()
                }
                UtilityButton(title: "Quit", systemName: "power") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.16), lineWidth: 1)
        )
    }
}

struct ProjectRow: View {
    let project: ProjectStatus
    @ObservedObject var model: SreeportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusGlyph(project: project)
                VStack(alignment: .leading, spacing: 3) {
                    Text(project.name)
                        .font(.system(size: 14, weight: .semibold))
                    Text(project.domain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(project.stateLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(project.stateColor)
                    Text(":\(project.port)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 7) {
                MiniActionButton(title: "Open", systemName: "safari") { model.run("open", project.name) }
                MiniIconButton(systemName: "play.fill", help: "Start \(project.name)") { model.run("start", project.name) }
                MiniIconButton(systemName: "arrow.clockwise", help: "Restart \(project.name)") { model.run("restart", project.name) }
                MiniIconButton(systemName: "stop.fill", help: "Stop \(project.name)") { model.run("stop", project.name) }
                MiniIconButton(systemName: "doc.text.magnifyingglass", help: "Show logs for \(project.name)") { model.capture("logs", project.name) }
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(project.stateColor.opacity(0.18), lineWidth: 1)
        )
    }
}

struct StatusGlyph: View {
    let project: ProjectStatus

    var body: some View {
        ZStack {
            Circle()
                .fill(project.stateColor.opacity(0.16))
            Circle()
                .fill(project.stateColor)
                .frame(width: 9, height: 9)
        }
        .frame(width: 24, height: 24)
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemName: String
    let tone: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tone)
                Text(title)
                    .font(.caption.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .background(tone.opacity(0.11), in: RoundedRectangle(cornerRadius: 11))
    }
}

struct UtilityButton: View {
    let title: String
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
        .help(title)
    }
}

struct MiniActionButton: View {
    let title: String
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
        .help(title)
    }
}

struct IconButton: View {
    let systemName: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
        .help(help)
    }
}

struct MiniIconButton: View {
    let systemName: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 26, height: 24)
        }
        .buttonStyle(.plain)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 7))
        .help(help)
    }
}

struct EmptyState: View {
    let query: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(query.isEmpty ? "No projects configured" : "No matching projects")
                .font(.subheadline.weight(.semibold))
            Text(query.isEmpty ? "Add projects with sreeport.config.ts." : "Try a different name or domain.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct OutputPanel: View {
    @ObservedObject var model: SreeportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(model.outputTitle, systemImage: model.error == nil ? "terminal" : "exclamationmark.triangle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(model.error == nil ? Color.secondary : Color.red)
                Spacer()
                if model.commandOutput != nil || model.error != nil {
                    Button("Clear") {
                        model.clearOutput()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }

            Text(model.visibleOutput)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(model.error == nil ? Color.secondary : Color.red)
                .lineLimit(4)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .topLeading)
                .padding(10)
                .textSelection(.enabled)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: SreeportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sreeport Settings")
                .font(.title2.bold())
            Text("Project mappings are managed with sreeport.config.ts in each workspace. The settings window will grow into a full editor for mappings, shortcuts, proxy configuration, and browser defaults.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Run Doctor") {
                model.run("doctor")
            }
            Spacer()
        }
        .padding(24)
        .frame(width: 520, height: 300)
    }
}

final class SreeportModel: ObservableObject {
    @Published var projects: [ProjectStatus] = []
    @Published var error: String?
    @Published var commandOutput: String?
    @Published var outputTitle = "Output"
    @Published var proxyRunning = false
    @Published var proxyPid: Int?

    var summary: String {
        if projects.isEmpty { return "No project config loaded" }
        let running = projects.filter(\.running).count
        return "\(running) of \(projects.count) running"
    }

    var runningCount: Int {
        projects.filter(\.running).count
    }

    var issueCount: Int {
        projects.filter { !$0.listening }.count
    }

    var workspaceLabel: String {
        guard let workspace = resolveWorkspace() else { return "Workspace not selected" }
        return (workspace as NSString).abbreviatingWithTildeInPath
    }

    var proxyLabel: String {
        proxyRunning ? "Live\(proxyPid.map { " pid=\($0)" } ?? "")" : "Not running"
    }

    var visibleOutput: String {
        if let error, !error.isEmpty { return error }
        if let commandOutput, !commandOutput.isEmpty { return commandOutput }
        return "Select a project action or open logs to see command output."
    }

    func refresh() {
        let result = runSreeport(["status", "--json"])
        if result.exitCode != 0 {
            error = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            projects = []
            return
        }
        do {
            let data = Data(result.output.utf8)
            let decoded = try JSONDecoder().decode(StatusResponse.self, from: data)
            projects = decoded.projects
            error = nil
            refreshProxy()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func run(_ args: String...) {
        let result = runSreeport(args)
        if result.exitCode != 0 {
            error = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            commandOutput = nil
        } else {
            error = nil
            commandOutput = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        outputTitle = args.joined(separator: " ")
        refresh()
    }

    func capture(_ args: String...) {
        let result = runSreeport(args)
        if result.exitCode != 0 {
            error = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            commandOutput = nil
        } else {
            error = nil
            commandOutput = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        outputTitle = args.joined(separator: " ")
    }

    func refreshProxy() {
        let result = runSreeport(["proxy", "status", "--json"])
        guard result.exitCode == 0,
              let data = result.output.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(ProxyStatus.self, from: data) else {
            proxyRunning = false
            proxyPid = nil
            return
        }
        proxyRunning = decoded.running
        proxyPid = decoded.pid
    }

    func clearOutput() {
        error = nil
        commandOutput = nil
        outputTitle = "Output"
    }

    func openWorkspace() {
        guard let workspace = resolveWorkspace() else {
            error = "Workspace path is not configured."
            return
        }
        openPath(workspace)
    }

    func openConfig() {
        guard let workspace = resolveWorkspace() else {
            error = "Workspace path is not configured."
            return
        }
        openPath("\(workspace)/sreeport.config.ts")
    }

    func copyStatus() {
        let result = runSreeport(["status"])
        if result.exitCode == 0 {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result.output, forType: .string)
            commandOutput = "Copied current status to clipboard."
            error = nil
        } else {
            error = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            commandOutput = nil
        }
        outputTitle = "copy status"
    }

    private func openPath(_ path: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [path]
        do {
            try process.run()
            commandOutput = "Opened \(path)"
            error = nil
        } catch {
            self.error = error.localizedDescription
            commandOutput = nil
        }
        outputTitle = "open"
    }

    private func runSreeport(_ args: [String]) -> CommandResult {
        let process = Process()
        let cli = resolveSreeportCLI()
        process.executableURL = URL(fileURLWithPath: cli.executable)
        process.arguments = cli.arguments + args
        if let workspace = resolveWorkspace() {
            process.currentDirectoryURL = URL(fileURLWithPath: workspace)
        }
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return CommandResult(exitCode: process.terminationStatus, output: String(data: data, encoding: .utf8) ?? "")
        } catch {
            return CommandResult(exitCode: 1, output: error.localizedDescription)
        }
    }

    private func resolveSreeportCLI() -> (executable: String, arguments: [String]) {
        let candidates = [
            "/opt/homebrew/bin/sreeport",
            "/usr/local/bin/sreeport"
        ]
        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
            return (candidate, [])
        }
        return ("/usr/bin/env", ["sreeport"])
    }

    private func resolveWorkspace() -> String? {
        if let envWorkspace = ProcessInfo.processInfo.environment["SREEPORT_WORKSPACE"], !envWorkspace.isEmpty {
            return envWorkspace
        }

        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let workspaceFile = support?
            .appendingPathComponent("Sreeport", isDirectory: true)
            .appendingPathComponent("workspace", isDirectory: false)

        if let workspaceFile,
           let content = try? String(contentsOf: workspaceFile, encoding: .utf8) {
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return nil
    }
}

struct CommandResult {
    let exitCode: Int32
    let output: String
}

struct StatusResponse: Decodable {
    let projects: [ProjectStatus]
}

struct ProxyStatus: Decodable {
    let running: Bool
    let pid: Int?
}

struct ProjectStatus: Decodable, Identifiable {
    var id: String { name }
    let name: String
    let domain: String
    let port: Int
    let pid: Int?
    let running: Bool
    let listening: Bool
    let url: String
    let logPath: String

    var stateLabel: String {
        if listening { return "Live" }
        if running { return "Starting" }
        return "Stopped"
    }

    var stateColor: Color {
        if listening { return .green }
        if running { return .orange }
        return .secondary
    }
}

enum SreeportIcon {
    static func menuBarImage() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.labelColor.setStroke()
        NSColor.labelColor.setFill()

        let line = NSBezierPath()
        line.lineWidth = 1.8
        line.lineCapStyle = .round
        line.move(to: NSPoint(x: 3, y: 5))
        line.curve(to: NSPoint(x: 15, y: 13), controlPoint1: NSPoint(x: 6, y: 15), controlPoint2: NSPoint(x: 11, y: 3))
        line.stroke()

        let dock = NSBezierPath(roundedRect: NSRect(x: 3, y: 3, width: 12, height: 4), xRadius: 1.5, yRadius: 1.5)
        dock.lineWidth = 1.5
        dock.stroke()

        NSBezierPath(ovalIn: NSRect(x: 12.5, y: 11.5, width: 4, height: 4)).fill()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
