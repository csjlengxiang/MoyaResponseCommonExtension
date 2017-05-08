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

public struct EmptyResponse: Mappable {
    public init?(map: Map) { }
    public mutating func mapping(map: Map) { }
}

enum ResponseError: Swift.Error {
    case jsonMapping(Response)
    case invalidSession(String)
    case unknowErrorCode(String)
}

extension ResponseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .jsonMapping:
            return "response error json map"
        case .invalidSession:
            return "response error invalid session"
        case .unknowErrorCode:
            return "response error unknow error code"
        }
    }
}

enum ApiError: Swift.Error {
    case moyaError(MoyaError)
    case responseError(ResponseError)
    case unkownError(Swift.Error)
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
                let _ = object.message,
                let data = object.data else {
                throw ResponseError.jsonMapping(response)
            }
            
            if status == "ok" {
                
            } else if (status == "invalid_session") {
                throw ResponseError.invalidSession(status)
            } else {
                throw ResponseError.unknowErrorCode(status)
            }
            return data
        })
    }

    public func mapEmptyResponse() -> Observable<EmptyResponse> {
        return self.mapResponse(type: EmptyResponse.self)
    }
    
    public func mapResponseAndThenSubscribe<T: Mappable>(type: T.Type, onNext: ((T) -> Void)? = nil, customizedOnError: ((Swift.Error) -> Bool)? = nil) -> Disposable {
        
        return self.mapResponse(type: T.self).subscribe(onNext: onNext, onError: { (error) in
            if ((customizedOnError != nil) && customizedOnError!(error)) {
                return
            }
            Self.onCommonError(error: error)
            
        }, onCompleted: nil, onDisposed: nil)
    }
    
    // onFailure return true 表示使用了自己的错误处理函数，即不使用通用错误处理
    public func mapResponseAndThenSubscribe2<T: Mappable>(type: T.Type, onNext: ((T) -> Void)? = nil, customizedOnError: ((Swift.Error) -> Bool)? = nil) -> Disposable {
        
        let onResponseNext: ((E) -> Void) = { response in
            guard let object = Mapper<CommonResponse<T>>().map(JSONObject: try? response.mapJSON()),
                let status = object.status,
                let _ = object.message,
                let data = object.data else {
                    Self.onCommonError(error: ApiError.responseError(ResponseError.jsonMapping(response)))
                    return ;
            }
            if status == "ok" {
                onNext?(data)
            } else if (status == "invalid_session") {
                Self.onCommonError(error: ApiError.responseError(ResponseError.invalidSession(status)))
            } else {
                Self.onCommonError(error: ApiError.responseError(ResponseError.unknowErrorCode(status)))
            }
        }
    
        let onResponseError: ((Swift.Error) -> Void)? = { err in
            if ((customizedOnError != nil) && customizedOnError!(err)) {
                return
            }
            Self.onCommonError(error: err)
        }
        
        return self.subscribe(onNext: onResponseNext, onError: onResponseError, onCompleted: nil, onDisposed: nil)
    }
    
    fileprivate static func onCommonError(error: Swift.Error) {
        
        let apiError: ApiError = Self.transforErrorToApiError(error: error)
        print (apiError.errorDescription!)
        
        switch apiError {
        case .moyaError, .unkownError:
            print ("process moya error: 网络不给力")
        case .responseError(let responseError):
            switch responseError {
            case .invalidSession:
                print ("process response error: 请重新登陆啊")
            default:
                print ("process response error: 服务器开了小差")
            }
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
