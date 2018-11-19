//
//  DownloadManager.swift
//  ATMusicPlayer
//
//  Created by Amrit Tiwari on 9/28/18.
//  Copyright © 2018 Amrit Tiwari. All rights reserved.
//

import Foundation
import UIKit
import AVKit

struct DownloadActivity{
    static let pause = "Pause"
    static let paused = "Paused"
    static let cancel = "Cancel"
    static let resume = "Resume"
    static let download = "Download"
    static let dowloading = "Downloading..."
}

@objc protocol DownloadManagerDelegate : class {
    @objc optional func pauseTapped()
    @objc optional func resumeTapped()
    @objc optional func cancelTapped()
    @objc optional func downloadTapped()
    @objc optional func downloadProgressUpdate(_ progress : Float, withFileSize totalSize : String)
}

class DownloadManager: NSObject{
    
    private static let sharedInstance = DownloadManager()
    
    private override init(){
        super.init()
        
    }
    weak var delegate : DownloadManagerDelegate?
    public var filePaths : URL?
    
    // Accessors
    public class func shared() -> DownloadManager{
        return self.sharedInstance
    }
    
    // SearchViewController creates downloadsSession
//    var downloadsSession: URLSession!
    var activeDownloads: [URL: Download] = [:]
    
    
    // Create downloadsSession here, to set self as delegate
    lazy var downloadsSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration")
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    // Get local file path: download task stores tune here; AV player plays it.
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    func localFilePath(for url: URL) -> URL {
        return documentsPath.appendingPathComponent(url.lastPathComponent)
    }
    
    // MARK: - Download methods called by TrackCell delegate methods
    func startDownload(_ musicVideoDetail: MusicVideoDetail) {
 
        // lets create your destination file url
        let destinationUrl = self.localFilePath(for: musicVideoDetail.previewURL)
        print(destinationUrl)
        
        let download = Download(musicVideoDetail: musicVideoDetail)

        var request = URLRequest(url: musicVideoDetail.previewURL)
        request.httpMethod = "GET"
        
        let fileManager = FileManager.default
        
//        try? fileManager.removeItem(at: destinationUrl)

        if fileManager.fileExists(atPath: destinationUrl.path) {
            let data = try? Data(contentsOf: destinationUrl)
            print(data)
            print("The file already exists at path")
            download.sessionDownloadTask = downloadsSession.downloadTask(withResumeData: data!)

        }else{
            download.sessionDownloadTask = downloadsSession.downloadTask(with: request)
        }
        
//        download.sessionDownloadTask = downloadsSession.downloadTask(with: musicVideoDetail.previewURL)
        download.sessionDownloadTask!.resume()
        download.isDownloading = true
        self.activeDownloads[download.musicVideoDetail.previewURL] = download
        self.delegate?.downloadTapped?()
    }
    
    func pauseDownload(_ musicVideoDetail: MusicVideoDetail) {
        guard let download = activeDownloads[musicVideoDetail.previewURL] else { return }
        
//        AVAssetDownloadURLSession
        
        if download.isDownloading{
            
            download.sessionDownloadTask?.cancel(byProducingResumeData: {[weak self] data in
                guard let `self` = self else { return }

                self.activeDownloads[musicVideoDetail.previewURL]?.resumeData = data
                print(data)
            })
            download.isDownloading = false
        }
        
        self.delegate?.pauseTapped?()
    }
    
    func cancelDownload(_ musicVideoDetail: MusicVideoDetail) {
        if let download = activeDownloads[musicVideoDetail.previewURL] {
            download.sessionDownloadTask?.cancel()
            self.activeDownloads[musicVideoDetail.previewURL] = nil
        }
        self.delegate?.cancelTapped?()

    }
    
