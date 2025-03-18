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
    
    // MARK: Initializaion
    
    init() {
        processTasks()
    }
    
    // MARK: Serial Task Stream
    
    private var taskHandler: ((@escaping MainActorAsyncClosure) -> Void)?
    
    private var taskStream: AsyncStream<MainActorAsyncClosure> {
        AsyncStream<MainActorAsyncClosure> { contiuation in
            taskHandler = { task in
                contiuation.yield(task)
            }
        }
    }
    
    private func processTasks() {
        Task {
            for await task in taskStream {
                await task()
            }
        }
    }
    
    // MARK: Enqueue
    
    func enqueue(_ task: @escaping MainActorAsyncClosure) {
        guard let taskHandler else { return }
        
        taskHandler(task)
    }
}
