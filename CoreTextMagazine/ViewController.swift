//
//  ViewController.swift
//  CoreTextMagazine
//
//  Created by Dang Quoc Huy on 8/29/17.
//  Copyright © 2017 Dang Quoc Huy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 1
    guard let file = Bundle.main.path(forResource: "zombies", ofType: "txt") else { return }
    
    do {
      let text = try String(contentsOfFile: file, encoding: .utf8)
      // 2
      let parser = MarkupParser()
      parser.parseMarkup(text)
      (view as? CTView)?.importAttrString(parser.attrString)
    } catch _ {
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

