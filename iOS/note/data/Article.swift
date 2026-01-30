//
//  Article.swift
//  note
//
//  Created by 倪申雷 on 2025/6/20.
//

import Foundation
import SwiftData

@Model
final class Article {
    
    var title: String
    var markdownText: String
    var createDate: Date
    var updateDate: Date
    
    init(title: String = "", markdownText: String = "", createDate: Date = Date(), updateDate: Date = Date()) {
        self.title = title
        self.markdownText = markdownText
        self.createDate = createDate
        self.updateDate = updateDate
    }
    
}
