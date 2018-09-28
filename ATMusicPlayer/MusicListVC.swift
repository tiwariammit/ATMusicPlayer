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

    fileprivate var musicPlayerVC : MusicPlayerVC?
   
    
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
        
    }
    
    private func setUpMusicPlayerVC(){
        
        self.musicPlayerVC = self.storyboard?.instantiateViewController(withIdentifier: "MusicPlayerVC") as? MusicPlayerVC        
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
