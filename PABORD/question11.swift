//
//  question11.swift
//  PABORD
//
//  Created by Neuroinformatica on 06/05/25.
//

import SwiftUI

struct Question11View: View {
    @Binding var question11Choice: Int

    var onAvanti: () -> Void
    var onIndietro: () -> Void

    @State private var inputText: String = ""
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Quante ore ha dormito la scorsa notte? (Inserisca una cifra)")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            TextField("Inserisci il numero di ore", text: $inputText)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                .frame(maxWidth: 200)

            Spacer()

            HStack {
                Button("Indietro") {
                    onIndietro()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.orange)

                Button("Avanti") {
                    if let value = Int(inputText), value >= 0 && value <= 99 {
                        question11Choice = value
                        showAlert = false
                        onAvanti()
                    } else {
                        showAlert = true
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Valore non valido"),
                        message: Text("Inserisci un numero intero tra 0 e 24."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        .padding()
        .onAppear {
            inputText = question11Choice > 0 ? "\(question11Choice)" : ""
        }
    }
}
