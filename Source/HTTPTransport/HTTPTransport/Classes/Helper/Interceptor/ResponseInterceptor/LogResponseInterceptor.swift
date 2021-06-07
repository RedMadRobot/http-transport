//
//  LogResponseInterceptor
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2017 RedMadRobot LLC. All rights reserved.
//


import Foundation

// MARK: - LogResponseInterceptor

/// Logs every transport response with selected level of details
open class LogResponseInterceptor: HTTPResponseInterceptor {

    /// Output detail level
    public let logLevel: LogLevel

    /// Will print only headers in this list if `LogResponseInterceptor.isFilteringHeaders`
    public let headerFilter: [Header]

    /// Will print only selected list of headers, see `LogResponseInterceptor.headerFilter`
    public let isFilteringHeaders: Bool

    /// Logger closure
    private let printer: (String) -> Void

    /// Default initializer
    /// - Parameters:
    ///   - logLevel: output detail level
    ///   - isFilteringHeaders: will print only selected list of headers, see `LogResponseInterceptor.headerFilter`
    ///   - headerFilter: will print only headers in this list if `LogResponseInterceptor.isFilteringHeaders`
    public init(
        logLevel: LogLevel = .status,
        isFilteringHeaders: Bool = true,
        headerFilter: [Header] = [
            .contentType,
            .lastModified,
            .setCookie
        ],
        printer: @escaping (String) -> Void = {
            print($0)
        }
    ) {
        self.logLevel = logLevel
        self.isFilteringHeaders = isFilteringHeaders
        self.headerFilter = headerFilter
        self.printer = printer
    }

    // MARK: - HTTPResponseInterceptor

    override open func intercept(
        response: HTTPResponseInterceptor.RawResponse
    ) -> HTTPResponseInterceptor.RawResponse {
        guard
            self.logLevel.rawValue > LogLevel.nothing.rawValue,
            let statusCode = HTTPStatusCode(httpURLResponse: response.response)
        else { return response }

        var message: String = "\n[RESPONSE] "
        message += "\(statusCode)\n"

        if let urlString: String = response.response?.url?.absoluteString {
            message += "From: \(urlString)\n"
        }

        let isError = (response.response?.statusCode ?? 0) >= 400

        guard
            self.logLevel.rawValue > LogLevel.status.rawValue,
            let headers: [AnyHashable: Any] = response.response?.allHeaderFields
        else {
            if isError {
                printer(message)
            } else {
                printer(message)
            }
            return response
        }

        message += "Headers:\n"
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
            let bodyString = bodyData.prettyPrintedJSONString
        else {
            if isError {
                printer(message)
            } else {
                printer(message)
            }
            return response
        }

        message += "Body:\n"
        message += bodyString + "\n\n"
        if isError {
            printer(message)
        } else {
            printer(message)
        }
        return response
    }

    /// `LogResponseInterceptor` log level
    public enum LogLevel: Int {
        case nothing = 0
        case status = 1
        case headers = 2
        case everything = 3
    }

    /// Known response headers.
    /// RFC 7231: https://tools.ietf.org/html/rfc7231
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

// MARK: - Data

extension Data {
    var prettyPrintedJSONString: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
        return prettyPrintedString as String
    }
}
