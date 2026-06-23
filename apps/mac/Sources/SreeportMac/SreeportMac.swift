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
    @State private var projectFilter: ProjectFilter = .all

    private var filteredProjects: [ProjectStatus] {
        let searched = query.isEmpty
            ? model.projects
            : model.projects.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.domain.localizedCaseInsensitiveContains(query) }
        return searched.filter(projectFilter.matches)
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

            ActionBar(model: model)

            HStack {
                Text("Projects")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(model.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProjectFilterTabs(selection: $projectFilter, projects: model.projects)

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
            IconButton(systemName: "arrow.clockwise", help: "Refresh", isLoading: model.isRunning("refresh")) {
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

enum ProjectFilter: String, CaseIterable, Identifiable {
    case all
    case live
    case stopped
    case issues

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .live: return "Live"
        case .stopped: return "Stopped"
        case .issues: return "Issues"
        }
    }

    func count(in projects: [ProjectStatus]) -> Int {
        projects.filter(matches).count
    }

    func matches(_ project: ProjectStatus) -> Bool {
        switch self {
        case .all:
            return true
        case .live:
            return project.listening
        case .stopped:
            return !project.running && !project.listening
        case .issues:
            return project.running && !project.listening
        }
    }
}

struct ProjectFilterTabs: View {
    @Binding var selection: ProjectFilter
    let projects: [ProjectStatus]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ProjectFilter.allCases) { filter in
                Button {
                    selection = filter
                } label: {
                    HStack(spacing: 5) {
                        Text(filter.title)
                        Text("\(filter.count(in: projects))")
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(selection == filter ? Color.white.opacity(0.85) : Color.secondary)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection == filter ? Color.white : Color.primary)
                .background(selection == filter ? Color.accentColor : Color(nsColor: .quaternaryLabelColor).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .help("Show \(filter.title.lowercased()) projects")
            }
        }
    }
}

struct ActionBar: View {
    @ObservedObject var model: SreeportModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                PrimaryActionButton(title: "Start All", systemName: "play.fill", tone: .green, isLoading: model.isRunning("start all")) {
                    model.run("start", "all")
                }
                PrimaryActionButton(title: "Stop All", systemName: "stop.fill", tone: .red, isLoading: model.isRunning("stop all")) {
                    model.run("stop", "all")
                }
                PrimaryActionButton(title: "Restart All", systemName: "arrow.clockwise", tone: .blue, isLoading: model.isRunning("restart all")) {
                    model.run("restart", "all")
                }
            }

            ProxyControlCard(model: model)
            WorkspaceToolsPanel(model: model)
        }
    }
}

struct ProxyControlCard: View {
    @ObservedObject var model: SreeportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(model.proxyRunning ? Color.green.opacity(0.14) : Color.orange.opacity(0.14))
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(model.proxyRunning ? Color.green : Color.orange)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Local Proxy")
                        .font(.caption.weight(.semibold))
                    Text(model.proxyRunning ? "Caddy is routing .localhost domains" : "Proxy is stopped")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusPill(text: model.proxyLabel, color: model.proxyRunning ? .green : .orange)
            }

            HStack(spacing: 8) {
                CompactActionButton(title: "Restart", systemName: "arrow.clockwise", tone: .blue, isLoading: model.isRunning("proxy restart")) {
                    model.run("proxy", "restart")
                }
                CompactActionButton(title: "Status", systemName: "wave.3.right", tone: .primary, subtle: true, isLoading: model.isRunning("proxy status")) {
                    model.capture("proxy", "status")
                    model.refreshProxy()
                }
                CompactActionButton(title: "Write Config", systemName: "doc.badge.gearshape", tone: .primary, subtle: true, isLoading: model.isRunning("proxy write")) {
                    model.capture("proxy", "write")
                    model.refreshProxy()
                }
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke((model.proxyRunning ? Color.green : Color.orange).opacity(0.16), lineWidth: 1)
        )
    }
}

