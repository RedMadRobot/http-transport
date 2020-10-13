//
//  NSError.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//


import Foundation


/**
 HTTP transport-related errors.
 */
public extension NSError {

    /**
     Error domain.
     */
    static let transportDomain: String = "Transport.error.domain"

    /**
     Get request URL from `userInfo`, if any.
     */
    var url: String? {
        return self.userInfo[UserInfoKey.url] as? String
    }

    /**
     Get response HTTP status code from `userInfo`, if any.
     */
    var httpStatusCode: HTTPStatusCode? {
        return self.userInfo[UserInfoKey.httpStatus] as? HTTPStatusCode
    }

    /**
     Get response body as Data from `userInfo`, if any.
     */
    var responseBodyData: Data? {
        return self.userInfo[UserInfoKey.responseBodyData] as? Data
    }

    /**
     Get response body as String from `userInfo`, if any.
     */
    var responseBodyString: String? {
        return self.userInfo[UserInfoKey.responseBodyString] as? String
    }

    /**
     Get response body as JSON object from `userInfo`, if any.
     */
    var responseBodyJSON: Any? {
        return self.userInfo[UserInfoKey.responseBodyJSON]
    }

    /**
     Get error.code from body JSON, if any.
     */
    var responseBodyErrorCode: String? {
        return self.userInfo[UserInfoKey.responseBodyErrorCode] as? String
    }

    /**
     Get error.message from body JSON, if any.
     */
    var responseBodyErrorMessage: String? {
        return self.userInfo[UserInfoKey.responseBodyErrorMessage] as? String
    }

    /**
     Get response body as dictionary from `userInfo`, if any.
     */
    var responseBodyJSONDictionary: [String: Any]? {
        guard let json: Any = self.responseBodyJSON
        else { return nil }

        if let dictionary: [String: Any] = json as? [String: Any] {
            return dictionary
        } else {
            return ["data": json]
        }
    }

    /**
     Request was interrupted because of the semaphore timeout.
     */
    static var timeout: NSError {
        return NSError(
            domain: transportDomain,
            code: NSURLErrorTimedOut,
            userInfo: [
                NSLocalizedDescriptionKey: "Request timed out on semaphore"
            ]
        )
    }

    /**
     Alamofire returned no HTTP response and no error.
     */
    static var noHTTPResponse: NSError {
        return NSError(
            domain: transportDomain,
            code: TransportErrorCode.noHTTPResponse.rawValue,
            userInfo: [
                NSLocalizedDescriptionKey: "Alamofire didn't return HTTPURLResponse nor Error"
            ]
        )
    }

    /**
     Wrong URL format.
     */
    static func cannotInitURL(urlString: String) -> NSError {
        return NSError(
            domain: transportDomain,
            code: TransportErrorCode.cannotInitURLWithString.rawValue,
            userInfo: [
                UserInfoKey.url: urlString,
                NSLocalizedDescriptionKey: "Cannot convert String to URL"
            ]
        )
    }

    /**
     Transport-related error codes.
     */
    enum TransportErrorCode: Int {
        case cannotInitURLWithString = 9000
        case noHTTPResponse          = 9001
    }

    /**
     Transport-related `userInfo` keys.
     */
    struct UserInfoKey {
        public static let url:                      String = "NSError.userInfo.key.url"
        public static let httpStatus:               String = "NSError.userInfo.key.httpStatus"
        public static let responseBodyData:         String = "NSError.userInfo.key.responseBodyData"
        public static let responseBodyString:       String = "NSError.userInfo.key.responseBodyString"
        public static let responseBodyJSON:         String = "NSError.userInfo.key.responseBodyJSON"
        public static let responseBodyErrorCode:    String = "NSError.userInfo.key.responseBodyErrorCode"
        public static let responseBodyErrorMessage: String = "NSError.userInfo.key.responseBodyErrorMessage"
    }

}
