import UIKit
import CoreLocation
import AVFoundation

class WelcomeViewController: UIViewController, CLLocationManagerDelegate {

    // MARK: – Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameButton: UIButton!      
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var westSideLabel: UILabel!
    @IBOutlet weak var eastSideLabel: UILabel!
    @IBOutlet weak var leftHalfImageView: UIImageView!
    @IBOutlet weak var rightHalfImageView: UIImageView!

    // MARK: – Properties
    private let locationManager = CLLocationManager()
    private let game = GameModel()
    private var playerName: String = ""
    private var playerSide: String = ""
    
    // MARK: – Audio
    // Background music starts here and is passed to GameViewController
    private var backgroundMusicPlayer: AVAudioPlayer?
    // True only when we hand the player to GameViewController
    private var didHandOffPlayer: Bool = false

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = ""
        startButton.isEnabled = false

        setupLocation()
        startBackgroundMusic()
        // checkSavedName()
    
    
        // Pause music when user goes to home screen
        NotificationCenter.default.addObserver(self,
           selector: #selector(appDidEnterBackground),
           name: UIApplication.didEnterBackgroundNotification,
           object: nil)
       
        // Resume music when user comes back to the app
        NotificationCenter.default.addObserver(self,
           selector: #selector(appDidBecomeActive),
           name: UIApplication.didBecomeActiveNotification,
           object: nil)
        
        // Restart music when returning from result screen via "Back to Menu"
             NotificationCenter.default.addObserver(self,
                 selector: #selector(handleBackToMenu),
                 name: .backToMenu,
                 object: nil)
         }
    
    private func checkSavedName() {
        if let saved = UserDefaults.standard.string(forKey: "playerName"), !saved.isEmpty {
            playerName = saved
            nameLabel.text = "Hi \(playerName)"
            nameButton.setTitle(playerName, for: .normal)
            evaluateStart()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only pause music if we did NOT hand it off to GameViewController
        if !didHandOffPlayer {
            backgroundMusicPlayer?.pause()
        }
        didHandOffPlayer = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

   // MARK: – Background / foreground handling
   @objc private func appDidEnterBackground() {
       backgroundMusicPlayer?.pause()
   }

   @objc private func appDidBecomeActive() {
       // Only resume if the player exists and is paused
       if let player = backgroundMusicPlayer, !player.isPlaying {
           player.play()
       }
   }
    
    // Called when "Back to Menu" is tapped on the result screen
        @objc private func handleBackToMenu() {
            startBackgroundMusic()
        }
    
    // MARK: – Audio
    private func startBackgroundMusic() {
        // Already playing — don't restart
        if backgroundMusicPlayer?.isPlaying == true { return }
        guard let url = Bundle.main.url(forResource: "background_music_game", withExtension: "mp3") else {
            print("⚠️ background_music_game.m4a not found")
            return
    }
      backgroundMusicPlayer = try? AVAudioPlayer(contentsOf: url)
      backgroundMusicPlayer?.numberOfLoops = -1  // loop forever
      backgroundMusicPlayer?.volume = 0.3
      backgroundMusicPlayer?.play()
   }
   
    // MARK: – Name handling
    @IBAction func nameButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Enter your name", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Your name"
            tf.text = self.playerName
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self.playerName = name
         //   UserDefaults.standard.set(name, forKey: "playerName")
            self.nameLabel.text = "Hi \(name)"
            self.nameButton.setTitle(name, for: .normal)
            self.evaluateStart()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: – Location
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        locationManager.stopUpdatingLocation()

        let longitude = loc.coordinate.longitude
        playerSide = longitude >= GameModel.midLongitude ? "East" : "West"
        game.playerSide = playerSide
        highlightSide()
        evaluateStart()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    private func highlightSide() {
        let isEast = playerSide == "East"
        eastSideLabel.font = isEast
            ? UIFont.boldSystemFont(ofSize: eastSideLabel.font.pointSize + 2)
            : UIFont.systemFont(ofSize: eastSideLabel.font.pointSize)
        westSideLabel.font = isEast
            ? UIFont.systemFont(ofSize: westSideLabel.font.pointSize)
            : UIFont.boldSystemFont(ofSize: westSideLabel.font.pointSize + 2)
    }

    private func evaluateStart() {
        startButton.isEnabled = !playerName.isEmpty && !playerSide.isEmpty
    }

    // MARK: – Navigation
    @IBAction func startTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "toGame", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toGame",
           let vc = segue.destination as? GameViewController {
            game.playerName = playerName
            game.playerSide = playerSide
            game.resetGame()
            vc.game = game
            // Hand off the player so music continues into game screen
            vc.backgroundMusicPlayer = backgroundMusicPlayer
            backgroundMusicPlayer = nil
            // Mark that we handed off — so viewWillDisappear doesn't pause it
            didHandOffPlayer = true
        }
    }
}
