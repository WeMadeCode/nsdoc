//
//  ToolItem.swift
//  note
//
//  Created by 倪申雷 on 2025/7/12.
//

import SwiftUI

enum ToolType {
    
    case insert
    case text
    case style
    case h1
    case h2
    case h3
    case h4
    case h5
    case order
    case unOrder
    case check
    case code
    case foldList
    case page
    
    case left
    case right
    case center
    case goLeft
    case goRight
    
    case bold
    case italic
    case strikethrough
    case line
    case reference
    case colors
    case camera
    case picture
    case mention
    
    var image: Image {
        switch self {
        case .insert:
            Image(systemName: "plus.circle")
        case .h1:
            Image(.fontH1)
        case .h2:
            Image(.fontH2)
        case .h3:
            Image(.fontH3)
        case .h4:
            Image(.fontH4)
        case .h5:
            Image(.fontH5)
        case .text:
            Image(.fontT)
        case .style:
            Image(systemName: "textformat")
        case .order:
            Image(.fontOrder)
        case .unOrder:
            Image(.fontUnOrder)
        case .check:
            Image(.fontCheck)
        case .code:
            Image(.fontCode)
        case .foldList:
            Image(systemName: "list.triangle")
        case .page:
            Image(systemName: "doc.text")
        case .left:
            Image(.alignLeft)
        case .right:
            Image(.alignRight)
        case .center:
            Image(.alignCenter)
        case .goLeft:
            Image(.alignGoLeft)
        case .goRight:
            Image(.alignGoRight)
        case .camera:
            Image(.otherCamera)
        case .picture:
            Image(.otherPicture)
        case .line:
            Image(.otherLine)
        case .reference:
            Image(.otherReference)
        case .colors:
            Image(.otherColors)
        case .bold:
            Image(.otherB)
        case .italic:
            Image(.otherI)
        case .strikethrough:
            Image(.otherS)
        case .mention:
            Image(systemName: "at")
        }
    }
    
    var jsMethodName: String {
        switch self {
        case .h1, .h2, .h3, .h4, .h5:
            "toggleHeading"
        case .text:
            "setParagraph"
        case .order:
            "toggleOrderedList"
        case .unOrder:
            "toggleBulletList"
        case .check:
            "toggleTaskList"
        case .code:
            "toggleCodeBlock"
        case .foldList:
            ""
        case .page:
            ""
            
        case .bold:
            "toggleBold"
        case .italic:
            "toggleItalic"
        case .strikethrough:
            "toggleStrike"
        case .line:
            "setHorizontalRule"
        case .reference:
            "toggleBlockquote"
            
        case .colors:
            ""
        case .camera:
            ""
        case .picture:
            ""
        case .insert:
            ""
        case .style:
            ""
        case .mention:
            ""
        case .left, .center, .right:
            "setTextAlign"
        case .goLeft:
            ""
        case .goRight:
            ""
        }
    }
    
    var jsParams: [String: Any]? {
        switch self {
        case .h1:
            ["level": 1]
        case .h2:
            ["level": 2]
        case .h3:
            ["level": 3]
        case .h4:
            ["level": 4]
        case .h5:
            ["level": 5]
        case .right:
            ["align": "right"]
        case .center:
            ["align": "center"]
        case .left:
            ["align": "left"]
        default:
            nil
        }
    }
}
