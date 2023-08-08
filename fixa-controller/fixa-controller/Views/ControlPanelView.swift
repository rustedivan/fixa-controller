//
//  ControlPanelView.swift
//  fixa-controller
//
//  Created by Ivan Milles on 2020-07-24.
//  Copyright © 2020 Ivan Milles. All rights reserved.
//

import SwiftUI
import Combine
import fixa

fileprivate typealias TabControls = (String, [(FixableId, FixableConfig)])

struct ControlPanelView: View {
	@ObservedObject var clientState: ControllerState
	var externalControllerSubject = PassthroughSubject<(), Never>()
	
	var body: some View {
		let tabs = arrangeTabs(controls: clientState.fixableConfigs)
		VStack {
			if clientState.connecting {
				ActivityIndicator()
			} else if clientState.connected {
				TabView {
					ForEach(tabs, id: \.self.0) { (key, value) in
						VStack {
							ForEach(value, id: \.self.0) { (fixableId, config) in
								insertControl(key: fixableId, config: config)
							}
						}
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
						.tabItem {
							Text(key)
						}
					}.padding(.all)
				}.padding(.all)
				HStack {
					Button(action: { self.clientState.persistTweaks() }) {
						Text("Store")
					}
					Button(action: { self.clientState.restoreTweaks() }) {
						Text("Restore")
					}
					if clientState.externalControllers.isEmpty == false {
						Button(action: { self.openControllerConfig() } ) {
							Text("Select controller")
						}
					}
				}.padding([.top, .bottom], 16.0)
			}
		}.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	@ViewBuilder
	func insertGrouping(key: FixableId, config: FixableConfig) -> some View {
		switch config {

			case .group(let contents, let display):
				GroupBox(label: Text(display.label)) {
					ForEach(contents, id: \.self.0.hashValue) { (key, value) in
						insertControl(key: key, config: value)
					}
				}.padding(.bottom)
			default:
				insertControl(key: key, config: config)
		}
	}
	
	@ViewBuilder
	func insertControl(key: FixableId, config: FixableConfig) -> some View {
		let controlPadding = 8.0
		switch config {
			case .bool(let display):
				FixableToggle(value: self.clientState.fixableBoolBinding(for: key),
											label: display.label)
									.padding(.bottom, controlPadding)
									.frame(maxWidth: .infinity)
			case .float(let min, let max, let display):
				FixableSlider(value: self.clientState.fixableFloatBinding(for: key),
											label: display.label, min: min, max: max)
					.padding(.bottom, controlPadding)
					.frame(maxWidth: .infinity)
			case .color(let display):
				FixableColorWell(value: self.clientState.fixableColorBinding(for: key),
												 label: display.label)
					.padding(.bottom, controlPadding)
					.frame(maxWidth: .infinity)
			case .divider(let display):
				Text(display.label)
					.font(.headline)
					.padding(.bottom, controlPadding)
					.frame(maxWidth: .infinity)
			default:
				Text("Unmapped control: \(key.debugDescription)").font(.callout).foregroundColor(.red)
		}
	}
	
	func openControllerConfig() {
		externalControllerSubject.send(())
	}
	
	fileprivate func arrangeTabs(controls: NamedFixableConfigs) -> [TabControls] {
		var groupTabs: [TabControls] = []
		var defaultTab: TabControls = TabControls("General", [])
		
		for control in controls {
			if case let .group(contents, display) = control.value {
				groupTabs.append((display.label, contents))
			} else {
				defaultTab.1.append(control)
			}
		}
		
		var allTabs: [TabControls] = []
		if defaultTab.1.count > 0 {
			let sortedTab = TabControls(defaultTab.0, defaultTab.1.sorted(by: { (lhs, rhs) in lhs.1.order < rhs.1.order }))
			allTabs.append(sortedTab)
		}
		for tab in groupTabs {
			let sortedTab = TabControls(tab.0, tab.1.sorted(by: { (lhs, rhs) in lhs.1.order < rhs.1.order }))
			allTabs.append(sortedTab)
		}
		return allTabs
	}
}

extension FixableConfig: Hashable {
	public static func == (lhs: FixableConfig, rhs: FixableConfig) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
	
	public func hash(into hasher: inout Hasher) {
		let displayHash: FixableDisplay
		switch self {
			case .bool(let display):
				displayHash = display
			case .float(_, _, let display):
				displayHash = display
			case .color(let display):
				displayHash = display
			case .divider(let display):
				displayHash = display
			case .group(_, let display):
				displayHash = display
		}
		
		hasher.combine(displayHash.label)
		hasher.combine(displayHash.order)
	}
	
	var childControls: [FixableConfig]? {
		if case let .group(contents, _) = self {
			return contents.map { $0.1 }
		} else {
			return nil
		}
	}
}

struct ControlPanelView_Previews: PreviewProvider {
    static var previews: some View {
			let previewState = ControllerState()
			previewState.connected = true
			previewState.connecting = false
			previewState.fixableConfigs = [
				FixableId("header") : .divider(display: FixableDisplay("Header", order: 0)),
				FixableId("top-group") : .group(contents: [
					(FixableId("slider1"), .float(min: 0.25, max: 1.0, display: FixableDisplay("Slider 1", order: 3))),
					(FixableId("slider2"), .float(min: 0.0, max: 360.55, display: FixableDisplay("Slider 2", order: 2)))
				], display: FixableDisplay("Top sliders", order: 2)),
				FixableId("bottom-group") : .group(contents: [
					(FixableId("slider3"), .float(min: 0.25, max: 1.0, display: FixableDisplay("Slider 3", order: 3))),
					(FixableId("slider4"), .float(min: 0.0, max: 360.55, display: FixableDisplay("Slider 4", order: 2)))
				], display: FixableDisplay("Bottom sliders", order: 3)),
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
