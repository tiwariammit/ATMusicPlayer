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


class MusicPlayerVC: UIViewController {
    
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
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
    
    fileprivate var blurEffectView : UIVisualEffectView = UIVisualEffectView.init(frame: CGRect.zero)
    fileprivate var audioPlayer: AVAudioPlayer = AVAudioPlayer()

    fileprivate var currentAudioPath: String = ""
    fileprivate var timerToTrackAudioActivities  : Timer?
    fileprivate var shuffleAudioListIndexArray = [Int]()
    
    fileprivate var topPositionOfPlayerView: CGFloat = -70
    
    fileprivate var bottomPositionOfPlayerView: CGFloat {
        
        let appDelagate = UIApplication.shared.delegate as! AppDelegate
        let window = appDelagate.window
        
        var yPosition: CGFloat = 0
        if #available(iOS 11.0, *) {
            if let bottom = window?.safeAreaInsets.bottom, bottom > 0{
                yPosition = bottom
            }
        }
        
        return UIScreen.main.bounds.height + self.topPositionOfPlayerView - yPosition
    }
    
    fileprivate var gesture : UIPanGestureRecognizer?

//   fileprivate let dmManager = DownloadMusicManager.shared()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.btnShuffle.isSelected = false
        self.btnRepeat.isSelected = false
        self.addGuesture()
        self.assingSliderUI()
//        self.prepareAudio()
        
        //LockScreen Media control registry
        if UIApplication.shared.responds(to: #selector(UIApplication.beginReceivingRemoteControlEvents)){
            UIApplication.shared.beginReceivingRemoteControlEvents()
            UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            })
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.prepareAudio()
        self.playAudio()
        self.startTimerToTrackAudioActivities()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.07, options: [.beginFromCurrentState], animations: {
            
            self.view.frame = CGRect(x: 0, y: self.topPositionOfPlayerView, width: self.view.frame.width, height: self.view.frame.height - self.topPositionOfPlayerView)
            
        }, completion: nil)
        
//        self.playAudio()

    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.timerToTrackAudioActivities?.invalidate()
        self.timerToTrackAudioActivities = nil
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.view.layoutIfNeeded()
    }
    
    
    deinit {
        print("musicPlayerVC deinitiallized")
    }
    
    private func addGuesture(){
        
        gesture = UIPanGestureRecognizer(target: self, action: #selector(self.wasDragging(_:)))
        self.view.addGestureRecognizer(gesture!)
        self.view.isUserInteractionEnabled = true
        gesture?.delegate = self
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
        
        self.audioSlider.setMinimumTrackImage(minImage, for: UIControl.State())
        self.audioSlider.setMaximumTrackImage(maxImage, for: UIControl.State())
        self.audioSlider.setThumbImage(thumb, for: UIControl.State())
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
    }
    
    
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
    
    
    //MARK:-Actions
    @IBAction func topPlayerViewTouched(_ sender: Any) {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.07, options: [.beginFromCurrentState], animations: {[weak self]  in
            guard let strongSelf = self else { return }
            
            strongSelf.view.frame = CGRect(x: 0, y: strongSelf.topPositionOfPlayerView, width: strongSelf.view.frame.width, height: strongSelf.view.frame.height)
            
            }, completion: nil)
    }
    
    @IBAction func btnDismissTouched(_ sender: Any) {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.07, options: [.beginFromCurrentState], animations: {[weak self]  in
            guard let strongSelf = self else { return }
            
            strongSelf.view.frame = CGRect(x: 0, y: strongSelf.bottomPositionOfPlayerView, width: strongSelf.view.frame.width, height: strongSelf.view.frame.height)

        }, completion: nil)
    }
    
    
    @IBAction func btnShuffleTouched(_ sender: UIButton) {
        
        self.shuffleAudioListIndexArray.removeAll()
        sender.isSelected = !sender.isSelected
        
        _ = sender.isSelected ? "\(sender.setImage(UIImage(named: "shuffle_s"), for: UIControl.State()))" : "\(sender.setImage(UIImage(named: "shuffle"), for: UIControl.State()))"
    }
    
    
    @IBAction func btnPlayPauseTouched(_ sender : AnyObject) {
        
        _ = self.audioPlayer.isPlaying ? "\(self.audioPlayer.pause())" : "\(self.audioPlayer.play())"
        _ = self.audioPlayer.isPlaying ? "\(self.setPlayImageInPlayButton(false))" : "\(self.setPlayImageInPlayButton(true)))"
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
        self.audioPlayer.currentTime = time
        return MPRemoteCommandHandlerStatus.success;
    }
    
    
    @IBAction func changeAudioLocationSlider(_ sender : UISlider) {
        
        self.audioPlayer.currentTime = TimeInterval(sender.value)
    }
    
    
    @IBAction func btnRepeatTouched(_ sender: UIButton) {
        
        sender.isSelected = !sender.isSelected
        _ = sender.isSelected ? "\(sender.setImage(UIImage(named: "repeat_s"), for: .normal))" : "\(sender.setImage(UIImage(named: "repeat"), for: .normal))"

    }
}


