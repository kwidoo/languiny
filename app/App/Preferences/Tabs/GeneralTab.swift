import SwiftUI
import AppKit

struct GeneralTab: View {
    @EnvironmentObject var settings: SettingsViewModel
    @State private var sources: [KeyboardInputSource] = []
    @State private var mappings: [Mapping] = []
    @State private var appMode: AppListMode = .blacklist
    @State private var appText: String = ""

    struct Mapping: Identifiable, Equatable {
        let id = UUID()
        var language: String
        var layoutID: String
    }

    enum AppListMode: String, CaseIterable, Identifiable {
        case whitelist
        case blacklist
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            Form {
                Section("Layout Pair") {
                    Picker("From", selection: Binding(
                        get: { settings.settings.layouts.pair.fromID },
                        set: { newValue in settings.update { $0.layouts.pair.fromID = newValue } }
                    )) {
                        ForEach(sources) { src in
                            Text(src.name).tag(src.id)
                        }
                    }
                    Picker("To", selection: Binding(
                        get: { settings.settings.layouts.pair.toID },
                        set: { newValue in settings.update { $0.layouts.pair.toID = newValue } }
                    )) {
                        ForEach(sources) { src in
                            Text(src.name).tag(src.id)
                        }
                    }
                }

                Section("Active layouts") {
                    ForEach(sources) { src in
                        Toggle(src.name, isOn: Binding(
                            get: { settings.settings.layouts.active.contains(src.id) },
                            set: { value in
                                settings.update { st in
                                    var set = Set(st.layouts.active)
                                    if value { set.insert(src.id) } else { set.remove(src.id) }
                                    st.layouts.active = Array(set)
                                }
                            }
                        ))
                    }
                }

                Section("Language → Layout") {
                    ForEach($mappings) { $mapping in
                        HStack {
                            TextField("Language", text: $mapping.language)
                            Picker("Layout", selection: $mapping.layoutID) {
                                ForEach(sources) { src in
                                    Text(src.name).tag(src.id)
                                }
                            }
                            Button(action: {
                                if let idx = mappings.firstIndex(where: { $0.id == mapping.id }) {
                                    mappings.remove(at: idx)
                                    saveMappings()
                                }
                            }) {
                                Image(systemName: "minus.circle")
                            }
                        }
                    }
                    Button("Add Mapping") {
                        mappings.append(Mapping(language: "", layoutID: sources.first?.id ?? ""))
                        saveMappings()
                    }
                }

                Section("Behavior") {
                    Toggle("Auto-fix on word boundary", isOn: Binding(
                        get: { settings.settings.retro.enabled },
                        set: { newValue in settings.update { $0.retro.enabled = newValue } }
                    ))
                    Toggle("Ignore URLs and emails", isOn: Binding(
                        get: { settings.settings.rules.ignoreUrlsEmails },
                        set: { newValue in settings.update { $0.rules.ignoreUrlsEmails = newValue } }
                    ))
                    Toggle("Bypass Option key", isOn: Binding(
                        get: { settings.settings.switching.bypassOption },
                        set: { newValue in settings.update { $0.switching.bypassOption = newValue } }
                    ))
                }

                Section("Apps") {
                    Picker("Mode", selection: $appMode) {
                        Text("Whitelist").tag(AppListMode.whitelist)
                        Text("Blacklist").tag(AppListMode.blacklist)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    TextEditor(text: $appText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 80)
                }
            }
            .padding()

            HStack {
                Button("Import…") { importPrefs() }
                Button("Export…") { exportPrefs() }
                Spacer()
            }
            .padding()
        }
        .onAppear { load() }
        .onChange(of: mappings) { _ in saveMappings() }
        .onChange(of: appMode) { _ in saveApps() }
        .onChange(of: appText) { _ in saveApps() }
    }

    private func load() {
        sources = InputSourcesService.shared.list()
        mappings = settings.settings.layouts.languageMap.map { Mapping(language: $0.key, layoutID: $0.value) }
        if !settings.settings.apps.whitelist.isEmpty {
            appMode = .whitelist
            appText = settings.settings.apps.whitelist.joined(separator: "\n")
        } else {
            appMode = .blacklist
            appText = settings.settings.apps.blacklist.joined(separator: "\n")
        }
    }

    private func saveMappings() {
        let dict = Dictionary(uniqueKeysWithValues: mappings.map { ($0.language, $0.layoutID) })
        settings.update { $0.layouts.languageMap = dict }
    }

    private func saveApps() {
        let list = appText.split(whereSeparator: { $0.isNewline })
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        settings.update { s in
            switch appMode {
            case .whitelist:
                s.apps.whitelist = list
                s.apps.blacklist = []
            case .blacklist:
                s.apps.blacklist = list
                s.apps.whitelist = []
            }
        }
    }

    private func exportPrefs() {
        guard let data = settings.exportData() else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "languiny_prefs.json"
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }

    private func importPrefs() {
        let panel = NSOpenPanel()
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
            settings.importData(data)
            load()
        }
    }
}
