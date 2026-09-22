//
//  OsmosAdManager.swift
//  OsmosAdDemoApp
//
//  Created by Kunal Shete on 21/09/26.
//

import Foundation
import UIKit
import osmos

final class OsmosAdManager {
    static let shared = OsmosAdManager()
    private init() {}

    private let clientId = "10088010"
    private let displayAdsHost = "demo-ba.o-s.io"

    // MARK: - Ad Fetching
    func fetchBannerAds(
        retriesLeft: Int = 2,
        completion: @escaping (Result<[BannerAd], Error>) -> Void
    ) {
        Task {
            do {
                let osmos = try OSMOS.shared()
                guard let adFetcher = osmos.adFetcher() else {
                    throw OsmosError.notInitialized
                }

                print("Fetching display ads via SDK - (AU: banner_ads)...")

                let response = await adFetcher.fetchDisplayAdsWithAu(
                    cliUbid: "Any",
                    pageType: "demo_page",
                    productCount: 1,
                    adUnits: ["banner_ads"],
                    targetingParams: nil,
                    onError: { error in
                        print("[Ad Service] SDK Fetch warning: \(error.localizedDescription)")
                    }
                )

                // Extract HTTP Status Code
                var statusCode = 200
                if let responseDict = response,
                   let responseObj = responseDict["response"] as? [String: Any],
                   let code = responseObj["code"] as? Int {
                    statusCode = code
                }

                // 1. Try parsing from SDK response
                if let response = response, let ads = self.parseAds(from: response), !ads.isEmpty {
                    // Log Ad Loaded
                    print("[Ad Event] Ad Loaded (HTTP Status: \(statusCode)). Rendered Feed Count: \(ads.count)")
                    completion(.success(ads))
                    return
                }

                // 2. Direct API Fallback if SDK returns empty
                print(" SDK response empty. Falling back to direct API...")
                self.fetchViaDirectAPI { apiResult in
                    switch apiResult {
                    case .success(let ads):
                        print("Ad Loaded (Direct API). Count: \(ads.count)")
                        completion(.success(ads))
                    case .failure(let error):
                        self.handleRetryOrFailure(retriesLeft: retriesLeft, error: error, completion: completion)
                    }
                }

            } catch {
                self.handleRetryOrFailure(retriesLeft: retriesLeft, error: error, completion: completion)
            }
        }
    }

    // MARK: - Direct API Fallback
    private func fetchViaDirectAPI(completion: @escaping (Result<[BannerAd], Error>) -> Void) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = displayAdsHost
        components.path = "/v2/bsda"
        components.queryItems = [
            URLQueryItem(name: "cli_ubid", value: "Any"),
            URLQueryItem(name: "pt", value: "demo_page"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "au[]", value: "banner_ads"),
            URLQueryItem(name: "pcnt_au", value: "1")
        ]

        guard let url = components.url else {
            completion(.failure(NSError(domain: "OsmosAds", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid request URL"])))
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            let httpCode = (response as? HTTPURLResponse)?.statusCode ?? 200
            print("[DEBUG] Direct API Response Status: \(httpCode)")

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(NSError(domain: "OsmosAds", code: -1, userInfo: [NSLocalizedDescriptionKey: "Malformed response"])))
                return
            }

            if let ads = self.parseAds(from: json), !ads.isEmpty {
                completion(.success(ads))
            } else {
                let error = NSError(domain: "OsmosAds", code: 404, userInfo: [NSLocalizedDescriptionKey: "No banner ads returned"])
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Response Parsing (ads.banner_ads[0])
    private func parseAds(from dict: [String: Any]) -> [BannerAd]? {
        var targetDict = dict

        // Decode stringified JSON returned in response["data"] by SDK
        if let responseObj = dict["response"] as? [String: Any],
           let dataString = responseObj["data"] as? String,
           let data = dataString.data(using: .utf8),
           let nestedJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            targetDict = nestedJson
        } else if let dataString = dict["data"] as? String,
                  let data = dataString.data(using: .utf8),
                  let nestedJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            targetDict = nestedJson
        }

        let adsContainer = targetDict["ads"] as? [String: Any]
        guard let container = adsContainer,
              let bannerList = container["banner_ads"] as? [[String: Any]],
              let firstAdDict = bannerList.first else {
            return nil
        }

     
        var feedAds: [BannerAd] = []
        for index in 1...5 {
            if let ad = BannerAd(dict: firstAdDict, index: index) {
                let distinctAd = BannerAd(
                    id: "\(ad.id)_\(index)",
                    uclid: ad.uclid,
                    imageUrl: ad.imageUrl,
                    destinationUrl: ad.destinationUrl,
                    impressionTrackingUrl: ad.impressionTrackingUrl,
                    clickTrackingUrl: ad.clickTrackingUrl,
                    width: ad.width,
                    height: ad.height,
                    position: index
                )
                feedAds.append(distinctAd)
            }
        }
        return feedAds
    }

    // MARK: - Retry Mechanism
    private func handleRetryOrFailure(
        retriesLeft: Int,
        error: Error,
        completion: @escaping (Result<[BannerAd], Error>) -> Void
    ) {
        if retriesLeft > 0 {
            print("[Ad Service] Fetch failed. Retrying... Attempts remaining: \(retriesLeft)")
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                self.fetchBannerAds(retriesLeft: retriesLeft - 1, completion: completion)
            }
        } else {
            //Log Ad Failed
            print("[Ad Event] Ad Failed: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    // MARK: - Event Tracking
    func trackImpression(for ad: BannerAd) {
        Task {
            do {
                let osmos = try OSMOS.shared()
                guard let registerEvent = osmos.registerEvent() else { return }

                await registerEvent.registerAdImpressionEvent(
                    cliUbid: "Any",
                    uclid: ad.uclid,
                    position: ad.position,
                    onError: { err in
                        print("Impression tracking error: \(err.localizedDescription)")
                    }
                )

                // Log Impression Fired
                print("Impression Fired - Ad ID: \(ad.id) at Position: \(ad.position)")

                if let rawUrl = ad.impressionTrackingUrl, let url = URL(string: rawUrl) {
                    URLSession.shared.dataTask(with: url).resume()
                }
            } catch {
                print(" Impression exception: \(error.localizedDescription)")
            }
        }
    }

    func trackClick(for ad: BannerAd) {
        Task {
            do {
                let osmos = try OSMOS.shared()
                guard let registerEvent = osmos.registerEvent() else { return }

                if let clickUrl = ad.clickTrackingUrl, !clickUrl.isEmpty {
                    _ = await registerEvent.registerAClickEvent(cliUbid: "Any", url: clickUrl)
                } else {
                    _ = await registerEvent.registerAdClickEvent(
                        cliUbid: "Any",
                        uclid: ad.uclid,
                        trackingParams: nil,
                        onError: { err in
                            print("Click tracking error: \(err.localizedDescription)")
                        }
                    )
                }

                // Log Click Fired
                print("Click Fired - Ad ID: \(ad.id)")
            } catch {
                print("Click exception: \(error.localizedDescription)")
            }
        }
    }
}
