//
//  Course.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/15/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import Foundation

class Course {
  var uuid: String = ""
  var title: String = ""
  var summary: String = ""
  var backgroundImageURL: String = ""
  var position: Int = 999
  var teacherUUID: String?
  var category: CourseCategory?
  var sessions: [CourseSession] = []
  var teacher: Teacher?
}
