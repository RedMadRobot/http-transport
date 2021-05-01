//
//  HTTPTransportRetrier.swift
//  HTTPTransport
//
//  Created by Ivan Vavilov
//  Copyright © 2017 RedMadRobot. All rights reserved.
//


import Alamofire


public typealias RequestRetryCompletion = (_ shouldRetry: Bool, _ timeDelay: TimeInterval) -> Void

/**
 Responsibility to decide, whether the request should be retried or not, and when.
 */
public protocol HTTPTransportRetrierDelegate {
    
    /**
     How many times request should be retried?
     */
    var maxAttemptsCount: Int { get }
    
    /**
     Failed request should be retried - yes or no?
     
     - Parameters:
         - response: former request answer;
         - responseJSON: serialized server response payload;
         - error: former request error.
     
     - Returns: Failed request should be retried - yes or no?
     */
    func shouldRetry(_ response: URLResponse, responseJSON: Any?, error: Error) -> Bool

    /**
     Here, perform all necessary work before failed request retrial will happen.
     
     - Parameter completion: call when finished.
     */
    func refreshForRetrieve(completion: @escaping (Bool) -> ())

    /**
     Adapt the original failed request before retrying.
     
     - Parameter urlRequest: original request.
     
     - Returns: modified or the same request.
     */
    func adapted(_ urlRequest: URLRequest) -> URLRequest

}


/**
 Alamofire's `RequestRetrier` & `RequestAdapter` all in one.
 
 - Seealso: Use `WebTransportRetrierDelegate` in order to provide business logic.
 */
open class HTTPTransportRetrier: RequestInterceptor {

    private var isRefreshing    = false
    private var requestsToRetry = [(RetryResult) -> Void]()

    private let delegate: HTTPTransportRetrierDelegate


    public init(delegate: HTTPTransportRetrierDelegate) {
        self.delegate = delegate
    }
    
    // MARK: - RequestAdapter

    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        completion(.success(delegate.adapted(urlRequest)))
    }
    
    public func retry(_ request: Request, for session: Alamofire.Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
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
