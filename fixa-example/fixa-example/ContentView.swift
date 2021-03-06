//
//  ContentView.swift
//  fixa-example
//
//  Created by Ivan Milles on 2020-07-24.
//  Copyright © 2020 Ivan Milles. All rights reserved.
//

import SwiftUI

struct ContentView: View {
	@ObservedObject var envelopeState: VisualEnvelope
	var body: some View {
		Image(systemName: Bool(envelopeState.open) ? "envelope.open.fill" : "envelope.fill")
			.font(.system(size: CGFloat(Float(envelopeState.size))))
			.rotationEffect(Angle(degrees: Double(Float(envelopeState.angle))))
			.foregroundColor(Color(UIColor(cgColor: envelopeState.color.value)))
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		let envelopeState = VisualEnvelope()
		return ContentView(envelopeState: envelopeState)
	}
}
