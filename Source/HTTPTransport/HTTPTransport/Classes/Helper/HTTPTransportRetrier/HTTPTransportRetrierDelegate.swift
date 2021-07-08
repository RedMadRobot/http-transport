//
//  HTTPTransportRetrierDelegate.swift
//  HTTPTransport
//
//  Created by Alexander Lezya on 07.07.2021.
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - HTTPTransportRetrierDelegate

/// Responsibility to decide, whether the request should be retried or not, and when
public protocol HTTPTransportRetrierDelegate {

    /// How many times request should be retried?
    var maxAttemptsCount: Int { get }

    /// Failed request should be retried - yes or no?
    /// - Parameters:
    ///   - response: former request answer
    ///   - responseJSON: serialized server response payload
    ///   - error: former request error
    func shouldRetry(_ response: URLResponse, responseJSON: Any?, error: Error) -> Bool

    /// Here, perform all necessary work before failed request retrial will happen
    /// - Parameter completion: call when finished
    func refreshForRetrieve(completion: @escaping (Bool) -> ())

    /// Adapt the original failed request before retrying
    /// - Parameter urlRequest: original request
    func adapted(_ urlRequest: URLRequest) -> URLRequest
}
