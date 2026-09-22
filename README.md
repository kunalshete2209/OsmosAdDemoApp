# OsmosAdDemoApp

A native iOS app built with UIKit and MVVM demonstrating the integration of the Osmos Ad SDK for display banner ads.

---

## Demo Recording

* Video file: `
https://github.com/user-attachments/assets/f6716ce1-cb2f-4d59-a50d-690f922b07a1
 `
* Demonstrates: Ad loading, 50% scroll impression tracking in Xcode console, click redirect via Safari, and offline error handling showing "Ad not available".

---

## Architecture

The project is structured using standard **MVVM**:

* **Views (`AdFeedViewController`, `BannerAdCell`):** Handles table view layout, cell rendering with aspect-fit banner images, and user scroll/tap events.
* **ViewModel (`AdFeedViewModel`):** Manages feed states (`loading`, `loaded`, `empty`, `error`), debounces multiple tap requests, and checks impression eligibility.
* **Services (`OsmosAdManager`):** Wraps the Osmos SDK methods, provides a direct REST API fallback, handles retry logic, and fires tracking events.
* **Utilities (`VisibilityTracker`):** A helper that calculates the percentage of a view visible inside the screen window.

---

## Implementation Details

### 1. Ad Fetching

* The app initializes the SDK in `AppDelegate` with client ID `10088010` and host `demo-ba.o-s.io`.
* Ads are requested using `fetchDisplayAdsWithAu` with `cliUbid: "Any"`, `pageType: "demo_page"`, `productCount: 1`, and `adUnits: ["banner_ads"]`.
* Because the SDK returns data as stringified JSON inside `response["response"]["data"]`, the manager deserializes it into dictionary format before parsing into `BannerAd` models.
* **Fallback:** If the SDK fails or returns an empty payload, a direct GET request is sent to `[https://demo-ba.o-s.io/v2/bsda](https://demo-ba.o-s.io/v2/bsda)` via `URLSession`.

### 2. 50% Viewability Impression Tracking

* On table view scroll, visible cells are converted to window coordinates using `view.convert(view.bounds, to: window)`.
* We compute the intersection between the cell frame and screen window bounds. If visible area / total area is **0.50 or higher**, the impression fires.
* A `hasFiredImpression` flag on each ad prevents duplicate impression calls when scrolling up and down.

### 3. Click Handling

* Tapping a banner card triggers `registerAdClickEvent` / `registerAClickEvent` with the ad's `uclid`.
* The destination URL opens modally inside `SFSafariViewController`.

### 4. Error Handling & Fallback UI

* Failed network calls automatically retry up to 2 times with a 1-second delay.
* If all retries fail or no ads return, the table view displays a centered **"Ad not available"** label.
* Missing fields in the API payload are safely unwrapped with fallback values so the app never crashes.

---

## Assumptions & Challenges

* **5-Item Feed:** The demo API only provisions 1 ad unit at a time (`productCount: 1`). To demonstrate table view scrolling, viewport clipping, and position-based impression firing, this ad is mapped across 5 feed items (`_1` to `_5`).
* **Missing Destination URL:** The demo endpoint payload did not return a `destination_url` key inside `elements`. Added a fallback to `[https://osmos.ai](https://osmos.ai)` so tap interactions could be tested without crashing.
* **Simulator Reconnection Lag:** Toggling Wi-Fi in the simulator kept broken TCP connections alive in `URLSession.shared`. Configured an ephemeral `URLSession` ignoring local cache to ensure immediate recovery when internet reconnects.

---

## How to Run

1. Clone the repository:
```bash
git clone https://github.com/kunalshete2209/OsmosAdDemoApp.git
cd OsmosAdDemoApp

```


2. Open `OsmosAdDemoApp.xcodeproj` in Xcode (15 or later).
3. Let Swift Package Manager finish resolving `osmos-ios-sdk-spm`.
4. Select an iOS Simulator (iOS 16+) and press **Cmd + R** to run.
5. Tap **Load Ad** to test the feed.
