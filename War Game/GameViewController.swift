import UIKit
import AVFoundation

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
    
    // Tracks whether the countdown was active when app went to background
    private var wasCountingDown: Bool = false
    
    // MARK: – Audio
    var backgroundMusicPlayer: AVAudioPlayer?  // loops quietly during the game
    private var cardFlipPlayer: AVAudioPlayer?         // plays on every normal card flip
    private var cardFlipWarPlayer: AVAudioPlayer?      // plays when 3 war cards are flipped
    private var gameOverPlayer: AVAudioPlayer?         // plays when result screen appears

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudio()
        
        // Stop music when user presses home button or switches apps
        NotificationCenter.default.addObserver(self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)

        // Resume music when user comes back to the app
        NotificationCenter.default.addObserver(self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        
        updateScoreLabels()
        startRound()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimers()
        // Pause music when leaving game screen (going to result screen)
        // so it can be resumed if the user comes back
        pauseBackgroundMusic()
    }
    
    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       // Resume music if returning to game screen from somewhere
       resumeBackgroundMusic()
    }
    
   deinit {
       NotificationCenter.default.removeObserver(self)
   }
    
   // MARK: – Background / foreground handling
   @objc private func appDidEnterBackground() {
       // Remember if countdown was running so we can resume it
       wasCountingDown = countdownTimer != nil
       stopTimers()
       pauseBackgroundMusic()
   }
   
    @objc private func appDidBecomeActive() {
           resumeBackgroundMusic()
           // Resume the countdown if it was running before going to background
           if wasCountingDown {
               wasCountingDown = false
               startCountdown()
           }
       }

    // MARK: – Audio setup
    ///   card_flip.mp3 — normal card flip
    ///   card_flip_war.m4a — war card flip (3 face-down cards)
    ///   game_over.mp3 — victory / end of game
    private func setupAudio() {
        cardFlipPlayer = makePlayer(filename: "card_flip", ext: "mp3")
        cardFlipPlayer?.volume = 0.8
 
        cardFlipWarPlayer = makePlayer(filename: "card_flip_war", ext: "m4a")
        cardFlipWarPlayer?.volume = 0.9
 
        gameOverPlayer = makePlayer(filename: "game_over", ext: "mp3")
        gameOverPlayer?.volume = 1.0
    }
     
    private func makePlayer(filename: String, ext: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            print("⚠️ Audio file not found: \(filename).\(ext)")
            return nil
        }
        return try? AVAudioPlayer(contentsOf: url)
    }
    
    // Pauses music — remembers position so it can resume from same spot.
    private func pauseBackgroundMusic() {
       backgroundMusicPlayer?.pause()
    }
    
   // Resumes music from where it was paused.
    private func resumeBackgroundMusic() {
       backgroundMusicPlayer?.play()
    }
    
    // Stops music completely (used before game over sound).
    private func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }
     
    // Plays the normal card flip sound (used every round).
    private func playCardFlipSound() {
        cardFlipPlayer?.stop()
        cardFlipPlayer?.currentTime = 0
        cardFlipPlayer?.play()
    }
     
    // Plays the war card flip sound (used when 3 face-down war cards are animated).
    private func playWarCardFlipSound() {
        cardFlipWarPlayer?.stop()
        cardFlipWarPlayer?.currentTime = 0
        cardFlipWarPlayer?.play()
    }
     
    // Stops background music and plays the game-over/victory sound.
    private func playGameOverSound() {
        stopBackgroundMusic()
        gameOverPlayer?.play()
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
        
        // Play war flip sound when the 3 face-down cards start animating
        playWarCardFlipSound()

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
        playCardFlipSound()
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
        playGameOverSound()
        performSegue(withIdentifier: "toResult", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toResult",
           let vc = segue.destination as? ResultViewController {
            vc.game = game
        }
    }
}
