//
//  HTTPCall
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - HTTPCall

/// Cancellable HTTP call with observable progress
public class HTTPCall<Request: DataRequest> {

    // MARK: - Aliases

    /// Progress changes observer
    public typealias ProgressHandler = (_ progress: Progress) -> ()

    // MARK: - Properties

    fileprivate let request: Request

    // MARK: - Initializers

    /// Default initalizer
    /// - Parameter request: request
    internal init(request: Request) {
        self.request = request
    }

    // MARK: - Useful

    /// Cancel HTTP call
    public func cancel() {
        request.cancel()
    }

    /// Observe progress changes
    /// - Parameters:
    ///   - callbackQueue: queue to call progress handler; default is `main`
    ///   - handler: callback to be called on progress change
    public func onProgress(
        callbackQueue: DispatchQueue = DispatchQueue.main,
        handler: @escaping ProgressHandler
    ) {
        request.downloadProgress(queue: callbackQueue) { progress in handler(progress) }
    }
}

// MARK: - UploadHTTPCall

/// Cancellable HTTP call with observable progress for file uploads
public class UploadHTTPCall: HTTPCall<UploadRequest> {

    /// Observe upload progress
    /// - Parameters:
    ///   - callbackQueue: queue to call progress handler; default is `main`
    ///   - handler: callback to be called on progress change
    public func onUploadProgress(
        callbackQueue: DispatchQueue = DispatchQueue.main,
        handler: @escaping ProgressHandler
    ) {
        request.uploadProgress(queue: callbackQueue) { progress in handler(progress) }
    }
}
