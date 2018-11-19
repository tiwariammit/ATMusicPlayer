//
//  AppDelegate.swift
//  ATMusicPlayer
//
//  Created by Amrit Tiwari on 9/25/18.
//  Copyright © 2018 Amrit Tiwari. All rights reserved.
//


import Foundation.NSURL

// Query service creates Track objects
class MusicVideoDetail {


  let previewURL: URL
  var downloaded = false

  init(previewURL: URL) {
   
    self.previewURL = previewURL
  }
}
