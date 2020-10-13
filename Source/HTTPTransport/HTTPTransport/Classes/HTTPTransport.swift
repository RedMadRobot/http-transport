//
//  HTTPTransport.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//


import Alamofire
import Foundation


public typealias ResultResponse = DataResponse<HTTPResponse, AFError>

/**
 Performs synchronous HTTP(s) requests.
 */
open class HTTPTransport {

    /**
     Default timeout gap for synchronous calls (calculated from `URLRequest` timeout).
     */
    public static let defaultSemaphoreTimeoutGap: TimeInterval = 3

    /**
     TCP/HTTP sessionManager between client and server.
     
     Includes security settings (see `Security`) and request retry strategy (see `HTTPTransportRetrier`).
     */
    public let sessionManager: SessionManager

    /**
     Synchronous calls' timeout (counting from `URLRequest` timeout).
     */
    public let semaphoreTimeoutGap: TimeInterval

    /**
     Collection of interceptors for outgoing HTTP requests.
     */
    public let requestInterceptors: [HTTPRequestInterceptor]

    /**
     Collection of interceptors for incoming HTTP responses.
     */
    public let responseInterceptors: [HTTPResponseInterceptor]

    /**
     Allow using Alamofire `validate()` method.
     */
    public let useDefaultValidation: Bool
    
    /**
     Precondition failure on network calls on main thread is disabled.
     */
    public let allowNetworkingOnMainThread: Bool

