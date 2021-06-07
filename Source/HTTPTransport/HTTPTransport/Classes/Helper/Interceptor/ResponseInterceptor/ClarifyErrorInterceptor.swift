//
//  ClarifyErrorInterceptor
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2017 RedMadRobot LLC. All rights reserved.
//


import Foundation


/**
 If error is received, try to fetch code and message from body data.
 */
open class ClarifyErrorInterceptor: HTTPResponseInterceptor {

    /**
     Possible error code JSON keys.
     */
    let errorCodeKeys: [String]
    
    /**
     Possible error message JSON keys.
     */
    let errorMessageKeys: [String]
    
    public init(
        errorCodeKeys: [String] = ["code", "error_code"],
        errorMessageKeys: [String] = ["message", "error_message"]
    ) {
        self.errorCodeKeys = errorCodeKeys
        self.errorMessageKeys = errorMessageKeys
    }
    
    open override func intercept(
        response: HTTPResponseInterceptor.RawResponse
    ) -> HTTPResponseInterceptor.RawResponse {
        guard
            let receivedError = response.error,
            let httpStatusCode = HTTPStatusCode(httpURLResponse: response.response)
        else { return response }

        let error: NSError = receivedError as NSError

        var newUserInfo: [String: Any] = error.userInfo
        newUserInfo[NSError.UserInfoKey.httpStatus] = httpStatusCode

        if let data: Data = response.data {
            newUserInfo[NSError.UserInfoKey.responseBodyData] = data

            if let dataString: String = String(data: data, encoding: String.Encoding.utf8) {
                newUserInfo[NSError.UserInfoKey.responseBodyString] = dataString
            }

            do {
                let dataJSON: Any = try JSONSerialization.jsonObject(
                    with: data,
                    options: JSONSerialization.ReadingOptions.allowFragments
                )
                newUserInfo[NSError.UserInfoKey.responseBodyJSON] = dataJSON

                if let dataJSONDictionary: [String: Any] = dataJSON as? [String: Any] {
                    // { "code": 123, "message": "Error" }
                    if let errorCode: String = self.getErrorCode(fromDictionary: dataJSONDictionary) {
                        newUserInfo[NSError.UserInfoKey.responseBodyErrorCode] = errorCode
                    }

                    if let errorMessage: String = self.getErrorMessage(fromDictionary: dataJSONDictionary) {
                        newUserInfo[NSError.UserInfoKey.responseBodyErrorMessage] = errorMessage
                    }

                    if let errorObject: [String: Any] = dataJSONDictionary["error"] as? [String: Any] {
                        // { "error": { "code": 123, "message": "Error" } }
                        if let errorCode: String = self.getErrorCode(fromDictionary: errorObject) {
                            newUserInfo[NSError.UserInfoKey.responseBodyErrorCode] = errorCode
                        }

                        if let errorMessage: String = self.getErrorMessage(fromDictionary: errorObject) {
                            newUserInfo[NSError.UserInfoKey.responseBodyErrorMessage] = errorMessage
                        }
                    }
                }
            } catch {
                // mute errors
            }
        }

        let newError: NSError = NSError(
            domain: NSError.transportDomain,
            code: error.code,
            userInfo: newUserInfo
        )

        return RawResponse(request: response.request, response: response.response, data: response.data, error: newError)
    }

}


private extension ClarifyErrorInterceptor {

    func getErrorCode(fromDictionary dictionary: [String: Any]) -> String? {
        return getString(
            fromDictionary: dictionary,
            possibleKeys: errorCodeKeys
        )
    }

    func getErrorMessage(fromDictionary dictionary: [String: Any]) -> String? {
        return getString(
            fromDictionary: dictionary,
            possibleKeys: errorMessageKeys
        )
    }

    func getString(fromDictionary dictionary: [String: Any], possibleKeys: [String]) -> String? {
        for key in possibleKeys {
            if let any: Any = dictionary[key] {
                return makeString(any)
            }
        }
        return nil
    }

    func makeString(_ any: Any) -> String {
        return String(describing: any)
    }

}
