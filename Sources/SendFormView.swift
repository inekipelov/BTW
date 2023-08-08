//
//  SendFormView.swift
//  Test
//
//  Created by Роман Некипелов on 07.08.2023.
//

import SwiftUI
import SFSafeSymbols

struct SendFormView: View {
    @EnvironmentObject private var environment: BitcoinEnvironment
    @Environment(\.dismiss) private var dismiss
    
    @State private var addressValue = "tb1qw2c3lxufxqe2x9s4rdzh65tpf4d7fssjgh8nv6"
    @State private var amountValue = "0.00001"
    @State private var lastErrorString = ""
    @State private var waitingForResult = false
    @Binding var result: BitcoinTransaction?
    
    private var isValidAddress: Bool {
        let patter = try? NSRegularExpression(pattern: "(tb(0([ac-hj-np-z02-9]{39}|[ac-hj-np-z02-9]{59})|1[ac-hj-np-z02-9]{8,87})|[mn2][a-km-zA-HJ-NP-Z1-9]{25,39})")
        return patter?.matches(addressValue) ?? false
    }
    private var isValidAmount: Bool {
        let satoshi = amountValue.satoshi
        return environment.balance.total > satoshi && satoshi > 0
    }
    private var isValidForm: Bool {
        return !addressValue.isEmpty && !amountValue.isEmpty && isValidAddress && isValidAmount
    }

    var body: some View {
        NavigationView {
            Form  {
                Section {
                    HStack {
                        Image(systemSymbol: .bitcoinsign)
                            .foregroundColor(.yellow)
                        TextField("amount", text: $amountValue)
                            .foregroundColor(isValidAmount ? .primary : .red)
                            .font(.largeTitle)
                            .monospaced()
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    .font(.largeTitle)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Address")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Testnet")
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        
                        TextField("type address here", text: $addressValue)
                            .foregroundColor(isValidAddress ? .blue : .red)
                    }
                } footer: {
                    Text(lastErrorString)
                        .foregroundColor(.red)
                    
                }
            }
            .navigationTitle("Send to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    PasteButton(payloadType: String.self) {
                        guard let first = $0.first else { return }
                        addressValue = first
                    }
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.capsule)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        Task {
                            waitingForResult = true
                            do {
                                result = try await environment.send(amount: amountValue.satoshi, address: addressValue)
                            } catch let error {
                                lastErrorString = error.localizedDescription
                            }
                            waitingForResult = false
                        }
                    } label: {
                        HStack {
                            Image(systemSymbol: .arrowUpCircleFill)
                                .imageScale(.large)
                            Text("Send")
                                .fontWeight(.semibold)
                        }.frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding()
                    .disabled(!isValidForm || waitingForResult)
                }
                .background(.regularMaterial)
            }
            
        }
    }
}

struct SendFormView_Previews: PreviewProvider {
    static var previews: some View {
        SendFormView(result: .constant(BitcoinTransaction())).environmentObject(BitcoinEnvironment())
    }
}
