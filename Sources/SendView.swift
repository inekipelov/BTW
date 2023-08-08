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
    
    @State private var addressValue = "tb1qw2c3lxufxqe2x9s4rdzh65tpf4d7fssjgh8nv6"
    @State private var amountValue = "0.00001"
    @State private var lastErrorString = ""
    @State private var waitingForResult = false
    @State private var transaction: BitcoinTransaction?
        
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
