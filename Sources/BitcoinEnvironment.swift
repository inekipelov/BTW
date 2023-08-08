//
//  BitcoinEnvironment.swift
//  Test
//
//  Created by Роман Некипелов on 07.08.2023.
//

import Foundation
import BitcoinDevKit

class BitcoinEnvironment: ObservableObject {
    @Published var wallet: Wallet?
    @Published var balance: Balance = Balance(immature: 0, trustedPending: 0, untrustedPending: 0, confirmed: 0, spendable: 0, total: 0)
    @Published var address: String = ""
    @Published var walletState: WalletState = .empty {
        didSet {
            switch walletState {
            case .loaded(let newWallet):
                wallet = newWallet
                getAddress()
            default:
                break
            }
        }
    }
    @Published var syncState = SyncState.empty {
        didSet {
            switch syncState {
            case .synced:
                getBalance()
            default:
                break
            }
        }
    }
    
    private let mnemonicContainer = SingleMnemonic(.words12)
    private let network: Network = .testnet
    private let syncSource: SyncSource = .electrumTestnet
    private let database: DatabaseType = .memory
    
    func load() {
        walletState = WalletState.loading
        let databaseConfig = database.databaseConfig()
        
        do {
            guard let descriptor = descriptorFromMnemonic(.singleKey_tr86) else { return }
            let wallet = try Wallet(descriptor: descriptor, changeDescriptor: nil, network: network, databaseConfig: databaseConfig)
            walletState = WalletState.loaded(wallet)
            Task {
                try await sync()
            }
        } catch let error {
            walletState = WalletState.failed(error)
        }
    }
    
    func sync() async throws {
        switch walletState {
        case .loaded(let wallet):
            await MainActor.run { syncState = .syncing }
            let task = Task {
                let blockchainConfig = self.syncSource.blockchainConfigWith(network: self.network)
                let blockchain = try Blockchain(config: blockchainConfig)
                try wallet.sync(blockchain: blockchain, progress: nil)
            }
            do {
                try await task.value
                await MainActor.run { syncState = .synced }
            } catch let error {
                await MainActor.run { syncState = .failed(error) }
            }
        default:
            break
        }
    }
    
    func send(amount: UInt64, feeRate: Float = 1.0, address: String) async throws -> BitcoinTransaction {
        let task = Task {
            guard let wallet else { return BitcoinTransaction() }
            let blockchainConfig = syncSource.blockchainConfigWith(network: network)
            let script = try Address(address: address)
                .scriptPubkey()
            let txBuilder = try TxBuilder()
                .addRecipient(script: script, amount: amount)
                .feeRate(satPerVbyte: feeRate)
                .finish(wallet: wallet)
            let _ = try wallet.sign(psbt: txBuilder.psbt, signOptions: nil)
            let transaction = txBuilder.psbt.extractTx()
            let blockchain = try Blockchain(config: blockchainConfig)
            try blockchain.broadcast(transaction: transaction)
            return BitcoinTransaction(txBuilder.transactionDetails)
        }
        
        return try await task.value
    }
    
    func estimateFee(target: UInt64) async throws -> Float {
        let task = Task {
            let blockchainConfig = syncSource.blockchainConfigWith(network: network)
            let blockchain = try Blockchain(config: blockchainConfig)
            return try blockchain.estimateFee(target: target)
        }
        
        return try await task.value.asSatPerVb()
    }
    
    
    private func getAddress() {
        do {
            guard let wallet else { return }
            let addressInfo = try wallet.getAddress(addressIndex: .new)
            address = addressInfo.address.asString()
        } catch _ { }
    }
    
    private func getBalance() {
        do {
            guard let wallet else { return }
            balance = try wallet.getBalance()
        } catch _ { }
    }
    
    private func descriptorFromMnemonic(_ type: DescriptorType, password: String? = nil) -> Descriptor? {
        do {
            let rootKey = DescriptorSecretKey(network: network, mnemonic: mnemonicContainer.mnemonic, password: password)
            switch type {
            case .singleKey_wpkh84:
                let path = try DerivationPath(path: "m/84h/1h/0h/0")
                let descriptorSecretKey = try rootKey.derive(path: path)
                return try Descriptor(descriptor: "wpkh(" + descriptorSecretKey.asString() + ")", network: network)
            case .singleKey_tr86:
                let path = try DerivationPath(path: "m/86'/1'/0'/0")
                let descriptorSecretKey = try rootKey.derive(path: path)
                return try Descriptor(descriptor: "tr(" + descriptorSecretKey.asString() + ")", network: network)
            }
        } catch _ {
            return nil
        }
    }
}

