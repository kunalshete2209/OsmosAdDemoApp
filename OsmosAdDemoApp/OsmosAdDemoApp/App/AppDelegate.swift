//
//  AppDelegate.swift
//  OsmosAdDemoApp
//
//  Created by Kunal Shete on 21/09/26.
//
//
//import UIKit
//
//@main
//class AppDelegate: UIResponder, UIApplicationDelegate {
//
//
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        // Override point for customization after application launch.
//        return true
//    }
//
//    // MARK: UISceneSession Lifecycle
//
//    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//        // Called when a new scene session is being created.
//        // Use this method to select a configuration to create the new scene with.
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
//
//    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
//        // Called when the user discards a scene session.
//        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
//        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
//    }
//
//
//}

import UIKit
import osmos

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        initializeOsmosSDK()
        return true
    }

    private func initializeOsmosSDK() {
        do {
            try OSMOS.Builder()
                .clientId("10088010")
                .productAdsHost("demo.o-s.io")
                .displayAdsHost("demo-ba.o-s.io")
                .debug(true)
                .buildGlobalInstance()
            print("SDK - Osmos initialized successfully.")
        } catch {
            print("SDK Error - Failed to initialize Osmos: \(error.localizedDescription)")
        }
    }
}
