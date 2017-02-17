//
//  AudioFile.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/15/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import Foundation

struct AudioFile {
  let urlString: String?
  let asset: Asset?
  
  init(urlString: String?) {
    self.urlString = urlString
    var asset: Asset? = nil
    if let urlString = urlString {
      asset = AssetPersistenceManager.shared.asset(forUrl: urlString)
    }
    
    self.asset = asset
  }
}
