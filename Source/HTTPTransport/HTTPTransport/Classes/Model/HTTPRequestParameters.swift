//
//  HTTPRequestParameters
//  HTTPTransport
//
//  Created by Jeorge Taflanidi on 4/18/2017 AD.
//  Copyright (c) 2017 RedMadRobot LLC. All rights reserved.
//


import Foundation
import Alamofire


/**
 Map of parameters with encoding.
 */
open class HTTPRequestParameters {

    /**
     Parameters map.
     */
    open var parameters: [String: Any]

    /**
     Parameters' encoding. Default is JSON.
     */
    open let encoding:   Encoding

    /**
     Initializer.

     - parameter parameters: map of parameters;
     - parameter encoding: parameters' encoding; default is JSON.
     */
    public init(
        parameters: [String: Any],
        encoding: Encoding = Encoding.json
    ) {
        self.parameters = parameters
        self.encoding = encoding
    }

    /**
     Operate over the parameters map.
     */
    public subscript(parameterName: String) -> Any? {
        get {
            return self.parameters[parameterName]
        }

        set(parameterValue) {
            self.parameters[parameterName] = parameterValue
        }
    }

    /**
     Parameters encoding.
     */
    public enum Encoding {

        /**
         Encode parameters into provided URLRequest.
         */
        public typealias EncodeFunction = (_ request: URLRequest, _ parameters: [String: Any]?) throws -> URLRequest

        /**
         JSON-encoded body.
         */
        case json

        /**
         Key=value-encoded URL.
         */
        case url

        /**
         Key=value-encoded body.
         */
        case propertyList

        /**
         Your custom format.
         */
        case custom(encode: EncodeFunction)

        /**
         Transform `Encoding` into `Alamofire.ParameterEncoding` instance.
         */
        func toAlamofire() -> ParameterEncoding {
            switch self {
                case .url: return URLEncoding.default
                case .json: return JSONEncoding.default
                case .propertyList: return PropertyListEncoding.default
                case .custom(let encodeFunction): return CustomEncoder(encodeFunction: encodeFunction)
            }
        }
    }

    fileprivate class CustomEncoder: ParameterEncoding {

        private let encodeFunction: Encoding.EncodeFunction

        init(encodeFunction: @escaping Encoding.EncodeFunction) {
            self.encodeFunction = encodeFunction
        }

        func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
            return try self.encodeFunction(try urlRequest.asURLRequest(), parameters)
        }

    }

}
