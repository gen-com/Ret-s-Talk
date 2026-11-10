//
//  MainActorTaskQueue.swift
//  RetsTalk
//
//  Created on 3/15/25.
//

@MainActor
final class MainActorTaskQueue {
    
    // MARK: Typealias
    
    typealias MainActorAsyncClosure = @MainActor () async -> Void
    
    // MARK: Serial Task Stream
    
    private let taskContinuation: AsyncStream<MainActorAsyncClosure>.Continuation
    
    // MARK: Initializaion
    
    init() {
        let (taskStream, taskContinuation) = AsyncStream.makeStream(of: MainActorAsyncClosure.self)
        self.taskContinuation = taskContinuation
        
        Task {
            for await task in taskStream {
                await task()
            }
        }
    }
    
    deinit {
        taskContinuation.finish()
    }
    
    // MARK: Enqueue
    
    func enqueue(_ task: @escaping MainActorAsyncClosure) {
        taskContinuation.yield(task)
    }
}
