//
//  HTTPRequestInterceptor.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//


import Foundation


/**
 Abstract class for HTTP request interceptors.
 
 Allows transforming original `URLRequest` before it is sent.
 */
open class HTTPRequestInterceptor {

    /**
     If subclass, we need to call super.init()
     See more: https://bugs.swift.org/browse/SR-2295
     */
    public init() { }
    
    /**
     Intercept outgoing HTTP request.
     
     - parameter request: original request.
     
     - returns: May return original or modified `URLRequest`.
     */
    /* abstract */ open func intercept(request: URLRequest) -> URLRequest {
        preconditionFailure()
    }

}
