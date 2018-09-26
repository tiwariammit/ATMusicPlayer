//
//  ViewController.swift
//  ATMusicPlayer
//
//  Created by Amrit Tiwari on 9/25/18.
//  Copyright © 2018 Amrit Tiwari. All rights reserved.
//

import UIKit

class MusicListVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var audioList : [AudioDetails] = []{
        didSet{
            self.tableView.reloadData()
        }
    }

    fileprivate var musicPlayerVC : MusicPlayerVC?
    fileprivate var gesture : UIPanGestureRecognizer?
    
    var topPositionOfPlayerView: CGFloat = -70

    var bottomPositionOfPlayerView: CGFloat {
        return UIScreen.main.bounds.height + self.topPositionOfPlayerView
    }
    
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
        self.musicPlayerVC?.dismissTrigger = { [weak self]  in
            guard let strongSelf = self else { return }
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.07, options: [.beginFromCurrentState], animations: {
                strongSelf.musicPlayerVC?.view.frame = CGRect(x: 0, y: strongSelf.bottomPositionOfPlayerView, width: strongSelf.view.frame.width, height: strongSelf.view.frame.height - strongSelf.topPositionOfPlayerView - 5)
            }, completion: nil)
        }
        
        gesture = UIPanGestureRecognizer(target: self, action: #selector(self.wasDragging(_:)))
        self.musicPlayerVC?.view.addGestureRecognizer(gesture!)
        self.musicPlayerVC?.view.isUserInteractionEnabled = true
        gesture?.delegate = self
    }
    
    
    //MARK:- add animation while dragging view
    @objc func wasDragging(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        guard let guestureView = gestureRecognizer.view else {
            return
        }
        
        let translation = gestureRecognizer.translation( in: self.view)
        let velocity = gestureRecognizer.velocity(in: guestureView)
        let y = guestureView.frame.minY
        
        //translate y postion when drag within fullview to partial view
        if (y + translation.y >= topPositionOfPlayerView) && (y + translation.y <= bottomPositionOfPlayerView) {
            
            guestureView.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height  - self.topPositionOfPlayerView)
            gestureRecognizer.setTranslation(CGPoint(x:0,y:0), in: self.view)
        }
        if gestureRecognizer.state == .ended {
            var duration =  velocity.y < 0 ? Double((y - topPositionOfPlayerView) / -velocity.y) : Double((bottomPositionOfPlayerView - y) / velocity.y )
            
            duration = duration > 1.5 ? 1 : duration
            UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
                if  velocity.y >= 0 {
                    guestureView.frame = CGRect(x: 0, y: self.bottomPositionOfPlayerView, width: self.view.frame.width, height: self.view.frame.height - self.topPositionOfPlayerView - 5)
                } else {
                    
                    guestureView.frame = CGRect(x: 0, y: self.topPositionOfPlayerView, width: self.view.frame.width, height: self.view.frame.height - self.topPositionOfPlayerView - 5)
                }
                
            }, completion: nil)
        }
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
        
        self.addChild(contentView)
        self.view.addSubview(contentView.view)

        contentView.didMove(toParent: self)
        contentView.view.frame = CGRect(x: 0, y: self.bottomPositionOfPlayerView - self.topPositionOfPlayerView, width: self.view.frame.width, height: self.view.frame.height - self.topPositionOfPlayerView)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.07, options: [.beginFromCurrentState], animations: {
            
            contentView.view.frame = CGRect(x: 0, y: self.topPositionOfPlayerView, width: self.view.frame.width, height: self.view.frame.height - self.topPositionOfPlayerView)

        }, completion: nil)
    }
    
    fileprivate func removeContainerView(_ contentView: UIViewController?){
        
        contentView?.willMove(toParent: nil)
        contentView?.view.removeFromSuperview()
        contentView?.removeFromParent()
        
        self.musicPlayerVC?.view.removeFromSuperview()
        self.musicPlayerVC?.removeFromParent()
    }
}
