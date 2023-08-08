//
//  WalletView.swift
//  Test
//
//  Created by Роман Некипелов on 04.08.2023.
//

import SwiftUI
import SFSafeSymbols

struct WalletView: View {
    @EnvironmentObject private var environment: BitcoinEnvironment
    @State private var showingSendForm = false
    
    var body: some View {
        NavigationView {
            Form {
                HStack {
                    Image(systemSymbol: .bitcoinsign)
                        .foregroundColor(.yellow)
                    Text(environment.balance.total.readableBitcoin)
                        .monospaced()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .redacted(reason: isRefreshing ? .placeholder : [])
                }
                .font(.largeTitle)
                .fontWeight(.semibold)
                .listRowSeparator(.visible, edges: .bottom)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Address")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Testnet")
                            .foregroundColor(.primary)
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    
                    Text(environment.address)
                        .foregroundColor(.blue)
                        .redacted(reason: isLoading ? .placeholder : [])
                        .monospaced()
                        .onTapGesture {
                            UIPasteboard.general.string = environment.address
                        }
                }
                .multilineTextAlignment(.leading)
                
            }
            .navigationTitle("Wallet")
            .refreshable {
                guard !isRefreshing else { return }
                Task {
                    try await environment.sync()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isRefreshing {
                        ProgressView().progressViewStyle(.circular)
                    } else {
                        Button(action: {
                            Task {
                                try await environment.sync()
                            }
                        }, label: {
                            Image(systemSymbol: .arrowClockwise)
                                .fontWeight(.semibold)
                                .imageScale(.large)
                        })
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    showingSendForm = true
                }, label: {
                    HStack {
                        Image(systemSymbol: .arrowUpCircleFill)
                            .imageScale(.large)
                        Text("Send")
                            .fontWeight(.semibold)
                    }.frame(maxWidth: .infinity)
                })
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
                .background(.regularMaterial)
                .disabled(controlsDisabled)
                .sheet(isPresented: $showingSendForm) {
                    SendView()
                        .presentationDetents([.medium])
                }
            }
        }
        .onAppear {
            environment.load()
        }
    }
    
    private var isLoading: Bool {
        guard case .loading = environment.walletState else {
            return false
        }
        return true
    }
    private var isSyncing: Bool {
        guard case .syncing = environment.syncState else {
            return false
        }
        return true
    }
    private var isRefreshing: Bool {
        return isLoading || isSyncing
    }
    private var controlsDisabled: Bool {
        return environment.balance.total == 0 || isRefreshing
    }
}

struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView().environmentObject(BitcoinEnvironment())
    }
}
