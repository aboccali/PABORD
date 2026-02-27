//
//  question14.swift
//  PABORD
//
//  Created by Neuroinformatica on 06/05/25.
//

import SwiftUI

struct Question14View: View {
    @Binding var question14Choice: Int
    var onAvanti: () -> Void
    var onIndietro: () -> Void

    @State private var showAlert = false

    let options = [
        (0, "No"),
        (1, "Sì, una volta"),
        (2, "Sì, più di una volta")
    ]

    var body: some View {
        VStack {
            Spacer()

            Text("Ha avuto risvegli notturni la scorsa notte?")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            ScrollView {
                VStack(spacing: 15) {
                    ForEach(options, id: \.0) { (id, text) in
                        Button(action: {
                            question14Choice = id
                            showAlert = false
                        }) {
                            HStack {
                                Text(text)
                                    .foregroundColor(.white)
                                    .padding()
                                Spacer()
                                if question14Choice == id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .padding()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .background(question14Choice == id ? Color.orange : Color.gray.opacity(0.8))
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
                    if question14Choice == -1 {
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
                        message: Text("Per favore, rispondi alla domanda prima di continuare."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
