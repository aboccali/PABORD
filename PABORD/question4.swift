//
//  question4.swift
//  PABORD
//
//  Created by Neuroinformatica on 29/04/25.
//

import SwiftUI

struct Question4View: View {
    @Binding var slider1Value: Int
    @Binding var slider2Value: Int
    @Binding var slider3Value: Int
    @Binding var slider4Value: Int
    @Binding var slider5Value: Int

    var onAvanti: () -> Void
    var onIndietro: () -> Void

    @State private var currentSlider = 1
    @State private var sliderTempValue: Double = 50
    @State private var hasMovedSlider = false
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Da quando mi sono alzata:")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.top)

            Text(domandaCorrente())
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Slider(value: $sliderTempValue, in: 0...100, step: 1, onEditingChanged: { _ in
                hasMovedSlider = true
                showAlert = false // Reset the alert when the user starts editing the slider
            })
            .padding(.horizontal)
            .accentColor(.orange)
            
            Text("Valore selezionato: \(Int(sliderTempValue))")
                .padding()

            Spacer()

            HStack {
                Button("Indietro") {
                    if currentSlider > 1 {
                        currentSlider -= 1
                        caricaValoreCorrente()
                    } else {
                        onIndietro()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.orange)
                
                Button("Avanti") {
                    if hasMovedSlider {
                        salvaValore()
                        if currentSlider < 5 {
                            currentSlider += 1
                            caricaValoreCorrente()
                            hasMovedSlider = false
                        } else {
                            onAvanti()
                        }
                    } else {
                        showAlert = true
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
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
        .onAppear {
            caricaValoreCorrente()
        }
        .padding()
    }

    func domandaCorrente() -> String {
        switch currentSlider {
        case 1: return "Ho agito impulsivamente a causa di emozioni negative (es: rabbia, tristezza, frustrazione)"
        case 2: return "Ho agito impulsivamente a causa di un'emozione positiva intensa (es: entusiasmo, euforia)"
        case 3: return "Ho preso una decisione senza riflettere sulle possibili conseguenze"
        case 4: return "Ho avuto difficoltà a portare a termine ciò che stavo facendo, anche se era importante per me"
        case 5: return "Ho sentito il desiderio di fare qualcosa di eccitante o rischioso"
        default: return ""
        }
    }

    func salvaValore() {
        let value = Int(sliderTempValue)
        switch currentSlider {
        case 1: slider1Value = value
        case 2: slider2Value = value
        case 3: slider3Value = value
        case 4: slider4Value = value
        case 5: slider5Value = value
        default: break
        }
    }

    func caricaValoreCorrente() {
        switch currentSlider {
        case 1: sliderTempValue = Double(slider1Value)
        case 2: sliderTempValue = Double(slider2Value)
        case 3: sliderTempValue = Double(slider3Value)
        case 4: sliderTempValue = Double(slider4Value)
        case 5: sliderTempValue = Double(slider5Value)
        default: break
        }
    }
}

