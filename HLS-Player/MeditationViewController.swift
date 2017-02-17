//
//  MeditationViewController.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/17/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class MeditationViewController: UIViewController {
  
  // MARK: Properties
  fileprivate var playerViewController: AVPlayerViewController?
  fileprivate var meditationViewModel: MeditationViewModel?
  fileprivate var courseSessionViewModel: CourseSessionViewModel?
  fileprivate var videoPlayed = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    AssetPlaybackManager.shared.delegate = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if !videoPlayed, let courseSession = courseSessionViewModel {
      playerViewController = AVPlayerViewController()
      AssetPlaybackManager.shared.setAssetForPlayback(courseSession.videoAsset)
      
      present(playerViewController!, animated: true)
    }
    
    if videoPlayed, let meditation = meditationViewModel {
      playerViewController = AVPlayerViewController()
      
      guard let asset = meditation.audioFiles.first?.asset else { return }
      AssetPlaybackManager.shared.setAssetForPlayback(asset)
      present(playerViewController!, animated: true)
    }
  }
}

extension MeditationViewController {
  convenience init(viewModel: MeditationViewModel) {
    self.meditationViewModel = viewModel
    self.courseSessionViewModel = viewModel.courseSession
  }
}

// Extend `CourseTableViewController` to conform to the `AssetPlaybackDelegate` protocol.
extension MeditationViewController: AssetPlaybackDelegate {
  func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerReadyToPlay player: AVPlayer) {
    player.play()
  }
  
  func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerCurrentItemDidChange player: AVPlayer) {
    guard let playerViewController = playerViewController, player.currentItem != nil else { return }
    playerViewController.player = player
  }
}
