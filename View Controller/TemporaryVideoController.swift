//
//  TemporaryVideoViewController.swift
//  Sentry
//
//  Created by Jonathan Vieri on 17/11/24.
//

import UIKit
import AVFoundation

class TemporaryVideoController: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var bufferingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var fullscreenButton: UIButton!
    @IBOutlet weak var overlayLayer: UIView!
    
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var timeObserver: Any?
    var wasPlayingBefore = false
    var areControlsVisible = false
    var isfullScreen = false
    var originalVideoContainer: UIView!
    var originalVideoFrame: CGRect!
    
    private var playbackBufferEmptyObserver: NSKeyValueObservation?
    private var playbackLikelyToKeepUpObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupVideoPlayer()
        addVideoCompletionObserver()
        addBufferingObservers()
        bufferingIndicator.isHidden = true
        
        // Add Tap Gesture
        let videoTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleControlVisibility))
        overlayLayer.addGestureRecognizer(videoTapGesture)
        
        fullscreenButton.alpha = 0.0
        
        originalVideoContainer = videoView.superview
        originalVideoFrame = videoView.frame
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        
        NotificationCenter.default.removeObserver(self, name: AVPlayerItem.didPlayToEndTimeNotification, object: player.currentItem)
    }

    private func setupVideoPlayer() {
        // Create URL for the Video
        guard let videoURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else { return }
        
        // Initializer AVPlayer
        player = AVPlayer(url: videoURL)
        
        // Add video player to the video view layer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoView.bounds
        playerLayer.videoGravity = .resizeAspectFill
        videoView.layer.addSublayer(playerLayer)
        videoView.addSubview(bufferingIndicator)
        videoView.addSubview(overlayLayer)
        videoView.addSubview(fullscreenButton)
        
        // Add periodic time obsever
        addPeriodicTimeObserver()
        
        // Fetch video duration when ready
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial],context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration" {
            guard let duration = player.currentItem?.duration.seconds, duration > 0 else { return }
            timeSlider.maximumValue = Float(duration)
            totalTimeLabel.text = "/ \(formatTime(seconds: duration))"
        }
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)) // 1-second interval
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] time in
            guard let self = self else { return }
            
            let currentTime = CMTimeGetSeconds(time)
            self.elapsedTimeLabel.text = self.formatTime(seconds: currentTime)
            self.timeSlider.value = Float(currentTime)
        })
    }
    
    private func addBufferingObservers() {
        playbackBufferEmptyObserver = player.currentItem?.observe(\.isPlaybackBufferEmpty, options: [.new], changeHandler: { [weak self] item, change in
            if let isBuffering = change.newValue, isBuffering {
                print("Video is buffering, showing buffering indicator")
                self?.bufferingIndicator.isHidden = false
                self?.bufferingIndicator.startAnimating()
            }
        })
        
        playbackLikelyToKeepUpObserver = player.currentItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new], changeHandler: { [weak self] item, change in
            if let isLikelyToKeepUp = change.newValue, isLikelyToKeepUp {
                print("Likely to keep up, removing buffering indicator")
                self?.bufferingIndicator.stopAnimating()
                self?.bufferingIndicator.isHidden = true
            }
        })
    }
    
    private func updatePlayButtonImage(toPause: Bool) {
        if toPause {
            playPauseButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
        } else {
            playPauseButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        }
    }
    
    private func formatTime(seconds: Double) -> String {
        let hour = Int(seconds) / 3600
        let minute = (Int(seconds) % 3600) / 60
        let second = Int(seconds) % 60
        
        if hour > 0 {
            return String(format: "%02d:%02d:%02d", hour, minute, second)
        } else {
            return String(format: "%02d:%02d", minute, second)
        }
    }
    
    private func addVideoCompletionObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: AVPlayerItem.didPlayToEndTimeNotification, object: player.currentItem)
    }
    
    private func enterFullscreen() {
        print("Entering full screen")
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })
        else { return }
        
        // Remove videoView from its original container
        videoView.removeFromSuperview()

        // Add videoView to the window
        window.addSubview(videoView)

        // Expand to fullscreen
        UIView.animate(withDuration: 0.3) {
            self.videoView.frame = CGRect(x: 0, y: 0, width: window.frame.width, height: window.frame.height)
            self.videoView.layoutIfNeeded()
        }
        
        // Rotate to landscape
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
    }
    
    private func exitFullscreen() {
        print("Exiting fullscreen")
        
        // Remove videoView from the window
        videoView.removeFromSuperview()
        
        // Re-add videoView to original container
        originalVideoContainer.addSubview(videoView)
        
        // Restore original frame
        UIView.animate(withDuration: 0.3) {
            self.videoView.frame = self.originalVideoFrame
            self.videoView.layoutIfNeeded()
        }
        
        // Rotate back to portrait
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")

    }
    
    @objc private func videoDidFinishPlaying() {
        print("Video finished playing")
        restartButton.isHidden = false
    }
    
    @objc private func toggleControlVisibility() {
        print("Control visibility is tapped")
        areControlsVisible.toggle()
        UIView.animate(withDuration: 0.2) {
            self.fullscreenButton.alpha = self.areControlsVisible ? 1.0 : 0.0
        }
    }
    
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        if player.timeControlStatus == .playing {
            player.pause()
            updatePlayButtonImage(toPause: false)
        } else {
            player.play()
            updatePlayButtonImage(toPause: true)
        }
    }
    
    @IBAction func timeSliderValueChanged(_ sender: UISlider, forEvent event: UIEvent) {
        if let touch = event.allTouches?.first {
            switch touch.phase {
            case .began:
                print("Began UI Slider touch")
                wasPlayingBefore = (player.timeControlStatus == .playing)
                player.pause()
                updatePlayButtonImage(toPause: false)
            case .moved:
                print("UI Slider is moved")
                let chosenTime = CMTime(seconds: Double(sender.value), preferredTimescale: 1)
                player.seek(to: chosenTime)
                restartButton.isHidden = true
            case .ended:
                print("Ended UISlider event")
                if wasPlayingBefore {
                    player.play()
                    updatePlayButtonImage(toPause: true)
                }
            default:
                break
            }
        }
    }
    
    @IBAction func restartButtonPressed(_ sender: Any) {
        player.seek(to: .zero)
        player.play()
        restartButton.isHidden = true
        updatePlayButtonImage(toPause: true)
    }
    
    @IBAction func skipForwardButtonpressed(_ sender: UIButton) {
        let currentTime = player.currentTime()
        let forwardedTime = CMTimeAdd(currentTime, CMTime(seconds: 5, preferredTimescale: 1))
        player.seek(to: forwardedTime)
    }
    
    @IBAction func skipBackwardButtonPressed(_ sender: UIButton) {
        let currentTime = player.currentTime()
        let backwardedTime = CMTimeSubtract(currentTime, CMTime(seconds: 5, preferredTimescale: 1))
        player.seek(to: backwardedTime)
    }
    
    @IBAction func fullscreenButtonPressed(_ sender: UIButton) {
        if isfullScreen {
            exitFullscreen()
        } else {
            enterFullscreen()
        }
        isfullScreen.toggle()
    }
    
}
