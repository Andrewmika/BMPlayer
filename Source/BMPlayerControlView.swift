//
//  BMPlayerControlView.swift
//  Pods
//
//  Created by BrikerMan on 16/4/29.
//
//

import UIKit
import NVActivityIndicatorView


@objc public protocol BMPlayerControlViewDelegate: class {
    /**
     call when control view choose a definition
     
     - parameter controlView: control view
     - parameter index:       index of definition
     */
    func controlView(controlView: BMPlayerControlView, didChooseDefinition index: Int)
    
    /**
     call when control view pressed an button
     
     - parameter controlView: control view
     - parameter button:      button type
     */
    func controlView(controlView: BMPlayerControlView, didPressButton button: UIButton)
    
    /**
     call when slider action trigged
     
     - parameter controlView: control view
     - parameter slider:      progress slider
     - parameter event:       action
     */
    func controlView(controlView: BMPlayerControlView, slider: UISlider, onSliderEvent event: UIControl.Event)
    
    /**
     call when needs to change playback rate
     
     - parameter controlView: control view
     - parameter rate:        playback rate
     */
    @objc optional func controlView(controlView: BMPlayerControlView, didChangeVideoPlaybackRate rate: Float)
}

open class BMPlayerControlView: UIView {
    
    open weak var delegate: BMPlayerControlViewDelegate?
    open weak var player: BMPlayer?
    
    // MARK: Variables
    open var resource: BMPlayerResource?
    
    open var selectedIndex = 0
    open var isFullscreen  = false
    open var isMaskShowing = true
    
    open var totalDuration: TimeInterval = 0
    open var delayItem: DispatchWorkItem?
    
    var playerLastState: BMPlayerState = .notSetURL
    
    fileprivate var isSelectDefinitionViewOpened = false
    
    // MARK: UI Components
    /// main views which contains the topMaskView and bottom mask view
    open var mainMaskView   = UIView()
    open var topMaskView    = UIView()
    open var bottomMaskView = UIView()
    
    /// Image view to show video cover
    open var maskImageView = UIImageView()
    
    /// top views
    open var topWrapperView = UIView()
    open var backButton = UIButton(type : UIButton.ButtonType.custom)
    open var titleLabel = UILabel()
    
    /// bottom view
    open var bottomWrapperView = UIView()
    open var currentTimeLabel = UILabel()
    open var totalTimeLabel   = UILabel()
    
    /// Progress slider
    open var timeSlider = BMTimeSlider()
    
    /// load progress view
    open var progressView = UIProgressView()
    
    /* play button
     playButton.isSelected = player.isPlaying
     */
    open var playButton = UIButton(type: UIButton.ButtonType.custom)
        
    /// Activty Indector for loading
    open var loadingIndicator  = NVActivityIndicatorView(frame:  CGRect(x: 0, y: 0, width: 30, height: 30))

    open var replayButton     = UIButton(type: UIButton.ButtonType.custom)
    
    /// Gesture used to show / hide control view
    open var tapGesture: UITapGestureRecognizer!
    open var doubleTapGesture: UITapGestureRecognizer!
    
    // MARK: - handle player state change
    /**
     call on when play time changed, update duration here
     
     - parameter currentTime: current play time
     - parameter totalTime:   total duration
     */
    open func playTimeDidChange(currentTime: TimeInterval, totalTime: TimeInterval) {
        currentTimeLabel.text = BMPlayer.formatSecondsToString(currentTime)
        totalTimeLabel.text   = BMPlayer.formatSecondsToString(totalTime)
        timeSlider.value      = Float(currentTime) / Float(totalTime)
    }


    /**
     change subtitle resource
     
     - Parameter subtitles: new subtitle object
     */
    open func update(subtitles: BMSubtitles?) {
        resource?.subtitle = subtitles
    }
    
    /**
     call on load duration changed, update load progressView here
     
     - parameter loadedDuration: loaded duration
     - parameter totalDuration:  total duration
     */
    open func loadedTimeDidChange(loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        progressView.setProgress(Float(loadedDuration)/Float(totalDuration), animated: true)
    }
    
    open func playerStateDidChange(state: BMPlayerState) {
        switch state {
        case .readyToPlay:
            hideLoader()
            
        case .buffering:
            showLoader()
            
        case .bufferFinished:
            hideLoader()
            
        case .playedToTheEnd:
            playButton.isSelected = false
            showPlayToTheEndView()
            controlViewAnimation(isShow: true)
            
        default:
            break
        }
        playerLastState = state
    }
    
