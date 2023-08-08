//
//  TestApp.swift
//  test
//
//  Created by Роман Некипелов on 04.08.2023.
//

import SwiftUI

@main
struct TestApp: App {
    
    @ObservedObject var environment = BitcoinEnvironment()
    
    var body: some Scene {
        WindowGroup {
            WalletView().environmentObject(environment)
        }
    }
}
