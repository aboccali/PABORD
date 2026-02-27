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
            if appStateManager.isLoggedIn {
                QuestionnaireView()
                    .environmentObject(appStateManager)
            } else {
                LoginView()
                    .environmentObject(appStateManager)
            }
        }
        .onAppear {
            print("🎬 ContentView appeared")
            print("   - isLoggedIn: \(appStateManager.isLoggedIn)")
            print("   - currentUserCode: \(String(describing: appStateManager.currentUserCode))")
        }
    }
}
