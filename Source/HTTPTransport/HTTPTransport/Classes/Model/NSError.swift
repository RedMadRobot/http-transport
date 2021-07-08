//
//  NSError.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - NSError

/// HTTP transport-related errors
public extension NSError {

    // MARK: - Properties

    /// Error domain
    static let transportDomain: String = "Transport.error.domain"

    /// Get request URL from `userInfo`, if any
    var url: String? {
        userInfo[UserInfoKey.url] as? String
    }

    /// Get response HTTP status code from `userInfo`, if any
    var httpStatusCode: HTTPStatusCode? {
        userInfo[UserInfoKey.httpStatus] as? HTTPStatusCode
    }

    /// Get response body as Data from `userInfo`, if any
    var responseBodyData: Data? {
        userInfo[UserInfoKey.responseBodyData] as? Data
    }

    /// Get response body as String from `userInfo`, if any
    var responseBodyString: String? {
        userInfo[UserInfoKey.responseBodyString] as? String
    }

    /// Get response body as JSON object from `userInfo`, if any
    var responseBodyJSON: Any? {
        userInfo[UserInfoKey.responseBodyJSON]
    }

    /// Get error.code from body JSON, if any
    var responseBodyErrorCode: String? {
        userInfo[UserInfoKey.responseBodyErrorCode] as? String
    }

    /// Get error.message from body JSON, if any
    var responseBodyErrorMessage: String? {
        userInfo[UserInfoKey.responseBodyErrorMessage] as? String
    }

    /// Get response body as dictionary from `userInfo`, if any
    var responseBodyJSONDictionary: [String: Any]? {
        guard let json: Any = self.responseBodyJSON else { return nil }
        if let dictionary = json as? [String: Any] {
            return dictionary
        } else {
            return ["data": json]
        }
    }

    /// Request was interrupted because of the semaphore timeout
    static var timeout: NSError {
        NSError(
            domain: transportDomain,
            code: NSURLErrorTimedOut,
            userInfo: [
                NSLocalizedDescriptionKey: "Request timed out on semaphore"
            ]
        )
    }

    /// Alamofire returned no HTTP response and no error
    static var noHTTPResponse: NSError {
        NSError(
            domain: transportDomain,
            code: TransportErrorCode.noHTTPResponse.rawValue,
            userInfo: [
                NSLocalizedDescriptionKey: "Alamofire didn't return HTTPURLResponse nor Error"
            ]
        )
    }

    /// Wrong URL format
    static func cannotInitURL(urlString: String) -> NSError {
        NSError(
            domain: transportDomain,
            code: TransportErrorCode.cannotInitURLWithString.rawValue,
            userInfo: [
                UserInfoKey.url: urlString,
                NSLocalizedDescriptionKey: "Cannot convert String to URL"
            ]
        )
    }

    // MARK: - TransportErrorCode

    /// Transport-related error codes
    enum TransportErrorCode: Int {

        case cannotInitURLWithString = 9000
        case noHTTPResponse          = 9001
    }

    // MARK: - UserInfoKey

    /// Transport-related `userInfo` keys
    struct UserInfoKey {
        public static let url                      = "NSError.userInfo.key.url"
        public static let httpStatus               = "NSError.userInfo.key.httpStatus"
        public static let responseBodyData         = "NSError.userInfo.key.responseBodyData"
        public static let responseBodyString       = "NSError.userInfo.key.responseBodyString"
        public static let responseBodyJSON         = "NSError.userInfo.key.responseBodyJSON"
        public static let responseBodyErrorCode    = "NSError.userInfo.key.responseBodyErrorCode"
        public static let responseBodyErrorMessage = "NSError.userInfo.key.responseBodyErrorMessage"
    }
}
