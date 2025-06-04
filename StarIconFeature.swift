import UIKit

class PerfectRepNotifier {
    private let iconView: UIImageView
    private let parentView: UIView

    init(in view: UIView) {
        self.parentView = view
        self.iconView = UIImageView(image: UIImage(systemName: "star.fill"))
        self.iconView.tintColor = .systemYellow
        self.iconView.alpha = 0
        self.iconView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)
        ])
    }

    func showIfPerfect(confidence: Float) {
        if confidence >= 0.95 {
            showStar()
        }
    }

    private func showStar() {
        UIView.animate(withDuration: 0.2, animations: {
            self.iconView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0.5, options: [], animations: {
                self.iconView.alpha = 0
            }, completion: nil)
        }
    }
}
