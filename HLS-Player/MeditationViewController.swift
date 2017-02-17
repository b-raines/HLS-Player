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
  fileprivate let fadeAnimationController = FadeAnimationController()
  fileprivate var playerViewController: AVPlayerViewController? {
    didSet {
      playerViewController?.transitioningDelegate = self
    }
  }
  fileprivate var meditationViewModel: MeditationViewModel?
  fileprivate var courseSessionViewModel: CourseSessionViewModel?
  fileprivate var videoPlayed = false
  fileprivate var audioPlayed = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .white
    
    AssetPlaybackManager.shared.delegate = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Clean up
    if playerViewController != nil {
      AssetPlaybackManager.shared.setAssetForPlayback(nil)
      playerViewController?.player = nil
      playerViewController = nil
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    switch (videoPlayed, audioPlayed) {
    case (false, false):
      if let courseSession = courseSessionViewModel {
        playerViewController = AVPlayerViewController()
        AssetPlaybackManager.shared.setAssetForPlayback(courseSession.videoAsset)
        
        present(playerViewController!, animated: true, completion: { [weak self] _ in
          self?.videoPlayed = true
        })
      }
    case (true, false):
      if let meditation = meditationViewModel {
        playerViewController = AVPlayerViewController()
        
        // TODO: This is selecting only the first asset
        guard let asset = meditation.audioFiles.first?.asset else { return }
        AssetPlaybackManager.shared.setAssetForPlayback(asset)
        
        present(playerViewController!, animated: true, completion: { [weak self] _ in
          self?.audioPlayed = true
        })
      }
    default:
      _ = navigationController?.popViewController(animated: true)
    }
  }
}

extension MeditationViewController {
  convenience init(_ viewModel: MeditationViewModel, courseSession: CourseSessionViewModel?) {
    self.init()
    self.meditationViewModel = viewModel
    self.courseSessionViewModel = courseSession
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

extension MeditationViewController: UIViewControllerTransitioningDelegate {
  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    fadeAnimationController.presenting = true
    return fadeAnimationController
  }
  
  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    fadeAnimationController.presenting = false
    return fadeAnimationController
  }
}
