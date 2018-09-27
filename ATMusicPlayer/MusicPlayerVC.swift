//
//  MusicPlayerVC.swift
//  ATMusicPlayer
//
//  Created by Amrit Tiwari on 9/25/18.
//  Copyright © 2018 Amrit Tiwari. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer


struct UserdefaultKeys {
    
    struct AudioPlayer {
        static let shuffleAudioPlayer = "audioPlayeIsInShuffleState"
        static let repeatedAudioPlayer = "audioPlayeIsInRepeatState"
        static let currentAudioIndexOfAudioPlayer = "currentAudioIndexOfAudioPlayer"
    }
}


class MusicPlayerVC: UIViewController {
    
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    //@IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var albumArtworkImageView: UIImageView!
    
    @IBOutlet weak var lblArtistName: UILabel!
    @IBOutlet weak var lblSongName : UILabel!
    @IBOutlet weak var lblCurrentDuration : UILabel!
    @IBOutlet weak var lblTotalDuration : UILabel!
    
    @IBOutlet weak var audioSlider : UISlider!
    
    @IBOutlet weak var btnShuffle: UIButton!
    @IBOutlet weak var btnPrevious : UIButton!
    @IBOutlet weak var btnPlayPause : UIButton!
    @IBOutlet weak var btnNext : UIButton!
    @IBOutlet weak var btnRepeat: UIButton!
    @IBOutlet weak var btnDismiss: UIButton!
    
    @IBOutlet weak var topAlbumArtworkImageView: UIImageView!
    @IBOutlet weak var lblTopArtistName: UILabel!
    @IBOutlet weak var btnTopPrevious : UIButton!
    @IBOutlet weak var btnTopPlayPause : UIButton!
    @IBOutlet weak var btnTopNext : UIButton!
    
    
    public var audioList : [AudioDetails] = []
    public var currentAudioIndex = 0
    
    public var dismissTrigger: (()->())?
    
    fileprivate var blurEffectView : UIVisualEffectView = UIVisualEffectView.init(frame: CGRect.zero)
    fileprivate var audioPlayer: AVAudioPlayer = AVAudioPlayer()
    fileprivate var currentAudioPath:URL!
    fileprivate var timerToTrackAudioActivities  : Timer?
    fileprivate var shuffleAudioListIndexArray = [Int]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.btnShuffle.isSelected = false
        self.btnRepeat.isSelected = false
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.prepareAudio()
        self.assingSliderUI()
        
        //LockScreen Media control registry
        if UIApplication.shared.responds(to: #selector(UIApplication.beginReceivingRemoteControlEvents)){
            UIApplication.shared.beginReceivingRemoteControlEvents()
            UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            })
        }
        
