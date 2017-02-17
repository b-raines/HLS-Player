//
//  FadeAnimationController.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/17/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import UIKit

class FadeAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
  
  // MARK: Properties
  private let transitionDuration: TimeInterval = 0.7
  var presenting = true
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return transitionDuration
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    guard let toVC = transitionContext.viewController(forKey: .to) else { return }
    guard let fromVC = transitionContext.viewController(forKey: .from) else { return }
    
    guard let toView = toVC.view else { return }
    guard let fromView = fromVC.view else { return }
    let containerView = transitionContext.containerView
    
    if presenting {
      toView.alpha = 0
      containerView.insertSubview(toView, aboveSubview: fromView)
    } else {
      containerView.insertSubview(toView, belowSubview: fromView)
    }
    
    toView.frame = transitionContext.finalFrame(for: toVC)
    
    UIView.animate(
      withDuration: transitionDuration,
      delay: 0,
      options: [.curveEaseInOut],
      animations: { [weak self] _ in
        if let presenting = self?.presenting, presenting {
          toView.alpha = 1
        } else {
          fromView.alpha = 0
        }
      }, completion: { _ in
        fromView.removeFromSuperview()
        transitionContext.completeTransition(true)
    })
  }
}
