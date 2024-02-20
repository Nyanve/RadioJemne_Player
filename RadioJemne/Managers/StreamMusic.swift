//
//  StreamMusic.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 02/02/2024.
//

import UIKit
import AVFoundation
import MediaPlayer

protocol StreamMusicDelegate: AnyObject {
    func sendVolumeValue(_ streamMusic: StreamMusic, volumeChangedTo: Float)
    func sendSongData(_ streamMusic: StreamMusic, songTitle: String, songArtist: String)
    func playerFailed()
}

class StreamMusic: NSObject {
    
    let urlString: String = "https://stream.bauermedia.sk/melody-lo.mp3"
    var artist = ""
    var title = "Radio Jemne"
    let image = UIImage(resource: ImageResource.rjMusic)
    
    var volumeValue: Float!
    var player: AVPlayer? = nil
    var playerItem: AVPlayerItem!
    var metadataOutput: AVPlayerItemMetadataOutput?
    weak var delegate: StreamMusicDelegate?
    
    @discardableResult @objc public func play() -> MPRemoteCommandHandlerStatus {
        setUpConnection()
        return .success
    }
 
    @discardableResult @objc public func pause() -> MPRemoteCommandHandlerStatus {
        guard let player else {
            return .commandFailed
        }
        
        player.pause()
        return .success
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            if let volumeValue = change?[.newKey] as? Float {
                delegate?.sendVolumeValue(self, volumeChangedTo: volumeValue)
            } else {
                debugPrint("The new value is not a float or is nil")
            }
        }
        if keyPath == #keyPath(AVPlayer.status) {
            if let newStatusNumber = change?[.newKey] as? NSNumber,
               let newStatus = AVPlayer.Status(rawValue: newStatusNumber.intValue) {
                if newStatus == .failed {
                    delegate?.playerFailed()
                }
            }
        }
    }
    
    private func setUpConnection() {
        let url = URL(string: urlString)!
        metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        playerItem = AVPlayerItem(url: url)
        playerItem.add(metadataOutput!)
        
        player = AVPlayer(playerItem: self.playerItem)
        player?.volume = 0.5
        player?.play()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            debugPrint("Stream connection", error)
        }
        
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: .new, context: nil)
        player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.new, .initial], context: nil)
        playerItem.addObserver(self, forKeyPath: "timedMetadata", options: .new, context: nil)
        musicBeganPlaying()
    }
    
    private func musicBeganPlaying() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        addActionsToControlCenter()
        metadataOutput?.setDelegate(self, queue: DispatchQueue.main)
        
        MPNowPlayingInfoCenter.default().playbackState = .playing
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: self.image.size) { size in
                return self.image
            }
        ]
    }

    private func newPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: self.image.size) { size in
                return self.image
            }
        ]
    }

    private func addActionsToControlCenter() {
        addActionToPauseCommand()
        addActionToPlayCommand()
    }
    
    private func addActionToPlayCommand(){
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget(self, action: #selector(play))
    }

    private func addActionToPauseCommand(){
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget(self, action: #selector(pause))
    }
    
    private func extractMetadata(from songName: String) {
        let components = songName.components(separatedBy: "-")
        
        if components.count == 2 {
            artist = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            title = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            title = "Radio Jemne"
            artist = songName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        delegate?.sendSongData(self, songTitle: title, songArtist: artist)
        newPlayingInfo()
    }
}

extension StreamMusic: AVPlayerItemMetadataOutputPushDelegate {
    
    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
        for group in groups {
            for item in group.items {
                let sendableItem = SendableAVMetadataItem(item: item)
                Task {
                    do {
                        let songData = try await sendableItem.loadValue()
                        if let songData = songData {
                            extractMetadata(from: songData)
                        }
                    } catch {
                        print("Error loading timed metadata: \(error)")
                    }
                }
            }
        }
    }
}

