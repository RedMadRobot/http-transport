//
//  HTTPRequest.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//


import Alamofire
import Foundation


/**
 HTTP request with HTTP verb, URL, headers, body and non-functional parameters, like `Session`, `ParameterEncoding`, timeout and
 request interceptors.
 */
open class HTTPRequest: URLRequestConvertible {

    /**
     Default HTTP `URLRequest` timeout.
     */
    public static let defaultTimeout: TimeInterval = 30

    /**
     GET, POST, PUT, PATCH etc.
     */
    public let httpMethod:           HTTPMethod

    /**
     URL endpoint.
     */
    public let endpoint:             String

    /**
     HTTP request headers map.
     */
    open var headers:              [String: String]

    /**
     Request parameters.
     */
    open var parameters:           [HTTPRequestParameters]

    /**
     Collection of request interceptors, see `HTTPRequestInterceptor`.
     */
    open var requestInterceptors:  [HTTPRequestInterceptor]

    /**
     Collection of response interceptors, see `HTTPResponseInterceptor`.
     */
    open var responseInterceptors: [HTTPResponseInterceptor]

    /**
     Custom session for this particular HTTP request.
     */
    public let session:              Session?

    /**
     Timeout for this particular HTTP request. Default is 30 seconds.
     */
    public let timeout:              TimeInterval

    /**
     Initializer.
     
     - parameter httpMethod: HTTP verb; default is GET;
     - parameter endpoint: URL endpoint; default is "";
     - parameter headers: map of HTTP headers; default is empty map;
     - parameter parameters: request parameters; default is empty list;
     - parameter interceptors: request interceptors; default is empty array;
     - parameter session: `Session` for this particular URLRequest; default is `None`, transport-defined;
     - parameter timeout: `URLRequest` timeout;
     - parameter base: base `HTTPRequest` to inherit parameters from; default is `None`.
     */
    public init(
        httpMethod: HTTPMethod = HTTPMethod.get,
        endpoint: String = "",
        headers: [String: String] = [:],
        parameters: [HTTPRequestParameters] = [],
        requestInterceptors: [HTTPRequestInterceptor] = [],
        responseInterceptors: [HTTPResponseInterceptor] = [],
        session: Session? = nil,
        timeout: TimeInterval? = nil,
        base: HTTPRequest? = nil
    ) {
        var mergedEndpoint:             String                    = endpoint
        var mergedHeaders:              [String: String]          = headers
        var mergedParameters:           [HTTPRequestParameters]   = parameters
        var mergedRequestInterceptors:  [HTTPRequestInterceptor]  = requestInterceptors
        var mergedResponseInterceptors: [HTTPResponseInterceptor] = responseInterceptors

        if let base = base {
            if endpoint.hasPrefix("?") || endpoint.hasPrefix("/") || endpoint.isEmpty {
                mergedEndpoint = base.endpoint + endpoint
            } else {
                mergedEndpoint = base.endpoint + "/" + endpoint
            }

            mergedHeaders = base.headers

            headers.forEach { (header: String, value: String) in
                mergedHeaders[header] = value
            }

            mergedParameters = type(of: self).merge(baseParameters: base.parameters, withParameters: parameters)
            mergedRequestInterceptors.append(contentsOf: base.requestInterceptors)
            mergedResponseInterceptors.append(contentsOf: base.responseInterceptors)
        }

        self.httpMethod = httpMethod

        self.endpoint = mergedEndpoint
        self.headers = mergedHeaders
        self.parameters = mergedParameters
        self.requestInterceptors = mergedRequestInterceptors
        self.responseInterceptors = mergedResponseInterceptors

        self.session = session ?? base?.session
        self.timeout = timeout ?? base?.timeout ?? HTTPRequest.defaultTimeout
    }

    /**
     Add HTTP request header.
     */
    @discardableResult
    open func with(header: String, value: String) -> Self {
        self.headers[header] = value
        return self
    }

    /**
     Add Cookie to HTTP request with Cookie name and value.
     */
    @discardableResult
    open func with(cookieName name: String, value: String) -> Self {
        return self.with(cookie: HTTPCookie(name: name, value: value))
    }

    /**
     Add Cookie to HTTP request.
     */
    @discardableResult
    open func with(cookie: HTTPCookie) -> Self {
        let headers: [String: String] = HTTPCookie.requestHeaderFields(with: [cookie])
        for (header, value) in headers {
            self.headers[header] = value
        }
        return self
    }

    /**
     Add request parameter.
     */
    @discardableResult
    open func with(
        parameter: String,
        value: Any,
        encoding: HTTPRequestParameters.Encoding = .json
    ) -> Self {
        return self.with(parameters: [parameter: value], encoding: encoding)
    }

    /**
     Add request parameters.
     */
    @discardableResult
    open func with(
        parameters: [String: Any],
        encoding: HTTPRequestParameters.Encoding = .json
    ) -> Self {
        let newParameters: HTTPRequestParameters = HTTPRequestParameters(parameters: parameters, encoding: encoding)
        return self.with(parameters: newParameters)
    }

