import Alamofire

public final class CustomDataResponseSerializerProtocol<Value>: DataResponseSerializerProtocol {
    
    public typealias SerializedObject = Value
    
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) throws -> Value
    
    public init(serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, Data?, Error?) throws -> Value) {
        self.serializeResponse = serializeResponse
    }
    
    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Value {
        try serializeResponse(request, response, data, error)
    }
    
}
