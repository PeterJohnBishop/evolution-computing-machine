import SwiftUI
import SwiftData

@main
struct evolution_computing_machine_swiftuiApp: App {
    
    @StateObject private var socketManager = WebSocketManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Message.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MessageView()
        }
        .environmentObject(socketManager)
        .modelContainer(sharedModelContainer)
    }
}
