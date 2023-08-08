//
//  Extensions.swift
//  Test
//
//  Created by Роман Некипелов on 07.08.2023.
//

import Foundation

extension BinaryInteger {
    var readableBitcoin: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 5
        numberFormatter.maximumFractionDigits = 8
        return numberFormatter.string(from: NSNumber(value: Double(self) / pow(Double(10), Double(8)))) ?? ""
    }
    var bitcoin: Double {
        return Double(self) / pow(Double(10), Double(8))
    }
}

extension Double {
    var satoshi: UInt64 {
        return UInt64(self * pow(Double(10), Double(8)))
    }
    var readableSatoshi: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter.string(from: NSNumber(value: self * pow(Double(10), Double(8)))) ?? ""
    }
}

extension String {
    var satoshi: UInt64 {
        guard let double = Double(self) else { return 0 }
        return double.satoshi
    }
    var bitcoin: Double {
        guard let double = UInt64(self) else { return 0 }
        return double.bitcoin
    }
}

extension UserDefaults {
    func object<T: Codable>(_ type: T.Type, with key: String, usingDecoder decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard let data = value(forKey: key) as? Data else { return nil }
        return try? decoder.decode(type.self, from: data)
    }
    func set<T: Codable>(object: T, forKey key: String, usingEncoder encoder: JSONEncoder = JSONEncoder()) {
        let data = try? encoder.encode(object)
        set(data, forKey: key)
    }
}

extension NSRegularExpression {
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}