    /**
     Call when User use the slide to seek function
     
     - parameter toSecound:     target time
     - parameter totalDuration: total duration of the video
     - parameter isAdd:         isAdd
     */
    open func showSeekToView(to toSecound: TimeInterval, total totalDuration:TimeInterval, isAdd: Bool) {
        
        let targetTime = BMPlayer.formatSecondsToString(toSecound)
        timeSlider.value = Float(toSecound / totalDuration)
        currentTimeLabel.text = targetTime
    }
    
    // MARK: - UI update related function
    /**
     Update UI details when player set with the resource
     
     - parameter resource: video resouce
     - parameter index:    defualt definition's index
     */
    open func prepareUI(for resource: BMPlayerResource, selectedIndex index: Int) {
        self.resource = resource
        self.selectedIndex = index
        titleLabel.text = resource.name
        autoFadeOutControlViewWithAnimation()
    }
    
    open func playStateDidChange(isPlaying: Bool) {
        autoFadeOutControlViewWithAnimation()
        playButton.isSelected = isPlaying
    }
    
    /**
     auto fade out controll view with animtion
     */
    open func autoFadeOutControlViewWithAnimation() {
        cancelAutoFadeOutAnimation()
        delayItem = DispatchWorkItem { [weak self] in
            if self?.playerLastState != .playedToTheEnd {
                self?.controlViewAnimation(isShow: false)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + BMPlayerConf.animateDelayTimeInterval,
                                      execute: delayItem!)
    }
    
    /**
     cancel auto fade out controll view with animtion
     */
    open func cancelAutoFadeOutAnimation() {
        delayItem?.cancel()
    }
    
    /**
     Implement of the control view animation, override if need's custom animation
     
     - parameter isShow: is to show the controlview
     */
    open func controlViewAnimation(isShow: Bool) {
        let alpha: CGFloat = isShow ? 1.0 : 0.0
        self.isMaskShowing = isShow
        
        UIApplication.shared.setStatusBarHidden(!isShow, with: .fade)
        
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
          guard let wSelf = self else { return }
          wSelf.topMaskView.alpha    = alpha
          wSelf.bottomMaskView.alpha = alpha
          wSelf.mainMaskView.backgroundColor = UIColor(white: 0, alpha: isShow ? 0.4 : 0.0)

          if isShow {
          } else {
              wSelf.replayButton.isHidden = true
          }
          wSelf.layoutIfNeeded()
        }) { [weak self](_) in
            if isShow {
                self?.autoFadeOutControlViewWithAnimation()
            }
        }
    }
    
    /**
     Implement of the UI update when screen orient changed
     
     - parameter isForFullScreen: is for full screen
     */
    open func updateUI(_ isForFullScreen: Bool) {
        isFullscreen = isForFullScreen
        if isForFullScreen {
            if BMPlayerConf.topBarShowInCase.rawValue == 2 {
                topMaskView.isHidden = true
            } else {
                topMaskView.isHidden = false
            }
        } else {
            if BMPlayerConf.topBarShowInCase.rawValue >= 1 {
                topMaskView.isHidden = true
            } else {
                topMaskView.isHidden = false
            }
        }
    }
    
    /**
     Call when video play's to the end, override if you need custom UI or animation when played to the end
     */
    open func showPlayToTheEndView() {
        replayButton.isHidden = false
    }
    
    open func hidePlayToTheEndView() {
        replayButton.isHidden = true
    }
    
    open func showLoader() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
    }
    
    open func hideLoader() {
        loadingIndicator.isHidden = true
    }
    
    open func showCoverWithLink(_ cover:String) {
        self.showCover(url: URL(string: cover))
    }
    
    open func showCover(url: URL?) {
        if let url = url {
            DispatchQueue.global(qos: .default).async { [weak self] in
                let data = try? Data(contentsOf: url)
                DispatchQueue.main.async(execute: { [weak self] in
                  guard let `self` = self else { return }
                    if let data = data {
                        self.maskImageView.image = UIImage(data: data)
                    } else {
                        self.maskImageView.image = nil
                    }
                    self.hideLoader()
                });
            }
        }
    }
    
    open func hideCoverImageView() {
        self.maskImageView.isHidden = true
    }
    
    
    open func prepareToDealloc() {
        self.delayItem = nil
    }
    
    // MARK: - Action Response
    /**
     Call when some action button Pressed
     
     - parameter button: action Button
     */
    @objc open func onButtonPressed(_ button: UIButton) {
      autoFadeOutControlViewWithAnimation()
      if let type = ButtonType(rawValue: button.tag) {
        switch type {
        case .play, .replay:
          if playerLastState == .playedToTheEnd {
            hidePlayToTheEndView()
          }
        default:
          break
        }
      }
      delegate?.controlView(controlView: self, didPressButton: button)
    }
    
    /**
     Call when the tap gesture tapped
     
     - parameter gesture: tap gesture
     */
    @objc open func onTapGestureTapped(_ gesture: UITapGestureRecognizer) {
        if playerLastState == .playedToTheEnd {
            return
        }
        controlViewAnimation(isShow: !isMaskShowing)
    }
    
    @objc open func onDoubleTapGestureRecognized(_ gesture: UITapGestureRecognizer) {
        guard let player = player else { return }
        guard playerLastState == .readyToPlay || playerLastState == .buffering || playerLastState == .bufferFinished else { return }
        
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }
    
    // MARK: - handle UI slider actions
    @objc func progressSliderTouchBegan(_ sender: UISlider)  {
      delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .touchDown)
    }
    
    @objc func progressSliderValueChanged(_ sender: UISlider)  {
      hidePlayToTheEndView()
      cancelAutoFadeOutAnimation()
      let currentTime = Double(sender.value) * totalDuration
      currentTimeLabel.text = BMPlayer.formatSecondsToString(currentTime)
      delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .valueChanged)
    }
    
    @objc func progressSliderTouchEnded(_ sender: UISlider)  {
      autoFadeOutControlViewWithAnimation()
      delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .touchUpInside)
    }
    
    
    // MARK: - private functions
    
    @objc fileprivate func onReplyButtonPressed() {
        replayButton.isHidden = true
    }
    
    // MARK: - Init
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUIComponents()
        addSnapKitConstraint()
        customizeUIComponents()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUIComponents()
        addSnapKitConstraint()
        customizeUIComponents()
    }
    
    /// Add Customize functions here
    open func customizeUIComponents() {
        
    }
    
    func setupUIComponents() {
                
        // Main mask view
        addSubview(mainMaskView)
        mainMaskView.addSubview(topMaskView)
        mainMaskView.addSubview(bottomMaskView)
        mainMaskView.insertSubview(maskImageView, at: 0)
        mainMaskView.clipsToBounds = true
        mainMaskView.backgroundColor = UIColor(white: 0, alpha: 0.4 )
        
        // Top views
        topMaskView.addSubview(topWrapperView)
        topWrapperView.addSubview(backButton)
        topWrapperView.addSubview(titleLabel)
        
        backButton.tag = BMPlayerControlView.ButtonType.back.rawValue
        backButton.setImage(BMImageResourcePath("BMPlayer_back"), for: .normal)
        backButton.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
        backButton.flipIfRTL()
        
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.textColor = UIColor.white
        titleLabel.text      = ""
        titleLabel.font      = UIFont.systemFont(ofSize: 16)
                
        // Bottom views
        bottomMaskView.addSubview(bottomWrapperView)
        bottomWrapperView.addSubview(playButton)
        bottomWrapperView.addSubview(currentTimeLabel)
        bottomWrapperView.addSubview(totalTimeLabel)
        bottomWrapperView.addSubview(progressView)
        bottomWrapperView.addSubview(timeSlider)
        
        playButton.tag = BMPlayerControlView.ButtonType.play.rawValue
        playButton.setImage(BMImageResourcePath("BMPlayer_play"),  for: .normal)
        playButton.setImage(BMImageResourcePath("BMPlayer_pause"), for: .selected)
        playButton.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
        
        currentTimeLabel.textColor  = UIColor.white
        currentTimeLabel.font       = UIFont.systemFont(ofSize: 12)
        currentTimeLabel.text       = "00:00"
        currentTimeLabel.textAlignment = NSTextAlignment.center
        currentTimeLabel.adjustsFontSizeToFitWidth = true

        totalTimeLabel.textColor    = UIColor.white
        totalTimeLabel.font         = UIFont.systemFont(ofSize: 12)
        totalTimeLabel.text         = "00:00"
        totalTimeLabel.textAlignment   = NSTextAlignment.center
        totalTimeLabel.adjustsFontSizeToFitWidth = true
        
        timeSlider.maximumValue = 1.0
        timeSlider.minimumValue = 0.0
        timeSlider.value        = 0.0
        timeSlider.setThumbImage(BMImageResourcePath("BMPlayer_slider_thumb"), for: .normal)
        
        timeSlider.maximumTrackTintColor = UIColor.clear
        timeSlider.minimumTrackTintColor = BMPlayerConf.tintColor
        
        timeSlider.addTarget(self, action: #selector(progressSliderTouchBegan(_:)),
                             for: UIControl.Event.touchDown)
        
        timeSlider.addTarget(self, action: #selector(progressSliderValueChanged(_:)),
                             for: UIControl.Event.valueChanged)
        
        timeSlider.addTarget(self, action: #selector(progressSliderTouchEnded(_:)),
                             for: [UIControl.Event.touchUpInside,UIControl.Event.touchCancel, UIControl.Event.touchUpOutside])
        
        progressView.tintColor      = UIColor ( red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6 )
        progressView.trackTintColor = UIColor ( red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3 )
        
        mainMaskView.addSubview(loadingIndicator)
        
        loadingIndicator.type  = BMPlayerConf.loaderType
        loadingIndicator.color = BMPlayerConf.tintColor
        
        addSubview(replayButton)
        replayButton.isHidden = true
        replayButton.setImage(BMImageResourcePath("BMPlayer_replay"), for: .normal)
        replayButton.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
        replayButton.tag = ButtonType.replay.rawValue
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapGestureTapped(_:)))
        addGestureRecognizer(tapGesture)
        
        if BMPlayerManager.shared.enablePlayControlGestures {
            doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTapGestureRecognized(_:)))
            doubleTapGesture.numberOfTapsRequired = 2
            addGestureRecognizer(doubleTapGesture)
            
            tapGesture.require(toFail: doubleTapGesture)
        }
    }
    
    func addSnapKitConstraint() {
        // Main mask view
        mainMaskView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.safeAreaLayoutGuide)
        }
        
        maskImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.mainMaskView)
        }

        topMaskView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalTo(self.mainMaskView)
        }
        
        topWrapperView.snp.makeConstraints { (make) in
            make.height.equalTo(50)
            make.top.leading.trailing.equalTo(self.topMaskView.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        
        bottomMaskView.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalTo(self.mainMaskView)
        }
        
        bottomWrapperView.snp.makeConstraints { (make) in
            make.height.equalTo(50)
            make.bottom.leading.trailing.equalTo(self.bottomMaskView.safeAreaLayoutGuide)
            make.top.equalToSuperview()
        }
        
        // Top views
        backButton.snp.makeConstraints { (make) in
          make.width.height.equalTo(50)
          make.leading.bottom.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(self.backButton.snp.trailing)
            make.trailing.lessThanOrEqualToSuperview().inset(15)
            make.centerY.equalTo(self.backButton)
        }
        
        // Bottom views
        playButton.snp.makeConstraints { (make) in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.bottom.equalToSuperview()
        }
        
        currentTimeLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(self.playButton.snp.trailing)
            make.centerY.equalTo(self.playButton)
            make.width.equalTo(40)
        }
        
        timeSlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.currentTimeLabel)
            make.leading.equalTo(self.currentTimeLabel.snp.trailing).offset(10)
            make.height.equalTo(30)
        }
        
        progressView.snp.makeConstraints { (make) in
            make.centerY.leading.trailing.equalTo(self.timeSlider)
            make.height.equalTo(2)
        }
        
        totalTimeLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.currentTimeLabel)
            make.leading.equalTo(self.timeSlider.snp.trailing).offset(5)
            make.width.equalTo(40)
            make.trailing.equalToSuperview().inset(19)

        }
        
        loadingIndicator.snp.makeConstraints { (make) in
            make.center.equalTo(self.mainMaskView)
        }
        
        
        replayButton.snp.makeConstraints { (make) in
            make.center.equalTo(self.mainMaskView)
            make.width.height.equalTo(50)
        }
    }
    
    fileprivate func BMImageResourcePath(_ fileName: String) -> UIImage? {
        return UIImage(named: fileName)
    }
}


extension UIView {
    // rtl适配
    func flipIfRTL() -> Self {
        if UIView.userInterfaceLayoutDirection(for: .unspecified) == .rightToLeft {
            transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        return self
    }
}
