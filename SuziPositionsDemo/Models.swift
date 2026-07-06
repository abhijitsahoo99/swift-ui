// Models.swift
// Mock domain models + sample data matching the Positions screenshot.
// No networking — pure static fixtures so the screen renders offline.

import SwiftUI

// MARK: - Formatting helpers

enum Format {
    static func usd(_ v: Double) -> String {
        let sign = v < 0 ? "-" : ""
        return "\(sign)$" + String(format: "%.2f", abs(v))
    }

    static func percent(_ v: Double, signed: Bool = true) -> String {
        let sign = v >= 0 ? "+" : "-"
        return "\(signed ? sign : "")" + String(format: "%.2f", abs(v)) + "%"
    }

    static func cents(_ c: Int) -> String { "\(c)\u{00A2}" } // e.g. 99¢

    static func price(_ v: Double) -> String {
        v >= 1 ? "$" + String(format: "%.2f", v) : "$" + String(format: "%.4f", v)
    }
}

// MARK: - Visual identity for logos / avatars

enum Glyph {
    case symbol(String, Color)   // SF Symbol name + tint
    case initials(String, Color) // letters + tint
    case remote(URL, fallback: Color) // network image, colored fallback
}

// MARK: - Position row

struct PositionItem: Identifiable {
    let id: String
    let kind: Kind

    enum Kind {
        /// Perps / spot / LP layout: icon + symbol (+leverage), subtitle, value + pnl.
        case perp(symbol: String, subtitle: String, leverage: String?,
                  value: Double, pnl: Double, logo: Glyph)
        /// Polymarket layout: avatar + question, outcome • price ... pnl value.
        case prediction(question: String, outcome: String, priceCents: Int,
                        pnl: Double, value: Double, avatar: Glyph)
    }
}

struct ProtocolSection: Identifiable {
    let id: String
    let name: String
    let logo: Glyph
    let total: Double
    let items: [PositionItem]
}

// MARK: - Order row

struct OrderItem: Identifiable {
    let id: String
    let symbol: String
    let side: String        // "buy" / "sell"
    let type: String        // "limit"
    let price: Double
    let amount: String      // "120 DOGE"
    let logo: Glyph
}

struct OrderSection: Identifiable {
    let id: String
    let name: String
    let logo: Glyph
    let total: Double
    let items: [OrderItem]
}

// MARK: - Sample data (mirrors the screenshot)

enum Mock {
    // MARK: Protocol logos
    static let hyperliquidLogo = Glyph.symbol("hourglass", Color(hex: "#7FE0C8"))
    static let polymarketLogo  = Glyph.symbol("chart.bar.fill", Color(hex: "#235AE1"))
    static let aaveLogo        = Glyph.initials("Aa", Color(hex: "#B6509E"))
    static let uniswapLogo     = Glyph.initials("U",  Color(hex: "#FF007A"))
    static let jupiterLogo     = Glyph.initials("J",  Color(hex: "#8FD14F"))
    static let driftLogo       = Glyph.symbol("water.waves", Color(hex: "#9463F7"))
    static let gmxLogo         = Glyph.initials("G",  Color(hex: "#2D42FC"))
    static let aerodromeLogo   = Glyph.symbol("paperplane.fill", Color(hex: "#1E5AFF"))

    // MARK: Token / market glyphs
    static let btc  = Glyph.initials("₿",  Color(hex: "#F7931A"))
    static let eth  = Glyph.initials("Ξ",  Color(hex: "#627EEA"))
    static let sol  = Glyph.initials("S",  Color(hex: "#14F195"))
    static let doge = Glyph.initials("Ð",  Color(hex: "#C2A633"))
    static let xrp  = Glyph.symbol("hourglass", Color(hex: "#7FE0C8"))
    static let arb  = Glyph.initials("A",  Color(hex: "#28A0F0"))
    static let sui  = Glyph.initials("Su", Color(hex: "#4DA2FF"))
    static let pepe = Glyph.initials("Pe", Color(hex: "#4CAF50"))
    static let avax = Glyph.initials("AV", Color(hex: "#E84142"))
    static let link = Glyph.initials("Li", Color(hex: "#2A5ADA"))
    static let op   = Glyph.initials("OP", Color(hex: "#FF0420"))
    static let wif  = Glyph.initials("W",  Color(hex: "#C8A98A"))
    static let usdc = Glyph.initials("$",  Color(hex: "#2775CA"))
    static let dai  = Glyph.initials("D",  Color(hex: "#F5AC37"))
    static let tia  = Glyph.initials("Ti", Color(hex: "#7B2BF9"))
    static let bonk = Glyph.initials("Bo", Color(hex: "#F5A623"))

    // MARK: Row factories (keep the fixtures readable)
    private static func perp(_ id: String, _ symbol: String, _ subtitle: String,
                             lev: String? = nil, value: Double, pnl: Double,
                             _ logo: Glyph) -> PositionItem {
        PositionItem(id: id, kind: .perp(symbol: symbol, subtitle: subtitle, leverage: lev,
                                         value: value, pnl: pnl, logo: logo))
    }

