//
//  FLHttpSessionManager.swift
//  swiftLearning
//
//  Created by clarence on 17/2/5.
//  Copyright © 2017年 gitKong. All rights reserved.
//

import UIKit

class FLHttpSessionManager: NSObject {
    
    var session:URLSession?
    var baseUrl:String?
    
//    override init (){
//        super.init()
//        self.session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
//    }
    
    init(baseUrl : String,configuration:URLSessionConfiguration){
        
        super.init()
        
        var url = baseUrl
        // 确保路径有/
        if !url.isEmpty && !url.hasSuffix("/") {
            url = url.appending("/")
        }
        self.baseUrl = url
        
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func fl_GET(urlString:String,params:Dictionary<String,Any>,success:@escaping (URLSessionDataTask,Any)->(),failure:@escaping (URLSessionDataTask,Any)->())->(URLSessionDataTask){
        
        return self.fl_dataTask(urlString: urlString, method: "GET", params: params, success: success, failure: failure)
    }
    
    func fl_POST(urlString:String,params:Dictionary<String,Any>,success:@escaping (URLSessionDataTask,Any)->(),failure:@escaping (URLSessionDataTask,Any)->())->(URLSessionDataTask){
        
        return self.fl_dataTask(urlString: urlString, method: "POST", params: params, success: success, failure: failure)
    }
    
    func fl_dataTask(urlString:String,method:String,params:Dictionary<String,Any>,success:@escaping (URLSessionDataTask,Any)->(),failure:@escaping (URLSessionDataTask,Any)->())->(URLSessionDataTask){
        
        var dataTask:URLSessionDataTask?
        
        dataTask = self.fl_dataTask(url: urlString, httpMethod: method, params: params, completionHandler: { (data, response, error) in
            
            if error != nil {
                var errorMessage:Any = error!
                if error is URLRequestSerializationError{
                    switch error as! URLRequestSerializationError {
                    case URLRequestSerializationError.RequestSerializationNoValueForKey:
                        errorMessage = "========  请求参数拼接中找不到 key 对应的 value 值   ========"
                        break
                        
                    default:
                        break
                        
                    }
                }
                failure(dataTask!,errorMessage)
            }
            else{
                if data != nil {
                    var json:Any?
                    do{
                        try json = JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                    }
                    catch{
                        json = "========  数据通过 JSONSerialization 序列化失败   ========"
                    }
                    success(dataTask!,json!)
                }
                else{
                    success(dataTask!,"data = nil")
                }
            }
        })
        
        return dataTask!
    }
    
    
    
    func fl_dataTask(url:String,httpMethod:String,params:Dictionary<String, Any>,completionHandler:@escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask{
        
        var tempUrl:String?
        // 拼接基路径
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            tempUrl = url
        }
        else{
            
            tempUrl = self.baseUrl?.appending(url)
            // 这个方法不能拼接baseurl
            // URL(string: url.absoluteString, relativeTo: self.baseUrl)
        }
        
        // 判断url是否有效
        assert(tempUrl != "", "url 不能为空")
        
        var request:URLRequest?
        
        var requestError:Error?
        do {
            try request = FLURLRequestSerialization().fl_request(method: httpMethod, urlString: tempUrl!, params: params)
            
        } catch {
            requestError = error
            // 如果有错误，创建一个默认的request
            request = URLRequest(url: URL(string: tempUrl!)!)
        }
        
        let dataTask = self.session!.dataTask(with: request!) { (data, response, error) in
            // 回到主线程
            DispatchQueue.main.async {
                // 如果有自己的错误，返回自己的，没有返回系统的
                completionHandler(data,response,requestError ?? error)
            }
        }
        dataTask.resume()
        
        return dataTask
    }
}

extension FLHttpSessionManager:URLSessionTaskDelegate{
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if(challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust){
            // 使用受保护空间的服务器信任创建凭据
            let credential:URLCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            // 通过 completionHandler 告诉服务器信任证书
            completionHandler(URLSession.AuthChallengeDisposition.useCredential,credential);
        }
    }
}
