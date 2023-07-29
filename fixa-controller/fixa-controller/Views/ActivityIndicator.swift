//
//  ActivityIndicator.swift
//  fixa-controller
//
//  Created by Ivan Milles on 2023-05-24.
//  Copyright © 2023 Ivan Milles. All rights reserved.
//

import SwiftUI

// $ SwiftUI cannot yet create ActivityIndicator
struct ActivityIndicator: NSViewRepresentable {
	typealias NSViewType = NSProgressIndicator
	func makeNSView(context: Context) -> NSProgressIndicator {
		let view = NSProgressIndicator()
		view.isIndeterminate = true
		view.startAnimation(nil)
		view.style = .spinning
		view.controlSize = .small
		return view
	}
	
	func updateNSView(_ nsView: NSProgressIndicator, context: Context) {
	}
}
