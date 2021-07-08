//
//  HTTPTransport.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - Aliases

public typealias ResultResponse = DataResponse<HTTPResponse, AFError>

// MARK: - HTTPTransport

/// Performs synchronous HTTP(s) request
open class HTTPTransport {

    // MARK: - Properties

    /// Default timeout gap for synchronous calls (calculated from `URLRequest` timeout)
    public static let defaultSemaphoreTimeoutGap: TimeInterval = 3

    /// TCP/HTTP session between client and server
    /// Includes security settings (see `Security`) and request retry strategy (see `HTTPTransportRetrier`)
    public let session: Session

    /// Synchronous calls' timeout (counting from `URLRequest` timeout)
    public let semaphoreTimeoutGap: TimeInterval

    /// Collection of interceptors for outgoing HTTP requests
    public let requestInterceptors: [HTTPRequestInterceptor]

    /// Collection of interceptors for incoming HTTP responses
    public let responseInterceptors: [HTTPResponseInterceptor]

    /// Allow using Alamofire `validate()` method
    public let useDefaultValidation: Bool
    
    /// Precondition failure on network calls on main thread is disabled
    public let allowNetworkingOnMainThread: Bool

    // MARK: - Initializers

    /// Convenience initializer
    /// - Parameters:
    ///   - security: applied SSL pinning policy; default is "no SSL pinning"
    ///   - interceptor: applied request retry policy; default is `None`
    ///   - semaphoreTimeoutGap: synchronous requests' timeout; default is `HTTPTransport.defaultSemaphoreTimeout`
    ///   - requestInterceptors: collection of interceptors for outgoing HTTP requests
    ///   - responseInterceptors: collection of interceptors for incoming HTTP responses
    ///   - useDefaultValidation: use Alamofire `validate()` method; default is true
    ///   - allowNetworkingOnMainThread: do not throw errors on networking on the main thread; default is false
    public convenience init(
        security: Security = Security.noEvaluation,
        interceptor: HTTPTransportRetrier? = nil,
        semaphoreTimeoutGap: TimeInterval = defaultSemaphoreTimeoutGap,
        requestInterceptors: [HTTPRequestInterceptor] = [],
        responseInterceptors: [HTTPResponseInterceptor] = [ClarifyErrorInterceptor()],
        useDefaultValidation: Bool = true,
        allowNetworkingOnMainThread: Bool = false
    ) {
        self.init(
            session: type(of: self).createSession(security: security, interceptor: interceptor),
            semaphoreTimeout: semaphoreTimeoutGap,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors,
            useDefaultValidation: useDefaultValidation,
            allowNetworkingOnMainThread: allowNetworkingOnMainThread
        )
    }

    /// Default initializer
    /// - Parameters:
    ///   - session: TCP/HTTP session between client and server
    ///   - semaphoreTimeout: synchronous requests' timeout; default is `HTTPTransport.defaultSemaphoreTimeout`
    ///   - requestInterceptors: collection of interceptors for outgoing HTTP requests
    ///   - responseInterceptors: collection of interceptors for incoming HTTP responses
    ///   - useDefaultValidation: use Alamofire `validate()` method; default is true
    ///   - allowNetworkingOnMainThread: do not throw errors on networking on the main thread; default is false
    public init(
        session: Session,
        semaphoreTimeout: TimeInterval = defaultSemaphoreTimeoutGap,
        requestInterceptors: [HTTPRequestInterceptor] = [],
        responseInterceptors: [HTTPResponseInterceptor] = [ClarifyErrorInterceptor()],
        useDefaultValidation: Bool = true,
        allowNetworkingOnMainThread: Bool = false
    ) {
        self.session = session
        self.semaphoreTimeoutGap = semaphoreTimeout
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.useDefaultValidation = useDefaultValidation
        self.allowNetworkingOnMainThread = allowNetworkingOnMainThread
    }

    // MARK: - Useful

    /// Send an HTTP request
    /// - Parameter request: an HTTP request with HTTP verb, URL, headers, body etc.
    /// - Returns: either `.success` with HTTP response or `.failure` with error object
    open func send(request: HTTPRequest) -> Result {
        guard !Thread.isMainThread || allowNetworkingOnMainThread
        else {
            preconditionFailure("Networking on the main thread")
        }
        let session = request.session ?? session
        let alamofireSession: Alamofire.Session = session.manager
        var result = Result.timeout
        let semaphore = DispatchSemaphore(value: 0)
        request.with(interceptors: requestInterceptors)
        let dataRequest = alamofireSession
            .request(request)
            .responseHTTP(
                interceptors: request.responseInterceptors + responseInterceptors
            ) { (response: ResultResponse) in
                result = self.composeResult(fromResponse: response)
                semaphore.signal()
            }
        if useDefaultValidation {
            dataRequest.validate()
        }
        let gap = request.timeout + semaphoreTimeoutGap
        _ = semaphore.wait(timeout: DispatchTime.now() + gap)
        return result
    }

