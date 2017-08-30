//
//  MarkupParser.swift
//  CoreTextMagazine
//
//  Created by Dang Quoc Huy on 8/29/17.
//  Copyright © 2017 Dang Quoc Huy. All rights reserved.
//

import UIKit
import CoreText

class MarkupParser: NSObject {
  
  // MARK: - Properties
  var color: UIColor = .black
  var fontName: String = "Arial"
  var attrString: NSMutableAttributedString!
  var images: [[String: Any]] = []
  
  // MARK: - Initializers
  override init() {
    super.init()
  }
  
  // MARK: - Internal
  func parseMarkup(_ markup: String) {
    // attrString starts out empty, but will eventually contain the parsed markup.
    attrString = NSMutableAttributedString(string: "")
    // This regular expression, matches blocks of text with the tags immediately follow them. It says, “Look through the string until you find an opening bracket, then look through the string until you hit a closing bracket (or the end of the document).”
    do {
      let regex = try NSRegularExpression(pattern: "(.*?)(<[^>]+>|\\Z)",
                                          options: [.caseInsensitive,
                                                    .dotMatchesLineSeparators])
      // Search the entire range of the markup for regex matches, then produce an array of the resulting NSTextCheckingResults.
      let chunks = regex.matches(in: markup,
                                 options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                 range: NSRange(location: 0,
                                                length: markup.characters.count))
      
      let defaultFont: UIFont = .systemFont(ofSize: UIScreen.main.bounds.size.height / 40)
      // Loop through chunks.
      for chunk in chunks {
        // Get the current NSTextCheckingResult's range, unwrap the Range<String.Index> and proceed with the block as long as it exists.
        guard let markupRange = markup.range(from: chunk.range) else { continue }
        // Break chunk into parts separated by "<". The first part contains the magazine text and the second part contains the tag (if it exists).
        let parts = markup[markupRange].components(separatedBy: "<")
        // Create a font using fontName, currently "Arial" by default, and a size relative to the device screen. If fontName doesn't produce a valid UIFont, set font to the default font.
        let font = UIFont(name: fontName, size: UIScreen.main.bounds.size.height / 40) ?? defaultFont
        // Create a dictionary of the font format, apply it to parts[0] to create the attributed string, then append that string to the result string.
        let attrs = [NSForegroundColorAttributeName: color, NSFontAttributeName: font] as [String : Any]
        let text = NSMutableAttributedString(string: parts[0], attributes: attrs)
        attrString.append(text)
        
        // If less than two parts, skip the rest of the loop body. Otherwise, store that second part as tag.
        if parts.count <= 1 {
          continue
        }
        let tag = parts[1]
        // If tag starts with "font", create a regex to find the font's "color" value, then use that regex to enumerate through tag's matching "color" values. In this case, there should be only one matching color value.
        if tag.hasPrefix("font") {
          let colorRegex = try NSRegularExpression(pattern: "(?<=color=\")\\w+",
                                                   options: NSRegularExpression.Options(rawValue: 0))
          colorRegex.enumerateMatches(in: tag,
                                      options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                      range: NSMakeRange(0, tag.characters.count)) { (match, _, _) in
                                        // If enumerateMatches(in:options:range:using:) returns a valid match with a valid range in tag, find the indicated value (ex. <font color="red"> returns "red") and append "Color" to form a UIColor selector. Perform that selector then set your class's color to the returned color if it exists, to black if not.
                                        if let match = match,
                                          let range = tag.range(from: match.range) {
                                          let colorSel = NSSelectorFromString(tag[range]+"Color")
                                          color = UIColor.perform(colorSel).takeRetainedValue() as? UIColor ?? .black
                                        }
          }
          // Similarly, create a regex to process the font's "face" value. If it finds a match, set fontName to that string.
          let faceRegex = try NSRegularExpression(pattern: "(?<=face=\")[^\"]+",
                                                  options: NSRegularExpression.Options(rawValue: 0))
          faceRegex.enumerateMatches(in: tag, 
                                     options: NSRegularExpression.MatchingOptions(rawValue: 0), 
                                     range: NSMakeRange(0, tag.characters.count)) { (match, _, _) in
                                      
                                      if let match = match,
                                        let range = tag.range(from: match.range) {
                                        fontName = String(tag[range])
                                      }
          }
        } //end of font parsing
        
        // If tag starts with "img", use a regex to search for the image's "src" value, i.e. the filename.
        else if tag.hasPrefix("img") {
          
          var filename:String = ""
          let imageRegex = try NSRegularExpression(pattern: "(?<=src=\")[^\"]+",
                                                   options: NSRegularExpression.Options(rawValue: 0))
          imageRegex.enumerateMatches(in: tag,
                                      options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                      range: NSMakeRange(0, tag.characters.count)) { (match, _, _) in
                                        
                                        if let match = match,
                                          let range = tag.range(from: match.range) {
                                          filename = String(tag[range])
                                        }
          }
          // Set the image width to the width of the column and set its height so the image maintains its height-width aspect ratio.
          let settings = CTSettings()
          var width: CGFloat = settings.columnRect.width
          var height: CGFloat = 0
          
          if let image = UIImage(named: filename) {
            height = width * (image.size.height / image.size.width)
            // If the height of the image is too long for the column, set the height to fit the column and reduce the width to maintain the image's aspect ratio. Since the text following the image will contain the empty space attribute, the text containing the empty space information must fit within the same column as the image; so set the image height to settings.columnRect.height - font.lineHeight.
            if height > settings.columnRect.height - font.lineHeight {
              height = settings.columnRect.height - font.lineHeight
              width = height * (image.size.width / image.size.height)
            }
          }
          
          // Append an Dictionary containing the image's size, filename and text location to images.
          images += [["width": NSNumber(value: Float(width)),
                      "height": NSNumber(value: Float(height)),
                      "filename": filename,
                      "location": NSNumber(value: attrString.length)]]
          // Define RunStruct to hold the properties that will delineate the empty spaces. Then initialize a pointer to contain a RunStruct with an ascent equal to the image height and a width property equal to the image width.
          struct RunStruct {
            let ascent: CGFloat
            let descent: CGFloat
            let width: CGFloat
          }
          
          let extentBuffer = UnsafeMutablePointer<RunStruct>.allocate(capacity: 1)
          extentBuffer.initialize(to: RunStruct(ascent: height, descent: 0, width: width))
          // Create a CTRunDelegateCallbacks that returns the ascent, descent and width properties belonging to pointers of type RunStruct.
          var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { (pointer) in
          }, getAscent: { (pointer) -> CGFloat in
            let d = pointer.assumingMemoryBound(to: RunStruct.self)
            return d.pointee.ascent
          }, getDescent: { (pointer) -> CGFloat in
            let d = pointer.assumingMemoryBound(to: RunStruct.self)
            return d.pointee.descent
          }, getWidth: { (pointer) -> CGFloat in
            let d = pointer.assumingMemoryBound(to: RunStruct.self)
            return d.pointee.width
          })
          // Use CTRunDelegateCreate to create a delegate instance binding the callbacks and the data parameter together.
          let delegate = CTRunDelegateCreate(&callbacks, extentBuffer)
          // Create an attributed dictionary containing the delegate instance, then append a single space to attrString which holds the position and sizing information for the hole in the text.
          let attrDictionaryDelegate = [(kCTRunDelegateAttributeName as String): (delegate as Any)]
          attrString.append(NSAttributedString(string: " ", attributes: attrDictionaryDelegate))
        }
        
      }
    } catch _ {
    }
  }
}

// MARK: - String
extension String {
  func range(from range: NSRange) -> Range<String.Index>? {
    guard let from16 = utf16.index(utf16.startIndex,
                                   offsetBy: range.location,
                                   limitedBy: utf16.endIndex),
      let to16 = utf16.index(from16, offsetBy: range.length, limitedBy: utf16.endIndex),
      let from = String.Index(from16, within: self),
      let to = String.Index(to16, within: self) else {
        return nil
    }
    
    return from ..< to
  }
}
