//
//  ControlPanelView.swift
//  fixa-controller
//
//  Created by Ivan Milles on 2020-07-24.
//  Copyright © 2020 Ivan Milles. All rights reserved.
//

import SwiftUI

import fixa

///////////////////
// $ Until SwiftUI improves
// SwiftUI cannot yet create ActivityIndicator, and Slider config support is too weak.
///////////////////

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

struct ColorWell: NSViewRepresentable {
	class Coordinator: NSObject {
		@Binding var value: CGColor
		init(value: Binding<CGColor>) {
			self._value = value
		}
		@objc func valueChanged(_ sender: NSColorWell) {
			self.value = sender.color.cgColor
		}
	}
	
	@Binding var value: CGColor
	typealias NSViewType = NSColorWell
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(value: $value)
	}
	
	func makeNSView(context: Context) -> NSColorWell {
		let view = NSColorWell()
		view.target = context.coordinator
		view.action = #selector(Coordinator.valueChanged(_:))
		return view
	}
	
	func updateNSView(_ nsView: NSColorWell, context: Context) {
		nsView.color = NSColor(cgColor: value)!
	}
}

struct ValueSlider: NSViewRepresentable {
	class Coordinator: NSObject {
		@Binding var value: Float
		init(value: Binding<Float>) {
			self._value = value
		}
		@objc func valueChanged(_ sender: NSSlider) {
			self.value = sender.floatValue
		}
	}
	
	@Binding var value: Float
	let minValue: Float
	let maxValue: Float
	typealias NSViewType = NSSlider
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(value: $value)
	}
	
	func makeNSView(context: Context) -> NSSlider {
		let view = NSSlider(value: Double(value),
												minValue: Double(minValue), maxValue: Double(maxValue),
												target: context.coordinator,
												action: #selector(Coordinator.valueChanged(_:)))
		view.numberOfTickMarks = 10
		return view
	}
	
	func updateNSView(_ nsView: NSSlider, context: Context) {
		nsView.floatValue = value
	}
}
//////////////////

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

struct FixableToggle: View {
	@Binding var value: Bool
	let label: String
	
	var body: some View {
		HStack{
			Text(label)
			Toggle(isOn: $value) { Text("") }
			Spacer()
		}
	}
}

struct FixableSlider: View {
	@Binding var value: Float
	let label: String
	let min: Float
	let max: Float
	
	var body: some View {
		let format = NumberFormatter()
		format.usesSignificantDigits = true
		format.minimumSignificantDigits = 2
		format.maximumSignificantDigits = 5
		return VStack {
			Text(label).frame(maxWidth: .infinity, alignment: .leading)
			HStack {
				VStack {
					ValueSlider(value: $value, minValue: min, maxValue: max)
					HStack {
						Text(format.string(from: NSNumber(value: min))!).font(.system(size: 10.0)).foregroundColor(.gray)
						Spacer()
						Text(format.string(from: NSNumber(value: max))!).font(.system(size: 10.0)).foregroundColor(.gray)
					}
				}.padding(.leading)
				TextField("", value: $value, formatter: format).frame(maxWidth: 50.0)
			}
		}
	}
}

struct FixableColorWell: View {
	@Binding var value: CGColor
	let label: String
	
	var body: some View {
		HStack{
			Text(label)
			ColorWell(value: $value).frame(width: 24.0, height: 24.0)
			Spacer()
		}
	}
}

struct ControlPanelView_Previews: PreviewProvider {
    static var previews: some View {
			let previewState = ControllerState()
			previewState.connected = true
			previewState.connecting = false
			previewState.fixableValues = [
				FixableId() : .divider(display: FixableDisplay("Header", order: 0)),
				FixableId() : .float(value: 0.5, min: 0.25, max: 1.0, display: FixableDisplay("Slider 1", order: 3)),
				FixableId() : .float(value: 90.0, min: 0.0, max: 360.55, display: FixableDisplay("Slider 2", order: 2)),
				FixableId() : .bool(value: true, display: FixableDisplay("Toggle", order: 1)),
				FixableId() : .color(value: .black, display: FixableDisplay("Color", order: 5))
			]
			return ControlPanelView(clientState: previewState)
				.frame(width: 450.0, height: 600.0)
    }
}
