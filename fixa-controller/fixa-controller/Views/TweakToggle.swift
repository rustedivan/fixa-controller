//
//  TweakToggle.swift
//  fixa-controller
//
//  Created by Ivan Milles on 2020-10-18.
//  Copyright © 2020 Ivan Milles. All rights reserved.
//

import SwiftUI

struct FixableToggle: View {
	@Binding var value: Bool
	let label: String
	
	var body: some View {
		HStack{
			Text(label)
			Toggle(isOn: $value) { Text("") }
			Spacer()
		}
	}
}
