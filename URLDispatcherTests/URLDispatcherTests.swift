//
//  URLDispatcherTests.swift
//  URLDispatcherTests
//
//  Created by 林 達也 on 2014/12/03.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

import UIKit
import XCTest


class MockViewController: UIViewController {
    var presented: UIViewController?
    
    override var presentedViewController: UIViewController? {
        return self.presented
    }
    
    override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: NSBundle? = nil) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MockNavigationController: UINavigationController {
    var presented: UIViewController?
    
    override var presentedViewController: UIViewController? {
        return self.presented
    }
}

class URLDispatcherTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_treeの構造確認_その１() {
        /**
        * nav
        * │├── vc1
        * │├── vc2
        * │└── vc3
        * └── vc4
        **/
        
        
        let vc4 = UIViewController()
        let vc3 = UIViewController()
        let vc2 = UIViewController()
        let vc1 = UIViewController()
        let nav = MockNavigationController()
        nav.viewControllers = [vc1, vc2, vc3]
        
        nav.presented = vc4
        
        
        let window = UIWindow()
        window.rootViewController = nav
        
        
        URLDispatchRouter.startup(window: window, optionalTraverseViewController: nil)
        
        var stack: [UIViewController] = []
        
        XCTAssertNotNil(nav.presentedViewController, "")
        XCTAssertEqual(nav.visibleViewController, vc4, "")
        
        wait { done in
            
            
            async_after(0.1, { () -> Void in
                stack = dispatched_treeViewController(router: nil)
                
                done()
            })
            
            return {
                XCTAssertEqual(stack.count, 2, "")
                XCTAssertEqual(stack.first!, nav, "")
                XCTAssertEqual(stack.last!, vc4, "")
            }
        }
    }
    func test_treeの構造確認_その２() {
        /**
        * nav
        * ├── vc1
        * ├── vc2
        * └── vc3
        *     └── vc4
        **/
        
        
        let vc4 = UIViewController()
        let vc3 = MockViewController()
        let vc2 = UIViewController()
        let vc1 = UIViewController()
        let nav = UINavigationController()
        nav.viewControllers = [vc1, vc2, vc3]
        
        vc3.presented = vc4
        
        
        let window = UIWindow()
        window.rootViewController = nav
        
        
        URLDispatchRouter.startup(window: window, optionalTraverseViewController: nil)
        
        var stack: [UIViewController] = []
        
        XCTAssertNotNil(vc3.presentedViewController, "")
        
        wait { done in
            
            
            async_after(0.1, { () -> Void in
                stack = dispatched_treeViewController(router: nil)
                
                done()
            })
            
            return {
                XCTAssertEqual(stack.count, 5, "")
                XCTAssertEqual(stack.first!, nav, "")
                XCTAssertEqual(stack.last!, vc4, "")
                
                println(stack)
            }
        }
    }
    
}



let when = { sec in dispatch_time(DISPATCH_TIME_NOW, Int64(sec * Double(NSEC_PER_SEC))) }

func async_after(_ time: NSTimeInterval = 0.5, block: () -> Void) {
    
    dispatch_after(when(time), dispatch_get_main_queue(), block)
}

extension XCTestCase {
    
    typealias DoneStatement = () -> Void
    func wait(till num: Int = 1, message: String = __FUNCTION__, _ block: DoneStatement -> DoneStatement) {
        self.wait(till: num, message: message, timeout: 1, block)
        
    }
    func wait(till num: Int, message: String = __FUNCTION__, timeout: NSTimeInterval, _ block: DoneStatement -> DoneStatement) {
        
        let expectation = self.expectationWithDescription(message)
        let queue = dispatch_queue_create("XCTestCase.wait", nil)
        var living = num
        
        var completion: (() -> Void)!
        let done: DoneStatement = {
            dispatch_async(queue) { //シングルキューで必ず順番に処理する
                living--
                if living == 0 {
                    completion?()
                    expectation.fulfill()
                }
            }
        }
        
        completion = block(done)
        
        self.waitForExpectationsWithTimeout(timeout) { (error) -> Void in
            completion?()
            return
        }
    }
}
