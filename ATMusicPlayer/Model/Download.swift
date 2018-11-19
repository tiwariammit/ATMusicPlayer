//
//  AppDelegate.swift
//  ATMusicPlayer
//
//  Created by Amrit Tiwari on 9/25/18.
//  Copyright © 2018 Amrit Tiwari. All rights reserved.
//



import Foundation

// Download service creates Download objects
class Download {

  var musicVideoDetail: MusicVideoDetail
  init(musicVideoDetail: MusicVideoDetail) {
    self.musicVideoDetail = musicVideoDetail
  }

  // Download service sets these values:
  var sessionDownloadTask: URLSessionDownloadTask?
  var isDownloading = false
  var resumeData: Data?

  // Download delegate sets this value:
  var progress: Float = 0

}
