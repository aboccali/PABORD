//
//  question12.swift
//  PABORD
//
//  Created by Neuroinformatica on 05/05/25.
//

import SwiftUI

struct Question12View: View {
    @Binding var question12Choice: Int
    var onAvanti: () -> Void
    var onIndietro: () -> Void

    let options = [
        (1, "Molto soddisfacente"),
        (2, "Abbastanza soddisfacente"),
        (3, "Soddisfacente"),
        (4, "Insoddisfacente"),
    ]

    var body: some View {
        VStack {
            Spacer()

            Text("Quanto ritiene che il sonno della notte precedente abbia soddisfatto la sua necessità di riposo?")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            ScrollView {
                VStack(spacing: 15) {
                    ForEach(options, id: \.0) { (id, text) in
                        Button(action: {
                            question12Choice = id
                        }) {
                            HStack {
                                Text(text)
                                    .foregroundColor(.white)
                                    .padding()
                                Spacer()
                                if question12Choice == id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .padding()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .background(question12Choice == id ? Color.orange : Color.gray.opacity(0.8))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            HStack {
                Button {
                    onIndietro()
                } label: {
                    Text("Indietro")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .foregroundColor(.orange)

                if question12Choice != 0 {
                    Button {
                        onAvanti()
                    } label: {
                        Text("Avanti")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
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
