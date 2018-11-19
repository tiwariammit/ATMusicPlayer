//
//  ViewController.swift
//  ATMusicPlayer
//
//  Created by Amrit Tiwari on 9/25/18.
//  Copyright © 2018 Amrit Tiwari. All rights reserved.
//

import UIKit

class MusicListVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var audioList : [AudioDetails] = []{
        didSet{
            self.tableView.reloadData()
        }
    }

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblProgress: UILabel!
    @IBOutlet weak var btnPauseResume: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnDownload: UIButton!
    
    fileprivate var musicPlayerVC : MusicPlayerVC?
    let downloadManager = DownloadManager.shared()
    var musicVideoDetails : MusicVideoDetail!
    
//    @IBAction func btnTouched(_ sender: Any) {
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        
        tableView.backgroundColor = UIColor.darkGray
        tableView.tableFooterView = UIView()
        
        AudioListModel.readFromPlist { [weak self]
            (data) in
            guard let strongSelf = self else { return }
            strongSelf.audioList = data
            strongSelf.setUpMusicPlayerVC()
        }
        
//        let dmManager = DownloadMusicManager.shared()
//        let urlString = "http://freetone.org/ring/stan/iPhone_5-Alarm.mp3"
//        let url = URL(string: urlString)
//        dmManager.downloads(url!)
        
        self.btnPauseResume.setTitle(DownloadActivity.pause, for: .normal)
        self.btnCancel.setTitle(DownloadActivity.cancel, for: .normal)
        self.btnDownload.setTitle(DownloadActivity.download, for: .normal)
        self.lblProgress.text = DownloadActivity.dowloading
        self.lblProgress.isHidden = true
        self.progressView.isHidden = true
        self.btnCancel.isHidden = true
        self.btnPauseResume.isHidden = true
        self.downloadManager.delegate = self
    }
    
    private func setUpMusicPlayerVC(){
        
        self.musicPlayerVC = self.storyboard?.instantiateViewController(withIdentifier: "MusicPlayerVC") as? MusicPlayerVC        
    }
    
    fileprivate func processDownload(){
        
        self.progressView.isHidden = false
        self.lblProgress.isHidden = false
        self.btnCancel.isHidden = false
        self.btnPauseResume.isHidden = false
        self.btnDownload.isHidden = true

        print(self.downloadManager.activeDownloads)
        
    }
    
    //MARK:-Actions
    @IBAction func btnDownloadTouched(_ sender: Any){
        
        let rawString = "https://mnmott.nettvnepal.com.np/test01/sample_movie.mp4/playlist.m3u8?attachment=true"
        
//        let urlString = "https://audio-ssl.itunes.apple.com/apple-assets-us-std-000001/AudioPreview118/v4/cd/e2/3c/cde23c28-74d2-5423-dc20-273241983ebc/mzaf_6066839747241472565.plus.aac.p.m4a"
        
        let urlString = rawString.replacingOccurrences(of: "/playlist.m3u8", with: "")
        guard let url = URL(string: urlString) else { return }
        self.musicVideoDetails = MusicVideoDetail(previewURL: url)
        self.downloadManager.startDownload(musicVideoDetails)
        self.processDownload()
    }
    
    @IBAction func btnPauseResumeTouched(_ sender: UIButton){
        
        var title = DownloadActivity.pause
        var status = DownloadActivity.dowloading
        
        if(self.btnPauseResume.titleLabel!.text == DownloadActivity.pause) {
            self.downloadManager.pauseDownload(self.musicVideoDetails)
            title = DownloadActivity.resume
            status = DownloadActivity.pause
        } else {
            self.downloadManager.resumeDownload(self.musicVideoDetails)
            title = DownloadActivity.pause
            status = DownloadActivity.dowloading
        }
        
        self.lblProgress.text = status
        self.btnPauseResume.setTitle(title, for: UIControl.State())
    }
    
    @IBAction func btnCancelTouched(_ sender: Any){
        self.downloadManager.cancelDownload(self.musicVideoDetails)
    }
    
}


extension MusicListVC : UITableViewDelegate,UITableViewDataSource{
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.contentView.backgroundColor = .clear
        cell.backgroundColor = .clear
        
        let songName = self.audioList[indexPath.row].songName
        let albumName = self.audioList[indexPath.row].albumName
        
        cell.textLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-BookIta", size: 25.0)
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = songName
        
        cell.detailTextLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-Book", size: 16.0)
        cell.detailTextLabel?.textColor = UIColor.white
        cell.detailTextLabel?.text = albumName
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }
    
    
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        self.musicPlayerVC?.audioList = self.audioList
        self.musicPlayerVC?.currentAudioIndex = indexPath.row
        self.addMusicPlayerContainerView(self.musicPlayerVC!)
//        self.navigationController?.pushViewController(self.musicPlayerVC!, animated: true)
    }
}


//MARK:- Add container view.
extension MusicListVC {
    
    fileprivate func addMusicPlayerContainerView(_ contentView: UIViewController){
        
        self.removeContainerView(contentView)
        
        contentView.view.frame = CGRect(x: 0, y: UIScreen.main.bounds.height + 100, width: self.view.frame.width, height: self.view.frame.height)

        self.addChild(contentView)
        self.view.addSubview(contentView.view)

        contentView.didMove(toParent: self)
    }
    
    fileprivate func removeContainerView(_ contentView: UIViewController?){
        
        contentView?.willMove(toParent: nil)
        contentView?.view.removeFromSuperview()
        contentView?.removeFromParent()
        
        self.musicPlayerVC?.view.removeFromSuperview()
        self.musicPlayerVC?.removeFromParent()
    }
}

extension MusicListVC : DownloadManagerDelegate{
    func downloadProgressUpdate(_ progress: Float, withFileSize totalSize: String) {
        self.progressView.progress = progress
        let progressD =  String(format: "%.1f%% of %@", progress * 100, totalSize)
        self.lblProgress.text = progressD
    }
    
    func cancelTapped() {
        self.btnPauseResume.setTitle(DownloadActivity.pause, for: .normal)
        self.lblProgress.text = DownloadActivity.dowloading
        self.lblProgress.isHidden = true
        self.progressView.isHidden = true
        self.btnCancel.isHidden = true
        self.btnPauseResume.isHidden = true
        self.btnDownload.isHidden = false
    }
}
