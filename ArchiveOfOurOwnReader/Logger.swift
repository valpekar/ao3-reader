//
//  Logger.swift
//  DrawMotion
//
//  Created by Sergey Pekar on 7/20/17.
//  Copyright © 2017 Sergey Pekar. All rights reserved.
//

import Foundation
import FirebaseCrashlytics

public func debugLog(_ message: String = "", functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
    debugLog(message:message, functionName:functionName, fileName:fileName, lineNumber:lineNumber)
}

public func debugLog(message: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
    let className = (fileName as NSString).lastPathComponent

    #if RELEASE
    CLSLogv("\(className) \(functionName) line: \(lineNumber) \(message)", getVaList([]));
    #else
    print(className, functionName, "line:", lineNumber, message, separator: " ", terminator: "\n")
    #endif
    
}
