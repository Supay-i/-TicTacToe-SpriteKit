import UIKit
import SpriteKit

/// Точка входа приложения: настраивает SKView и показывает стартовое меню.
final class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else {
            // На случай, если корневой view ещё не SKView (например, при программной
            // инициализации без Storyboard) — берём размер уже существующего view
            // контроллера вместо устаревшего UIScreen.main.
            let newSKView = SKView(frame: view.bounds)
            self.view = newSKView
            configureAndPresent(on: newSKView)
            return
        }
        configureAndPresent(on: skView)
    }

    private func configureAndPresent(on skView: SKView) {
        skView.ignoresSiblingOrder = true
        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        #endif

        let scene = MenuScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
    }

    override var prefersStatusBarHidden: Bool { true }
}
