//
//  HTTPResponseInterceptor.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - HTTPResponseInterceptor

/// Protocol for HTTP response interceptors
/// Allows transforming original HTTP response before it is returned from `HTTPTransport`
public protocol HTTPResponseInterceptor {

    /// Intercept incoming HTTP response
    /// - Parameter response: original response
    /// - Returns: may return original or modified response
    func intercept(response: RawResponse) -> RawResponse
}
