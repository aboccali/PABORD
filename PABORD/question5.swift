//
//  question5.swift
//  PABORD
//
//  Created by Neuroinformatica on 29/04/25.
//


import SwiftUI

struct Question5View: View {
    @Binding var question5YesNoAnswer: Int  // 0 per No, 1 per Sì
    @Binding var question5Choice: Int       // da 1 a 7
    @Binding var openResponseText5: String   // testo libero per "Altro"

    var onAvanti: () -> Void
    var onIndietro: () -> Void

    @State private var hasStressEvent: Bool? = nil
    @State private var selectedOption: Int? = nil
    @State private var otherText: String = ""
    @State private var showAlert = false

    let stressOptions: [(Int, String)] = [
        (1, "Ho affrontato difficoltà lavorative o economiche (es: discussioni con colleghi o con datore di lavoro, perdita del lavoro, problemi finanziari)"),
        (2, "Ho avuto problemi o cambiamenti importanti nelle relazioni personali (rottura con il/la partner, conflitti con familiari o amici)"),
        (3, "Ho avuto problemi di salute, miei o di una persona a me cara (es: malattie, infortuni, diagnosi importanti)"),
        (4, "Ho subito una perdita affettiva (es: morte di una persona cara o animale domestico)"),
        (5, "Ho vissuto cambiamenti significativi nella mia vita domestica (es: traslochi, ristrutturazioni, acquisto o vendita della casa)"),
        (6, "Ho vissuto eventi traumatici o destabilizzanti (es: separazione dei genitori, abusi fisici o sessuali)"),
        (7, "Altro...")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Da quando si è alzata le sono capitati uno o più eventi per lei stressanti?")
                .font(.title)
                .multilineTextAlignment(.center)

            HStack {
                Button("No") {
                    hasStressEvent = false
                    question5YesNoAnswer = 0
                    question5Choice = 0
                    openResponseText5 = ""
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
                    question5YesNoAnswer = 1
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
                    Text("Scelga dall'elenco seguente quello che somiglia di più all'evento stressante a cui ha pensato. Selezioni quello per lei più significativo:")
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
                        question5YesNoAnswer = 0
                        question5Choice = 0
                        openResponseText5 = ""
                        onAvanti()
                    } else {
                        guard let selected = selectedOption else {
                            showAlert = true
                            return
                        }

                        question5Choice = selected

                        if selected == 7 {
                            openResponseText5 = otherText
                        } else {
                            openResponseText5 = ""
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
                        message: Text("Per favore rispondi alla domanda prima di continuare."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        .padding()
    }
}
