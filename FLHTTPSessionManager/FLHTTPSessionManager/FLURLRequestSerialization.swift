/*
 * author gitKong
 *
 * gitHub https://github.com/gitkong
 * cocoaChina http://code.cocoachina.com/user/
 * 简书 http://www.jianshu.com/users/fe5700cfb223/latest_articles
 * QQ 279761135
 * 微信公众号 原创技术分享
 * 喜欢就给个like 和 star 喔~
 */

import UIKit

enum URLRequestSerializationError:Error{
    case None// 没错误
    case RequestSerializationNoValueForKey// 没有key对应的value
}

class FLURLRequestSerialization: NSObject {
    /*
     *  @author gitkong
     *
     *  超时时间
     */
    var timeoutInterval:TimeInterval = 10.0
    /*
     *  @author gitkong
     *
     *  请求头
     */
    var mutableHTTPRequestHeaders:NSMutableDictionary?
    
    /*
     *  @author gitkong
     *
     *  缓存策略
     */
    var cachePolicy:URLRequest.CachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
    
    override init (){
        super.init()
        
        self.mutableHTTPRequestHeaders = NSMutableDictionary()
        
        // 初始化必要的请求头
        let acceptLanguagesComponents:NSMutableArray = NSMutableArray()
        
        for idx in 0 ..< Locale.preferredLanguages.count{
            let obj = Locale.preferredLanguages[idx]
            let q = 1.0 - (Double(idx) * 0.1)
            acceptLanguagesComponents.add("".appendingFormat("%@;q=%0.1g",obj,q))
            if q <= 0.5 {
                break
            }
        }
        
        self.fl_setValue(value: acceptLanguagesComponents.componentsJoined(by: ", "), forHTTPHeaderField: "Accept-Language")
        
        var infoDict = Bundle.main.infoDictionary! as [String : Any]
        // iOS
        var userAgent:String = "".appendingFormat("%@/%@ (%@; iOS %@; Scale/%0.2f)", infoDict[kCFBundleExecutableKey as String] as! CVarArg? ?? infoDict[kCFBundleIdentifierKey as String] as! CVarArg,infoDict["CFBundleShortVersionString"] as! CVarArg? ?? infoDict[kCFBundleVersionKey as String] as! CVarArg,UIDevice.current.model,UIDevice.current.systemVersion,UIScreen.main.scale)
        
        if userAgent.canBeConverted(to: String.Encoding.ascii) {
            let mutableUserAgent:NSMutableString = NSMutableString(string: userAgent)
            if CFStringTransform(mutableUserAgent as CFMutableString, nil, "Any-Latin; Latin-ASCII; [:^ASCII:] Remove" as CFString, false) {
                userAgent = mutableUserAgent as String
            }
        }
        
        self.fl_setValue(value: userAgent, forHTTPHeaderField: "User-Agent")
        
    }
    
    
    func fl_request(method:String,urlString:String,params:[String:Any]) throws ->URLRequest{
        
        var bodyStr:String = ""
        do {
            try bodyStr = self.fl_httpBodyString(parmas: params)
        } catch {
            // 继续往上抛
            throw error
        }
        
        let url:URL = URL(string: urlString)!
        
        var request:URLRequest = URLRequest(url: url, cachePolicy: self.cachePolicy, timeoutInterval: self.timeoutInterval)
        // request method
        request.httpMethod = method
        // request header
        self.mutableHTTPRequestHeaders?.enumerateKeysAndObjects({ (field, value, stop) in
            if((request.value(forHTTPHeaderField: field as! String)) == nil){
                request.setValue(value as? String, forHTTPHeaderField: field as! String)
            }
        })
        
        // request data
        if method == "POST" {
            // POST Header
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyStr.data(using: String.Encoding.utf8)
        }
        else if method == "GET"{
            request.url = URL(string: urlString.appending("?"+"\(bodyStr)"))!
        }
        
        return request
    }
    
    
    private func fl_setValue(value:String,forHTTPHeaderField field:String){
        self.mutableHTTPRequestHeaders?.setValue(value, forKey: field)
    }
    
    private func fl_httpBodyString(parmas:Dictionary<String, Any>) throws ->String{
        let tempArr = NSMutableArray()
        // test
//        throw URLRequestSerializationError.RequestSerializationNoValueForKey
        for key in parmas.keys {
            // 解包去掉optional
            guard parmas[key] != nil else {
                throw URLRequestSerializationError.RequestSerializationNoValueForKey
            }
            let value = parmas[key]!
            print("----------value = \(value)")
            tempArr.add("\(key)"+"="+"\(value)")
        }
        return tempArr.componentsJoined(by: "&")
    }
}
