//
//  ViewController.swift
//  Example
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import UIKit
import HTTPTransport

// MARK: - ViewController

class ViewController: UIViewController {

    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resourceURI = "https://private-024fa-template12.apiary-mock.com/messages"
        let errorURI = "https://private-024fa-template12.apiary-mock.com/message"
        
        let queue = OperationQueue()
        let cookieStorage = CookieStorage()
        
        let transport = HTTPTransport(
            security: Security(certificates: [
                    TrustPolicyManager.Certificate.wildcard
                ]
            ),
            requestInterceptors: [
                AddCookieInterceptor(cookieProvider: cookieStorage),
                LogRequestInterceptor(logLevel: LogRequestInterceptor.LogLevel.everything),
            ],
            responseInterceptors: [
                ReceivedCookieInterceptor(cookieStorage: cookieStorage),
                ClarifyErrorInterceptor(),
                LogResponseInterceptor(
                    logLevel: LogResponseInterceptor.LogLevel.headers,
                    headerFilter:[
                        LogResponseInterceptor.Header.contentType,
                        LogResponseInterceptor.Header.setCookie,
                    ]
                ),
            ]
        )
        
        let request = HTTPRequest(httpMethod: HTTPRequest.HTTPMethod.get, endpoint: resourceURI)
            .with(cookie: HTTPCookie(name: "wild_token", value: "123456"))
            .with(parameter: "query", value: "search", encoding: HTTPRequestParameters.Encoding.url)
            .with(
                parameters: HTTPRequestParameters(
                    parameters: [
                        "limit": 10,
                        "offset": 0,
                        "search_id": UUID().uuidString,
                    ],
                    encoding: HTTPRequestParameters.Encoding.url
                )
            )
        
        queue.addOperation {
            let result = transport.send(request: request)
            print("\nRESULTS\n")
            switch result {
                case .success(let response):
                    debugPrint(try! response.getJSONDictionary()!)
                    break
                case .failure:
                    break
            }
            print("")
        }
        
        let errorRequest = HTTPRequest(endpoint: errorURI)
        queue.addOperation {
            let result: HTTPTransport.Result = transport.send(request: errorRequest)
            print("\nERROR RESULTS\n")
            switch result {
                case .success:
                    break
                case .failure(let error):
                    // { "error": { "code": ..., "message": ... } }
                    print("STATUS:  \(error.httpStatusCode!)")            // 400 Bad Request
                    print("CODE:    \(error.responseBodyErrorCode!)")     // error.code value from payload
                    print("MESSAGE: \(error.responseBodyErrorMessage!)")  // error.message value from payload
                    print("")
                    print("DATA:      \(error.responseBodyData!)")
                    print("STRING:    \(error.responseBodyString!)")
                    print("JSON:      \(error.responseBodyJSON!)")
                    print("JSON DICT: \(error.responseBodyJSONDictionary!)")
                    break
            }
            print("")
        }
        
        let fileName = "text.txt"
        let fileUploadRequest = FileUploadHTTPRequest(
            httpMethod: HTTPRequest.HTTPMethod.post,
            endpoint: "http://dumb.upload.com",
            fileData: "Text file data".data(using: String.Encoding.utf8)!,
            partName: "text_file",
            fileName: fileName,
            mimeType: MIMEType(path: fileName)
        )
        
        queue.addOperation {
            let _ = transport.send(request: fileUploadRequest)
        }
        
        let imageRequest = HTTPRequest(
            endpoint: "https://upload.wikimedia.org/wikipedia/commons/3/3d/LARGE_elevation.jpg"
        )
        
        let call = transport.send(request: imageRequest) { (result: HTTPTransport.Result) in
                switch result {
                    case .success:
                        print("SUCCESS")
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }
        
        call.onProgress { (progress: Progress) in
            if progress.fractionCompleted > 0.5 {
                call.cancel()
            }
        }
        
        let debugSecurity = Security(
            certificates: [
                TrustPolicyManager.Certificate(
                    host: "gist.github.com", // LOOK FOR "gist.github.com" IN CONSOLE
                    fingerprint: TrustPolicyManager.Certificate.Fingerprint.debug
                )
            ]
        )
        
        let debugTransport = HTTPTransport(security: debugSecurity)
        let debugRequest = HTTPRequest(endpoint: "https://gist.github.com/chedabob/64a4cdc4a1194d815814")
        
        debugTransport.send(request: debugRequest) { (result: HTTPTransport.Result) in
            print(result)
        }
    }

    // MARK: - CookieStorage
    
    class CookieStorage: CookieStoring, CookieProviding {

        func store(cookies: [HTTPCookie]) {
            cookies.forEach { (cookie: HTTPCookie) in
                print("RECEIVED COOKIES:")
                print(cookie.name + " = " + cookie.value)
            }
        }
        
        func getStoredCookies() -> [HTTPCookie] {
            [HTTPCookie(name: "default_token", value: "abcdef")]
        }
    }
}
