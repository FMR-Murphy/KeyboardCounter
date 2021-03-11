//
//  FDatabaseManager.swift
//  KeyboardCounter
//
//  Created by Fang on 2021/2/22.
//

import Cocoa

import SQLite

private let FTableName = "counts"

private let id = Expression<Int64>("id")
private let appId = Expression<String>("app")
private let dateString = Expression<String>("dateString")
private let startTime = Expression<Date>("startTime")
private let endTime = Expression<Date>("endTime")
private let count = Expression<Int>("count")
private let lineNum = Expression<Int>("lineNum")


class FDatabaseManager: NSObject {
    
    var db: Connection?
    var counts: Table?
    
    override init() {
        
        let path = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory, .userDomainMask, true
        ).first! + "/" + Bundle.main.bundleIdentifier!

        // create parent directory iff it doesn’t exist
        
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("DBManager: 创建数据库目录失败")
        }
        
        //创建数据库链接
        guard let database = try? Connection.init("\(path)/db.sqlite3") else {
            return
        }
        db = database
        //创建数据库
        counts = Table(FTableName)
        
        
        
        //创建表
        do {
            try db!.run(counts!.create(ifNotExists: true) { t in
                
                //主键，不为空，自动递增
                t.column(id, primaryKey: .autoincrement)
                t.column(appId)
                t.column(dateString)
                t.column(startTime)
                t.column(endTime)
                t.column(count)
                t.column(lineNum)
            })
        } catch {
            print("db create error \(error)")
        }
    }
    
    func insertData(model: FCounterModel) {
        guard counts != nil && db != nil else {
            print("insertData faile: 数据库不存在或表不存在")
            return
        }
        do {
            let rowid = try db!.run(counts!.insert(appId <- model.app!,
                                                   dateString <- model.dateString,
                                                   startTime <- model.startTime!,
                                                   endTime <- model.endTime!,
                                                   count <- model.count,
                                                   lineNum <- model.lineNum))
            
            print("inserted success, id:\(rowid)")
        } catch {
            print("insertion faile: \(error)")
        }
    }
    
    func queryData(dateStr: String) -> Array<FNumberModel>? {
        
        guard counts != nil && db != nil else {
            print("insertData faile: 数据库不存在或表不存在")
            return nil
        }
        
        let query = counts!.select(appId, count.sum)
            .order(count.sum.desc)
            .group(appId)
            .filter(dateString == dateStr)
                    
        guard let data = try? db!.prepare(query) else {
            return nil
        }
        
        var array = [FNumberModel]()
        for user in data {
            let number = FNumberModel.init(appId: user[appId], count: user[count.sum]!)
            array.append(number)
        }
        return array
    }
    
    func queryTotolCount(dateStr: String) -> Int {
        guard counts != nil && db != nil else {
            print("insertData faile: 数据库不存在或表不存在")
            return 0
        }
        
        let query = counts!.select(count.sum)
            .filter(dateString == dateStr)
        
        guard let data = try? db!.prepare(query) else {
            return 0
        }
        
        var i = 0
        for item in data {
            i += item[count.sum] ?? 0
        }
        return i
    }
    
    func queryAllTotal() -> Array<Any>? {
        guard counts != nil && db != nil else {
            print("insertData faile: 数据库不存在或表不存在")
            return nil
        }
        
        let query = counts!.select(appId, count.sum, dateString)
            .order(dateString.asc)
            .group(dateString)
        
        guard let data = try? db!.prepare(query) else {
            return nil
        }
        
        for item in data {
            print(item)
        }
        return nil
    }
}
