//
//  BMPlayerCustomControlView.swift
//  BMPlayer
//
//  Created by BrikerMan on 2017/4/4.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit
import BMPlayer
import CoreMedia
import AVFoundation

func _MKImageResourcePath(_ fileName: String) -> UIImage? {
    let bundle = Bundle(for: MKPlayer.self)
    return UIImage(named: fileName, in: bundle, compatibleWith: nil)
}

open class MKPlayerControlView: BMPlayerControlView {
    
    var playbackRateButton = BMRateButton()
    
    private var _playRate: Float = 1.0
    
    var playRate: Float {
        get {
            return _playRate
        }
        set {
            guard newValue > 0 else {
                return
            }
            _playRate = newValue
            playbackRateButton.updateUI(rate: _playRate)
        }
    }
    
    /**
     Override if need to customize UI components
     */
    open override func customizeUIComponents() {
        replayButton.setImage(_MKImageResourcePath("replay"), for: .normal)
        timeSlider.setThumbImage(_MKImageResourcePath("slider_thumb"), for: .normal)
        fullscreenButton.setImage(_MKImageResourcePath("por-to-lan"), for: .normal)
        fullscreenButton.setImage(_MKImageResourcePath("lan-to-por"), for: .selected)
        
        mainMaskView.backgroundColor   = UIColor.clear
        topMaskView.backgroundColor    = UIColor.black.withAlphaComponent(0.4)
        bottomMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        
        playbackRateButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onPlaybackRateButtonPressed)))
        
        bottomWrapperView.addSubview(playbackRateButton)
        
        playRate = 1.0
        
        // View to show when slide to seek
        seekToView.backgroundColor = .black.withAlphaComponent(0.4)
        seekToView.snp.remakeConstraints { [unowned self](make) in
            make.edges.equalTo(self)
        }
        seekToViewImage.contentMode = .scaleAspectFit
        seekToViewImage.image = _MKImageResourcePath("fast-forward")
        seekToViewImage.snp.remakeConstraints { [unowned self](make) in
            make.top.equalTo(self.seekToView.snp.centerY).offset(-22.5)
            make.centerX.equalTo(self.seekToView.snp.centerX)
            make.height.equalTo(24)
            make.width.equalTo(24)
        }
        
        seekToLabel.snp.remakeConstraints { [unowned self](make) in
            make.centerX.equalTo(self.seekToView.snp.centerX)
            make.bottom.equalTo(self.seekToView.snp.centerY).offset(22.5)
        }
        
        replayButton.snp.remakeConstraints { [unowned self](make) in
            make.center.equalTo(self.mainMaskView)
            make.width.height.equalTo(60)
        }
        
        _updateUI()
    }
    
    open override func updateUI(_ isForFullScreen: Bool) {
        super.updateUI(isForFullScreen)
        if let layer = player?.playerLayer {
            layer.frame = player!.bounds
        }
        _updateUI()
    }
    
    open override func reset() {
        super.reset()
        playRate = 1.0;
    }
    
    open override func controlViewAnimation(isShow: Bool) {
        controlViewAnimation(isShow: isShow, autoHidden: true)
    }
    
    open func controlViewAnimation(isShow: Bool, autoHidden: Bool) {
        delegate?.controlView?(controlView: self, controlViewWillAnimation: isShow)
        self.isMaskShowing = isShow
        if let vc = self.mk_viewController {
            let _ = vc.prefersStatusBarHidden
            vc.setNeedsStatusBarAppearanceUpdate()
        }
        
        UIView.animate(withDuration: 0.24, animations: {
            self.topMaskView.snp.remakeConstraints {
                $0.top.equalTo(self.mainMaskView).offset(isShow ? 0 : -65)
                $0.left.right.equalTo(self.mainMaskView)
                $0.height.equalTo(65)
            }
            self.bottomMaskView.snp.remakeConstraints {
                if isShow {
                    $0.bottom.equalTo(self.mainMaskView.snp.bottom)
                } else {
                    $0.top.equalTo(self.mainMaskView.snp.bottom)
                }
//                $0.bottom.equalTo(self.mainMaskView).offset(isShow ? 0 : 85)
                $0.left.right.equalTo(self.mainMaskView)
            }
            self.layoutIfNeeded()
        }) { (_) in
            if autoHidden {
                self.autoFadeOutControlViewWithAnimation()
            }
        }
    }
    
    @objc func onPlaybackRateButtonPressed() {
        autoFadeOutControlViewWithAnimation()
        BMRateMaskView.present(playRate) { [unowned self] newRate in
            self.playRate = newRate
            self.delegate?.controlView?(controlView: self, didChangeVideoPlaybackRate: playRate)
        }
    }
    
    func _updateUI() {
        if bottomMaskView.superview == nil {
            return
        }
        
        var text = currentTimeLabel.text as? NSString;
        if let textOK = text, textOK.contains("/") {
            text = textOK.components(separatedBy: "/").first as? NSString
        }
        if text == nil || text!.length == 0 {
            text = "00:00";
        }
        if isFullscreen {
            currentTimeLabel.text = text as! String
        } else {
            currentTimeLabel.text = "\(text!)/" + (totalTimeLabel.text ?? "")
        }
        // Bottom views
        if isFullscreen {
            bottomWrapperView.snp.remakeConstraints { [unowned self](make) in
                make.height.equalTo(50)
                if #available(iOS 11.0, *) {
                  make.bottom.left.right.equalTo(self.bottomMaskView.safeAreaLayoutGuide)
                  make.top.equalToSuperview()
                } else {
                  make.edges.equalToSuperview()
                }
            }
            
            totalTimeLabel.isHidden = false
            currentTimeLabel.textAlignment = .center;
            
            playButton.snp.remakeConstraints { (make) in
                make.width.equalTo(50)
                make.height.equalTo(50)
                make.left.bottom.equalToSuperview()
            }
            
            currentTimeLabel.snp.remakeConstraints { [unowned self](make) in
                make.left.equalTo(self.playButton.snp.right)
                make.centerY.equalTo(self.playButton)
                make.width.equalTo(40)
            }
            
            progressView.snp.remakeConstraints { [unowned self](make) in
                make.centerY.equalTo(self.currentTimeLabel)
                make.left.equalTo(self.currentTimeLabel.snp.right).offset(10).priority(750)
                make.height.equalTo(2)
            }
            
            timeSlider.snp.remakeConstraints { [unowned self](make) in
                make.centerY.left.right.equalTo(self.progressView)
                make.height.equalTo(30)
            }
            
            totalTimeLabel.snp.remakeConstraints { [unowned self](make) in
                make.centerY.equalTo(self.currentTimeLabel)
                make.left.equalTo(self.progressView.snp.right).offset(8)
                make.width.equalTo(40)
            }
            
            fullscreenButton.snp.remakeConstraints { [unowned self](make) in
                make.width.equalTo(fullscreenButton.isHidden ? 0 : 50)
                make.height.equalTo(50)
                make.centerY.equalTo(self.playButton)
                make.right.equalToSuperview()
            }
            
            playbackRateButton.snp.remakeConstraints { [unowned self](make) in
                make.width.equalTo(playbackRateButton.isHidden ? 0 : 50)
                make.height.equalTo(50)
                make.centerY.equalTo(self.playButton)
                make.left.equalTo(self.totalTimeLabel.snp.right)
                make.right.equalTo(self.fullscreenButton.snp.left)
            }
        } else {
            totalTimeLabel.isHidden = true
            totalTimeLabel.snp.removeConstraints()
            currentTimeLabel.textAlignment = .left;
            
            bottomWrapperView.snp.remakeConstraints { [unowned self](make) in
                make.height.equalTo(62)
                if #available(iOS 11.0, *) {
                  make.bottom.left.right.equalTo(self.bottomMaskView.safeAreaLayoutGuide)
                  make.top.equalToSuperview()
                } else {
                  make.edges.equalToSuperview()
                }
            }
            
            progressView.snp.remakeConstraints { [unowned self](make) in
                make.centerY.equalTo(2 + 15)
                make.left.equalToSuperview().offset(15)
                make.right.equalToSuperview().offset(-15)
                make.height.equalTo(2)
            }
            
            timeSlider.snp.remakeConstraints { [unowned self](make) in
                make.centerY.left.right.equalTo(self.progressView)
                make.height.equalTo(30)
            }
            
            playButton.snp.remakeConstraints { (make) in
                make.width.equalTo(40)
                make.height.equalTo(40)
                make.left.equalToSuperview().offset(1)
                make.bottom.equalToSuperview()
            }
            
            currentTimeLabel.snp.remakeConstraints { [unowned self](make) in
                make.left.equalTo(self.playButton.snp.right)
                make.centerY.equalTo(self.playButton)
                make.width.equalTo(100)
            }
            
            fullscreenButton.snp.remakeConstraints { [unowned self](make) in
                make.width.equalTo(fullscreenButton.isHidden ? 0 : 50)
                make.height.equalTo(30)
                make.centerY.equalTo(self.playButton)
                make.right.equalToSuperview()
            }
            
            playbackRateButton.snp.remakeConstraints { [unowned self](make) in
                make.width.equalTo(playbackRateButton.isHidden ? 0 : 50)
                make.height.equalTo(30)
                make.centerY.equalTo(self.playButton)
                if fullscreenButton.isHidden {
                    make.right.equalToSuperview().offset(-14)
                } else {
                    make.right.equalTo(self.fullscreenButton.snp.left)
                }
            }
        }
    }
    
    open override func updateCurrentTimeLabel(_ toSecound: TimeInterval) {
        let time0 = BMPlayer.formatSecondsToString(toSecound)
        if isFullscreen {
            currentTimeLabel.text = time0
        } else {
            currentTimeLabel.text = "\(time0)/" + (totalTimeLabel.text ?? "")
        }
    }
    
    open override func showSeekToView(to toSecound: TimeInterval, total totalDuration: TimeInterval, isAdd: Bool) {
        super.showSeekToView(to: toSecound, total: totalDuration, isAdd: isAdd)
        seekToLabel.text = "\(BMPlayer.formatSecondsToString(toSecound))/\(BMPlayer.formatSecondsToString(totalDuration))"
    }
}

extension UIView {
    var mk_viewController: UIViewController? {
        get {
            var next: UIResponder? = self.next
            while next != nil {
                guard let nextOK = next else { return nil }
                if nextOK.isKind(of: UIViewController.self) {
                    return nextOK as? UIViewController
                }
                next = nextOK.next
            }
            return nil
        }
    }
}
