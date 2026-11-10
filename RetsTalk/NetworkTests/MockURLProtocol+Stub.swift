//
//  MockURLProtocol+Stub.swift
//  NetworkTests
//
//  Created on 11/10/26.
//

import XCTest

extension MockURLProtocol {
    static func stubSession() -> URLSession {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: sessionConfiguration)
    }
    
    static func stubResponse(
        for request: URLRequest,
        statusCode: Int,
        body: String
    ) throws -> (HTTPURLResponse, Data) {
        let url = try XCTUnwrap(request.url)
        let response = try XCTUnwrap(
            HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        )
        return (response, Data(body.utf8))
    }
}

extension URLRequest {
    var bodyData: Data? {
        if let httpBody { return httpBody }
        guard let httpBodyStream else { return nil }
        
        httpBodyStream.open()
        defer { httpBodyStream.close() }
        
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while httpBodyStream.hasBytesAvailable {
            let readCount = httpBodyStream.read(&buffer, maxLength: buffer.count)
            guard 0 < readCount else { break }
            
            data.append(buffer, count: readCount)
        }
        return data
    }
}

struct RequestedChat: Decodable {
    let messages: [RequestedMessage]
    
    struct RequestedMessage: Decodable {
        let role: String
        let content: String
    }
}
