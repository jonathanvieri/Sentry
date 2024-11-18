//
//  VideoViewController.swift
//  Sentry
//
//  Created by Jonathan Vieri on 17/11/24.
//

import UIKit
import AVFoundation

class VideoViewController: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var restartButton: UIButton!

    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var timeObserver: Any?
    var wasPlayingBefore = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupVideoPlayer()
        addVideoCompletionObserver()
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
    
    @objc private func videoDidFinishPlaying() {
        print("Video finished playing")
        restartButton.isHidden = false
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
    
    
}
