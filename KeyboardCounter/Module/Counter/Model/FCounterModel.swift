//
//  FCounterModel.swift
//  KeyboardCounter
//
//  Created by Fang on 2020/8/14.
//

import Cocoa

typealias AppBundleId = String

struct FCounterModel {
    var app: AppBundleId?
    //日期
    var dateString: String
    //开始时间
    var startTime: Date?
    //结束时间
    var endTime: Date?
    
    var count: Int
    var lineNum: Int
    
    init(app: AppBundleId?, dateString: String) {
        self.app = app
        self.dateString = dateString
        self.startTime = nil
        self.endTime = nil
        self.count = 0
        self.lineNum = 0
    }
}

struct FNumberModel {
    var app: NSRunningApplication?
    var appId: AppBundleId
    var count: Int
    
    init(appId: AppBundleId, count: Int) {
        self.appId = appId
        self.count = count
        self.app = nil
    }
}
