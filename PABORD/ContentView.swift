//
//  ContentView.swift
//  PABORD
//
//  Created by Neuroinformatica on 05/06/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var appStateManager = AppStateManager.shared

    var body: some View {
        Group {
            if !appStateManager.isLoggedIn {
                LoginView()
                    .environmentObject(appStateManager)
            } else if !appStateManager.hasSeenNotificationPrompt {
                NotificationPermissionView()
                    .environmentObject(appStateManager)
            } else if appStateManager.hasNotificationsDenied {
                // L'utente ha negato il consenso alle notifiche: non può partecipare
                NotificationDeniedView()
                    .environmentObject(appStateManager)
            } else {
                QuestionnaireView()
                    .environmentObject(appStateManager)
                    .onAppear {
                        // Avvia il polling quando l'utente entra nella schermata principale
                        appStateManager.startSessionPolling()
                    }
            }
        }
        .onAppear {
            print("🎬 ContentView appeared")
            print("   - isLoggedIn: \(appStateManager.isLoggedIn)")
            print("   - hasSeenNotificationPrompt: \(appStateManager.hasSeenNotificationPrompt)")
            print("   - hasNotificationsDenied: \(appStateManager.hasNotificationsDenied)")
            print("   - currentUserCode: \(String(describing: appStateManager.currentUserCode))")
        }
    }
}
