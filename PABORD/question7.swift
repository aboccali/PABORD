//
//  question7.swift
//  PABORD
//
//  Created by Neuroinformatica on 05/05/25.
//

import SwiftUI

struct Question7View: View {
    @Binding var question7YesNoAnswer: Int  // 0 per No, 1 per Sì
    @Binding var question7Choice: Int       // da 1 a 7
    @Binding var openResponseText7: String   // testo libero per "Altro"

    var onAvanti: () -> Void
    var onIndietro: () -> Void

    @State private var hasStressEvent: Bool? = nil
    @State private var selectedOption: Int? = nil
    @State private var otherText: String = ""
    @State private var showAlert = false

    let stressOptions: [(Int, String)] = [
        (1, "Ho avuto esperienze positive sul lavoro (es: comunicazioni costruttive, complimenti dal datore di lavoro o dai colleghi)"),
        (2, "Ho trascorso momenti piacevoli o significativi con il partner, la famiglia o una persona speciale (es: cene, uscite, conversazioni"),
        (3, "Ho partecipato ad eventi sociali o condiviso momenti speciali con gli altri (es: feste, cene, momenti con amici)"),
        (4, "Ho ricevuo supporto o affetto da persone vicine (es: amici, familiari, partner, figli"),
        (5, "Ho portato a termine un compito o un'attività con soddisfazione (es: riordino, pulizie, obiettvi personali)"),
        (6, "Ho dedicato del tempo a me stessa e alle mie passioni (es: hobby, attività gratificanti, relax"),
        (7, "Altro...")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Da quando si è alzata ha vissuto uno o più eventi per lei positivi?")
                .font(.title)
                .multilineTextAlignment(.center)

            HStack {
                Button("No") {
                    hasStressEvent = false
                    question7YesNoAnswer = 0
                    question7Choice = 0
                    openResponseText7 = ""
                    selectedOption = nil
                    otherText = ""
                    showAlert = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(hasStressEvent == false ? Color.orange : Color.gray.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Sì") {
                    hasStressEvent = true
                    question7YesNoAnswer = 1
                    showAlert = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(hasStressEvent == true ? Color.orange : Color.gray.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            if hasStressEvent == true {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Scelga dall'elenco seguente quello che somiglia di più all'evento positivo a cui ha pensato. Selezioni quello per lei più significativo:")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(stressOptions, id: \.0) { option in
                                Button(action: {
                                    selectedOption = option.0
                                    showAlert = false
                                }) {
                                    HStack(alignment: .top) {
                                        Text(option.1)
                                            .font(.body)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .foregroundColor(.white)
                                        Spacer()
                                        if selectedOption == option.0 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding()
                                    .background(selectedOption == option.0 ? Color.orange : Color.gray.opacity(0.8))
                                    .cornerRadius(10)
                                }
                            }

                            if selectedOption == 7 {
                                TextField("Scrivi qui...", text: $otherText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 300)
                }
            }

            Spacer()

            HStack {
                Button("Indietro") {
                    onIndietro()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.orange)

                Button("Avanti") {
                    guard let hasEvent = hasStressEvent else {
                        showAlert = true
                        return
                    }

                    if !hasEvent {
                        question7YesNoAnswer = 0
                        question7Choice = 0
                        openResponseText7 = ""
                        onAvanti()
                    } else {
                        guard let selected = selectedOption else {
                            showAlert = true
                            return
                        }

                        question7Choice = selected

                        if selected == 7 {
                            openResponseText7 = otherText
                        } else {
                            openResponseText7 = ""
                        }

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
                        message: Text("Per favore, rispondi alla domanda prima di continuare."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        .padding()
    }
}
