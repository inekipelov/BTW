//
//  SendView.swift
//  Test
//
//  Created by Роман Некипелов on 08.08.2023.
//

import SwiftUI
import SFSafeSymbols

struct SendView: View {
    @EnvironmentObject private var environment: BitcoinEnvironment
    @Environment(\.dismiss) private var dismiss
    
    @State private var transaction: BitcoinTransaction?

    var body: some View {
        if let transaction {
            SendResultView(transaction: transaction)
        } else {
            SendFormView(result: $transaction)
        }
    }
}

struct SendForm_Previews: PreviewProvider {
    static var previews: some View {
        SendView().environmentObject(BitcoinEnvironment())
    }
}
