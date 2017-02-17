//
//  CourseTableViewController.swift
//  HLS-Player
//
//  Created by Brent Raines on 2/10/17.
//  Copyright © 2017 Brent Raines. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class CourseTableViewController: UITableViewController {
  
  // MARK: Properties
  fileprivate let viewModel = CourseViewModel.withSampleData()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.register(CourseSessionTableViewCell.self, forCellReuseIdentifier: CourseSessionTableViewCell.reuseIdentifier)
    tableView.estimatedRowHeight = 75.0
    tableView.rowHeight = UITableViewAutomaticDimension
  }
  
  // MARK: Deinitialization
  deinit {
    NotificationCenter.default.removeObserver(self, name: AssetListManager.didLoadNotification, object: nil)
  }
}

// MARK: UITableView DataSource/Delegate Methods
extension CourseTableViewController {
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.courseSessions.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CourseSessionTableViewCell.reuseIdentifier, for: indexPath)
    
    if let cell = cell as? CourseSessionTableViewCell {
      cell.courseSession = viewModel.courseSessions[indexPath.row]
      cell.delegate = self
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) as? CourseSessionTableViewCell else { return }
    guard let meditation = cell.courseSession?.meditation else { return }
    
    let meditationVC = MeditationViewController(viewModel: meditation)
    navigationController?.pushViewController(meditationVC, animated: true)
  }

  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) as? CourseSessionTableViewCell, let asset = cell.asset else { return }
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

// Extend `CourseTableViewController` to conform to the `CourseSessionTableViewCellDelegate` protocol.
extension CourseTableViewController: CourseSessionTableViewCellDelegate {
  func courseSessionTableViewCell(_ cell: CourseSessionTableViewCell, downloadStateDidChange newState: Asset.DownloadState) {
    guard let indexPath = tableView.indexPath(for: cell) else { return }
    tableView.reloadRows(at: [indexPath], with: .automatic)
  }
}
