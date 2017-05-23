//
//  Observable+ResponseObjectMapper.swift
//  NetworkDemo
//
//  Created by sijiechen3 on 2017/5/4.
//  Copyright © 2017年 sijiechen3. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import ObjectMapper

struct CommonResponse<T: Mappable>: Mappable {
    var status: String?
    var message: String?
    var data: T?
    
    // 只要结果不符合，直接nil
    init?(map: Map) { }
    
    mutating func mapping(map: Map) {
        status 	<- map["status"]
        message <- map["msg"]
        data    <- map["data"]
    }
}

struct EmptyResponse: Mappable {
    public init?(map: Map) { }
    public mutating func mapping(map: Map) { }
}

public enum ResponseError: Swift.Error {
    case jsonMapping(Response)
    case unknowErrorCode(String, String)
}

extension ResponseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .jsonMapping:
            return "response error json map"
        case .unknowErrorCode:
            return "response error unknow error code"
        }
    }
}

public enum ApiError: Swift.Error {
    case moyaError(MoyaError)
    case responseError(ResponseError)
    case unkownError(Swift.Error)
}

public enum CustomizedOnErrorResult {
    case handled
    case useDefaultOnError(UIViewController)
}

extension ApiError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .moyaError(let moyaError):
            return "api moya error " + (moyaError.errorDescription ?? " with out parameter")
        case .responseError(let responseError):
            return "api response error " + (responseError.errorDescription ?? " with out parameter")
        case .unkownError:
            return "api unkown error"
        }
    }
}

extension ObservableType where Self.E == Response {

    // 这个其实不用的
    public func mapObject<T: Mappable>(type: T.Type) -> Observable<T> {
        return self.map({ response -> T in
            guard let object = Mapper<T>().map(JSONObject: try response.mapJSON()) else {
                throw MoyaError.jsonMapping(response)
            }
            return object
        })
    }

    public func mapResponse<T: Mappable>(type: T.Type) -> Observable<T> {
        
        return self.map({ response -> T in
            // try? 打算mapJSON err throw. 使用 ResponseError.jsonMapping
            guard let object = Mapper<CommonResponse<T>>().map(JSONObject: try? response.mapJSON()),
                let status = object.status,
                let msg = object.message,
                let data = object.data else {
                throw ResponseError.jsonMapping(response)
            }
            
            if status == "ok" {
                
            } else {
                throw ResponseError.unknowErrorCode(status, msg)
            }
            return data
        })
    }

    public func mapEmptyResponse() -> Observable<Void> {
        return self.mapResponse(type: EmptyResponse.self).map({ _ in Void() })
    }
    
    public func mapResponseAndThenSubscribe<T: Mappable>(type: T.Type, onNext: @escaping ((T) -> Void), customizedOnError: @escaping ((ApiError) -> CustomizedOnErrorResult) = { _ in .useDefaultOnError((UIApplication.shared.keyWindow?.rootViewController
)!) }) -> Disposable {
        return self.mapResponse(type: T.self).subscribe(onNext: onNext, onError: { (error) in
            // transform err to apierr first
            let apiError: ApiError = Self.transforErrorToApiError(error: error)
            switch customizedOnError(apiError) {
            case .handled: return
            case .useDefaultOnError(let vc):
                Self.defaultOnError(apiError: apiError, vc: vc)
            }
        }, onCompleted: nil, onDisposed: nil)
    }
    
    fileprivate static func defaultOnError(apiError: ApiError, vc: UIViewController) {
        print (apiError.errorDescription!)
        
        var msg = ""
        switch apiError {
        case .moyaError, .unkownError:
            msg = "网络不给力"
        case .responseError(let responseError):
            switch responseError {
            default:
                msg = "服务器开了小差"
            }
        }
        
        let alert = UIAlertController(title: msg, message: nil, preferredStyle: .alert)
        vc.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) { 
            vc.dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate static func transforErrorToApiError(error: Swift.Error) -> ApiError {
        var apiError: ApiError!
        if error is MoyaError {
            apiError = ApiError.moyaError(error as! MoyaError)
        } else if error is ResponseError {
            apiError = ApiError.responseError(error as! ResponseError)
        } else {
            apiError = ApiError.unkownError(error)
        }
        return apiError
    }
}
