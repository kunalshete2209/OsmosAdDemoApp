//
//  AdFeedViewModel.swift
//  OsmosAdDemoApp
//
//  Created by Kunal Shete on 21/09/26.
//

import Foundation

enum FeedViewState {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
}

final class AdFeedViewModel {
    private let adManager: OsmosAdManager
    private(set) var ads: [BannerAd] = []
    
    var onStateChange: ((FeedViewState) -> Void)?
    private(set) var isLoading: Bool = false

    init(adManager: OsmosAdManager = .shared) {
        self.adManager = adManager
    }

    var numberOfAds: Int {
        return ads.count
    }

    func ad(at index: Int) -> BannerAd? {
        guard index >= 0 && index < ads.count else { return nil }
        return ads[index]
    }

    func loadAds() {
        guard !isLoading else { return }

        isLoading = true
        onStateChange?(.loading)

        adManager.fetchBannerAds { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let fetchedAds):
                    self.ads = fetchedAds
                    if fetchedAds.isEmpty {
                        self.onStateChange?(.empty)
                    } else {
                        self.onStateChange?(.loaded)
                    }
                case .failure(let error):
                    self.ads = []
                    self.onStateChange?(.error(error.localizedDescription))
                }
            }
        }
    }

    func evaluateImpression(at index: Int, visibleRatio: Double) {
        guard index >= 0 && index < ads.count else { return }
        
        if visibleRatio >= 0.50 && !ads[index].hasFiredImpression {
            ads[index].hasFiredImpression = true
            adManager.trackImpression(for: ads[index])
        }
    }

    func handleClick(at index: Int) -> URL? {
        guard index >= 0 && index < ads.count else { return nil }
        let selectedAd = ads[index]
        
        adManager.trackClick(for: selectedAd)
        return URL(string: selectedAd.destinationUrl)
    }
}
