//
//  HTTPTransportRetrier.swift
//  HTTPTransport
//
//  Created by Ivan Vavilov
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - Aliases

public typealias RequestRetryCompletion = (_ shouldRetry: Bool, _ timeDelay: TimeInterval) -> Void

// MARK: - HTTPTransportRetrier

/// Alamofire's `RequestRetrier` & `RequestAdapter` all in one.
/// - Seealso: Use `WebTransportRetrierDelegate` in order to provide business logic
open class HTTPTransportRetrier {

    // MARK: - Properties

    private var isRefreshing    = false
    private var requestsToRetry = [(RetryResult) -> Void]()

    /// HTTPTransportRetrierDelegate instance
    private let delegate: HTTPTransportRetrierDelegate

    // MARK: - Initializers

    /// Default initializer
    /// - Parameter delegate: HTTPTransportRetrierDelegate instance
    public init(delegate: HTTPTransportRetrierDelegate) {
        self.delegate = delegate
    }
}

// MARK: - RequestInterceptor

extension HTTPTransportRetrier: RequestInterceptor {

    public func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        delegate.adapted(urlRequest)
    }
    
    public func retry(
        _ request: Request,
        for session: Alamofire.Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard request.retryCount < delegate.maxAttemptsCount else {
            completion(.doNotRetry)
            return
        }
        var responseJSON: Any?
        if let data = (request as? DataRequest)?.data  {
            responseJSON = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
        }
        if let response = request.task?.response as? HTTPURLResponse,
           delegate.shouldRetry(response, responseJSON: responseJSON, error: error) {
            requestsToRetry.append(completion)
            if !isRefreshing {
                isRefreshing = true
                delegate.refreshForRetrieve { [weak self] success in
                    guard let self = self else {
                        return
                    }
                    self.isRefreshing = false
                    self.requestsToRetry.forEach { $0(.retry) }
                    self.requestsToRetry.removeAll()
                }
            }
        } else {
            completion(.doNotRetry)
        }
    }
}
