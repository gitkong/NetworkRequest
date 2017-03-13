//
//  VZNetworkTool.swift
//  betterShop
//
//  Created by clarence on 17/3/10.
//  Copyright © 2017年 vzan. All rights reserved.
//

import UIKit
import Alamofire

typealias Complete = (_ isSuccess:Bool,_ data:[String:AnyObject]?,_ error:Error?)->()

class FLNetworkTool: NSObject {
    static let shared:FLNetworkTool = FLNetworkTool()
    /*
     *  @author gitkong
     *
     *  base url
     */
    var baseUrl:String? = nil
    /*
     *  @author gitkong
     *
     *  统一设置请求头
     */
    var headers:HTTPHeaders? = nil
    /*
     *  @author gitkong
     *
     *  统一设置编码方式
     */
    var encoding: ParameterEncoding = URLEncoding.default
    
    /*
     *  @author gitkong
     *
     *  自动判断所需的返回值类型要求
     */
    let validateContentType = ["application/json",
                                       "text/html",
                                       "text/json",
                                       "text/plain",
                                       "text/javascript",
                                       "text/xml",
                                       "image/*"
    ]
    
    lazy var manager : SessionManager = {
        let config:URLSessionConfiguration = URLSessionConfiguration.default
        //设置超时时间为15S
        config.timeoutIntervalForRequest = 15
        //根据config创建manager
        return SessionManager(configuration: config)
    }()
    
    /*
     *  @author gitkong
     *
     *  对外readonly 对内readwrite（同一个extension中）
     */
    private(set) var isListening:Bool = false
    
    
    fileprivate let networkReachability = NetworkReachabilityManager()
    
    func monitor(_ handler:@escaping (NetworkReachabilityManager.NetworkReachabilityStatus) -> Void) {
        networkReachability?.listener = {
            (status) in
            handler(status)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(foreground), name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(background), name: NSNotification.Name(rawValue: "UIApplicationDidEnterBackground"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func foreground() {
        if !isListening {
            isListening = networkReachability!.startListening()
        }
    }
    
    
    @objc fileprivate func background() {
        if isListening{
            networkReachability!.stopListening()
            isListening = false
        }
    }
}


/*
 *  @author gitkong
 *
 *  公开请求方法
 */
extension FLNetworkTool{
    /*
     *  @author gitkong
     *
     *  GET 请求
     */
    @discardableResult func GET(_ url:String,params:Parameters?,complete:@escaping Complete) -> DataRequest{
       return self.request(url, method: .get, parameters: params, encoding: encoding,headers:headers,complete: complete)
    }
    /*
     *  @author gitkong
     *
     *  POST 请求
     */
    @discardableResult func POST(_ url:String,params:Parameters?,complete:@escaping Complete) -> DataRequest {
        return self.request(url, method: .post, parameters: params, encoding: encoding,headers:headers,complete: complete)
    }
    /*
     *  @author gitkong
     *
     *  数据上传
     */
    @discardableResult func UPLOAD(data:Data,url:String,complete:@escaping Complete) -> DataRequest {
        return self.upload(data: data, url: url, method: .post, headers: headers, complete: complete)
    }
    
}
/*
 *  @author gitkong
 *
 *  私有方法
 */
extension FLNetworkTool{
    /*
     *  @author gitkong
     *
     *  私有方法-隔离框架request方法
     */
    fileprivate func request(_ url: String,
                             method: HTTPMethod = .get,
                             parameters: Parameters? = nil,
                             encoding: ParameterEncoding = URLEncoding.default,
                             headers: HTTPHeaders? = nil,complete:@escaping Complete) -> DataRequest{
        var tempUrl = url
        if !tempUrl.hasPrefix("http://") && !tempUrl.hasPrefix("https://")  {
            if let temp = self.baseUrl{
                tempUrl = temp.isEmpty ? tempUrl : temp.appending(tempUrl)
            }
        }
        var tempParams:Parameters = Dictionary()
        if parameters != nil {
            tempParams = parameters!
        }
        return manager.request(tempUrl, method: method, parameters: tempParams, encoding: encoding, headers: headers)
            /*
             *  @author gitkong
             *
             *  不传参数：开启自动验证数据，自动判断返回code是否在200…299之间，并不会加以判断返回的数据类型 ，除非添加header（此时添加header：["Accept": "application/json"]，那么如果返回数据不是json，那么就会判断为错误）
             */
//            .validate()
            .validate(statusCode:200..<300)
            .validate(contentType: validateContentType)
            .responseJSON {[unowned self] (response) in
                self.handleResponse(response: response, complete: complete)
            }
    }
    /*
     *  @author gitkong
     *
     *  私有方法-隔离upload方法
     */
    fileprivate func upload(data:Data,url:String,method:HTTPMethod? = .post,headers:HTTPHeaders? = nil,complete:@escaping Complete) -> DataRequest{
        return manager.upload(data, to: url, method: method!, headers: headers)
            .validate(statusCode:200..<300)
            .validate(contentType: validateContentType)
            .responseJSON {[unowned self] (response) in
                self.handleResponse(response: response, complete: complete)
        }
    }
    
    fileprivate func handleResponse(response:DataResponse<Any>,complete:@escaping Complete){
        switch response.result {
        case .success(let value):
            if let value = value as? [String : AnyObject] {
                complete(true, value, nil)
            }
        case .failure(let error):
            complete(false, nil, error)
        }
    }
    
    
}

