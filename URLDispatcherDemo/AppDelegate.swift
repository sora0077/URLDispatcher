//
//  AppDelegate.swift
//  URLDispatcherDemo
//
//  Created by 林 達也 on 2014/12/03.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

import UIKit
import URLDispatcher

extension UIViewController: URLViewDispatched {

    public func dispatchEvent(fromViewController from: UIViewController, completion: () -> Void) {

    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        URLDispatcher(scheme: "app").dispatch(pattern: "/:users/:test/:view") { (request) -> URLDispatchEntry in

            println((request.url, request.options))
            return .None
        }
        URLDispatcher(scheme: "app").dispatch(pattern: "/users/test/:view") { (request) -> URLDispatchEntry in

            println((request.url, request.options))
            return .None
        }
        URLDispatcher(scheme: "app").dispatch(pattern: "/users/view/test") { (request) -> URLDispatchEntry in

            println((request.url, request.options))
            return .None
        }
        URLDispatcher(scheme: "app").dispatch(pattern: "/") { (request) -> URLDispatchEntry in

            println((request.url, request.options))
            return .Future({ (done) in

                done(.None)
                
            })
        }

        let c = URLDispatchClient(string: "app:///users/test/4444?z-callback=app%3a%2f%2f%2fusers%2ftest%2f6666%3fz%2dcallback%3dapp%253a%252f%252f%252fusers%252ftest%252f8888&param=22")
//        let c = URLDispatchClient(string: "aaa:///")
        c.open()
//        c.open()

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

