//
//  BMCustomPlayer.swift
//  BMPlayer
//
//  Created by Aqua on 2017/5/6.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit
import BMPlayer
import NVActivityIndicatorView
import AVFoundation

/**
 Player status emun
 
 - notSetURL:      not set url yet
 - readyToPlay:    player ready to play
 - buffering:      player buffering
 - bufferFinished: buffer finished
 - playedToTheEnd: played to the End
 - error:          error with playing
 */
@objc public enum MKPlayerState: Int {
    case notSetURL          // = BMPlayerState.notSetURL
    case readyToPlay        // = BMPlayerState.readyToPlay
    case buffering          // = BMPlayerState.buffering
    case bufferFinished     // = BMPlayerState.bufferFinished
    case playedToTheEnd     // = BMPlayerState.playedToTheEnd
    case error              // = BMPlayerState.error
}

open class KKKPlayer : NSObject {
    
    @objc func aaaa() {
        
    }
}

open class MMPlayer : BMPlayer {
    
    @objc func aaaa() {
        
    }
}

@objc public protocol MKPlayerDelegate : class {
    @objc optional
    func mkPlayer(player: AnyObject, playerStateDidChange state: MKPlayerState)
    
    @objc optional
    func mkPlayer(player: AnyObject, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
    
    @objc optional
    func mkPlayer(player: AnyObject, playTimeDidChange currentTime : TimeInterval, totalTime: TimeInterval)
    
    @objc optional
    func mkPlayer(player: AnyObject, playerIsPlaying playing: Bool)
    
    @objc optional
    func mkPlayer(player: AnyObject, playerOrientChanged isFullscreen: Bool)
    
    @objc optional
    func mkPlayer(player: AnyObject, didSeek currentTime : TimeInterval, totalTime: TimeInterval)
    
    @objc optional
    func mkPlayer(player: AnyObject, controlViewWillAnimation isShow: Bool)
    
}

@objcMembers open class MKPlayer: BMPlayer {
    
    open weak var playerDelegate: MKPlayerDelegate?
    
    open var backButtonBlock: ((Bool) -> Void)?
        
    fileprivate var maxSeekTo: TimeInterval {
        get {
            return resource.maxSeekToLocation ?? 0
        }
        set {
            resource.maxSeekToLocation = newValue
        }
    }

    open var volume: Float {
        get {
            return self.volumeViewSlider.value
        }
        set {
            self.volumeViewSlider.value = newValue
        }
    }
    
    open var enableReplayButton = true {
        didSet {
            self.controlView.replayButton.alpha = enableReplayButton ? 1 : 0
        }
    }
    
    open var enableFullScreenButton = true {
        didSet {
            self.controlView.fullscreenButton.isHidden = !enableFullScreenButton
            self.controlView.updateUI(self.controlView.isFullscreen)
        }
    }
    
    open var enablePlaybackRateButton = true {
        didSet {
            (self.controlView as? MKPlayerControlView)?.playbackRateButton.isHidden = !enablePlaybackRateButton
            self.controlView.updateUI(self.controlView.isFullscreen)
        }
    }
    
    open var enableTapGesture = true {
        didSet {
            self.controlView.tapGesture.isEnabled = enableTapGesture
        }
    }
    
    open var enableDoubleTapGesture = true {
        didSet {
            self.controlView.doubleTapGesture.isEnabled = enableDoubleTapGesture
        }
    }
    
    open var isMaskShowing: Bool {
        get {
            controlView.isMaskShowing
        }
    }
    
    private var tmpOrientation: UIInterfaceOrientation = .unknown
    
