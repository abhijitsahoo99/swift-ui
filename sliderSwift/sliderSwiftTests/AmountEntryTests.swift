//
//  AmountEntryTests.swift
//  sliderSwiftTests
//
//  The rules that decide what may be typed and what may be bought. They live in
//  `AmountEntry` rather than in the keypad view precisely so they can be checked
//  here, without a simulator.
//

import Testing
import Foundation
@testable import sliderSwift

@MainActor
struct AmountEntryTests {

    /// Types a run of keys the way the numpad would. `.` is the separator key,
    /// `<` is backspace.
    private func typing(_ keys: String, into entry: inout AmountEntry) {
        for key in keys {
            switch key {
            case ".": entry.appendSeparator()
            case "<": entry.deleteBackward()
            default: entry.append(digit: key)
            }
        }
    }

    private func typed(_ keys: String) -> AmountEntry {
        var entry = AmountEntry()
        typing(keys, into: &entry)
        return entry
    }

    // MARK: - Typing

    @Test func acceptsAPlainAmount() {
        #expect(typed("126.89").digits == "126.89")
    }

    @Test func refusesAThirdDecimalPlace() {
        #expect(typed("126.897").digits == "126.89")
    }

    @Test func separatorOnAnEmptyFieldGetsALeadingZero() {
        #expect(typed(".").digits == "0.")
        #expect(typed(".5").digits == "0.5")
    }

    @Test func refusesASecondSeparator() {
        #expect(typed("1.5.2").digits == "1.52")
    }

    /// A leading zero is a placeholder, not a digit.
    @Test func replacesALeadingZero() {
        #expect(typed("05").digits == "5")
        #expect(typed("000").digits == "0")
    }

    @Test func capsTheIntegerDigits() {
        #expect(typed("1234567890123").digits == "123456789")
        #expect(typed("1234567890123").digits.count == AmountEntry.maxIntegerDigits)
    }

    @Test func backspaceOnAnEmptyFieldIsSafe() {
        #expect(typed("<<<").digits == "")
    }

    @Test func anEmptyFieldStillReadsAsZero() {
        #expect(AmountEntry().display == "0")
    }

    // MARK: - Values arriving from outside

    @Test func normalisesWhateverItIsSeededWith() {
        #expect(AmountEntry("00126.8999").digits == "126.89")
        #expect(AmountEntry("126,89").digits == "126.89")
        #expect(AmountEntry("£1 2 3").digits == "123")
    }

    /// "Max" must never produce a figure the keypad itself could not have typed.
    @Test func maxRoundsDownToCents() {
        var entry = AmountEntry()
        entry.fill(with: .money("288.396"))
        #expect(entry.digits == "288.39")
    }

    @Test func maxRefusesToGoNegative() {
        var entry = AmountEntry()
        entry.fill(with: .money("-50"))
        #expect(entry.value == 0)
    }

    // MARK: - Validation

    @Test func aTypedAmountWithinBudgetPasses() {
        #expect(AmountEntry("126.89").problem(spending: .money("288.39")) == nil)
    }

    @Test func nothingTypedIsRefused() {
        #expect(AmountEntry().problem(spending: .money("288.39")) == .noAmount)
        #expect(AmountEntry("0.00").problem(spending: .money("288.39")) == .noAmount)
    }

    @Test func moreThanIsSpendableIsRefused() {
        #expect(AmountEntry("999999").problem(spending: .money("288.39")) == .aboveBalance)
        #expect(AmountEntry("288.40").problem(spending: .money("288.39")) == .aboveBalance)
    }

    /// The boundary matters more than the middle: "Max" fills exactly this
    /// number, so if the comparison is off by a hair, Max then slide is refused.
    @Test func exactlyTheSpendableAmountPasses() {
        #expect(AmountEntry("288.39").problem(spending: .money("288.39")) == nil)
    }

    /// The reason the above works. `let x: Decimal = 288.39` routes through
    /// `Double` and lands slightly *below* 288.39, so the same figure typed on
    /// the keypad — parsed from a string, and exact — compares as greater.
    @Test func floatLiteralsAreNotExactAndMoneyIs() {
        #expect(Decimal(288.39) != .money("288.39"))
        #expect(AmountEntry("288.39").value == .money("288.39"))
    }
}
