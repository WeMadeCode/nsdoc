//
//  ArticleStatisticsRepo.swift
//  note
//
//  Created by 倪申雷 on 2025/6/24.
//

import Foundation
import SwiftData

// 文章统计服务
class ArticleService {
    
    /// 获取指定日期范围的文章数量
    func articleCount(modelContext: ModelContext, startDate: Date, endDate: Date) -> Int {
        // 1. 创建查询谓词
        let predicate = #Predicate<Article> { article in
            article.createDate >= startDate && article.createDate < endDate
        }
        
        // 2. 创建查询描述符
        let descriptor = FetchDescriptor<Article>(predicate: predicate)
        
        // 3. 获取文章数量
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            return 0
        }
    }
    
    /// 获取指定日期范围的文章
    func articles(modelContext: ModelContext, startDate: Date, endDate: Date, sortOrder: SortOrder = .forward) -> [Article] {
        // 1. 创建查询谓词（日期范围）
        let predicate = #Predicate<Article> { article in
            article.createDate >= startDate && article.createDate < endDate
        }
        // 2. 创建排序描述符（按 createDate 升序）
        let sortDescriptor = SortDescriptor<Article>(\.createDate, order: sortOrder)
        // 3. 创建查询描述符
        let descriptor = FetchDescriptor<Article>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )
        // 4. 获取结果
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
    
}
