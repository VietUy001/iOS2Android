import SwiftUI

struct HomeView: View {
    @StateObject private var store = ItemStore()
    @State private var showAddSheet = false
    @State private var addButtonScale: CGFloat = 1.0
    @State private var draftName = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(store.items) { item in
                    HStack {
                        Circle()
                            .fill(Color.fixtureAccent)
                            .frame(width: 10, height: 10)
                        Text(item.name)
                        Spacer()
                        Text(item.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("home.title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Animation: nút Add scale bump (spring) trước khi mở sheet
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                            addButtonScale = 1.3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation(.spring()) { addButtonScale = 1.0 }
                            showAddSheet = true
                        }
                    } label: {
                        Label(LocalizedStringKey("home.addButton"), systemImage: "plus.circle.fill")
                    }
                    .scaleEffect(addButtonScale)
                }
            }
            // Flow nhiều bước: bấm Add → sheet detail → nhập tên → Save → persist
            .sheet(isPresented: $showAddSheet) {
                NavigationView {
                    Form {
                        TextField(LocalizedStringKey("home.detail.namePlaceholder"), text: $draftName)
                    }
                    .navigationTitle(LocalizedStringKey("home.detail.title"))
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(LocalizedStringKey("home.detail.save")) {
                                store.add(name: draftName)
                                draftName = ""
                                showAddSheet = false
                            }
                            .disabled(draftName.isEmpty)
                        }
                    }
                }
            }
        }
    }
}
