//
//  VisibilityTracker.swift
//  OsmosAdDemoApp
//
//  Created by Kunal Shete on 21/09/26.
//

import UIKit

enum VisibilityTracker {
    static func visibleRatio(of view: UIView, in referenceWindow: UIWindow?) -> CGFloat {
        guard let window = referenceWindow ?? view.window,
              !view.isHidden,
              view.alpha > 0.01 else {
            return 0.0
        }

        let viewRectInWindow = view.convert(view.bounds, to: window)
        let visibleIntersection = viewRectInWindow.intersection(window.bounds)

        guard !visibleIntersection.isNull else { return 0.0 }

        let visibleArea = visibleIntersection.width * visibleIntersection.height
        let totalArea = view.bounds.width * view.bounds.height

        return totalArea > 0 ? (visibleArea / totalArea) : 0.0
    }
}
