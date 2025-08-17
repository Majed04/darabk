//
// QuizView.swift
// darbak
//
// Created by Majed on 10/02/1447 AH.
//

import Lottie
import SwiftUI

struct QuizView: View {
    @State private var progress: Float = 0.0
    @State private var quizNumber: Int = 0
    @State private var navigateToHome: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @EnvironmentObject var user: User

    private let totalQuestions = 9

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with progress
                    VStack(spacing: 20) {
                        // Progress section
                        VStack(spacing: 12) {
                            HStack {
                                Text("خلنا نعرفك")
                                    .font(DesignSystem.Typography.largeTitle)
                                    .primaryText()
                                Spacer()
                                Text("\(quizNumber + 1)/\(totalQuestions)")
                                    .font(DesignSystem.Typography.headline)
                                    .secondaryText()
                            }
                            ProgressView(value: progress)
                                .progressViewStyle(
                                    LinearProgressViewStyle(
                                        tint: DesignSystem.Colors.primary
                                    )
                                )
                                .scaleEffect(x: 1, y: 2)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }

                    // Question content
                    VStack(spacing: 30) {
                        currentQuestionView()
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                        Spacer(minLength: 40)
                    }
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationDestination(isPresented: $navigateToHome) {
                MainTabView().navigationBarBackButtonHidden(true)
            }
            .onAppear {
                updateProgress()
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func updateProgress() {
        if totalQuestions > 1 {
            progress = Float(quizNumber) / Float(totalQuestions - 1)
        } else {
            progress = 1.0
        }
    }

    // MARK: - Input Validation Logic

    private func isInputValid() -> Bool {
        switch quizNumber {
        case 0: return user.name.count >= 3
        case 1: return user.gender == .male || user.gender == .female
        case 2: return user.age >= 15 && user.age <= 120
        case 3: return true // Weight
        case 4: return true // Height
        case 5: return true // Sleeping Hours
        case 6: return true // Step Goal choice
        case 7: return user.goalSteps > 1000
        case 8: return true // Final View
        default: return false
        }
    }

    @ViewBuilder private func currentQuestionView() -> some View {
        switch quizNumber {
        case 0:
            QuestionOne_Name(
                isInputValid: isInputValid(),
                onNext: nextQuestion,
                onPrevious: previousQuestion
            )
        case 1:
            QuestionTwo_Gender(
                isInputValid: isInputValid(),
                onNext: nextQuestion,
                onPrevious: previousQuestion
            )
        case 2:
            QuestionThree_Age(
                isInputValid: isInputValid(),
                onNext: nextQuestion,
                onPrevious: previousQuestion
            )
        case 3:
            QuestionFour_Weight(
                isInputValid: isInputValid(),
                onNext: nextQuestion,
                onPrevious: previousQuestion
            )
        case 4:
            QuestionFive_Height(
                isInputValid: isInputValid(),
                onNext: nextQuestion,
                onPrevious: previousQuestion
            )
        case 5:
            QuestionSix_SleepingHours(
                isInputValid: isInputValid(),
                onNext: nextQuestion,
                onPrevious: previousQuestion
            )
        case 6:
            QuestionSeven_StepGoal(
                onSelectGoal: { hasGoal in
                    if hasGoal {
                        quizNumber = 7
                    } else {
                        calculateGoalSteps(user: user)
                        quizNumber = 8
                    }
                    updateProgress()
                },
                onPrevious: previousQuestion
            )
        case 7:
            QuestionEight_SetGoal(
                isInputValid: isInputValid(),
                onNext: nextQuestion,
                onPrevious: previousQuestion
            )
        case 8:
            FinalView(
                onNext: nextQuestion,
                onPrevious: previousQuestion
            )
        default:
            Text("Something went wrong or quiz completed.")
        }
    }

    private func nextQuestion() {
        if quizNumber == totalQuestions - 1 {
            navigateToHome = true
            hasCompletedOnboarding = true
            user.saveToDefaults()
        } else {
            quizNumber += 1
            updateProgress()
        }
    }

    private func previousQuestion() {
        if quizNumber > 0 {
            quizNumber -= 1
            updateProgress()
        }
    }
}

// MARK: - Navigation Buttons View

struct QuizNavigationButtons: View {
    let isInputValid: Bool
    let showPrevious: Bool
    let isFinalQuestion: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            Button(action: onNext) {
                HStack {
                    Text(isFinalQuestion ? "خلصنا 🎉" : "التالي")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.invertedText)
                    if !isFinalQuestion {
                        Image(systemName: "arrow.left")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.invertedText)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.lg)
                .background(isInputValid ? DesignSystem.Colors.primary : DesignSystem.Colors.border)
                .cornerRadius(DesignSystem.CornerRadius.large)
            }
            .disabled(!isInputValid)
            .animation(.easeInOut(duration: 0.2), value: isInputValid)

            if showPrevious {
                Button(action: onPrevious) {
                    HStack {
                        Image(systemName: "arrow.right")
                            .font(DesignSystem.Typography.subheadline)
                        Text("السابق")
                            .font(DesignSystem.Typography.headline)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.lg)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1.5)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
}

// MARK: - User name Question

struct QuestionOne_Name: View {
    @EnvironmentObject var user: User
    @FocusState private var isNameFieldFocused: Bool
    let isInputValid: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 12) {
                Text("اسمك الكريم")
                    .font(DesignSystem.Typography.title)
                    .primaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("اكتب اسمك لنتمكن من مناداتك به")
                    .font(DesignSystem.Typography.subheadline)
                    .secondaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: 12) {
                TextField("مثال: أحمد محمد", text: $user.name)
                    .font(DesignSystem.Typography.body)
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(
                                user.name.count >= 3 ? DesignSystem.Colors.primary
                                    .opacity(0.4) : DesignSystem.Colors.border
                                    .opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
                    .focused($isNameFieldFocused)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isNameFieldFocused = true
                        }
                    }

                if !user.name.isEmpty && user.name.count < 3 {
                    Text("الاسم يجب أن يكون 3 أحرف على الأقل")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            QuizNavigationButtons(
                isInputValid: isInputValid,
                showPrevious: false,
                isFinalQuestion: false,
                onNext: onNext,
                onPrevious: onPrevious
            )
        }
        .padding()
        .cardStyle()
    }
}

