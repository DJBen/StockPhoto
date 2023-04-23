//
//  SwiftUIView.swift
//  
//
//  Created by Sihao Lu on 4/23/23.
//

import SwiftUI

struct GoogleSignInButton: View {
    let disabled: Bool = false
    let signIn: () -> Void

    var body: some View {
        Button(action: signIn) {
            HStack {
                Image(uiImage: UIImage(named: "google", in: .module, with: nil)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .padding(18)
                    .background(Color.white.opacity(disabled ? 0.5 : 1))
                    .frame(width: 60, height: 60)
                Spacer()
                Text("Sign in with Google")
                    .foregroundColor(.white)
                    .font(.title3)
                    .bold()
                Spacer()
            }
            .background(Color(red: 66 / 255, green: 133 / 255, blue: 244 / 255))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(
                    cornerRadius: 4
                )
                .stroke(Color(red: 66 / 255, green: 133 / 255, blue: 244 / 255), lineWidth: 2)
            )
            .disabled(disabled)
        }
    }
}

struct GoogleSignInButton_Previews: PreviewProvider {
    static var previews: some View {
        GoogleSignInButton {}
    }
}
