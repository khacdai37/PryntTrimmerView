//
//  ViewController.swift
//  PryntTrimmerView
//
//  Created by Henry on 27/03/2017.
//  Copyright © 2017 Prynt. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import PryntTrimmerView

/// A view controller to demonstrate the trimming of a video. Make sure the scene is selected as the initial
// view controller in the storyboard
class VideoTrimmerViewController: AssetSelectionViewController {
  
  @IBOutlet weak var selectAssetButton: UIButton!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var playerView: UIView!
  @IBOutlet weak var trimmerView: TrimmerView!
  
  var player: AVQueuePlayer?
  var playbackTimeCheckerTimer: Timer?
  var trimmerPositionChangedTimer: Timer?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    trimmerView.handleColor = UIColor.white
    trimmerView.mainColor = UIColor.darkGray
  }
  
  @IBAction func selectAsset(_ sender: Any) {
//    loadAssetRandomly()
    let url1 = Bundle.main.url(forResource: "portraitVideo", withExtension: "mp4")!
    let url2 = Bundle.main.url(forResource: "video1", withExtension: "MOV")!
    let assets = [AVAsset(url: url1), AVAsset(url: url2)]
                  
    trimmerView.maxDuration = assets.reduce(0, { partialResult, asset in
      partialResult + asset.duration.seconds
    })
    
    trimmerView.selectedDuration = trimmerView.maxDuration
    
    trimmerView.assets = assets
    trimmerView.delegate = self
    addVideoPlayer(with: assets, playerView: playerView)
    
    print("loadAsset: \(trimmerView.endTime!.seconds) - \(trimmerView.startTime!.seconds)")
  }
  
  @IBAction func play(_ sender: Any) {
    
    guard let player = player else { return }
    
    if !player.isPlaying {
      player.play()
      startPlaybackTimeChecker()
    } else {
      player.pause()
      stopPlaybackTimeChecker()
    }
  }
  
  override func loadAsset(_ asset: AVAsset) {
    
//    trimmerView.asset = asset
//    trimmerView.delegate = self
//    addVideoPlayer(with: asset, playerView: playerView)
    
//    trimmerView.selectedDuration = 4
//    trimmerView.regenerateThumbnails()
//    trimmerView.scrollToTime(8)
    
  }
  
  private func addVideoPlayer(with assets: [AVAsset], playerView: UIView) {
    let playerItems = assets.map { asset -> AVPlayerItem in
      let item = AVPlayerItem(asset: asset)
      NotificationCenter.default.addObserver(self, selector: #selector(VideoTrimmerViewController.itemDidFinishPlaying(_:)),
                                             name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
      return item
    }
    player = AVQueuePlayer(items: playerItems)
    
    let layer: AVPlayerLayer = AVPlayerLayer(player: player)
    layer.backgroundColor = UIColor.white.cgColor
    layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
    layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
    playerView.layer.addSublayer(layer)
  }
  
  @objc func itemDidFinishPlaying(_ notification: Notification) {
    guard let item = notification.object as? AVPlayerItem else {
      return
    }
//    player?.insert(item, after: nil)
    if let startTime = trimmerView.startTime {
      player?.seek(to: startTime)
      if (player?.isPlaying != true) {
        player?.play()
      }
    }
  }
  
  func startPlaybackTimeChecker() {
    
    stopPlaybackTimeChecker()
    playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                                    selector:
                                                      #selector(VideoTrimmerViewController.onPlaybackTimeChecker), userInfo: nil, repeats: true)
  }
  
  func stopPlaybackTimeChecker() {
    
    playbackTimeCheckerTimer?.invalidate()
    playbackTimeCheckerTimer = nil
  }
  
  @objc func onPlaybackTimeChecker() {
    
    guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = player else {
      return
    }
    
    let playBackTime = player.currentTime()
    trimmerView.seek(to: playBackTime)
    
    if playBackTime >= endTime {
      player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
      trimmerView.seek(to: startTime)
    }
  }
}

extension VideoTrimmerViewController: TrimmerViewDelegate {
  func positionBarStoppedDrag(_ playerTime: CMTime) {
    let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
//    trimmerView.selectedDuration = duration
//    trimmerView.regenerateThumbnails()
//    trimmerView.resetHandleViewPosition()
//    trimmerView.scrollToTime(playerTime.seconds)
    print("positionBarStoppedMoving: second \(playerTime.seconds) - \(duration)")
  }
  
  func positionBarStoppedMoving(_ playerTime: CMTime) {
    player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    player?.play()
    startPlaybackTimeChecker()
  }
  
  func didChangePositionBar(_ playerTime: CMTime) {
    stopPlaybackTimeChecker()
    player?.pause()
    player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
    print("endTime: \(trimmerView.endTime!.seconds) startTime: \(trimmerView.startTime!.seconds)")
    print(duration)
  }
}
