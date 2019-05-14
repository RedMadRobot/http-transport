//
//  LogResponseInterceptor
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2017 RedMadRobot LLC. All rights reserved.
//


import Foundation


/**
 Logs every transport response with selected level of details.
 */
open class LogResponseInterceptor: HTTPResponseInterceptor {

    /**
     Output detail level.
     */
    public let logLevel:           LogLevel

    /**
     Will print only headers in this list if `LogResponseInterceptor.isFilteringHeaders`
     */
    public let headerFilter:       [Header]

    /**
     Will print only selected list of headers, see `LogResponseInterceptor.headerFilter`
     */
    public let isFilteringHeaders: Bool

    /**
     Initializer.
     
     - parameter logLevel: output detail level.
     */
    public init(
        logLevel: LogLevel = LogLevel.status,
        isFilteringHeaders: Bool = true,
        headerFilter: [Header] = [Header.contentType, Header.lastModified, Header.setCookie]
    ) {
        self.logLevel = logLevel
        self.isFilteringHeaders = isFilteringHeaders
        self.headerFilter = headerFilter
    }

    open override func intercept(
        response: HTTPResponseInterceptor.RawResponse
    ) -> HTTPResponseInterceptor.RawResponse {
        guard
            self.logLevel.rawValue > LogLevel.nothing.rawValue,
            let statusCode: HTTPStatusCode = HTTPStatusCode(httpURLResponse: response.response)
        else { return response }

        var message: String = "<-- HTTP RESPONSE\n"
        message += "\(statusCode)\n"

        if let urlString: String = response.response?.url?.absoluteString {
            message += "From: \(urlString)\n"
        }

        guard
            self.logLevel.rawValue > LogLevel.status.rawValue,
            let headers: [AnyHashable: Any] = response.response?.allHeaderFields
        else {
            print(message)
            return response
        }

        headers.forEach { (headerName: AnyHashable, headerValue: Any) in
            if !self.isFilteringHeaders {
                message += "\(headerName): \(headerValue)\n"
            } else if let headerName: String = headerName as? String,
                      let header: Header = Header(rawValue: headerName),
                      self.headerFilter.contains(header) {
                message += "\(headerName): \(headerValue)\n"
            }
        }

        guard
            self.logLevel.rawValue > LogLevel.headers.rawValue,
            let bodyData: Data = response.data,
            let bodyString: String = String(data: bodyData, encoding: String.Encoding.utf8)
        else {
            print(message)
            return response
        }

        message += bodyString + "\n"
        print(message)
        return response
    }

    /**
     `LogResponseInterceptor` log level.
     */
    public enum LogLevel: Int {
        case nothing    = 0
        case status     = 1
        case headers    = 2
        case everything = 3
    }

    /**
     Known response headers.
     RFC 7231: https://tools.ietf.org/html/rfc7231
     */
    public enum Header: String {
        case cacheControl    = "Cache-Control"
        case contentEncoding = "Content-Encoding"
        case contentLanguage = "Content-Language"
        case contentLength   = "Content-Length"
        case contentMD5      = "Content-MD5"
        case contentType     = "Content-Type"
        case lastModified    = "Last-Modified"
        case server          = "Server"
        case setCookie       = "Set-Cookie"
        case upgrade         = "Upgrade"
    }

}
