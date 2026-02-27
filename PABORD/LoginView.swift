// LoginView.swift
// PABORD
//
// Created by Neuroinformatica on 27/05/25.
//

// prova git

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var userCode: String = ""
    @State private var accessCode: String = ""
    @State private var showingLoginErrorAlert = false
    @State private var loginErrorMessage: String = "Codice utente o codice d'accesso errati."
    @State private var isLoading: Bool = false

    var body: some View {
        ZStack {
            Image("sfondo")
                .resizable()
                .ignoresSafeArea()

            VStack {
                Text("Benvenuta in PABORD")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.orange)
                    .padding(.top, 200)

                Spacer()
                    .frame(height: 40)

                VStack(spacing: 10) {
                    TextField("Codice utente", text: $userCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("Codice d'accesso", text: $accessCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button {
                        authenticateUser()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Accedi")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(isLoading)
                }

                Spacer()
            }
        }
        .alert("Errore di accesso", isPresented: $showingLoginErrorAlert) {
            Button("OK") { }
        } message: {
            Text(loginErrorMessage)
        }
    }

    private func authenticateUser() {
        isLoading = true

        if userCode.lowercased() == "demo" && accessCode.lowercased() == "demo" {
            // ✅ MODALITÀ DEMO
            print("🎮 Login DEMO")
            
            // ✅ ORDINE CRITICO: salva PRIMA currentUserCode, POI isTestMode, POI isLoggedIn
            appStateManager.currentUserCode = "Demo"
            appStateManager.isTestMode = true
            appStateManager.isLoggedIn = true
            
            print("✅ DEMO salvato:")
            print("   - currentUserCode: \(String(describing: appStateManager.currentUserCode))")
            print("   - isTestMode: \(appStateManager.isTestMode)")
            print("   - isLoggedIn: \(appStateManager.isLoggedIn)")
            
            // Schedula notifica demo dopo 5 minuti
            NotificationManager.shared.scheduleDemoNotification()
            
            isLoading = false
            
        } else {
            // ✅ MODALITÀ NORMALE
            print("🔐 Login NORMALE per utente: \(userCode)")
            
            NetworkManager.shared.authenticateAndFetchNotificationTimes(userCode: userCode, accessCode: accessCode) { success, notifications, errorMessage in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if success, let _ = notifications {
                        // ✅ ORDINE CRITICO: salva PRIMA currentUserCode, POI isTestMode, POI isLoggedIn
                        self.appStateManager.currentUserCode = self.userCode
                        self.appStateManager.isTestMode = false
                        self.appStateManager.isLoggedIn = true
                        
                        print("✅ Login riuscito:")
                        print("   - currentUserCode: \(String(describing: self.appStateManager.currentUserCode))")
                        print("   - isTestMode: \(self.appStateManager.isTestMode)")
                        print("   - isLoggedIn: \(self.appStateManager.isLoggedIn)")
                        
                        // Aggiorna device token per notifiche push
                        NetworkManager.shared.updateDeviceTokenOnLogin(userCode: self.userCode)
                        
                    } else {
                        self.loginErrorMessage = errorMessage ?? "Codice utente o codice d'accesso errati."
                        self.showingLoginErrorAlert = true
                        print("❌ Errore di autenticazione: \(errorMessage ?? "Sconosciuto")")
                    }
                }
            }
        }
    }
}
