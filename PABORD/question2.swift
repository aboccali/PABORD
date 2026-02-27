//
//  question2.swift
//  PABORD
//
//  Created by Neuroinformatica on 29/04/25.
//

import SwiftUI

struct Question2View: View {
    @Binding var question2Choice: Int
    var onAvanti: () -> Void
    var onIndietro: () -> Void

    // Elenco delle opzioni (puoi aggiungerne facilmente altre)
    let options = [
        (1, "Sono a letto malata"),
        (2, "Sto mangiando/bevendo/facendo colazione/facendo uno spuntino"),
        (3, "Mi sto prendendo cura di me (lavarmi, vestirmi, ecc)"),
        (4, "Sto lavorando o facendo una stage (o sto cercando lavoro)"),
        (5, "Sto studiando/frequentando corsi di formazione"),
        (6, "Sto pulendo, cucinando, mettendo in ordine la casa o l'auto, facendo la spesa"),
        (7, "Sto facendo attività ricreative (es: vita sociale, giocare, chiacchierare, leggere, andare al cinema, suonare uno strumento, ecc)"),
        (8, "Sto facendo sport, attività fisica"),
        (9, "Mi sto spostando (a piedi, in bicicletta, in auto, con mezzi pubblici"),
        (10, "Sto guardando la TV/ ascoltando la radio"),
        (11, "Sto partecipando ad attività religiose (es: andare a messa, pregare, ecc")
        ]

    var body: some View {
        VStack {
            Spacer()

            Text("Cosa sta facendo esattamente in questo momento? (Selezioni una sola opzione)")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            ScrollView {
                VStack(spacing: 15) {
                    ForEach(options, id: \.0) { (id, text) in
                        Button(action: {
                            question2Choice = id
                        }) {
                            HStack {
                                Text(text)
                                    .foregroundColor(.white)
                                    .padding()
                                Spacer()
                                if question2Choice == id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .padding()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .background(question2Choice == id ? Color.orange : Color.gray.opacity(0.8))
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

                if question2Choice != 0 {
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
