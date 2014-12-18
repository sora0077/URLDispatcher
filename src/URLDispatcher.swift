//
//  URLDispatcher.swift
//  URLDispatcher
//
//  Created by 林 達也 on 2014/12/03.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

import Foundation
import UIKit
import JavaScriptCore

public typealias URLDispatchEntry = _URLDispatch.Entry
public typealias URLDispatchRouter = _URLDispatch.Router
public typealias URLDispatchClient = _URLDispatch.Client
public typealias URLDispatchRequest = _URLDispatch.Request

public func URLDispatcher() -> URLDispatchRouter {
    return URLDispatchRouter.Static.instance
}

public func URLDispatcher(#scheme: String) -> URLDispatchRouter {
    return URLDispatchRouter.scheme(scheme)
}

/**
*
*/
@objc
public protocol URLDispatched {

}

@objc
public protocol URLViewDispatched: URLDispatched {

    func dispatchEvent(fromViewController from: UIViewController, completion: () -> Void)
}

@objc
public protocol URLEventDispatched: URLDispatched {

    func dispatchEvent(completion: () -> Void)
}


public struct _URLDispatch {
    private static let PATTERN_PREFIX: Character = ":"
    private static let CALLBACK_KEY: String = "z-callback"

    public enum Entry {
        case Immediate(URLDispatched)
        case Future((done: (Entry) -> Void) -> Void)
        case None
    }

    public struct Request {

        private let client: Client
        private let node: Router.Node   //future use

        public let options: [String: String]?

        private init() {
            fatalError("")
        }

        private init(client: Client, options: [String: String]?, node: Router.Node) {
            self.client = client
            self.options = options
            self.node = node
        }
    }

    public class Client {

        public let url: NSURL

        private let callback: Client?

        private var generator: GeneratorOf<Router.PatternMatcher>?
        private var first: Router.PatternMatcher?

        public init(url: NSURL, callback: NSURL?) {
            self.url = url
            if let c = callback {
                self.callback = Client(url: c)
            }
        }
    }

    public class Router {


        private var callbackKey: String = CALLBACK_KEY

        private var patterns: [Int: [Node]] = [:]

        private init() {}

    }
}

extension URLDispatchRequest {

    public var url: NSURL {
        return self.client.url
    }

    public var callbackURL: NSURL? {
        return self.client.callback?.url
    }
}

extension URLDispatchClient {

    public convenience init(url: NSURL) {
        let ret = URLDispatchClient.parseURLString(url.absoluteString!)
        self.init(url: ret.0, callback: ret.1)
    }

    public convenience init(string: String) {
        let ret = URLDispatchClient.parseURLString(string)
        self.init(url: ret.0, callback: ret.1)
    }

    public convenience init(string: String, callback: String) {
        self.init(url: NSURL(string: string)!, callback: NSURL(string: callback)!)
    }

    public var canOpen: Bool {

        if self.generator == nil {
            switch (self.url.scheme, path: self.url.path) {
            case let (.Some(host), .Some(path)):
                let r = URLDispatcher(scheme: host)
                self.generator = r.match(pattern: path)
            default:
                break
            }

            self.first = self.generator?.next()
        }

        return self.first != nil
    }

    public func open() {

        if self.canOpen {
            if var gen = self.generator {
                for (f, options, node) in gen {
                    let request = URLDispatchRequest(client: self, options: options, node: node)
                    self.dispatch(entry: f(request))
                }
            }
            if let (f, options, node) = self.first {
                let request = URLDispatchRequest(client: self, options: options, node: node)
                self.dispatch(entry: f(request), callback: true)
            }
            self.generator = nil
        }
    }
}

extension URLDispatchClient {

    //MARK: private
    private func dispatch(#entry: URLDispatchEntry, callback: Bool = false) {

        switch entry {
        case let .Immediate(dispatched):
            if let vc = dispatched as? URLViewDispatched {
                assert((vc as AnyObject as? UIViewController) != nil, "URLViewDispatched object expects UIViewController object")

                vc.dispatchEvent(fromViewController: URLDispatchRouter.presentingViewController, completion: {
                    if callback { self.callback?.open() }
                    return
                })
                let vc = vc as AnyObject as UIViewController
                URLDispatchRouter.presentingViewController = vc
            } else if let d = dispatched as? URLEventDispatched {
                d.dispatchEvent({
                    if callback { self.callback?.open() }
                    return
                })
            }
        case let .Future(block):
            block { (entry) -> Void in
                self.dispatch(entry: entry)
            }
        case .None:
            if callback { self.callback?.open() }
        }
    }
}

