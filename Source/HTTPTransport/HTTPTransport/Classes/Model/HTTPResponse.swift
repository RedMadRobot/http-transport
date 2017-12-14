//
//  HTTPResponse.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//


import Foundation


/**
 HTTP response with status code, response headers and body, if any.
 */
open class HTTPResponse {

    /**
     Request status.
     */
    open let httpStatus: HTTPStatusCode

    /**
     Collection of received headers.
     */
    open let headers:    [String: String]

    /**
     Received body data, if any.
     */
    open let body:       Data?

    /**
     Corresponding HTTP request, which produced this response.
     */
    open let request:    URLRequest?

    /**
     Initializer.
     
     - parameter httpStatus: request status;
     - parameter headers: collection of received headers;
     - parameter body: received body data, if any;
     - parameter request: original URLRequest, which produced this response, if any.
     */
    public init(
        httpStatus: HTTPStatusCode,
        headers: [String: String],
        body: Data?,
        request: URLRequest?
    ) {
        self.httpStatus = httpStatus
        self.headers = headers
        self.body = body
        self.request = request
    }

    /**
     Transform body data to JSON object, if any.
     
     - returns: `None`, if no body data is received.
     - throws: Serialization error, if present body data cannot be deserialized.
     */
    open func getJSON() throws -> Any? {
        if let bodyData: Data = self.body {
            return try JSONSerialization.jsonObject(with: bodyData, options: JSONSerialization.ReadingOptions.allowFragments)
        } else {
            return nil
        }
    }

    /**
     Transform body data to JSON dictionary, if any.
     
     - returns: `None`, if no body data is received; if received JSON is not a dictionary, it gets wrapped into ["data": JSON];
     - throws: Serialization error, if present body data cannot be deserialized.
     */
    open func getJSONDictionary() throws -> [String: Any]? {
        guard let json: Any = try self.getJSON()
        else { return nil }

        if let dictionary: [String: Any] = json as? [String: Any] {
            return dictionary
        } else {
            return ["data": json]
        }
    }

}
