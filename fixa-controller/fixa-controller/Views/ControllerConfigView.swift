//
//  ControllerConfigView.swift
//  fixa-controller
//
//  Created by Ivan Milles on 2023-05-10.
//  Copyright © 2023 Ivan Milles. All rights reserved.
//

import SwiftUI
import Combine

struct ControllerConfigView: View {
	@ObservedObject var clientState: ControllerState

	var body: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Available controllers").font(.title)
				Picker("Controller", selection: $clientState.selectedController) {
					ForEach(clientState.externalControllers, id: \.self) { name in
						Text(name).tag(name)
					}
				}.padding(16.0)
			}
			Spacer()
		}.padding(16.0)
	}
}

struct ControllerConfigView_Previews: PreviewProvider {
	
	static var previews: some View {
		let previewState = ControllerState()
		return ControllerConfigView(clientState: previewState)
			.frame(width: 400.0, height: 600)
	}
}
