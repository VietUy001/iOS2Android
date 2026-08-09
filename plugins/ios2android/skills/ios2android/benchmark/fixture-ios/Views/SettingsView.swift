import SwiftUI

struct SettingsView: View {
    @AppStorage("settings.darkMode") private var darkMode = false
    @AppStorage("settings.language") private var language = "vi"

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle(LocalizedStringKey("settings.darkMode"), isOn: $darkMode)
                    Picker(LocalizedStringKey("settings.language"), selection: $language) {
                        Text("Tiếng Việt").tag("vi")
                        Text("English").tag("en")
                    }
                }
                Section {
                    HStack {
                        Text(LocalizedStringKey("settings.version"))
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("settings.title"))
        }
    }
}
