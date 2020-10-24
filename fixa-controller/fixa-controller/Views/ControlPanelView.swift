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
		VStack {
			if clientState.connecting {
				ActivityIndicator()
			} else if clientState.connected {
				// $ This is terrible until XC12
				ForEach(Array(clientState.fixableValues)
									.sorted(by: { (lhs, rhs) in lhs.value.order < rhs.value.order }), id: \.self.key) { (key, value) in
										self.insertTypedController(self.clientState.fixableValues[key]!, key: key)
						.padding(.bottom)
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
				FixableId("slider1", in: "header") : .float(value: 0.5, min: 0.25, max: 1.0, display: FixableDisplay("Slider 1", order: 3)),
				FixableId("slider2", in: "header") : .float(value: 90.0, min: 0.0, max: 360.55, display: FixableDisplay("Slider 2", order: 2)),
				FixableId("Toggle", in: "header") : .bool(value: true, display: FixableDisplay("Toggle", order: 1)),
				FixableId("Color") : .color(value: .black, display: FixableDisplay("Color", order: 5))
			]
			return ControlPanelView(clientState: previewState)
				.frame(width: 450.0, height: 600.0)
    }
}
