//
//  CTView.swift
//  CoreTextMagazine
//
//  Created by Dang Quoc Huy on 8/29/17.
//  Copyright © 2017 Dang Quoc Huy. All rights reserved.
//

import UIKit
import CoreText

class CTView: UIScrollView {
  // MARK: - Properties
  var imageIndex: Int!
  
  // buildFrames(withAttrString:andImages:) will create CTColumnViews then add them to the scrollview.
  func buildFrames(withAttrString attrString: NSAttributedString,
                   andImages images: [[String: Any]]) {
    imageIndex = 0
    
    // Enable the scrollview's paging behavior; so, whenever the user stops scrolling, the scrollview snaps into place so exactly one entire page is showing at a time.
    isPagingEnabled = true
    // CTFramesetter framesetter will create each column's CTFrame of attributed text.
    let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
    // UIView pageViews will serve as a container for each page's column subviews; textPos will keep track of the next character; columnIndex will keep track of the current column; pageIndex will keep track of the current page; and settings gives you access to the app's margin size, columns per page, page frame and column frame settings.
    var pageView = UIView()
    var textPos = 0
    var columnIndex: CGFloat = 0
    var pageIndex: CGFloat = 0
    let settings = CTSettings()
    // You're going to loop through attrString and lay out the text column by column, until the current text position reaches the end.
    while textPos < attrString.length {
      // If the column index divided by the number of columns per page equals 0, thus indicating the column is the first on its page, create a new page view to hold the columns. To set its frame, take the margined settings.pageRect and offset its x origin by the current page index multiplied by the width of the screen; so within the paging scrollview, each magazine page will be to the right of the previous one.
      if columnIndex.truncatingRemainder(dividingBy: settings.columnsPerPage) == 0 {
        columnIndex = 0
        pageView = UIView(frame: settings.pageRect.offsetBy(dx: pageIndex * bounds.width, dy: 0))
        addSubview(pageView)
        // Increment the pageIndex.
        pageIndex += 1
      }
      // Divide pageView's width by settings.columnsPerPage to get the first column's x origin; multiply that origin by the column index to get the column offset; then create the frame of the current column by taking the standard columnRect and offsetting its x origin by columnOffset.
      let columnXOrigin = pageView.frame.size.width / settings.columnsPerPage
      let columnOffset = columnIndex * columnXOrigin
      let columnFrame = settings.columnRect.offsetBy(dx: columnOffset, dy: 0)
      
      // Create a CGMutablePath the size of the column, then starting from textPos, render a new CTFrame with as much text as can fit.
      let path = CGMutablePath()
      path.addRect(CGRect(origin: .zero, size: columnFrame.size))
      let ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, nil)
      // Create a CTColumnView with a CGRect columnFrame and CTFrame ctframe then add the column to pageView.
      let column = CTColumnView(frame: columnFrame, ctframe: ctframe)
      
      if images.count > imageIndex {
        attachImagesWithFrame(images, ctframe: ctframe, margin: settings.margin, columnView: column)
      }
      
      pageView.addSubview(column)
      // Use CTFrameGetVisibleStringRange(_:) to calculate the range of text contained within the column, then increment textPos by that range length to reflect the current text position.
      let frameRange = CTFrameGetVisibleStringRange(ctframe)
      textPos += frameRange.length
      // Increment the column index by 1 before looping to the next column.
      columnIndex += 1
    }
    
    // set the scroll view's content size
    contentSize = CGSize(width: CGFloat(pageIndex) * bounds.size.width,
                         height: bounds.size.height)
  }
  
  func attachImagesWithFrame(_ images: [[String: Any]],
                             ctframe: CTFrame,
                             margin: CGFloat,
                             columnView: CTColumnView) {
    // Get an array of ctframe's CTLine objects.
    let lines = CTFrameGetLines(ctframe) as NSArray
    // Use CTFrameGetOrigins to copy ctframe's line origins into the origins array. By setting a range with a length of 0, CTFrameGetOrigins will know to traverse the entire CTFrame.
    var origins = [CGPoint](repeating: .zero, count: lines.count)
    CTFrameGetLineOrigins(ctframe, CFRangeMake(0, 0), &origins)
    // Set nextImage to contain the attributed data of the current image. If nextImage contain's the image's location, unwrap it and continue; otherwise, return early.
    var nextImage = images[imageIndex]
    guard var imgLocation = nextImage["location"] as? Int else {
      return
    }
    // Loop through the text's lines.
    for lineIndex in 0..<lines.count {
      let line = lines[lineIndex] as! CTLine
      // If the line's glyph runs, filename and image with filename all exist, loop through the glyph runs of that line.
      if let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun],
        let imageFilename = nextImage["filename"] as? String,
        let img = UIImage(named: imageFilename)  {
        for run in glyphRuns {
          // If the range of the present run does not contain the next image, skip the rest of the loop. Otherwise, render the image here.
          let runRange = CTRunGetStringRange(run)
          if runRange.location > imgLocation || runRange.location + runRange.length <= imgLocation {
            continue
          }
          // Calculate the image width using CTRunGetTypographicBounds and set the height to the found ascent.
          var imgBounds: CGRect = .zero
          var ascent: CGFloat = 0
          imgBounds.size.width = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, nil, nil))
          imgBounds.size.height = ascent
          // Get the line's x offset with CTLineGetOffsetForStringIndex then add it to the imgBounds' origin.
          let xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
          imgBounds.origin.x = origins[lineIndex].x + xOffset
          imgBounds.origin.y = origins[lineIndex].y
          // Add the image and its frame to the current CTColumnView.
          columnView.images += [(image: img, frame: imgBounds)]
          // Increment the image index. If there's an image at images[imageIndex], update nextImage and imgLocation so they refer to that next image.
          imageIndex! += 1
          if imageIndex < images.count {
            nextImage = images[imageIndex]
            imgLocation = (nextImage["location"] as AnyObject).intValue
          }
        }
      }
    }
  }
  
}
