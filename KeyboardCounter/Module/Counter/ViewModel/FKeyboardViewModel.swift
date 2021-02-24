//
//  FKeyboardViewModel.swift
//  KeyboardCounter
//
//  Created by Fang on 2020/8/13.
//

import Cocoa
import RxSwift
import RxCocoa

typealias AppsDictionary = Dictionary<String, FApplicationModel>

let appInfoKey = "appInfo"
let totalCountKey = "totalCountKey"
let mouseCountKey = "mouseCountKey"

class FKeyboardViewModel: NSObject {
    
    @objc dynamic var count: Int = 0
    
    private lazy var disposeBag = { () -> DisposeBag in
        let disposeBag = DisposeBag()
        return disposeBag
    }()
    
    private lazy var model: FCounterModel? = {
        let model = FCounterModel(app: appBundleId, dateString: dateString!)
        return model
    }()
    
    //临时信息
    var appBundleId: AppBundleId?
    var apps: AppsDictionary?
    
    //日期格式化
    private lazy var dateString: String? = {
        return getDateString()
    }()
    
    private lazy var dateFormatter: DateFormatter? = { () -> DateFormatter in
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        return dateFormatter
    }()
    
    //UI
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    private let dbManager = FDatabaseManager()
    
    override init() {
        super.init()
        
        getAppInfo()
        //获取今天总数
        todayTotal()
        bindAction()
    }
    
    private func bindAction() {
        let open = AXIsProcessTrusted()
        if !open {
            print("需要开启辅助功能权限")
            return
        }
        
        let workspace = NSWorkspace.shared
        workspace.addObserver(self, forKeyPath: "frontmostApplication", options: [.new, .old], context: nil)
        
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) { [self] (event) in
            if event.characters != "\u{7F}" {
                self.startInput(event)
            }
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseDown) { [self](event) in
            if event.type == NSEvent.EventType.leftMouseDown {
                
            }
        }
        
        
        Observable<Int>.interval(RxTimeInterval.seconds(1), scheduler: MainScheduler.asyncInstance).subscribe {[weak self] (value) in

            if self?.dateString != self?.getDateString() {
                self?.saveDayData()
                self?.dateString = self?.getDateString()
                self?.todayTotal()
            }
        }.disposed(by: disposeBag)
    }
    
    func saveDayData() {
        saveTotal()
        saveData()
    }
    
    //MARK: 功能
    private func todayTotal() {
        let key = totalKey(dateString!)
        count = UserDefaults.standard.value(forKey: key) as? Int ?? 0
    }
    
    private func saveTotal() {
        let key = totalKey(dateString!)
        UserDefaults.standard.setValue(count, forKey: key)
    }
    
    private func totalKey(_ date: String) -> String {
        return totalCountKey + "-" + date
    }
    
    private func getDateString() -> String {
        let date = Date()
        return (dateFormatter?.string(from: date))!
    }
    
    @objc dynamic private func startInput(_ event: NSEvent) {
        self.count += 1
        if model == nil {
            model = FCounterModel(app: appBundleId, dateString: dateString!)
        } else {
            model?.count += 1
            if event.characters == "\r" {
                model?.lineNum += 1
                print("换行   \r")
            }
        }
        
    }
    
    private func saveData() {
        //TODO: 123
        print("saveData")
        if model!.count > 0 {
            model?.endTime = Date()
            dbManager.insertData(model: model!)
        }
        model = nil
    }
    
    //MARK: observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frontmostApplication" {
            if let app: NSRunningApplication = change?[NSKeyValueChangeKey.newKey] as? NSRunningApplication {
                
                appBundleId = updateAppInfo(app: app)
                if model?.app == nil {
                    model?.app = appBundleId
                } else {
                    //切换
                    saveData()
                }
            }
            
        } else {
            super .observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func getAppInfo() {

        apps = AppsDictionary()
        let appsDic = UserDefaults.standard.value(forKey: appInfoKey) as? [String: Data] ?? [String: Data]()
        for (key,appData) in appsDic {
            
            apps![key] = try? NSKeyedUnarchiver.unarchivedObject(ofClass: FApplicationModel.self, from: appData)
        }
    }
    
    private func updateAppInfo(app: NSRunningApplication) -> AppBundleId {
        
        let bundleId = getAppBundleID(app: app)
        
        guard apps?[bundleId] == nil else {
            return bundleId
        }
        
        let model = FApplicationModel.model(withApp: app)
        apps?[bundleId] = model
        
        storeAppInfo(key: bundleId, app: model)
        
        return bundleId
    }
    
    private func storeAppInfo(key: String, app: FApplicationModel) {
        var appsDic = UserDefaults.standard.value(forKey: appInfoKey) as? [String: Data] ?? [String: Data]()
        let data = try? NSKeyedArchiver.archivedData(withRootObject: app, requiringSecureCoding: false)
        
        appsDic[key] = data
        UserDefaults.standard.setValue(appsDic, forKey: appInfoKey)
    }
    
    private func getAppBundleID(app: NSRunningApplication) -> AppBundleId {
        return app.bundleIdentifier ?? app.localizedName!
    }
    
    
    //MARK: OPEN
    func queryTodayData() -> Array<FNumberModel>? {
        return dbManager.queryData(dateStr: dateString!)
    }
}