    /**
     Initializer.
     
     - parameter security: applied SSL pinning policy; default is "no SSL pinning";
     - parameter retrier: applied request retry policy; default is `None`
     - parameter semaphoreTimeout: synchronous requests' timeout; default is `HTTPTransport.defaultSemaphoreTimeout`;
     - parameter requestInterceptors: collection of interceptors for outgoing HTTP requests;
     - parameter responseInterceptors: collection of interceptors for incoming HTTP responses;
     - parameter useDefaultValidation: use Alamofire `validate()` method; default is true;
     - parameter allowNetworkingOnMainThread: do not throw errors on networking on the main thread; default is false.
     */
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
            sessionManager: type(of: self).createSessionManager(security: security, interceptor: interceptor),
            semaphoreTimeout: semaphoreTimeoutGap,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors,
            useDefaultValidation: useDefaultValidation,
            allowNetworkingOnMainThread: allowNetworkingOnMainThread
        )
    }

    /**
     Initializer.
     
     - parameter sessionManager: TCP/HTTP sessionManager between client and server;
     - parameter semaphoreTimeout: synchronous requests' timeout; default is `HTTPTransport.defaultSemaphoreTimeout`;
     - parameter requestInterceptors: collection of interceptors for outgoing HTTP requests;
     - parameter responseInterceptors: collection of interceptors for incoming HTTP responses;
     - parameter useDefaultValidation: use Alamofire `validate()` method; default is true;
     - parameter allowNetworkingOnMainThread: do not throw errors on networking on the main thread; default is false.
     */
    public init(
        sessionManager: SessionManager,
        semaphoreTimeout: TimeInterval = defaultSemaphoreTimeoutGap,
        requestInterceptors: [HTTPRequestInterceptor] = [],
        responseInterceptors: [HTTPResponseInterceptor] = [ClarifyErrorInterceptor()],
        useDefaultValidation: Bool = true,
        allowNetworkingOnMainThread: Bool = false
    ) {
        self.sessionManager = sessionManager
        self.semaphoreTimeoutGap = semaphoreTimeout
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.useDefaultValidation = useDefaultValidation
        self.allowNetworkingOnMainThread = allowNetworkingOnMainThread
    }

    /**
     Send an HTTP request.
     
     - parameter request: an HTTP request with HTTP verb, URL, headers, body etc.
     
     - returns: either `.success` with HTTP response or `.failure` with error object.
     */
    open func send(request: HTTPRequest) -> Result {
        guard !Thread.isMainThread || allowNetworkingOnMainThread
        else {
            preconditionFailure("Networking on the main thread")
        }

        let sessionManager:        SessionManager        = request.sessionManager ?? self.sessionManager
        let session: Session = sessionManager.manager

        var result:    Result            = Result.timeout
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

        request.with(interceptors: self.requestInterceptors)

        let dataRequest: DataRequest =
            session
                .request(request)
                .responseHTTP(
                    interceptors: request.responseInterceptors + self.responseInterceptors
                ) { (response: ResultResponse) in
                    result = self.composeResult(fromResponse: response)
                    semaphore.signal()
                }

        if self.useDefaultValidation {
            dataRequest.validate()
        }

        let gap: TimeInterval = request.timeout + self.semaphoreTimeoutGap
        _ = semaphore.wait(timeout: DispatchTime.now() + gap)
        return result
    }

    /**
     Send an HTTP request.

     - parameter request: an `URLRequest` instance.

     - returns: either `.success` with HTTP response or `.failure` with error object.
     */
    open func send(request: URLRequest) -> Result {
        guard !Thread.isMainThread || allowNetworkingOnMainThread
        else {
            preconditionFailure("Networking on the main thread")
        }

        let session: Session = self.sessionManager.manager

        var result:    Result            = Result.timeout
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

        let interceptedRequest: URLRequest =
            self.requestInterceptors.reduce(request) { (
                result: URLRequest,
                interceptor: HTTPRequestInterceptor
            ) -> URLRequest in
                return interceptor.intercept(request: result)
            }

        let dataRequest: DataRequest =
            session
                .request(interceptedRequest)
                .responseHTTP(interceptors: self.responseInterceptors) { (response: ResultResponse) in
                    result = self.composeResult(fromResponse: response)
                    semaphore.signal()
                }

        if self.useDefaultValidation {
            dataRequest.validate()
        }

        let gap: TimeInterval = interceptedRequest.timeoutInterval + self.semaphoreTimeoutGap
        _ = semaphore.wait(timeout: DispatchTime.now() + gap)
        return result
    }

    /**
     Send an HTTP request in order to upload file.
     
     - parameter request: an HTTP request with HTTP verb, URL, headers, file data etc.
     
     - attention: JSON-encoded request parameters are ignored, plist-encoded parameters are put together with the body 
     form data, URL parameters go into URL as always.
     
     - returns: either `.success` with HTTP response or `.failure` with error object.
     */
    open func send(request: FileUploadHTTPRequest) -> Result {
        guard !Thread.isMainThread || allowNetworkingOnMainThread
        else {
            preconditionFailure("Networking on the main thread")
        }

        let sessionManager:        SessionManager        = request.sessionManager ?? self.sessionManager
        let session: Session = sessionManager.manager

        var result: Result            = Result.timeout
        let semaphore:    DispatchSemaphore = DispatchSemaphore(value: 0)

        request.with(interceptors: self.requestInterceptors)

        let uploadResult = session.upload(
            multipartFormData: { (formData: MultipartFormData) in
                formData.append(
                    request.fileMultipart.fileData,
                    withName: request.fileMultipart.partName,
                    fileName: request.fileMultipart.fileName,
                    mimeType: request.fileMultipart.mimeType.value
                )

                let parameters: [String: Any] = request.parameters.reduce([:]) {
                    (result: [String: Any], parameters: HTTPRequestParameters) -> [String: Any] in
                    var result = result
                    if case HTTPRequestParameters.Encoding.json = parameters.encoding {
                        parameters.parameters.forEach { (key: String, value: Any) in
                            result[key] = value
                        }
                    }
                    return result
                }

                for (key, value) in parameters {
                    if let value = value as? String {
                        formData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                    }
                }
            },
            with: request
        )
        
        uploadResult.responseHTTP(interceptors: request.responseInterceptors + self.responseInterceptors,
                            completionHandler: { respons in
                                result = self.composeResult(fromResponse: respons)
                                semaphore.signal()
                            })
        
        if self.useDefaultValidation {
            uploadResult.validate()
        }
        
        let gap: TimeInterval = request.timeout + self.semaphoreTimeoutGap
        _ = semaphore.wait(timeout: DispatchTime.now() + gap)
        return result
    }

    /**
     Send an HTTP request asynchronously.

     - parameter request: an HTTP request with HTTP verb, URL, headers, body etc.
     - parameter callback: completion closure fired with a result of call.

     - returns: cancellable HTTPCall object, with observable progress.
     */
    @discardableResult
    public func send(request: HTTPRequest, callback: @escaping Callback) -> HTTPCall<DataRequest> {
        let sessionManager:        SessionManager        = request.sessionManager ?? self.sessionManager
        let session: Session = sessionManager.manager

        request.with(interceptors: self.requestInterceptors)

        let dataRequest: DataRequest =
            session
                .request(request)
                .responseHTTP(
                    interceptors: request.responseInterceptors + self.responseInterceptors
                ) { (response: ResultResponse) in
                    callback(self.composeResult(fromResponse: response))
                }

        if self.useDefaultValidation {
            dataRequest.validate()
        }

        return HTTPCall(request: dataRequest)
    }

    /**
     Send an HTTP request asynchronously.

     - parameter request: an `URLRequest` instance.
     - parameter callback: completion closure fired with a result of call.

     - returns: cancellable HTTPCall object, with observable progress.
     */
    @discardableResult
    public func send(request: URLRequest, callback: @escaping Callback) -> HTTPCall<DataRequest> {
        let session: Session = self.sessionManager.manager

        let interceptedRequest: URLRequest =
            self.requestInterceptors.reduce(request) { (
                result: URLRequest,
                interceptor: HTTPRequestInterceptor
            ) -> URLRequest in
                return interceptor.intercept(request: result)
            }

        let dataRequest: DataRequest =
            session
                .request(interceptedRequest)
                .responseHTTP(
                    interceptors: self.responseInterceptors
                ) { (response: ResultResponse) in
                    callback(self.composeResult(fromResponse: response))
                }

        if self.useDefaultValidation {
            dataRequest.validate()
        }

        return HTTPCall(request: dataRequest)
    }

    /**
     Send an HTTP request in order to upload file (asynchronously).

     - parameter request: an HTTP request with HTTP verb, URL, headers, file data etc.
     - parameter multipartEncodingCallback: file data encoding completion closure.
     - parameter callback: completion closure fired with a result of call.

     - attention: JSON-encoded request parameters are ignored, plist-encoded parameters are put together with the body
     form data, URL parameters go into URL as always.
     */
    open func send(
        request: FileUploadHTTPRequest,
        multipartEncodingCallback: MultipartEncodingCallback? = nil,
        callback: @escaping Callback
    ) {
        let sessionManager:        SessionManager        = request.sessionManager ?? self.sessionManager
        let session: Session = sessionManager.manager

        request.with(interceptors: self.requestInterceptors)

        let uploadResult = session.upload(
            multipartFormData: { (formData: MultipartFormData) in
                formData.append(
                    request.fileMultipart.fileData,
                    withName: request.fileMultipart.partName,
                    fileName: request.fileMultipart.fileName,
                    mimeType: request.fileMultipart.mimeType.value
                )

                let parameters: [String: Any] = request.parameters.reduce([:]) {
                    (result: [String: Any], parameters: HTTPRequestParameters) -> [String: Any] in
                    var result = result
                    if case HTTPRequestParameters.Encoding.json = parameters.encoding {
                        parameters.parameters.forEach { (key: String, value: Any) in
                            result[key] = value
                        }
                    }
                    return result
                }

                for (key, value) in parameters {
                    if let value = value as? String {
                        formData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                    }
                }
            },
            with: request
        )
        uploadResult.responseHTTP(interceptors: request.responseInterceptors + self.responseInterceptors,
                                  completionHandler: { response in
                                    callback(self.composeResult(fromResponse: response))
                                  })
        
        if self.useDefaultValidation {
            uploadResult.validate()
        }
    }

    /**
     Send an HTTP request with data.
     
     - parameter request: an HTTP request with HTTP verb, URL, headers, data etc.
     
     - returns: either `.success` with HTTP response or `.failure` with error object.
     */
    public func send(request: DataUploadHTTPRequest) -> Result {
        guard !Thread.isMainThread || allowNetworkingOnMainThread
        else {
            preconditionFailure("Networking on the main thread")
        }
        
        let sessionManager: SessionManager               = request.sessionManager ?? self.sessionManager
        let session: Session = sessionManager.manager
        
        var result: Result               = Result.timeout
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        
        request.with(interceptors: self.requestInterceptors)
        
        var urlRequest: URLRequest!
        
        do {
            urlRequest = try request.asURLRequest()
        } catch let error {
            return .failure(error: error as NSError)
        }
        
        let interceptedRequest: URLRequest =
            self.requestInterceptors.reduce(urlRequest) { (
                result: URLRequest,
                interceptor: HTTPRequestInterceptor
            ) -> URLRequest in
                return interceptor.intercept(request: result)
            }
        
        let uploadRequest: UploadRequest =
            session
                .upload(request.data, with: interceptedRequest)
                .responseHTTP(
                    interceptors: request.responseInterceptors + self.responseInterceptors
                ) { (response: ResultResponse) in
                    result = self.composeResult(fromResponse: response)
                    semaphore.signal()
                }
        
        if self.useDefaultValidation {
            uploadRequest.validate()
        }
        
        let gap: TimeInterval = request.timeout + self.semaphoreTimeoutGap
        _ = semaphore.wait(timeout: DispatchTime.now() + gap)
        return result
    }
    
    /**
     Send an HTTP request with data asynchronously.
     
     - parameter data: data to send.
     - parameter request: an `URLRequest` instance.
     - parameter callback: completion closure fired with a result of call.
     
     - returns: cancellable HTTPCall object, with observable progress.
     */
    public func send(data: Data, request: URLRequest, callback: @escaping Callback) -> HTTPCall<DataRequest> {
        let session: Session = self.sessionManager.manager
        
        let interceptedRequest: URLRequest =
            self.requestInterceptors.reduce(request) { (
                result: URLRequest,
                interceptor: HTTPRequestInterceptor
            ) -> URLRequest in
                return interceptor.intercept(request: result)
        }
        
        let uploadRequest: UploadRequest =
            session
                .upload(data, with: interceptedRequest)
                .responseHTTP(
                    interceptors: self.responseInterceptors
                ) { (response: ResultResponse) in
                    callback(self.composeResult(fromResponse: response))
                }
        
        if self.useDefaultValidation {
            uploadRequest.validate()
        }
        
        return HTTPCall(request: uploadRequest)
    }
    
    /**
     HTTP request result.
     */
    public enum Result {
        case success(response: HTTPResponse)
        case failure(error: NSError)

        public static var timeout: Result {
            return Result.failure(error: NSError.timeout)
        }
    }

    /**
     File data encoding result.
     */
    public enum MultipartEncodingResult {
        case success(call: UploadHTTPCall)
        case failure(error: Error)
    }

    /**
     Callback closure returning result of HTTP call.
     */
    public typealias Callback = (_ result: Result) -> ()

    /**
     Callback closure returning result of file data encoding into URLRequest.
     */
    public typealias MultipartEncodingCallback = (_ result: MultipartEncodingResult) -> ()
}


private extension HTTPTransport {

    class func createSessionManager(
        security: Security,
        interceptor: HTTPTransportRetrier?
    ) -> SessionManager {
        let manager: Session = Session(startRequestsImmediately: true,
                                       interceptor: interceptor,
                                       serverTrustManager: security.trustPolicyManager)
        return SessionManager(manager: manager)
    }

    func composeResult(fromResponse response: ResultResponse) -> Result {
        switch response.result {
        case let .success(httpResponse):
            return Result.success(response: httpResponse)
        
        case let .failure(afError):
            return Result.failure(error: afError as NSError)
        }
    }

}
