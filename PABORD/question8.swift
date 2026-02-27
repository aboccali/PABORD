//
//  question8.swift
//  PABORD
//
//  Created by Neuroinformatica on 05/05/25.
//
import SwiftUI

struct Question8View: View {
    @Binding var question8Choice: Int
    var onAvanti: () -> Void
    var onIndietro: () -> Void

    @State private var showAlert = false

    let options = [
        (0, "Nessun evento positivo significativo"),
        (1, "Molto lieve"),
        (2, "Lieve"),
        (3, "Moderato"),
        (4, "Intenso"),
        (5, "Molto intenso"),
        (6, "Estremamente intenso")
    ]

    var body: some View {
        VStack {
            Spacer()

            Text("Considerando l'evento positivo più significativo che le è accaduto, quanto è stato intenso?")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            ScrollView {
                VStack(spacing: 15) {
                    ForEach(options, id: \.0) { (id, text) in
                        Button(action: {
                            question8Choice = id
                            showAlert = false
                        }) {
                            HStack {
                                Text(text)
                                    .foregroundColor(.white)
                                    .padding()
                                Spacer()
                                if question8Choice == id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .padding()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .background(question8Choice == id ? Color.orange : Color.gray.opacity(0.8))
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
                    if question8Choice == -1 {
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
