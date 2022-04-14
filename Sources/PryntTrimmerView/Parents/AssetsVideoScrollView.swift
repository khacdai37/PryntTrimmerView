//
//  AssetsVideoScrollView.swift
//  PryntTrimmerView
//
//  Created by Nguyen Khac Dai on 4/13/22.
//  Copyright © 2022 hhk. All rights reserved.
//

import UIKit
import AVKit

class AssetsVideoScrollView: UIScrollView {
  
  private var widthConstraint: NSLayoutConstraint?
  
  let contentView = UIView()
  public var maxDuration: Double = 15
  private var generator: AVAssetImageGenerator?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupSubviews()
  }
  
  private func setupSubviews() {
    
    backgroundColor = .clear
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false
    clipsToBounds = true
    
    contentView.backgroundColor = .clear
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.tag = -1
    addSubview(contentView)
    
    contentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    widthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0)
    widthConstraint?.isActive = true
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    contentSize = contentView.bounds.size
  }
  
  internal func regenerateThumbnails(for assets: [AVAsset]) {
    let totalDuration = assets.reduce(0.0) { x, y in
      x + y.duration.seconds
    }
    setContentSize(for: totalDuration)
    removeFormerThumbnails()
    generate(assets: assets)
  }
  
  func generate(assets: [AVAsset]) {
    guard let asset = assets.first, let thumbnailSize = getThumbnailFrameSize(from: asset), thumbnailSize.width != 0 else {
      print("Could not calculate the thumbnail size.")
      return
    }
    generator?.cancelAllCGImageGeneration()
    let newContentSize = estimateContentSize(for: asset.duration.seconds)
    let visibleThumbnailsCount = Int(ceil(frame.width / thumbnailSize.width))
    let thumbnailCount = Int(ceil(newContentSize.width / thumbnailSize.width))
    let numberOfCurrentThumbnail = contentView.subviews.count
    addThumbnailViews(thumbnailCount, size: thumbnailSize, initialIndex: numberOfCurrentThumbnail)
    let timesForThumbnail = getThumbnailTimes(for: asset, numberOfThumbnails: thumbnailCount)
    generateImages(for: asset, at: timesForThumbnail, with: thumbnailSize, visibleThumnails: visibleThumbnailsCount, initialIndex: numberOfCurrentThumbnail) {[weak self] success in
      if !success || assets.isEmpty {
        return
      }
      var newAssets = assets
      newAssets.removeFirst()
      self?.generate(assets: newAssets)
    }
  }
  
  private func getThumbnailFrameSize(from asset: AVAsset) -> CGSize? {
    guard let track = asset.tracks(withMediaType: AVMediaType.video).first else { return nil}
    
    let assetSize = track.naturalSize.applying(track.preferredTransform)
    
    let height = frame.height
    let ratio = assetSize.width / assetSize.height
    let width = height * ratio
    return CGSize(width: abs(width), height: abs(height))
  }
  
  private func removeFormerThumbnails() {
    contentView.subviews.forEach({ $0.removeFromSuperview() })
  }
  
  public var selectedDuration: Double = 15
  
  private func setContentSize(for duration: Double) {
    let contentWidthFactor = CGFloat(max(1, duration / selectedDuration))
    widthConstraint?.isActive = false
    widthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: contentWidthFactor)
    widthConstraint?.isActive = true
    layoutIfNeeded()
  }
  
  private func estimateContentSize(for duration: Double) -> CGSize {
    let contentWidthFactor = CGFloat(max(1, duration / selectedDuration))
    return CGSize(width: bounds.width * contentWidthFactor, height: bounds.height)
  }
  
  private func addThumbnailViews(_ count: Int, size: CGSize, initialIndex: Int = 0) {
    for i in 0..<count {
      let index = initialIndex + i
      let thumbnailView = UIImageView(frame: CGRect.zero)
      thumbnailView.clipsToBounds = true
      
      let viewEndX = CGFloat(index) * size.width + size.width
      
      if viewEndX > contentView.frame.width {
        thumbnailView.frame.size = CGSize(width: size.width + (contentView.frame.width - viewEndX), height: size.height)
        thumbnailView.contentMode = .scaleAspectFill
      } else {
        thumbnailView.frame.size = size
        thumbnailView.contentMode = .scaleAspectFit
      }
      let lastView = contentView.subviews.last?.frame.maxX ?? CGFloat(index) * size.width
      thumbnailView.frame.origin = CGPoint(x: lastView, y: 0)
      thumbnailView.tag = index
      //print("addThumbnailViews \(index): \(thumbnailView.frame.debugDescription)")
      contentView.addSubview(thumbnailView)
    }
  }
  
  private func getThumbnailTimes(for asset: AVAsset, numberOfThumbnails: Int) -> [NSValue] {
    getThumbnailTimes(for: asset.duration.seconds, numberOfThumbnails: numberOfThumbnails)
  }
  
  private func getThumbnailTimes(for seconds: Double, numberOfThumbnails: Int) -> [NSValue] {
    let timeIncrement = (seconds * 1000) / Double(numberOfThumbnails)
    var timesForThumbnails = [NSValue]()
    for index in 0..<numberOfThumbnails {
      let cmTime = CMTime(value: Int64(timeIncrement * Float64(index)), timescale: 1000)
      let nsValue = NSValue(time: cmTime)
      timesForThumbnails.append(nsValue)
    }
    return timesForThumbnails
  }
  
  private func generateImages(for asset: AVAsset, at times: [NSValue], with maximumSize: CGSize, visibleThumnails: Int, initialIndex: Int = 0, completion: ((Bool) -> ())? = nil) {
    generator = AVAssetImageGenerator(asset: asset)
    generator?.appliesPreferredTrackTransform = true
    
    let scaledSize = CGSize(width: maximumSize.width * UIScreen.main.scale, height: maximumSize.height * UIScreen.main.scale)
    generator?.maximumSize = scaledSize
    var count = initialIndex
    
    let handler: AVAssetImageGeneratorCompletionHandler = { [weak self] (_, cgimage, _, result, error) in
      if let cgimage = cgimage, error == nil && result == AVAssetImageGenerator.Result.succeeded {
        DispatchQueue.main.async(execute: { [weak self] () -> Void in
          if count == 0 {
            self?.displayFirstImage(cgimage, visibleThumbnails: visibleThumnails)
          }
          self?.displayImage(cgimage, at: count)
          count += 1
          if count == times.count {
            completion?(true)
          }
        })
      }else {
        DispatchQueue.main.async {
          completion?(false)
        }
      }
    }
    
    generator?.generateCGImagesAsynchronously(forTimes: times, completionHandler: handler)
  }
  
  private func displayFirstImage(_ cgImage: CGImage, visibleThumbnails: Int) {
    for i in 0...visibleThumbnails {
      displayImage(cgImage, at: i)
    }
  }
  
  private func displayImage(_ cgImage: CGImage, at index: Int) {
    if let imageView = contentView.viewWithTag(index) as? UIImageView {
      let uiimage = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImage.Orientation.up)
      imageView.image = uiimage
    }
  }
}
