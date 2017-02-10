//
//  AssetTableViewController.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/10/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class AssetTableViewController: UITableViewController {
  
  // MARK: Properties
  let cellReuseIdentifier = "assetCell"
  fileprivate var playerViewController: AVPlayerViewController?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(AssetTableViewCell.self, forCellReuseIdentifier: AssetTableViewCell.reuseIdentifier)
    
    tableView.estimatedRowHeight = 75.0
    tableView.rowHeight = UITableViewAutomaticDimension
    
    AssetPlaybackManager.shared.delegate = self
    NotificationCenter.default.addObserver(self, selector: #selector(handleAssetListManagerDidLoadNotification(_:)), name: AssetListManager.didLoadNotification, object: nil)
  }
  
  // MARK: Deinitialization
  deinit {
    NotificationCenter.default.removeObserver(self, name: AssetListManager.didLoadNotification, object: nil)
  }
  
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if playerViewController != nil {
      // The view reappeared as a results of dismissing an AVPlayerViewController.
      // Perform cleanup.
      AssetPlaybackManager.shared.setAssetForPlayback(nil)
      playerViewController?.player = nil
      playerViewController = nil
    }
  }
  
  // MARK: Notification handling
  func handleAssetListManagerDidLoadNotification(_: Notification) {
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }
}

// MARK: UITableView DataSource/Delegate Methods
extension AssetTableViewController {
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return AssetListManager.shared.numberOfAssets()
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: AssetTableViewCell.reuseIdentifier, for: indexPath)
    
    let asset = AssetListManager.shared.asset(at: indexPath.row)
    
    if let cell = cell as? AssetTableViewCell {
      cell.asset = asset
      cell.delegate = self
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) as? AssetTableViewCell, let asset = cell.asset else { return }
    let downloadState = AssetPersistenceManager.shared.downloadState(for: asset)
    let alertAction: UIAlertAction
    
    switch downloadState {
    case .notDownloaded:
      alertAction = UIAlertAction(title: "Download", style: .default) { _ in
        AssetPersistenceManager.shared.downloadStream(for: asset)
      }
    case .downloading:
      alertAction = UIAlertAction(title: "Cancel", style: .default) { _ in
        AssetPersistenceManager.shared.cancelDownload(for: asset)
      }
    case .downloaded:
      alertAction = UIAlertAction(title: "Delete", style: .default) { _ in
        AssetPersistenceManager.shared.deleteAsset(asset)
      }
    }
    
    let alertController = UIAlertController(title: asset.name, message: "Select from the following options:", preferredStyle: .actionSheet)
    alertController.addAction(alertAction)
    alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
    
    if UIDevice.current.userInterfaceIdiom == .pad {
      guard let popoverController = alertController.popoverPresentationController else {
        return
      }
      
      popoverController.sourceView = cell
      popoverController.sourceRect = cell.bounds
    }
    
    present(alertController, animated: true, completion: nil)
  }
}

// Extend `AssetTableViewController` to conform to the `AssetPlaybackDelegate` protocol.
extension AssetTableViewController: AssetPlaybackDelegate {
  func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerReadyToPlay player: AVPlayer) {
    player.play()
  }
  
  func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerCurrentItemDidChange player: AVPlayer) {
    guard let playerViewController = playerViewController, player.currentItem != nil else { return }
    playerViewController.player = player
  }
}

// Extend `AssetTableViewController` to conform to the `AssetTableViewCellDelegate` protocol.
extension AssetTableViewController: AssetTableViewCellDelegate {
  func assetTableViewCell(_ cell: AssetTableViewCell, downloadStateDidChange newState: Asset.DownloadState) {
    guard let indexPath = tableView.indexPath(for: cell) else { return }
    
    tableView.reloadRows(at: [indexPath], with: .automatic)
  }
}
