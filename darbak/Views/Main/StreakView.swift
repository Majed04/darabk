//
//  StreakView.swift
//  darbak
//
//  Created by Ghina Alsubaie on 11/02/1447 AH.
//

import SwiftUI

struct StreakView: View {
    @State var stepsByDay: [Date: Int] = [
        //fake data
        // Today
        Calendar.current.startOfDay(for: Date()): 8500,
        // Yesterday
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!): 12000,
        // 2 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -2, to: Date())!): 11500,
        // 3 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -3, to: Date())!): 11000,
        // 4 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -4, to: Date())!): 15000,
        // 5 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -5, to: Date())!): 15000,
        // 6 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date())!): 13000,
        // 7 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -7, to: Date())!): 9500,
        // 8 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -8, to: Date())!): 0,
        // 9 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -9, to: Date())!): 8000,
        // 10 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -10, to: Date())!): 12500,
        // 11 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -11, to: Date())!): 16000,
        // 12 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -12, to: Date())!): 0,
        // 13 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -13, to: Date())!): 9000,
        // 14 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -14, to: Date())!): 11000,
        // 15 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -15, to: Date())!): 7000,
        // 16 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -16, to: Date())!): 13000,
        // 17 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -17, to: Date())!): 4000,
        // 18 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -18, to: Date())!): 0,
        // 19 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -19, to: Date())!): 8500,
        // 20 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -20, to: Date())!): 11500,
        // 21 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -21, to: Date())!): 6500,
        // 22 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -22, to: Date())!): 0,
        // 23 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -23, to: Date())!): 9500,
        // 24 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -24, to: Date())!): 12000,
        // 25 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -25, to: Date())!): 5500,
        // 26 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -26, to: Date())!): 0,
        // 27 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -27, to: Date())!): 8000,
        // 28 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -28, to: Date())!): 10500,
        // 29 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -29, to: Date())!): 7500,
        // 30 days ago
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -30, to: Date())!): 0
    ]
    @State var selectedDate: Date = Date().onlyDate
    @State var currentMonth: Date = Date()
    @State private var currentIndex = 0
    let emojis: [String] = ["🔥", "🏃‍♀️", "🚴‍♂️", "🚀", "💨", "🔥"]
    
    let dailyGoal = 10000
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!.onlyDate
    
    var body: some View {
        NavigationStack {
            ZStack {
                createEmojiBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    //title
                    VStack {
                        Text("تقدمك 🔥")
                            .font(.title)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("بدأت رحلتك في \(startDate, style: .date)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 25)
                    
                    // Calendar View
                    CalendarView(
                        currentMonth: $currentMonth,
                        selectedDate: $selectedDate,
                        stepsByDay: stepsByDay,
                        dailyGoal: dailyGoal
                    )
                    
                    // Selected Date Info
                    VStack(spacing: 10) {
                        Text(selectedDateString)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 15)
                    
                    // Circular Progress Bar
                    CircularProgressView(
                        progress: selectedDateProgressValue,
                        steps: selectedDateSteps,
                        dailyGoal: dailyGoal
                    )
                    .frame(width: 150, height: 150)
                    
                    // Progress Text Below Circle
                    Text(selectedDateProgress)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding()
        }
        .onChange(of: selectedDate) { _, _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % emojis.count
            }
        }
    }
    
    //background emoji animation
    private func createEmojiBackground() -> some View {
        GeometryReader { geometry in
            ForEach(0..<19, id: \.self) { index in
                let column = index % 3
                let row = index / 3
                let xOffset = CGFloat(column) * (geometry.size.width / 2.5) + 60
                let yOffset = CGFloat(row) * (geometry.size.height / 8) + 120
                
                Text(emojis[index % emojis.count])
                    .font(.system(size: 60))
                    .opacity(0.05)
                    .rotationEffect(.degrees(Double.random(in: -15...15)))
                    .position(
                        x: xOffset + CGFloat.random(in: -20...20),
                        y: yOffset + CGFloat.random(in: -15...15)
                    )
                    .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.01), value: currentIndex)
            }
        }
        .allowsHitTesting(false)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: selectedDate)
    }
    
    private var selectedDateSteps: Int {
        return stepsByDay[selectedDate.onlyDate] ?? 0
    }
    
    private var selectedDateProgressValue: Double {
        return min(Double(selectedDateSteps) / Double(dailyGoal), 1.0)
    }
    
    private var selectedDateProgress: String {
        let steps = selectedDateSteps
        let percentage = Int((Double(steps) / Double(dailyGoal)) * 100)
        
        if steps >= dailyGoal {
            return " تم تحقيق \(percentage)% من الهدف! 🎉"
        } else if steps > 0 {
            return " حققت (\(percentage)%) من الهدف "
        } else {
            return "لا توجد بيانات لهذا اليوم"
        }
    }
}

    

