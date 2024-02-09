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
}


class StreamMusic: NSObject {
    
    let urlString: String = "https://stream.bauermedia.sk/melody-lo.mp3"
    var player: AVPlayer? = nil
    var playerItem: AVPlayerItem?
    var metadataOutput: AVPlayerItemMetadataOutput?
    
    weak var delegate: StreamMusicDelegate?
    
    var artist = "---"
    var title = "Radio Jemne"
    let image = UIImage(resource: ImageResource.rjMusic )
    
    
    func setUpConnection() {
        let url = URL(string: urlString)!
        metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        
        let playerItem = AVPlayerItem(url: url)
        playerItem.add(metadataOutput!)
        player = AVPlayer(playerItem: playerItem)
        
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            print("Playback OK")
            try AVAudioSession.sharedInstance().setActive(true)
            print("Session is Active")
        } catch {
            print("some shit dont work", error)
        }
        
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: .new, context: nil)
        player?.volume = 0.5
        playerItem.addObserver(self, forKeyPath: "timedMetadata", options: .new, context: nil)
        musicBeganPlaying()
        player?.play()
        
    }

        
    @objc private func musicBeganPlaying() {
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
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            if let volumeValue = change?[.newKey] as? Float {
                delegate?.sendVolumeValue(self, volumeChangedTo: volumeValue)
            } else {
                print("The new value is not a float or is nil")
            }
        }
    }
    
    
    func addActionsToControlCenter() {
        addActionToPauseCommand()
        addActionToPlayCommand()
    }
    
    
    func addActionToPlayCommand(){
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget(self, action: #selector(play))
    }
    
    
    func addActionToPauseCommand(){
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget(self, action: #selector(pause))
    }
    
    
    @discardableResult @objc public func play() -> MPRemoteCommandHandlerStatus {
        if player == nil {
            setUpConnection()
        }
        guard let player else {
            return .commandFailed
        }
        player.play()
        return .success
    }
 
    
    @discardableResult @objc public func pause() -> MPRemoteCommandHandlerStatus {
        guard let player else {
            return .commandFailed
        }
        player.pause()
        return .success
    }
    

    func extractMetadata(from songName: String) {
        // Split the string based on the separator "-"
        let components = songName.components(separatedBy: "-")
        
        // If there are exactly two components, assume artist and title
        if components.count == 2 {
            artist = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            title = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // If there's only one component, assume it's the artist
            title = "Radio Jemné"
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
                if let songData = item.value as? String {
                    extractMetadata(from: songData)
                    print ("song data: ",songData)
                }
            }
        }
    }
}