//        let commandCenter = MPRemoteCommandCenter.shared()
//        if #available(iOS 9.1, *) {
//            commandCenter.changePlaybackPositionCommand.isEnabled = true
//            commandCenter.changePlaybackPositionCommand.addTarget(self, action:#selector(self.changePlaybackPositionCommand(_:)))
//        } else {
//            // Fallback on earlier versions
//        }

        playAudio()
        self.startTimerToTrackAudioActivities()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.timerToTrackAudioActivities?.invalidate()
        self.timerToTrackAudioActivities = nil
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    deinit {
        print("musicPlayerVC deinitiallized")
    }
    
    fileprivate func blurEffect(_ imageView : UIImageView) {
        
        blurEffectView.removeFromSuperview()
        
        let effect = UIBlurEffect(style: .dark)
        blurEffectView.effect = effect
        // set boundry and alpha
        blurEffectView.frame = CGRect(x: 0, y: 0, width: imageView.frame.width, height: self.view.frame.height)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = 0.98
        
        imageView.addSubview(blurEffectView)
    }
    
    
    //This returns song length
    fileprivate func calculateTimeFromNSTimeInterval(_ duration:TimeInterval) ->(minute:String, second:String){
        //         let hour_   = abs(Int(duration)/3600)
        let minute_ = abs(Int((duration/60).truncatingRemainder(dividingBy: 60)))
        let second_ = abs(Int(duration.truncatingRemainder(dividingBy: 60)))
        
        //        var hour = hour_ > 9 ? "\(hour_)" : "0\(hour_)"
        let minute = minute_ > 9 ? "\(minute_)" : "0\(minute_)"
        let second = second_ > 9 ? "\(second_)" : "0\(second_)"
        return (minute,second)
    }
    
    
    fileprivate func updateLabels(){
        let artistName = self.audioList[currentAudioIndex].artistName
        self.lblArtistName.text = artistName
        self.lblTopArtistName.text = artistName
        
        let songName = self.audioList[currentAudioIndex].songName
        self.lblSongName.text = songName
        
        let albumArtworkImage = UIImage(named: self.audioList[currentAudioIndex].albumArtwork)
        self.albumArtworkImageView.image = albumArtworkImage
        self.topAlbumArtworkImageView.image = albumArtworkImage
        
        let bgImage = UIImage(named: self.audioList[currentAudioIndex].albumArtwork)
        self.backgroundImageView.image = bgImage
        self.blurEffect(self.backgroundImageView)
    }
    
    
    fileprivate func assingSliderUI () {
        let minImage = UIImage(named: "slider-track-fill")
        let maxImage = UIImage(named: "slider-track")
        let thumb = UIImage(named: "thumb")
        
        audioSlider.setMinimumTrackImage(minImage, for: UIControl.State())
        audioSlider.setMaximumTrackImage(maxImage, for: UIControl.State())
        audioSlider.setThumbImage(thumb, for: UIControl.State())
    }
    
    fileprivate func startTimerToTrackAudioActivities(){
        
        self.timerToTrackAudioActivities?.invalidate()
        self.timerToTrackAudioActivities = nil
        
        self.timerToTrackAudioActivities = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector:  #selector(self.timerToTrackAudioActivitiesTrigger(_:)), userInfo: nil,repeats: true)
    }
    
    @objc fileprivate func timerToTrackAudioActivitiesTrigger(_ tm : Timer){
        if !self.audioPlayer.isPlaying{
            return
        }
        let time = calculateTimeFromNSTimeInterval(audioPlayer.currentTime)
        self.lblCurrentDuration.text  = "\(time.minute):\(time.second)"
        self.audioSlider.value = CFloat(audioPlayer.currentTime)
        MPMusicPlayerController.applicationMusicPlayer.play()
    }
    
    
    //MARK:-Actions
    
    @IBAction func btnDismissTouched(_ sender: Any) {
        self.dismissTrigger?()
    }
    
    
    @IBAction func btnShuffleTouched(_ sender: UIButton) {
        
        shuffleAudioListIndexArray.removeAll()
        
        sender.isSelected = !sender.isSelected
    }
    
    
    @IBAction func btnPlayPauseTouched(_ sender : AnyObject) {
        
        _ = audioPlayer.isPlaying ? "\(audioPlayer.pause())" : "\(audioPlayer.play())"
        _ = audioPlayer.isPlaying ? "\(self.setPlayImageInPlayButton(false))" : "\(self.setPlayImageInPlayButton(true)))"
    }
    
    
    @IBAction func btnPreviousTouched(_ sender : AnyObject) {
        
        _ = self.btnShuffle.isSelected ? "\(self.createSuffleArrayAndPlaySong())" : "\(self.playPreviousAudio())"
    }
    
    
    
    @IBAction func btnNextTouched(_ sender : AnyObject) {
        
         _ = self.btnShuffle.isSelected ? "\(self.createSuffleArrayAndPlaySong())" : "\(self.playNextAudio())"
    }
    
    @objc func changePlaybackPositionCommand(_ event:MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus{
        
        let time = event.positionTime
        self.audioSlider.value = Float(time)
        audioPlayer.currentTime = time
        return MPRemoteCommandHandlerStatus.success;
    }
    
    
    @IBAction func changeAudioLocationSlider(_ sender : UISlider) {
        
        audioPlayer.currentTime = TimeInterval(sender.value)
    }
    
    
    @IBAction func btnRepeatTouched(_ sender: UIButton) {
        
        sender.isSelected = !sender.isSelected
    }
}


extension MusicPlayerVC{
    
    fileprivate func setPlayImageInPlayButton(_ isPlay : Bool){
        
        if isPlay{
            let playImage = UIImage(named: "play")
            self.btnPlayPause.setImage(playImage, for: UIControl.State())
            self.btnTopPlayPause.setImage(playImage, for: UIControl.State())
        }else{
            let pauseImage = UIImage(named: "pause")
            self.btnPlayPause.setImage(pauseImage, for: UIControl.State())
            self.btnTopPlayPause.setImage(pauseImage, for: UIControl.State())
        }
    }
    
    fileprivate func createSuffleArrayAndPlaySong(){
        
        shuffleAudioListIndexArray.append(currentAudioIndex)
        if shuffleAudioListIndexArray.count >= audioList.count {
            //            self.setPlayImageInPlayButton(true)
            //            return
            shuffleAudioListIndexArray.removeAll()
        }
        
        var randomIndex = 0
        var newIndex = false
        while newIndex == false {
            randomIndex =  Int(arc4random_uniform(UInt32(audioList.count)))
            if shuffleAudioListIndexArray.contains(randomIndex) {
                newIndex = false
            }else{
                newIndex = true
            }
        }
        currentAudioIndex = randomIndex
        prepareAudio()
        playAudio()
    }
    
    
    //Sets audio file URL
    func setCurrentAudioPath(){
        let currentAudio = self.audioList[currentAudioIndex].songName
        currentAudioPath = URL(fileURLWithPath: Bundle.main.path(forResource: currentAudio, ofType: "mp3")!)
    }
    
    
    
