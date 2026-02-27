//
//  question13.swift
//  PABORD
//
//  Created by Neuroinformatica on 05/05/25.
//

import SwiftUI

struct Question13View: View {
    @Binding var question13Choice: Int
    var onAvanti: () -> Void
    var onIndietro: () -> Void

    // Elenco delle opzioni (puoi aggiungerne facilmente altre)
    let options = [
        (1, "Meno di 15 minuti"),
        (2, "15-30 minuti"),
        (3, "30-60 minuti"),
        (4, "Più di 60 minuti"),
        
        ]

    var body: some View {
        VStack {
            Spacer()

            Text("Quanto tempo ha impiegato ad addormentarsi la scorsa notte?")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            ScrollView {
                VStack(spacing: 15) {
                    ForEach(options, id: \.0) { (id, text) in
                        Button(action: {
                            question13Choice = id
                        }) {
                            HStack {
                                Text(text)
                                    .foregroundColor(.white)
                                    .padding()
                                Spacer()
                                if question13Choice == id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .padding()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .background(question13Choice == id ? Color.orange : Color.gray.opacity(0.8))
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

                if question13Choice != 0 {
                    Button("Avanti") {
                        onAvanti()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
