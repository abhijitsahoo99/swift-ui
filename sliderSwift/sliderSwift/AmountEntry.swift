//
//  AmountEntry.swift
//  sliderSwift
//
//  What the keypad is actually editing, and the rules for whether it can be
//  bought. Deliberately free of SwiftUI so it can be reasoned about — and
//  tested — on its own.
//
//  Two things live here that a plain `String` binding could not carry:
//
//  · **Money is `Decimal`, never `Double`.** `Double` is binary floating point:
//    adding 0.1 to itself ten times gives 0.9999999999999999, and it holds
//    whole numbers exactly only up to 2^53 (~9×10¹⁵). Token base units run to
//    18 decimal places, so a single whole token is already past that. Anything
//    that will one day touch a chain should be an integer of the smallest unit;
//    everything on this screen is a display amount, so `Decimal` is enough.
//
//  · **The separator the user types is not the separator we store.** The digits
//    are kept `.`-separated so they parse identically on every device, and
//    `display` swaps in whatever the locale writes. Storing the localized form
//    and parsing it back is exactly what puts "126,89" through a parser that
//    expects a dot and silently yields zero.
//

import Foundation

struct AmountEntry: Equatable {
    /// Nine figures is past anything the 64pt display can show without
    /// shrinking, which is the real limit being enforced here.
    static let maxIntegerDigits = 9
    /// Currency behaviour: cents, and no more.
    static let maxFractionDigits = 2

    /// Canonical: digits and at most one `.`, never grouped, never localized.
    private(set) var digits: String = ""

    init(_ digits: String = "") {
        self.digits = Self.sanitized(digits)
    }

    // MARK: - Reading

    /// Parsed with a fixed locale on purpose — `digits` is our own canonical
    /// form, not something the user's region gets a say in.
    var value: Decimal {
        Decimal(string: digits, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    var isEmpty: Bool { digits.isEmpty }

    /// What the field shows. An empty field reads "0" rather than going blank,
    /// so the amount line never collapses.
    var display: String {
        guard !digits.isEmpty else { return "0" }
        let separator = Locale.current.decimalSeparator ?? "."
        return digits.replacingOccurrences(of: ".", with: separator)
    }

    // MARK: - Editing

    /// Ignores the press rather than truncating: a keypad that silently drops
    /// the digit you typed is less confusing than one that rewrites what is
    /// already on screen.
    mutating func append(digit: Character) {
        guard digit.isNumber else { return }

        if let dot = digits.firstIndex(of: ".") {
            guard digits.distance(from: dot, to: digits.endIndex) <= Self.maxFractionDigits else { return }
        } else {
            guard digits.count < Self.maxIntegerDigits else { return }
        }

        /// A leading zero is a placeholder, not a digit — "0" then "5" is 5,
        /// not 05. It only survives in front of a separator.
        if digits == "0" {
            digits = String(digit)
        } else {
            digits.append(digit)
        }
    }

    mutating func appendSeparator() {
        guard !digits.contains(".") else { return }
        digits += digits.isEmpty ? "0." : "."
    }

    mutating func deleteBackward() {
        guard !digits.isEmpty else { return }
        digits.removeLast()
    }

    /// Used by "Max". Rounds to the fraction length the keypad itself allows,
    /// so the field never shows something it could not have been typed.
    mutating func fill(with amount: Decimal) {
        var rounded = Decimal()
        var source = max(0, amount)
        NSDecimalRound(&rounded, &source, Self.maxFractionDigits, .down)
        digits = Self.sanitized(rounded.description)
    }

    mutating func clear() { digits = "" }

    // MARK: - Validation

    /// Why this amount cannot be bought, or `nil` if it can.
    enum Problem: Equatable {
        /// Nothing typed, or typed down to zero.
        case noAmount
        /// More than the funding token can cover.
        case aboveBalance
    }

    /// `spendable` is what may actually be committed — see `BuyScreen`, where
    /// it is deliberately a smaller number than the wallet balance on display.
    func problem(spending spendable: Decimal) -> Problem? {
        if value <= 0 { return .noAmount }
        if value > spendable { return .aboveBalance }
        return nil
    }

    // MARK: - Normalising

    /// Applied to anything arriving from outside — a seeded value, a "Max"
    /// fill — so the invariants hold no matter where the string came from.
    private static func sanitized(_ input: String) -> String {
        var integer = ""
        var fraction = ""
        var seenSeparator = false

        for character in input {
            if character.isNumber {
                if seenSeparator {
                    if fraction.count < maxFractionDigits { fraction.append(character) }
                } else if integer.count < maxIntegerDigits {
                    integer.append(character)
                }
            } else if character == "." || character == "," {
                guard !seenSeparator else { continue }
                seenSeparator = true
                if integer.isEmpty { integer = "0" }
            }
        }

        if integer.count > 1 { integer.removeFirst(integer.prefix(while: { $0 == "0" }).count) }
        if integer.isEmpty { integer = seenSeparator ? "0" : "" }

        return seenSeparator ? integer + "." + fraction : integer
    }
}

// MARK: - Exact money literals

extension Decimal {
    /// A money constant that is actually the number you wrote.
    ///
    /// `let price: Decimal = 288.39` does **not** give you 288.39. Swift routes
    /// float literals through `Double` first, so what lands in the `Decimal` is
    /// 288.38999999999998635…, and comparing it against the same figure typed
    /// on the keypad — which is parsed from a string, and therefore exact —
    /// fails. Write `.money("288.39")` instead; it is the same reason this
    /// file exists at all.
    static func money(_ literal: String) -> Decimal {
        Decimal(string: literal, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }
}