struct QuestionTwo_Gender: View {
    @EnvironmentObject var user: User
    let isInputValid: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 12) {
                Text("جنسك")
                    .font(DesignSystem.Typography.title)
                    .primaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("هذا يساعدنا في حساب الأهداف المناسبة لك")
                    .font(DesignSystem.Typography.subheadline)
                    .secondaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Picker("اختر جنسك", selection: $user.gender) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender == .male ? "ذكر" : "أنثى")
                        .font(DesignSystem.Typography.body)
                        .tag(gender)
                }
            }
            .pickerStyle(.segmented)
            .background(DesignSystem.Colors.primaryLight.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.medium)

            QuizNavigationButtons(
                isInputValid: isInputValid,
                showPrevious: true,
                isFinalQuestion: false,
                onNext: onNext,
                onPrevious: onPrevious
            )
        }
        .padding()
        .cardStyle()
    }
}

struct QuestionThree_Age: View {
    @EnvironmentObject var user: User
    @FocusState private var isAgeFieldFocused: Bool
    let isInputValid: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 12) {
                Text("كم عمرك؟")
                    .font(DesignSystem.Typography.title)
                    .primaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("العمر يساعد في تحديد النشاط المناسب")
                    .font(DesignSystem.Typography.subheadline)
                    .secondaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: 12) {
                TextField("مثال: 25", value: $user.age, formatter: NumberFormatter())
                    .font(DesignSystem.Typography.body)
                    .keyboardType(.numberPad)
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(
                                (user.age >= 15 && user.age <= 120) ? DesignSystem.Colors.primary
                                    .opacity(0.4) : DesignSystem.Colors.border
                                    .opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
                    .focused($isAgeFieldFocused)
                    .onAppear {
                        user.age = 0 // Set age to 0 initially to make the field empty
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isAgeFieldFocused = true
                        }
                    }

                if user.age != 0 && (user.age < 15 || user.age > 120) {
                    Text("يرجى إدخال عمر صحيح بين 15 و 120")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            QuizNavigationButtons(
                isInputValid: isInputValid,
                showPrevious: true,
                isFinalQuestion: false,
                onNext: onNext,
                onPrevious: onPrevious
            )
        }
        .padding()
        .cardStyle()
    }
}

