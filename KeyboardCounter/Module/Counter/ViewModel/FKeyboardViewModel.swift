//
//  FKeyboardViewModel.swift
//  KeyboardCounter
//
//  Created by Fang on 2020/8/13.
//

import Cocoa
import RxSwift
import RxCocoa
import ServiceManagement


typealias AppsDictionary = Dictionary<String, FApplicationModel>

let appInfoKey = "appInfo"
let mouseCountKey = "mouseCountKey"
let autoStartKey = "AutoStartKey"
let loginItemIdentifier = "com.murphy.KeyboardCounter.helper"

class FKeyboardViewModel: NSObject {
    
    @objc dynamic var count: Int = 0
    @objc dynamic var autoLaunch = false
    @objc dynamic var temperature = ""
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
        getAutoState()
        //获取今天总数
        todayTotal()
        bindAction()
    }
    
    private func bindAction() {
        
        let opts = NSDictionary(object: true,forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString) as CFDictionary
        if !AXIsProcessTrustedWithOptions(opts) {
            print("需要开启辅助功能权限")
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
                self?.saveData()
                self?.dateString = self?.getDateString()
                self?.todayTotal()
            }
            self?.temperature = String(format: "%.2f", SMC().getValue("TC0P") ?? 0.0)
        }.disposed(by: disposeBag)
    }
    
    //MARK: 功能
    private func todayTotal() {
        count = queryTotalCount()
    }
    
    private func getDateString() -> String {
        let date = Date()
        return (dateFormatter?.string(from: date))!
    }
    
    @objc dynamic private func startInput(_ event: NSEvent) {
        self.count += 1
        if model?.startTime == nil {
            model?.startTime = Date()
        }
        if model?.app == nil {
            model?.app = appBundleId
        }
        model?.count += 1
        if event.characters == "\r" {
            model?.lineNum += 1
            print("换行   \r")
        }
    }
    
    private func saveData() {
        //TODO: 123
        guard model?.count ?? 0 > 0 && model?.app != nil else {
            model = FCounterModel(app: appBundleId, dateString: dateString!)
            return
        }
        model?.endTime = Date()
        dbManager.insertData(model: model!)
        print("saveData")
        
        model = FCounterModel(app: appBundleId, dateString: dateString!)
    }
    
    //MARK: observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frontmostApplication" {
            if let app: NSRunningApplication = change?[NSKeyValueChangeKey.newKey] as? NSRunningApplication {
                
                appBundleId = updateAppInfo(app: app)
                saveData()
            }
            
        } else {
            super .observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func getAppInfo() {

        apps = AppsDictionary()
        let appsDic = UserDefaults.standard.value(forKey: appInfoKey) as? [String: Data] ?? [String: Data]()
        for (key,appData) in appsDic {
            
            apps![key] = try? (NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(appData) as! FApplicationModel)
//            apps![key] = try? NSKeyedUnarchiver.unarchivedObject(ofClass: FApplicationModel.self, from: appData)
            
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
    
    private func getAutoState() {
        autoLaunch = UserDefaults.standard.value(forKey: autoStartKey) as? Bool ?? false
    }
    
    //MARK: OPEN
    func changeAutoLaunchState(state: Bool, complate: (_ result: Bool) -> ()) {
        if #available(macOS 13.0, *) {
            state ? addLoginItem(complate: complate) : removeLoginItem(complate: complate)
        } else {
            let result = SMLoginItemSetEnabled(loginItemIdentifier as CFString, state)
            if result {
                saveLoginAutoLaunchState(state: state)
            }
            complate(result)
        }
    }
    
    @available(macOS 13.0, *)
    private func addLoginItem(complate: (_ result: Bool) -> ()) {
        do {
            try loginItem().register()
            saveLoginAutoLaunchState(state: true)
            complate(true)
        } catch {
            print(error)
            complate(false)
        }
    }
    
    @available(macOS 13.0, *)
    private func removeLoginItem(complate: (_ result: Bool) -> ()) {
        do {
            try loginItem().unregister()
            saveLoginAutoLaunchState(state: false)
            complate(true)
        } catch {
            print(error)
            complate(false)
        }
    }
    
    private func saveLoginAutoLaunchState(state: Bool) {
        autoLaunch = state
        UserDefaults.standard.setValue(state, forKey: autoStartKey)
    }
    
    @available(macOS 13.0, *)
    private func loginItem() -> SMAppService {
        return SMAppService.loginItem(identifier: loginItemIdentifier)
    }
    func saveDayData() {
        saveData()
    }
    
    func queryTodayData() -> Array<FNumberModel>? {
        return dbManager.queryData(dateStr: dateString!)
    }
    
    func queryTotalCount() -> Int {
        return dbManager.queryTotolCount(dateStr: dateString!)
    }
    
    func queryAllTotal() -> Array<Any>? {
        return dbManager.queryAllTotal()
    }
}

