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
	static let group = FixableId("group")
	static let size = FixableId("size")
	static let angle = FixableId("angle")
	static let open = FixableId("open")
	static let color = FixableId("color")
}

class VisualEnvelope: ObservableObject {
	@Published var size = FixableFloat(AppFixables.size, initial: 50.0)		// % Connect to a Fixable identifier and set the pre-connection value
	@Published var angle = FixableFloat(AppFixables.angle, initial: -30.0)
	@Published var open = FixableBool(AppFixables.open, initial: false)
	@Published var color = FixableColor(AppFixables.color, initial: UIColor.black.cgColor)
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
		(FixableId("tweaks"), 	.divider(display: FixableDisplay("Tweaks"))),
		(AppFixables.group,			.group(contents: [
			(AppFixables.size, 			.float(min: 10.0, max: 150.0, display: FixableDisplay("Envelope size"))),
			(AppFixables.angle, 		.float(min: -180.0, max: 180.0, display: FixableDisplay("Envelope angle"))),
		], display: FixableDisplay("Geometry"))),
		(AppFixables.color, 		.color(display: FixableDisplay("Letter color"))),
		(FixableId("controls"), .divider(display: FixableDisplay("Controls"))),
		(AppFixables.open, 			.bool(display: FixableDisplay("Letter read")))
	])
		
		
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		envelope = VisualEnvelope()
		
		fixaStream.startListening()
		return true
	}
	
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

