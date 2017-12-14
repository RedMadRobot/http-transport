//
//  ViewController.swift
//  Example
//
//  Created by Jeorge Taflanidi
//  Copyright © 28 Heisei RedMadRobot LLC. All rights reserved.
//


import UIKit
import HTTPTransport


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resourceURI: String = "https://private-024fa-template12.apiary-mock.com/messages"
        let errorURI: String    = "https://private-024fa-template12.apiary-mock.com/message"
        
        let queue: OperationQueue        = OperationQueue()
        let cookieStorage: CookieStorage = CookieStorage()
        
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
        
        let request: HTTPRequest =
            HTTPRequest(httpMethod: HTTPRequest.HTTPMethod.get, endpoint: resourceURI)
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
            let result: HTTPTransport.Result = transport.send(request: request)
        
            print("")
            print("RESULTS")
            print("")
            
            switch result {
                case .success(let response):
                    debugPrint(try! response.getJSONDictionary()!)
                    break
                case .failure:
                    break
            }
            print("")
        }
        
        let errorRequest: HTTPRequest = HTTPRequest(
            endpoint: errorURI
        )
        
        queue.addOperation {
            let result: HTTPTransport.Result = transport.send(request: errorRequest)
            
            print("")
            print("ERROR RESULTS")
            print("")
            
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
        
        let fileName: String = "text.txt"
        
        let fileUploadRequest: FileUploadHTTPRequest =
            FileUploadHTTPRequest(
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
        
        let imageRequest: HTTPRequest =
            HTTPRequest(endpoint: "https://upload.wikimedia.org/wikipedia/commons/3/3d/LARGE_elevation.jpg")
        
        let call: HTTPCall =
            transport.send(request: imageRequest) { (result: HTTPTransport.Result) in
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
        
        let debugSecurity: Security =
            Security(
                certificates: [
                    TrustPolicyManager.Certificate(
                        host: "gist.github.com", // LOOK FOR "gist.github.com" IN CONSOLE 
                        fingerprint: TrustPolicyManager.Certificate.Fingerprint.debug
                    )
                ]
            )
        
        let debugTransport: HTTPTransport = HTTPTransport(security: debugSecurity)
        let debugRequest:   HTTPRequest   = HTTPRequest(endpoint: "https://gist.github.com/chedabob/64a4cdc4a1194d815814")
        
        debugTransport.send(request: debugRequest) { (result: HTTPTransport.Result) in
            print(result)
        }
    }
    
    class CookieStorage: CookieStoring, CookieProviding {

        func store(cookies: [HTTPCookie]) {
            cookies.forEach { (cookie: HTTPCookie) in
                print("RECEIVED COOKIES:")
                print(cookie.name + " = " + cookie.value)
            }
        }
        
        func getStoredCookies() -> [HTTPCookie] {
            return [
                HTTPCookie(name: "default_token", value: "abcdef")
            ]
        }
        
    }

}