// MARK: - Types

enum DescriptorType {
    case singleKey_wpkh84 // Native Segwit
    case singleKey_tr86 // Taproot
}

struct SyncSource {
    let sourceType: SyncSourceType
    let network: Network
    
    static let electrumTestnet = Self(sourceType: .electrum, network: .testnet)
    
    fileprivate func blockchainConfigWith(network: Network) -> BlockchainConfig {
        switch sourceType {
        case .esplora:
            let url = network == Network.bitcoin ? ESPLORA_URL_BITCOIN : ESPLORA_URL_TESTNET
            let esploraConfig = EsploraConfig(baseUrl: url, proxy: nil, concurrency: nil, stopGap: ESPLORA_STOPGAP, timeout: ESPLORA_TIMEOUT)
            return BlockchainConfig.esplora(config: esploraConfig)
        case .electrum:
            let url = network == Network.bitcoin ? ELECTRUM_URL_BITCOIN : ELECTRUM_URL_TESTNET
            let electrumConfig = ElectrumConfig(url: url, socks5: nil, retry: ELECTRUM_RETRY, timeout: nil, stopGap: ELECTRUM_STOPGAP, validateDomain: true)
            return BlockchainConfig.electrum(config: electrumConfig)
        }
    }
}

enum SyncSourceType {
    case esplora
    case electrum
}

enum DatabaseType {
    case memory
    case disk(path: String)
    
    fileprivate func databaseConfig() -> DatabaseConfig {
        switch self {
        case .memory:
            return  DatabaseConfig.memory
        case .disk(path: let path):
            let sqlLiteDbConfig = SqliteDbConfiguration(path: path)
            return DatabaseConfig.sqlite(config: sqlLiteDbConfig)
        }
    }
}

enum SyncState {
    case empty
    case syncing
    case synced
    case failed(Error)
}

enum WalletState {
    case empty
    case loading
    case loaded(Wallet)
    case failed(Error)
}

struct BitcoinTransaction {
    init(confirmationDate: Date = .now, sent: String = "", received: String = "", fee: String = "", txid: String = "") {
        self.confirmationDate = confirmationDate
        self.sent = sent
        self.received = received
        self.fee = fee
        self.txid = txid
    }
    
    let confirmationDate: Date
    let sent: String
    let received: String
    let fee: String
    let txid: String
    
    init(_ bdkTransaction: TransactionDetails) {
        let timeInterval = TimeInterval(bdkTransaction.confirmationTime?.timestamp ?? 0)
        let dateFormat = DateFormatter()
        dateFormat.locale = .current
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        self.init(confirmationDate:Date(timeIntervalSince1970: timeInterval),
                  sent: bdkTransaction.sent.readableBitcoin,
                  received: bdkTransaction.received.readableBitcoin,
                  fee: bdkTransaction.fee?.readableBitcoin ?? "",
                  txid: bdkTransaction.txid)
    }
}

extension Date {
    var formattedString: String {
        let dateFormat = DateFormatter()
        dateFormat.locale = .current
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormat.string(from: self)
    }
}

struct SingleMnemonic: Codable {
    let mnemonic: Mnemonic
    private let userDefaults = UserDefaults.standard
    private let storageKey = "SingleMnemonic"
    
    init(_ wordCount: WordCount) {
        let container = userDefaults.object(Self.self, with: storageKey)
        mnemonic = container?.mnemonic ?? Mnemonic(wordCount: wordCount)
        userDefaults.set(object: self, forKey: storageKey)
    }
    
    private enum CodingKeys: String, CodingKey {
        case mnemonic
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let mnemonicString = try container.decode(String.self, forKey: .mnemonic)
        mnemonic = try Mnemonic.fromString(mnemonic: mnemonicString)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mnemonic.asString(), forKey: .mnemonic)
    }
}

// MARK: - API URLs
let ESPLORA_URL_BITCOIN = "https://blockstream.info/api/"
let ESPLORA_URL_TESTNET = "https://blockstream.info/testnet/api"

let ELECTRUM_URL_BITCOIN = "ssl://electrum.blockstream.info:60001"
let ELECTRUM_URL_TESTNET = "ssl://electrum.blockstream.info:60002"

// MARK: - Defaults
let ESPLORA_TIMEOUT = UInt64(1000)
let ESPLORA_STOPGAP = UInt64(20)

let ELECTRUM_RETRY = UInt8(5)
let ELECTRUM_STOPGAP = UInt64(10)
