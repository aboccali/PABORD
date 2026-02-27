import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject var appStateManager: AppStateManager

    // MARK: - Stati delle domande
    @State private var question1Slider1: Int? = nil
    @State private var question1Slider2: Int? = nil
    @State private var question1Slider3: Int? = nil
    @State private var question1Slider4: Int? = nil
    @State private var question1Slider5: Int? = nil
    @State private var question1Slider6: Int? = nil
    @State private var question1Slider7: Int? = nil
    @State private var question2Selection: Int? = nil
    @State private var question3Selection: Int? = nil
    @State private var question4Slider1: Int? = nil
    @State private var question4Slider2: Int? = nil
    @State private var question4Slider3: Int? = nil
    @State private var question4Slider4: Int? = nil
    @State private var question4Slider5: Int? = nil
    @State private var question5YesNot: Int? = nil
    @State private var question5Selection: Int? = nil
    @State private var question5OpenText: String = ""
    @State private var question6Selection: Int? = nil
    @State private var question7YesNot: Int? = nil
    @State private var question7Selection: Int? = nil
    @State private var question7OpenText: String = ""
    @State private var question8Selection: Int? = nil
    @State private var question9YesNot: Int? = nil
    @State private var question9Selection: [Int] = []
    @State private var question9OpenText: String = ""
    @State private var question10YesNoAnswer: Int? = nil
    @State private var question10FirstChoices: [Int] = []
    @State private var question10SecondChoice: Int? = nil
    @State private var question11Selection: Int? = nil
    @State private var question12Selection: Int? = nil
    @State private var question13Selection: Int? = nil
    @State private var question14Selection: Int? = nil
    @State private var question15Selection: Int? = nil
    @State private var slider16Value: Int? = nil

    @State private var randomizedQuestionIndices: [Int] = []
    
    // ⚠️ Alert per errore invio dati
    @State private var showSendErrorAlert = false
    @State private var sendErrorMessage = ""

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Image("sfondo")
                .resizable()
                .ignoresSafeArea()

            VStack {
                if appStateManager.hasCompletedQuestionnaire {
                    completionScreen()
                } else if appStateManager.activeNotificationType == nil || !appStateManager.isQuestionnaireAvailable {
                    Text("Attendere una notifica per iniziare il questionario.")
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                } else if let type = appStateManager.activeNotificationType, appStateManager.isQuestionnaireAvailable {
                    if !randomizedQuestionIndices.isEmpty {
                        displayQuestions(indices: randomizedQuestionIndices, forType: type)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            checkInitialQuestionnaireState()
            // ✅ Resetta badge quando l'utente apre effettivamente il questionario
            if appStateManager.activeNotificationType != nil {
                NotificationManager.shared.clearBadge()
            }
        }
        .onChange(of: appStateManager.activeNotificationType) { newValue in
            if newValue != nil && !appStateManager.hasCompletedQuestionnaire {
                appStateManager.isQuestionnaireAvailable = true
                appStateManager.currentQuestionIndex = 0
                resetAllAnswers()
                randomizedQuestionIndices = generateQuestionIndices(forType: newValue!)
                logMessage("Questionario reso disponibile tramite notifica")
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive, appStateManager.hasCompletedQuestionnaire {
                appStateManager.resetQuestionnaireState()
                resetAllAnswers()
                randomizedQuestionIndices = []
                logMessage("App in background: stato questionario resettato")
            }
            
            // ✅ Quando l'app torna in foreground, verifica se il questionario è ancora valido
            if newPhase == .active {
                if let activeType = appStateManager.activeNotificationType,
                   !appStateManager.hasCompletedQuestionnaire {
                    
                    NotificationManager.shared.checkIfQuestionnaireIsActive(type: activeType) { isActive in
                        DispatchQueue.main.async {
                            if !isActive {
                                print("⛔️ Questionario scaduto mentre l'app era in background")
                                self.appStateManager.resetQuestionnaireState()
                                self.resetAllAnswers()
                                self.randomizedQuestionIndices = []
                            }
                        }
                    }
                }
            }
        }
        .alert("Errore invio dati", isPresented: $showSendErrorAlert) {
            Button("OK") {
                // L'utente può riprovare cliccando nuovamente "Avanti" se vuole
            }
        } message: {
            Text(sendErrorMessage)
        }
    }

    // MARK: - Funzione logging su file
    private func logMessage(_ message: String) {
        let fileManager = FileManager.default
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let logFile = documents.appendingPathComponent("app_logs.txt")
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fullMessage = "[\(timestamp)] \(message)\n"

        if fileManager.fileExists(atPath: logFile.path) {
            if let handle = try? FileHandle(forWritingTo: logFile) {
                handle.seekToEndOfFile()
                if let data = fullMessage.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            }
        } else {
            try? fullMessage.write(to: logFile, atomically: true, encoding: .utf8)
        }
        print(fullMessage)
    }

    // MARK: - Resetta tutte le risposte
    private func resetAllAnswers() {
        question1Slider1 = nil
        question1Slider2 = nil
        question1Slider3 = nil
        question1Slider4 = nil
        question1Slider5 = nil
        question1Slider6 = nil
        question1Slider7 = nil
        question2Selection = nil
        question3Selection = nil
        question4Slider1 = nil
        question4Slider2 = nil
        question4Slider3 = nil
        question4Slider4 = nil
        question4Slider5 = nil
        question5YesNot = nil
        question5Selection = nil
        question5OpenText = ""
        question6Selection = nil
        question7YesNot = nil
        question7Selection = nil
        question7OpenText = ""
        question8Selection = nil
        question9YesNot = nil
        question9Selection = []
        question9OpenText = ""
        question10YesNoAnswer = nil
        question10FirstChoices = []
        question10SecondChoice = nil
        question11Selection = nil
        question12Selection = nil
        question13Selection = nil
        question14Selection = nil
        question15Selection = nil
        slider16Value = nil
        logMessage("✅ Tutte le risposte resettate")
    }

    // MARK: - Genera ordine domande
    private func generateQuestionIndices(forType type: Int) -> [Int] {
        // 📋 REGOLE RANDOMIZZAZIONE DOMANDE
        // type = notification_type_daily (1-8)
        // isFirstDay/isLastDay vengono da AppStateManager
        // currentTimePoint può essere "T0", "T1", "T6"
        
        var questionIndices: [Int] = []
        var alwaysQuestions: [Int] = [0, 1, 2, 8]  // Q1, Q2, Q3, Q9 - sempre presenti
        var morningOnlyQuestions: [Int] = []       // Q11, Q12, Q13, Q14 - solo prima notifica (type 1)
        var eveningOnlyQuestions: [Int] = []       // Q5, Q6, Q7, Q8, Q10, Q15 - solo ultima notifica (type 8)
        
        // ✅ DOMANDE SEMPRE PRESENTI (tutte le notifiche, tutti i giorni)
        // Q1, Q2, Q3, Q9 → randomizzate
        questionIndices.append(contentsOf: alwaysQuestions)
        
        // ✅ DOMANDE SOLO PRIMA NOTIFICA GIORNATA (type 1)
        if type == 1 {
            // Q11 può essere randomica, ma se presente deve essere seguita da Q12, Q13, Q14
            morningOnlyQuestions = [10, 11, 12, 13]  // Q11, Q12, Q13, Q14
        }
        
        // ✅ DOMANDE SOLO ULTIMA NOTIFICA SERALE (type 8)
        if type == 8 {
            // Q5 può essere randomica, ma se presente deve essere seguita da Q6, Q7, Q8
            eveningOnlyQuestions.append(contentsOf: [4, 5, 6, 7])  // Q5, Q6, Q7, Q8
            
            // Q10 - sempre ultima notifica
            eveningOnlyQuestions.append(9)  // Q10
            
            // Q15 - sempre ultima notifica (randomica)
            eveningOnlyQuestions.append(14)  // Q15
            
            // Q4 - solo settimana T6, solo ultima notifica
            if appStateManager.currentTimePoint == "T6" {
                eveningOnlyQuestions.append(3)  // Q4
            }
            
            // Q16 - solo ultimo giorno (primo e ultimo), solo ultima notifica
            if appStateManager.isFirstDay || appStateManager.isLastDay {
                eveningOnlyQuestions.append(15)  // Q16
            }
        }
        
        // 🎲 RANDOMIZZAZIONE CON SEQUENZE OBBLIGATORIE
        
        // Separiamo le domande che devono mantenere sequenza
        var randomizableQuestions: [Int] = []
        var sequencedGroups: [[Int]] = []
        
        // Aggiungi domande "always" (già randomizzabili)
        randomizableQuestions.append(contentsOf: alwaysQuestions)
        
        // Gestione MATTINA (type 1): Q11 randomica, poi Q12-13-14 in sequenza
        if !morningOnlyQuestions.isEmpty {
            randomizableQuestions.append(morningOnlyQuestions[0])  // Q11 randomica
            if morningOnlyQuestions.count > 1 {
                sequencedGroups.append(Array(morningOnlyQuestions[1...]))  // Q12, Q13, Q14 in sequenza
            }
        }
        
        // Gestione SERA (type 8): Q5 randomica, poi Q6-7-8 in sequenza
        if type == 8 {
            // Q5 randomica
            if eveningOnlyQuestions.contains(4) {
                randomizableQuestions.append(4)  // Q5
                // Q6, Q7, Q8 in sequenza
                sequencedGroups.append([5, 6, 7])
                
                // Rimuovi Q5, Q6, Q7, Q8 da eveningOnlyQuestions
                eveningOnlyQuestions.removeAll { [4, 5, 6, 7].contains($0) }
            }
            
            // Aggiungi le altre domande serali randomizzabili (Q10, Q15, Q4?, Q16?)
            randomizableQuestions.append(contentsOf: eveningOnlyQuestions)
        }
        
        // Randomizza le domande randomizzabili
        randomizableQuestions.shuffle()
        
        // 🔨 COSTRUZIONE FINALE DELL'ARRAY
        var finalIndices: [Int] = []
        
        for question in randomizableQuestions {
            finalIndices.append(question)
            
            // Se questa domanda inizia una sequenza, aggiungi il resto della sequenza
            if type == 1 && question == 10 {  // Q11
                // Aggiungi Q12, Q13, Q14 in sequenza
                if let morningSequence = sequencedGroups.first(where: { $0.contains(11) }) {
                    finalIndices.append(contentsOf: morningSequence)
                }
            }
            
            if type == 8 && question == 4 {  // Q5
                // Aggiungi Q6, Q7, Q8 in sequenza
                if let eveningSequence = sequencedGroups.first(where: { $0.contains(5) }) {
                    finalIndices.append(contentsOf: eveningSequence)
                }
            }
        }
        
        logMessage("📋 Tipo \(type): Domande da mostrare: \(finalIndices.map { $0 + 1 })")
        logMessage("   - TimePoint: \(appStateManager.currentTimePoint ?? "N/A")")
        logMessage("   - Primo giorno: \(appStateManager.isFirstDay)")
        logMessage("   - Ultimo giorno: \(appStateManager.isLastDay)")
        
        return finalIndices
    }

    // MARK: - Controllo stato iniziale questionario
    private func checkInitialQuestionnaireState() {
        if appStateManager.hasCompletedQuestionnaire { appStateManager.isQuestionnaireAvailable = false; return }
        
        // 🔒 Verifica se la sessione corrente è già scaduta
        if let sessionId = appStateManager.currentNotificationSessionId,
           appStateManager.isSessionExpired(sessionId: sessionId) {
            print("🔒 APP AVVIO: sessione \(sessionId) è scaduta, resetto stato")
            appStateManager.resetQuestionnaireState()
            return
        }
        
        if let activeType = appStateManager.activeNotificationType {
            NotificationManager.shared.checkIfQuestionnaireIsActive(type: activeType) { isActive in
                DispatchQueue.main.async {
                    if isActive {
                        self.appStateManager.isQuestionnaireAvailable = true
                        self.appStateManager.currentQuestionIndex = 0
                        if self.randomizedQuestionIndices.isEmpty {
                            self.resetAllAnswers()
                            self.randomizedQuestionIndices = self.generateQuestionIndices(forType: activeType)
                        }
                    } else {
                        // 🔒 Marca sessione come scaduta se non più valida
                        if let sessionId = self.appStateManager.currentNotificationSessionId {
                            self.appStateManager.markSessionAsExpired(sessionId: sessionId)
                        }
                        self.appStateManager.resetQuestionnaireState()
                    }
                }
            }
        }
    }

    // MARK: - Visualizzazione domande
    private func displayQuestions(indices: [Int], forType questionnaireType: Int) -> some View {
        let onAvanti: () -> Void = {
            if appStateManager.currentQuestionIndex < indices.count - 1 {
                appStateManager.currentQuestionIndex += 1
            } else {
                sendSurveyAndComplete(questionnaireType: questionnaireType)
            }
        }

        let onIndietro: () -> Void = {
            if appStateManager.currentQuestionIndex > 0 {
                appStateManager.currentQuestionIndex -= 1
            }
        }

        let actualQuestionIndex = indices[appStateManager.currentQuestionIndex]

        switch actualQuestionIndex {
        case 0:
            return AnyView(Question1View(
                slider1Value: Binding(get: { question1Slider1 ?? 50 }, set: { question1Slider1 = $0 }),
                slider2Value: Binding(get: { question1Slider2 ?? 50 }, set: { question1Slider2 = $0 }),
                slider3Value: Binding(get: { question1Slider3 ?? 50 }, set: { question1Slider3 = $0 }),
                slider4Value: Binding(get: { question1Slider4 ?? 50 }, set: { question1Slider4 = $0 }),
                slider5Value: Binding(get: { question1Slider5 ?? 50 }, set: { question1Slider5 = $0 }),
                slider6Value: Binding(get: { question1Slider6 ?? 50 }, set: { question1Slider6 = $0 }),
                slider7Value: Binding(get: { question1Slider7 ?? 50 }, set: { question1Slider7 = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 1:
            return AnyView(Question2View(
                question2Choice: Binding(get: { question2Selection ?? 0 }, set: { question2Selection = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 2:
            return AnyView(Question3View(
                question3Choice: Binding(get: { question3Selection ?? 0 }, set: { question3Selection = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 3:
            return AnyView(Question4View(
                slider1Value: Binding(get: { question4Slider1 ?? 50 }, set: { question4Slider1 = $0 }),
                slider2Value: Binding(get: { question4Slider2 ?? 50 }, set: { question4Slider2 = $0 }),
                slider3Value: Binding(get: { question4Slider3 ?? 50 }, set: { question4Slider3 = $0 }),
                slider4Value: Binding(get: { question4Slider4 ?? 50 }, set: { question4Slider4 = $0 }),
                slider5Value: Binding(get: { question4Slider5 ?? 50 }, set: { question4Slider5 = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 4:
            return AnyView(Question5View(
                question5YesNoAnswer: Binding(get: { question5YesNot ?? 0 }, set: { question5YesNot = $0 }),
                question5Choice: Binding(get: { question5Selection ?? 0 }, set: { question5Selection = $0 }),
                openResponseText5: $question5OpenText,
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 5:
            return AnyView(Question6View(
                question6Choice: Binding(get: { question6Selection ?? -1 }, set: { question6Selection = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 6:
            return AnyView(Question7View(
                question7YesNoAnswer: Binding(get: { question7YesNot ?? 0 }, set: { question7YesNot = $0 }),
                question7Choice: Binding(get: { question7Selection ?? 0 }, set: { question7Selection = $0 }),
                openResponseText7: $question7OpenText,
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 7:
            return AnyView(Question8View(
                question8Choice: Binding(get: { question8Selection ?? -1 }, set: { question8Selection = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 8:
            return AnyView(Question9View(
                question9YesNoAnswer: Binding(get: { question9YesNot ?? 0 }, set: { question9YesNot = $0 }),
                question9Choices: $question9Selection,
                openResponseText9: $question9OpenText,
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 9:
            return AnyView(Question10View(
                question10YesNoAnswer: Binding(get: { question10YesNoAnswer ?? 0 }, set: { question10YesNoAnswer = $0 }),
                question10FirstChoices: $question10FirstChoices,
                question10SecondChoice: Binding(get: { question10SecondChoice ?? 0 }, set: { question10SecondChoice = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 10:
            return AnyView(Question11View(
                question11Choice: Binding(get: { question11Selection ?? 0 }, set: { question11Selection = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 11:
            return AnyView(Question12View(
                question12Choice: Binding(get: { question12Selection ?? 0 }, set: { question12Selection = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 12:
            return AnyView(Question13View(
                question13Choice: Binding(get: { question13Selection ?? 0 }, set: { question13Selection = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 13:
            return AnyView(Question14View(
                question14Choice: Binding(get: { question14Selection ?? -1 }, set: { question14Selection = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 14:
            return AnyView(Question15View(
                question15Choice: Binding(get: { question15Selection ?? -1 }, set: { question15Selection = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        case 15:
            return AnyView(Question16View(
                slider16Value: Binding(get: { slider16Value ?? 0 }, set: { slider16Value = $0 }),
                onAvanti: onAvanti,
                onIndietro: onIndietro
            ))
        default:
            return AnyView(Text("Errore: Domanda non trovata").foregroundColor(.red))
        }
    }

    // MARK: - Invio dati e completamento questionario
    private func sendSurveyAndComplete(questionnaireType: Int) {
        
        // 🔒 Marca la sessione come completata (impedisce risposta duplicata)
        if let sessionId = appStateManager.currentNotificationSessionId {
            appStateManager.markSessionAsExpired(sessionId: sessionId)
            logMessage("🔒 Sessione \(sessionId) marcata come completata")
        }
        
        // 🎮 MODALITÀ DEMO: non inviare nulla al server
        if appStateManager.isTestMode {
            logMessage("🎮 Modalità demo: invio dati al server BLOCCATO")
            appStateManager.hasCompletedQuestionnaire = true
            appStateManager.isQuestionnaireAvailable = false
            appStateManager.activeNotificationType = nil
            appStateManager.currentQuestionIndex = 0
            randomizedQuestionIndices = []
            NotificationManager.shared.clearBadge()
            return
        }
        
        guard let userCode = appStateManager.currentUserCode else {
            logMessage("Errore: codice utente non disponibile")
            return
        }

        logMessage("Inizio invio dati al server per QType \(questionnaireType)")

        // ✅ USA LA DATA SCHEDULATA ORIGINALE (dalla notifica push), non quella modificata
        let notificationScheduledDate = appStateManager.notificationScheduledDateOriginal ?? appStateManager.notificationSentDate
        let questionnaireOpenedDate = appStateManager.questionnaireOpenedDate
        let questionnaireResponseDate = Date()

        NetworkManager.shared.sendSurveyData(
            codice_soggetto: userCode,
            lastOpenTime: questionnaireOpenedDate,
            notifica: notificationScheduledDate,  // ✅ Data programmata originale (senza secondi nel formatter)
            data_ora_risposta: questionnaireResponseDate,
            ALERT_TIRED: question1Slider1,
            HAPPY_UNHAPPY: question1Slider2,
            AGIT_CALM: question1Slider3,
            ENERGY: question1Slider4,
            WELL_BEING: question1Slider5,
            RELAX_TENSE: question1Slider6,
            SOC_CONN: question1Slider7,
            ACT_TRACK: question2Selection,
            SOC_INT: question3Selection,
            IMP_NEG_URG: question4Slider1,
            IMP_POS_URG: question4Slider2,
            IMP_LACK_PREM: question4Slider3,
            IMP_LACK_PERS: question4Slider4,
            IMP_SENS_SEEK: question4Slider5,
            STRESS_EVT_OCC: question5YesNot,
            STRESS_EVT_TYPE: question5OpenText,
            STRESS_EVT_INT: question6Selection,
            POS_EVT_OCC: question7YesNot,
            POS_EVT_TYPE: question7OpenText,
            POS_EVT_INT: question8Selection,
            DYS_BEH: question9YesNot,
            DYS_BEH_TYPE: question9OpenText,
            PHY_ACT: question10YesNoAnswer,
            PHY_ACT_TYPE: question10FirstChoices.map(String.init).joined(separator: ","),
            PHY_ACT_INT: question10SecondChoice,
            SLEEP_HR: question11Selection,
            SLEEP_SAT: question12Selection,
            SLEEP_ONSET: question13Selection,
            SLEEP_MAINT: question14Selection,
            DAILY_NAP: question15Selection,
            PERC_EFF: slider16Value
        ) { success, message in
            DispatchQueue.main.async {
                self.logMessage("Invio dati completato: \(success ? "successo" : "fallito") - \(message)")
                
                if !success {
                    // ⚠️ ERRORE: mostra alert e resetta come se avesse risposto
                    self.sendErrorMessage = message
                    self.showSendErrorAlert = true
                    self.logMessage("⚠️ Invio fallito, utente informato con alert")
                    
                    // Resetta lo stato del questionario (torna a "Attendere notifica")
                    self.appStateManager.hasCompletedQuestionnaire = false
                    self.appStateManager.isQuestionnaireAvailable = false
                    self.appStateManager.activeNotificationType = nil
                    self.appStateManager.currentQuestionIndex = 0
                    self.randomizedQuestionIndices = []
                    NotificationManager.shared.clearBadge()
                    
                    return
                }
                
                // ✅ SUCCESSO: procedi con cancellazione notifiche e completamento
                
                // ✅ CANCELLA LE NOTIFICHE REMINDER ED EXPIRED
                if let notificationDate = notificationScheduledDate {
                    NetworkManager.shared.cancelPendingNotifications(
                        codice_soggetto: userCode,
                        notificationType: questionnaireType,
                        notificationDate: notificationDate
                    ) { cancelSuccess, cancelMessage in
                        if cancelSuccess {
                            self.logMessage("✅ Notifiche REMINDER/EXPIRED cancellate con successo")
                        } else {
                            self.logMessage("⚠️ Errore cancellazione notifiche: \(cancelMessage)")
                        }
                    }
                }
                
                // ✅ Resetta badge
                NotificationManager.shared.clearBadge()
            }
        }
    }

    private func completionScreen() -> AnyView {
        AnyView(
            VStack {
                Text("Complimenti, hai completato il questionario!")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
            }
        )
    }
}