    func resumeDownload(_ musicVideoDetail: MusicVideoDetail) {
        guard let download = activeDownloads[musicVideoDetail.previewURL] else { return }
        if let resumeData = download.resumeData {
            download.sessionDownloadTask = downloadsSession.downloadTask(withResumeData: resumeData)
        } else {
            download.sessionDownloadTask = downloadsSession.downloadTask(with: download.musicVideoDetail.previewURL)
        }
        download.sessionDownloadTask!.resume()
        download.isDownloading = true
        self.delegate?.resumeTapped?()
    }
    
}


extension DownloadManager : URLSessionDownloadDelegate{
    
    // Stores downloaded file
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let sourceURL = downloadTask.originalRequest?.url else { return }
        let download = self.activeDownloads[sourceURL]
        self.activeDownloads[sourceURL] = nil
        let destinationURL = localFilePath(for: sourceURL)
        print(destinationURL)
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationURL)
        do {
            try fileManager.copyItem(at: location, to: destinationURL)
            download?.musicVideoDetail.downloaded = true
        } catch let error {
            print("Could not copy file to disk: \(error.localizedDescription)")
        }
//        if let index = download?.musicVideoDetail.index {
//            DispatchQueue.main.async {
//                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
//            }
//        }
    }
    
    // Updates progress info
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url, let download = self.activeDownloads[url]  else { return }
        
        download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite,
                                                  countStyle: .file)
        DispatchQueue.main.async{
            self.delegate?.downloadProgressUpdate?(download.progress, withFileSize: totalSize)
        }
    }

    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64){
        
    }
    
    
//    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
//        NSLog("%@",response.description)
//        completionHandler(NSURLSessionResponseDisposition.BecomeDownload)
//    }
//    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {
//        downloadTask.resume()
//    }
//    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
//        NSLog("%@",location);
//        //Get response
//        NSLog("%@", downloadTask.response!.description)
//
//    }
}


// MARK: - URLSessionDelegate

extension DownloadManager: URLSessionDelegate{
    
    // Standard background session handler
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                completionHandler()
            }
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?){
        
        if let error = error{
            print(error)
        }
    }
    
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
        
        if let error = error{
            print(error)
        }
    }
    
    
    
    public func downloads(_ audioUrl : URL){
        
        // then lets create your document folder url
        guard let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(audioUrl.lastPathComponent)
        print(destinationUrl)
        
        let fileManager = FileManager.default
        
        // to check if it exists before downloading it
        if fileManager.fileExists(atPath: destinationUrl.path) {
            print("The file already exists at path")
            self.filePaths = destinationUrl
            // if the file doesn't exist
        } else {
            
            let defaultSession = URLSession(configuration: .default)
            var dataTask: URLSessionDataTask?
            
            dataTask?.cancel()
            
            dataTask = defaultSession.dataTask(with: audioUrl, completionHandler: { [weak self] (location, response, error) in
                guard let `self` = self else { return }
                defer { dataTask = nil}
                
                guard let location = location, error == nil else {
                    print("DataTask error: " + error!.localizedDescription)
                    return
                }
                
//                do {
//                    // after downloading your file you need to move it to your destination url
//                    try FileManager.default.moveItem(at: location, to: destinationUrl)
//                    print("File moved to documents folder")
//                    self.filePaths = destinationUrl
//                } catch let error as NSError {
//                    print(error.localizedDescription)
//                }
            })
            dataTask?.resume()
        }
    }
}


extension AppDelegate{
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundSessionCompletionHandler = completionHandler
    }
}

/*

 
 /*
 // you can use NSURLSession.sharedSession to download the data asynchronously
 URLSession.shared.downloadTask(with: audioUrl, completionHandler: { [weak self] (location, response, error) -> Void in
 guard let location = location, error == nil else { return }
 guard let `self` = self else { return }
 
 
 do {
 // after downloading your file you need to move it to your destination url
 try FileManager.default.moveItem(at: location, to: destinationUrl)
 print("File moved to documents folder")
 self.filePaths = destinationUrl
 } catch let error as NSError {
 print(error.localizedDescription)
 }
 }).resume()
 */
 }
 }
 
 */
