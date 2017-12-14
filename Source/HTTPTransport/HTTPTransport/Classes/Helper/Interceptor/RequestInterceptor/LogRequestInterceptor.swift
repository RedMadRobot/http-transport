//
//  LogRequestInterceptor
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2017 RedMadRobot LLC. All rights reserved.
//


import Foundation


/**
 Logs every HTTP request with selected level of details.
 */
open class LogRequestInterceptor: HTTPRequestInterceptor {

    /**
     Output detail level.
     */
    open let logLevel: LogLevel

    /**
     Initializer.
     
     - parameter logLevel: output detail level.
     */
    public init(
        logLevel: LogLevel = LogLevel.url
    ) {
        self.logLevel = logLevel
    }

    open override func intercept(request: URLRequest) -> URLRequest {
        guard
            self.logLevel.rawValue > LogLevel.nothing.rawValue,
            let httpMethod: String = request.httpMethod,
            let url: String = request.url?.absoluteString,
            let headers: [String: String] = request.allHTTPHeaderFields
        else {
            return request
        }

        var message: String = "--> HTTP REQUEST\n"
        message += "\(httpMethod.uppercased()) \(url)\n"

        guard self.logLevel.rawValue > LogLevel.url.rawValue
        else {
            print(message)
            return request
        }

        headers.forEach { (key: String, value: String) in
            message += "\(key): \(value)\n"
        }

        guard
            self.logLevel.rawValue > LogLevel.headers.rawValue,
            let bodyData: Data = request.httpBody,
            let bodyString: String = String(data: bodyData, encoding: String.Encoding.utf8)
        else {
            print(message)
            return request
        }

        message += bodyString + "\n"
        print(message)
        return request
    }

    /**
     `LogRequestInterceptor` log level.
     */
    public enum LogLevel: Int {
        case nothing    = 0
        case url        = 1
        case headers    = 2
        case everything = 3
    }

}
