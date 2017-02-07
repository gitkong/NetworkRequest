//
//  FLURLSessionManager.swift
//  FLHTTPSessionManager
//
//  Created by clarence on 17/2/7.
//  Copyright © 2017年 gitKong. All rights reserved.
//

import UIKit

//声明一个闭包类型
typealias FLURLSessionTaskProgressBlock = (Progress)->()
typealias FLURLSessionTaskCompletionHandler = (URLResponse,Any,Error)->()

typealias FLURLSessionDownloadTaskDidFinishDownloadingBlock = (URLSession,URLSessionDownloadTask,URL)->(URL)

class FLURLSessionManagerTaskDelegate:NSObject,URLSessionDataDelegate,URLSessionTaskDelegate,URLSessionDownloadDelegate{
    var downloadProgress:Progress?
    var uploadProgress:Progress?
    var mutableData:Data?
    
    /*
     *  @author gitkong
     *
     *  下载文件url
     */
    var downloadFileURL:URL?
    /*
     *  @author gitkong
     *
     *  上传回调
     */
    var uploadProgressBlock:FLURLSessionTaskProgressBlock?
    /*
     *  @author gitkong
     *
     *  下载回调
     */
    var downloadProgressBlock:FLURLSessionTaskProgressBlock?
    
    var downloadTaskDidFinishDownloading:FLURLSessionDownloadTaskDidFinishDownloadingBlock?
    
    init(task:URLSessionTask) {
        super.init()
        self.mutableData = Data()
        self.downloadProgress = Progress(parent: nil, userInfo: nil)
        self.uploadProgress = Progress(parent: nil, userInfo: nil)
        weak var weakTask = task
        for progress in [self.uploadProgress,self.downloadProgress] {
            progress?.totalUnitCount = NSURLSessionTransferSizeUnknown
            progress?.isCancellable = true
            progress?.cancellationHandler = {
                ()->()
                in
               weakTask?.cancel()
            }
            progress?.isPausable = true
            progress?.pausingHandler = {
                ()->()
                in
                weakTask?.suspend()
            }
            // 是否有设置resume
            if (progress?.responds(to: #selector(setter: progress?.resumingHandler)))! {
                progress?.resumingHandler = {
                    () in
                    weakTask?.resume()
                }
            }
            progress?.addObserver(self, forKeyPath: String(NSStringFromSelector(#selector(getter: progress?.fractionCompleted))), options: NSKeyValueObservingOptions.new, context: nil)
        }
    }
    
    deinit{
        self.downloadProgress?.removeObserver(self, forKeyPath: String(NSStringFromSelector(#selector(getter: self.downloadProgress?.fractionCompleted))))
        self.uploadProgress?.removeObserver(self, forKeyPath: String(NSStringFromSelector(#selector(getter: self.uploadProgress?.fractionCompleted))))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object is Progress {
            // 执行回调
            if (object as? Progress == self.downloadProgress) {
                if self.downloadProgressBlock != nil {
                    self.downloadProgressBlock!((object as? Progress)!)
                }
            }
            else if(object as? Progress == self.uploadProgress){
                if self.uploadProgressBlock != nil {
                    self.uploadProgressBlock!((object as? Progress)!)
                }
            }
        }
    }
    
    // URLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
    }
    
    // NSURLSessionDataDelegate
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.mutableData?.append(data)
        self.downloadProgress?.totalUnitCount = dataTask.countOfBytesExpectedToReceive
        self.downloadProgress?.completedUnitCount = dataTask.countOfBytesReceived
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        self.uploadProgress?.totalUnitCount = task.countOfBytesExpectedToSend
        self.uploadProgress?.completedUnitCount = task.countOfBytesSent
    }
    
    // URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.downloadProgress?.totalUnitCount = totalBytesExpectedToWrite
        self.downloadProgress?.completedUnitCount = totalBytesWritten
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        self.downloadProgress?.totalUnitCount = expectedTotalBytes
        self.downloadProgress?.completedUnitCount = fileOffset
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.downloadFileURL = nil
        if self.downloadTaskDidFinishDownloading != nil {
            self.downloadFileURL = self.downloadTaskDidFinishDownloading!(session,downloadTask,location)
            if self.downloadFileURL != nil {
                do {
                    try FileManager.default.moveItem(at:location , to: self.downloadFileURL!)
                    
                    // 发送通知
                    
                } catch {
                    print("moveItem error")
                }
                
            }
        }
    }
}

class FLURLSessionManager: NSObject {

}
