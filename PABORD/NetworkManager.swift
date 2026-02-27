// NetworkManager.swift
// PABORD
//
// Created by Neuroinformatica on 05/06/25.
//

import Foundation

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()

    private let authAndNotificationsUrl = "https://www.newpsy4u.eu/scripts_iOS/PABORD_credentials_iOS.php"
    private let surveyDataUrl = "https://www.newpsy4u.eu/scripts_android/PABORD/PABORD_Save_Data.php"
    private let syncDataUrl = "https://www.newpsy4u.eu/scripts_android/PABORD/PABORD_synchro_db.php"

    private let unsentSurveyDataKey = "unsentSurveyData"

    @Published var lastDailySyncDate: Date? = UserDefaults.standard.object(forKey: "lastDailySyncDate") as? Date

    private init() {}

    func authenticateAndFetchNotificationTimes(userCode: String, accessCode: String, completion: @escaping (Bool, [Date]?, String?) -> Void) {
        guard var components = URLComponents(string: authAndNotificationsUrl) else {
            completion(false, nil, "URL di autenticazione non valido.")
            return
        }

        components.queryItems = [
            URLQueryItem(name: "codice_soggetto", value: userCode),
            URLQueryItem(name: "codice_controllo", value: accessCode)
        ]

        guard let url = components.url else {
            completion(false, nil, "Impossibile costruire l'URL di autenticazione.")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(false, nil, "Errore di rete durante l'autenticazione: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(false, nil, "Risposta del server di autenticazione non valida o errore. Codice: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return
            }

            guard let data = data else {
                completion(false, nil, "Nessun dato ricevuto dal server di autenticazione.")
                return
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("NetworkManager RAW Server Response: \(jsonString)")
            }
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let status = jsonResponse["status"] as? String {

                    if status == "success", let notifications = jsonResponse["notifications"] as? [[String: Any]] {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                        dateFormatter.locale = Locale(identifier: "it_IT")
                        dateFormatter.timeZone = TimeZone(identifier: "Europe/Rome")

                        var scheduledDates: [Date] = []
                        for notificationData in notifications {
                            if let timePointString = notificationData["notifica"] as? String,
                               let date = dateFormatter.date(from: timePointString) {
                                scheduledDates.append(date)
                            } else {
                                print("NetworkManager: Errore nel parsing di una data di notifica: \(notificationData["notifica"] ?? "N/A")")
                            }
                        }
                        scheduledDates.sort()
                        print("NetworkManager: Parsed and sorted notification dates: \(scheduledDates)")
                        completion(true, scheduledDates, nil)

                    } else if status == "error", let message = jsonResponse["message"] as? String {
                        completion(false, nil, message)
                    } else {
                        completion(false, nil, "Formato risposta JSON sconosciuto dal server di autenticazione.")
                    }
                } else {
                    completion(false, nil, "Dati JSON non validi dal server di autenticazione.")
                }
            } catch {
                completion(false, nil, "Errore di parsing JSON dall'autenticazione: \(error.localizedDescription)")
            }
        }.resume()
    }

    /// Funzione per inviare i dati del questionario al server.
    func sendSurveyData(
        codice_soggetto: String,
        lastOpenTime: Date?,
        notifica: Date?,
        data_ora_risposta: Date,
        ALERT_TIRED: Int?,
        HAPPY_UNHAPPY: Int?,
        AGIT_CALM: Int?,
        ENERGY: Int?,
        WELL_BEING: Int?,
        RELAX_TENSE: Int?,
        SOC_CONN: Int?,
        ACT_TRACK: Int?,
        SOC_INT: Int?,
        IMP_NEG_URG: Int?,
        IMP_POS_URG: Int?,
        IMP_LACK_PREM: Int?,
        IMP_LACK_PERS: Int?,
        IMP_SENS_SEEK: Int?,
        STRESS_EVT_OCC: Int?,
        STRESS_EVT_TYPE: String,
        STRESS_EVT_INT: Int?,
        POS_EVT_OCC: Int?,
        POS_EVT_TYPE: String,
        POS_EVT_INT: Int?,
        DYS_BEH: Int?,
        DYS_BEH_TYPE: String,
        PHY_ACT: Int?,
        PHY_ACT_TYPE: String,
        PHY_ACT_INT: Int?,
        SLEEP_HR: Int?,
        SLEEP_SAT: Int?,
        SLEEP_ONSET: Int?,
        SLEEP_MAINT: Int?,
        DAILY_NAP: Int?,
        PERC_EFF: Int?,
        completion: @escaping (Bool, String) -> Void
    ) {
        guard let url = URL(string: surveyDataUrl) else {
            completion(false, "URL per l'invio dei dati non valido")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "Europe/Rome")
        
        // Formatter separato per notifica (SENZA secondi nella stringa)
        let notificaFormatter = DateFormatter()
        notificaFormatter.dateFormat = "yyyy-MM-dd HH:mm"  // ✅ SENZA :ss
        notificaFormatter.locale = Locale(identifier: "en_US_POSIX")
        notificaFormatter.timeZone = TimeZone(identifier: "Europe/Rome")

        let formattedLastOpenTime = lastOpenTime.map { dateFormatter.string(from: $0) } ?? ""
        let formattedNotifica = notifica.map { notificaFormatter.string(from: $0) } ?? ""  // ✅ Usa formatter senza secondi
        let formattedDataOraRisposta = dateFormatter.string(from: data_ora_risposta)

        func intToString(_ value: Int?) -> String {
            return value.map(String.init) ?? ""
        }

        var postItems: [String] = []

        postItems.append("codice_soggetto=\(codice_soggetto.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        postItems.append("notifica=\(formattedNotifica.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        postItems.append("lastOpenTime=\(formattedLastOpenTime.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        postItems.append("data_ora_risposta=\(formattedDataOraRisposta.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        postItems.append("ALERT_TIRED=\(intToString(ALERT_TIRED))")
        postItems.append("HAPPY_UNHAPPY=\(intToString(HAPPY_UNHAPPY))")
        postItems.append("AGIT_CALM=\(intToString(AGIT_CALM))")
        postItems.append("ENERGY=\(intToString(ENERGY))")
        postItems.append("WELL_BEING=\(intToString(WELL_BEING))")
        postItems.append("RELAX_TENSE=\(intToString(RELAX_TENSE))")
        postItems.append("SOC_CONN=\(intToString(SOC_CONN))")
        postItems.append("ACT_TRACK=\(intToString(ACT_TRACK))")
        postItems.append("SOC_INT=\(intToString(SOC_INT))")
        postItems.append("IMP_NEG_URG=\(intToString(IMP_NEG_URG))")
        postItems.append("IMP_POS_URG=\(intToString(IMP_POS_URG))")
        postItems.append("IMP_LACK_PREM=\(intToString(IMP_LACK_PREM))")
        postItems.append("IMP_LACK_PERS=\(intToString(IMP_LACK_PERS))")
        postItems.append("IMP_SENS_SEEK=\(intToString(IMP_SENS_SEEK))")
        postItems.append("STRESS_EVT_OCC=\(intToString(STRESS_EVT_OCC))")
        postItems.append("STRESS_EVT_TYPE=\(STRESS_EVT_TYPE.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        postItems.append("STRESS_EVT_INT=\(intToString(STRESS_EVT_INT))")
        postItems.append("POS_EVT_OCC=\(intToString(POS_EVT_OCC))")
        postItems.append("POS_EVT_TYPE=\(POS_EVT_TYPE.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        postItems.append("POS_EVT_INT=\(intToString(POS_EVT_INT))")
        postItems.append("DYS_BEH=\(intToString(DYS_BEH))")
        postItems.append("DYS_BEH_TYPE=\(DYS_BEH_TYPE.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        postItems.append("PHY_ACT=\(intToString(PHY_ACT))")
        postItems.append("PHY_ACT_TYPE=\(PHY_ACT_TYPE.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        postItems.append("PHY_ACT_INT=\(intToString(PHY_ACT_INT))")
        postItems.append("SLEEP_HR=\(intToString(SLEEP_HR))")
        postItems.append("SLEEP_SAT=\(intToString(SLEEP_SAT))")
        postItems.append("SLEEP_ONSET=\(intToString(SLEEP_ONSET))")
        postItems.append("SLEEP_MAINT=\(intToString(SLEEP_MAINT))")
        postItems.append("DAILY_NAP=\(intToString(DAILY_NAP))")
        postItems.append("PERC_EFF=\(intToString(PERC_EFF))")

        let bodyString = postItems.joined(separator: "&")

        print("Generated POST string: \(bodyString)")

        request.httpBody = bodyString.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("NetworkManager: Errore di rete, salvataggio dati in locale.")
                self.saveDataLocally(params: postItems)
                DispatchQueue.main.async {
                    completion(false, "Errore nella connessione. Dati salvati in locale.")
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Risposta server invio dati: \(responseString)")
                        completion(true, "Dati inviati con successo! Risposta server: \(responseString)")
                    } else {
                        completion(true, "Dati inviati con successo (nessuna risposta dal server).")
                    }
                } else {
                    let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Nessun corpo di risposta"
                    print("Errore nel server durante l'invio dati. Codice HTTP: \(httpResponse.statusCode), Body: \(responseBody)")
                    self.saveDataLocally(params: postItems)
                    DispatchQueue.main.async {
                        completion(false, "Errore nel server. Dati salvati in locale.")
                    }
                }
            } else {
                print("NetworkManager: Risposta non HTTP, salvataggio dati in locale.")
                self.saveDataLocally(params: postItems)
                DispatchQueue.main.async {
                    completion(false, "Risposta non HTTP. Dati salvati in locale.")
                }
            }
        }

        task.resume()
    }

    private func saveDataLocally(params: [String]) {
        if var savedData = UserDefaults.standard.array(forKey: unsentSurveyDataKey) as? [[String]] {
            savedData.append(params)
            UserDefaults.standard.set(savedData, forKey: unsentSurveyDataKey)
        } else {
            let newData = [params]
            UserDefaults.standard.set(newData, forKey: unsentSurveyDataKey)
        }
        print("NetworkManager: Dati salvati localmente. Totale record: \((UserDefaults.standard.array(forKey: unsentSurveyDataKey) as? [[String]])?.count ?? 0)")
    }

    /// Tenta di inviare tutti i dati salvati in locale al server di sincronizzazione.
    func synchronizeSavedData(completion: @escaping (Bool, String) -> Void) {
        guard var savedData = UserDefaults.standard.array(forKey: unsentSurveyDataKey) as? [[String]], !savedData.isEmpty else {
            completion(true, "Nessun dato da sincronizzare.")
            return
        }

        let totalRecords = savedData.count
        var recordsSent = 0
        var recordsFailed = 0

        let syncQueue = DispatchQueue(label: "com.pabord.syncQueue", qos: .background)
        let group = DispatchGroup()

        syncQueue.async {
            for (index, record) in savedData.enumerated() {
                group.enter()
                
                let bodyString = record.joined(separator: "&")
                
                guard let url = URL(string: self.syncDataUrl) else {
                    print("URL di sincronizzazione non valido per il record \(index).")
                    recordsFailed += 1
                    group.leave()
                    continue
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = bodyString.data(using: .utf8)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Errore di sincronizzazione per il record \(index): \(error.localizedDescription)")
                        recordsFailed += 1
                    } else if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            if let responseString = data.flatMap({ String(data: $0, encoding: .utf8) }) {
                                if responseString.contains("OK") {
                                    recordsSent += 1
                                    print("Sincronizzazione riuscita per il record \(index).")
                                } else {
                                    recordsFailed += 1
                                    print("Sincronizzazione fallita per il record \(index). Risposta server inattesa: \(responseString)")
                                }
                            } else {
                                recordsSent += 1
                                print("Sincronizzazione riuscita per il record \(index).")
                            }
                        } else {
                            let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Nessun corpo di risposta"
                            print("Sincronizzazione fallita per il record \(index). Codice HTTP: \(httpResponse.statusCode), Body: \(responseBody)")
                            recordsFailed += 1
                        }
                    } else {
                        print("Sincronizzazione fallita per il record \(index). Risposta non HTTP.")
                        recordsFailed += 1
                    }
                    group.leave()
                }
                task.resume()
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            group.notify(queue: .main) {
                var finalSavedData = UserDefaults.standard.array(forKey: self.unsentSurveyDataKey) as? [[String]] ?? []
                
                if recordsSent > 0 {
                    finalSavedData = Array(finalSavedData.dropFirst(recordsSent))
                    UserDefaults.standard.set(finalSavedData, forKey: self.unsentSurveyDataKey)
                }
                
                let success = recordsSent > 0
                let message = "Sincronizzazione completata. \(recordsSent) di \(totalRecords) record inviati con successo, \(recordsFailed) falliti."
                print(message)
                completion(success, message)
            }
        }
    }

    /// Funzione di sincronizzazione con una versione semplificata per `ContentView`.
    func synchronizeUnsentData(completion: @escaping () -> Void) {
        self.synchronizeSavedData { success, message in
            if success {
                print("Sincronizzazione dati non inviati: \(message)")
            } else {
                print("Sincronizzazione dati non inviati fallita: \(message)")
            }
            completion()
        }
    }
}
// Aggiungi questa funzione alla classe NetworkManager esistente

extension NetworkManager {
    
    /// Invia il device token al server per abilitare le notifiche push
    func sendDeviceToken(token: String, completion: @escaping (Bool, String) -> Void) {
        
        guard let userCode = AppStateManager.shared.currentUserCode else {
            completion(false, "Codice utente non disponibile")
            return
        }
        
        let urlString = "https://www.newpsy4u.eu/scripts_iOS/PABORD_save_device_token.php"
        
        guard let url = URL(string: urlString) else {
            completion(false, "URL non valido")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Determina il tipo di dispositivo
        let deviceType = "ios" // Puoi usare "ios_test" per la modalità test se necessario
        
        let bodyString = "codice_soggetto=\(userCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&device_token=\(token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&device_type=\(deviceType)"
        
        request.httpBody = bodyString.data(using: .utf8)
        
        print("📤 Invio device token al server per utente: \(userCode)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Errore di rete: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "Risposta del server non valida")
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Risposta server device token: \(responseString)")
                    
                    // Verifica se la risposta contiene "success"
                    if responseString.contains("success") || responseString.contains("OK") {
                        DispatchQueue.main.async {
                            completion(true, "Device token salvato con successo")
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(false, "Risposta server: \(responseString)")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(true, "Device token inviato")
                    }
                }
            } else {
                let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Nessuna risposta"
                DispatchQueue.main.async {
                    completion(false, "Errore HTTP \(httpResponse.statusCode): \(responseBody)")
                }
            }
        }.resume()
    }
    
    /// Aggiorna il device token quando l'utente fa login
    func updateDeviceTokenOnLogin(userCode: String) {
        if let savedToken = UserDefaults.standard.string(forKey: "deviceToken") {
            print("🔄 Aggiornamento device token per nuovo utente: \(userCode)")
            sendDeviceToken(token: savedToken) { success, message in
                if success {
                    print("✅ Device token aggiornato per nuovo utente")
                } else {
                    print("⚠️ Errore aggiornamento device token: \(message)")
                }
            }
        }
    }
    
    /// Cancella le notifiche REMINDER ed EXPIRED dal server
    func cancelPendingNotifications(
        codice_soggetto: String,
        notificationType: Int,
        notificationDate: Date,
        completion: @escaping (Bool, String) -> Void
    ) {
        let urlString = "https://www.newpsy4u.eu/scripts_iOS/PABORD_cancel_notifications.php"
        
        guard let url = URL(string: urlString) else {
            completion(false, "URL non valido")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "Europe/Rome")
        
        let dateString = dateFormatter.string(from: notificationDate)
        
        let bodyString = "codice_soggetto=\(codice_soggetto.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&notification_type_daily=\(notificationType)&notification_date=\(dateString)"
        
        request.httpBody = bodyString.data(using: .utf8)
        
        print("🗑️ Cancellazione notifiche: utente=\(codice_soggetto), tipo=\(notificationType), data=\(dateString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Errore di rete: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "Risposta non valida")
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Risposta cancellazione: \(responseString)")
                    
                    if responseString.contains("success") {
                        DispatchQueue.main.async {
                            completion(true, "Notifiche cancellate con successo")
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(false, responseString)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(true, "Notifiche cancellate")
                    }
                }
            } else {
                let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Nessuna risposta"
                DispatchQueue.main.async {
                    completion(false, "Errore HTTP \(httpResponse.statusCode): \(responseBody)")
                }
            }
        }.resume()
    }
}
