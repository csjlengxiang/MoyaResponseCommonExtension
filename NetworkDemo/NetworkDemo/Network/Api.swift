//
// Created by sijiechen3 on 2017/5/8.
// Copyright (c) 2017 sijiechen3. All rights reserved.
//

import Moya

public enum ApiRequest {
    case category
}

extension ApiRequest: TargetType {

    public var baseURL: URL {
        return URL(string: "https://iu.snssdk.com")!
    }

    public var path: String {
        switch self {
        case .category:
            return "/article/category/get_subscribed/v1/"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .category:
            return .get
        }
    }

    public var parameters: [String : Any]? {
        switch self {
        case .category:
            return ["iid": 6253487170]
        }
    }

    public var parameterEncoding: ParameterEncoding {
        switch self {
        case .category:
            return URLEncoding.default
        }
    }

    public var task: Task {
        switch self {
        case .category:
            return .request
        }
    }

    public var sampleData: Data {
        switch self {
        case .category:
            return "".data(using: String.Encoding.utf8)!
        }
    }
}

let Api = RxMoyaProvider<ApiRequest>(endpointClosure: MoyaProvider.defaultEndpointMapping, requestClosure: MoyaProvider.defaultRequestMapping, stubClosure: MoyaProvider.neverStub, manager:
{
    let configuration = URLSessionConfiguration.default
    var headers = Manager.defaultHTTPHeaders
    headers["User-Agent"] = "test my user agent"
    configuration.httpAdditionalHeaders = headers
    let manager = Manager(configuration: configuration)
    manager.startRequestsImmediately = false
    return manager
}(), plugins: [NetworkLoggerPlugin()], trackInflights: false)
