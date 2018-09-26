//
//  MusicModel.swift
//  ATMusicPlayer
//
//  Created by Amrit Tiwari on 9/25/18.
//  Copyright © 2018 Amrit Tiwari. All rights reserved.
//

import Foundation

class AudioListModel {
    
    
    //Read plist file and creates an array of dictionary
    class func readFromPlist(onCompletion datas : (([AudioDetails])->Void)? =  nil){
        
        
        guard let path = Bundle.main.path(forResource: "list", ofType: "plist") else {
            return
        }
        guard let data = NSArray(contentsOfFile:path) else {
            return
        }
        var dataList = [AudioDetails]()

        
        for item in data{
            let dic = item as! NSDictionary
            let albumArtwork = dic.value(forKey: "albumArtwork") as! String
            let albumName = dic.value(forKey: "albumName") as! String
            let artistName = dic.value(forKey: "artistName") as! String
            let songName = dic.value(forKey: "songName") as! String
            let details = AudioDetails.init(songName: songName, albumName: albumName, albumArtwork: albumArtwork, artistName: artistName)
            dataList.append(details)
        }
        
        datas?(dataList)
    }
}

class  AudioDetails {
    
    var songName : String
    var albumName : String
    var albumArtwork : String
    var artistName : String
    
    init(songName : String,albumName : String,albumArtwork : String,artistName : String) {
        self.songName = songName
        self.albumName = albumName
        self.albumArtwork = albumArtwork
        self.artistName = artistName
    }
}