    /// Send an HTTP request
    /// - Parameter request: an `URLRequest` instance
    /// - Returns: either `.success` with HTTP response or `.failure` with error object
    open func send(request: URLRequest) -> Result {
        guard !Thread.isMainThread || allowNetworkingOnMainThread
        else {
            preconditionFailure("Networking on the main thread")
        }
        let alamofireSession: Alamofire.Session = session.manager
        var result = Result.timeout
        let semaphore = DispatchSemaphore(value: 0)
        let interceptedRequest = requestInterceptors.reduce(request) { (
            result: URLRequest,
            interceptor: HTTPRequestInterceptor
        ) -> URLRequest in
            return interceptor.intercept(request: result)
        }
        let dataRequest = alamofireSession
            .request(interceptedRequest)
            .responseHTTP(interceptors: responseInterceptors) { (response: ResultResponse) in
                result = self.composeResult(fromResponse: response)
                semaphore.signal()
            }
        if useDefaultValidation {
            dataRequest.validate()
        }
        let gap = interceptedRequest.timeoutInterval + semaphoreTimeoutGap
        _ = semaphore.wait(timeout: DispatchTime.now() + gap)
        return result
    }

    /// Send an HTTP request in order to upload file
    /// - Parameter request: an HTTP request with HTTP verb, URL, headers, file data etc.
    /// - Returns: either `.success` with HTTP response or `.failure` with error object
    open func send(request: FileUploadHTTPRequest) -> Result {
        guard !Thread.isMainThread || allowNetworkingOnMainThread
        else {
            preconditionFailure("Networking on the main thread")
        }
        let session = request.session ?? session
        let alamofireSession: Alamofire.Session = session.manager
        var result = Result.timeout
        let semaphore = DispatchSemaphore(value: 0)
        request.with(interceptors: requestInterceptors)
        let uploadResult = alamofireSession.upload(
            multipartFormData: { (formData: MultipartFormData) in
                formData.append(
                    request.fileMultipart.fileData,
                    withName: request.fileMultipart.partName,
                    fileName: request.fileMultipart.fileName,
                    mimeType: request.fileMultipart.mimeType.value
                )
                request.parameters.forEach{
                    for (key, value) in $0.parameters {
                        if let value = value as? String {
                            formData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                        }
                    }
                }
            },
            with: request
        )
        uploadResult.responseHTTP(
            interceptors: request.responseInterceptors + responseInterceptors,
            completionHandler: { respons in
                result = self.composeResult(fromResponse: respons)
                semaphore.signal()
            }
        )
        if useDefaultValidation {
            uploadResult.validate()
        }
        let gap = request.timeout + semaphoreTimeoutGap
        _ = semaphore.wait(timeout: DispatchTime.now() + gap)
        return result
    }

    /// Send an HTTP request asynchronously
    /// - Parameters:
    ///   - request: an HTTP request with HTTP verb, URL, headers, body etc.
    ///   - callback: completion closure fired with a result of call
    /// - Returns: cancellable HTTPCall object, with observable progress
    @discardableResult public func send(
        request: HTTPRequest,
        callback: @escaping Callback
    ) -> HTTPCall<DataRequest> {
        let session = request.session ?? session
        let alamofireSession: Alamofire.Session = session.manager
        request.with(interceptors: requestInterceptors)
        let dataRequest = alamofireSession
            .request(request)
            .responseHTTP(
                interceptors: request.responseInterceptors + responseInterceptors
            ) { (response: ResultResponse) in
                callback(self.composeResult(fromResponse: response))
            }
        if useDefaultValidation {
            dataRequest.validate()
        }
        return HTTPCall(request: dataRequest)
    }

    /// Send an HTTP request asynchronously
    /// - Parameters:
    ///   - request: an `URLRequest` instance
    ///   - callback: completion closure fired with a result of call
    /// - Returns: cancellable HTTPCall object, with observable progress
    @discardableResult public func send(
        request: URLRequest,
        callback: @escaping Callback
    ) -> HTTPCall<DataRequest> {
        let session: Alamofire.Session = self.session.manager
        let interceptedRequest = requestInterceptors.reduce(request) { (
            result: URLRequest,
            interceptor: HTTPRequestInterceptor
        ) -> URLRequest in
            return interceptor.intercept(request: result)
        }
        let dataRequest = session
            .request(interceptedRequest)
            .responseHTTP(
                interceptors: responseInterceptors
            ) { (response: ResultResponse) in
                callback(self.composeResult(fromResponse: response))
            }
        if useDefaultValidation {
            dataRequest.validate()
        }
        return HTTPCall(request: dataRequest)
    }

