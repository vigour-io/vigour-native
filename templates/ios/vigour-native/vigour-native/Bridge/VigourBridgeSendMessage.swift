//
//  VigourBridgeJSMessage.swift
//  vigour-native
//
//  Created by Alexander van der Werff on 28/09/15.
//  Copyright © 2015 Vigour.io. All rights reserved.
//

import Foundation


//window.vigour.native.bridge.ready(err, response, pluginId)
internal let scriptMessageReadyCallbackTpl = "%@; window.vigour.native.bridge.ready(error, %@, '%@')"

//window.vigour.native.bridge.result(cbId, err, response)
internal let scriptMessageResultCallbackTpl = "%@; window.vigour.native.bridge.result(%d, error, %@)"

//window.vigour.native.bridge.receive(eventType, data, pluginId)
internal let scriptMessageReceiveCallbackTpl = "%@; window.vigour.native.bridge.receive('%@', %@, '%@')"

internal let scriptMessageTpl = "(function() { %@ }())"

protocol JSStringProtocol {
     func jsString() -> String
}

/**
    VigourBridgeSendMessage enum for sending different types to the bridge
 */
enum VigourBridgeSendMessage: JSStringProtocol {
    case Receive(error: JSError?, event: String, message: JSObject, pluginId: String?)
    case Result(error: JSError?, calbackId: Int, response: JSObject)
    case Ready(error: JSError?, response: JSObject, pluginId: String?)
    
    func jsString() -> String {
        var js = ""
        
        switch self {
        case .Ready(let error, let response, let pluginId):
            
            if let id = pluginId {
                js = String(format: scriptMessageReadyCallbackTpl, errorJSString(error), response.jsString(), id)
            }
            else {
                js = String(format: scriptMessageReadyCallbackTpl, errorJSString(error), response.jsString(), "")
            }
            
        case .Result(let error, let callbackId, let response):
            
            js = String(format: scriptMessageResultCallbackTpl, errorJSString(error), callbackId, response.jsString())
            
        case .Receive(let error, let event, let message, let pluginId):
            if let _ = error {
                js = String(format: scriptMessageReceiveCallbackTpl, errorJSString(error), event, "error", pluginId ?? "null")
            }
            else {
                js = String(format: scriptMessageReceiveCallbackTpl, errorJSString(error), event, message.jsString(), pluginId ?? "null")
            }
            
        }
        
        return String(format: scriptMessageTpl, js)
    }
    
    private func errorJSString(error: JSError?) -> String {
        var js = ""
        if let e = error {
            js += "\(e.jsString()), "
        }
        else {
            js += "var error = null"
        }
        return js
    }
    
}

struct JSError: JSStringProtocol {
    let title: String
    let description: String
    let todo: String?
    func jsString() -> String {
        var error = "var error = new Error('\(title)');"
        error += "error.info = {description:'\(description)'"
        if let t = todo {
            error += ", todo:'\(t)'}"
        }
        else {
            error += "}"
        }
        return error
    }
}

struct JSObject: JSStringProtocol {
    let value:Dictionary<String, NSObject>
    
    init(_ value: Dictionary<String, NSObject>) {
        self.value = value
    }
    
    func jsString() -> String {
        var s = ""
        traverse(value, js: &s)
        return s
    }
    
    func traverse<T>(obj:T, inout js:String) {
        if let o = obj as? Dictionary<String, NSObject> {
            js += "{"
            var count = 0
            for (key, value) in o {
                count++
                js += "'\(key)':"
                traverse(value, js: &js)
                if count < o.count {
                    js += ", "
                }
            }
            js += "}"
        }
        else if let o = obj as? NSArray {
            js += "["
            for (index, item) in o.enumerate() {
                traverse(item, js: &js)
                if index < o.count - 1 {
                    js += ","
                }
            }
            js += "]"
        }
        else if let o = obj as? String {
            js += "'\(o)'"
        }
        else if obj is NSNumber {
            js += "\(obj)"
        }
        else if let o = obj as? Bool {
            js += "\(o)"
        }
    }
}