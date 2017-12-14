# HTTPTransport
## Description

This library is an Alamofire wrapper allowing synchronous HTTP requests.

Basically, instead of using callbacks like this:

```swift
Alamofire.request(someRequest).response { reponse in
    if response ...
}
```

**HTTPTransport** allows you to use a regular flow of control like this:

```swift
let result = transport.send(someRequest)

if result ...
```

> **N.B.:** Library authors assume that you know your onions when it comes to build a mobile app, and leave the discussion about
multithreading and synchronous networking drawbacks behind brackets.

# Usage

* [Installation: CocoaPods](#pods)
* [Main actors](#actors)
* [Cook book](#book)
* [Evolution](#evolution)

<a name="pods" />

## Installation: CocoaPods

```ruby
pod 'HTTPTransport', :git => 'git@github.com:RedMadRobot/http-transport.git'
```

<a name="actors" />

## Main actors

* [HTTPTransport](#transport)
* [HTTPRequest](#httprequest)
* [HTTPTransport.Result](#result)
* [HTTPRequestParameters](#parameters)
* [Session](#session)
* [Interceptors](#interceptors)
* [NSError](#nserror)

Fundamental concept of the library is pretty straightforward: you have a **request** to send over a **transport** in order to
receive some **result** — these are three main actors you are going to deal with.

<a name="transport" />

### HTTPTransport

Beside making actual HTTP calls, an `HTTPTransport` instance holds non-functional requirements to your connection, like
keeping alive an established HTTP session, applied security measures, and default request and response processing stacks,
including error processing.

```swift
class HTTPTransport {
    let session:              Session
    let requestInterceptors:  [HTTPRequestInterceptor]
    let responseInterceptors: [HTTPResponseInterceptor]
}
```

Read about [Session](#session) and [interceptors](#interceptors) below.

<a name="httprequest" />

### HTTPRequest

A Swiss army knife multitool to satisfy all your needs when you are up to construct an HTTP request.

```swift
class HTTPRequest {
    let httpMethod:           HTTPMethod
    let endpoint:             String
    var headers:              [String: String]
    var parameters:           [HTTPRequestParameters]
    var requestInterceptors:  [HTTPRequestInterceptor]
    var responseInterceptors: [HTTPResponseInterceptor]
    let session:              Session?
    let timeout:              TimeInterval
}
```

Works mostly as you would expect it to. First of all, it is a container object for an HTTP request envelope fields, including
an `HTTPMethod`, an `endpoint` (URL or its part), request headers and request body.

Second, each `HTTPRequest` instance specifies its own timeout interval, a custom [`Session`](#session) (if needed), and two sets of
[Interceptors](#interceptors) to be applied to this particular request and its response. Most of these options have their default values,
so they won't bother you much.

`HTTPRequest` class provides several ways to modify its contents, including an intelligent constructor, which allows to make
`HTTPRequest` instances based on other `HTTPRequest` instances, see Cook book's [Basic dependent requests](#dependent).

```swift
class HTTPRequest {
    func with(header: String, value: String) -> Self
    func with(cookieName name: String, value: String) -> Self
    func with(cookie: HTTPCookie) -> Self
    func with(parameter: String, value: Any, encoding: HTTPRequestParameters.Encoding) -> Self
    func with(parameters: [String: Any], encoding: HTTPRequestParameters.Encoding) -> Self
    func with(parameters: HTTPRequestParameters) -> Self
    func with(parameters: [HTTPRequestParameters]) -> Self
    func with(interceptors: [HTTPRequestInterceptor]) -> Self
    func with(interceptors: [HTTPResponseInterceptor]) -> Self
}


let userSearchRequest =
    HTTPRequest(endpoint: "/user")
        .with(cookieName: "SESSION_ID", value: sessionId)
        .with(parameters: ["first_name": "John", "last_name": "Appleseed"], encoding: .url)
```

Request parameters are represented with a separate container class [`HTTPRequestParameters`](#parameters),
allowing each `HTTPRequest` to include a few sets of parameters encoded differently.

There are two children that extend `HTTPRequest`: `DataUploadHTTPRequest` and `FileUploadHTTPRequest`. Both are pretty much
self-explanatory; they serve to upload `Data` and files respectively.

<a name="result" />

### HTTPTransport.Result

The third main actor, representing the outcome of an HTTP call. Either a `.success` or a `.failure`:

```swift
enum Result {
    case success(response: HTTPResponse)
    case failure(error: NSError)
}
```

The main idea you need to know is that the definition of **successful** HTTP call or **failed** HTTP call varies depending on the
validation techniques you apply.

By default, Alamofire's `validate()` method is called (see `HTTPTransport.useDefaultValidation` property), which means only
the responses with a `2xx` status are considered successful, otherwise they are translated into an error.
Disabling `useDefaultValidation` will lead to success in cases when there was *any* kind of a response from the server,
no matter what the answer was, and fail in cases like when the Internet connection is down.

On the low level, responses are influenced by the set of [response interceptors](#interceptors), which are applied before the
Alamofire's validation. This is why you might consider putting a `ClarifyErrorInterceptor` into your transport response
interceptors' stack, as it enriches the resulting [`NSError` object](#nserror).

<a name="parameters" />

### HTTPRequestParameters

Essentially, a dictionary with an additional property of how this dictionary is going to be encoded.

```swift
class HTTPRequestParameters {
    var parameters: [String: Any]
    let encoding:   Encoding

    subscript(parameterName: String) -> Any? { get set }

    enum Encoding {
        case json
        case url
        case propertyList
        case custom(encode: EncodeFunction)
    }
}
```

`json` and `propertyList` are encoded into the body, `url` parameters go into the query string.

Your `HTTPRequest` may contain several sets of `HTTPRequestParameters`:

```swift
class HTTPRequest {
    var parameters: [HTTPRequestParameters]
}


let request =
    HTTPRequest(
        parameters: [
            HTTPRequestParameters(parameters: ["name": "John"], encoding: .json),
            HTTPRequestParameters(parameters: ["dob": "12/12/12"], encoding: .json),
            HTTPRequestParameters(parameters: ["age": 5], encoding: .url),
        ]
    )
```

The rules here:

* parameters with the same encoding are merged into a single dictionary;
* parameters with the same encoding and same keys override previous values in the merged dictionary;
* parameters are appended after the `base` request parameters with the same encoding;
* parameters override `base` parameters with the same encoding and same keys;
* `propertyList` parameters and `json` parameters do not mix in one body, they overwrite each other; last-in wins;
* `FileUploadHTTPRequest` requests ignore `json` parameters; `propertyList` parameters are appended after the file multipart;
* `DataUploadHTTPRequest` requests ignore both `propertyList` and `json` parameters.

<a name="session" />

### Session

Session object holds Alamofire's [`SessionManager`](https://github.com/Alamofire/Alamofire/blob/master/Documentation/AdvancedUsage.md#session-manager)
and provides convenient way to configure connection security with the `Security` object.

```swift
class Session {
    let manager: SessionManager

    convenience init()
    init(security: Security)
}
```

`Security` object allows to check hosts against certificate fingerprints:

```swift
class Security {
    class var noEvaluation: Security

    init(certificates: [Certificate])
}


struct Certificate {
    let host:        String
    let fingerprint: Fingerprint
    
    enum Fingerprint {
        case sha1(fingerprint: String)
        case sha256(fingerprint: String)
        case publicKey(fingerprint: String)
        case debug
        case disable
    }
}
```

Host names are checked by the string intersection. This means `Certificate(host: "host.com", fingerprint:...)` is applied
for URLs like `https://www.host.com/query`, `https://host.com`, `https://api.host.com/v1` et al.

<a name="interceptors" />

### Interceptors

`HTTPRequestInterceptor` and `HTTPResponseInterceptor` are abstract middleware classes, inspired by
[OkHTTP interceptors](https://github.com/square/okhttp/wiki/Interceptors),
[Django middlewares](https://docs.djangoproject.com/en/2.0/topics/http/middleware/) et al. Interceptors alter input and output,
each `HTTPTransport` instance contains two lists of request and reponse interceptors subsequently applied to every request and
response respectively.

In other words, when your **app** sends a **request** through the **transport**, latter passes this **request** through its list of
**request interceptors** before the actual sending. After the **response** is received, **transport** passes it through the list of
**response interceptors** before transfering it to your **app**.

```swift
class HTTPRequestInterceptor {
    func intercept(request: URLRequest) -> URLRequest
}


class HTTPResponseInterceptor {
    func intercept(response: RawResponse) -> RawResponse

    struct RawResponse {
        let request:  URLRequest?
        let response: HTTPURLResponse?
        let data:     Data?
        let error:    Error?
    }
}
```

Interceptors may or may not alter the data they process. For instance, one of your request interceptors may add an
`Authentication` header to every request. Other request interceptor might only print request data into the console log.

You implement your own interceptors by extending the classes mentioned above. **HTTPTransport** library already includes some
basic utility interceptors, like:

* `LogRequestInterceptor` and `LogResponseInterceptor` — allow you to log requests and responses;
* `AddCookieInterceptor` — adds cookies from `cookieProvider` to each request;
* `ReceivedCookieInterceptor` — stores received cookies to `cookieStorage`;
* `ClarifyErrorInterceptor` — translates JSON payloads with API errors like `{"code": 500, "message": "Database error"}` into `NSError` instances, [see below](#nserror).

<a name="nserror" />

### NSError

**HTTPTransport** provides an extension for the existing `NSError` class with some utility properties with additional parts
of the received HTTP response, if any.

Most of them will only work if the `ClarifyErrorInterceptor` was engaged.

```swift
extension NSError {
    var url: String? // contains URL when HTTPRequest have failed to serialize into URLRequest

    var httpStatusCode:             HTTPStatusCode? // HTTP status
    
    var responseBodyData:           Data?           // received bytes
    var responseBodyString:         String?         // received bytes as UTF8 string
    var responseBodyJSON:           Any?            // received bytes as a JSON object
    var responseBodyJSONDictionary: [String: Any]?  // received JSON object casted to dictionary
    
    var responseBodyErrorCode:      String?         // parsed error code from received JSON
    var responseBodyErrorMessage:   String?         // parsed error message from received JSON
}
```

<a name="book" />

## Cook book

* [Basic GET request](#basic)
* [Basic dependent requests](#dependent)
* [Logging](#logging)
* [Send and receive cookies](#cookies)
* [POST request with body & URL parameters](#post_parameters)
* [SSL pinning with SHA1 fingerprint](#sha1_fingerprint)

<a name="basic" />

### Basic GET request

```swift
// assuming all following code runs in a background thread

let request   = HTTPRequest(endpoint: "https://api.service.com")
let transport = HTTPTransport()

let result: HTTPTransport.Result = transport.send(request: request)

switch result {
    case .success(let httpResponse):
        print(httpResponse.httpStatus)
        do {
            if let json: [String: Any] = try httpResponse.getJSONDictionary() {
                print(json)
            }
        } catch {
            print("JSONSerialization error")
        }
    case .failure(let nsError):
        if let httpStatus: HTTPStatusCode = nsError.httpStatusCode {
            print(httpStatus)
        } else {
            print(nsError.localizedDescription)
        }
}
```

<a name="dependent" />

### Basic dependent requests

```swift
// assuming all following code runs in a background thread

let transport = HTTPTransport()

let baseRequest =
    HTTPRequest(endpoint: "https://api.service.com")
        .with(header: "User-Agent", value: "Application/iOS")

let authRequest = HTTPRequest(endpoint: "/session", base: baseRequest)
let authResult  = transport.send(request: authRequest)

if let sessionId: String = getSessionId(authResult) {
    let userSearchRequest =
        HTTPRequest(endpoint: "/user", base: baseRequest)
            .with(cookieName: "SESSION_ID", value: sessionId)
            .with(parameters: ["first_name": "John", "last_name": "Appleseed"], encoding: .url)
    
    let searchResult = transport.send(request: userSearchRequest)
    if let users: [User] = getUsers(searchResult) {
        showUsers(users)
    } else {
        showEmptyScreen()
    }
} else {
    showError()
}
```

<a name="logging" />

### Logging

```swift
let transport = HTTPTransport(
    requestInterceptors: [
        LogRequestInterceptor(logLevel: LogRequestInterceptor.LogLevel.url),
    ],
    responseInterceptors: [
        LogResponseInterceptor(logLevel: LogResponseInterceptor.LogLevel.everything),
    ]
)

let result = transport.send(...)
```

<a name="cookies" />

### Send and receive cookies

```swift
let cookieStorage: CookieStoring & CookieProviding = getCookieStorage()

let transport = HTTPTransport(
    requestInterceptors: [
        AddCookieInterceptor(cookieProvider: cookieStorage),
    ],
    responseInterceptors: [
        ReceivedCookieInterceptor(cookieStorage: cookieStorage),
    ]
)

let result = transport.send(...)
```

<a name="post_parameters" />

### POST request with body & URL parameters

```swift
let urlParameters = HTTPRequestParameters(
    parameters: ["first_name" : "John"],
    encoding: .url
)

let bodyParameters = HTTPRequestParameters(
    parameters: ["salary" : 100000],
    encoding: .json
)

let updateSalaryRequest = HTTPRequest(
    httpMethod: HTTPRequest.HTTPMethod.post,
    endpoint: "https://api.company.com/employees",
    parameters: [urlParameters, bodyParameters]
)

let result = transport.send(request: updateSalaryRequest)
```

<a name="sha1_fingerprint" />

### SSL pinning with SHA1 fingerprint

```swift
let fingerprint =
    "ED D6 27 B8 8B 51 B0 24 B9 BF 90 4C D4 AB 9A AB E2 4B 93 00"
        .replacingOccurrences(of: " ", with: "")

let security = Security(
    certificates: [
        TrustPolicyManager.Certificate(host: "google.com", fingerprint: .sha1(fingerprint: fingerprint))
    ]
)

let transport = HTTPTransport(security: security)
let result = transport.send(request: HTTPRequest(endpoint: "https://google.com/ncr"))
```

<a name="evolution" />

## Evolution

You may have noticed that our library tries not to expose Alamofire interfaces. There is a simple idea to get rid of this transitive
dependency, and to erect an independent logic on top of the **URLSession** framework.

These far-reaching plans require significant efforts we cannot afford right now. Still, it is a major target we aspire to hit eventually.

So, pull requests are welcome, but consider creating a tentative issue before the actual coding.
