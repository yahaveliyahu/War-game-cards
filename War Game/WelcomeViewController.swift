import UIKit
import CoreLocation

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

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = ""
        startButton.isEnabled = false

        setupLocation()
        // checkSavedName()
    }

    // MARK: – Name handling
    private func checkSavedName() {
        if let saved = UserDefaults.standard.string(forKey: "playerName"), !saved.isEmpty {
            playerName = saved
            nameLabel.text = "Hi \(playerName)"
            nameButton.setTitle(playerName, for: .normal)
            evaluateStart()
        }
    }

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
        }
    }
}
