//
//  ItemListViewController.swift
//  TbSWAMPSwiftSample
//
//  Created by Ueda on 2019/05/11.
//  Copyright © 2019 3bitter.com. All rights reserved.
//

import UIKit
import CoreBluetooth

// SDKメソッドを使用しない場合はCBCentralManagerDelegateを実装
class ItemListViewController: UITableViewController, TbBTManagerDelegate, CBCentralManagerDelegate {

    @IBOutlet var searchBeaconButton: UIButton!
    
    var fullContents: NSMutableArray = []
    var btManager: TbBTManager?
    var activityView: UIActivityIndicatorView?
    var timer: Timer?
    
    // SDKメソッドを使用しない場合はCBCentralManagerで直接Bluetoothチェック
    var cbManager: CBCentralManager?
    
    var searching: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        fullContents = NSMutableArray.init(array:ContentManager.sharedManager.defeaultContents())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewDidDisappear(animated)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fullContents.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContentCell", for: indexPath)

        // Configure the cell...
        if fullContents.count > 0 && indexPath.row < fullContents.count {
            let content = fullContents[indexPath.row] as! OurContent
            cell.textLabel?.text = content.title
            cell.detailTextLabel?.text = content.contentDescription
            cell.imageView?.image = content.icon;
        } else {
            cell.textLabel?.text = nil;
            cell.detailTextLabel?.text = nil
            cell.imageView?.image = nil
        }
        return cell
    }
    
    @IBAction func beaconSearchButtonDidPush(_ sender: Any) -> Void {
        // 位置情報サービス自体の許可がされていない
        if CLLocationManager.locationServicesEnabled() == false {
            let alertC = UIAlertController(title: "Warning", message: "「プライバシー」-「位置情報サービス」をオンにすることで、特殊コンテンツを検索できます", preferredStyle: .alert)
            alertC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                print("位置情報サービスがオフのアラート")
            }))
            self.present(alertC, animated: true, completion: nil)
        }
        self .checkUserPermissions()
    }
    
    @objc func prepareLocManager() -> Void {
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.locManager = CLLocationManager()
        appDelegate.locManager!.delegate = appDelegate
    }
    // アプリに対しての位置情報サービス使用のユーザー許可のチェック
    func checkUserPermissions() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(ItemListViewController.requestUserPermission), name: Notification.Name(kLocationServicePermissionNotDetermied), object: UIApplication.shared.delegate)
        
        // Bluetoothが本当に（コントロールセンターのみでなく）設定オフとなっているかをチェックするために先にCLLocationManagerをインスタンス化
        NotificationCenter.default.addObserver(self, selector: #selector(ItemListViewController.checkBluetoothState),name: Notification.Name(kLocationServicePermissionWhenInUse),  object:UIApplication.shared.delegate)
        
        self.prepareLocManager()
    }
    
    // Bluetoothの使用状態のチェッック
    @objc func checkBluetoothState() {
        // SDK使用のアプローチ（サイレントチェック）
        btManager = TbBTManager.shared()
        if (btManager == nil) {
            self.prepareBTManager()
        }
        btManager?.delegate = self
        //btManager!.checkCurrentBluetoothAvailability()
        // Bluetoothがオフの場合、デフォルトでのBluetooth設定ダイアログが表示される
        cbManager = CBCentralManager.init(delegate: self, queue: nil)
    }
    
    @objc func requestUserPermission() -> Void {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let locManager = appDelegate.locManager {
            locManager.requestWhenInUseAuthorization()
        }
    }
    
    func prepareBTManager() -> Void {
        btManager = TbBTManager.initSharedManagerUnderAgreement(true)
        btManager?.delegate = self
    }
    
   
     // btManager?.checkCurrentBluetoothAvailability() でのBluetoothチェックのコールバック
    func didDetermineBlutoothAvailability(_ available: Bool) {
        if available == false
        {
          //  self.confirmBluetoothIsReallyOff()
            /*
            let alertC = UIAlertController(title: "Warning", message: "Bluetoothをオンにすることで、特殊コンテンツを検索できます", preferredStyle: .alert)
            alertC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                print("Bluetoothがオフのアラート")
            }))
            self.present(alertC, animated: true, completion: nil) */
        } else {
            print("Bluetooth is ON")
        }
    }
    
    @objc func startSearch() -> Void {
        self.searching = true
    }
    
    @objc func stopCheckRanging() -> Void {
        print("BLE can be used. Stop ranging for check");
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let locationManager = appDelegate.locManager { self.btManager?.stopRangingTbBTDynamicBeacons(locationManager)
            appDelegate.inCheckProcess = false
            self.perform(#selector(ItemListViewController.startSearch))
        }
    }
    // Bluetoothが本当にオフ（設定アプリによる明示的なオフ）なのかチェックする
    // Beaconの計測が機能すればオフではない
    func confirmBluetoothIsReallyOff() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.inCheckProcess = true;
        let stopTime = Date(timeInterval: 0.5, since: Date())
        // for iOS 9.0+
        appDelegate.stopCheckTimer = Timer(fireAt: stopTime, interval: 0, target: self, selector:#selector(ItemListViewController.stopCheckRanging), userInfo: nil, repeats: false)
        RunLoop.main.add(appDelegate.stopCheckTimer!, forMode: RunLoop.Mode.common)
        print("Start ranging for check");
        self.btManager?.startRangingTbBTDynamicBeacons(appDelegate.locManager)
        /* iOS 10.0+
        if let locationManager = appDelegate.locManager {
                appDelegate.stopCheckTimer = Timer(fire: stopTime, interval: 0, repeats: false, block:{(timer)->Void in
                print("BLE can be used. Stop ranging for check");
                self.btManager?.stopRangingTbBTDynamicBeacons(locationManager)
                appDelegate.inCheckProcess = false
                    self.perform(#selector(ItemListViewController.startSearch))
            })
                RunLoop.main.add(appDelegate.stopCheckTimer!, forMode: RunLoop.Mode.common)
                print("Start ranging for check");
                self.btManager?.startRangingTbBTDynamicBeacons(appDelegate.locManager)
        } else {
            print("CLLocationManager not prepared yet.")
        } */
    }

        
    func refreshContents() -> Void {
        fullContents = NSMutableArray(objects: ContentManager.sharedManager.defeaultContents())
        let mappedCotents = ContentManager.sharedManager.currentMappedContents
        fullContents.add(mappedCotents)
        self.tableView.reloadData()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("%s", #function)
        if (central.state == CBManagerState.poweredOn) {
            print("Power ON");
            // 処理を継続
        } else {
            // カスタマイズ処理をするか、処理を中断
            confirmBluetoothIsReallyOff()
            //print("Power OFF. Stop using bluetooth..");
        }
    }
}
