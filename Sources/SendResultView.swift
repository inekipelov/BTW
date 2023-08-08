//
//  SendResultView.swift
//  Test
//
//  Created by Роман Некипелов on 08.08.2023.
//

import SwiftUI
import SFSafeSymbols

struct SendResultView: View {
    let transaction: BitcoinTransaction
    
    @EnvironmentObject private var environment: BitcoinEnvironment
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Txid")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(transaction.txid)
                        .font(.body)
                        .foregroundColor(.primary)
                        .monospaced()
                        .multilineTextAlignment(.trailing)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Confirmed")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(transaction.confirmationDate.formattedString)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.trailing)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Received")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(transaction.received)
                        .font(.body)
                        .foregroundColor(.primary)
                        .monospaced()
                        .multilineTextAlignment(.trailing)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Sent")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(transaction.sent)
                        .font(.body)
                        .foregroundColor(.primary)
                        .monospaced()
                        .multilineTextAlignment(.trailing)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Fees")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(transaction.fee)
                        .font(.body)
                        .foregroundColor(.primary)
                        .monospaced()
                        .multilineTextAlignment(.trailing)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemSymbol: .checkmarkCircleFill)
                                .imageScale(.large)
                            Text("Done")
                                .fontWeight(.semibold)
                        }.frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding()
                }
                .background(.regularMaterial)
            }
        }
        .onDisappear {
            Task {
                try await environment.sync()
            }
        }
    }
}

struct TransactionDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        SendResultView(transaction: BitcoinTransaction()).environmentObject(BitcoinEnvironment())
    }
}
