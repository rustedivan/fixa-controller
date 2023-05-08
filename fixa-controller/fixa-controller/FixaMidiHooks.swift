//
//  FixaMidiHooks.swift
//  fixa-controller
//
//  Created by Ivan Milles on 2023-05-07.
//  Copyright © 2023 Ivan Milles. All rights reserved.
//

import Foundation
import CoreMIDI
import fixa

fileprivate enum FixableMidiBinding {
	case hold(_ id: FixableId)
	case toggle(_ id: FixableId, _ on: Bool)
	case stepper(_ id: FixableId)
	case event(_ id: FixableId, _ label: String)
}

typealias FixaMidiApplyMessage = (FixableId, FixableValue) -> ()

fileprivate enum MidiVoices: UInt8 {
	case noteOff = 0x80
	case noteOn = 0x90
	case keyPress = 0xa0
	case control = 0xb0
	case program = 0xc0
	case channel = 0xd0
	case pitch = 0xe0
}

class FixaMidiHooks {
	private var midiClient: MIDIClientRef
	private var midiInputPort: MIDIPortRef
	private var midiBindings: [UInt8 : FixableMidiBinding] = [:]
	private var midiConfigs: NamedFixableConfigs = [:]
	private var listenForTrigger: FixableMidiBinding? = nil
	
	private var messageCallback: FixaMidiApplyMessage? = nil
	
	init() {
		// Setup CoreMIDI
		midiClient = 0
		_ = withUnsafeMutablePointer(to: &midiClient) { client in
			MIDIClientCreateWithBlock("Fixa MIDI Hook" as CFString, client) { notificationPtr in
				let notification = notificationPtr.pointee
				switch notification.messageID {
					case .msgObjectAdded: print("Added MIDI device")			// $ handle
					case .msgObjectRemoved: print("Removed MIDI device")	// $ handle
					default: return
				}
			}
		}
		
		// Listen to and dispatch MIDI messages
		midiInputPort = 0
		_ = withUnsafeMutablePointer(to: &midiInputPort, { port in
			MIDIInputPortCreateWithBlock(midiClient, "Fixa Midi input port" as CFString, port) { (packets, connRefCon) in
				for packet in packets.unsafeSequence() {
					if let listenForTrigger = self.listenForTrigger {
						if self.bindMessage(packet.pointee, to: listenForTrigger) {
							self.listenForTrigger = nil
						}
					} else {
						self.applyPacket(packet.pointee)
					}
				}
			}
		})
		
		// $ temp
		makeBinding(number: 1, voice: .control, binding: .stepper(FixableId("angle")))
		makeBinding(number: 9, voice: .control, binding: .stepper(FixableId("size")))
		makeBinding(number: 21, voice: .noteOn, binding: .hold(FixableId("open")))
	}
	
	func midiIsAvailable() -> Bool {
		return MIDIGetNumberOfSources() > 0
	}
	
	func midiDevices() -> [(String, MIDIEndpointRef)] {
		var out: [(String, MIDIEndpointRef)] = []
		let n = MIDIGetNumberOfSources()
		
		for i in 0..<n {
			let source = MIDIGetSource(i)
			var name: Unmanaged<CFString>?
			MIDIObjectGetStringProperty(source, kMIDIPropertyDisplayName, &name)
			if let name = name {
				out.append((String(name.takeRetainedValue()), source))
			}
		}
		return out
	}

	func useMidiDevice(name: String, endpoint: MIDIEndpointRef, forConfigs configs: NamedFixableConfigs) -> Bool {
		var source = endpoint
		let err = MIDIPortConnectSource(midiInputPort, source, &source)
		applyConfigs(configs)
		return err == noErr
	}
	
	func applyMidiMessage(_ callback: @escaping FixaMidiApplyMessage) {
		messageCallback = callback
	}
	
	fileprivate func applyConfigs(_ configs: NamedFixableConfigs) {
		for (key, config) in configs {
			switch config {
				case .group(let contents, _):
					for (nestedKey, nestedConfig) in contents {
						midiConfigs[nestedKey] = nestedConfig
					}
					break
				case .divider:
					break
				default:
					midiConfigs[key] = config
			}
		}
	}
	
	fileprivate func applyPacket(_ packet: MIDIPacket) {
		guard let cb = messageCallback else {
			print("No MIDI application callback bound")
			return
		}
		let voice = MidiVoices(rawValue: packet.data.0 & 0xf0)
		let target = packet.data.1
		let data = Int(packet.data.2)
		if let binding = midiBindings[target] {
			switch(binding) {
				case .stepper(let fixableId):
					if case let .float(min, max, _) = midiConfigs[fixableId] {
						cb(fixableId, .float(value: min + (max - min) * Float(data) / 127.0))
					}
				case .toggle(let fixableId, let wasOn) where voice == .noteOff:
					if case .bool = midiConfigs[fixableId] {
						midiBindings[target] = .toggle(fixableId, !wasOn)
						cb(fixableId, .bool(value: !wasOn))
					}
				case .hold(let fixableId):
					if case .bool = midiConfigs[fixableId] {
						cb(fixableId, .bool(value: voice == .noteOn))
					}
				case .event(let fixableId, let label):
					// $ fixable event needed
					fallthrough
				default: return
			}
		}
	}
	
	fileprivate func bindMessage(_ packet: MIDIPacket, to binding: FixableMidiBinding) -> Bool {
		let status = packet.data.0
		let number = packet.data.1
		let voiceNibble = status & 0xf0
		let voice = MidiVoices(rawValue: voiceNibble)
		if let voice = voice {
			switch(binding, voice) {
				case (.event, .noteOn): fallthrough
				case (.event, .keyPress):
					print("Bind button to event")
				case (.stepper, .control): fallthrough
				case (.stepper, .pitch):
					print("Bind knob/slider to stepper")
				case (.hold, .noteOn): fallthrough
				case (.hold, .keyPress):
					print("Bind button to hold flag")
				case (.toggle, .noteOn): fallthrough
				case (.toggle, .keyPress):
					print("Bind button to toggle")
				default:
					print("Incompatible bind: \(binding) to \(voice)")
					return false
			}
			makeBinding(number: number, voice: voice, binding: binding)
			return true
		}
		return false
	}
	
	fileprivate func makeBinding(number: UInt8, voice: MidiVoices, binding: FixableMidiBinding) {
		print("Binding \(voice) \(number) to \(binding)")
		midiBindings[number] = binding
	}
}
