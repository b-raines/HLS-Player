//
//  CourseSessionTableViewCell.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/10/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import UIKit

class CourseSessionTableViewCell: UITableViewCell {
  
  // MARK: Properties
  static let reuseIdentifier = "CourseSessionTableViewCellIdentifier"
  private let titleLabel = UILabel()
  private let downloadStateLabel = UILabel()
  private let downloadProgressView = UIProgressView(progressViewStyle: .default)
  private let topMargin: CGFloat = 12
  private let bottomMargin: CGFloat = -12
  private let leadingMargin: CGFloat = 12
  private let trailingMargin: CGFloat = -12
  weak var delegate: CourseSessionTableViewCellDelegate?
  var courseSession: CourseSessionViewModel? {
    didSet {
      titleLabel.text = courseSession?.title
    }
  }
  
  var asset: Asset?
//    didSet {
//      if let asset = asset {
//        let downloadState = AssetPersistenceManager.shared.downloadState(for: asset)
//        
//        switch downloadState {
//        case .downloaded:
//          downloadProgressView.isHidden = true
//        case .downloading:
//          downloadProgressView.isHidden = false
//        case .notDownloaded:
//          break
//        }
//        
//        titleLabel.text = asset.name
//        downloadStateLabel.text = downloadState.rawValue
//        
//        let notificationCenter = NotificationCenter.default
//        notificationCenter.addObserver(self, selector: #selector(handleAssetDownloadStateChangedNotification(_:)), name: AssetPersistenceManager.downloadStateChangedNotification, object: nil)
//        notificationCenter.addObserver(self, selector: #selector(handleAssetDownloadProgressNotification(_:)), name: AssetPersistenceManager.downloadProgressNotification, object: nil)
//      } else {
//        downloadProgressView.isHidden = false
//        titleLabel.text = ""
//        downloadStateLabel.text = ""
//      }
//    }
  
  // MARK: Initialization
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    config()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  // MARK: Notification handling
  func handleAssetDownloadStateChangedNotification(_ notification: Notification) {
    guard let assetStreamName = notification.userInfo?[Asset.Keys.name] as? String,
      let downloadStateRawValue = notification.userInfo?[Asset.Keys.downloadState] as? String,
      let downloadState = Asset.DownloadState(rawValue: downloadStateRawValue),
      let asset = asset
      , asset.name == assetStreamName else { return }
    
    DispatchQueue.main.async {
      switch downloadState {
      case .downloading:
        self.downloadProgressView.isHidden = false
        self.downloadStateLabel.text = downloadStateRawValue
      case .downloaded, .notDownloaded:
        self.downloadProgressView.isHidden = true
      }
      
      self.delegate?.courseSessionTableViewCell(self, downloadStateDidChange: downloadState)
    }
  }
  
  func handleAssetDownloadProgressNotification(_ notification: NSNotification) {
    guard let assetStreamName = notification.userInfo?[Asset.Keys.name] as? String, let asset = asset , asset.name == assetStreamName else { return }
    guard let progress = notification.userInfo?[Asset.Keys.percentDownloaded] as? Double else { return }
    
    self.downloadProgressView.setProgress(Float(progress), animated: true)
  }
  
  func config() {
    let views = [
      "name": titleLabel,
      "downloadState": downloadStateLabel,
      "downloadProgress": downloadProgressView
    ]
    
    for sv in views.values {
      sv.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(sv)
      sv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingMargin).isActive = true
      sv.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: trailingMargin).isActive = true
    }
    
    downloadProgressView.isHidden = true
    downloadProgressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: trailingMargin * 3).isActive = true
    
    contentView.addConstraints(NSLayoutConstraint.constraints(
      withVisualFormat: "V:|-(topMargin)-[name]-(topMargin)-[downloadState]-(topMargin)-[downloadProgress]-(topMargin)-|",
      options: [],
      metrics: ["topMargin": topMargin, "bottomMargin": bottomMargin],
      views: views
    ))
  }
  
  deinit {
    let notificationCenter = NotificationCenter.default
    notificationCenter.removeObserver(self)
  }
}

protocol CourseSessionTableViewCellDelegate: class {
  func courseSessionTableViewCell(_ cell: CourseSessionTableViewCell, downloadStateDidChange newState: Asset.DownloadState)
}
