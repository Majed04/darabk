//
//  Profileview2.swift
//  darbak
//
//  Created by Raghad Alqut on 16/02/1447 AH.
//

import SwiftUI

struct PersonalProfileView: View {
    @EnvironmentObject var user: User
    @State private var isEditingName = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            
            // Top Bar - Title Left
            HStack {
                Text("حسابك الشخصي")
                    .font(.system(size: 22, weight: .bold))
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

           
            //name
            VStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray.opacity(0.4))
                
                HStack(spacing: 8) {
                    TextField("", text: $user.name)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .disabled(!isEditingName)
                    
                    Button(action: {
                        withAnimation {
                            isEditingName.toggle()
                        }
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(isEditingName ? .blue : .gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Input Fields
            VStack(alignment: .leading, spacing: 16) {
                CustomTextField(label: "هدفك:", value: $user.goalSteps)
                CustomTextField(label: "عمرك:", value: $user.age)
                CustomTextField(label: "وزنك:", value: $user.weight)
                CustomTextField(label: "طولك:", value: $user.height)
                CustomTextField(label:  "ساعات نومك:", value: $user.sleepingHours)
              
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            Spacer()
            
            VStack {
                Spacer()
                CustomButton(title: "العودة للرئيسية") {
                    print("Button tapped!")
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}

struct CustomTextField: View {
    var label: String
    @Binding var value: Int
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.black)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                
                HStack {
                    TextField("", value: $value, formatter: NumberFormatter())
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity)
                        .disabled(!isEditing)
                    
                    Button(action: {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(isEditing ? .blue : .gray)
                    }
                }
                .padding(.horizontal)
                .frame(height: 50)
            }
        }
    }
}



#Preview {
    PersonalProfileView().environmentObject(User())
}

