//
//  QuizView.swift
//  darbak
//
//  Created by Majed on 10/02/1447 AH.
//
import SwiftUI
import Lottie


struct QuizView: View {
    @State private var progress: Float = 0.0
    @State private var quizNumber: Int = 0
    @State private var isInputValid: Bool = false
    @State private var navigateToHome: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @EnvironmentObject var user: User

    private let totalQuestions = 9

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .animation(.linear(duration: 0.3), value: progress)
                    .padding(.bottom, 10)

                currentQuestionView()
                
                Spacer()

                HStack(alignment: .center) {

                    if quizNumber != 6 {
                        let title = quizNumber == totalQuestions - 1 ? "خلصنا" : " الي بعده"
                        CustomButton(title: title) {
                            if quizNumber == totalQuestions - 1 {
                                navigateToHome = true
                                hasCompletedOnboarding = true
                            } else {
                                quizNumber += 1
                                updateProgress()
                            }
                        }
                        .disabled(!isInputValid)
                        .frame(maxWidth: .infinity)
                    }
                
                }
            }
            .padding()
            .navigationTitle("خلنا نعرفك")
            .navigationDestination(isPresented: $navigateToHome){
                Home().navigationBarBackButtonHidden(true)
            }
            .toolbar{
                if quizNumber > 0 {
                    Button {
                        if quizNumber > 0 {
                            quizNumber -= 1
                            updateProgress()
                        }
                    } label: {
                        Image(systemName: "arrow.left")
                            .foregroundStyle(.black)
                    }
                }
            }
            .onAppear {
                updateProgress()
                isInputValid = checkValidity()
            }
            .onChange(of: quizNumber) {

                isInputValid = checkValidity()
            }
        }
    }

    private func updateProgress() {
        if totalQuestions > 1 {
            progress = Float(quizNumber) / Float(totalQuestions - 1)
        } else {
            progress = 1.0
        }
    }
    
    // MARK: - Input Validation Logic
    private func checkValidity() -> Bool {
        switch quizNumber {
        case 0:
            return user.name.count >= 3
        case 1:
            return true
        case 2:
            return user.age > 0 && user.age < 120
        case 3:
            return true
        case 4:
            return true
        case 5:
            return true
        case 6:
            return true
        case 7:
            return user.goalSteps > 1000
        case 8:
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private func currentQuestionView() -> some View {
        switch quizNumber {
        case 0:
            // Add .onChange to trigger validation whenever the name text changes
            QuestionOne_Name()
                .onChange(of: user.name) {
                    isInputValid = checkValidity()
                }
        case 1:
            QuestionTwo_Gender()
        case 2:
            // Add .onChange to trigger validation whenever the age text changes
            QuestionThree_Age()
                .onChange(of: user.age) {
                    isInputValid = checkValidity()
                }
        case 3:
            QuestionFour_Weight()
        case 4:
            QuestionFive_Height()
        case 5:
            QuestionSix_SleepingHours()
        case 6:
            QuestionSeven_StepGoal { hasGoal in
                quizNumber += hasGoal ? 1 : 2
                updateProgress()
            }
        case 7:
            // Add .onChange to trigger validation whenever the goal steps text changes
            QuestionEight_SetGoal()
                .onChange(of: user.goalSteps) {
                    isInputValid = checkValidity()
                }
        case 8:
            FinalView()
        default:
            Text("Something went wrong or quiz completed.")
        }
    }
}

// MARK: - Individual Question Views
struct QuestionOne_Name: View {
    @EnvironmentObject var user: User
    var body: some View {
        VStack(alignment: .leading) {
            Text("اسمك الكريم").font(.title2).bold()
            TextField("أدخل اسمك", text: $user.name)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct QuestionTwo_Gender: View {
    @EnvironmentObject var user: User
    var body: some View {
        VStack(alignment: .leading) {
            Text("جنسك").font(.title2).bold()
            Picker("اختر جنسك", selection: $user.gender) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender == .male ? "ذكر" : "أنثى").tag(gender)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, 5)
        }
    }
}

struct QuestionThree_Age: View {
    @EnvironmentObject var user: User
    var body: some View {
        VStack(alignment: .leading) {
            Text("كم عمرك؟").font(.title2).bold()
            TextField("أدخل عمرك", value: $user.age, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct QuestionFour_Weight: View {
    @EnvironmentObject var user: User
    var body: some View {
        VStack(alignment: .leading) {
            Text("كم وزنك؟").font(.title2).bold()
            Picker("وزنك", selection: $user.weight){
                ForEach(20...200, id: \.self) { weight in
                    Text("\(weight) كجم")
                }
            }.pickerStyle(.wheel)
        }
    }
}

struct QuestionFive_Height: View {
    @EnvironmentObject var user: User
    var body: some View {
        VStack(alignment: .leading) {
            Text("كم طولك؟").font(.title2).bold()
            // Corrected binding to user.height
            Picker("طولك", selection: $user.height){
                ForEach(140...240, id: \.self) { height in
                    Text("\(height) سم")
                }
            }.pickerStyle(.wheel)
        }
    }
}

struct QuestionSix_SleepingHours: View {
    @EnvironmentObject var user: User
    var body: some View {
        VStack(alignment: .leading) {
            Text("كم ساعة تنام يومياً؟").font(.title2).bold()
            Stepper(value: $user.sleepingHours, in: 4...12) {
                Text("\(user.sleepingHours) ساعة")
            }
        }
    }
}

struct QuestionSeven_StepGoal: View {
    @EnvironmentObject var user: User
    let action: (_ hasGoal: Bool) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("هل عندك هدف  ولا تبي نحسب لك هدف يناسبك؟").font(.title2).bold()
            Button(action: {
                action(true)
            }){
                HStack {
                        Text("عندي")
                            .foregroundColor(.black)
                        Spacer()
                    }
            }.frame(
                maxWidth: .infinity
            )
            .padding()
            .overlay(
                RoundedRectangle(
                    cornerRadius: 10
                )
                .stroke(
                    Color(hex: "#1B5299"),
                    lineWidth: 4
                )
            )
            .cornerRadius(
                10
            )
    
            Button(action: {
                action(false)
                calculateGoalSteps(user: user)
            }){
                HStack {
                        Text("لا احسبولي")
                            .foregroundColor(.black)
                        Spacer()
                    }
            }.frame(
                maxWidth: .infinity
            )
            .padding()
            .overlay(
                RoundedRectangle(
                    cornerRadius: 10
                )
                .stroke(
                    Color(hex: "#1B5299"),
                    lineWidth: 4
                )
            )
            .cornerRadius(
                10
            )
        
        }
    }
}

struct QuestionEight_SetGoal: View {
    @EnvironmentObject var user: User
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("كم هدفك؟").font(.title2).bold()
            TextField("10,000 (Step)", value: $user.goalSteps, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct FinalView: View {
    @EnvironmentObject var user: User
    @State private var animatedGoalSteps: Int = 0
    var body: some View {
        VStack{
            ZStack{
                Image("StarHoldingSign")
                Text("\(animatedGoalSteps)")
                    .font(.title)
                    .bold()
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            animatedGoalSteps = user.goalSteps
                        }
                    }.padding(.top, 40)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#Preview {
    QuizView().environmentObject(User())
}
