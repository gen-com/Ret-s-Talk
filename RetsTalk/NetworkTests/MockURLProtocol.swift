//
//  MockURLProtocol.swift
//  RetsTalk
//
//  Created on 11/5/24.
//

import os
import XCTest

final class MockURLProtocol: URLProtocol {
    typealias RequestHandler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    
    private static let requestHandlerLock = OSAllocatedUnfairLock<RequestHandler?>(initialState: nil)
    
    static var requestHandler: RequestHandler? {
        get { requestHandlerLock.withLock({ $0 }) }
        set { requestHandlerLock.withLock({ $0 = newValue }) }
    }
    
    override static func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler
        else {
            XCTFail("Received unexpected request with no handler set")
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}
