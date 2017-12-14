//
//  HTTPResponseInterceptor.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//


import Foundation


/**
 Abstract class for HTTP response interceptors.
 
 Allows transforming original HTTP response before it is returned from `HTTPTransport`.
 */
open class HTTPResponseInterceptor {

    /**
     If subclass, we need to call super.init()
     See more: https://bugs.swift.org/browse/SR-2295
     */
    public init() { }
    
    /**
     Intercept incoming HTTP response.
     
     - parameter response: original response.
     
     - returns: May return original or modified response.
     */
    /* abstract */ open func intercept(response: RawResponse) -> RawResponse {
        preconditionFailure()
    }

    /**
     Model for raw HTTP response with or without incoming error and data.
     */
    public struct RawResponse {
        public let request:  URLRequest?
        public let response: HTTPURLResponse?
        public let data:     Data?
        public let error:    Error?

        public init(
            request: URLRequest?,
            response: HTTPURLResponse?,
            data: Data?,
            error: Error?
        ) {
            self.request = request
            self.response = response
            self.data = data
            self.error = error
        }
    }

}
