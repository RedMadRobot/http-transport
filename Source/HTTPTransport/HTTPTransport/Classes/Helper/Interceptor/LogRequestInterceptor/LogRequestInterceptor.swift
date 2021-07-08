//
//  LogRequestInterceptor
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - LogRequestInterceptor

/// Logs every HTTP request with selected level of details.
open class LogRequestInterceptor {

    // MARK: - Properties

    /// Output detail level
    public let logLevel: LogLevel

    /// Logger closure
    private let printer: (String) -> Void

    // MARK: - Initializers

    /// Default initializer
    /// - Parameters:
    ///   - logLevel: output detail level
    ///   - printer: logger closure
    public init(
        logLevel: LogLevel = LogLevel.url,
        printer: @escaping (String) -> Void = {
            print($0)
        }
    ) {
        self.logLevel = logLevel
        self.printer = printer
    }

    // MARK: - LogLevel

    public enum LogLevel: Int {

        // MARK: - Cases

        case nothing = 0
        case url = 1
        case curl = 2
        case headers = 3
        case everything = 4
    }
}

// MARK: - HTTPRequestInterceptor

extension LogRequestInterceptor: HTTPRequestInterceptor {

    open func intercept(request: URLRequest) -> URLRequest {
        guard
            logLevel.rawValue > LogLevel.nothing.rawValue,
            let httpMethod = request.httpMethod,
            let url = request.url?.absoluteString,
            let headers: [String: String] = request.allHTTPHeaderFields
        else {
            return request
        }
        var message = "\n[REQUEST] "
        message += "\(httpMethod.uppercased()) \(url)\n"
        guard logLevel.rawValue > LogLevel.url.rawValue else {
            printer(message)
            return request
        }
        message += "\(request.curlString)\n\n"
        guard logLevel.rawValue > LogLevel.curl.rawValue else {
            printer(message)
            return request
        }
        message += "Headers:\n"
        headers.forEach { (key: String, value: String) in
            message += "\(key): \(value)\n\n"
        }
        guard
            logLevel.rawValue > LogLevel.headers.rawValue,
            let bodyData = request.httpBody,
            let bodyString = bodyData.prettyPrintedJSONString?.truncated()
        else {
            printer(message)
            return request
        }
        message += "Body:\n"
        message += bodyString + "\n\n"
        printer(message)
        return request
    }
}

// MARK: - CURL

extension URLRequest {

    /// Returns a cURL command representation of this URL request.
    var curlString: String {
        guard let url = url else { return "" }
        var baseCommand = "curl \(url.absoluteString)"
        if httpMethod == "HEAD" {
            baseCommand += " --head"
        }
        var command = [baseCommand]
        if let method = httpMethod, method != "GET" && method != "HEAD" {
            command.append("-X \(method)")
        }
        if let headers = allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H '\(key): \(value)'")
            }
        }
        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            command.append("-d '\(body)'")
        }
        return command.joined(separator: " \\\n\t")
    }
}