    /**
     Add request parameters.
     */
    @discardableResult
    open func with(
        parameters: HTTPRequestParameters
    ) -> Self {
        return self.with(parameters: [parameters])
    }

    /**
     Add request parameters.
     */
    @discardableResult
    open func with(
        parameters: [HTTPRequestParameters]
    ) -> Self {
        self.parameters = type(of: self).merge(baseParameters: self.parameters, withParameters: parameters)
        return self
    }

    /**
     Add request interceptors.
     */
    @discardableResult
    public func with(interceptors: [HTTPRequestInterceptor]) -> Self {
        self.requestInterceptors += interceptors
        return self
    }

    /**
     Add response interceptors.
     */
    @discardableResult
    public func with(interceptors: [HTTPResponseInterceptor]) -> Self {
        self.responseInterceptors += interceptors
        return self
    }

    public func asURLRequest() throws -> URLRequest {
        guard let url: URL = URL(string: self.endpoint)
        else {
            throw NSError.cannotInitURL(urlString: self.endpoint)
        }

        let initialRequest: URLRequest =
            try self.createURLRequest(
                method: self.httpMethod,
                url: url,
                headers: self.headers,
                timeout: self.timeout,
                parameters: self.parameters
            )

        return self.requestInterceptors.reduce(initialRequest) { (
            currentRequest: URLRequest,
            interceptor: HTTPRequestInterceptor
        ) -> URLRequest in
            return interceptor.intercept(request: currentRequest)
        }
    }

    public enum HTTPMethod: String {
        case options = "OPTIONS"
        case get     = "GET"
        case head    = "HEAD"
        case post    = "POST"
        case put     = "PUT"
        case patch   = "PATCH"
        case delete  = "DELETE"
        case trace   = "TRACE"
        case connect = "CONNECT"
    }

}


private extension HTTPRequest {

    func createURLRequest(
        method: HTTPMethod,
        url: URL,
        headers: [String: String],
        timeout: TimeInterval,
        parameters: [HTTPRequestParameters]?
    ) throws -> URLRequest {
        var request: URLRequest = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue

        for (headerField, headerValue) in headers {
            request.setValue(headerValue, forHTTPHeaderField: headerField)
        }

        return try self.parameters.reduce(request) { (result: URLRequest, parameters: HTTPRequestParameters) -> URLRequest in
            return try parameters.encoding.toAlamofire().encode(request, with: parameters.parameters)
        }
    }

    class func merge(
        baseParameters: [HTTPRequestParameters],
        withParameters parameters: [HTTPRequestParameters]
    ) -> [HTTPRequestParameters] {
        var jsonParameters:   [String: Any]           = [:]
        var urlParameters:    [String: Any]           = [:]
        var plistParameters:  [String: Any]           = [:]
        var customParameters: [HTTPRequestParameters] = []

        // PUT BASE PARAMETERS INTO CORRESPONDING BASKETS
        for baseParameters in baseParameters {
            switch baseParameters.encoding {
                case HTTPRequestParameters.Encoding.json:
                    for baseKey in baseParameters.parameters.keys {
                        jsonParameters[baseKey] = baseParameters.parameters[baseKey]
                    }

                case HTTPRequestParameters.Encoding.url:
                    for baseKey in baseParameters.parameters.keys {
                        urlParameters[baseKey] = baseParameters.parameters[baseKey]
                    }

                case HTTPRequestParameters.Encoding.propertyList:
                    for baseKey in baseParameters.parameters.keys {
                        plistParameters[baseKey] = baseParameters.parameters[baseKey]
                    }

                case HTTPRequestParameters.Encoding.custom:
                    customParameters.append(baseParameters)
            }
        }

        // OVERRIDE/APPEND BASE PARAMETERS IN BASKETS
        for parameters in parameters {
            switch parameters.encoding {
                case HTTPRequestParameters.Encoding.json:
                    for baseKey in parameters.parameters.keys {
                        jsonParameters[baseKey] = parameters.parameters[baseKey]
                    }

                case HTTPRequestParameters.Encoding.url:
                    for baseKey in parameters.parameters.keys {
                        urlParameters[baseKey] = parameters.parameters[baseKey]
                    }

                case HTTPRequestParameters.Encoding.propertyList:
                    for baseKey in parameters.parameters.keys {
                        plistParameters[baseKey] = parameters.parameters[baseKey]
                    }

                case HTTPRequestParameters.Encoding.custom:
                    customParameters.append(parameters)
            }
        }

        var result: [HTTPRequestParameters] = []

        if !jsonParameters.isEmpty {
            result.append(HTTPRequestParameters(parameters: jsonParameters, encoding: HTTPRequestParameters.Encoding.json))
        }

        if !urlParameters.isEmpty {
            result.append(HTTPRequestParameters(parameters: urlParameters, encoding: HTTPRequestParameters.Encoding.url))
        }

        if !plistParameters.isEmpty {
            result.append(
                HTTPRequestParameters(parameters: plistParameters, encoding: HTTPRequestParameters.Encoding.propertyList)
            )
        }

        result += customParameters

        return result
    }

}
