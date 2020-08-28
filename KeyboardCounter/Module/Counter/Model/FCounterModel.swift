//
//  FCounterModel.swift
//  KeyboardCounter
//
//  Created by Fang on 2020/8/14.
//

import Cocoa

struct FCounterModel {
    var app: NSRunningApplication?
    //日期
    var dateString: String
    //开始时间
    var startTime: Date
    //结束时间
    var endTime: Date?
    
    var count: Int
    var lineNum: Int
    
    init(app: NSRunningApplication?, dateString: String) {
        self.app = app
        self.dateString = dateString
        self.startTime = Date()
        self.endTime = nil
        self.count = 0
        self.lineNum = 0
    }
}
