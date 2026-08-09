import SwiftUI

// Fixture app cho benchmark process-compliance — KHÔNG cần build được,
// chỉ là input port có cấu trúc biết trước.
@main
struct FixtureApp: App {
    @AppStorage("settings.darkMode") private var darkMode = false

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label(LocalizedStringKey("tab.home"), systemImage: "house.fill")
                    }
                    .tag(0)
                SettingsView()
                    .tabItem {
                        Label(LocalizedStringKey("tab.settings"), systemImage: "gearshape.fill")
                    }
                    .tag(1)
            }
            .preferredColorScheme(darkMode ? .dark : .light)
            .tint(.fixtureAccent)
        }
    }
}

extension Color {
    // Asset color định nghĩa trong CODE (không có Assets.xcassets) — #FF6B35
    static let fixtureAccent = Color(red: 1.0, green: 0.42, blue: 0.208)
}
