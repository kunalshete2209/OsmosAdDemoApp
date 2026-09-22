//
//  BannerAd.swift
//  OsmosAdDemoApp
//
//  Created by Kunal Shete on 21/09/26.
//

import UIKit

struct BannerAd {
    let id: String
    let uclid: String
    let imageUrl: String
    let destinationUrl: String
    let impressionTrackingUrl: String?
    let clickTrackingUrl: String?
    let width: CGFloat
    let height: CGFloat
    let position: Int
    var hasFiredImpression: Bool = false

    init(
        id: String,
        uclid: String,
        imageUrl: String,
        destinationUrl: String,
        impressionTrackingUrl: String?,
        clickTrackingUrl: String?,
        width: CGFloat,
        height: CGFloat,
        position: Int
    ) {
        self.id = id
        self.uclid = uclid
        self.imageUrl = imageUrl
        self.destinationUrl = destinationUrl
        self.impressionTrackingUrl = impressionTrackingUrl
        self.clickTrackingUrl = clickTrackingUrl
        self.width = width
        self.height = height
        self.position = position
        self.hasFiredImpression = false
    }

    init?(dict: [String: Any], index: Int = 1) {
        self.position = index
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.uclid = dict["uclid"] as? String ?? ""
        self.impressionTrackingUrl = dict["impression_tracking_url"] as? String
        self.clickTrackingUrl = dict["click_tracking_url"] as? String

        guard let elements = dict["elements"] as? [String: Any],
              let image = elements["value"] as? String else {
            return nil
        }

        self.imageUrl = image
        // If destination_url is not present by the demo server we have uses osmos.ai
        self.destinationUrl = elements["destination_url"] as? String ?? "https://osmos.ai"
        self.width = elements["width"] as? CGFloat ?? 200
        self.height = elements["height"] as? CGFloat ?? 200
        self.hasFiredImpression = false
    }
}
