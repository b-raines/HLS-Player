//
//  AssetPersistenceManager.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/10/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import Foundation
import AVFoundation

class AssetPersistenceManager: NSObject {
  
  // MARK: Properties
  static let shared = AssetPersistenceManager()
  
  /// downloadProgressNotificationNotification for when download progress has changed.
  static let downloadProgressNotification: NSNotification.Name = NSNotification.Name(rawValue: "AssetDownloadProgressNotification")
  
  /// Notification for when the download state of an Asset has changed.
  static let downloadStateChangedNotification: NSNotification.Name = NSNotification.Name(rawValue: "AssetDownloadStateChangedNotification")
  
  /// Notification for when AssetPersistenceManager has completely restored its state.
  static let persistenceManagerDidRestoreStateNotification: NSNotification.Name = NSNotification.Name(rawValue: "AssetPersistenceManagerDidRestoreStateNotification")
  
  /// Internal Bool used to track if the AssetPersistenceManager finished restoring its state.
  private var didRestorePersistenceManager = false
  
  /// The AVAssetDownloadURLSession to use for managing AVAssetDownloadTasks.
  fileprivate var assetDownloadURLSession: AVAssetDownloadURLSession!
  
  /// Internal map of AVAssetDownloadTask to its corresponding Asset.
  fileprivate var activeDownloadsMap: [AVAssetDownloadTask: Asset] = [:]
  
  fileprivate let baseDownloadURL = URL(fileURLWithPath: NSHomeDirectory())
  fileprivate let userDefaults = UserDefaults.standard
  
  // MARK: Intialization
  override private init() {
    super.init()
    
    // Create AVAssetDownloadURLSession using background URLSessionConfiguration.
    let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "HLS-backgroundDownload")
    assetDownloadURLSession = AVAssetDownloadURLSession(configuration: backgroundConfiguration, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
  }
  
  /// Restores the Application state by getting all the AVAssetDownloadTasks and restoring their Asset structs.
  func restorePersistenceManager() {
    guard !didRestorePersistenceManager else { return }
    
    didRestorePersistenceManager = true
    
    // Grab all the tasks associated with the assetDownloadURLSession
    assetDownloadURLSession.getAllTasks { tasksArray in
      // For each task, restore the state in the app by recreating Asset structs and reusing existing AVURLAsset objects.
      for task in tasksArray {
        guard let assetDownloadTask = task as? AVAssetDownloadTask, let assetName = task.taskDescription else { break }
        
        let asset = Asset(name: assetName, urlAsset: assetDownloadTask.urlAsset)
        self.activeDownloadsMap[assetDownloadTask] = asset
      }
      
      NotificationCenter.default.post(name: AssetPersistenceManager.persistenceManagerDidRestoreStateNotification, object: nil)
    }
  }
  
  /// Triggers the initial AVAssetDownloadTask for a given Asset.
  func downloadStream(for asset: Asset) {
    guard let task = assetDownloadURLSession.makeAssetDownloadTask(asset: asset.urlAsset, assetTitle: asset.name, assetArtworkData: nil, options: nil) else { return }
    
    // To better track the AVAssetDownloadTask we set the taskDescription to something unique for our sample.
    task.taskDescription = asset.name
    
    activeDownloadsMap[task] = asset
    
    task.resume()
    
    let userInfo = [
      Asset.Keys.name: asset.name,
      Asset.Keys.downloadState: Asset.DownloadState.downloading.rawValue
    ]
    
    NotificationCenter.default.post(name: AssetPersistenceManager.downloadStateChangedNotification, object: nil, userInfo:  userInfo)
  }
  
  /// Returns an Asset given a specific name if that Asset is associated with an active download.
  func assetForStream(withName name: String) -> Asset? {
    for (_, assetValue) in activeDownloadsMap {
      if name == assetValue.name {
        return assetValue
      }
    }
    
    return nil
  }
  
  /// Returns an Asset pointing to a file on disk if it exists.
  func localAssetForStream(withName name: String) -> Asset? {
    guard let localFileLocation = userDefaults.value(forKey: name) as? String else { return nil }
    let url = baseDownloadURL.appendingPathComponent(localFileLocation)
    
    return Asset(name: name, urlAsset: AVURLAsset(url: url))
  }
  
