import UIKit

class ResultViewController: UIViewController {

    // MARK: – Outlets
    @IBOutlet weak var winnerLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!

    // MARK: – Properties
    var game: GameModel!

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Prevent going back to Game screen
        navigationItem.hidesBackButton = true

        if game.isTie {
            winnerLabel.text = "Tie!"
            scoreLabel.text = "Score: \(game.playerScore)"            } else {
                winnerLabel.text = "Winner: \(game.winner)"
                scoreLabel.text = "Score: \(max(game.playerScore, game.pcScore))"
            }
        }

    // MARK: – Actions
    @IBAction func backToMenuTapped(_ sender: UIButton) {
        view.window?.rootViewController?.dismiss(animated: true)
    }
}
