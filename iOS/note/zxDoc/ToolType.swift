//
//  ToolItem.swift
//  note
//
//  Created by 倪申雷 on 2025/7/12.
//

import SwiftUI

enum ToolType {
    
    case text
    case h1
    case h2
    case h3
    case h4
    case h5
    case order
    case unOrder
    case check
    case code
    
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
    
    var image: Image {
        switch self {
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
        case .order:
            Image(.fontOrder)
        case .unOrder:
            Image(.fontUnOrder)
        case .check:
            Image(.fontCheck)
        case .code:
            Image(.fontCode)
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
        }
    }
    
    var jsMethodName: String {
        switch self {
        case .h1, .h2, .h3, .h4, .h5:
            "toggleHeading"
        case .text:
            "clearParagraph"
        case .order:
            "toggleOrderedList"
        case .unOrder:
            "toggleBulletList"
        case .check:
            "toggleTaskList"
        case .code:
            "toggleCodeBlcok"
            
        case .bold:
            "toggleBold"
        case .italic:
            "toggleItalic"
        case .strikethrough:
            "toggleUnderline"
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
        case .left, .center, .right:
            "setTextAlign"
        case .goLeft:
            ""
        case .goRight:
            ""
        }
    }
    
    var jsArguments: [Any]? {
        switch self {
        case .h1:
            [1]
        case .h2:
            [2]
        case .h3:
            [3]
        case .h4:
            [4]
        case .h5:
            [5]
        case .right:
            ["right"]
        case .center:
            ["center"]
        case .left:
            ["left"]
        default:
            nil
        }
    }
}
