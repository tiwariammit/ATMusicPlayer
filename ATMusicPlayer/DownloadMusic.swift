//
//  DownloadMusic.swift
//  ATMusicPlayer
//
//  Created by Amrit Tiwari on 9/28/18.
//  Copyright © 2018 Amrit Tiwari. All rights reserved.
//

import Foundation

class DownloadMusicManager: NSObject{
    
    private static let sharedInstance = DownloadMusicManager()
    
    private override init(){
        super.init()
        
    }
    
    public var filePaths : URL?
    
    // Accessors
    public class func shared() -> DownloadMusicManager{
        return sharedInstance
    }
    
    
    
    public func download(_ audioUrl : URL){
        
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
            
            // you can use NSURLSession.sharedSession to download the data asynchronously
            URLSession.shared.downloadTask(with: audioUrl, completionHandler: { [weak self] (location, response, error) -> Void in
                guard let location = location, error == nil else { return }
                guard let strongSelf = self else { return }
                
                do {
                    // after downloading your file you need to move it to your destination url
                    try FileManager.default.moveItem(at: location, to: destinationUrl)
                    print("File moved to documents folder")
                    strongSelf.filePaths = destinationUrl
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }).resume()
        }
    }
}
