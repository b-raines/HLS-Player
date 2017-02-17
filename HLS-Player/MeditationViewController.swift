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
  
  // MARK: Initialization
  convenience init(_ viewModel: MeditationViewModel, courseSession: CourseSessionViewModel?) {
    self.init()
    self.meditationViewModel = viewModel
    self.courseSessionViewModel = courseSession
  }
  
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
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] _ in
      guard let strongSelf = self else { return }
      switch (strongSelf.videoPlayed, strongSelf.audioPlayed) {
      case (false, false):
        if let courseSession = strongSelf.courseSessionViewModel {
          strongSelf.playerViewController = AVPlayerViewController()
          AssetPlaybackManager.shared.setAssetForPlayback(courseSession.videoAsset)
          
          strongSelf.present(strongSelf.playerViewController!, animated: true, completion: { _ in
            strongSelf.videoPlayed = true
          })
        }
      case (true, false):
        if let meditation = strongSelf.meditationViewModel {
          strongSelf.playerViewController = AVPlayerViewController()
          
          // TODO: This is selecting only the first asset
          guard let asset = meditation.audioFiles.first?.asset else { return }
          AssetPlaybackManager.shared.setAssetForPlayback(asset)
          
          strongSelf.present(strongSelf.playerViewController!, animated: true, completion: { _ in
            strongSelf.audioPlayed = true
          })
        }
      default:
        _ = strongSelf.navigationController?.popViewController(animated: true)
      }
    })
  }
}

extension MeditationViewController {
  override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
    return .fade
  }
}

// UIViewControllerTransitioningDelegate
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