struct QuestionFour_Weight: View {
    @EnvironmentObject var user: User
    let isInputValid: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 12) {
                Text("كم وزنك؟")
                    .font(DesignSystem.Typography.title)
                    .primaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("نحتاج هذه المعلومة لح حساب السعرات المحروقة")
                    .font(DesignSystem.Typography.subheadline)
                    .secondaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: 15) {
                HStack {
                    Text("الوزن")
                        .font(DesignSystem.Typography.headline)
                        .primaryText()
                    Spacer()
                    Text("\(user.weight) كجم")
                        .font(DesignSystem.Typography.title2)
                        .accentText()
                }
                Picker("وزنك", selection: $user.weight) {
                    ForEach(20 ... 200, id: \.self) { weight in
                        Text("\(weight) كجم")
                            .font(DesignSystem.Typography.body)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
            }
            QuizNavigationButtons(
                isInputValid: isInputValid,
                showPrevious: true,
                isFinalQuestion: false,
                onNext: onNext,
                onPrevious: onPrevious
            )
        }
        .padding()
        .cardStyle()
    }
}

struct QuestionFive_Height: View {
    @EnvironmentObject var user: User
    let isInputValid: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 12) {
                Text("كم طولك؟")
                    .font(DesignSystem.Typography.title)
                    .primaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("هذا يساعدنا في حساب مؤشر كتلة الجسم")
                    .font(DesignSystem.Typography.subheadline)
                    .secondaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: 15) {
                HStack {
                    Text("الطول")
                        .font(DesignSystem.Typography.headline)
                        .primaryText()
                    Spacer()
                    Text("\(user.height) سم")
                        .font(DesignSystem.Typography.title2)
                        .accentText()
                }
                Picker("طولك", selection: $user.height) {
                    ForEach(140 ... 240, id: \.self) { height in
                        Text("\(height) سم")
                            .font(DesignSystem.Typography.body)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
            }
            QuizNavigationButtons(
                isInputValid: isInputValid,
                showPrevious: true,
                isFinalQuestion: false,
                onNext: onNext,
                onPrevious: onPrevious
            )
        }
        .padding()
        .cardStyle()
    }
}

struct QuestionSix_SleepingHours: View {
    @EnvironmentObject var user: User
    let isInputValid: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 12) {
                Text("كم ساعة تنام يومياً؟")
                    .font(DesignSystem.Typography.title)
                    .primaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("النوم الكافي مهم للصحة والنشاط")
                    .font(DesignSystem.Typography.subheadline)
                    .secondaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: 20) {
                HStack {
                    Text("ساعات النوم")
                        .font(DesignSystem.Typography.headline)
                        .primaryText()
                    Spacer()
                    Text("\(user.sleepingHours) ساعة")
                        .font(DesignSystem.Typography.title2)
                        .accentText()
                }
                HStack(spacing: 20) {
                    Button(action: {
                        if user.sleepingHours > 4 {
                            user.sleepingHours -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(DesignSystem.Typography.title)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    Spacer()
                    Text("\(user.sleepingHours)")
                        .font(DesignSystem.Typography.largeTitle)
                        .primaryText()
                        .frame(minWidth: 60)
                    Spacer()
                    Button(action: {
                        if user.sleepingHours < 12 {
                            user.sleepingHours += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(DesignSystem.Typography.title)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
            }
            QuizNavigationButtons(
                isInputValid: isInputValid,
                showPrevious: true,
                isFinalQuestion: false,
                onNext: onNext,
                onPrevious: onPrevious
            )
        }
        .padding()
        .cardStyle()
    }
}

struct QuestionSeven_StepGoal: View {
    @EnvironmentObject var user: User
    let onSelectGoal: (_ hasGoal: Bool) -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 12) {
                Text("هدف الخطوات")
                    .font(DesignSystem.Typography.title)
                    .primaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("هل عندك هدف محدد أم تريدنا نحسب لك هدف يناسبك؟")
                    .font(DesignSystem.Typography.subheadline)
                    .secondaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: 15) {
                Button(action: { onSelectGoal(true) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("عندي هدف محدد")
                                .font(DesignSystem.Typography.headline)
                                .primaryText()
                            Text("سأدخل هدفي بنفسي")
                                .font(DesignSystem.Typography.caption)
                                .secondaryText()
                        }
                        Spacer()
                        Image(systemName: "target")
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(DesignSystem.Colors.primary.opacity(0.4), lineWidth: 1.5)
                    )
                }
                Button(action: { onSelectGoal(false) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("احسب لي هدف مناسب")
                                .font(DesignSystem.Typography.headline)
                                .primaryText()
                            Text("بناءً على معلوماتي الشخصية")
                                .font(DesignSystem.Typography.caption)
                                .secondaryText()
                        }
                        Spacer()
                        Image(systemName: "brain.head.profile")
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(DesignSystem.Colors.success.opacity(0.4), lineWidth: 1.5)
                    )
                }
            }
            QuizNavigationButtons(
                isInputValid: true, // Always valid to choose an option
                showPrevious: true,
                isFinalQuestion: false,
                onNext: {}, // No direct next, handled by onSelectGoal
                onPrevious: onPrevious
            )
        }
        .padding()
        .cardStyle()
    }
}

