//
//  MeditationViewModel.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/16/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import Foundation

struct MeditationViewModel {
  let title: String
  let audioFiles: [AudioFile]
}

extension MeditationViewModel {
  init(meditation: Meditation) {
    self.init(
      title: meditation.title,
      audioFiles: meditation.audioFiles
    )
  }
}
