//
//  Observable+RepeatWhenTests.swift
//  Tests
//
//  Created by sergdort on 16/05/2017.
//  Copyright © 2017 Krunoslav Zaher. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class ObservableRepeatWhenTests: RxTest {
    
    func testRepeatWhen_never() {
        let scheduler = TestScheduler(initialClock: 0)
        
        let xs = scheduler.createHotObservable([
            Recorded.next(150, 1),
            Recorded.completed(250)
        ])
        
        let ys = scheduler.createColdObservable([
            Recorded.completed(1, Int.self)
        ])
        
        let results = scheduler.start {
            return xs.repeatWhen { _ in
                return ys
            }
        }
        
        XCTAssertEqual(results.events, [
            Recorded.completed(250)
        ])
        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 250)
        ])
        XCTAssertEqual(ys.subscriptions, [
            Subscription(200, 201)
        ])
    }
    
    func testRepeatWhen_Observable_Never() {
        let scheduler = TestScheduler(initialClock: 0)
        
        let xs = scheduler.createHotObservable([
            Recorded.next(150, 1),
            Recorded.next(210, 2),
            Recorded.next(220, 3),
            Recorded.next(230, 4),
            Recorded.next(240, 5),
            Recorded.completed(250)
        ])
        
        let ys: TestableObservable<Int> = scheduler.createColdObservable([])
        
        let results = scheduler.start {
            return xs.repeatWhen { _ in
                return ys
            }
        }
        
        XCTAssertEqual(results.events, [
            Recorded.next(210, 2),
            Recorded.next(220, 3),
            Recorded.next(230, 4),
            Recorded.next(240, 5)
        ])
        
        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 250)
        ])
        
        XCTAssertEqual(ys.subscriptions, [
            Subscription(200, 1000)
        ])
    }
    
    func testRepeatObservable_Empty() {
        let scheduler = TestScheduler(initialClock: 0)
        
        let xs = scheduler.createColdObservable([
            Recorded.next(100, 1),
            Recorded.next(150, 2),
            Recorded.next(200, 3),
            Recorded.completed(250)
            ])
        
        let ys = scheduler.createColdObservable([
            Recorded.completed(1, Int.self)
        ])
        
        let results = scheduler.start {
            return xs.repeatWhen { _ in
                return ys
            }
        }
        
        XCTAssertEqual(results.events, [
            Recorded.next(300, 1),
            Recorded.next(350, 2),
            Recorded.next(400, 3),
            Recorded.completed(450)
        ])
        
        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 450)
        ])
    }
    
    func testRepeatWhenObservable_NextError() {
        let scheduler = TestScheduler(initialClock: 0)
        
        let xs = scheduler.createColdObservable([
            Recorded.next(10, 1),
            Recorded.next(20, 2),
            Recorded.error(30, testError),
            Recorded.completed(40)
        ])
        
        let results = scheduler.start {
            return xs.repeatWhen { notifications in
                return notifications.scan(0, accumulator: { (count, _) in
                    if count == 2 {
                        throw testError
                    }
                    return count + 1
                })
            }
        }
        
        XCTAssertEqual(results.events, [
            Recorded.next(210, 1),
            Recorded.next(220, 2),
            Recorded.error(230, testError)
        ])
        
        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 230)
        ])
    }
    
    func testRepeatWhenObservable_Complete() {
        let scheduler = TestScheduler(initialClock: 0)
        
        let xs = scheduler.createColdObservable([
            Recorded.next(10, 1),
            Recorded.next(20, 2),
            Recorded.completed(30)
        ])
        
        let ys = scheduler.createColdObservable([
            Recorded.completed(0, Int.self)
        ])
        
        let results = scheduler.start {
            return xs.repeatWhen { _ in
                return ys
            }
        }

        XCTAssertEqual(results.events, [
            Recorded.next(210, 1),
            Recorded.next(220, 2),
            Recorded.completed(230)
        ])
        
        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 230)
        ])
        
        XCTAssertEqual(ys.subscriptions, [
            Subscription(200, 200)
        ])
    }
    
    func testRepeatWhenNextComplete() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createColdObservable([
            Recorded.next(10, 1),
            Recorded.next(20, 2),
            Recorded.completed(30)
        ])

        let results = scheduler.start {
            return xs.repeatWhen { notifications in
                return notifications.scan(0) { (count, _) in
                    return count + 1
                }.takeWhile { count in
                    return count < 2
                }
            }
        }

        XCTAssertEqual(results.events, [
            Recorded.next(210, 1),
            Recorded.next(220, 2),
            Recorded.next(240, 1),
            Recorded.next(250, 2),
            Recorded.completed(260)
        ])

        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 230),
            Subscription(230, 260)
        ])
    }
    
    func testRepeatWhenInfinite() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createColdObservable([
            Recorded.next(10, 1),
            Recorded.next(20, 2),
            Recorded.completed(30)
        ])

        let ys: TestableObservable<Int> = scheduler.createColdObservable([])

        let results = scheduler.start {
            return xs.repeatWhen { _ in
                return ys
            }
        }

        XCTAssertEqual(results.events, [
            Recorded.next(210, 1),
            Recorded.next(220, 2)
        ])

        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 230)
        ])
    }
    
    #if TRACE_RESOURCES
    func testRepeatWhen1ReleasesResourcesOnComplete() {
        _ = Observable<Int>.just(1).repeatWhen { _ in Observable.just(1) }.subscribe()
    }
    
    func testRepeatWhen1ReleasesResourcesOnError() {
        _ = Observable<Int>.error(testError).repeatWhen { _ in Observable.just(1) }.subscribe()
    }
    
    func testRepeatWhen3ReleasesResourcesOnError() {
        _ = Observable<Int>.just(1).repeatWhen { e in
            return Observable<Int>.error(testError)
        }.subscribe()
    }
    #endif
}
