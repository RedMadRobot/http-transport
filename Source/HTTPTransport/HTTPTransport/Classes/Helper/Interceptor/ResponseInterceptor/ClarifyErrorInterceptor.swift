//
//  ClarifyErrorInterceptor
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - ClarifyErrorInterceptor

/// If error is received, try to fetch code and message from body data
open class ClarifyErrorInterceptor {

    // MARK: - Properties

    /// Possible error code JSON keys
    let errorCodeKeys: [String]
    
    /// Possible error message JSON keys
    let errorMessageKeys: [String]

    // MARK: - Initializers

    /// Default initializer
    /// - Parameters:
    ///   - errorCodeKeys: error code JSON keys
    ///   - errorMessageKeys: error message JSON keys
    public init(
        errorCodeKeys: [String] = ["code", "error_code"],
        errorMessageKeys: [String] = ["message", "error_message"]
    ) {
        self.errorCodeKeys = errorCodeKeys
        self.errorMessageKeys = errorMessageKeys
    }
}

// MARK: - HTTPResponseInterceptor

extension ClarifyErrorInterceptor: HTTPResponseInterceptor {
    
    open func intercept(response: RawResponse) -> RawResponse {
        guard
            let receivedError = response.error,
            let httpStatusCode = HTTPStatusCode(httpURLResponse: response.response)
        else { return response }
        let error = receivedError as NSError
        var newUserInfo = error.userInfo
        newUserInfo[NSError.UserInfoKey.httpStatus] = httpStatusCode
        if let data: Data = response.data {
            newUserInfo[NSError.UserInfoKey.responseBodyData] = data
            if let dataString = String(data: data, encoding: String.Encoding.utf8) {
                newUserInfo[NSError.UserInfoKey.responseBodyString] = dataString
            }
            do {
                let dataJSON = try JSONSerialization.jsonObject(
                    with: data,
                    options: JSONSerialization.ReadingOptions.allowFragments
                )
                newUserInfo[NSError.UserInfoKey.responseBodyJSON] = dataJSON
                if let dataJSONDictionary = dataJSON as? [String: Any] {
                    // { "code": 123, "message": "Error" }
                    if let errorCode = getErrorCode(fromDictionary: dataJSONDictionary) {
                        newUserInfo[NSError.UserInfoKey.responseBodyErrorCode] = errorCode
                    }
                    if let errorMessage = getErrorMessage(fromDictionary: dataJSONDictionary) {
                        newUserInfo[NSError.UserInfoKey.responseBodyErrorMessage] = errorMessage
                    }
                    if let errorObject = dataJSONDictionary["error"] as? [String: Any] {
                        // { "error": { "code": 123, "message": "Error" } }
                        if let errorCode = getErrorCode(fromDictionary: errorObject) {
                            newUserInfo[NSError.UserInfoKey.responseBodyErrorCode] = errorCode
                        }
                        if let errorMessage = getErrorMessage(fromDictionary: errorObject) {
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

// MARK: - Private

private extension ClarifyErrorInterceptor {

    func getErrorCode(fromDictionary dictionary: [String: Any]) -> String? {
        getString(fromDictionary: dictionary, possibleKeys: errorCodeKeys)
    }

    func getErrorMessage(fromDictionary dictionary: [String: Any]) -> String? {
        getString(fromDictionary: dictionary, possibleKeys: errorMessageKeys)
    }

    func getString(fromDictionary dictionary: [String: Any], possibleKeys: [String]) -> String? {
        for key in possibleKeys {
            if let any = dictionary[key] {
                return makeString(any)
            }
        }
        return nil
    }

    func makeString(_ any: Any) -> String {
        String(describing: any)
    }
}
