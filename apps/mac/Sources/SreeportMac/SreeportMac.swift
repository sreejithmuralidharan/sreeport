import AppKit
import SwiftUI

@main
struct SreeportMacApp: App {
    @StateObject private var model = SreeportModel()

    var body: some Scene {
        MenuBarExtra {
            SreeportMenu(model: model)
                .frame(width: 360)
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

    private var filteredProjects: [ProjectStatus] {
        if query.isEmpty { return model.projects }
        return model.projects.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.domain.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Sreeport")
                        .font(.headline)
                    Text(model.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    model.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh")
            }

            TextField("Search projects", text: $query)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Start All") { model.run("start", "all") }
                Button("Stop All") { model.run("stop", "all") }
                Button("Proxy") { model.run("proxy", "restart") }
            }

            Divider()

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(filteredProjects) { project in
                        ProjectRow(project: project, model: model)
                    }
                }
            }
            .frame(maxHeight: 420)

            if let error = model.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(3)
            }
        }
        .padding(14)
    }
}

struct ProjectRow: View {
    let project: ProjectStatus
    @ObservedObject var model: SreeportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(project.listening ? Color.green : (project.running ? Color.orange : Color.gray))
                    .frame(width: 9, height: 9)
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.system(size: 13, weight: .semibold))
                    Text(project.domain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(project.port))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Start") { model.run("start", project.name) }
                Button("Stop") { model.run("stop", project.name) }
                Button("Restart") { model.run("restart", project.name) }
                Button("Open") { model.run("open", project.name) }
                Button("Logs") { model.run("logs", project.name) }
            }
            .font(.caption)
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
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

    var summary: String {
        if projects.isEmpty { return "No project config loaded" }
        let running = projects.filter(\.running).count
        return "\(running) of \(projects.count) running"
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
        } catch {
            self.error = error.localizedDescription
        }
    }

    func run(_ args: String...) {
        let result = runSreeport(args)
        if result.exitCode != 0 {
            error = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            error = nil
        }
        refresh()
    }

    private func runSreeport(_ args: [String]) -> CommandResult {
        let process = Process()
        let cli = resolveSreeportCLI()
        process.executableURL = URL(fileURLWithPath: cli.executable)
        process.arguments = cli.arguments + args
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
}

struct CommandResult {
    let exitCode: Int32
    let output: String
}

struct StatusResponse: Decodable {
    let projects: [ProjectStatus]
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