struct QuestionEight_SetGoal: View {
    @EnvironmentObject var user: User
    @FocusState private var isGoalFieldFocused: Bool
    let isInputValid: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 12) {
                Text("كم هدفك؟")
                    .font(DesignSystem.Typography.title)
                    .primaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("ادخل عدد الخطوات التي تريد تحقيقها يومياً")
                    .font(DesignSystem.Typography.subheadline)
                    .secondaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: 12) {
                TextField("مثال: 10000", value: $user.goalSteps, formatter: NumberFormatter())
                    .font(DesignSystem.Typography.body)
                    .keyboardType(.numberPad)
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(
                                user.goalSteps > 1000 ? DesignSystem.Colors.primary
                                    .opacity(0.4) : DesignSystem.Colors.border
                                    .opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
                    .focused($isGoalFieldFocused)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isGoalFieldFocused = true
                        }
                    }

                HStack {
                    Text("خطوة يومياً")
                        .font(DesignSystem.Typography.subheadline)
                        .secondaryText()
                    Spacer()
                }
                if user.goalSteps > 0 && user.goalSteps <= 1000 {
                    Text("الهدف يجب أن يكون أكثر من 1000 خطوة")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            QuizNavigationButtons(
                isInputValid: isInputValid,
                showPrevious: true,
                isFinalQuestion: false,
                onNext: onNext,
                onPrevious: onPrevious
            )
        }
        .padding()
        .cardStyle()
    }
}

struct FinalView: View {
    @EnvironmentObject var user: User
    @State private var animatedGoalSteps: Int = 0
    let onNext: () -> Void
    let onPrevious: () -> Void // Not strictly needed for final, but for consistency

    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Text("مبروك! 🎉")
                    .font(DesignSystem.Typography.largeTitle)
                    .primaryText()
                Text("تم إعداد ملفك الشخصي بنجاح")
                    .font(DesignSystem.Typography.title2)
                    .secondaryText()
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primaryLight.opacity(0.2))
                        .frame(width: 200, height: 200)
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .frame(width: 160, height: 160)
                    VStack(spacing: 8) {
                        Image("StarHoldingSign")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                        Text(animatedGoalSteps.englishFormatted)
                            .font(DesignSystem.Typography.largeTitle)
                            .primaryText()
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 1.0), value: animatedGoalSteps)
                        Text("خطوة يومياً")
                            .font(DesignSystem.Typography.subheadline)
                            .secondaryText()
                    }
                }
                Text("هذا هو هدفك اليومي، يمكنك تغييره لاحقاً من الإعدادات")
                    .font(DesignSystem.Typography.body)
                    .secondaryText()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        animatedGoalSteps = user.goalSteps
                    }
                }
            }
            QuizNavigationButtons(
                isInputValid: true,
                showPrevious: false,
                isFinalQuestion: true,
                onNext: onNext,
                onPrevious: onPrevious
            )
        }
        .cardStyle()
        .padding(.horizontal, 20)
    }
}

#Preview {
    QuizView().environmentObject(User())
}
