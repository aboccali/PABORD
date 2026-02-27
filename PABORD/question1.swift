//
//  question1.swift
//  PABORD
//
//  Created by Neuroinformatica on 10/04/25.
//

import SwiftUI

struct Question1View: View {
    @Binding var slider1Value: Int
    @Binding var slider2Value: Int
    @Binding var slider3Value: Int
    @Binding var slider4Value: Int
    @Binding var slider5Value: Int
    @Binding var slider6Value: Int
    @Binding var slider7Value: Int

    var onAvanti: () -> Void
    var onIndietro: () -> Void

    @State private var currentSlider = 1
    @State private var sliderTempValue: Double = 50
    @State private var initialSliderValue: Double = 50
    @State private var hasMovedSlider = false
    @State private var showAlert = false

    var body: some View {
        VStack {
            Spacer()

            Text("Al momento mi sento:")
                .font(.title)
                .padding()

            VStack {
                Slider(value: $sliderTempValue, in: 0...100, step: 1, onEditingChanged: { editing in
                    if !editing {
                        if Int(sliderTempValue) != Int(initialSliderValue) {
                            hasMovedSlider = true
                        }
                    }
                })
                .padding()
                .accentColor(.orange)

                HStack {
                    Text(labelLeft(for: currentSlider))
                    Spacer()
                    Text(labelRight(for: currentSlider))
                }
                .padding(.horizontal)

                Text("Valore selezionato: \(Int(sliderTempValue))")
                    .padding()
            }

            Spacer()

            HStack {
                Button("Indietro") {
                    if currentSlider > 1 {
                        salvaValore()
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
                    if !hasMovedSlider {
                        // Mostra l'alert se lo slider non è stato spostato
                        showAlert = true
                    } else {
                        salvaValore()
                        if currentSlider < 7 {
                            currentSlider += 1
                            caricaValoreCorrente()
                        } else {
                            onAvanti()
                        }
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

    func salvaValore() {
        let valore = Int(sliderTempValue)
        switch currentSlider {
        case 1: slider1Value = valore
        case 2: slider2Value = valore
        case 3: slider3Value = valore
        case 4: slider4Value = valore
        case 5: slider5Value = valore
        case 6: slider6Value = valore
        case 7: slider7Value = valore
        default: break
        }
        hasMovedSlider = false
    }

    func caricaValoreCorrente() {
        switch currentSlider {
        case 1: sliderTempValue = Double(slider1Value)
        case 2: sliderTempValue = Double(slider2Value)
        case 3: sliderTempValue = Double(slider3Value)
        case 4: sliderTempValue = Double(slider4Value)
        case 5: sliderTempValue = Double(slider5Value)
        case 6: sliderTempValue = Double(slider6Value)
        case 7: sliderTempValue = Double(slider7Value)
        default: break
        }
        initialSliderValue = sliderTempValue
        hasMovedSlider = false
    }

    func labelLeft(for slider: Int) -> String {
        switch slider {
        case 1: return "Stanca"
        case 2: return "Scontenta"
        case 3: return "Agitata"
        case 4: return "Senza energie"
        case 5: return "Male"
        case 6: return "Tesa"
        case 7: return "Sola"
        default: return ""
        }
    }

    func labelRight(for slider: Int) -> String {
        switch slider {
        case 1: return "Sveglia"
        case 2: return "Contenta"
        case 3: return "Calma"
        case 4: return "Piena di energie"
        case 5: return "Bene"
        case 6: return "Rilassata"
        case 7: return "In connessione con gli altri"
        default: return ""
        }
    }
}

