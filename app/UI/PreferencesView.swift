import AppKit
import SwiftUI
import UniformTypeIdentifiers

final class PreferencesViewModel: ObservableObject {
    @Published var layouts: [InputSourceInfo] = listInputSources()
    @Published var fromID: String
    @Published var toID: String
    @Published var autoFix: Bool
    @Published var ignoreURLs: Bool
    @Published var bypassOption: Bool
    @Published var appListMode: AppListMode
    @Published var appListText: String

    init() {
        let pair = loadLayoutPair()
        self.fromID = pair?.fromID ?? ""
        self.toID = pair?.toID ?? ""
        self.autoFix = autoFixEnabled()
        self.ignoreURLs = shouldIgnoreUrlsEmails()
        self.bypassOption = shouldBypassOption()
        self.appListMode = loadAppListMode()
        self.appListText = loadAppList().joined(separator: "\n")
    }

    private func saveLayoutPair() {
        let pair = LayoutPair(fromID: fromID, toID: toID)
        Languiny.saveLayoutPair(pair)
    }

    private func saveBehavior() {
        setAutoFixEnabled(autoFix)
        setIgnoreUrlsEmails(ignoreURLs)
        setBypassOption(bypassOption)
    }

    private func saveApps() {
        saveAppListMode(appListMode)
        let ids =
            appListText
            .split(whereSeparator: { $0.isNewline })
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        saveAppList(Set(ids))
    }

    func exportPrefs() {
        guard let data = exportPreferences() else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "languiny_prefs.json"

        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [UTType.json]
        } else {
            panel.allowedFileTypes = ["json"]
        }
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }

    func importPrefs() {
        let panel = NSOpenPanel()

        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [UTType.json]
        } else {
            panel.allowedFileTypes = ["json"]
        }
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
            importPreferences(data: data)
            // Reload from defaults
            let pair = loadLayoutPair()
            fromID = pair?.fromID ?? ""
            toID = pair?.toID ?? ""
            autoFix = autoFixEnabled()
            ignoreURLs = shouldIgnoreUrlsEmails()
            bypassOption = shouldBypassOption()
            appListMode = loadAppListMode()
            appListText = loadAppList().joined(separator: "\n")
        }
    }

    func onLayoutChange() { saveLayoutPair() }
    func onBehaviorChange() { saveBehavior() }
    func onAppsChange() { saveApps() }
}

struct PreferencesView: View {
    @StateObject private var model = PreferencesViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            Form {
                Section("Layout Pair") {
                    Picker("From", selection: $model.fromID) {
                        ForEach(model.layouts) { layout in
                            Text(layout.name).tag(layout.id)
                        }
                    }
                    .onChange(of: model.fromID) { _ in model.onLayoutChange() }

                    Picker("To", selection: $model.toID) {
                        ForEach(model.layouts) { layout in
                            Text(layout.name).tag(layout.id)
                        }
                    }
                    .onChange(of: model.toID) { _ in model.onLayoutChange() }
                }

                Section("Behavior") {
                    Toggle("Auto-fix on word boundary", isOn: $model.autoFix)
                        .onChange(of: model.autoFix) { _ in model.onBehaviorChange() }
                    Toggle("Ignore URLs and emails", isOn: $model.ignoreURLs)
                        .onChange(of: model.ignoreURLs) { _ in model.onBehaviorChange() }
                    Toggle("Bypass Option key", isOn: $model.bypassOption)
                        .onChange(of: model.bypassOption) { _ in model.onBehaviorChange() }
                }

                Section("Apps") {
                    Picker("Mode", selection: $model.appListMode) {
                        Text("Whitelist").tag(AppListMode.whitelist)
                        Text("Blacklist").tag(AppListMode.blacklist)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: model.appListMode) { _ in model.onAppsChange() }
                    TextEditor(text: $model.appListText)
                        .frame(minHeight: 80)
                        .onChange(of: model.appListText) { _ in model.onAppsChange() }
                }
            }
            HStack {
                Button("Import…") { model.importPrefs() }
                Button("Export…") { model.exportPrefs() }
                Spacer()
            }
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}
