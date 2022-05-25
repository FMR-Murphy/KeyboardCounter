//
//  FKeyboardMenuView.swift
//  KeyboardCounter
//
//  Created by Fang on 2021/2/20.
//

import Cocoa

import ServiceManagement
import RxSwift
import RxCocoa

class FKeyboardMenuView: NSObject, NSMenuDelegate {
    
    let statusMenu = NSMenu()
    lazy var autoItem: NSMenuItem = {
        let item = NSMenuItem(title: "开机启动", action: #selector(autoLaunchItemClick(_:)), keyEquivalent: "")
        item.target = self
        return item
    }()
    
    lazy var dataItem: NSMenuItem = {
        let item = NSMenuItem()
        item.title = "今日数据"
        return item
    }()
    
    lazy var quitItem: NSMenuItem = {
        let item = NSMenuItem(title: "Quit", action: #selector(quitClick(_:)), keyEquivalent: "")
        item.target = self
        return item
    }()
    
    let viewModel = FKeyboardViewModel()
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let subMenu = NSMenu()
    
    override init() {
        super.init()
        
        //监听
        bindAction()
    }
    
    override func awakeFromNib() {
        createUI()
    }
    
    func createUI() {
        let icon = NSImage(named: "keyboard")
        icon?.isTemplate = true
        statusItem.button?.image = icon
        statusItem.button?.imagePosition = NSControl.ImagePosition.imageLeft
        statusItem.menu = statusMenu
        
        statusMenu.addItem(autoItem)
        statusMenu.addItem(dataItem)
        statusMenu.addItem(quitItem)
        
        statusMenu.setSubmenu(subMenu, for: dataItem)
        subMenu.delegate = self
    }
    
    func bindAction() {
        let countSignal = self.viewModel.rx.observe(Int.self, "count")
        let tempSignal = self.viewModel.rx.observe(String.self, "temperature")
        
        _ = Observable.combineLatest(countSignal, tempSignal).takeUntil(rx.deallocated).subscribe(onNext: {[weak self] (first, second) in
            self?.statusItem.button?.title = " \(first!)/字 | \(second!)˚C"
        })
        
        _ = self.viewModel.rx.observe(Bool.self, "autoLaunch").takeUntil(rx.deallocated).subscribe(onNext: {[weak self] (value) in
            self?.autoItem.state = value ?? false ? .on : .off
        })
    }
    
    //MARK: NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        subMenu.removeAllItems()
        
        let array = viewModel.queryTodayData()
        guard array?.count ?? 0 > 0 else {
            let noData = NSMenuItem.init()
            noData.title = "暂无数据"
            subMenu.addItem(noData)
            return
        }
        
        for model in array! {
            
            let app = viewModel.apps?[model.appId]
            
            let item = NSMenuItem(title: String(model.count), action: #selector(numberItemClick(item:)), keyEquivalent: "")
            item.toolTip = app?.localizedName
            item.image = app?.icon
            item.target = self
            subMenu.addItem(item)
        }
    }
    
    @objc func numberItemClick(item: NSMenuItem) {
        
    }
    
    //MARK: action
    @objc func autoLaunchItemClick(_ sender: NSMenuItem) {
        let open = sender.state != .on
        
        viewModel.changeAutoLaunchState(state: open) { (result) in
            print("\(open ? "添加" : "移除")登录项\(result ? "成功" : "失败")")
        }
    }
    
    @objc func quitClick(_ sender: NSMenuItem) {
        viewModel.saveDayData()
        NSApplication.shared.terminate(self)
    }

    
    func queryDataClick(_ sender: NSMenuItem) {
        
    }
    
}
