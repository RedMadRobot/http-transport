//
//  DataUploadHTTPRequest.swift
//  soglasie
//
//  Created by Ivan Vavilov on 9/12/17.
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - DataUploadHTTPRequest

/// Data upload HTTP request
open class DataUploadHTTPRequest: HTTPRequest {

    // MARK: - Properties

    /// File data
    public let data: Data

    // MARK: - Initializers

    /// Default initializer
    /// - Parameters:
    ///   - httpMethod: HTTP verb; default is GET
    ///   - endpoint: URL endpoint; default is ""
    ///   - headers: map of HTTP headers; default is empty map
    ///   - parameters: request parameters; default is empty list
    ///   - requestInterceptors: request interceptors; default is empty array
    ///   - responseInterceptors: response interceptors; default is empty array
    ///   - session: `Session` for this particular URLRequest; default is `None`, transport-defined
    ///   - timeout: `URLRequest` timeout
    ///   - base: base `HTTPRequest` to inherit parameters from; default is `None`
    ///   - data: file data
    public init(
        httpMethod: HTTPRequest.HTTPMethod = HTTPMethod.post,
        endpoint: String = "",
        headers: [String : String] = [:],
        parameters: [HTTPRequestParameters] = [],
        requestInterceptors: [HTTPRequestInterceptor] = [],
        responseInterceptors: [HTTPResponseInterceptor] = [],
        session: Session? = nil,
        timeout: TimeInterval? = nil,
        base: HTTPRequest? = nil,
        data: Data
    ) {
        self.data = data
        super.init(
            httpMethod: httpMethod,
            endpoint: endpoint,
            headers: headers,
            parameters: parameters,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors,
            session: session,
            timeout: timeout,
            base: base
        )
    }
}
