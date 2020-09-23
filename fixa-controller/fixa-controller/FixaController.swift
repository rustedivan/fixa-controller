//
//  FixaController.swift
//  fixa-controller
//
//  Created by Ivan Milles on 2020-07-24.
//  Copyright © 2020 Ivan Milles. All rights reserved.
//

import Foundation
import Combine
import Network
import SwiftUI

import fixa

class ControllerState: ObservableObject {
	var controllerValueChanged = PassthroughSubject<[String], Never>()
	@Published var connecting: Bool
	@Published var connected: Bool
	@Published var fixableValues: NamedFixables {
		didSet { controllerValueChanged.send(dirtyKeys) }
	}
	var dirtyKeys: [String]

	init() {
		connecting = false
		connected = false
		fixableValues = [:]
		dirtyKeys = []
	}
	
	func fixableBoolBinding(for key: String) -> Binding<Bool> {
		let bound = fixableValues[key]
		return .init(
			get: {
				guard case let .bool(value, _) = bound else { return false }
				return value
			},
			set: {
				guard case let .bool(_, display) = bound else { return }
				self.dirtyKeys.append(key)	// Mark the key as dirty before updating the value, otherwise valueChangedStream won't see it
				self.fixableValues[key] = .bool(value: $0, display: display)
			})
	}
	
	func fixableFloatBinding(for key: String) -> Binding<Float> {
		return .init(
			get: {
				guard case let .float(value, _, _, _) = self.fixableValues[key] else { return 0.0 }
				return value
			},
			set: {
				guard case .float(_, let min, let max, let display) = self.fixableValues[key] else { return }
				self.dirtyKeys.append(key)	// Mark the key as dirty before updating the value, otherwise valueChangedStream won't see it
				self.fixableValues[key] = .float(value: $0, min: min, max: max, display: display)
			})
	}
	
	func fixableColorBinding(for key: String) -> Binding<CGColor> {
		return .init(
			get: {
				guard case let .color(value, _) = self.fixableValues[key] else { return .black }
				return value
			},
			set: {
				guard case .color(_, let display) = self.fixableValues[key] else { return }
				self.dirtyKeys.append(key)	// Mark the key as dirty before updating the value, otherwise valueChangedStream won't see it
				self.fixableValues[key] = .color(value: $0, display: display)
			})
	}
}

class FixaController: FixaProtocolDelegate {
	enum SendFrequency: Double {
		case immediately = 0.0
		case normal = 0.02
		case careful = 0.5
	}
	var clientConnection: NWConnection?
	let clientState: ControllerState
	var valueChangedStream: AnyCancellable?
	
	init(frequency: SendFrequency) {
		clientState = ControllerState()
		fixaInitProtocol(withDelegate: self)
		valueChangedStream = clientState.controllerValueChanged
			.throttle(for: .seconds(frequency.rawValue), scheduler: DispatchQueue.main, latest: true)
			.sink { dirtyKeys in
				let dirtyFixables = self.clientState.fixableValues.filter {
					dirtyKeys.contains($0.key)
				}
				fixaSendUpdates(dirtyFixables, over: self.clientConnection!)
				self.clientState.dirtyKeys = []
			}
	}
	
	func openConnection(to endpoint: NWEndpoint) {
		clientState.connecting = true
		clientConnection = fixaMakeConnection(to: endpoint)
		clientConnection?.stateUpdateHandler = { newState in
			switch newState {
				case .ready:
					self.receiveMessage()
				default: break
			}
		}
		clientConnection?.start(queue: .main)
		print("Fixa controller: opened connection to \(clientConnection?.endpoint.debugDescription ?? "unknown endpoint")")
	}
	
	func receiveMessage() {
		clientConnection?.receiveMessage(completion: { (data, context, _, error) in
			fixaReceiveMessage(data: data, context: context, error: error)
			self.receiveMessage()
		})
	}
	
	func hangUp() {
		fixaEndConnection(self.clientConnection!)
	}

	func sessionDidStart(withFixables fixables: NamedFixables) {
		clientState.fixableValues = fixables
		clientState.connected = true
		print("Fixa controller: synching back to app")
		fixaSendUpdates(clientState.fixableValues, over: clientConnection!)
		clientState.connecting = false
	}

	func sessionDidEnd() {
		clientConnection!.cancel()
		clientState.connected = false
	}
}
