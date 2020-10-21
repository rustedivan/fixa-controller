//
//  TweakColorWell.swift
//  fixa-controller
//
//  Created by Ivan Milles on 2020-10-18.
//  Copyright © 2020 Ivan Milles. All rights reserved.
//

import SwiftUI

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