    /// Send an HTTP request in order to upload file (asynchronously)
    /// - Parameters:
    ///   - request: an HTTP request with HTTP verb, URL, headers, file data etc.
    ///   - multipartEncodingCallback: file data encoding completion closure
    ///   - callback: completion closure fired with a result of call
    open func send(
        request: FileUploadHTTPRequest,
        multipartEncodingCallback: MultipartEncodingCallback? = nil,
        callback: @escaping Callback
    ) {
        let session = request.session ?? session
        let alamofireSession: Alamofire.Session = session.manager
        request.with(interceptors: requestInterceptors)
        let uploadResult = alamofireSession.upload(
            multipartFormData: { (formData: MultipartFormData) in
                formData.append(
                    request.fileMultipart.fileData,
                    withName: request.fileMultipart.partName,
                    fileName: request.fileMultipart.fileName,
                    mimeType: request.fileMultipart.mimeType.value
                )
                request.parameters.forEach{
                    for (key, value) in $0.parameters {
                        if let value = value as? String {
                            formData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                        }
                    }
                }
            },
            with: request
        )
        uploadResult.responseHTTP(
            interceptors: request.responseInterceptors + responseInterceptors,
            completionHandler: { response in
                callback(self.composeResult(fromResponse: response))
            }
        )
        if useDefaultValidation {
            uploadResult.validate()
        }
    }

    /// Send an HTTP request with data
    /// - Parameter request: an HTTP request with HTTP verb, URL, headers, data etc.
    /// - Returns: either `.success` with HTTP response or `.failure` with error object
    public func send(request: DataUploadHTTPRequest) -> Result {
        guard !Thread.isMainThread || allowNetworkingOnMainThread
        else {
            preconditionFailure("Networking on the main thread")
        }
        let session = request.session ?? session
        let alamofireSession: Alamofire.Session = session.manager
        var result = Result.timeout
        let semaphore = DispatchSemaphore(value: 0)
        request.with(interceptors: requestInterceptors)
        var urlRequest: URLRequest!
        do {
            urlRequest = try request.asURLRequest()
        } catch let error {
            return .failure(error: error as NSError)
        }
        let interceptedRequest = requestInterceptors.reduce(urlRequest) { (
            result: URLRequest,
            interceptor: HTTPRequestInterceptor
        ) -> URLRequest in
            return interceptor.intercept(request: result)
        }
        let uploadRequest = alamofireSession
            .upload(request.data, with: interceptedRequest)
            .responseHTTP(
                interceptors: request.responseInterceptors + responseInterceptors
            ) { (response: ResultResponse) in
                result = self.composeResult(fromResponse: response)
                semaphore.signal()
            }
        if useDefaultValidation {
            uploadRequest.validate()
        }
        let gap = request.timeout + semaphoreTimeoutGap
        _ = semaphore.wait(timeout: DispatchTime.now() + gap)
        return result
    }

    /// Send an HTTP request with data asynchronously
    /// - Parameters:
    ///   - data: data to send
    ///   - request: an `URLRequest` instance
    ///   - callback: completion closure fired with a result of call
    /// - Returns: cancellable HTTPCall object, with observable progress
    public func send(data: Data, request: URLRequest, callback: @escaping Callback) -> HTTPCall<DataRequest> {
        let alamofireSession: Alamofire.Session = self.session.manager
        let interceptedRequest = requestInterceptors.reduce(request) { (
            result: URLRequest,
            interceptor: HTTPRequestInterceptor
        ) -> URLRequest in
            return interceptor.intercept(request: result)
        }
        let uploadRequest = alamofireSession
            .upload(data, with: interceptedRequest)
            .responseHTTP(
                interceptors: responseInterceptors
            ) { (response: ResultResponse) in
                callback(self.composeResult(fromResponse: response))
            }
        if useDefaultValidation {
            uploadRequest.validate()
        }
        return HTTPCall(request: uploadRequest)
    }

    // MARK: - Result
    
    /// HTTP request result
    public enum Result {

        // MARK: - Cases

        case success(response: HTTPResponse)
        case failure(error: NSError)

        // MARK: - Properties

        public static var timeout: Result {
            Result.failure(error: NSError.timeout)
        }
    }

    // MARK: - MultipartEncodingResult

    /// File data encoding result
    public enum MultipartEncodingResult {

        // MARK: - Cases

        case success(call: UploadHTTPCall)
        case failure(error: Error)
    }

    // MARK: - Aliases

    /// Callback closure returning result of HTTP call
    public typealias Callback = (_ result: Result) -> ()

    /// Callback closure returning result of file data encoding into URLRequest
    public typealias MultipartEncodingCallback = (_ result: MultipartEncodingResult) -> ()
}

// MARK: - Private

private extension HTTPTransport {

    class func createSession(
        security: Security,
        interceptor: HTTPTransportRetrier?
    ) -> Session {
        let alamofireSession = Alamofire.Session(
            startRequestsImmediately: true,
            interceptor: interceptor,
            serverTrustManager: security.trustPolicyManager
        )
        return Session(manager: alamofireSession)
    }

    func composeResult(fromResponse response: ResultResponse) -> Result {
        switch response.result {
        case let .success(httpResponse):
            return Result.success(response: httpResponse)
        case let .failure(afError):
            return Result.failure(error: afError.underlyingError as NSError? ?? afError as NSError)
        }
    }
}
