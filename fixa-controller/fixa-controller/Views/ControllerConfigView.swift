//
//  ControllerConfigView.swift
//  fixa-controller
//
//  Created by Ivan Milles on 2023-05-10.
//  Copyright © 2023 Ivan Milles. All rights reserved.
//

import SwiftUI
import Combine
import fixa

struct ControllerConfigView: View {
	@ObservedObject var clientState: ControllerState
	var midiHooks: FixaMidiHooks?

	var body: some View {
		let orderedControls = Array(clientState.fixableConfigs)
		HStack {
			VStack(alignment: .leading) {
				Text("Available controllers").font(.title)
				Picker("Controller", selection: $clientState.selectedController) {
					ForEach(clientState.externalControllers, id: \.self) { name in
						Text(name).tag(name)
					}
				}.padding(16.0)
				ForEach(orderedControls, id: \.self.key) { (key, value) in
					HStack {
						Button(action: { self.startBinding(key) } ) {
							Text(bindingLabel(value))
						}.disabled(clientState.pendingBind != nil)
						if clientState.pendingBind == key {
							ActivityIndicator()
						}
					}
				}
			}.padding(16.0)
		}.padding(16.0)
	}
	
	func startBinding(_ key: FixableId) {
		clientState.pendingBind = key
		midiHooks?.startBinding(key)
	}
	
	func bindingLabel(_ config: FixableConfig) -> String {
		var label = ""
		switch config {
			case .bool(let display): label = display.label
			case .float(_, _, let display): label = display.label
			default: label = ""
		}
		return "Bind \(label)"
	}
}

struct ControllerConfigView_Previews: PreviewProvider {
	
	static var previews: some View {
		let previewState = ControllerState()
		return ControllerConfigView(clientState: previewState)
			.frame(width: 400.0, height: 600)
	}
}
