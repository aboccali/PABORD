//
//  question3.swift
//  PABORD
//
//  Created by Neuroinformatica on 10/04/25.
//

import SwiftUI

struct Question3View: View {
    @Binding var question3Choice: Int
    var onAvanti: () -> Void
    var onIndietro: () -> Void

    var body: some View {
        VStack {
            Spacer()

            Text("Con chi è attualmente?")
                .font(.title)
                .padding()

            HStack(spacing: 40) {
                Button(action: {
                    question3Choice = 1
                }) {
                    Text("Da sola")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(question3Choice == 1 ? Color.orange : Color.gray.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    question3Choice = 2
                }) {
                    Text("Con una o più persone")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(question3Choice == 2 ? Color.orange : Color.gray.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()

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

                if question3Choice != 0 {
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
