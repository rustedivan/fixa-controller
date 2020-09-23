//
//  AppDelegate.swift
//  fixa-example
//
//  Created by Ivan Milles on 2020-07-24.
//  Copyright © 2020 Ivan Milles. All rights reserved.
//

import UIKit
import Combine
import CoreGraphics.CGColor

import fixa

// % Declare the set of fixable values
struct AppFixables {
	static let size = FixableSetup("Envelope size", config: .float(value: 50.0, min: 10.0, max: 150.0, display: FixableDisplay("Envelope size")))
	static let angle = FixableSetup("Envelope angle", config: .float(value: 0.0, min: -180.0, max: 180.0, display: FixableDisplay("Envelope angle")))
	static let open = FixableSetup("Letter read", config: .bool(value: false, display: FixableDisplay("Letter read")))
	static let color = FixableSetup("Letter color", config: .color(value: UIColor.blue.cgColor, display: FixableDisplay("Letter color")))
}

class VisualEnvelope: ObservableObject {
	@Published var size = FixableFloat(AppFixables.size)		// % Wrap the variable instances by type and name
	@Published var angle = FixableFloat(AppFixables.angle)
	@Published var open = FixableBool(AppFixables.open)
	@Published var color = FixableColor(AppFixables.color)
	var sizeSubject: AnyCancellable? = nil
	var angleSubject: AnyCancellable? = nil
	var openSubject: AnyCancellable? = nil
	var colorSubject: AnyCancellable? = nil
	
	init() {
		// $ Future: assign(to: self.objectWillChange)
		sizeSubject = size.newValues.sink { _ in self.objectWillChange.send() }
		angleSubject = angle.newValues.sink { _ in self.objectWillChange.send() }
		openSubject = open.newValues.sink { _ in self.objectWillChange.send() }
		colorSubject = color.newValues.sink { _ in self.objectWillChange.send() }
	}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var envelope: VisualEnvelope?
	
	var fixaStream = FixaStream(fixableSetups: [
		FixableSetup("Tweaks", config: .divider(display: FixableDisplay("Tweaks"))),
		AppFixables.size,
		AppFixables.angle,
		AppFixables.color,
		FixableSetup("Controls", config: .divider(display: FixableDisplay("Controls"))),
		AppFixables.open
	])
		
		
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		envelope = VisualEnvelope()
		
		fixaStream.startListening()
		return true
	}
	
	// $ stop/restart the listener
	
	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}

	

}

