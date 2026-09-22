//
//  AdFeedViewController.swift
//  OsmosAdDemoApp
//
//  Created by Kunal Shete on 21/09/26.
//

import UIKit
import SafariServices

final class AdFeedViewController: UIViewController {

    @IBOutlet weak var loadAdButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var feedTableView: UITableView!

  
    private let fallbackLabel: UILabel = {
        let label = UILabel()
        label.text = "Ad not available"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let viewModel = AdFeedViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Display Ads Demo"
        setupTableView()
        bindViewModel()
    }

    private func setupTableView() {
        feedTableView.delegate = self
        feedTableView.dataSource = self
        // Set fallbackLabel as the default background view
        feedTableView.backgroundView = fallbackLabel
        fallbackLabel.isHidden = true
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .idle:
                self.activityIndicator.stopAnimating()
                self.loadAdButton.isEnabled = true
                self.loadAdButton.setTitle("Load Ad", for: .normal)
                self.fallbackLabel.isHidden = true

            case .loading:
                self.activityIndicator.startAnimating()
                self.loadAdButton.isEnabled = false // Prevent duplicate requests (Requirement 8)
                self.loadAdButton.setTitle("", for: .normal)
                self.fallbackLabel.isHidden = true

            case .loaded:
                self.activityIndicator.stopAnimating()
                self.loadAdButton.isEnabled = true
                self.loadAdButton.setTitle("Load Ad", for: .normal)
                self.fallbackLabel.isHidden = true
                self.feedTableView.reloadData()
                self.checkVisibleItemsForImpression()

            case .empty:
                self.activityIndicator.stopAnimating()
                self.loadAdButton.isEnabled = true
                self.loadAdButton.setTitle("Load Ad", for: .normal)
                //Fallback UI
                self.fallbackLabel.text = "Ad not available"
                self.fallbackLabel.isHidden = false
                self.feedTableView.reloadData()

            case .error(let message):
                self.activityIndicator.stopAnimating()
                self.loadAdButton.isEnabled = true
                self.loadAdButton.setTitle("Load Ad", for: .normal)
                // Fallback UI
                self.fallbackLabel.text = "Ad not available\n(\(message))"
                self.fallbackLabel.isHidden = false
                self.feedTableView.reloadData()
            }
        }
    }

    @IBAction func didTapLoadAd(_ sender: UIButton) {
        viewModel.loadAds()
    }

    private func checkVisibleItemsForImpression() {
        for cell in feedTableView.visibleCells {
            guard let indexPath = feedTableView.indexPath(for: cell) else { continue }
            let ratio = VisibilityTracker.visibleRatio(of: cell, in: view.window)
            viewModel.evaluateImpression(at: indexPath.row, visibleRatio: ratio)
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AdFeedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfAds
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: BannerAdCell.reuseIdentifier,
            for: indexPath
        ) as? BannerAdCell,
        let ad = viewModel.ad(at: indexPath.row) else {
            return UITableViewCell()
        }

        cell.configure(with: ad)

        cell.onAdTap = { [weak self] in
            guard let self = self else { return }
            if let targetUrl = self.viewModel.handleClick(at: indexPath.row) {
                let safariVC = SFSafariViewController(url: targetUrl)
                self.present(safariVC, animated: true)
            }
        }

        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        checkVisibleItemsForImpression()
    }
}
