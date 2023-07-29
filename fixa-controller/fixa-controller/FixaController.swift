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
	var streamName: String = "Not connected"
	var controllerValueChanged = PassthroughSubject<[FixableId], Never>()
	var externalControllerChanged = PassthroughSubject<String, Never>()
	@Published var connecting: Bool
	@Published var connected: Bool
	@Published var fixableConfigs: NamedFixableConfigs
	@Published var fixableValues: NamedFixableValues {
		didSet { controllerValueChanged.send(dirtyKeys) }
	}
	
	// External controller support
	@Published var externalControllers: [String]
	@Published var selectedController: String {
		didSet { externalControllerChanged.send(selectedController) }
	}
	@Published var externalControllerBindings: [UInt8 : FixableMidiBinding] = [:]
	@Published var pendingBind: FixableId?
	
	var dirtyKeys: [FixableId]

	init() {
		connecting = false
		connected = false
		fixableConfigs = [:]
		fixableValues = [:]
		dirtyKeys = []
		externalControllers = []
		selectedController = "" // $ pick from persistence
	}
	
	func fixableBoolBinding(for key: FixableId) -> Binding<Bool> {
		return .init(
			get: {
				guard case let .bool(value) = self.fixableValues[key] else { return false }
				return value
			},
			set: {
				self.dirtyKeys.append(key)	// Mark the key as dirty before updating the value, otherwise valueChangedStream won't see it
				self.fixableValues[key] = .bool(value: $0)
			})
	}
	
	func fixableFloatBinding(for key: FixableId) -> Binding<Float> {
		return .init(
			get: {
				guard case let .float(value) = self.fixableValues[key] else { return 0.0 }
				return value
			},
			set: {
				self.dirtyKeys.append(key)	// Mark the key as dirty before updating the value, otherwise valueChangedStream won't see it
				self.fixableValues[key] = .float(value: $0)
			})
	}
	
	func fixableColorBinding(for key: FixableId) -> Binding<CGColor> {
		return .init(
			get: {
				guard case let .color(value) = self.fixableValues[key] else { return .black }
				return value
			},
			set: {
				self.dirtyKeys.append(key)	// Mark the key as dirty before updating the value, otherwise valueChangedStream won't see it
				self.fixableValues[key] = .color(value: $0)
			})
	}
	
	func persistTweaks() {
		let defaults = UserDefaults.standard
		do {
			let data = try PropertyListEncoder().encode(fixableValues)
			defaults.set(data, forKey: streamName)
		} catch {
			print("Could not store fixables")	// $ Make into alert
		}
	}
	
	func restoreTweaks() {
		let defaults = UserDefaults.standard
		do {
			let data = defaults.object(forKey: streamName) as? Data ?? Data()
			fixableValues = try PropertyListDecoder().decode(NamedFixableValues.self, from: data)
			dirtyKeys = Array(fixableValues.keys)
		} catch {
			print("Could not restore fixables")
		}
	}
}

class FixaController: FixaProtocolDelegate {
	public static var DidEndConnection = Notification.Name(rawValue: "FixaController.DidEndConnection")

	enum SendFrequency: Double {
		case immediately = 0.0
		case normal = 0.02
		case careful = 0.5
	}
	var clientConnection: NWConnection?
	let clientState: ControllerState
	var valueChangedStream: AnyCancellable?
	var externalControllerChangedStream: AnyCancellable?
	
	var midiClient: FixaMidiHooks?
	
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
		externalControllerChangedStream = clientState.externalControllerChanged
			.sink { controllerName in
				print(controllerName)
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
			if context?.isFinal == true {
				print("Fixa controller: app hung up. Disconnecting.")
				self.sessionDidEnd()
				return
			}
			
			fixaReceiveMessage(data: data, context: context, error: error)
			self.receiveMessage()
		})
	}
	
	func hangUp() {
		fixaEndConnection(self.clientConnection!)
	}

	func sessionDidStart(_ name: String, withFixables fixables: NamedFixableConfigs, withValues values: NamedFixableValues) {
		clientState.streamName = name
		clientState.fixableConfigs = fixables
		clientState.fixableValues = values
		clientState.connected = true
		clientState.connecting = false
		
		connectMidi()
	}

	func sessionDidEnd() {
		clientConnection!.cancel()
		clientState.connected = false
		let connectionId = clientConnection!.endpoint.hashValue
		NotificationCenter.default.post(name: FixaController.DidEndConnection, object: connectionId)
	}
	
	func connectMidi() {
		midiClient = FixaMidiHooks()
		
		midiClient!.handleMidiDevice {
			let devices = self.midiClient!.midiDevices()
			self.clientState.externalControllers = devices.map { $0.0 }
		}
		
		midiClient!.applyMidiMessage { (target, midiSetValue) in
			DispatchQueue.main.sync {
				self.clientState.fixableValues[target] = midiSetValue
				self.clientState.controllerValueChanged.send([target])
			}
		}
		
		midiClient!.updateMidiBindings { bindings in
			self.clientState.externalControllerBindings = bindings
			self.clientState.pendingBind = nil
		}
		
		midiClient!.start()
		
		let midiDevices = midiClient!.midiDevices()
		if let firstDevice = midiDevices.first {
			_ = midiClient!.useMidiDevice(name: firstDevice.0, endpoint: firstDevice.1, forConfigs: clientState.fixableConfigs)
		}
	}
}
