//
//  HTTPRequestInterceptor.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//


import Foundation

// MARK: - HTTPRequestInterceptor

/// Abstract class for HTTP request interceptors.
/// Allows transforming original `URLRequest` before it is sent.
public protocol HTTPRequestInterceptor {

    /// Intercept outgoing HTTP request
    /// - Parameter request: original request
    /// - Returns: may return original or modified `URLRequest`
    func intercept(request: URLRequest) -> URLRequest
}
