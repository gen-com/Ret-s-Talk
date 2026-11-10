//
//  StreamRecorder.swift
//  RetsTalkTests
//
//  Created on 11/10/26.
//

@MainActor
final class StreamRecorder<Element: Sendable> {
    private(set) var elements = [Element]()
    
    init(_ stream: AsyncStream<Element>) {
        Task { [weak self] in
            for await element in stream {
                self?.elements.append(element)
            }
        }
    }
}