    private static func pred(_ id: String, _ question: String, _ outcome: String,
                             _ cents: Int, pnl: Double, value: Double,
                             _ avatar: Glyph) -> PositionItem {
        PositionItem(id: id, kind: .prediction(question: question, outcome: outcome,
                                               priceCents: cents, pnl: pnl, value: value,
                                               avatar: avatar))
    }

    // MARK: Positions — many protocols, many rows (sticky-scroll testbed)
    static let positionSections: [ProtocolSection] = [
        ProtocolSection(id: "hyperliquid", name: "Hyperliquid", logo: hyperliquidLogo,
                        total: 486.31, items: [
            perp("hl-btc",  "BTC-PERP",   "Perp", lev: "20x", value: 182.40, pnl: 3.11,   btc),
            perp("hl-eth",  "ETH-PERP",   "Perp", lev: "10x", value: 96.72,  pnl: -1.24,  eth),
            perp("hl-sol",  "SOL-PERP",   "Perp", lev: "5x",  value: 54.10,  pnl: 8.63,   sol),
            perp("hl-doge", "DOGE-PERP",  "Perp",             value: 74.58,  pnl: -0.72,  doge),
            perp("hl-xrp",  "XRP-PERP",   "Perp",             value: 20.42,  pnl: 4.45,   xrp),
            perp("hl-arb",  "ARB-PERP",   "Perp", lev: "3x",  value: 18.05,  pnl: -2.30,  arb),
            perp("hl-sui",  "SUI-PERP",   "Perp",             value: 22.90,  pnl: 1.02,   sui),
            perp("hl-pepe", "kPEPE-PERP", "Perp", lev: "10x", value: 17.14,  pnl: 12.88,  pepe),
        ]),
        ProtocolSection(id: "polymarket", name: "Polymarket", logo: polymarketLogo,
                        total: 39.75, items: [
            pred("pm-kim",   "Will Kim Kardashian win the 2028 Democratic presidential nomination?",
                 "NO", 99, pnl: -0.05, value: 4.97, .initials("KK", Color(hex: "#8E44AD"))),
            pred("pm-lebron","Will LeBron James win the 2028 Democratic presidential nomination?",
                 "NO", 99, pnl: -0.05, value: 4.97, .initials("LJ", Color(hex: "#552583"))),
            pred("pm-xi",    "Xi Jinping out before 2027?",
                 "NO", 94, pnl: 1.23, value: 4.75, .initials("XJ", Color(hex: "#B02A2A"))),
            pred("pm-putin", "Putin out as President of Russia before 2026?",
                 "NO", 90, pnl: -30.00, value: 3.27, .initials("VP", Color(hex: "#3A6EA5"))),
            pred("pm-btc",   "Will Bitcoin hit $150k in 2028?",
                 "YES", 42, pnl: 5.40, value: 6.10, .initials("₿", Color(hex: "#F7931A"))),
            pred("pm-fed",   "Fed cuts rates in March?",
                 "YES", 68, pnl: -2.10, value: 4.20, .initials("Fed", Color(hex: "#2E7D32"))),
            pred("pm-gta",   "GTA 6 released in 2026?",
                 "NO", 55, pnl: 0.90, value: 3.80, .initials("G6", Color(hex: "#E67E22"))),
            pred("pm-swift", "Will Taylor Swift announce a 2028 world tour?",
                 "YES", 77, pnl: 11.20, value: 8.44, .initials("TS", Color(hex: "#4A148C"))),
        ]),
        ProtocolSection(id: "aave", name: "Aave", logo: aaveLogo,
                        total: 439.70, items: [
            perp("aave-eth",  "ETH",  "Supplied", value: 120.00, pnl: 2.14,  eth),
            perp("aave-usdc", "USDC", "Supplied", value: 300.00, pnl: 0.31,  usdc),
            perp("aave-wbtc", "WBTC", "Borrowed", value: -85.00, pnl: -1.02, btc),
            perp("aave-dai",  "DAI",  "Supplied", value: 64.20,  pnl: 0.12,  dai),
            perp("aave-link", "LINK", "Supplied", value: 40.50,  pnl: 3.90,  link),
        ]),
        ProtocolSection(id: "uniswap", name: "Uniswap", logo: uniswapLogo,
                        total: 444.34, items: [
            perp("uni-ethusdc", "ETH / USDC",  "LP • 0.30%", value: 210.44, pnl: 6.72,  eth),
            perp("uni-wbtceth", "WBTC / ETH",  "LP • 0.05%", value: 158.10, pnl: -1.18, btc),
            perp("uni-opusdc",  "OP / USDC",   "LP • 1.00%", value: 44.20,  pnl: 2.05,  op),
            perp("uni-arbeth",  "ARB / ETH",   "LP • 0.30%", value: 31.60,  pnl: -0.44, arb),
        ]),
        ProtocolSection(id: "jupiter", name: "Jupiter", logo: jupiterLogo,
                        total: 288.00, items: [
            perp("jup-btc",  "BTC-PERP",  "Perp", lev: "20x", value: 140.00, pnl: 2.90,  btc),
            perp("jup-sol",  "SOL-PERP",  "Perp", lev: "10x", value: 88.90,  pnl: 5.51,  sol),
            perp("jup-wif",  "WIF-PERP",  "Perp", lev: "5x",  value: 27.30,  pnl: -3.20, wif),
            perp("jup-jup",  "JUP-PERP",  "Perp",             value: 19.75,  pnl: 1.44,  jupiterLogo),
            perp("jup-bonk", "BONK-PERP", "Perp", lev: "10x", value: 12.05,  pnl: 22.10, bonk),
        ]),
        ProtocolSection(id: "drift", name: "Drift", logo: driftLogo,
                        total: 144.60, items: [
            perp("drift-sol",  "SOL-PERP",  "Perp", lev: "5x", value: 61.20, pnl: 4.02,  sol),
            perp("drift-eth",  "ETH-PERP",  "Perp", lev: "3x", value: 45.90, pnl: -0.88, eth),
            perp("drift-tia",  "TIA-PERP",  "Perp",            value: 15.40, pnl: 6.71,  tia),
            perp("drift-avax", "AVAX-PERP", "Perp", lev: "2x", value: 22.10, pnl: -2.14, avax),
        ]),
        ProtocolSection(id: "gmx", name: "GMX", logo: gmxLogo,
                        total: 340.10, items: [
            perp("gmx-btc",  "BTC-PERP",  "Perp", lev: "10x", value: 175.00, pnl: 1.75,  btc),
            perp("gmx-eth",  "ETH-PERP",  "Perp", lev: "5x",  value: 92.30,  pnl: -0.63, eth),
            perp("gmx-link", "LINK-PERP", "Perp",             value: 28.80,  pnl: 3.30,  link),
            perp("gmx-arb",  "ARB-PERP",  "Perp", lev: "3x",  value: 19.40,  pnl: -1.90, arb),
            perp("gmx-avax", "AVAX-PERP", "Perp",             value: 24.60,  pnl: 0.75,  avax),
        ]),
        ProtocolSection(id: "aerodrome", name: "Aerodrome", logo: aerodromeLogo,
                        total: 488.90, items: [
            perp("aero-ethusdc", "ETH / USDC",  "LP • 0.05%", value: 130.00, pnl: 2.40,  eth),
            perp("aero-aeroweth","AERO / WETH",  "LP • 1.00%", value: 58.90,  pnl: -4.10, aerodromeLogo),
            perp("aero-usdcdai", "USDC / DAI",  "LP • 0.01%", value: 300.00, pnl: 0.05,  usdc),
        ]),
    ]

