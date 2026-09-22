//
//  BannerAdCell.swift
//  OsmosAdDemoApp
//
//  Created by Kunal Shete on 21/09/26.
//

import UIKit

final class BannerAdCell: UITableViewCell {
    static let reuseIdentifier = "BannerAdCell"

    @IBOutlet weak var containerCardView: UIView!
    @IBOutlet weak var adImageView: UIImageView!
    @IBOutlet weak var fallbackLabel: UILabel!

    var onAdTap: (() -> Void)?
    private var imageTask: URLSessionDataTask?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCard))
        containerCardView.addGestureRecognizer(tap)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        adImageView.image = nil
        fallbackLabel.isHidden = true
    }

    @objc private func didTapCard() {
        onAdTap?()
    }

    func configure(with ad: BannerAd) {
        fallbackLabel.isHidden = true
        adImageView.image = nil
        imageTask?.cancel()

        guard let url = URL(string: ad.imageUrl) else {
            fallbackLabel.isHidden = false
            return
        }

        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if error != nil || data == nil {
                DispatchQueue.main.async { self.fallbackLabel.isHidden = false }
                return
            }
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.adImageView.image = image
                }
            }
        }
        imageTask?.resume()
    }
}
