// NotificationPermissionView.swift
// PABORD
//
// Created by Neuroinformatica on 23/05/25.
//

import SwiftUI

// MARK: - Schermata di rifiuto notifiche

struct NotificationDeniedView: View {
    @EnvironmentObject var appStateManager: AppStateManager

    var body: some View {
        ZStack {
            Image("sfondo")
                .resizable()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icona
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.gray)
                    .padding(.bottom, 32)

                // Titolo
                Text("Partecipazione non possibile")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)

                // Messaggio
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                        Text("Hai scelto di non abilitare le notifiche. Senza di esse NON è possibile partecipare allo studio, poiché i questionari vengono attivati tramite notifiche PUSH.")
                            .foregroundColor(.primary)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                        Text("L'app non invierà alcuna notifica. Se desideri partecipare, puoi abilitare le notifiche per PABORD nelle Impostazioni di sistema e poi effettuare nuovamente il login.")
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.85))
                .cornerRadius(16)
                .padding(.horizontal, 24)

                Spacer()

                // Tasto per aprire le Impostazioni di sistema
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Apri Impostazioni")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.gray.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Tasto logout
                Button {
                    appStateManager.logout()
                } label: {
                    Text("Esci")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.clear)
                .foregroundColor(.gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Schermata di richiesta permesso notifiche

struct NotificationPermissionView: View {
    @EnvironmentObject var appStateManager: AppStateManager

    var body: some View {
        ZStack {
            Image("sfondo")
                .resizable()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icona campana
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.orange)
                    .padding(.bottom, 32)

                // Titolo
                Text("Abilita le notifiche")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)

                // Corpo del messaggio
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        Text("PABORD utilizza le notifiche PUSH per avvisarti quando è il momento di compilare un questionario.")
                            .foregroundColor(.primary)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        Text("Senza notifiche l'app non potrà funzionare correttamente e potresti perdere sessioni importanti.")
                            .foregroundColor(.primary)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        Text("Le notifiche vengono inviate solo nei momenti stabiliti dal protocollo di ricerca.")
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.85))
                .cornerRadius(16)
                .padding(.horizontal, 24)

                Spacer()

                // Tasto Consenti
                Button {
                    allowNotifications()
                } label: {
                    Text("Consenti notifiche")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                // Tasto Nega
                Button {
                    denyNotifications()
                } label: {
                    Text("Non consentire")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.clear)
                .foregroundColor(.gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private func allowNotifications() {
        if appStateManager.isTestMode {
            // Modalità DEMO: richiedi permessi e poi schedula la notifica demo 5 sec dopo il consenso
            NotificationManager.shared.requestPermissionThenScheduleDemo()
        } else {
            // Modalità normale: richiedi solo i permessi push
            NotificationManager.shared.requestNotificationPermission()
        }

        // Segna che l'utente ha visto (e interagito con) questa schermata
        // hasNotificationsDenied rimane false → flusso normale
        appStateManager.hasSeenNotificationPrompt = true
    }

    private func denyNotifications() {
        // Segna che il permesso è stato esplicitamente negato
        appStateManager.hasSeenNotificationPrompt = true
        appStateManager.hasNotificationsDenied = true
    }
}
