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
  let courseSession: CourseSessionViewModel?
}

extension MeditationViewModel {
  init(meditation: Meditation) {
    var courseSessionViewModel: CourseSessionViewModel? = nil
    if let courseSession = meditation.courseSession {
      courseSessionViewModel = CourseSessionViewModel(courseSession: courseSession)
    }
    
    self.init(
      title: meditation.title,
      audioFiles: meditation.audioFiles,
      courseSession: courseSessionViewModel
    )
  }
}