struct WorkspaceToolsPanel: View {
    @ObservedObject var model: SreeportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Quick Tools", systemImage: "slider.horizontal.3")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(model.workspaceLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack(spacing: 8) {
                UtilityButton(title: "Open Folder", systemName: "folder", isLoading: model.isRunning("open workspace")) {
                    model.openWorkspace()
                }
                UtilityButton(title: "Config", systemName: "doc.text", isLoading: model.isRunning("open config")) {
                    model.openConfig()
                }
                UtilityButton(title: "Doctor", systemName: "stethoscope", isLoading: model.isRunning("doctor")) {
                    model.capture("doctor")
                    model.refreshProxy()
                }
            }

            HStack(spacing: 8) {
                UtilityButton(title: "Copy Status", systemName: "doc.on.doc", isLoading: model.isRunning("copy status")) {
                    model.copyStatus()
                }
                UtilityButton(title: "Refresh", systemName: "arrow.clockwise", isLoading: model.isRunning("refresh")) {
                    model.refresh()
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
                    StatusPill(text: project.stateLabel, color: project.stateColor)
                    Text(":\(project.port)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 7) {
                MiniActionButton(title: "Open", systemName: "safari", tone: .blue, isLoading: model.isRunning("open \(project.name)")) { model.run("open", project.name) }
                MiniActionButton(title: "Start", systemName: "play.fill", tone: .green, isLoading: model.isRunning("start \(project.name)")) { model.run("start", project.name) }
                MiniActionButton(title: "Restart", systemName: "arrow.clockwise", tone: .blue, isLoading: model.isRunning("restart \(project.name)")) { model.run("restart", project.name) }
                MiniActionButton(title: "Stop", systemName: "stop.fill", tone: .red, isLoading: model.isRunning("stop \(project.name)")) { model.run("stop", project.name) }
                MiniIconButton(systemName: "doc.text.magnifyingglass", help: "Show logs for \(project.name)", isLoading: model.isRunning("logs \(project.name)")) { model.capture("logs", project.name) }
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

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemName: String
    let tone: Color
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                LoadingIcon(systemName: systemName, isLoading: isLoading)
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
        .disabled(isLoading)
        .opacity(isLoading ? 0.78 : 1)
        .background(tone.opacity(0.11), in: RoundedRectangle(cornerRadius: 11))
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(tone.opacity(0.16), lineWidth: 1)
        )
        .help(title)
    }
}

struct CompactActionButton: View {
    let title: String
    let systemName: String
    let tone: Color
    var subtle = false
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                LoadingIcon(systemName: systemName, isLoading: isLoading, size: 12)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.caption.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.78 : 1)
        .foregroundStyle(tone)
        .background(tone.opacity(subtle ? 0.08 : 0.11), in: RoundedRectangle(cornerRadius: 9))
        .help(title)
    }
}

struct UtilityButton: View {
    let title: String
    let systemName: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                LoadingIcon(systemName: systemName, isLoading: isLoading)
                Text(title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.78 : 1)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
        .help(title)
    }
}

struct MiniActionButton: View {
    let title: String
    let systemName: String
    let tone: Color
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                LoadingIcon(systemName: systemName, isLoading: isLoading, size: 11)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.78 : 1)
        .foregroundStyle(tone)
        .background(tone.opacity(0.11), in: RoundedRectangle(cornerRadius: 7))
        .help(title)
    }
}

struct IconButton: View {
    let systemName: String
    let help: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LoadingIcon(systemName: systemName, isLoading: isLoading, size: 15)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.78 : 1)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
        .help(help)
    }
}

struct MiniIconButton: View {
    let systemName: String
    let help: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LoadingIcon(systemName: systemName, isLoading: isLoading, size: 12)
                .frame(width: 26, height: 24)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.78 : 1)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 7))
        .help(help)
    }
}

struct LoadingIcon: View {
    let systemName: String
    let isLoading: Bool
    var size: CGFloat = 13

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.55)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: size, weight: .semibold))
            }
        }
        .frame(width: 16, height: 16)
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
                HStack(spacing: 6) {
                    if model.isBusy {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.55)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: model.error == nil ? "terminal" : "exclamationmark.triangle")
                    }
                    Text(model.outputTitle)
                }
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

            if model.isBusy {
                ProgressView()
                    .progressViewStyle(.linear)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
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
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(nsImage: SreeportIcon.menuBarImage())
                    .resizable()
                    .frame(width: 26, height: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sreeport Settings")
                        .font(.title2.bold())
                    Text("Workspace, proxy, and diagnostics")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                SettingsInfoRow(label: "Workspace", value: model.workspaceLabel, systemName: "folder")
                SettingsInfoRow(label: "Proxy", value: model.proxyLabel, systemName: "point.3.connected.trianglepath.dotted")
                SettingsInfoRow(label: "Projects", value: "\(model.runningCount) of \(model.projects.count) running", systemName: "list.bullet.rectangle")
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                CompactActionButton(title: "Open Folder", systemName: "folder", tone: .blue, isLoading: model.isRunning("open workspace")) {
                    model.openWorkspace()
                }
                CompactActionButton(title: "Open Config", systemName: "doc.text", tone: .blue, isLoading: model.isRunning("open config")) {
                    model.openConfig()
                }
                CompactActionButton(title: "Run Doctor", systemName: "stethoscope", tone: .orange, isLoading: model.isRunning("doctor")) {
                    model.capture("doctor")
                }
            }

            HStack(spacing: 10) {
                CompactActionButton(title: "Restart Proxy", systemName: "arrow.clockwise", tone: .green, isLoading: model.isRunning("proxy restart")) {
                    model.run("proxy", "restart")
                }
                CompactActionButton(title: "Copy Status", systemName: "doc.on.doc", tone: .primary, subtle: true, isLoading: model.isRunning("copy status")) {
                    model.copyStatus()
                }
                CompactActionButton(title: "Refresh", systemName: "arrow.clockwise.circle", tone: .primary, subtle: true, isLoading: model.isRunning("refresh")) {
                    model.refresh()
                }
            }

            OutputPanel(model: model)
            Spacer()
        }
        .padding(24)
        .frame(width: 560, height: 430)
        .onAppear {
            model.refresh()
        }
    }
}

