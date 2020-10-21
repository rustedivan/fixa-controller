//
//  TweakSlider.swift
//  fixa-controller
//
//  Created by Ivan Milles on 2020-10-18.
//  Copyright © 2020 Ivan Milles. All rights reserved.
//

import SwiftUI

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
