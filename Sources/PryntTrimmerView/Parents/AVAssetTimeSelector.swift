//
//  AVAssetTimeSelector.swift
//  Pods
//
//  Created by Henry on 06/04/2017.
//
//

import UIKit
import AVFoundation

/// A generic class to display an asset into a scroll view with thumbnail images, and make the equivalence between a time in
// the asset and a position in the scroll view
public class AVAssetTimeSelector: UIView, UIScrollViewDelegate {
  
  let assetPreview = AssetsVideoScrollView()
  
  /// The maximum duration allowed for the trimming. Change it before setting the asset, as the asset preview
  public var maxDuration: Double = 15 {
    didSet {
      assetPreview.maxDuration = maxDuration
    }
  }
  
  public var selectedDuration: Double = 15 {
    didSet {
      assetPreview.selectedDuration = selectedDuration
    }
  }
  
  public var assets: [AVAsset]? {
    didSet {
      assetDidChange(newAssets: assets)
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupSubviews()
  }
  
  func setupSubviews() {
    setupAssetPreview()
    constrainAssetPreview()
  }
  
  public func regenerateThumbnails() {
    if let assets = assets {
      assetPreview.regenerateThumbnails(for: assets)
    }
  }
  
  // MARK: - Asset Preview
  
  func setupAssetPreview() {
    self.translatesAutoresizingMaskIntoConstraints = false
    assetPreview.translatesAutoresizingMaskIntoConstraints = false
    assetPreview.delegate = self
    addSubview(assetPreview)
  }
  
  func constrainAssetPreview() {
    assetPreview.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    assetPreview.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    assetPreview.topAnchor.constraint(equalTo: topAnchor).isActive = true
    assetPreview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
  }
  
  func assetDidChange(newAssets: [AVAsset]?) {
    if let assets = newAssets {
      assetPreview.regenerateThumbnails(for: assets)
    }
  }
  
  // MARK: - Time & Position Equivalence
  
  var durationSize: CGFloat {
    return assetPreview.contentSize.width
  }
  
  func getTime(from position: CGFloat) -> CMTime? {
    guard let assets = assets, let timescale = assets.first?.duration.timescale  else {
      return nil
    }
    let durations = assets.reduce(0) { partialResult, asset in
      partialResult + Double(asset.duration.value)
    }
    let normalizedRatio = max(min(1, position / durationSize), 0)
    let positionTimeValue = Double(normalizedRatio) * durations
    return CMTime(value: Int64(positionTimeValue), timescale: timescale)
  }
  
  func getPosition(from time: CMTime) -> CGFloat? {
    guard let assets = assets, let timescale = assets.first?.duration.timescale  else {
      return nil
    }
    let durations = assets.reduce(0) { partialResult, asset in
      partialResult + Double(asset.duration.value)
    }
    let timeRatio = CGFloat(time.value) * CGFloat(timescale) /
    (CGFloat(time.timescale) * CGFloat(durations))
    return timeRatio * durationSize
  }
  
  public func scrollToTime(_ second: Double) {
    guard let asset = assets?.first else {
      return
    }
    let time = CMTime(seconds: second, preferredTimescale: asset.duration.timescale)
    let positionX = getPosition(from: time) ?? 0
    assetPreview.setContentOffset(CGPoint(x: positionX, y: 0), animated: false)
  }
}
