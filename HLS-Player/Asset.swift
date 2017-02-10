//
//  Asset.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/10/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import AVFoundation

struct Asset {
  let name: String
  let urlAsset: AVURLAsset
}

extension Asset: Equatable {}

func ==(lhs: Asset, rhs: Asset) -> Bool {
  return lhs.name == rhs.name && lhs.urlAsset == rhs.urlAsset
}

extension Asset {
  enum DownloadState: String {
    case notDownloaded
    case downloading
    case downloaded
  }
}

extension Asset {
  struct Keys {
    /**
     Key for the Asset name, used for `AssetDownloadProgressNotification` and
     `AssetDownloadStateChangedNotification` Notifications as well as
     AssetListManager.
     */
    static let name = "AssetNameKey"
    
    /**
     Key for the Asset download percentage, used for
     `AssetDownloadProgressNotification` Notification.
     */
    static let percentDownloaded = "AssetPercentDownloadedKey"
    
    /**
     Key for the Asset download state, used for
     `AssetDownloadStateChangedNotification` Notification.
     */
    static let downloadState = "AssetDownloadStateKey"
  }
}
