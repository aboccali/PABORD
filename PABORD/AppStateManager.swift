// AppStateManager.swift
// PABORD
//
// Created by Neuroinformatica on 28/05/25.
//

import Foundation
import Combine
import UserNotifications

/// Gestisce lo stato globale dell'applicazione, inclusa la notifica attiva e l'indice della domanda corrente.
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()

    /// Indica se l'app è in modalità test (true se credenziali "demo" usate).
    @Published var isTestMode: Bool {
        didSet {
            print("🎮 Modalità test impostata su: \(isTestMode)")
            UserDefaults.standard.set(isTestMode, forKey: AppConstants.isTestModeKey)
            UserDefaults.standard.synchronize()
            if isTestMode {
                resetQuestionnaireState()
            }
        }
    }

    /// Indica se l'utente è autenticato.
    @Published var isLoggedIn: Bool {
        didSet {
            print("🔐 isLoggedIn cambiato a: \(isLoggedIn)")
            UserDefaults.standard.set(isLoggedIn, forKey: AppConstants.isLoggedInKey)
            UserDefaults.standard.synchronize()
            if !isLoggedIn {
                resetQuestionnaireState()
            }
        }
    }
    
    /// Indica se l'utente ha già visto (e interagito con) la schermata di richiesta notifiche.
    /// Viene resettato al logout in modo che venga mostrata di nuovo al prossimo login.
    @Published var hasSeenNotificationPrompt: Bool {
        didSet {
            print("🔔 hasSeenNotificationPrompt cambiato a: \(hasSeenNotificationPrompt)")
            UserDefaults.standard.set(hasSeenNotificationPrompt, forKey: AppConstants.hasSeenNotificationPromptKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    /// Indica se l'utente ha esplicitamente negato il permesso alle notifiche dalla schermata PABORD.
    /// Quando true, viene mostrata la schermata "Non puoi partecipare".
    @Published var hasNotificationsDenied: Bool {
        didSet {
            print("🚫 hasNotificationsDenied cambiato a: \(hasNotificationsDenied)")
            UserDefaults.standard.set(hasNotificationsDenied, forKey: AppConstants.hasNotificationsDeniedKey)
            UserDefaults.standard.synchronize()
        }
    }

    /// Il tipo di notifica che ha attivato il questionario.
    @Published var activeNotificationType: Int? = nil {
        didSet {
            if activeNotificationType != nil {
                hasCompletedQuestionnaire = false
                currentQuestionIndex = 0
            }
            print("📬 Tipo di notifica attivo impostato su: \(String(describing: activeNotificationType))")
        }
    }

    /// L'indice della domanda corrente all'interno del set di domande attivo.
    @Published var currentQuestionIndex: Int = 0

    /// Indica se l'ultimo questionario è stato completato.
    @Published var hasCompletedQuestionnaire: Bool = false

    /// Indica se il questionario è attualmente accessibile (non è scaduto).
    @Published var isQuestionnaireAvailable: Bool = false

    /// Il codice soggetto dell'utente corrente.
    @Published var currentUserCode: String? {
        didSet {
            print("👤 currentUserCode cambiato a: \(String(describing: currentUserCode))")
            if let code = currentUserCode {
                UserDefaults.standard.set(code, forKey: AppConstants.currentUserCodeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: AppConstants.currentUserCodeKey)
            }
            UserDefaults.standard.synchronize()
        }
    }

    /// La data e ora in cui la notifica originale è stata inviata (o programmata).
    @Published var notificationSentDate: Date? = nil
    
    /// La data e ora ORIGINALE programmata (dalla notifica push, senza modifiche)
    @Published var notificationScheduledDateOriginal: Date? = nil

    /// La data e ora in cui l'utente ha aperto il questionario.
    @Published var questionnaireOpenedDate: Date? = nil
    
    /// Il ruolo della notifica che ha attivato il questionario ("original" o "reminder")
    @Published var activeNotificationRole: String? = nil

    // ✅ CAMPI per gestire le regole delle domande
    
    /// Il time_point della notifica corrente (es. "T0", "T1", "T6")
    @Published var currentTimePoint: String? = nil

    /// Indica se è il primo giorno del protocollo
    @Published var isFirstDay: Bool = false

    /// Indica se è l'ultimo giorno del protocollo
    @Published var isLastDay: Bool = false

    // 🔒 GESTIONE SESSIONI SCADUTE
    
    /// ID univoco della sessione di notifica corrente (es. "1_1738180800" = tipo_timestamp)
    @Published var currentNotificationSessionId: String? = nil
    
    /// Set di ID sessioni già scadute - impedisce riapertura dopo expired
    @Published var expiredSessionIds: Set<String> = []

    // MARK: - Timer per polling sessione attiva (accesso da app senza tap notifica)
    
    /// Timer che controlla periodicamente se c'è una sessione attiva non ancora raccolta
    private var sessionPollingTimer: Timer? = nil
    
    private init() {
        // ✅ CARICAMENTO SINCRONO da UserDefaults
        let loadedIsTestMode = UserDefaults.standard.bool(forKey: AppConstants.isTestModeKey)
        let loadedIsLoggedIn = UserDefaults.standard.bool(forKey: AppConstants.isLoggedInKey)
        let loadedUserCode = UserDefaults.standard.string(forKey: AppConstants.currentUserCodeKey)
        let loadedHasSeenPrompt = UserDefaults.standard.bool(forKey: AppConstants.hasSeenNotificationPromptKey)
        let loadedHasNotificationsDenied = UserDefaults.standard.bool(forKey: AppConstants.hasNotificationsDeniedKey)
        
        // ✅ Assegna i valori SENZA triggerare didSet (usa _variabile)
        self.isTestMode = loadedIsTestMode
        self.isLoggedIn = loadedIsLoggedIn
        self.currentUserCode = loadedUserCode
        self.hasSeenNotificationPrompt = loadedHasSeenPrompt
        self.hasNotificationsDenied = loadedHasNotificationsDenied
        
        self.currentQuestionIndex = UserDefaults.standard.integer(forKey: "currentQuestionIndex")
        self.hasCompletedQuestionnaire = UserDefaults.standard.bool(forKey: "hasCompletedQuestionnaire")
        self.isQuestionnaireAvailable = UserDefaults.standard.bool(forKey: "isQuestionnaireAvailable")

        self.notificationSentDate = UserDefaults.standard.object(forKey: "notificationSentDate") as? Date
        self.notificationScheduledDateOriginal = UserDefaults.standard.object(forKey: "notificationScheduledDateOriginal") as? Date
        self.questionnaireOpenedDate = UserDefaults.standard.object(forKey: "questionnaireOpenedDate") as? Date
        
        self.activeNotificationRole = UserDefaults.standard.string(forKey: "activeNotificationRole")

        self.currentTimePoint = UserDefaults.standard.string(forKey: "currentTimePoint")
        self.isFirstDay = UserDefaults.standard.bool(forKey: "isFirstDay")
        self.isLastDay = UserDefaults.standard.bool(forKey: "isLastDay")

        self.currentNotificationSessionId = UserDefaults.standard.string(forKey: "currentNotificationSessionId")
        
        if let expiredIds = UserDefaults.standard.array(forKey: "expiredSessionIds") as? [String] {
            self.expiredSessionIds = Set(expiredIds)
        }
        
        print("📱 AppStateManager INIZIALIZZATO")
        print("🔐 isLoggedIn: \(self.isLoggedIn)")
        print("🎮 isTestMode: \(self.isTestMode)")
        print("👤 currentUserCode: \(String(describing: self.currentUserCode))")
        print("🔔 hasSeenNotificationPrompt: \(self.hasSeenNotificationPrompt)")
        print("🚫 hasNotificationsDenied: \(self.hasNotificationsDenied)")

        UNUserNotificationCenter.current().delegate = NotificationManager.shared
    }

    // MARK: - Polling sessione attiva
    
    /// Avvia il timer di polling: ogni 15 secondi controlla se c'è una notifica pendente
    /// consegnata ma non ancora tappata, e attiva il questionario se la sessione è valida.
    func startSessionPolling() {
        guard sessionPollingTimer == nil else { return }
        print("⏱️ Avvio polling sessione attiva (ogni 15 sec)")
        sessionPollingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.checkForActiveSessionFromDeliveredNotifications()
        }
        // Prima chiamata immediata
        checkForActiveSessionFromDeliveredNotifications()
    }
    
    /// Ferma il timer di polling (quando l'app va in background o viene completato il questionario)
    func stopSessionPolling() {
        sessionPollingTimer?.invalidate()
        sessionPollingTimer = nil
        print("⏹️ Polling sessione fermato")
    }
    
    /// Controlla le notifiche già consegnate al Centro Notifiche e, se trova una sessione
    /// valida non ancora raccolta (e non scaduta), attiva il questionario.
    func checkForActiveSessionFromDeliveredNotifications() {
        // Non fare nulla se c'è già un questionario attivo o completato
        guard activeNotificationType == nil,
              !hasCompletedQuestionnaire,
              isLoggedIn,
              !hasNotificationsDenied
        else { return }
        
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] notifications in
            guard let self = self else { return }
            
            // Considera tutte le notifiche consegnate: sia locali (demo) che push
            for notification in notifications {
                let userInfo = notification.request.content.userInfo
                
                // Estrai tipo notifica
                var notificationType: Int?
                if let t = userInfo["notificationType"] as? Int {
                    notificationType = t
                } else if let tStr = userInfo["notificationType"] as? String, let t = Int(tStr) {
                    notificationType = t
                }
                guard let typeInt = notificationType else { continue }
                
                // Estrai ruolo
                guard let role = userInfo["notificationRole"] as? String,
                      role == "original" || role == "reminder"
                else { continue }
                
                // Estrai data programmata
                var scheduledDate: Date?
                if let ti = userInfo["scheduledDate"] as? TimeInterval {
                    scheduledDate = Date(timeIntervalSince1970: ti)
                } else if let s = userInfo["scheduledDate"] as? String {
                    scheduledDate = ISO8601DateFormatter().date(from: s)
                }
                guard let scheduled = scheduledDate else { continue }
                
                // Genera session ID
                let sessionId = "\(typeInt)_\(Int(scheduled.timeIntervalSince1970))"
                
                // Salta sessioni già scadute o già completate
                if self.isSessionExpired(sessionId: sessionId) { continue }
                
                // Calcola finestra di validità
                let windowMinutes = role == "reminder" ? 5 : 20
                let now = Date()
                let windowStart = role == "reminder" ? now : min(scheduled, now)
                guard let windowEnd = Calendar.current.date(byAdding: .minute, value: windowMinutes, to: scheduled) else { continue }
                
                // Verifica che siamo nella finestra valida
                guard now >= scheduled, now < windowEnd else { continue }
                
                // ✅ Sessione valida trovata — attivala sul main thread
                print("🔍 Polling: trovata sessione attiva \(sessionId) (tipo \(typeInt), ruolo \(role))")
                
                DispatchQueue.main.async {
                    // Evita doppia attivazione
                    guard self.activeNotificationType == nil, !self.hasCompletedQuestionnaire else { return }
                    
                    self.notificationSentDate = windowStart
                    self.notificationScheduledDateOriginal = scheduled
                    self.currentNotificationSessionId = sessionId
                    self.activeNotificationRole = role
                    
                    if let timePoint = userInfo["timePoint"] as? String {
                        self.currentTimePoint = timePoint
                    }
                    if let firstDayStr = userInfo["isFirstDay"] as? String {
                        self.isFirstDay = firstDayStr == "true"
                    }
                    if let lastDayStr = userInfo["isLastDay"] as? String {
                        self.isLastDay = lastDayStr == "true"
                    }
                    
                    self.activeNotificationType = typeInt
                    self.currentQuestionIndex = 0
                    self.hasCompletedQuestionnaire = false
                    self.isQuestionnaireAvailable = true
                    self.questionnaireOpenedDate = Date()
                    
                    NotificationManager.shared.clearBadge()
                    print("✅ Polling: questionario tipo \(typeInt) attivato automaticamente (senza tap)")
                }
                
                // Basta la prima sessione valida trovata
                break
            }
        }
    }
    
    // MARK: - Reset

    /// Resetta solo lo stato del questionario corrente (non logout)
    func resetQuestionnaireState() {
        activeNotificationType = nil
        activeNotificationRole = nil
        currentQuestionIndex = 0
        hasCompletedQuestionnaire = false
        isQuestionnaireAvailable = false
        notificationSentDate = nil
        notificationScheduledDateOriginal = nil
        questionnaireOpenedDate = nil
        currentTimePoint = nil
        isFirstDay = false
        isLastDay = false
        currentNotificationSessionId = nil
        // ⚠️ NON resettiamo expiredSessionIds - quelli devono persistere!
        print("🔄 Stato del questionario resettato.")
    }
    
    /// 🔒 Marca una sessione come scaduta (chiamata quando arriva notifica EXPIRED)
    func markSessionAsExpired(sessionId: String) {
        expiredSessionIds.insert(sessionId)
        UserDefaults.standard.set(Array(expiredSessionIds), forKey: "expiredSessionIds")
        UserDefaults.standard.synchronize()
        print("🔒 Sessione \(sessionId) marcata come SCADUTA")
    }
    
    /// ✅ Verifica se una sessione è già scaduta
    func isSessionExpired(sessionId: String) -> Bool {
        return expiredSessionIds.contains(sessionId)
    }
    
    /// 🧹 Pulisce sessioni scadute vecchie (oltre 7 giorni)
    func cleanupOldExpiredSessions() {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60).timeIntervalSince1970
        
        let cleaned = expiredSessionIds.filter { sessionId in
            if let timestampStr = sessionId.split(separator: "_").last,
               let timestamp = Double(timestampStr) {
                return timestamp > sevenDaysAgo
            }
            return false
        }
        
        expiredSessionIds = Set(cleaned)
        UserDefaults.standard.set(Array(expiredSessionIds), forKey: "expiredSessionIds")
        UserDefaults.standard.synchronize()
        print("🧹 Pulizia sessioni scadute completata")
    }
    
    /// ✅ Logout completo - resetta tutto e cancella le credenziali
    func logout() {
        stopSessionPolling()
        isLoggedIn = false
        isTestMode = false
        currentUserCode = nil
        hasSeenNotificationPrompt = false   // 🔔 Mostra di nuovo la schermata notifiche al prossimo login
        hasNotificationsDenied = false      // 🔔 Resetta anche il rifiuto
        resetQuestionnaireState()
        
        // 🧹 Pulizia completa delle sessioni scadute al logout
        expiredSessionIds.removeAll()
        UserDefaults.standard.removeObject(forKey: "expiredSessionIds")
        UserDefaults.standard.synchronize()
        
        print("🚪 Logout completato - tutte le credenziali e sessioni cancellate")
    }
    
    func saveAppState() {
        print("💾 Salvataggio stato app...")

        UserDefaults.standard.set(isTestMode, forKey: AppConstants.isTestModeKey)
        UserDefaults.standard.set(isLoggedIn, forKey: AppConstants.isLoggedInKey)
        UserDefaults.standard.set(currentUserCode, forKey: AppConstants.currentUserCodeKey)
        UserDefaults.standard.set(hasSeenNotificationPrompt, forKey: AppConstants.hasSeenNotificationPromptKey)
        UserDefaults.standard.set(hasNotificationsDenied, forKey: AppConstants.hasNotificationsDeniedKey)

        UserDefaults.standard.set(currentQuestionIndex, forKey: "currentQuestionIndex")
        UserDefaults.standard.set(hasCompletedQuestionnaire, forKey: "hasCompletedQuestionnaire")
        UserDefaults.standard.set(isQuestionnaireAvailable, forKey: "isQuestionnaireAvailable")

        if let date = notificationSentDate {
            UserDefaults.standard.set(date, forKey: "notificationSentDate")
        }
        
        if let scheduledOriginal = notificationScheduledDateOriginal {
            UserDefaults.standard.set(scheduledOriginal, forKey: "notificationScheduledDateOriginal")
        }

        if let openedDate = questionnaireOpenedDate {
            UserDefaults.standard.set(openedDate, forKey: "questionnaireOpenedDate")
        }
        
        UserDefaults.standard.set(activeNotificationRole, forKey: "activeNotificationRole")

        UserDefaults.standard.set(currentTimePoint, forKey: "currentTimePoint")
        UserDefaults.standard.set(isFirstDay, forKey: "isFirstDay")
        UserDefaults.standard.set(isLastDay, forKey: "isLastDay")

        UserDefaults.standard.set(currentNotificationSessionId, forKey: "currentNotificationSessionId")
        UserDefaults.standard.set(Array(expiredSessionIds), forKey: "expiredSessionIds")

        UserDefaults.standard.synchronize()
    }

}

struct AppConstants {
    static let isTestModeKey = "isTestMode"
    static let isLoggedInKey = "isLoggedIn"
    static let currentUserCodeKey = "currentUserCode"
    static let hasSeenNotificationPromptKey = "hasSeenNotificationPrompt"
    static let hasNotificationsDeniedKey = "hasNotificationsDenied"
}