//MARK:-Music player portions!!!
extension MusicPlayerVC{
    
    fileprivate func createSuffleArrayAndPlaySong(){
        
        self.shuffleAudioListIndexArray.append(currentAudioIndex)
        if self.shuffleAudioListIndexArray.count >= audioList.count {
            //            self.setPlayImageInPlayButton(true)
            //            return
            self.shuffleAudioListIndexArray.removeAll()
        }
        
        var randomIndex = 0
        var newIndex = false
        while newIndex == false {
            randomIndex =  Int(arc4random_uniform(UInt32(audioList.count)))
            if self.shuffleAudioListIndexArray.contains(randomIndex) {
                newIndex = false
            }else{
                newIndex = true
            }
        }
        self.currentAudioIndex = randomIndex
        self.prepareAudio()
        self.playAudio()
    }
    
    
    //Sets audio file URL
    func setCurrentAudioPath(){
        let currentAudio = self.audioList[self.currentAudioIndex].songName
        self.currentAudioPath = Bundle.main.path(forResource: currentAudio, ofType: "mp3") ?? ""
        
//        self.currentAudioPath = URL(fileURLWithPath: "file:///var/mobile/Containers/Data/Application/44617FC2-15AF-449D-9BAA-C6E31628187D/Documents/iPhone_5-Alarm.mp3")
    }
    
    
    
    // Prepare audio for playing
    func prepareAudio(){
        self.setCurrentAudioPath()

        do {

            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            }
            else {
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
            }
        }
        catch {}
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {}
        
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        do{
            
            let pathUrl  = URL(fileURLWithPath: self.currentAudioPath)
            self.audioPlayer = try! AVAudioPlayer(contentsOf: pathUrl)

        }catch let error{
            print(error)
        }
        self.audioPlayer.delegate = self
        
        self.audioSlider.maximumValue = CFloat(audioPlayer.duration)
        self.audioSlider.minimumValue = 0.0
        self.audioSlider.value = 0.0
        
        self.audioPlayer.prepareToPlay()

        let time = calculateTimeFromNSTimeInterval(self.audioPlayer.duration)
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
        
        self.audioPlayer.play()
        self.updateLabels()
        self.showMediaInfo()
        _ = audioPlayer.isPlaying ? "\(self.setPlayImageInPlayButton(false), for: UIControl.State()))" : "\(self.setPlayImageInPlayButton(true))"
//        MPMusicPlayerController.applicationMusicPlayer.play()

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
    
    func playNextAudio(){
        
        self.currentAudioIndex += 1
        if self.currentAudioIndex>self.audioList.count-1{
            self.currentAudioIndex -= 1
            
            return
        }
        
        self.prepareAudio()
        self.playAudio()
    }
    
    
    func playPreviousAudio(){
        
        self.currentAudioIndex -= 1
        if self.currentAudioIndex<0{
            self.currentAudioIndex += 1
            return
        }
        
        self.prepareAudio()
        self.playAudio()
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


//MARK:-Animations
extension MusicPlayerVC : UIGestureRecognizerDelegate{
    
    //MARK:- add animation while dragging view
    @objc func wasDragging(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        let translation = gestureRecognizer.translation( in: self.view)
        let velocity = gestureRecognizer.velocity(in: self.view)
        let y = self.view.frame.minY
        
        //translate y postion when drag within topPositionOfPlayerView to bottomPositionOfPlayerView
        if (y + translation.y >= topPositionOfPlayerView) && (y + translation.y <= bottomPositionOfPlayerView) {
            
            self.view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
            gestureRecognizer.setTranslation(CGPoint(x:0,y:0), in: self.view)
        }
        
        if gestureRecognizer.state != .ended{ return}
        
//        print("y + translation.y: \(y + translation.y)")
//        print("View Height: \((self.view.frame.height/2) + self.topPositionOfPlayerView/2)")
//        print("velocity: \(velocity.y)")

        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction], animations: {
            
            if velocity.y < -500{
                self.view.frame = CGRect(x: 0, y: self.topPositionOfPlayerView, width: self.view.frame.width, height: self.view.frame.height)
            }else if velocity.y > 500{
                self.view.frame = CGRect(x: 0, y: self.bottomPositionOfPlayerView, width: self.view.frame.width, height: self.view.frame.height)
            }else{
                
                if y + translation.y <= ((self.view.frame.height/2) + self.topPositionOfPlayerView/2){
                    
                    self.view.frame = CGRect(x: 0, y: self.topPositionOfPlayerView, width: self.view.frame.width, height: self.view.frame.height)
                }else{
                    
                    self.view.frame = CGRect(x: 0, y: self.bottomPositionOfPlayerView, width: self.view.frame.width, height: self.view.frame.height)
                }
            }
        }, completion: nil)
    }
}
