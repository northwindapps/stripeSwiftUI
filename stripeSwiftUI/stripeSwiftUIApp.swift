//
//  stripeSwiftUIApp.swift
//  stripeSwiftUI
//
//  Created by yujin on 2021/05/31.
//

import SwiftUI
import Stripe

class AppDelegate:NSObject, UIApplicationDelegate{
    func applicationDidFinishLaunching(_ application: UIApplication,  launchOptions:[UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        StripeAPI.defaultPublishableKey = "sk_test_51GqE6AJri2UpFjVbvjVvivnsCf2alGTBungm9O3EATMRCpWoqvhnVokNEzukZ5tISRHVK6poN9HjfSbFuqDYCkqD00rWfcQqOF"
        return true
    }
}
@main
struct stripeSwiftUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ProductView()
        }
    }
}