struct SettingsInfoRow: View {
    let label: String
    let value: String
    let systemName: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 18)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption.weight(.semibold))
                .frame(width: 76, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
    }
}

final class SreeportModel: ObservableObject {
    @Published var projects: [ProjectStatus] = []
    @Published var error: String?
    @Published var commandOutput: String?
    @Published var outputTitle = "Output"
    @Published var proxyRunning = false
    @Published var proxyPid: Int?
    @Published private var activeCommands: Set<String> = []

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

    var isBusy: Bool {
        !activeCommands.isEmpty
    }

    func isRunning(_ command: String) -> Bool {
        activeCommands.contains(command)
    }

    func refresh() {
        refreshStatus(showActivity: true)
    }

    func run(_ args: String...) {
        let command = args.joined(separator: " ")
        begin(command, message: "Running: sreeport \(command)")
        executeSreeport(args) { result in
            self.finish(command)
            self.handle(result, command: command)
            self.refreshStatus(showActivity: false)
        }
    }

    func capture(_ args: String...) {
        let command = args.joined(separator: " ")
        begin(command, message: "Running: sreeport \(command)")
        executeSreeport(args) { result in
            self.finish(command)
            self.handle(result, command: command)
        }
    }

    func refreshProxy() {
        refreshProxyStatus(showActivity: false)
    }

    private func refreshStatus(showActivity: Bool) {
        let command = "refresh"
        if showActivity {
            begin(command, message: "Refreshing Sreeport status")
        }
        executeSreeport(["status", "--json"]) { result in
            if showActivity {
                self.finish(command)
            }
            guard result.exitCode == 0 else {
                if showActivity {
                    self.error = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.projects = []
                }
                return
            }
            do {
                let data = Data(result.output.utf8)
                let decoded = try JSONDecoder().decode(StatusResponse.self, from: data)
                self.projects = decoded.projects
                if showActivity {
                    self.error = nil
                    self.commandOutput = "Status refreshed."
                    self.outputTitle = "refresh"
                }
                self.refreshProxyStatus(showActivity: false)
            } catch {
                if showActivity {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    private func refreshProxyStatus(showActivity: Bool) {
        let command = "proxy status"
        if showActivity {
            begin(command, message: "Checking proxy status")
        }
        executeSreeport(["proxy", "status", "--json"]) { result in
            if showActivity {
                self.finish(command)
            }
            guard result.exitCode == 0,
                  let data = result.output.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(ProxyStatus.self, from: data) else {
                self.proxyRunning = false
                self.proxyPid = nil
                return
            }
            self.proxyRunning = decoded.running
            self.proxyPid = decoded.pid
        }
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
        openPath(workspace, command: "open workspace")
    }

    func openConfig() {
        guard let workspace = resolveWorkspace() else {
            error = "Workspace path is not configured."
            return
        }
        openPath("\(workspace)/sreeport.config.ts", command: "open config")
    }

    func copyStatus() {
        let command = "copy status"
        begin(command, message: "Copying current status")
        executeSreeport(["status"]) { result in
            self.finish(command)
            if result.exitCode == 0 {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result.output, forType: .string)
                self.commandOutput = "Copied current status to clipboard."
                self.error = nil
            } else {
                self.error = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
                self.commandOutput = nil
            }
            self.outputTitle = command
        }
    }

    private func openPath(_ path: String, command: String) {
        begin(command, message: "Opening \(path)")
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = [path]
            let result: CommandResult
            do {
                try process.run()
                result = CommandResult(exitCode: 0, output: "Opened \(path)")
            } catch {
                result = CommandResult(exitCode: 1, output: error.localizedDescription)
            }
            DispatchQueue.main.async {
                self.finish(command)
                self.handle(result, command: command)
            }
        }
    }

    private func begin(_ command: String, message: String) {
        activeCommands.insert(command)
        outputTitle = command
        commandOutput = message
        error = nil
    }

    private func finish(_ command: String) {
        activeCommands.remove(command)
    }

    private func handle(_ result: CommandResult, command: String) {
        if result.exitCode != 0 {
            error = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            commandOutput = nil
        } else {
            error = nil
            commandOutput = normalizedOutput(result.output, command: command)
        }
        outputTitle = command
    }

    private func normalizedOutput(_ output: String, command: String) -> String {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return "Completed: sreeport \(command)"
    }

    private func executeSreeport(_ args: [String], completion: @escaping (CommandResult) -> Void) {
        let cli = resolveSreeportCLI()
        let workspace = resolveWorkspace()
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Self.runSreeport(args, cli: cli, workspace: workspace)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    private static func runSreeport(_ args: [String], cli: (executable: String, arguments: [String]), workspace: String?) -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cli.executable)
        process.arguments = cli.arguments + args
        if let workspace {
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
