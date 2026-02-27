// NotificationManager.swift
// PABORD - Gestione Notifiche PUSH e DEMO
//
// Created by Neuroinformatica on 28/05/25.
//

import UserNotifications
import Foundation
import UIKit

/// Gestisce le notifiche PUSH (modalità  normale) e LOCALI (modalità  demo)
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Session ID Generation
    
    /// Genera un ID univoco per la sessione di notifica (tipo + timestamp schedulato)
    private func generateSessionId(notificationType: Int, scheduledDate: Date) -> String {
        let timestamp = Int(scheduledDate.timeIntervalSince1970)
        return "\(notificationType)_\(timestamp)"
    }

    // MARK: - Permessi
    
    /// Richiede il permesso all'utente per le notifiche
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permesso notifiche concesso.")
            } else if let error = error {
                print("Permesso notifiche negato: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Badge
    
    /// Resetta il badge a 0 (compatibile iOS 15+)
    func clearBadge() {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("Errore reset badge: \(error.localizedDescription)")
                } else {
                    print("Badge resettato a 0")
                }
            }
        } else {
            // iOS 15 e precedenti
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
                print("Badge resettato a 0 (iOS 15)")
            }
        }
    }

    // MARK: - Modalità  DEMO
    
    /// Schedula una notifica DEMO dopo 5 minuti con questionario casuale
    func scheduleDemoNotification() {
        // Cancella eventuali notifiche precedenti
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Scegli un tipo di questionario casuale (1-8)
        let randomType = Int.random(in: 1...8)
        
        // Schedula tra 5 minuti
        let triggerDate = Date().addingTimeInterval(5)
        
        let content = UNMutableNotificationContent()
        content.title = "Questionario PABORD [DEMO]"
        content.body = "E' ora di compilare il questionario! (\(randomType)/8)"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "notificationType": randomType,
            "notificationRole": "original",
            "scheduledDate": triggerDate.timeIntervalSince1970,
            "isDemo": true
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "demo_\(randomType)_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Errore scheduling notifica DEMO: \(error.localizedDescription)")
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                formatter.timeZone = TimeZone.current
                print("Notifica DEMO schedulata per \(formatter.string(from: triggerDate)) - Tipo: \(randomType)")
            }
        }
    }

    // MARK: - Validità Questionario
    
    /// Controlla se un questionario è ancora valido
    /// - ORIGINAL: 20 minuti dalla notifica ORIGINAL fino all'EXPIRED
    /// - REMINDER: 5 minuti dalla notifica REMINDER fino all'EXPIRED
    func checkIfQuestionnaireIsActive(type: Int, completion: @escaping (Bool) -> Void) {
        guard let scheduledDate = AppStateManager.shared.notificationSentDate else {
            print("⚠️ Nessuna scheduledDate salvata per tipo \(type).")
            AppStateManager.shared.isQuestionnaireAvailable = false
            completion(false)
            return
        }
        
        // 🔑 Determina la finestra in base al ruolo della notifica
        let notificationRole = AppStateManager.shared.activeNotificationRole ?? "original"
        let windowMinutes: Int
        
        if notificationRole == "reminder" {
            windowMinutes = 5  // 📌 REMINDER: 5 minuti
        } else {
            windowMinutes = 20 // 📌 ORIGINAL: 20 minuti
        }

        let now = Date()
        let calendar = Calendar.current
        
        guard let endDate = calendar.date(byAdding: .minute, value: windowMinutes, to: scheduledDate) else {
            print("❌ Impossibile calcolare endDate")
            completion(false)
            return
        }

        let isActive = now >= scheduledDate && now < endDate
        AppStateManager.shared.isQuestionnaireAvailable = isActive

        // DEBUG
        let debugFormatter = DateFormatter()
        debugFormatter.dateFormat = "HH:mm:ss"
        debugFormatter.timeZone = TimeZone(identifier: "Europe/Rome")
        
        if isActive {
            print("✅ Questionario tipo \(type) ATTIVO")
            print("   Ruolo: \(notificationRole.uppercased())")
            print("   Finestra: \(debugFormatter.string(from: scheduledDate)) → \(debugFormatter.string(from: endDate)) (\(windowMinutes) minuti)")
            print("   Ora: \(debugFormatter.string(from: now))")
            
            let remaining = endDate.timeIntervalSince(now)
            print("   ⏱️ Tempo rimanente: \(Int(remaining/60)) minuti \(Int(remaining.truncatingRemainder(dividingBy: 60))) secondi")
        } else {
            print("⛔️ Questionario tipo \(type) NON ATTIVO")
            print("   Ruolo: \(notificationRole.uppercased())")
            print("   Finestra: \(debugFormatter.string(from: scheduledDate)) → \(debugFormatter.string(from: endDate)) (\(windowMinutes) minuti)")
            print("   Ora: \(debugFormatter.string(from: now))")
            
            if now < scheduledDate {
                let diff = scheduledDate.timeIntervalSince(now)
                print("   ⏰ Troppo presto di \(Int(diff)) secondi")
            } else {
                let diff = now.timeIntervalSince(endDate)
                print("   ⏰ Troppo tardi di \(Int(diff)) secondi")
            }
        }

        completion(isActive)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Mostra notifica anche quando app Ã¨ in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  willPresent notification: UNNotification,
                                  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Gestisce il tap sulla notifica
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        print("Notifica toccata. UserInfo: \(userInfo)")
        
        // Verifica se è una notifica DEMO
        let isDemo = userInfo["isDemo"] as? Bool ?? false
        
        // Estrai notificationType (può essere Int o String)
        let notificationType: Int
        if let typeInt = userInfo["notificationType"] as? Int {
            notificationType = typeInt
        } else if let typeStr = userInfo["notificationType"] as? String,
                  let typeInt = Int(typeStr) {
            notificationType = typeInt
        } else {
            print("Notifica senza tipo valido.")
            completionHandler()
            return
        }
        
        guard let notificationRole = userInfo["notificationRole"] as? String else {
            print("Notifica senza ruolo valido.")
            completionHandler()
            return
        }
        
        print("Tipo: \(notificationType), Ruolo: \(notificationRole), Demo: \(isDemo)")
        
        // ✅ Estrai la data programmata PRIMA (necessaria per Session ID)
        var scheduledDate: Date?
        
        if let scheduledTimeInterval = userInfo["scheduledDate"] as? TimeInterval {
            scheduledDate = Date(timeIntervalSince1970: scheduledTimeInterval)
        } else if let scheduledDateString = userInfo["scheduledDate"] as? String {
            let dateFormatter = ISO8601DateFormatter()
            scheduledDate = dateFormatter.date(from: scheduledDateString)
        }
        
        guard let scheduledDate = scheduledDate else {
            print("⚠️ Impossibile estrarre scheduledDate")
            completionHandler()
            return
        }
        
        // 🔑 Genera Session ID univoco
        let sessionId = generateSessionId(notificationType: notificationType, scheduledDate: scheduledDate)
        print("🔑 Session ID: \(sessionId)")
        
        // 🔒 BLOCCA se è una notifica EXPIRED - marca la sessione come scaduta
        if notificationRole == "expired" {
            print("⛔️ Notifica EXPIRED toccata: questionario NON più disponibile")
            
            // Marca questa sessione come scaduta
            AppStateManager.shared.markSessionAsExpired(sessionId: sessionId)
            
            // Resetta completamente lo stato
            DispatchQueue.main.async {
                AppStateManager.shared.activeNotificationType = nil
                AppStateManager.shared.isQuestionnaireAvailable = false
                AppStateManager.shared.hasCompletedQuestionnaire = false
                AppStateManager.shared.notificationSentDate = nil
                AppStateManager.shared.questionnaireOpenedDate = nil
                AppStateManager.shared.currentNotificationSessionId = nil
                
                print("🚫 Accesso bloccato: questionario scaduto")
            }
            
            completionHandler()
            return
        }
        
        // 🔒 VERIFICA se questa sessione è già stata marcata come scaduta
        if AppStateManager.shared.isSessionExpired(sessionId: sessionId) {
            print("🔒 ACCESSO NEGATO: sessione \(sessionId) già scaduta in precedenza")
            
            DispatchQueue.main.async {
                AppStateManager.shared.activeNotificationType = nil
                AppStateManager.shared.isQuestionnaireAvailable = false
                AppStateManager.shared.hasCompletedQuestionnaire = false
            }
            
            completionHandler()
            return
        }
        
        // ✅ BLOCCA anche REMINDER se il questionario è già completato o scaduto
        if notificationRole == "reminder" {
            // Verifica se il questionario è ancora valido
            let now = Date()
            let calendar = Calendar.current
            
            guard let endDate = calendar.date(byAdding: .minute, value: 20, to: scheduledDate) else {
                print("⛔️ REMINDER: impossibile calcolare scadenza")
                completionHandler()
                return
            }
            
            if now >= endDate {
                print("⛔️ REMINDER toccato ma questionario GIÀ SCADUTO")
                
                // Marca come scaduta
                AppStateManager.shared.markSessionAsExpired(sessionId: sessionId)
                
                DispatchQueue.main.async {
                    AppStateManager.shared.activeNotificationType = nil
                    AppStateManager.shared.isQuestionnaireAvailable = false
                    AppStateManager.shared.hasCompletedQuestionnaire = false
                }
                
                completionHandler()
                return
            }
        }
        
        // ✅ BLOCCA se il questionario è già stato completato
        if AppStateManager.shared.hasCompletedQuestionnaire {
            print("⛔️ Questionario già completato: accesso bloccato")
            completionHandler()
            return
        }
        
        // ✅ Procedi SOLO se è una notifica ORIGINAL o REMINDER valido
        if notificationRole != "original" && notificationRole != "reminder" {
            print("⚠️ Ruolo notifica non gestito: \(notificationRole)")
            completionHandler()
            return
        }
        
        let now = Date()
        
        // 🔑 notificationSentDate = base per calcolare la finestra temporale
        //    - ORIGINAL: min(scheduledDate, now) → finestra di 20 min da scheduledDate
        //    - REMINDER: now → finestra di 5 min da quando arriva il reminder
        // 🔑 notificationScheduledDateOriginal = data dell'ORIGINAL, sempre, per inviare al server
        if notificationRole == "reminder" {
            AppStateManager.shared.notificationSentDate = now  // finestra parte da adesso
        } else {
            AppStateManager.shared.notificationSentDate = min(scheduledDate, now)  // finestra parte dalla data programmata
        }
        AppStateManager.shared.notificationScheduledDateOriginal = scheduledDate  // 🔑 Sempre data ORIGINAL per il server
        AppStateManager.shared.currentNotificationSessionId = sessionId  // 🔑 Salva session ID
        AppStateManager.shared.activeNotificationRole = notificationRole  // 🔑 Salva ruolo notifica
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current
        print("📅 Data programmata: \(formatter.string(from: scheduledDate))")
        print("📅 Finestra inizia: \(formatter.string(from: AppStateManager.shared.notificationSentDate ?? now))")
        print("📌 Ruolo notifica: \(notificationRole.uppercased())")
        
        // Verifica se il questionario è ancora valido
        self.checkIfQuestionnaireIsActive(type: notificationType) { isActive in
            DispatchQueue.main.async {
                if isActive {
                    AppStateManager.shared.activeNotificationType = notificationType
                    AppStateManager.shared.currentQuestionIndex = 0
                    AppStateManager.shared.hasCompletedQuestionnaire = false
                    AppStateManager.shared.questionnaireOpenedDate = Date()
                    
                    print("✅ Questionario tipo \(notificationType) attivato (\(notificationRole.uppercased()))")
                } else {
                    print("⛔️ Questionario tipo \(notificationType) NON valido (scaduto)")
                    
                    // Marca come scaduta
                    AppStateManager.shared.markSessionAsExpired(sessionId: sessionId)
                    
                    AppStateManager.shared.activeNotificationType = nil
                    AppStateManager.shared.isQuestionnaireAvailable = false
                    AppStateManager.shared.hasCompletedQuestionnaire = false
                }
            }
            completionHandler()
        }
    }
}
