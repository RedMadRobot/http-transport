//
//  HTTPRequestParameters
//  HTTPTransport
//
//  Created by Jeorge Taflanidi on 4/18/2017 AD.
//  Copyright (c) 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - HTTPRequestParameters

/// Map of parameters with encoding
open class HTTPRequestParameters {

    // MARK: - Properties

    /// Parameters map
    open var parameters: [String: Any]

    /// Parameters' encoding. Default is JSON
    public let encoding: Encoding

    // MARK: - Initializers

    /// Default initializer
    /// - Parameters:
    ///   - parameters: map of parameters
    ///   - encoding: parameters encoding; default is JSON
    public init(
        parameters: [String: Any],
        encoding: Encoding = Encoding.json
    ) {
        self.parameters = parameters
        self.encoding = encoding
    }

    /// Operate over the parameters map
    public subscript(parameterName: String) -> Any? {
        get {
            return self.parameters[parameterName]
        }
        set(parameterValue) {
            self.parameters[parameterName] = parameterValue
        }
    }

    // MARK: - Encoding

    /// Parameters encoding
    public enum Encoding {

        /// Encode parameters into provided URLRequest
        public typealias EncodeFunction = (_ request: URLRequest, _ parameters: [String: Any]?) throws -> URLRequest

        // MARK: - Cases

        /// JSON-encoded body
        case json

        /// Key=value-encoded URL
        case url

        /// Your custom format
        case custom(encode: EncodeFunction)

        /// Transform `Encoding` into `Alamofire.ParameterEncoding` instance
        func toAlamofire() -> ParameterEncoding {
            switch self {
                case .url: return URLEncoding.default
                case .json: return JSONEncoding.default
                case .custom(let encodeFunction): return CustomEncoder(encodeFunction: encodeFunction)
            }
        }
    }

    // MARK: - CustomEncoder

    fileprivate class CustomEncoder: ParameterEncoding {

        // MARK: - Properties

        private let encodeFunction: Encoding.EncodeFunction

        // MARK: - Initializers

        /// Default initializer
        /// - Parameter encodeFunction: encode function
        init(encodeFunction: @escaping Encoding.EncodeFunction) {
            self.encodeFunction = encodeFunction
        }

        func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
            try self.encodeFunction(try urlRequest.asURLRequest(), parameters)
        }
    }
}