  /// Returns the current download state for a given Asset.
  func downloadState(for asset: Asset) -> Asset.DownloadState {
    // Check if there is a file URL stored for this asset.
    if let localFileLocation = userDefaults.value(forKey: asset.name) as? String {
      // Check if the file exists on disk
      let localFilePath = baseDownloadURL.appendingPathComponent(localFileLocation).path
      
      if localFilePath == baseDownloadURL.path {
        return .notDownloaded
      }
      
      if FileManager.default.fileExists(atPath: localFilePath) {
        return .downloaded
      }
    }
    
    // Check if there are any active downloads in flight.
    for (_, assetValue) in activeDownloadsMap {
      if asset.name == assetValue.name {
        return .downloading
      }
    }
    
    return .notDownloaded
  }
  
  /// Deletes an Asset on disk if possible.
  func deleteAsset(_ asset: Asset) {
    do {
      if let localFileLocation = userDefaults.value(forKey: asset.name) as? String {
        let localFileLocation = baseDownloadURL.appendingPathComponent(localFileLocation)
        try FileManager.default.removeItem(at: localFileLocation)
        
        userDefaults.removeObject(forKey: asset.name)
        
        let userInfo = [
          Asset.Keys.name: asset.name,
          Asset.Keys.downloadState: Asset.DownloadState.notDownloaded.rawValue
        ]
        
        NotificationCenter.default.post(name: AssetPersistenceManager.downloadStateChangedNotification, object: nil, userInfo:  userInfo)
      }
    } catch {
      print("An error occured deleting the file: \(error)")
    }
  }
  
  /// Cancels an AVAssetDownloadTask given an Asset.
  func cancelDownload(for asset: Asset) {
    for (taskKey, assetVal) in activeDownloadsMap {
      if asset == assetVal  {
        taskKey.cancel()
        break
      }
    }
  }
}

// MARK: AVAssetDownloadDelegate
extension AssetPersistenceManager: AVAssetDownloadDelegate {
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let task = task as? AVAssetDownloadTask , let asset = activeDownloadsMap.removeValue(forKey: task) else { return }
    
    // Prepare the basic userInfo dictionary that will be posted as part of our notification.
    var userInfo = [Asset.Keys.name: asset.name]
    
    if let error = error as? NSError {
      switch (error.domain, error.code) {
      case (NSURLErrorDomain, NSURLErrorCancelled):
        // Task was cancelled. Perform cleanup using URL from urlSession(_:assetDownloadTask:didFinishDownloadingTo:)
        guard let localFileLocation = userDefaults.value(forKey: asset.name) as? String else { return }
        do {
          let fileURL = baseDownloadURL.appendingPathComponent(localFileLocation)
          try FileManager.default.removeItem(at: fileURL)
          userDefaults.removeObject(forKey: asset.name)
        } catch {
          print("An error occured trying to delete the contents on disk for \(asset.name): \(error)")
        }
        
        userInfo[Asset.Keys.downloadState] = Asset.DownloadState.notDownloaded.rawValue
      case (NSURLErrorDomain, NSURLErrorUnknown):
        fatalError("Downloading HLS streams is not supported in the simulator.")
      default:
        fatalError("An unexpected error occured \(error.domain)")
      }
    } else {
      // Stream successfully finished downloading
      userInfo[Asset.Keys.downloadState] = Asset.DownloadState.downloaded.rawValue
    }
    
    NotificationCenter.default.post(name: AssetPersistenceManager.downloadStateChangedNotification, object: nil, userInfo: userInfo)
  }
  
  func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
    // Store relative path for asset in user defaults.
    if let asset = activeDownloadsMap[assetDownloadTask] {
      userDefaults.set(location.relativePath, forKey: asset.name)
    }
  }
  
  func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
    // This delegate callback should be used to provide download progress for your AVAssetDownloadTask.
    guard let asset = activeDownloadsMap[assetDownloadTask] else { return }
    
    let totalTimeLoaded = loadedTimeRanges
      .map({ CMTimeGetSeconds($0.timeRangeValue.duration) })
      .reduce(0.0, +)
    
    let percentComplete = totalTimeLoaded / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
    let userInfo: [String: Any] = [
      Asset.Keys.name: asset.name,
      Asset.Keys.percentDownloaded: percentComplete
    ]
    
    NotificationCenter.default.post(name: AssetPersistenceManager.downloadProgressNotification, object: nil, userInfo:  userInfo)
  }
}
