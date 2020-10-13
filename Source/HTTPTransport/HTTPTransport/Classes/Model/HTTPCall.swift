//
//  HTTPCall
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2017 RedMadRobot LLC. All rights reserved.
//


import Alamofire
import Foundation


/**
 Cancellable HTTP call with observable progress.
 */
public class HTTPCall<Request: DataRequest> {
    fileprivate let request: Request

    /**
     Cancel HTTP call.
     */
    public func cancel() {
        request.cancel()
    }

    /**
     Observe progress changes.

     - parameter callbackQueue: queue to call progress handler; default is `main`
     - parameter handler: callback to be called on progress change.
     */
    public func onProgress(callbackQueue: DispatchQueue = DispatchQueue.main, handler: @escaping ProgressHandler) {
        request.downloadProgress(queue: callbackQueue) { progress in handler(progress) }
    }

    internal init(request: Request) {
        self.request = request
    }

    /**
     Progress changes observer.
     */
    public typealias ProgressHandler = (_ progress: Progress) -> ()
}

/**
 Cancellable HTTP call with observable progress for file uploads.
 */
public class UploadHTTPCall: HTTPCall<UploadRequest> {
    /**
     Observe upload progress.

     - parameter callbackQueue: queue to call progress handler; default is `main`
     - parameter handler: callback to be called on progress change.
     */
    public func onUploadProgress(callbackQueue: DispatchQueue = DispatchQueue.main, handler: @escaping ProgressHandler) {
        self.request.uploadProgress(queue: callbackQueue) { progress in handler(progress) }
    }
}
