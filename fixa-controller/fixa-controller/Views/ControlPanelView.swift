//
//  ControlPanelView.swift
//  fixa-controller
//
//  Created by Ivan Milles on 2020-07-24.
//  Copyright © 2020 Ivan Milles. All rights reserved.
//

import SwiftUI

import fixa

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

struct ControlPanelView: View {
	@ObservedObject var clientState: ControllerState
	
	var body: some View {
		let orderedControls = Array(clientState.fixableConfigs).sorted(by: { (lhs, rhs) in lhs.value.order < rhs.value.order })
		VStack {
			if clientState.connecting {
				ActivityIndicator()
			} else if clientState.connected {
				ForEach(orderedControls, id: \.self.key) { (key, value) in
					switch value {
						case .bool(let display):
							FixableToggle(value: self.clientState.fixableBoolBinding(for: key),
														label: display.label)
								.padding(.bottom)
								.frame(maxWidth: .infinity)
						case .float(let min, let max, let display):
							FixableSlider(value: self.clientState.fixableFloatBinding(for: key),
														label: display.label, min: min, max: max)
								.padding(.bottom)
								.frame(maxWidth: .infinity)
						case .color(let display):
							FixableColorWell(value: self.clientState.fixableColorBinding(for: key),
															 label: display.label)
								.padding(.bottom)
								.frame(maxWidth: .infinity)
						case .divider(let display):
							Text(display.label)
								.font(.headline)
								.padding(.bottom)
								.frame(maxWidth: .infinity)
					}
				}
			}
			Spacer()
			HStack {
				Button(action: { self.clientState.persistTweaks() }) {
					Text("Store")
				}
				Button(action: { self.clientState.restoreTweaks() }) {
					Text("Restore")
				}
			}
		}.padding(16.0)
		 .frame(minWidth: 320.0)
	}
}

struct ControlPanelView_Previews: PreviewProvider {
    static var previews: some View {
			let previewState = ControllerState()
			previewState.connected = true
			previewState.connecting = false
			previewState.fixableConfigs = [
				FixableId("header") : .divider(display: FixableDisplay("Header", order: 0)),
				FixableId("slider1") : .float(min: 0.25, max: 1.0, display: FixableDisplay("Slider 1", order: 3)),
				FixableId("slider2") : .float(min: 0.0, max: 360.55, display: FixableDisplay("Slider 2", order: 2)),
				FixableId("toggle") : .bool(display: FixableDisplay("Toggle", order: 1)),
				FixableId("color") : .color(display: FixableDisplay("Color", order: 5))
			]
			previewState.fixableValues = [
				FixableId("slider1") : .float(value: 0.5),
				FixableId("slider2") : .float(value: 45.0),
				FixableId("toggle") : .bool(value: false),
				FixableId("color") : .color(value: CGColor(srgbRed: 1.0, green: 0.6, blue: 0.1, alpha: 1.0))
			]
			return ControlPanelView(clientState: previewState)
				.frame(width: 450.0, height: 600.0)
    }
}
