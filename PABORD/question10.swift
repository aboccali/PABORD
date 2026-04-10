//
//  question10.swift
//  PABORD
//
//  Created by Neuroinformatica on 06/05/25.
//

import SwiftUI

struct Question10View: View {
    @Binding var question10YesNoAnswer: Int
    @Binding var question10FirstChoices: [Int]
    @Binding var question10SecondChoice: Int?

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
                Button {
                    hasEvent = false
                    question10YesNoAnswer = 0
                    question10FirstChoices = []
                    question10SecondChoice = nil
                    showAlert = false
                } label: {
                    Text("No")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(hasEvent == false ? Color.orange : Color.gray.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)

                Button {
                    hasEvent = true
                    question10YesNoAnswer = 1
                    showAlert = false
                } label: {
                    Text("Sì")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
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
                                .frame(maxWidth: .infinity)
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
                                .frame(maxWidth: .infinity)
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
                Button {
                    if firstStepDone {
                        firstStepDone = false
                    } else {
                        onIndietro()
                    }
                } label: {
                    Text("Indietro")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .foregroundColor(.orange)

                Button {
                    guard let hasSelected = hasEvent else {
                        showAlert = true
                        return
                    }

                    if hasSelected && !firstStepDone {
                        if firstSelected.isEmpty {
                            showAlert = true
                            return
                        }
                        question10FirstChoices = Array(firstSelected).sorted()
                        firstStepDone = true
                        return
                    }

                    if hasSelected && firstStepDone {
                        guard let selected = secondSelected else {
                            showAlert = true
                            return
                        }
                        question10SecondChoice = selected
                        onAvanti()
                        return
                    }

                    if !hasSelected {
                        question10YesNoAnswer = 0
                        question10FirstChoices = []
                        question10SecondChoice = nil
                        onAvanti()
                    }
                } label: {
                    Text("Avanti")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
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