    // MARK: Orders — a few protocols so the Orders tab is also long enough
    static let orderSections: [OrderSection] = [
        OrderSection(id: "hyperliquid", name: "Hyperliquid", logo: hyperliquidLogo,
                     total: 132.10, items: [
            OrderItem(id: "o1", symbol: "DOGE-PERP", side: "buy",  type: "limit",
                      price: 0.1180, amount: "600 DOGE", logo: doge),
            OrderItem(id: "o2", symbol: "XRP-PERP",  side: "sell", type: "limit",
                      price: 2.42, amount: "25 XRP", logo: xrp),
            OrderItem(id: "o3", symbol: "BTC-PERP",  side: "buy",  type: "limit",
                      price: 61500, amount: "0.002 BTC", logo: btc),
            OrderItem(id: "o4", symbol: "ETH-PERP",  side: "sell", type: "limit",
                      price: 3450, amount: "0.05 ETH", logo: eth),
            OrderItem(id: "o5", symbol: "SOL-PERP",  side: "buy",  type: "limit",
                      price: 138.20, amount: "1.5 SOL", logo: sol),
        ]),
        OrderSection(id: "jupiter", name: "Jupiter", logo: jupiterLogo,
                     total: 58.40, items: [
            OrderItem(id: "o6", symbol: "WIF-PERP", side: "buy",  type: "limit",
                      price: 1.82, amount: "20 WIF", logo: wif),
            OrderItem(id: "o7", symbol: "SOL-PERP", side: "sell", type: "limit",
                      price: 152.00, amount: "0.8 SOL", logo: sol),
            OrderItem(id: "o8", symbol: "TIA-PERP", side: "buy",  type: "limit",
                      price: 7.40, amount: "5 TIA", logo: tia),
        ]),
        OrderSection(id: "gmx", name: "GMX", logo: gmxLogo,
                     total: 44.90, items: [
            OrderItem(id: "o9",  symbol: "LINK-PERP", side: "buy",  type: "limit",
                      price: 14.20, amount: "3 LINK", logo: link),
            OrderItem(id: "o10", symbol: "ARB-PERP",  side: "sell", type: "limit",
                      price: 0.92, amount: "40 ARB", logo: arb),
        ]),
    ]

    static var positionsTotal: Double { positionSections.reduce(0) { $0 + $1.total } }
    static var ordersTotal: Double { orderSections.reduce(0) { $0 + $1.total } }
}
