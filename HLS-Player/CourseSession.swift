//
//  CourseSession.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/15/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import Foundation

class CourseSession {
  var uuid: String = ""
  var position: Int = 999
  var title: String = ""
  var free: Bool = true
  var duration: Int = 0
  var videoURL: String?
  var startedAt: Date?
  var completedAt: Date?
  var meditation: Meditation?
  var course: Course?
}
