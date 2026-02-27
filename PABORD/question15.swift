//
//  question15.swift
//  PABORD
//
//  Created by Neuroinformatica on 06/05/25.
//

import SwiftUI

struct Question15View: View {
    @Binding var question15Choice: Int     // Deve iniziare a -1 nel contenitore
    var onAvanti: () -> Void
    var onIndietro: () -> Void

    @State private var showAlert = false

    let options = [
        (0, "No"),
        (1, "Sì, meno di 30 minuti"),
        (2, "Sì, tra 30 minuti e 1 ora"),
        (3, "Sì, più di 1 ora")
    ]

    var body: some View {
        VStack {
            Spacer()

            Text("Ha fatto un sonnellino durante il giorno?")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            ScrollView {
                VStack(spacing: 15) {
                    ForEach(options, id: \.0) { (id, text) in
                        Button(action: {
                            question15Choice = id
                            showAlert = false
                        }) {
                            HStack {
                                Text(text)
                                    .foregroundColor(.white)
                                    .padding()
                                Spacer()
                                if question15Choice == id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .padding()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .background(question15Choice == id ? Color.orange : Color.gray.opacity(0.8))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            HStack {
                Button("Indietro") {
                    onIndietro()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .foregroundColor(.orange)

                Button("Avanti") {
                    if question15Choice == -1 {
                        showAlert = true
                        return
                    }
                    onAvanti()
                }
                .padding()
                .frame(maxWidth: .infinity)
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
            .padding(.horizontal)
        }
        .padding()
    }
}
