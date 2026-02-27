//
//  question10.swift
//  PABORD
//
//  Created by Neuroinformatica on 06/05/25.
//


import SwiftUI

struct Question10View: View {
    @Binding var question10YesNoAnswer: Int             // 0 per No, 1 per Sì
    @Binding var question10FirstChoices: [Int]          // Scelte multiple
    @Binding var question10SecondChoice: Int            // Scelta singola

    var onAvanti: () -> Void
    var onIndietro: () -> Void

    @State private var hasEvent: Bool? = nil
    @State private var firstStepDone = false
    @State private var firstSelected: Set<Int> = []
    @State private var secondSelected: Int? = nil
    @State private var showAlert = false

    let firstOptions: [(Int, String)] = [
        (1, "Attività domestiche (pulizie, giardinaggio, ecc)"),
        (2, "Lavoro fisico (caricare, trasportare oggetti, ecc)"),
        (3, "Allenamento in autonomia (es: camminata, corsa o jogging)"),
        (4, "Allenamento assistito o allenamento con trainer (es: palestra, yoga, pilates, corsi fitness)"),
        (5, "Attività sportiva di squadra (es: pallavolo, calcio, basket, nuoto, ciclismo, ecc)"),
        
    ]

    let secondOptions: [(Int, String)] = [
        (1, "Leggera (es: passeggiata tranquilla, stretching)"),
        (2, "Moderata (es: camminata veloce, yoga)"),
        (3, "Alta (es: corsa, allenamento intenso, sport)"),
        (4, "Molto alta (es: allenamento ad alta intensità, sollevamento pesi pesanti, attività fisica intensa per un lungo periodo)")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Ha svolto qualche tipo di attività fisica nel corso della giornata?")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack {
                Button("No") {
                    hasEvent = false
                    question10YesNoAnswer = 0
                    question10FirstChoices = []
                    question10SecondChoice = 0
                    showAlert = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(hasEvent == false ? Color.orange : Color.gray.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Sì") {
                    hasEvent = true
                    question10YesNoAnswer = 1
                    showAlert = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(hasEvent == true ? Color.orange : Color.gray.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            if hasEvent == true && !firstStepDone {
                Text("Che tipo di attività fisica ha svolto? (Selezioni una o più opzioni)")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(firstOptions, id: \.0) { option in
                            Button(action: {
                                if firstSelected.contains(option.0) {
                                    firstSelected.remove(option.0)
                                } else {
                                    firstSelected.insert(option.0)
                                }
                                showAlert = false
                            }) {
                                HStack {
                                    Text(option.1)
                                        .font(.body)
                                        .foregroundColor(.white)
                                    Spacer()
                                    if firstSelected.contains(option.0) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(firstSelected.contains(option.0) ? Color.orange : Color.gray.opacity(0.8))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 250)
            }

            if firstStepDone {
                Text("Indichi l'intensità dell'attività fisica che ha svolto:")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(secondOptions, id: \.0) { option in
                            Button(action: {
                                secondSelected = option.0
                                showAlert = false
                            }) {
                                HStack {
                                    Text(option.1)
                                        .font(.body)
                                        .foregroundColor(.white)
                                    Spacer()
                                    if secondSelected == option.0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(secondSelected == option.0 ? Color.orange : Color.gray.opacity(0.8))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            }

            Spacer()

            HStack {
                Button("Indietro") {
                    if firstStepDone {
                        firstStepDone = false
                    } else {
                        onIndietro()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.orange)

                Button("Avanti") {
                    // Controllo iniziale: non ha scelto sì/no
                    guard let hasSelected = hasEvent else {
                        showAlert = true
                        return
                    }

                    // Se ha detto Sì ma non ha ancora concluso il primo step
                    if hasSelected && !firstStepDone {
                        if firstSelected.isEmpty {
                            showAlert = true
                            return
                        }
                        question10FirstChoices = Array(firstSelected).sorted()
                        firstStepDone = true
                        return
                    }

                    // Se ha detto Sì ed è al secondo step
                    if hasSelected && firstStepDone {
                        guard let selected = secondSelected else {
                            showAlert = true
                            return
                        }
                        question10SecondChoice = selected
                        onAvanti()
                        return
                    }

                    // Se ha detto No
                    if !hasSelected {
                        question10YesNoAnswer = 0
                        question10FirstChoices = []
                        question10SecondChoice = 0
                        onAvanti()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Attenzione"),
                        message: Text("Per favore risponda alla domanda prima di continuare."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        .padding()
    }
}

