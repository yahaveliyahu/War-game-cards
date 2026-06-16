import UIKit

class GameViewController: UIViewController {

    // MARK: – Outlets
    @IBOutlet weak var playerNameLabel: UILabel!
    @IBOutlet weak var playerScoreLabel: UILabel!
    @IBOutlet weak var pcScoreLabel: UILabel!
    @IBOutlet weak var playerCardImageView: UIImageView!
    @IBOutlet weak var pcCardImageView: UIImageView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var timerIconImageView: UIImageView!

    // MARK: – Properties
    var game: GameModel!
    private var countdownTimer: Timer?
    private var secondsLeft: Int = 5
    private var warCardViews: [UIImageView] = []

    // How long cards are shown before the toast appears
    private let cardDisplayTime: TimeInterval = 1.0

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        updateScoreLabels()
        startRound()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimers()
    }

    // MARK: – Round logic
    private func startRound() {
        guard !game.isGameOver else {
            navigateToResult()
            return
        }

        secondsLeft = 5
        timerLabel.text = "\(secondsLeft)"

        guard let (playerCard, pcCard) = game.drawOne() else {
            navigateToResult()
            return
        }

        // 1. Show the cards first
        showCards(playerCard: playerCard, pcCard: pcCard)

        // 2. After cardDisplayTime, show toast + update score
        if playerCard.strength == pcCard.strength {
            DispatchQueue.main.asyncAfter(deadline: .now() + cardDisplayTime) { [weak self] in
                guard let self = self else { return }
                self.handleWar(playerCard: playerCard, pcCard: pcCard)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + cardDisplayTime) { [weak self] in
                guard let self = self else { return }
                self.game.evaluateRound(playerCard: playerCard, pcCard: pcCard)
                self.updateScoreLabels()
                let playerWon = playerCard.strength > pcCard.strength
                self.showToast(message: playerWon
                    ? "\(self.game.playerName) won the round!"
                    : "PC won the round!")
                self.startCountdown()
            }
        }
    }

    // MARK: – War logic
    private func handleWar(playerCard: Card, pcCard: Card) {
        // Show WAR toast immediately (cards already visible)
        showToast(message: "⚔️ WAR! ⚔️")

        // After toast fades, animate 3 stacked face-down cards
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            guard let self = self else { return }

            let burned = self.game.burnCards(count: 3)

            guard burned == 3, let (warPlayer, warPC) = self.game.drawOne() else {
                self.game.evaluateRound(playerCard: playerCard, pcCard: pcCard)
                self.updateScoreLabels()
                self.showToast(message: "Not enough cards for war! Round skipped.")
                self.startCountdown()
                return
            }

            // Animate 3 face-down cards stacking up on each side
            self.animateWarCards {
                // Remove stacked cards, then reveal the 4th
                self.removeWarCards {
                    // Show the 4th cards
                    self.showCards(playerCard: warPlayer, pcCard: warPC)

                    // Wait cardDisplayTime, then show result
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.cardDisplayTime) {
                        if warPlayer.strength == warPC.strength {
                            // Another tie — recurse
                            self.handleWar(playerCard: warPlayer, pcCard: warPC)
                        } else {
                            self.game.evaluateRound(playerCard: warPlayer, pcCard: warPC)
                            self.updateScoreLabels()
                            let playerWon = warPlayer.strength > warPC.strength
                            self.showToast(message: playerWon
                                ? "\(self.game.playerName) won the war!"
                                : "PC won the war!")
                            self.startCountdown()
                        }
                    }
                }
            }
        }
    }

    // MARK: – War card stack animation
    private func animateWarCards(completion: @escaping () -> Void) {
        warCardViews.forEach { $0.removeFromSuperview() }
        warCardViews = []

        let backImage = UIImage(named: "card_back")
        let cardWidth: CGFloat = playerCardImageView.frame.width * 0.85
        let cardHeight: CGFloat = playerCardImageView.frame.height * 0.85
        let playerCenter = playerCardImageView.center
        let pcCenter = pcCardImageView.center

        for i in 0..<3 {
            let offset = CGFloat(i) * 6

            let playerWarCard = UIImageView(image: backImage)
            playerWarCard.contentMode = .scaleAspectFit
            playerWarCard.frame = CGRect(
                x: playerCenter.x - cardWidth / 2 + offset,
                y: playerCenter.y - cardHeight / 2 + offset,
                width: cardWidth,
                height: cardHeight
            )
            playerWarCard.alpha = 0
            view.addSubview(playerWarCard)
            warCardViews.append(playerWarCard)

            let pcWarCard = UIImageView(image: backImage)
            pcWarCard.contentMode = .scaleAspectFit
            pcWarCard.frame = CGRect(
                x: pcCenter.x - cardWidth / 2 + offset,
                y: pcCenter.y - cardHeight / 2 + offset,
                width: cardWidth,
                height: cardHeight
            )
            pcWarCard.alpha = 0
            view.addSubview(pcWarCard)
            warCardViews.append(pcWarCard)
        }

        // Animate each pair in one by one, 0.4s apart
        for i in 0..<3 {
            let delay = Double(i) * 0.4
            let pCard = warCardViews[i * 2]
            let cCard = warCardViews[i * 2 + 1]
            UIView.animate(withDuration: 0.3, delay: delay, options: [], animations: {
                pCard.alpha = 1
                cCard.alpha = 1
            })
        }

        // All 3 cards shown after ~1.2s, hold for 0.8s then call completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completion()
        }
    }

    private func removeWarCards(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3, animations: {
            self.warCardViews.forEach { $0.alpha = 0 }
        }, completion: { _ in
            self.warCardViews.forEach { $0.removeFromSuperview() }
            self.warCardViews = []
            completion()
        })
    }

    // MARK: – Show cards
    private func showCards(playerCard: Card, pcCard: Card) {
        flipCard(imageView: playerCardImageView, toImage: UIImage(named: playerCard.imageName))
        flipCard(imageView: pcCardImageView,     toImage: UIImage(named: pcCard.imageName))
    }

    // MARK: – Toast
    private func showToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textAlignment = .center
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.font = UIFont.boldSystemFont(ofSize: 22)
        toast.numberOfLines = 0
        toast.layer.cornerRadius = 16
        toast.clipsToBounds = true
        toast.alpha = 0

        toast.frame = CGRect(x: 0, y: 0, width: view.frame.width - 60, height: 80)
        toast.center = view.center
        view.addSubview(toast)

        UIView.animate(withDuration: 0.4, animations: {
            toast.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 1.2, animations: {
                toast.alpha = 0
            }, completion: { _ in
                toast.removeFromSuperview()
            })
        })
    }

    // MARK: – Timers
    private func startCountdown() {
        stopTimers()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsLeft -= 1
            self.timerLabel.text = "\(self.secondsLeft)"
            if self.secondsLeft <= 0 {
                self.stopTimers()
                if self.game.isGameOver {
                    self.navigateToResult()
                } else {
                    self.startRound()
                }
            }
        }
    }

    private func stopTimers() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // MARK: – Card flip animation
    private func flipCard(imageView: UIImageView, toImage: UIImage?) {
        UIView.transition(with: imageView,
                          duration: 0.3,
                          options: .transitionFlipFromRight,
                          animations: { imageView.image = UIImage(named: "card_back") },
                          completion: { _ in
            UIView.transition(with: imageView,
                              duration: 0.3,
                              options: .transitionFlipFromRight,
                              animations: { imageView.image = toImage },
                              completion: nil)
        })
    }

    // MARK: – UI updates
    private func updateScoreLabels() {
        playerNameLabel.text = game.playerName
        playerScoreLabel.text = "\(game.playerScore)"
        pcScoreLabel.text = "\(game.pcScore)"
    }

    // MARK: – Navigation
    private func navigateToResult() {
        performSegue(withIdentifier: "toResult", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toResult",
           let vc = segue.destination as? ResultViewController {
            vc.game = game
        }
    }
}
