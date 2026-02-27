// PABORDApp.swift
// PABORD
//
// Created by Neuroinformatica on 23/05/25.
//

import SwiftUI
import UserNotifications

@main
struct PABORDApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var appStateManager = AppStateManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appStateManager)
        }
    }
}

/// AppDelegate per configurare notifiche push e gestire la sincronizzazione
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Imposta il delegato delle notifiche
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        // Richiedi permessi per notifiche push
        NotificationManager.shared.requestNotificationPermission()
        
        // Registra l'app per ricevere notifiche push remote
        application.registerForRemoteNotifications()
        
        // 🧹 Pulizia sessioni scadute vecchie (oltre 7 giorni)
        AppStateManager.shared.cleanupOldExpiredSessions()
        
        // Sincronizzazione all'avvio
        NetworkManager.shared.synchronizeSavedData { success, message in
            if success {
                print("Sincronizzazione all'avvio completata: \(message)")
            } else {
                print("Sincronizzazione all'avvio fallita: \(message)")
            }
        }
        
        return true
    }
    
    // MARK: - Gestione Device Token (FONDAMENTALE per Push Notifications)
    
    /// Chiamato quando la registrazione per le notifiche push ha successo
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Converti il token in stringa esadecimale
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        print("Device Token ricevuto: \(token)")
        
        // Salva il token localmente
        UserDefaults.standard.set(token, forKey: "deviceToken")
        
        // Invia il token al server
        NetworkManager.shared.sendDeviceToken(token: token) { success, message in
            if success {
                print("Device token inviato al server con successo")
            } else {
                print("Errore nell'invio del device token: \(message)")
            }
        }
    }
    
    /// Chiamato se la registrazione per le notifiche push fallisce
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Registrazione notifiche push fallita: \(error.localizedDescription)")
    }
    
    // MARK: - Gestione Notifiche Push Ricevute
    
    /// Gestisce le notifiche push ricevute quando l'app Ã¨ in background/chiusa
    /// Gestisce le notifiche push ricevute quando l'app è in background/chiusa
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("📩 Notifica push ricevuta RAW userInfo: \(userInfo)")
        
        // Debug: stampa tutte le chiavi disponibili
        print("🔎 Chiavi disponibili in userInfo:")
        for (key, value) in userInfo {
            print("  - \(key): \(value)")
        }
        
        // Estrai i dati dalla notifica
        if let notificationTypeStr = userInfo["notificationType"] as? String,
           let typeInt = Int(notificationTypeStr),
           let notificationRole = userInfo["notificationRole"] as? String,
           let scheduledDateString = userInfo["scheduledDate"] as? String {
            
            print("✅ Dati estratti: tipo=\(typeInt), ruolo=\(notificationRole), data=\(scheduledDateString)")
            
            // Converti la data ISO8601
            let dateFormatter = ISO8601DateFormatter()
            
            if let scheduledDate = dateFormatter.date(from: scheduledDateString) {
                
                // DEBUG: Verifica la data parsata
                let debugFormatter = DateFormatter()
                debugFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                debugFormatter.timeZone = TimeZone(identifier: "Europe/Rome")
                print("📅 Data programmata: \(debugFormatter.string(from: scheduledDate)) (ora italiana)")
                print("📅 Ora corrente: \(debugFormatter.string(from: Date())) (ora italiana)")
                
                // 🔑 notificationSentDate = base per calcolare la finestra temporale
                //    - ORIGINAL: min(scheduledDate, now) → finestra di 20 min da scheduledDate
                //    - REMINDER: now → finestra di 5 min da quando arriva il reminder
                // 🔑 notificationScheduledDateOriginal = data dell'ORIGINAL, sempre, per inviare al server
                let now = Date()
                if notificationRole == "reminder" {
                    AppStateManager.shared.notificationSentDate = now  // finestra parte da adesso
                } else {
                    AppStateManager.shared.notificationSentDate = min(scheduledDate, now)  // finestra parte dalla data programmata
                }
                AppStateManager.shared.notificationScheduledDateOriginal = scheduledDate  // 🔑 Sempre data ORIGINAL per il server
                
                // ✅ Salva time_point e info sul giorno
                if let timePoint = userInfo["timePoint"] as? String {
                    AppStateManager.shared.currentTimePoint = timePoint
                    print("📌 TimePoint: \(timePoint)")
                }
                
                if let isFirstDayStr = userInfo["isFirstDay"] as? String {
                    AppStateManager.shared.isFirstDay = (isFirstDayStr == "true")
                    print("📅 Primo giorno: \(AppStateManager.shared.isFirstDay)")
                }
                
                if let isLastDayStr = userInfo["isLastDay"] as? String {
                    AppStateManager.shared.isLastDay = (isLastDayStr == "true")
                    print("📅 Ultimo giorno: \(AppStateManager.shared.isLastDay)")
                }
                
                print("📅 Finestra inizia: \(debugFormatter.string(from: AppStateManager.shared.notificationSentDate ?? now))")
                
                // 🔑 Genera Session ID univoco
                let sessionId = "\(typeInt)_\(Int(scheduledDate.timeIntervalSince1970))"
                print("🔑 Session ID: \(sessionId)")
                
                // Gestisci in base al ruolo della notifica
                if notificationRole == "expired" {
                    // 🔒 Marca sessione come scaduta
                    AppStateManager.shared.markSessionAsExpired(sessionId: sessionId)
                    AppStateManager.shared.activeNotificationType = nil
                    AppStateManager.shared.isQuestionnaireAvailable = false
                    print("⛔️ Notifica EXPIRED: sessione \(sessionId) marcata come scaduta")
                    completionHandler(.noData)
                    
                } else if notificationRole == "original" || notificationRole == "reminder" {
                    
                    // 🔒 Verifica se sessione già scaduta
                    if AppStateManager.shared.isSessionExpired(sessionId: sessionId) {
                        print("🔒 PUSH: sessione \(sessionId) già scaduta, ignoro")
                        completionHandler(.noData)
                        return
                    }
                    
                    // Salva session ID e ruolo corrente
                    AppStateManager.shared.currentNotificationSessionId = sessionId
                    AppStateManager.shared.activeNotificationRole = notificationRole  // 🔑 Salva ruolo
                    
                    NotificationManager.shared.checkIfQuestionnaireIsActive(type: typeInt) { isActive in
                        DispatchQueue.main.async {
                            if isActive {
                                AppStateManager.shared.activeNotificationType = typeInt
                                AppStateManager.shared.currentQuestionIndex = 0
                                AppStateManager.shared.hasCompletedQuestionnaire = false
                                AppStateManager.shared.questionnaireOpenedDate = Date()
                                print("✅ Questionario tipo \(typeInt) attivato da notifica push (\(notificationRole.uppercased()))")
                            } else {
                                // Marca come scaduta se non più valida
                                AppStateManager.shared.markSessionAsExpired(sessionId: sessionId)
                                print("⛔️ PUSH: questionario scaduto, sessione \(sessionId) marcata")
                            }
                        }
                    }
                    completionHandler(.newData)
                    
                } else {
                    print("⚠️ Ruolo notifica sconosciuto: \(notificationRole)")
                    completionHandler(.noData)
                }
            } else {
                print("❌ Impossibile convertire scheduledDate: \(scheduledDateString)")
                completionHandler(.failed)
            }
        } else {
            print("⚠️ Notifica senza dati validi. Contenuto userInfo:")
            print(userInfo)
            completionHandler(.noData)
        }
    }
    
    // MARK: - Ciclo di vita app
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        NetworkManager.shared.synchronizeSavedData { success, message in
            if success {
                print("Sincronizzazione al ritorno in primo piano: \(message)")
            } else {
                print("Sincronizzazione al ritorno in primo piano fallita: \(message)")
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        AppStateManager.shared.saveAppState()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        AppStateManager.shared.saveAppState()
        
        // âœ… RESET dello stato del questionario quando l'app va in background
        if AppStateManager.shared.hasCompletedQuestionnaire {
            print("App in background: resetto stato questionario completato")
            
            AppStateManager.shared.hasCompletedQuestionnaire = false
            AppStateManager.shared.activeNotificationType = nil
            AppStateManager.shared.isQuestionnaireAvailable = false
            AppStateManager.shared.currentQuestionIndex = 0
            AppStateManager.shared.notificationSentDate = nil
            AppStateManager.shared.questionnaireOpenedDate = nil
        }
    }
}
