import Foundation

class GameModel {
    var playerName: String = ""
    var playerSide: String = ""
    var playerScore: Int = 0
    var pcScore: Int = 0
    var roundsPlayed: Int = 0
    let totalRounds: Int = 10

    static let midLongitude: Double = 34.817549168324334

    var playerDeck: [Card] = []
    var pcDeck: [Card] = []

    init() {
        resetGame()
    }

    func resetGame() {
        playerDeck = Card.playerDeck().shuffled()
        pcDeck = Card.pcDeck().shuffled()
        playerScore = 0
        pcScore = 0
        roundsPlayed = 0
    }

    /// Draws one card from each deck. Returns nil if deck is empty.
    func drawOne() -> (player: Card, pc: Card)? {
        guard !playerDeck.isEmpty, !pcDeck.isEmpty else { return nil }
        let p = playerDeck.removeFirst()
        let c = pcDeck.removeFirst()
        return (p, c)
    }

    /// Burns up to 3 cards from each deck (face-down war cards).
    /// Returns how many pairs were actually burned.
    func burnCards(count: Int) -> Int {
        let available = min(count, playerDeck.count, pcDeck.count)
        for _ in 0..<available {
            playerDeck.removeFirst()
            pcDeck.removeFirst()
        }
        return available
    }

    func evaluateRound(playerCard: Card, pcCard: Card) {
        if playerCard.strength > pcCard.strength {
            playerScore += 1
        } else if pcCard.strength > playerCard.strength {
            pcScore += 1
        }
        roundsPlayed += 1
    }

    var isGameOver: Bool { roundsPlayed >= totalRounds }
   
    var isTie: Bool { playerScore == pcScore }

    var winner: String {
        if playerScore > pcScore { return playerName }
        if pcScore > playerScore { return "PC" }
        return "Tie"
    }
}
