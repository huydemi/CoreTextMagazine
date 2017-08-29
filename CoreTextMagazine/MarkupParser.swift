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
    /*
    1. attrString starts out empty, but will eventually contain the parsed markup.
    2. This regular expression, matches blocks of text with the tags immediately follow them. It says, “Look through the string until you find an opening bracket, then look through the string until you hit a closing bracket (or the end of the document).”
    3. Search the entire range of the markup for regex matches, then produce an array of the resulting NSTextCheckingResults.
    */
    
    //1
    attrString = NSMutableAttributedString(string: "")
    //2
    do {
      let regex = try NSRegularExpression(pattern: "(.*?)(<[^>]+>|\\Z)",
                                          options: [.caseInsensitive,
                                                    .dotMatchesLineSeparators])
      //3
      let chunks = regex.matches(in: markup,
                                 options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                 range: NSRange(location: 0,
                                                length: markup.characters.count))
      
      /*
       1. Loop through chunks.
       2. Get the current NSTextCheckingResult's range, unwrap the Range<String.Index> and proceed with the block as long as it exists.
       3. Break chunk into parts separated by "<". The first part contains the magazine text and the second part contains the tag (if it exists).
       4. Create a font using fontName, currently "Arial" by default, and a size relative to the device screen. If fontName doesn't produce a valid UIFont, set font to the default font.
       5. Create a dictionary of the font format, apply it to parts[0] to create the attributed string, then append that string to the result string.
      */
      let defaultFont: UIFont = .systemFont(ofSize: UIScreen.main.bounds.size.height / 40)
      //1
      for chunk in chunks {
        //2
        guard let markupRange = markup.range(from: chunk.range) else { continue }
        //3
        let parts = markup[markupRange].components(separatedBy: "<")
        //4
        let font = UIFont(name: fontName, size: UIScreen.main.bounds.size.height / 40) ?? defaultFont
        //5
        let attrs = [NSForegroundColorAttributeName: color, NSFontAttributeName: font] as [String : Any]
        let text = NSMutableAttributedString(string: parts[0], attributes: attrs)
        attrString.append(text)
        
        /*
         1. If less than two parts, skip the rest of the loop body. Otherwise, store that second part as tag.
         2. If tag starts with "font", create a regex to find the font's "color" value, then use that regex to enumerate through tag's matching "color" values. In this case, there should be only one matching color value.
         3. If enumerateMatches(in:options:range:using:) returns a valid match with a valid range in tag, find the indicated value (ex. <font color="red"> returns "red") and append "Color" to form a UIColor selector. Perform that selector then set your class's color to the returned color if it exists, to black if not.
         4. Similarly, create a regex to process the font's "face" value. If it finds a match, set fontName to that string.

        */
        // 1
        if parts.count <= 1 {
          continue
        }
        let tag = parts[1]
        //2
        if tag.hasPrefix("font") {
          let colorRegex = try NSRegularExpression(pattern: "(?<=color=\")\\w+",
                                                   options: NSRegularExpression.Options(rawValue: 0))
          colorRegex.enumerateMatches(in: tag,
                                      options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                      range: NSMakeRange(0, tag.characters.count)) { (match, _, _) in
                                        //3
                                        if let match = match,
                                          let range = tag.range(from: match.range) {
                                          let colorSel = NSSelectorFromString(tag[range]+"Color")
                                          color = UIColor.perform(colorSel).takeRetainedValue() as? UIColor ?? .black
                                        }
          }
          //4
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
