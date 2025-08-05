//
//  SNSImageFullscreenViewController.swift
//  SNSNotificationSDK
//
//  Created by Awaken Mobile on 22/7/2025.
//

//image and video both working
import UIKit

public final class SNSImageFullscreenViewController: UIViewController {

    // MARK: - Properties

    private let imageURL: URL
    private let imageView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Initializer

    public init(imageURL: URL) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupImageView()
        setupLoadingIndicator()
        loadImage()
    }

    // MARK: - Setup UI

    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.clipsToBounds = true
        view.addSubview(imageView)
    }

    private func setupLoadingIndicator() {
        loadingIndicator.center = view.center
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
    }

    // MARK: - Load Image

    private func loadImage() {
        print("🖼️ SNS: Loading image from \(imageURL.absoluteString)")
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
            }
            if let error = error {
                print("❌ SNS: Failed to load image: \(error.localizedDescription)")
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                print("❌ SNS: Image decoding failed")
                return
            }
            DispatchQueue.main.async {
                self.imageView.image = image
                print("✅ SNS: Image loaded successfully")
            }
        }.resume()
    }

    // MARK: - Dismiss on Touch

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss(animated: true)
    }
}