    // Prepare audio for playing
    func prepareAudio(){
        
        self.setCurrentAudioPath()
        self.startTimerToTrackAudioActivities()
        
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            }
            else {
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
            }
        }
        catch {
            // report for an error
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.audioPlayer = try! AVAudioPlayer(contentsOf: currentAudioPath)
        self.audioPlayer.delegate = self
        self.audioSlider.maximumValue = CFloat(audioPlayer.duration)
        self.audioSlider.minimumValue = 0.0
        self.audioSlider.value = 0.0
        self.audioPlayer.prepareToPlay()
        
        let time = calculateTimeFromNSTimeInterval(audioPlayer.duration)
        let totalLengthOfAudio = "\(time.minute):\(time.second)"
        self.lblTotalDuration.text = totalLengthOfAudio
        self.lblCurrentDuration.text = "00:00"

        self.updateLabels()
        
        self.btnPrevious.isHidden = false
        self.btnTopPrevious.isHidden = false
        self.btnNext.isHidden = false
        self.btnTopNext.isHidden = false

        if self.currentAudioIndex == 0{
            self.btnPrevious.isHidden = true
            self.btnTopPrevious.isHidden = true
        }else if currentAudioIndex == self.audioList.count-1{
            self.btnNext.isHidden = true
            self.btnTopNext.isHidden = true
        }
    }
    
    //MARK:- Player Controls Methods
    func playAudio(){
        
        audioPlayer.play()
        updateLabels()
        showMediaInfo()
        _ = audioPlayer.isPlaying ? "\(self.setPlayImageInPlayButton(false), for: UIControl.State()))" : "\(self.setPlayImageInPlayButton(true))"
        MPMusicPlayerController.applicationMusicPlayer.play()
//        MPRemoteCommandCenter.shared().nex
        
    }
    
    func playNextAudio(){
        
        currentAudioIndex += 1
        if currentAudioIndex>audioList.count-1{
            currentAudioIndex -= 1
            
            return
        }
        if audioPlayer.isPlaying{
            prepareAudio()
            playAudio()
        }else{
            prepareAudio()
        }
    }
    
    
    func playPreviousAudio(){
        
        currentAudioIndex -= 1
        if currentAudioIndex<0{
            currentAudioIndex += 1
            return
        }
        if audioPlayer.isPlaying{
            prepareAudio()
            playAudio()
        }else{
            prepareAudio()
        }
    }
    
}


extension MusicPlayerVC : AVAudioPlayerDelegate{
    
    // MARK:- AVAudioPlayer Delegate's Callback method
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool){
        
        if !flag { return }
        
        if self.btnShuffle.isSelected == false && self.btnRepeat.isSelected == false {
            // do nothing
            self.setPlayImageInPlayButton(true)
            self.playNextAudio()
            return
        }
        
        if self.btnRepeat.isSelected {
            //repeat same song
            prepareAudio()
            playAudio()
            return
        }
        
        if self.btnShuffle.isSelected {
            
            self.createSuffleArrayAndPlaySong()
        }
    }
    
    
    //MARK:- Lockscreen Media Control
    // This shows media info on lock screen - used currently and perform controls
    func showMediaInfo(){
        let artistName = self.audioList[currentAudioIndex].artistName
        let songName = self.audioList[currentAudioIndex].songName
        
        let albumArt = MPMediaItemArtwork(image: UIImage(named:self.audioList[currentAudioIndex].albumArtwork)!)
        
        let currentPlayingControlInfo : [String : Any] = [
            MPMediaItemPropertyArtist : artistName,
            MPMediaItemPropertyTitle : songName,
            MPMediaItemPropertyArtwork: albumArt,
            MPMediaItemPropertyPlaybackDuration: audioPlayer.duration
//            MPNowPlayingInfoPropertyPlaybackRate : self.audioPlayer.currentTime
        ]
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = currentPlayingControlInfo
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        
        guard let event = event else {
            return
        }
        
        if event.type == UIEvent.EventType.remoteControl{
            switch event.subtype{
            case UIEvent.EventSubtype.remoteControlPlay:
                self.btnPlayPauseTouched(self)
            case UIEvent.EventSubtype.remoteControlPause:
                self.btnPlayPauseTouched(self)
            case UIEvent.EventSubtype.remoteControlNextTrack:
                self.btnNextTouched(self)
            case UIEvent.EventSubtype.remoteControlPreviousTrack:
                self.btnPreviousTouched(self)
            default:
                break
//                print("There is an issue with the control")
            }
        }
    }
}
