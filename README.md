### Demo说明
	本demo是针对Moya/RxSwift的Response，做的ObjectMapper扩展

#### 针对解决如下常见问题
	通常后台返回的数据模型如下：
	
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
一般数据里带有常见状态和后台返回的错误信息...
当后台运行正确时候，数据长这个样子

	status = "ok", message = "ok"
	
	然后data里包装了一个正确的model数据
	
错误时候:

	status = "unkown_error" | "invalid_session"
	message = "未知错误" | "您的一台手机从其他地方登陆balabala"

#### 解决方案

对Moya/RxSwift的Response做extension，增加一个mapResponse函数，采用ObjectMapper做json转换：
		
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
    
#### 然后就有新的问题了
	对于CommonResponse我们肯定是要处理的，然而每次subscribe时候都在onError里写一坨代码也是很尴尬
#### 解决方案

	继续extension，加入mapResponseAndThenSubscribe，我们先来看

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

参照Subscribe函数，对onNext onError提前做好封装，要求用户填入customizedOnError，当customizedOnError返回true时候，不执行通用的错误处理。当然啦，你也可随意调整逻辑，这里只是丢了个砖

	跟mapResponse结合起来就如下了
	
    public func mapResponseAndThenSubscribe<T: Mappable>(type: T.Type, onNext: ((T) -> Void)? = nil, customizedOnError: ((Swift.Error) -> Bool)? = nil) -> Disposable {
        
        return self.mapResponse(type: T.self).subscribe(onNext: onNext, onError: { (error) in
            if ((customizedOnError != nil) && customizedOnError!(error)) {
                return
            }
            Self.onCommonError(error: error)
            
        }, onCompleted: nil, onDisposed: nil)
    }

