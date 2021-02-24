//
//  FKeyboardMenuView.swift
//  KeyboardCounter
//
//  Created by Fang on 2021/2/20.
//

import Cocoa

import ServiceManagement


class FKeyboardMenuView: NSObject, NSMenuDelegate {
    
    @IBOutlet var statusMenu: NSMenu!
    @IBOutlet weak var startItem: NSMenuItem!
    @IBOutlet weak var dataItem: NSMenuItem!
    
    
    let viewModel = FKeyboardViewModel()
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let subMenu = NSMenu()
    
    override init() {
        super.init()
        
        //监听
        bindAction()
    }
    
    override func awakeFromNib() {
        let icon = NSImage(named: "keyboard")
        icon?.isTemplate = true
        statusItem.button?.image = icon
        statusItem.button?.imagePosition = NSControl.ImagePosition.imageLeft
        statusItem.menu = statusMenu
        
        statusMenu.setSubmenu(subMenu, for: dataItem)
        subMenu.delegate = self
        
    }
    
    func bindAction() {
        _ = self.viewModel.rx.observe(Int.self, "count").takeUntil(rx.deallocated).subscribe(onNext: {[weak self] (value) in
            self?.statusItem.button?.title = " \(value!)/字"
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
    @IBAction func startupItemClick(_ sender: NSMenuItem) {
        let open = sender.state != .on
        
        let launcherAppIdentifier = "com.example.KeyboardHelper"

        if SMLoginItemSetEnabled(launcherAppIdentifier as CFString, open) {
            if open {
                print("添加登录项成功")
                sender.state = .on
            } else {
                print("移除登录项成功")
                sender.state = .off
            }
        } else {
            print("添加登录项失败")
        }
        
    }
    
    //MARK: action
    @IBAction func quitClick(_ sender: NSMenuItem) {
        viewModel.saveDayData()
        NSApplication.shared.terminate(self)
    }

    
    @IBAction func queryDataClick(_ sender: NSMenuItem) {
        
    }
    
}
