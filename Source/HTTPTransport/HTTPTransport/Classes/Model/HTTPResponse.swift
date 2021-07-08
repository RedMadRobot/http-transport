//
//  HTTPResponse.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - HTTPResponse

/// HTTP response with status code, response headers and body, if any
open class HTTPResponse {

    // MARK: - Properties

    /// Request status
    public let httpStatus: HTTPStatusCode

    /// Collection of received headers
    public let headers: [String: String]

    /// Received body data, if any
    public let body: Data?

    /// Corresponding HTTP request, which produced this response
    public let request: URLRequest?

    // MARK: - Initializers

    /// Default initializer
    /// - Parameters:
    ///   - httpStatus: request status
    ///   - headers: collection of received headers
    ///   - body: received body data, if any
    ///   - request: original URLRequest, which produced this response, if any
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

    /// Transform body data to JSON object, if any
    /// - Throws: Serialization error, if present body data cannot be deserialized
    /// - Returns: `None`, if no body data is received
    open func getJSON() throws -> Any? {
        if let bodyData = body {
            return try JSONSerialization.jsonObject(
                with: bodyData, options: JSONSerialization.ReadingOptions.allowFragments
            )
        } else {
            return nil
        }
    }

    /// Transform body data to JSON dictionary, if any
    /// - Throws: Serialization error, if present body data cannot be deserialized
    /// - Returns: `None`, if no body data is received;
    ///   - if received JSON is not a dictionary, it gets wrapped into ["data": JSON]
    open func getJSONDictionary() throws -> [String: Any]? {
        guard let json: Any = try self.getJSON() else { return nil }
        if let dictionary = json as? [String: Any] {
            return dictionary
        } else {
            return ["data": json]
        }
    }
}
