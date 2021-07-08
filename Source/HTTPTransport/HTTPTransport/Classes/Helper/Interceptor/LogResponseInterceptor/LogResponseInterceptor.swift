//
//  LogResponseInterceptor
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - LogResponseInterceptor

/// Logs every transport response with selected level of details
open class LogResponseInterceptor {

    // MARK: - Properties

    /// Output detail level
    public let logLevel: LogLevel

    /// Will print only headers in this list if `LogResponseInterceptor.isFilteringHeaders`
    public let headerFilter: [ResponseHeader]

    /// Will print only selected list of headers, see `LogResponseInterceptor.headerFilter`
    public let isFilteringHeaders: Bool

    /// Logger closure
    private let printer: (String) -> Void

    /// Default initializer
    /// - Parameters:
    ///   - logLevel: output detail level
    ///   - isFilteringHeaders: will print only selected list of headers, see `LogResponseInterceptor.headerFilter`
    ///   - headerFilter: will print only headers in this list if `LogResponseInterceptor.isFilteringHeaders`
    ///   - printer: logger closure
    public init(
        logLevel: LogLevel = .status,
        isFilteringHeaders: Bool = true,
        headerFilter: [ResponseHeader] = [
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

    // MARK: - LogLevel

    public enum LogLevel: Int {

        // MARK: - Cases

        case nothing = 0
        case status = 1
        case headers = 2
        case everything = 3
    }

    // MARK: - Header

    /// Known response headers.
    /// RFC 7231: https://tools.ietf.org/html/rfc7231
    public enum ResponseHeader: String {

        // MARK: - Cases

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

// MARK: - HTTPResponseInterceptor

extension LogResponseInterceptor: HTTPResponseInterceptor {

    open func intercept(response: RawResponse) -> RawResponse {
        guard
            logLevel.rawValue > LogLevel.nothing.rawValue,
            let statusCode = HTTPStatusCode(httpURLResponse: response.response)
        else { return response }
        var message = "\n[RESPONSE] "
        message += "\(statusCode)\n"
        if let urlString = response.response?.url?.absoluteString {
            message += "From: \(urlString)\n"
        }
        let isError = (response.response?.statusCode ?? 0) >= 400
        guard
            logLevel.rawValue > LogLevel.status.rawValue,
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
            if !isFilteringHeaders {
                message += "\(headerName): \(headerValue)\n"
            } else if let headerName = headerName as? String,
                      let header = ResponseHeader(rawValue: headerName),
                      headerFilter.contains(header) {
                message += "\(headerName): \(headerValue)\n"
            }
        }
        guard
            logLevel.rawValue > LogLevel.headers.rawValue,
            let bodyData = response.data,
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
