//
//  DataUploadHTTPRequest.swift
//  soglasie
//
//  Created by Ivan Vavilov on 9/12/17.
//  Copyright © 2017 RedMadRobot. All rights reserved.
//

import Alamofire


/**
 Data upload HTTP request.
 */
open class DataUploadHTTPRequest: HTTPRequest {

    /**
     File data.
     */
    public let data: Data

    /**
     Initializer.
     
     - parameter httpMethod: HTTP verb; default is GET;
     - parameter endpoint: URL endpoint; default is "";
     - parameter headers: map of HTTP headers; default is empty map;
     - parameter parameters: request parameters; default is empty list;
     - parameter interceptors: request interceptors; default is empty array;
     - parameter sessionManager: `SessionManager` for this particular URLRequest; default is `None`, transport-defined;
     - parameter timeout: `URLRequest` timeout;
     - parameter base: base `HTTPRequest` to inherit parameters from; default is `None`.
     - parameter data: file data;
     */
    public init(
        httpMethod: HTTPRequest.HTTPMethod = HTTPMethod.post,
        endpoint: String = "",
        headers: [String : String] = [:],
        parameters: [HTTPRequestParameters] = [],
        requestInterceptors: [HTTPRequestInterceptor] = [],
        responseInterceptors: [HTTPResponseInterceptor] = [],
        sessionManager: SessionManager? = nil,
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
            sessionManager: sessionManager,
            timeout: timeout,
            base: base
        )
    }

}
