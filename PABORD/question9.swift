//
//  question9.swift
//  PABORD
//
//  Created by Neuroinformatica on 05/05/25.
//

import SwiftUI

struct Question9View: View {
    @Binding var question9YesNoAnswer: Int
    @Binding var question9Choices: [Int]
    @Binding var openResponseText9: String

    var onAvanti: () -> Void
    var onIndietro: () -> Void

    @State private var hasStressEvent: Bool? = nil
    @State private var selectedOptions: Set<Int> = []
    @State private var otherText: String = ""
    @State private var showAlert = false

    @State private var showInfoPopup = false

    let stressOptions: [(Int, String)] = [
        (1, "Comportamento ad alto rischio (es: guidare ad altissima velocità in città)"),
        (2, "Tagli/graffi/bruciature"),
        (3, "Testate o pugni al muro"),
        (4, "Sesso promiscuo"),
        (5, "Abuso di alcol, droghe o farmaci"),
        (6, "Abbuffate/restrizioni alimentari"),
        (7, "Altri...")
    ]

    let maxPopupCount = 2000
    let popupCountKey = "question9PopupShownCount"

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 20) {
                Spacer()

                Text("Da quando si è alzata le è capitato di mettere in atto uno o più di questi comportamenti disfunzionali?")
                    .font(.title)
                    .multilineTextAlignment(.center)

                HStack {
                    Button("No") {
                        hasStressEvent = false
                        question9YesNoAnswer = 0
                        question9Choices = []
                        openResponseText9 = ""
                        selectedOptions = []
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
                        question9YesNoAnswer = 1
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
                        Text("Quali comportamenti disfunzionali ha messo in atto? (può selezionare anche più opzioni)")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(stressOptions, id: \.0) { option in
                                    Button(action: {
                                        if selectedOptions.contains(option.0) {
                                            selectedOptions.remove(option.0)
                                        } else {
                                            selectedOptions.insert(option.0)
                                        }
                                        showAlert = false
                                    }) {
                                        HStack(alignment: .top) {
                                            Text(option.1)
                                                .font(.body)
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .foregroundColor(.white)
                                            Spacer()
                                            if selectedOptions.contains(option.0) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        .padding()
                                        .background(selectedOptions.contains(option.0) ? Color.orange : Color.gray.opacity(0.8))
                            
                                        .cornerRadius(10)
                                    }
                                }

                                if selectedOptions.contains(7) {
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
                            question9YesNoAnswer = 0
                            question9Choices = []
                            openResponseText9 = ""
                            onAvanti()
                        } else {
                            if selectedOptions.isEmpty {
                                showAlert = true
                                return
                            }

                            question9Choices = Array(selectedOptions).sorted()

                            if selectedOptions.contains(7) {
                                openResponseText9 = otherText
                            } else {
                                openResponseText9 = ""
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

            // Info popup overlay
            if showInfoPopup {
                Color.black.opacity(0.4).ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Attenzione")
                        .font(.title)
                        .bold()
                    Text("I comportamenti disfunzionali sono comportamenti che possono essere vantaggiosi a breve termine, ma dannosi a medio e lungo termine. Esempi di comportamenti disfunzionali sono: l'autolesionismo, l'abuso di alcool, le abbuffate o il vomito, i comportamenti ad alto rischio (es: guida ad alta velocità), gli acquisti fatti in modo compulsivo, e l'impulsività sessuale.")
                        .multilineTextAlignment(.center)
                        .padding()

                    Button(action: {
                        showInfoPopup = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding()
            }
        }
        .onAppear {
            let shownCount = UserDefaults.standard.integer(forKey: popupCountKey)
            if shownCount < maxPopupCount {
                showInfoPopup = true
                //UserDefaults.standard.set(shownCount + 1, forKey: popupCountKey)
            }
        }
    }
}
