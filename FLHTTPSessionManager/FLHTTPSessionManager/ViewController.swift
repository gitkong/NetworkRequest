//
//  ViewController.swift
//  FLHTTPSessionManager
//
//  Created by clarence on 17/2/6.
//  Copyright © 2017年 gitKong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // GET
        let baseUrl:String = "http://60.205.59.95"
        let url:String = "/v1/dish/info"
        
        // POST
//        let url:String = "/Ajax/ckUserFocus"
//        let baseUrl:String = "http://liveapi.vzan.com"
        let manager = FLHttpSessionManager(baseUrl: baseUrl, configuration: URLSessionConfiguration.default)
        
        
        
        
        // GET
        let get_params:[String:Any] = [
            "code":84758768
        ]
        /*
         *  @author gitkong
         *
         *  正常闭包回调
         */
        _ = manager.fl_GET(urlString: url, params: get_params, success: { (dataTask, data) in
            print("\(data)")
        }, failure: { (dataTask, error) in
            print("\(error)")
        })
        
        /*
         *  @author gitkong
         *
         *  使用结构体回调
         */
        _ = manager.fl_GET(urlString: url, params: get_params, complete:Result(success: { (task, data) in
            print("\(data)")
        }, failure: { (dask, error) in
            print("\(error)")
        }))
        
        /*
         *  @author gitkong
         *
         *  使用枚举回调
         */
        _ = manager.fl_GET(urlString: url, params: get_params, complete: { (response) in
            
            switch response{
            case .success(_, let data):
                print("\(data)")
                break
                
            case .failure(_,let error):
                print("\(error)")
                break
            }
        })
        
        
//        let post_params:[String:Any] = [
//            "deviceType" : 2,
//            "sign" : "D850556EE632E270ACEC2714BA07C69EFED6406E1FB8E8264EBCECD8958A9B289C0CAE35AA5C2BAE",
//            "timestamp" : 1486286686332,
//            "uid" : "oW2wBwStFjhB_6oAWRDC2ocW2sSs",
//            "versionCode" : "2.0.6",
//            "zbid" : 162120
//        ]
//        
//        _ = manager.fl_POST(urlString: url, params: post_params, success: { (dataTask, data) in
//            
//            print("\(data)")
//            
//        }, failure: { (dataTask, error) in
//            
//            print("\(error)")
//        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

