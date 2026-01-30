//
//  MonthCalendarViewModel.swift
//  note
//
//  Created by 倪申雷 on 2025/6/24.
//

import Foundation
import SwiftData

class MonthCalendarViewModel: ObservableObject {
    
    struct Items: Hashable {
        var date: Date
        var articleCount: Int
    }
    
    @Published var currentDate: Date
    
    @Published var paddingItems: [Int] = []
    @Published var monthItems: [Items] = []
    
    @Published var selectedDate: Date
    @Published var selectedDateArticles: [Article] = []
    
    let articleService: ArticleService = ArticleService()
    
    init(currentDate: Date, selectedDate: Date) {
        self.currentDate = currentDate
        self.selectedDate = selectedDate
    }
    
    func fetchDatas(modelContext: ModelContext) {
        // 1. 生成月前的空白
        paddingItems = Array(0..<currentDate.currentMonthStartPadding)
        // 2. 生成一个月的完整数据
        let months = currentDate.currentMonthDays
        monthItems = months.map { date in
            let count = articleService.articleCount(
                modelContext: modelContext,
                startDate: date.startOfDay,
                endDate: date.endOfDay
            )
            return Items(date: date, articleCount: count)
        }
        // 3. 更新选中的文章
        updateSelectedDateArticles(modelContext: modelContext)
    }
    
    func updateSelectedDateArticles(modelContext: ModelContext) {
        selectedDateArticles = articleService.articles(
            modelContext: modelContext,
            startDate: selectedDate.startOfDay,
            endDate: selectedDate.endOfDay,
            sortOrder: .reverse
        )
    }
    
}
