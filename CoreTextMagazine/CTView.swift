//
//  CTView.swift
//  CoreTextMagazine
//
//  Created by Dang Quoc Huy on 8/29/17.
//  Copyright © 2017 Dang Quoc Huy. All rights reserved.
//

import UIKit
import CoreText

class CTView: UIView {

  /*
  1. Upon view creation, draw(_:) will run automatically to render the view’s backing layer.
  2. Unwrap the current graphic context you’ll use for drawing.
  3. Create a path which bounds the drawing area, the entire view’s bounds in this case
  4. In Core Text, you use NSAttributedString, as opposed to String or NSString, to hold the text and its attributes. Initialize “Hello World” as an attributed string.
  5. CTFramesetterCreateWithAttributedString creates a CTFramesetter with the supplied attributed string. CTFramesetter will manage your font references and your drawing frames.
  6. Create a CTFrame, by having CTFramesetterCreateFrame render the entire string within path.
  7. CTFrameDraw draws the CTFrame in the given context.
  That’s all you need to draw some simple text! Build, run and see the result.
  */
  
  //1
  override func draw(_ rect: CGRect) {
    // 2
    guard let context = UIGraphicsGetCurrentContext() else { return }
    
    // Flip the coordinate system
    context.textMatrix = .identity
    context.translateBy(x: 0, y: bounds.size.height)
    context.scaleBy(x: 1.0, y: -1.0)
    
    // 3
    let path = CGMutablePath()
    path.addRect(bounds)
    // 4
    let attrString = NSAttributedString(string: "Hello World")
    // 5
    let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
    // 6
    let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), path, nil)
    // 7
    CTFrameDraw(frame, context)
  }
  
}
