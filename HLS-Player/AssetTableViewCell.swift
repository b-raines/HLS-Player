//
//  AssetTableViewCell.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/10/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import UIKit

class AssetTableViewCell: UITableViewCell {
  
  // MARK: Properties
  static let reuseIdentifier = "AssetTableViewCellIdentifier"
  fileprivate let assetNameLabel = UILabel()
  fileprivate let downloadStateLabel = UILabel()
  fileprivate let downloadProgressView = UIProgressView(progressViewStyle: .default)
  weak var delegate: AssetTableViewCellDelegate?
  
  var asset: Asset? {
    didSet {
      if let asset = asset {
        let downloadState = AssetPersistenceManager.shared.downloadState(for: asset)
        
        switch downloadState {
        case .downloaded:
          downloadProgressView.isHidden = true
        case .downloading:
          downloadProgressView.isHidden = false
        case .notDownloaded:
          break
        }
        
        assetNameLabel.text = asset.name
        downloadStateLabel.text = downloadState.rawValue
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(handleAssetDownloadStateChangedNotification(_:)), name: AssetPersistenceManager.downloadStateChangedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleAssetDownloadProgressNotification(_:)), name: AssetPersistenceManager.downloadProgressNotification, object: nil)
      } else {
        downloadProgressView.isHidden = false
        assetNameLabel.text = ""
        downloadStateLabel.text = ""
      }
    }
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
      
      self.delegate?.assetTableViewCell(self, downloadStateDidChange: downloadState)
    }
  }
  
  func handleAssetDownloadProgressNotification(_ notification: NSNotification) {
    guard let assetStreamName = notification.userInfo?[Asset.Keys.name] as? String, let asset = asset , asset.name == assetStreamName else { return }
    guard let progress = notification.userInfo?[Asset.Keys.percentDownloaded] as? Double else { return }
    
    self.downloadProgressView.setProgress(Float(progress), animated: true)
  }
  
  deinit {
    let notificationCenter = NotificationCenter.default
    notificationCenter.removeObserver(self)
  }
}

protocol AssetTableViewCellDelegate: class {
  func assetTableViewCell(_ cell: AssetTableViewCell, downloadStateDidChange newState: Asset.DownloadState)
}
