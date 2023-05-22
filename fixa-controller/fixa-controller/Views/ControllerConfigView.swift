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
	// $ list of devices
	// $ list of fixable configs
	var body: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Available controllers").font(.title)
			}
			Spacer()
		}.padding(16.0)
	}
}

struct ControllerConfigView_Previews: PreviewProvider {
	
	static var previews: some View {
		return ControllerConfigView()
			.frame(width: 400.0, height: 600)
	}
}
