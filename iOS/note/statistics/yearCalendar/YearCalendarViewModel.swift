//
//  YearCalendarViewModel.swift
//  note
//
//  Created by 倪申雷 on 2025/6/25.
//

import Foundation
import SwiftData

struct DayInfo: Hashable {
    let day: Date?
    let articleCount: Int
    
    var isHaveData: Bool {
        articleCount > 0
    }
    var isNotMock: Bool {
        day != nil
    }
}

struct MonthInfo: Hashable {

    let title: String
    let startOfMonth: Date
    let days: [DayInfo]

}

class YearCalendarViewModel: ObservableObject {
    
    @Published var currentYear: Date
    @Published var months: [MonthInfo] = []
    
    let articleService: ArticleService = ArticleService()
    
    init(currentYear: Date) {
        self.currentYear = currentYear
    }
    
    func addYear(value: Int) {
        currentYear = currentYear.addYear(value)
    }
    
    func fetchDatas(modelContext: ModelContext) {
        createMonths(currentYear: currentYear, modelContext: modelContext)
    }
    
    private func createMonths(currentYear: Date, modelContext: ModelContext) {
        var months = [MonthInfo]()
        let startOfYear = currentYear.startOfYear
        let monthsTitle: [String] = Calendar.gregorian.standaloneMonthSymbols
        for i in 0...11 {
            let month = startOfYear.addMonth(i)
            let days = getDaysInMonth(month: month, modelContext: modelContext)
            let title = monthsTitle[i]
            let monthInfo = MonthInfo(title: title, startOfMonth: month, days: days)
            months.append(monthInfo)
        }
        self.months = months
    }
    
    // 获取当月日期数据（固定42个日期）
    private func getDaysInMonth(month: Date, modelContext: ModelContext) -> [DayInfo] {
        var days = [DayInfo]()
        
        // 填充开头空白（上个月日期）
        let prevMonthDays = Array(0..<month.currentMonthStartPadding).map { _ in
            DayInfo(day: nil, articleCount: 0)
        }
        
        days += prevMonthDays
        
        // 添加当月日期
        let curMonthDays = month.currentMonthDays.map { day in
            let count = articleService.articleCount(
                modelContext: modelContext,
                startDate: day.startOfDay,
                endDate: day.endOfDay
            )
            return DayInfo(day: day, articleCount: count)
        }
        
        days += curMonthDays
        
        // 填充结尾空白（下个月日期）
        let remaining = 42 - days.count
        if remaining > 0 {
            for _ in 1...remaining {
                days.append(DayInfo(day: nil, articleCount: 0))
            }
        }
        
        return days
    }
    
}
