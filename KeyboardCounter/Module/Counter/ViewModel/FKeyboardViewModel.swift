//
//  FKeyboardViewModel.swift
//  KeyboardCounter
//
//  Created by Fang on 2020/8/13.
//

import Cocoa
import RxSwift
import RxCocoa

let totalCountKey = "totalCountKey"
let mouseCountKey = "mouseCountKey"

class FKeyboardViewModel: NSObject {

    @IBOutlet var statusMenu: NSMenu!
    
    
    @objc dynamic var count: Int = 0
    
    lazy var disposeBag = { () -> DisposeBag in
        let disposeBag = DisposeBag()
        return disposeBag
    }()
    
    lazy var model: FCounterModel? = {
        let model = FCounterModel(app: activeApp, dateString: dateString!)
        return model
    }()
    
    var activeApp: NSRunningApplication?
    lazy var dateString: String? = {
        return getDateString()
    }()
    
    lazy var dateFormatter: DateFormatter? = { () -> DateFormatter in
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        return dateFormatter
    }()
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    override init() {
        super.init()
        //获取今天总数
        todayTotal()
        
        //监听
        bindAction()
    }
    override func awakeFromNib() {
        let icon = NSImage(named: "keyboard")
        icon?.isTemplate = true
        statusItem.button?.image = icon
        statusItem.button?.imagePosition = NSControl.ImagePosition.imageLeft
        statusItem.menu = statusMenu
    }
    
    func bindAction() {
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
        
        _ = self.rx.observe(Int.self, "count").takeUntil(rx.deallocated).subscribe(onNext: {[weak self] (value) in
            self?.statusItem.button?.title = " \(value!)/字"
        })
        
        Observable<Int>.interval(RxTimeInterval.seconds(1), scheduler: MainScheduler.asyncInstance).subscribe {[weak self] (value) in

            if self?.dateString != self?.getDateString() {
                self?.saveDayData()
                self?.dateString = self?.getDateString()
                self?.todayTotal()
            }
        }.disposed(by: disposeBag)
        
      _ =  NotificationCenter.default.rx.notification(NSApplication.willTerminateNotification).subscribe { [weak self] (notification) in
            self?.saveTotal()
            self?.saveData()
        }
    }
    
    func saveDayData() {
        saveTotal()
        saveData()
    }
    
    //MARK: 功能
    func todayTotal() {
        let key = totalKey(dateString!)
        count = UserDefaults.standard.value(forKey: key) as? Int ?? 0
    }
    
    func saveTotal() {
        let key = totalKey(dateString!)
        UserDefaults.standard.setValue(count, forKey: key)
    }
    
    func totalKey(_ date: String) -> String {
        return totalCountKey + "-" + date
    }
    
    func getDateString() -> String {
        let date = Date()
        return (dateFormatter?.string(from: date))!
    }
    
    @objc dynamic func startInput(_ event: NSEvent) {
        self.count += 1
        if model == nil {
            model = FCounterModel(app: activeApp, dateString: dateString!)
        } else {
            model?.count += 1
            if event.characters == "\r" {
                model?.lineNum += 1
                print("换行   \r")
            }
        }
        
    }
    
    func saveData() {
        //TODO: 123
        print("saveData")
        model?.endTime = Date()
        model = nil
    }
    
    //MARK: observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frontmostApplication" {
            if let app: NSRunningApplication = change?[NSKeyValueChangeKey.newKey] as? NSRunningApplication {
                print(app.localizedName!)
                activeApp = app
                if model?.app == nil {
                    model?.app = app
                } else {
                    //切换
                    saveData()
                }
            }
            
        } else {
            super .observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @IBAction func clearCacheData(_ sender: Any) {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            
            defaults.removeObject(forKey: String(key))
        }
        count = 0
    }
    //MARK: action
    @IBAction func quitClick(_ sender: NSMenuItem) {
        saveData()
        saveTotal()
        NSApplication.shared.terminate(self)
    }
    
}