extension URLDispatchClient {

    //MARK: utility
    private class func parseURLString(string: String) -> (NSURL, NSURL?) {
        let components = NSURLComponents(string: string)!

        var callbackURL: NSURL?

        if let items = components.queryItems as? [NSURLQueryItem] {
            var queryItems = [NSURLQueryItem]()
            for item in items {
                if item.name == _URLDispatch.CALLBACK_KEY && item.value != nil {
                    callbackURL = NSURL(string: item.value!)
                } else {
                    queryItems.append(item)
                }
            }
            components.queryItems = queryItems
        }

        return (components.URL!, callbackURL)
    }
}

extension URLDispatchRouter {

    //MARK: definition
    private typealias DispatchProcess = (URLDispatchRequest) -> URLDispatchEntry
    private typealias PatternMatcher = (DispatchProcess, [String: String]?, Node)

    private struct Static {
        static weak var presentingViewController: UIViewController!
        static var routers: [String: URLDispatchRouter] = [:]
        static let instance: URLDispatchRouter = {
            let d = URLDispatchRouter.scheme("")
            return d
            }()
    }

    private enum Node {
        case Leaf(DispatchProcess)
        case Child(String, @autoclosure () -> Node)

        init(_ v: String,  _ node: Node) {
            let node = node
            self = .Child(v, node)
        }
    }

    private enum LookupResult {
        case Success(DispatchProcess)
        case Failure
    }
}


extension URLDispatchRouter {

    public func test(#pattern: String) -> Bool {

        for _ in self.match(pattern: pattern) {
            return true
        }
        return false
    }

    public func dispatch(#pattern: String, _ block: (request: URLDispatchRequest) -> URLDispatchEntry) {

        self.addPattern(pattern, block: block)
    }
}

extension URLDispatchRouter {

    //MARK: private
    private class func scheme(scheme: String) -> URLDispatchRouter {

        if let d = Static.routers[scheme] {
            return d
        }
        let d = URLDispatchRouter()
        Static.routers[scheme] = d
        return d

    }

    private class var presentingViewController: UIViewController {
        get {
            return Static.presentingViewController ?? UIApplication.sharedApplication().delegate?.window??.rootViewController
        }
        set {
            Static.presentingViewController = newValue
        }
    }

    private func addPattern(pattern: String, block: DispatchProcess) {

        assert(pattern[pattern.startIndex] == "/", "pattern not start with /")

        let components = split(pattern) { $0 == "/" }

        var node = Node.Leaf(block)
        for c in reverse(components) {
            node = Node(c, node)
        }

        if self.patterns[components.count] == nil {
            self.patterns[components.count] = []
        }

        self.patterns[components.count]!.append(node)
    }

    private func match(#pattern: String) -> GeneratorOf<PatternMatcher> {

        let components = split(pattern) { $0 == "/" }

        if var gen = self.patterns[components.count]?.generate() {
            return GeneratorOf<PatternMatcher> {
                while let n = gen.next() {
                    var options: [String: String]?
                    switch self.lookupNode(n, target: components, options: &options) {
                    case let .Success(block):
                        return (block, options, n)
                    case .Failure:
                        break
                    }
                }
                return .None
            }
        } else {
            return GeneratorOf<PatternMatcher> {
                return .None
            }
        }
    }

    private func lookupNode(node: Node, target: [String], inout options: [String: String]?, level: Int = 0) -> LookupResult {

        switch node {
        case let .Child(c, n):
            if target.count <= level {
                return .Failure
            }
            if c[c.startIndex] == _URLDispatch.PATTERN_PREFIX {
                if options == nil { options = [:] }
                options?[c[advance(c.startIndex, 1)..<c.endIndex]] = target[level]
                return self.lookupNode(n(), target: target, options: &options, level: level + 1)
            }
            if c == target[level] {
                return self.lookupNode(n(), target: target, options: &options, level: level + 1)
            }
        case let .Leaf(block):
            return .Success(block)
        }
        return .Failure
    }

}

extension URLDispatchRouter.Node: DebugPrintable {

    var debugDescription: String {
        switch self {
        case .Leaf:
            return "(Leaf)"
        case let .Child(k, n):
            return k + " -> " + n().debugDescription
        }
    }
}
