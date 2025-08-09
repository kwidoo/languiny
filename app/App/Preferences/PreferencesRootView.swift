import SwiftUI

/// Root of the tabbed preferences window. Add a new tab by
/// extending the `Tab` enum and inserting a corresponding view
/// in the `TabView` below.
struct PreferencesRootView: View {
    @StateObject private var settings = SettingsViewModel()

    enum Tab: String, CaseIterable, Identifiable {
        case general
        case detection
        case switching
        case rules
        case hotkeys
        case logging
        case learning
        case profiles

        var id: String { rawValue }
        var title: String {
            switch self {
            case .general: return "General"
            case .detection: return "Detection"
            case .switching: return "Switching"
            case .rules: return "Rules"
            case .hotkeys: return "Hotkeys"
            case .logging: return "Logging"
            case .learning: return "Learning"
            case .profiles: return "Profiles"
            }
        }
        var systemImage: String {
            switch self {
            case .general: return "gearshape"
            case .detection: return "eye"
            case .switching: return "arrow.triangle.2.circlepath"
            case .rules: return "list.bullet"
            case .hotkeys: return "command"
            case .logging: return "doc.text"
            case .learning: return "graduationcap"
            case .profiles: return "person.2"
            }
        }
    }

    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(Tab.general)
            // Placeholders for future tabs
            ForEach([Tab.detection, .switching, .rules, .hotkeys, .logging, .learning, .profiles], id: \.self) { tab in
                Text("Coming Soon")
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .tag(tab)
            }
        }
        .environmentObject(settings)
        .frame(minWidth: 560, minHeight: 400)
        .padding()
    }
}
