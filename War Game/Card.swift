import Foundation

struct Card {
    let imageName: String
    let strength: Int

    // Player deck: diamonds + hearts + red joker
    static func playerDeck() -> [Card] {
        var deck: [Card] = []
        for suit in ["diamond", "heart"] {
            for value in 1...10 {
                deck.append(Card(imageName: "\(suit)_\(value)", strength: value))
            }
            deck.append(Card(imageName: "\(suit)_jack",  strength: 11))
            deck.append(Card(imageName: "\(suit)_queen", strength: 12))
            deck.append(Card(imageName: "\(suit)_king",  strength: 13))
        }
        deck.append(Card(imageName: "joker_red", strength: 14))
        return deck
    }

    // PC deck: clubs + spades + black joker
    static func pcDeck() -> [Card] {
        var deck: [Card] = []
        for suit in ["club", "spade"] {
            for value in 1...10 {
                deck.append(Card(imageName: "\(suit)_\(value)", strength: value))
            }
            deck.append(Card(imageName: "\(suit)_jack",  strength: 11))
            deck.append(Card(imageName: "\(suit)_queen", strength: 12))
            deck.append(Card(imageName: "\(suit)_king",  strength: 13))
        }
        deck.append(Card(imageName: "joker_black", strength: 14))
        return deck
    }
}
