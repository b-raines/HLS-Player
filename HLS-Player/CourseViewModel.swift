//
//  CourseViewModel.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/15/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import Foundation

struct CourseViewModel {
  let courseSessions: [CourseSessionViewModel]
  
  init(courseSessions: [CourseSession]) {
    self.courseSessions = courseSessions.map { CourseSessionViewModel(courseSession: $0) }
  }
}

// Methods for populating w/ sample data
extension CourseViewModel {
  static func withSampleData() -> CourseViewModel {
    return CourseViewModel(courseSessions: sessionsForSampleData(["Session 1", "Session 2"]))
  }
  
  private init(courseSessions: [CourseSessionViewModel]) {
    self.courseSessions = courseSessions
  }
  
  private static func sessionsForSampleData(_ titles: [String]) -> [CourseSessionViewModel] {
    return titles.map { CourseSessionViewModel.withSampleData(title: $0) }
  }
}