struct CalendarView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let stepsByDay: [Date: Int]
    let dailyGoal: Int
    
    private let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday = 1
        return calendar
    }()
    private let daysOfWeek = ["سبت", "جمعة", "خميس", "أربعاء", "ثلاثاء", "اثنين", "أحد"]
    
    var body: some View {
        VStack(spacing: 10) {
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            
            // Days of Week Header
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCircle(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            steps: stepsByDay[date.onlyDate] ?? 0,
                            dailyGoal: dailyGoal,
                            isInStreak: isInStreak(index: index),
                            showRightConnection: shouldShowRightConnection(index: index),
                            showBottomConnection: shouldShowBottomConnection(index: index)
                        )
                        .onTapGesture {
                            selectedDate = date.onlyDate
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.32)
            .environment(\.layoutDirection, .leftToRight)

        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first day of the month
        // Since we set firstWeekday = 1 (Sunday), we need to offset by firstWeekday - 1
        for _ in 0..<(firstWeekday - 1) {
            days.append(nil)
        }
        
        // Add all days in the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func isInStreak(index: Int) -> Bool {
        guard let currentDate = daysInMonth[index],
              let currentSteps = stepsByDay[currentDate.onlyDate],
              currentSteps >= dailyGoal else {
            return false
        }
        
        // Check if any adjacent day (left, right, above, below) achieved goal
        let adjacentIndices = [
            index - 1,  // left
            index + 1,  // right
            index - 7,  // above
            index + 7   // below
        ]
        
        for adjacentIndex in adjacentIndices {
            if adjacentIndex >= 0 && adjacentIndex < daysInMonth.count,
               let adjacentDate = daysInMonth[adjacentIndex],
               let adjacentSteps = stepsByDay[adjacentDate.onlyDate],
               adjacentSteps >= dailyGoal {
                return true
            }
        }
        
        return false
    }
    
    private func shouldShowRightConnection(index: Int) -> Bool {
        let currentCol = index % 7
        
        // Check if not the last column and next day exists and both achieved goal
        if currentCol < 6 && index + 1 < daysInMonth.count,
           let currentDate = daysInMonth[index],
           let nextDate = daysInMonth[index + 1],
           let currentSteps = stepsByDay[currentDate.onlyDate],
           let nextSteps = stepsByDay[nextDate.onlyDate],
           currentSteps >= dailyGoal && nextSteps >= dailyGoal {
            return true
        }
        return false
    }
    
    private func shouldShowBottomConnection(index: Int) -> Bool {
        // Check if next row exists and both achieved goal
        if index + 7 < daysInMonth.count,
           let currentDate = daysInMonth[index],
           let nextDate = daysInMonth[index + 7],
           let currentSteps = stepsByDay[currentDate.onlyDate],
           let nextSteps = stepsByDay[nextDate.onlyDate],
           currentSteps >= dailyGoal && nextSteps >= dailyGoal {
            return true
        }
        return false
    }
}

struct DayCircle: View {
    let date: Date
    let isSelected: Bool
    let steps: Int
    let dailyGoal: Int
    let isInStreak: Bool
    let showRightConnection: Bool
    let showBottomConnection: Bool
    
    private let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday = 1
        return calendar
    }()
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(backgroundColor)
                .frame(width: 40, height: 40)
            
            // Right connection
            if showRightConnection {
                Rectangle()
                    .fill(Color(hex: "#1B5299"))
                    .frame(width: 50, height: 40)
                    .offset(x: 29, y: 0)
            }
            
            // Bottom connection
            if showBottomConnection {
                Rectangle()
                    .fill(Color(hex: "#1B5299"))
                    .frame(width: 50, height: 40)
                    .offset(x: 0, y: 20)
            }
            
            // Day number
            Text(String(calendar.component(.day, from: date)))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
                
            
            // Data indicator dot
            if steps > 0 {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 5, height: 5)
                    .offset(x: 0, y: 12)
            }
        }
        .overlay(
            Circle()
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }
    
    private var backgroundColor: Color {
        if isToday && isInStreak {
            return Color(hex: "#1B5299")
        } else if isInStreak {
            return Color(hex: "#1B5299")
        }
        else if isToday {
            return Color(hex: "#1B5299").opacity(0.3)
        } else {
            return .clear
        }
    }
    
    private var textColor: Color {
        if isToday && isInStreak {
            return .white
        } else if isInStreak {
            return .white
        }
        else if isToday {
           return .black
        } else {
            return .primary
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        if isToday {
            return 3
        } else if isSelected {
            return 2
        } else {
            return 0
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let steps: Int
    let dailyGoal: Int
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: animatedProgress)
            
            // Center content
            VStack(spacing: 4) {
                Text(String(steps))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("خطوة")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            animatedProgress = newValue
        }
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        }  else {
            return .blue
        }
    }
}

extension Date {
    var onlyDate: Date {
        Calendar.current.startOfDay(for: self)
    }
}



#Preview {
    StreakView()
}
    


