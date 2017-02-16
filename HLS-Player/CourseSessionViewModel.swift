//
//  CourseSessionViewModel.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/15/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import Foundation
import AVFoundation
import ReactiveSwift

struct CourseSessionViewModel {
  let title: String
  let videoAsset: Asset?
  let audioAssets: [Asset]?
}

extension CourseSessionViewModel {
  init(courseSession: CourseSession) {
    let videoAsset = courseSession.videoURL
      .flatMap { AssetPersistenceManager.shared.asset(for: $0) }
    let audioAssets = courseSession.meditation?.audioFiles
      .flatMap { $0.urlString }
      .flatMap { AssetPersistenceManager.shared.asset(for: $0) }
    
    self.init(
      title: courseSession.title,
      videoAsset: videoAsset,
      audioAssets: audioAssets
    )
  }
}

// Methods for populating w/ sample data
extension CourseSessionViewModel {
  static func withSampleData(title: String) -> CourseSessionViewModel {
    let audioFile = AudioFile(urlString: "https://d3fw0mens6o5gn.cloudfront.net/audio/Day%2B1_v2-Simple-but-not-easy/index.m3u8")
    let meditation = Meditation(
      title: "Meditation",
      audioFiles: [audioFile]
    )
    let session = CourseSession(
      title: title,
      videoURL: "https://d3fw0mens6o5gn.cloudfront.net/video/Day%2B1%2B-%2BNew%2BBasics%2B-%2BDan%252BMeditation%252B%2BMotiongrphic/index.m3u8",
      meditation: meditation
    )
    
    return self.init(courseSession: session)
  }
}
