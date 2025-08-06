//
//  QuizView.swift
//  darbak
//
//  Created by Majed on 10/02/1447 AH.
//
import SwiftUI

struct QuizView: View {
    @State private var progress: Float = 0
    @State private var quizNumber: Int = 0

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
                    
                    if quizNumber < totalQuestions - 1 {
                        if quizNumber != 6 {
                            CustomButton(title: "الي بعده") {
                                quizNumber += 1
                                updateProgress()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("خلنا نعرفك")
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
            }
        }
    }

    private func updateProgress() {
        progress = Float(quizNumber) / Float(totalQuestions - 1)
        if totalQuestions == 1 { progress = 1.0 }
        if quizNumber == 0 && totalQuestions > 1 {
            progress = 0.0
        } else if totalQuestions > 1 {
            progress = Float(quizNumber) / Float(totalQuestions - 1)
        } else {
            progress = 1.0
        }
    }

    @ViewBuilder
    private func currentQuestionView() -> some View {
        switch quizNumber {
        case 0:
            QuestionOne_Name()
        case 1:
            QuestionTwo_Gender()
        case 2:
            QuestionThree_Age()
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
            QuestionEight_SetGoal()
        case 8:
            Final_Screen()
        default:
            Text("Something went wrong or quiz completed.")
        }
    }
}

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
            Picker("طولك", selection: $user.weight){
                ForEach(140...240, id: \.self) { weight in
                    Text("\(weight) سم")
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

struct Final_Screen: View {
    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    QuizView().environmentObject(User())
}
