//
//  question16.swift
//  PABORD
//
//  Created by Neuroinformatica on 06/05/25.
//

import SwiftUI

struct Question16View: View {
    @Binding var slider16Value: Int

    var onAvanti: () -> Void
    var onIndietro: () -> Void

    @State private var sliderValue: Double = 50
    @State private var hasMovedSlider = false
    @State private var initialSliderValue: Double = 50
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ScrollView {
                Text("Siamo consapevoli che rispondere alle domande dell'APP talvolta può essere impegnativo nella vita di tutti i giorni. Dunque, vorremmo porle una domanda confidenziale: quanto impegno mette nel rispondere alle domande?")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                Slider(value: $sliderValue, in: 0...100, step: 1, onEditingChanged: { editing in
                    if !editing {
                        if Int(sliderValue) != Int(initialSliderValue) {
                            hasMovedSlider = true
                        }
                    }
                })
                .padding(.horizontal)
                .accentColor(.orange)

                HStack {
                    Text("Molto poco sforzo")
                    Spacer()
                    Text("Molto sforzo")
                }
                .padding(.horizontal)

                Text("Valore selezionato: \(Int(sliderValue))")
                    .font(.headline)
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

                Button {
                    if !hasMovedSlider {
                        showAlert = true
                    } else {
                        slider16Value = Int(sliderValue)
                        onAvanti()
                    }
                } label: {
                    Text("Avanti")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(hasMovedSlider ? Color.orange : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(10)
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Attenzione"),
                        message: Text("Per favore, muovi lo slider prima di procedere."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        .padding()
        .onAppear {
            sliderValue = Double(slider16Value)
            initialSliderValue = sliderValue
            hasMovedSlider = false
        }
    }
}
