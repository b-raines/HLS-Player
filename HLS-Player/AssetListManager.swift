//
//  AssetListManager.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/10/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import Foundation
import AVFoundation

class AssetListManager: NSObject {
  
  // MARK: Properties
  static let shared = AssetListManager()
  
  /// Notification for when download progress has changed.
  static let didLoadNotification = NSNotification.Name(rawValue: "AssetListManagerDidLoadNotification")
  
  /// The internal array of Asset structs.
  private var assets: [Asset] = []
  
  // MARK: Initialization
  override private init() {
    super.init()
    
    /*
     Do not setup the AssetListManager.assets until AssetPersistenceManager has
     finished restoring.  This prevents race conditions where the `AssetListManager`
     creates a list of `Asset`s that doesn't reuse already existing `AVURLAssets`
     from existng `AVAssetDownloadTasks.
     */
    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(self, selector: #selector(handleAssetPersistenceManagerDidRestoreStateNotification(_:)), name: AssetPersistenceManager.persistenceManagerDidRestoreStateNotification, object: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: AssetPersistenceManager.persistenceManagerDidRestoreStateNotification, object: nil)
  }
  
  // MARK: Asset access
  
  /// Returns the number of Assets.
  func numberOfAssets() -> Int {
    return assets.count
  }
  
  /// Returns an Asset for a given IndexPath.
  func asset(at index: Int) -> Asset {
    return assets[index]
  }
  
  func handleAssetPersistenceManagerDidRestoreStateNotification(_ notification: Notification) {
    DispatchQueue.main.async {
      // Get the file path of the Streams.plist from the application bundle.
      guard let streamsFilepath = Bundle.main.path(forResource: "Streams", ofType: "plist") else { return }
      
      // Create an array from the contents of the Streams.plist file.
      guard let arrayOfStreams = NSArray(contentsOfFile: streamsFilepath) as? [[String: AnyObject]] else { return }
      
      // Iterate over each dictionary in the array.
      for entry in arrayOfStreams {
        // Get the Stream name from the dictionary
        guard let streamName = entry[Asset.Keys.name] as? String else { continue }
        
        // To ensure that we are reusing AVURLAssets we first find out if there is one available for an already active download.
        if let asset = AssetPersistenceManager.shared.assetForStream(withName: streamName) {
          self.assets.append(asset)
        } else {
          /*
           If an existing `AVURLAsset` is not available for an active
           download we then see if there is a file URL available to
           create an asset from.
           */
          if let asset = AssetPersistenceManager.shared.localAssetForStream(withName: streamName) {
            self.assets.append(asset)
          } else {
            // No instance of AVURLAsset exists for this stream, create new instance.
            guard let streamPlaylistURLString = entry["StreamPlaylistURL"] as? String else { continue }
            
            let streamPlaylistURL = URL(string: streamPlaylistURLString)!
            let asset = Asset(name: streamName, urlAsset: AVURLAsset(url: streamPlaylistURL))
            
            self.assets.append(asset)
          }
        }
      }
      
      NotificationCenter.default.post(name: AssetListManager.didLoadNotification, object: self)
    }
  }
}