    public static func player() -> MKPlayer {
        return MKPlayer(customControlView: MKPlayerControlView())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(customControlView: BMPlayerControlView?) {
        
        BMPlayerConf.allowLog = false
        BMPlayerConf.shouldAutoPlay = false
        BMPlayerConf.topBarShowInCase = .none
        BMPlayerConf.tintColor = UIColor.white
        BMPlayerConf.loaderType  = NVActivityIndicatorType.ballRotateChase
        
        super.init(customControlView: customControlView)
        
        self.delegate = self
        self.backBlock = { [unowned self] (isFullScreen) in
            self.backButtonBlock?(isFullScreen)
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    open override func storyBoardCustomControl() -> BMPlayerControlView? {
        return MKPlayerControlView()
    }
    
    
    @objc func applicationWillResignActive() {
        guard isPlaying else {
            return
        }
        pause(allowAutoPlay: true)
    }
    
    @objc func applicationDidBecomeActive() {
        autoPlay()
    }
    
    @objc func applicationWillEnterForeground() {
        self.setOrientation(ori: tmpOrientation)
    }
    
    @objc func applicationDidEnterBackground() {
        tmpOrientation = UIApplication.shared.statusBarOrientation
    }
    
    open override func prepareToDealloc() {
        super.prepareToDealloc()
        NotificationCenter.default.removeObserver(self)
    }
    
    
    open func controlViewAnimation(isShow: Bool) {
        controlView.controlViewAnimation(isShow: isShow)
    }
    
    open func setVideoURL(_ url: NSURL) {
        setVideo(resource: BMPlayerResource(url: url as URL))
    }
    
    open func setVideoURL(_ url: NSURL, maxSeekToLocation: Double) {
        let resource = BMPlayerResource(url: url as URL)
        resource.maxSeekToLocation = maxSeekToLocation
        setVideo(resource: resource)
    }
    
    open func setVideoAsset(_ asset: AVAsset) {
        if asset == nil {
            return
        }
        let definition = BMPlayerResourceDefinition(asset: asset, definition: "")
        let resource = BMPlayerResource(name: "", definitions: [definition], cover: nil, subtitles: nil)
        setVideo(resource: resource)
    }
    
    open var hasSetVideo: Bool {
        get {
            return resource != nil
        }
    }
    
    open func showCover(_ cover: UIImage) {
        controlView.maskImageView.contentMode = .scaleAspectFit
        controlView.maskImageView.image = cover
        controlView.hideLoader()
        controlView.maskImageView.isHidden = false
    }
    
    open override func resetPlayer() {
        super.resetPlayer()
    }
    
    open func setSeek(shouldSeekTo: TimeInterval) {
        self.shouldSeekTo = shouldSeekTo
    }
    
    open func setSeek(shouldSeekTo: TimeInterval, maxSeekTo: TimeInterval) {
        resource.maxSeekToLocation = maxSeekTo >= 0 ? max(shouldSeekTo, maxSeekTo) : nil
        self.shouldSeekTo = shouldSeekTo
    }
    
    open override func autoPlay() {
        super.autoPlay()
    }
    
    open override func play() {
        super.play()
    }
    
    open override func pause(allowAutoPlay allow: Bool = false) {
        super.pause(allowAutoPlay: allow)
    }
    
    open override var isPlaying: Bool {
        get {
            super.isPlaying
        }
    }
    
    open var state: MKPlayerState = .notSetURL
    
    var audioCoverView: MKAudioCoverView?
    
    open var isAudio = false {
        didSet {
            let controlView = self.controlView as? MKPlayerControlView
            
            guard isAudio else {
                setPanGestureEnabled(true)
                controlView?.fullscreenButton.isHidden = false
                controlView?.playbackRateButton.isHidden = false
                audioCoverView?.removeFromSuperview()
                audioCoverView = nil
                return
            }
            setPanGestureEnabled(false)
            controlView?.fullscreenButton.isHidden = true
            controlView?.playbackRateButton.isHidden = true
            if audioCoverView == nil {
                audioCoverView = MKAudioCoverView()
            }
            if audioCoverView?.superview == nil {
                insertSubview(audioCoverView!, belowSubview: self.controlView)
                audioCoverView?.snp.makeConstraints({ make in
                    make.edges.equalTo(self)
                })
            }
        }
    }
    
    open func setPanGestureEnabled(_ isEnabled: Bool) {
        guard isEnabled == false else {
            guard let _ = self.gestureRecognizers else { return }
            if self.gestureRecognizers!.contains(panGesture) == false {
                self.removeGestureRecognizer(panGesture)
            }
            return
        }
        self.removeGestureRecognizer(panGesture)
    }
    
    deinit {
        self.prepareToDealloc()
    }
    
    open func controlViewAnimation(isShow: Bool, autoHidden: Bool) {
        (controlView as? MKPlayerControlView)?.controlViewAnimation(isShow: isShow, autoHidden: autoHidden)
    }
}

extension MKPlayer: BMPlayerDelegate {
    
    public func bmPlayer(player: BMPlayer, playerStateDidChange state: BMPlayerState) {
        var mkState: MKPlayerState
        switch state {
        case .notSetURL:
            mkState = .notSetURL
        case .readyToPlay:
            mkState = .readyToPlay
        case .buffering:
            mkState = .buffering
        case .bufferFinished:
            mkState = .bufferFinished
        case .playedToTheEnd:
            mkState = .playedToTheEnd
            if enableReplayButton == false {
                seek(0, completion: { })
            }
        case .error:
            mkState = .error
        }
        self.state = mkState;
        playerDelegate?.mkPlayer?(player: self, playerStateDidChange: mkState)
    }
    
    public func bmPlayer(player: BMPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        playerDelegate?.mkPlayer?(player: self, loadedTimeDidChange: loadedDuration, totalDuration: totalDuration)
    }
    
    public func bmPlayer(player: BMPlayer, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
        if let maxSeekToLocation = resource?.maxSeekToLocation {
            if currentTime > maxSeekToLocation {
                resource?.maxSeekToLocation = currentTime
            }
        }
        playerDelegate?.mkPlayer?(player: self, playTimeDidChange: currentTime, totalTime: totalTime)
    }
    
    public func bmPlayer(player: BMPlayer, playerIsPlaying playing: Bool) {
        if playing {
            audioCoverView?.resume()
        } else {
            audioCoverView?.stop()
        }
        playerDelegate?.mkPlayer?(player: self, playerIsPlaying: playing)
    }
    
    public func bmPlayer(player: BMPlayer, playerOrientChanged isFullscreen: Bool) {
        playerDelegate?.mkPlayer?(player: self, playerOrientChanged: isFullscreen)
    }
    
    public func bmPlayer(player: BMPlayer, didSeek currentTime: TimeInterval, totalTime: TimeInterval) {
        playerDelegate?.mkPlayer?(player: self, didSeek: currentTime, totalTime: totalTime)
    }
    
    public func bmPlayer(player: BMPlayer, controlViewWillAnimation isShow: Bool) {
        if isShow {
            guard let controlView = controlView as? MKPlayerControlView else {
                return
            }
            controlView.playRate = self.playerLayer?.player?.rate ?? 1.0
        }
        playerDelegate?.mkPlayer?(player: self, controlViewWillAnimation: isShow)
    }
}

class MKAudioCoverView: UIView {
    
    let imageView = UIImageView(image: _MKImageResourcePath("audio"))
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(hex: 0x252425)
        
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(200)
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)
        }
    }
    // 添加旋转动画
    func addTransformAnimated() {
        let ani = CABasicAnimation(keyPath: "transform.rotation.z")
        ani.fromValue     = 0;
        ani.toValue       = Double.pi * 2
        ani.duration      = 40
        ani.autoreverses  = false
        ani.repeatCount   = MAXFLOAT
        ani.isRemovedOnCompletion = false
        imageView.layer.add(ani, forKey: "audio")
    }
    
    // 停止旋转
    func stop() {
        if imageView.layer.speed == 0 {
            return
        }
        // 保存时间，恢复旋转需要用到
        let pausedTime = imageView.layer.convertTime(CACurrentMediaTime(), from: nil)
        imageView.layer.speed = 0
        imageView.layer.timeOffset = pausedTime
    }
    
    // 恢复旋转
    func resume() {
        if imageView.layer.timeOffset == 0 {
            addTransformAnimated()
            return
        }
        let pausedTime = imageView.layer.timeOffset
        imageView.layer.speed = 1
        imageView.layer.timeOffset = 0
        imageView.layer.beginTime  = 0
        // 恢复时间
        let timeSincePaused = imageView.layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        // 从暂停的时间点开始旋转
        imageView.layer.beginTime  = timeSincePaused
    }
}

extension UIColor {

    /// hexColor
    convenience init(hex: UInt32) {
        let r: CGFloat = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g: CGFloat = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let b: CGFloat = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
