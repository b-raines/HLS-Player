//
//  Meditation.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/15/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import Foundation

class Meditation {
  var title: String = ""
  var position: Int = 999
  var session: CourseSession?
  var category: MeditationCategory?
  var audioFiles: [AudioFile] = []
  var teacher: Teacher?
}
