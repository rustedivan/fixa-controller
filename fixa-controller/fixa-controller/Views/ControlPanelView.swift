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
		let orderedControls = Array(clientState.fixableValues).sorted(by: { (lhs, rhs) in lhs.value.order < rhs.value.order })
		VStack {
			if clientState.connecting {
				ActivityIndicator()
			} else if clientState.connected {
				ForEach(orderedControls, id: \.self.key) { (key, value) in
					switch value {
						case .bool(_, let display):
							FixableToggle(value: self.clientState.fixableBoolBinding(for: key),
														label: display.label)
								.padding(.bottom)
								.frame(maxWidth: .infinity)
						case .float(_, let min, let max, let display):
							FixableSlider(value: self.clientState.fixableFloatBinding(for: key),
														label: display.label, min: min, max: max)
								.padding(.bottom)
								.frame(maxWidth: .infinity)
						case .color(_, let display):
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

	func insertTypedController(_ fixable: FixableConfig, key: FixableId) -> AnyView {
		let controller: AnyView
		switch fixable {
			case .bool(_, let display):
				let binding = self.clientState.fixableBoolBinding(for: key)
				controller = AnyView(FixableToggle(value: binding, label: display.label))
			case .float(_, let min, let max, let display):
				let binding = self.clientState.fixableFloatBinding(for: key)
				controller = AnyView(FixableSlider(value: binding, label: display.label, min: min, max: max))
			case .color(_, let display):
				let binding = self.clientState.fixableColorBinding(for: key)
				controller = AnyView(FixableColorWell(value: binding, label: display.label))
			case .divider(let display):
				controller = AnyView(Text(display.label).font(.headline))
		}
		
		return AnyView(
			controller.frame(maxWidth: .infinity)
		)
	}
}

struct ControlPanelView_Previews: PreviewProvider {
    static var previews: some View {
			let previewState = ControllerState()
			previewState.connected = true
			previewState.connecting = false
			previewState.fixableValues = [
				FixableId("header") : .divider(display: FixableDisplay("Header", order: 0)),
				FixableId("slider1") : .float(value: 0.5, min: 0.25, max: 1.0, display: FixableDisplay("Slider 1", order: 3)),
				FixableId("slider2") : .float(value: 90.0, min: 0.0, max: 360.55, display: FixableDisplay("Slider 2", order: 2)),
				FixableId("toggle") : .bool(value: true, display: FixableDisplay("Toggle", order: 1)),
				FixableId("color") : .color(value: .black, display: FixableDisplay("Color", order: 5))
			]
			return ControlPanelView(clientState: previewState)
				.frame(width: 450.0, height: 600.0)
    }
}
