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

    // ✅ NUOVI CAMPI per gestire le regole delle domande
    
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

    private init() {
        // ✅ CARICAMENTO SINCRONO da UserDefaults
        let loadedIsTestMode = UserDefaults.standard.bool(forKey: AppConstants.isTestModeKey)
        let loadedIsLoggedIn = UserDefaults.standard.bool(forKey: AppConstants.isLoggedInKey)
        let loadedUserCode = UserDefaults.standard.string(forKey: AppConstants.currentUserCodeKey)
        
        // ✅ Assegna i valori SENZA triggerare didSet (usa _variabile)
        self.isTestMode = loadedIsTestMode
        self.isLoggedIn = loadedIsLoggedIn
        self.currentUserCode = loadedUserCode
        
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
        

        UNUserNotificationCenter.current().delegate = NotificationManager.shared
    }

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
        currentNotificationSessionId = nil  // ✅ Resetta sessione corrente
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
        isLoggedIn = false
        isTestMode = false
        currentUserCode = nil
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
}
