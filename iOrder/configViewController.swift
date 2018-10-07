//
//  configViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/25.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB

class configViewController: UIViewController, UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate {

//    @IBOutlet weak var demoLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var authButton: UIButton!
    
    var tableViewMain = UITableView()
    
    let allIcons:NSDictionary = NSDictionary(dictionary: FAKFontAwesome.allIcons())
    
    let sqls = ["DELETE FROM staffs_now;","DELETE FROM categorys_master;","DELETE FROM menus_master;","DELETE FROM sub_menus_master;","DELETE FROM menus_price WHERE order_kbn = 2;","DELETE FROM special_menus_master;","DELETE FROM menus_price WHERE order_kbn = 3;","DELETE FROM pc_config;","DELETE FROM timezone;","DELETE FROM once_a_day;"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor

        let iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        
        // 下記でアイコンの色も変えられます
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
//        iconImage?.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        backButton.setImage(Image, for: UIControlState())

        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.pressedLong(_:)))
        
        backButton.addGestureRecognizer(longPress)

        // 認証ボタンアイコン設定
        let iconImage2 = FAKFontAwesome.lockIcon(withSize: iconSize)
        iconImage2?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        let Image2 = iconImage2?.image(with: CGSize(width: iconSize, height: iconSize))
        authButton.setImage(Image2, for: UIControlState())
        
        let iconImage3 = FAKFontAwesome.unlockIcon(withSize: iconSize)
        iconImage3?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        let Image3 = iconImage3?.image(with: CGSize(width: iconSize, height: iconSize))
        
        // 認証してるかどうかでボタンを非活性にする
        let serverAuth:checkServerAuth = checkServerAuth()
        let serverCertification_flag = serverAuth.checkCertification()
        if (serverCertification_flag == 1) { // 認証済
            self.authButton.isEnabled = false
            self.authButton.alpha = 0.6
            self.authButton.setTitle("認証済",for:UIControlState())
            authButton.setImage(Image3, for: UIControlState())
        } else if(serverCertification_flag == 2) { // 認証待ち
            self.authButton.isEnabled = false
            self.authButton.alpha = 0.6
            self.authButton.setTitle("認証待",for:UIControlState())
            authButton.setImage(Image3, for: UIControlState())
        }
         
        self.loadData()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if globals_config_info != nil {
            for (i,conf_section) in configtableData.enumerated() {
                print(conf_section,globals_config_info!.item)
                let row = conf_section.index(where: {$0.item == globals_config_info!.item})
                if row != nil {
                    let indexPath = IndexPath(row: row!, section: i)
                    
                    self.tableViewMain.reloadRows(at: [indexPath], with: .automatic)
                }
            }
        }
        
//        if globals_config_info?.0 != nil && globals_config_info?.1 != nil {
//            
//            let indexPath = NSIndexPath(forRow: globals_config_info!.1, inSection: globals_config_info!.0)
//            self.tableViewMain.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
//        }
        
        
    }

    
    // ステータスバーとナビゲーションバーの色を同じにする
    func position(for bar: UIBarPositioning) -> UIBarPosition {

        return UIBarPosition.topAttached
        
    }
    
    // ステータスバーの文字を白にする
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent

    }
    
    func loadData(){
        // テーブルビューを作る
        // Status Barの高さを取得する.
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        
        // Navigetion Barの高さを取得する.
        //        let NavHeight: CGFloat = (self.navigationController?.navigationBar.frame.size.height)!
//        let NavHeight: CGFloat = 44
        
        // Viewの高さと幅を取得する.
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height - toolBarHeight
        
        // TableViewの生成する(status barの高さ分ずらして表示).
        self.tableViewMain = UITableView(frame: CGRect(x: 0, y: barHeight + NavHeight , width: displayWidth, height: displayHeight - barHeight - NavHeight ), style: UITableViewStyle.plain)
        
        // テーブルビューを追加する
        self.view.addSubview(self.tableViewMain)
        
        // テーブルビューのデリゲートとデータソースになる
        self.tableViewMain.delegate = self
        self.tableViewMain.dataSource = self
        
        // xibをテーブルビューのセルとして使う
        tableViewMain.register(UINib(nibName: "configTableViewCell", bundle: nil), forCellReuseIdentifier: "configCell")
        
        tableViewMain.register(UINib(nibName: "configSegmentedControlTableViewCell", bundle: nil), forCellReuseIdentifier: "configSegmentedCell")
        
        tableViewMain.register(UINib(nibName: "configToggleTableViewCell", bundle: nil), forCellReuseIdentifier: "configToggleCell")

        tableViewMain.register(UINib(nibName: "configStepperTableViewCell", bundle: nil), forCellReuseIdentifier: "configStepperCell")
        tableViewMain.rowHeight = UITableViewAutomaticDimension
        tableViewMain.allowsSelection = true

    }

    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {


        return configtableData[section].count
    }
    
    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {


        let cellData = configtableData[indexPath.section][indexPath.row]
        
        // セルを取り出す
        let iconName = "fa-" + cellData.icon
        
        var resultCode = allIcons.object(forKey: iconName)
        if (resultCode == nil) {
            // アイコンが設定されていない時はスマイルマークを出す
            resultCode = allIcons.object(forKey: "fa-smile-o")
        }
        
        let button = FAKFontAwesome(code: resultCode as! String, size: 20)
        
        // 色
        button?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        let Image = button?.image(with: CGSize(width: 20, height: 20))

        switch cellData.cellMode {
        // 通常のセル
        case normalCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: "configCell") as! configTableViewCell
            
            cell.configLabel1.baselineAdjustment = .alignCenters
            cell.configLabel2.baselineAdjustment = .alignCenters
            
            if cellData.isDisabled == true {
                // セルの選択不可にする
                cell.selectionStyle = UITableViewCellSelectionStyle.none
                cell.backgroundColor = iOrder_borderColor
                cell.configImage.alpha = 0.6
                cell.configLabel1.textColor = UIColor.gray
                cell.configLabel2.textColor = UIColor.gray
                
            } else {
                // セルの選択を許可
                cell.selectionStyle = UITableViewCellSelectionStyle.blue
                cell.backgroundColor = UIColor.clear
                cell.configImage.alpha = 1.0
                cell.configLabel1.textColor = UIColor.black
                cell.configLabel2.textColor = UIColor.darkGray
            }
            
            // 選択時に色を変えない
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            
            cell.configImage.image = Image
            cell.configLabel1.text = cellData.itemName
            
            // バージョン情報とビルド情報は ’＞’ を出さない
            switch cellData.item {
            case "version","build":
                cell.selectionStyle = UITableViewCellSelectionStyle.none
                cell.accessoryType = .none
                cell.configLabel2.text = cellData.defaultSt
                break;
            // ライセンスは ’＞’ を出す
            case "license":
                    cell.configLabel2.text = cellData.defaultSt
                    break;
                
            case "shop_code":
                cell.accessoryType = .none
                cell.configLabel2.text = String(cellData.defaultNo)
                // 店舗コードが変更可能の場合
                if is_shop_code_change {
                    // セルの選択を許可
                    cell.selectionStyle = UITableViewCellSelectionStyle.blue
                    cell.backgroundColor = UIColor.clear
                    configtableData[indexPath.section][indexPath.row].isDisabled = false
                    cell.configImage.alpha = 1.0
                    cell.configLabel1.textColor = UIColor.black
                    cell.configLabel2.textColor = UIColor.darkGray
                    
                } else {
                    // セルの選択不可にする
                    cell.selectionStyle = UITableViewCellSelectionStyle.none
                    cell.backgroundColor = iOrder_borderColor
                    configtableData[indexPath.section][indexPath.row].isDisabled = true
                    cell.configImage.alpha = 0.6
                    cell.configLabel1.textColor = UIColor.gray
                    cell.configLabel2.textColor = UIColor.gray
                }
                
                
                break
            case "is_minus_qty":
                // マイナス数量入力可否（デフォルト：許可しない）
                cell.accessoryType = .none
                cell.configLabel2.text = is_minus_qty == 0 ? "許可しない" : "許可する"
                break
            case "is_oder_cancel":
                // 注文取消し可否（0：常に許可（デフォルト）1：チェックアウト済みは不可 2：配膳済みは不可 3：調理済みは不可 4：常に不可）
                cell.accessoryType = .none
                var msg = ""
                switch is_oder_cancel {
                case 0:
                    msg = "常に許可"
                case 1:
                    msg = "チェックアウト済みは不可"
                case 2:
                    msg = "配膳済みは不可"
                case 3:
                    msg = "調理済みは不可"
                case 4:
                    msg = "常に不可"
                default:
                    break
                }
                cell.configLabel2.text = msg
                break
            case "is_order_wait":
                // オーダー待ち機能可否（デフォルト：許可）
                cell.accessoryType = .none
                cell.configLabel2.text = is_order_wait == 1 ? "使用できます" : "使用できません"
                break
            case "is_payer_allocation":
                // 精算者振り替え機能可否（デフォルト：許可）
                cell.accessoryType = .none
                cell.configLabel2.text = is_payer_allocation == 1 ? "使用できます" : "使用できません"
                break
            case "is_timezone":
                // 時間帯区分を使用するか（デフォルト：使用する）
                cell.accessoryType = .none
                cell.configLabel2.text = is_timezone == 1 ? "使用できます" : "使用できません"
                break
            case "is_unit_price_kbn":
                // 単価区分変更可否（デフォルト：変更可）
                cell.accessoryType = .none
                cell.configLabel2.text = is_unit_price_kbn == 1 ? "変更できます" : "変更できません"
                break
            default:
                // サウンド設定の場合
                if indexPath.section == 2 {
                    // 使用DB
                    var use_db = production_db
                    if demo_mode != 0{
                        use_db = demo_db
                    }
                    
                    // /Documentsまでのパスを取得
                    let paths = NSSearchPathForDirectoriesInDomains(
                        .documentDirectory,
                        .userDomainMask, true)
                    let _path = (paths[0] as NSString).appendingPathComponent(use_db)
                    let db = FMDatabase(path: _path)
                    db.open()
                    
                    let sql = "select * from app_config_sound where sound_no = ? ; "
                    let results = db.executeQuery(sql, withArgumentsIn:[configtableData[indexPath.section][indexPath.row].defaultNo])
                    
                    while (results?.next())! {
                        let disp_name = results?.string(forColumn:"disp_name")
                        cell.configLabel2.text = disp_name
                        configtableData[indexPath.section][indexPath.row].defaultSt = disp_name!
                        
                    }
                    db.close()
                } else {
                    cell.configLabel2.text = String(cellData.defaultNo)
                }
                cell.accessoryType = .disclosureIndicator
            }

            return cell
        // スイッチのついたセル
        case switchCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: "configToggleCell") as! configToggleTableViewCell
            
            
            if cellData.isDisabled == true {
                // セルの選択不可にする
                cell.selectionStyle = UITableViewCellSelectionStyle.none
                cell.backgroundColor = iOrder_borderColor
                cell.configToggleSwitch.isEnabled = false
                cell.configToggleImage.alpha = 0.6
                cell.configToggleLabel.textColor = UIColor.gray
                
            } else {
                // セルの選択を許可
                cell.selectionStyle = UITableViewCellSelectionStyle.blue
                cell.backgroundColor = UIColor.clear
                cell.configToggleSwitch.isEnabled = true
                cell.configToggleImage.alpha = 1.0
                cell.configToggleLabel.textColor = UIColor.black
            }
            
            // 選択時に色を変えない
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            
            cell.configToggleImage.image = Image
            cell.configToggleLabel.text = cellData.itemName
            
            cell.configToggleSwitch.addTarget(self, action: #selector(self.tapSwich), for: .valueChanged)

            if cellData.defaultNo == 0 {
                cell.configToggleSwitch.isOn = false
            } else {
                cell.configToggleSwitch.isOn = true
            }
            
            return cell
        // セグメントコントロールのついたセル
        case segmentCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: "configSegmentedCell") as! configSegmentedControlTableViewCell
            
            if cellData.isDisabled == true {
                // セルの選択不可にする
                cell.selectionStyle = UITableViewCellSelectionStyle.none
                cell.backgroundColor = iOrder_borderColor
                cell.configSegmentedSegmented.isEnabled = false
                cell.configSegmentedImage.alpha = 0.6
                cell.configSegmentedLabel.textColor = UIColor.gray
            } else {
                // セルの選択を許可
                cell.selectionStyle = UITableViewCellSelectionStyle.blue
                cell.backgroundColor = UIColor.clear
                cell.configSegmentedSegmented.isEnabled = true
                cell.configSegmentedImage.alpha = 1.0
                cell.configSegmentedLabel.textColor = UIColor.black
                
            }
            
            // 選択時に色を変えない
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            
            cell.configSegmentedSegmented.addTarget(self, action: #selector(self.tapSegmented), for: .valueChanged)

            cell.configSegmentedImage.image = Image
            cell.configSegmentedSegmented.selectedSegmentIndex = cellData.defaultNo
            cell.configSegmentedLabel.text = cellData.itemName
            return cell
        default:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "configStepperCell") as! configStepperTableViewCell

            
            // 選択時に色を変えない
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            
            cell.configImage.image = Image
            cell.configLabel1.text = cellData.itemName
            cell.configLabel2.text = ""
//            cell.configLabel2.text = String(cellData.defaultNo)
            
//            let stepper = UIStepper()
//
//            // 最小値, 最大値, 規定値の設定をする.
//            
//            stepper.minimumValue = 0
//            stepper.maximumValue = 999
//            stepper.value = Double(cellData.defaultNo)
//            
//            stepper.addTarget(self, action: #selector(configViewController.stepperDidTap(_:)), forControlEvents: UIControlEvents.ValueChanged)
            
            
//            cell.accessoryView = stepper
            
            if cellData.isDisabled == true {
                // セルの選択不可にする
                cell.selectionStyle = UITableViewCellSelectionStyle.none
                cell.backgroundColor = iOrder_borderColor
                cell.configImage.alpha = 0.6
                cell.configLabel1.textColor = UIColor.gray
                cell.configLabel2.textColor = UIColor.gray
//                stepper.enabled = false
                
            } else {
                // セルの選択を許可
                cell.selectionStyle = UITableViewCellSelectionStyle.blue
                cell.backgroundColor = UIColor.clear
                cell.configImage.alpha = 1.0
                cell.configLabel1.textColor = UIColor.black
                cell.configLabel2.textColor = UIColor.darkGray
//                stepper.enabled = true
            }

            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {


        if configtableData[indexPath.section][indexPath.row].isDisabled == true {
            return nil;
            
        } else {
            return indexPath;
        }
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        

        return configTitle.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {


        let cell = tableView.dequeueReusableCell(withIdentifier: "configCell") as! configTableViewCell
        return cell.bounds.height
    }
    
    
    // セクションのタイトル（UITableViewDataSource）
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {


        let title = configTitle[section]
        return title
    }
    
    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
//        AVAudioPlayerUtil.play()
        
        // SubViewController へ遷移するために Segue を呼び出す
        // セルに表示するデータを取り出す
        let cellData = configtableData[indexPath.section][indexPath.row]
        if cellData.cellMode == normalCell || cellData.cellMode == stepperCell {
            if cellData.item == "shop_code" {
                //textの表示はalertのみ。ActionSheetだとtextfiledを表示させようとすると
                //落ちます。
                let alert:UIAlertController = UIAlertController(title:cellData.itemName,message: "店舗コードを入力してください。",preferredStyle: UIAlertControllerStyle.alert)
                
                let cancelAction:UIAlertAction = UIAlertAction(title: "キャンセル",style: UIAlertActionStyle.cancel,handler:{(action:UIAlertAction!) ->
                    Void in
                    print("Cancel")
                    tableView.deselectRow(at: indexPath, animated: true)
                                                                
                })
                let defaultAction:UIAlertAction = UIAlertAction(title: "OK",style: UIAlertActionStyle.default,handler:{(action:UIAlertAction!) ->
                    Void in
                    print("OK")
                    let textFields:Array<UITextField>? =  alert.textFields as Array<UITextField>?
                    if textFields != nil {
                        for textField:UITextField in textFields! {
                            //各textにアクセス
                            print(textField.text as Any)
                            let predicate = NSPredicate(format: "SELF MATCHES '\\\\d+'")
                            if !(predicate.evaluate(with: textField.text)){
                                // エラー
                                print("エラー")
                            } else {
                                // 店舗コードが変更になったらDBを削除する
                                if shop_code != Int(textField.text!)! {
                                    
                                    // 使用DB
                                    var use_db = production_db
                                    if demo_mode != 0{
                                        use_db = demo_db
                                    }
                                    
                                    // /Documentsまでのパスを取得
                                    let paths = NSSearchPathForDirectoriesInDomains(
                                        .documentDirectory,
                                        .userDomainMask, true)
                                    let _path = (paths[0] as NSString).appendingPathComponent(use_db)
                                    
                                    // FMDatabaseクラスのインスタンスを作成
                                    // 引数にファイルまでのパスを渡す
                                    let db = FMDatabase(path: _path)
                                    
                                    // データベースをオープン
                                    db.open()
                                    // DBクリア
                                    for sql in self.sqls {
                                        print(sql)
                                        let _ = db.executeUpdate(sql, withArgumentsIn: [])
                                    }
                                    
                                    db.close()

                                    
                                    shop_code = Int(textField.text!)!
                                    configtableData[indexPath.section][indexPath.row].defaultNo = Int(textField.text!)!
                                    tableView.deselectRow(at: indexPath, animated: true)
                                    tableView.reloadRows(at: [indexPath], with: .automatic)
                                    
                                }
                                
//                                shop_code = Int(textField.text!)!
//                                configtableData[indexPath.section][indexPath.row].defaultNo = Int(textField.text!)!
//                                tableView.deselectRowAtIndexPath(indexPath, animated: true)
//                                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                            }
                        
                        }
                    }
                })
                alert.addAction(cancelAction)
                alert.addAction(defaultAction)
                
                //textfiledの追加
                alert.addTextField(configurationHandler: {(text:UITextField!) -> Void in
                    // キーボードは数字のみ
                    text.keyboardType = .numberPad
                    
                })
                present(alert, animated: true, completion: nil)
            } else {
                switch cellData.item {
                case "version","build":
                    break;
                default:
                    globals_config_info = cellData
                    performSegue(withIdentifier: "toConfigDetailViewContollerSegue",sender: nil)
                    break;
                }
            }
            
        }
        
    }
    
    func tapSwich(_ sender: UISwitch) {
        var sender_sv = sender.superview
        while(sender_sv!.isKind(of: configToggleTableViewCell.self) == false) {
            sender_sv = sender_sv!.superview
        }
        let cell = sender_sv as! configToggleTableViewCell
        // touchIndexは選択したセルが何番目かを記録しておくプロパティ
        let indexPath = self.tableViewMain.indexPath(for: cell)
        
        let cellData = configtableData[indexPath!.section][indexPath!.row]
        if cellData.cellMode == switchCell {
            
            let value = Int(NSNumber(value:sender.isOn))
            configtableData[indexPath!.section][indexPath!.row].defaultNo = value
            
            let item = configtableData[indexPath!.section][indexPath!.row].item
            
            switch item {
            case "is_guide" :
                guide_mode = value
            case "is_handwrite" :
                hand_write_mode = value
            case "is_search" :
                search_mode = value
            case "is_kana_show" :
                furigana = value
            case "is_price" :
                cost_disp = value
            case "is_holder_show_large" :
                text_size = value
            case "is_animation" :
                animation = value
            case "is_grid" :
                grid_disp = value
            case "is_bbsinfo" :
                notification = value
            case "is_bbsinfocenter" :
                notification_centre = value
            case "is_bbssound" :
                notification_sound = value
            case "is_bbsbadge" :
                notification_badge = value
            case "is_bbslock" :
                notification_lock = value
                
            default:
                break
            }
            
        }
        
    }
    
    func tapSegmented(_ sender: UISegmentedControl){
        let point: CGPoint = sender.convert(CGPoint.zero, to: tableViewMain)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)
        
        if indexPath != nil {
            let cellData = configtableData[indexPath!.section][indexPath!.row]
            if cellData.cellMode == segmentCell {
                if indexPath!.section == 1 && indexPath!.row == 0 {
                    configtableData[indexPath!.section][indexPath!.row].defaultNo = sender.selectedSegmentIndex
                    disp_row_height = sender.selectedSegmentIndex
                }
            }
        }
        
    }
    
//    func stepperDidTap(stepper: UIStepper) {
//
//        let point = stepper.convertPoint(CGPointZero, toView: tableViewMain)
//        let indexPath = self.tableViewMain.indexPathForRowAtPoint(point)!
//
//        configtableData[indexPath.section][indexPath.row].defaultNo = Int(stepper.value)
//        if indexPath.section == 2 && indexPath.row == 3 {
//            not_send_alert.sound_interval = Int(stepper.value)
//        } else {
//            data_not_send_alert.sound_interval = Int(stepper.value)
//        }
//        
//        self.tableViewMain.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
//        
//    }

    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
//        AVAudioPlayerUtil.play()
        
        // 使用DB
        let use_db = production_db
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        let _path = (paths[0] as NSString).appendingPathComponent(use_db)
        
        // FMDatabaseクラスのインスタンスを作成
        // 引数にファイルまでのパスを渡す
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        let sql = "UPDATE app_config SET is_demo = ?,is_guide = ?, new_order_category_DEFAULT = ?, add_order_category_DEFAULT = ?,is_handwrite = ?,is_search = ?,row_height = ?,is_kana_show = ?,is_price = ?,is_holder_show_large = ?,is_animation = ?,is_grid = ?,is_tapsound = ?,is_errorbeep = ?,topreturn_sound = ?,is_senddata = ?,is_senddata_sound = ?,is_senddata_interval = ?,is_senderror = ?,is_senderror_sound = ?,is_senderror_interval = ?,is_order_s2e = ?,is_order_s2e_sound = ?,is_order_s2e_interval = ?,is_bbsinfo = ?,is_bbsinfocenter = ?,is_bbssound = ?,is_bbsbadge = ?,is_bbslock = ?,shop_code = ?;"
        
        let colums = ["is_demo","is_guide","new_order_category_DEFAULT","add_order_category_DEFAULT","is_handwrite","is_search","row_height","is_kana_show","is_price","is_holder_show_large","is_animation","is_grid","is_tapsound","is_errorbeep","topreturn_sound","is_senddata","is_senddata_sound","is_senderror","is_senderror_sound","is_order_s2e","is_bbsinfo","is_bbsinfocenter","is_bbssound","is_bbsbadge","is_bbslock","shop_code","is_senddata_interval","is_senderror_interval"]
        
        
        var argumentArray:Array<Any> = []
        
        for colum in colums {
            for (section,confData) in configtableData.enumerated() {
                let row = confData.index(where: {$0.item == colum})
                if row != nil {
                    print(colum,configtableData[section][row!].defaultNo)
                    switch colum {
                    case "is_demo":
                        demo_mode = configtableData[section][row!].defaultNo
                        argumentArray.append(demo_mode)
                        break;
                    case "is_guide":
                        guide_mode = configtableData[section][row!].defaultNo
                        argumentArray.append(guide_mode)
                        break;
                    case "new_order_category_DEFAULT" :
                        first_disp_new = configtableData[section][row!].defaultNo
                        argumentArray.append(first_disp_new)
                        break;
                    case "add_order_category_DEFAULT":
                        first_disp_add = configtableData[section][row!].defaultNo
                        argumentArray.append(first_disp_add)
                        break;
                    case "is_handwrite":
                        hand_write_mode = configtableData[section][row!].defaultNo
                        argumentArray.append(hand_write_mode)
                        break;
                    case "is_search":
                        search_mode = configtableData[section][row!].defaultNo
                        argumentArray.append(search_mode)
                        break;
                    case "row_height":
                        disp_row_height = configtableData[section][row!].defaultNo
                        argumentArray.append(disp_row_height)
                        break;
                    case "is_kana_show":
                        furigana = configtableData[section][row!].defaultNo
                        argumentArray.append(furigana)
                        break;
                    case "is_price":
                        cost_disp = configtableData[section][row!].defaultNo
                        argumentArray.append(cost_disp)
                        break;
                    case "is_holder_show_large":
                        text_size = configtableData[section][row!].defaultNo
                        argumentArray.append(text_size)
                        break;
                    case "is_animation":
                        animation = configtableData[section][row!].defaultNo
                        argumentArray.append(animation)
                        break;
                    case "is_grid":
                        grid_disp = configtableData[section][row!].defaultNo
                        argumentArray.append(grid_disp)
                        break;
                    case "is_tapsound":
                        tap_sound = configtableData[section][row!].defaultNo
                        argumentArray.append(tap_sound)
                        break;
                    case "is_errorbeep":
                        err_sound = configtableData[section][row!].defaultNo
                        argumentArray.append(err_sound)
                        break;
                    case "topreturn_sound":
                        top_sound = configtableData[section][row!].defaultNo
                        argumentArray.append(top_sound)
                        break;
                    case "is_senddata":
                        not_send_alert.sound_interval = configtableData[section][row!].defaultNo
                        argumentArray.append(not_send_alert.sound_interval)
                        argumentArray.append(not_send_alert.sound_no)
                        argumentArray.append(not_send_alert.interval)
                        break;
                    case "is_senderror":
                        data_not_send_alert.sound_interval = configtableData[section][row!].defaultNo
                        argumentArray.append(data_not_send_alert.sound_interval)
                        argumentArray.append(data_not_send_alert.sound_no)
                        argumentArray.append(data_not_send_alert.interval)
                        break;
                    case "is_order_s2e":
                        order_start2end_alert.sound_interval = configtableData[section][row!].defaultNo
                        argumentArray.append(order_start2end_alert.sound_interval)
                        argumentArray.append(order_start2end_alert.sound_no)
                        argumentArray.append(order_start2end_alert.interval)
                        break;
                    case "is_bbsinfo":
                        notification = configtableData[section][row!].defaultNo
                        argumentArray.append(notification)
                        break;
                    case "is_bbsinfocenter":
                        notification_centre = configtableData[section][row!].defaultNo
                        argumentArray.append(notification_centre)
                        break;
                    case "is_bbssound":
                        notification_sound = configtableData[section][row!].defaultNo
                        argumentArray.append(notification_sound)
                        break;
                    case "is_bbsbadge":
                        notification_badge = configtableData[section][row!].defaultNo
                        argumentArray.append(notification_badge)
                        break;
                    case "is_bbslock":
                        notification_lock = configtableData[section][row!].defaultNo
                        argumentArray.append(notification_lock)
                        break;
                    case "shop_code":
                        shop_code = configtableData[section][row!].defaultNo
                        argumentArray.append("\(shop_code)")
                        break;
                    default:
                        break;
                    }

                }
            }
        }
        // 名前を付けたパラメータに値を渡す場合
        print(argumentArray)
        let results = db.executeUpdate(sql, withArgumentsIn: argumentArray)
        if !results {
            // エラー時
            print(results.description)
        }
        
        db.close()
    
        self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
    }

    
    // 戻るボタンで戻ってくるためのおまじない
    @IBAction func unwindToConfigView(_ segue: UIStoryboardSegue) {
        
    }
    
    // ボタンを長押ししたときの処理
    @IBAction func pressedLong(_ sender: UILongPressGestureRecognizer!) {
        let alertController = UIAlertController(title: "戻るが長押しされました", message: "メインメニューに戻りますか？\n入力中の内容がすべて消去されます！", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
            action in print("Pushed cancel")
//            return;
        }
        
        let okAction = UIAlertAction(title: "削除", style: .default){
            action in
            // メインメニューに戻る音
            TapSound.buttonTap(top_sound_file.0, type: top_sound_file.1)
            print("Pushed OK")
            self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
            
//            return;
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }

    
    // MARK: - Override methods
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion began")
            // エラー表示
            let alertController = UIAlertController(title: "シェイクされました", message: "メインメニューに戻りますか？\n入力中の内容がすべて消去されます！", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
                action in print("Pushed cancel")
                return;
            }
            
            let okAction = UIAlertAction(title: "削除", style: .default){
                action in
                // メインメニューに戻る音
                TapSound.buttonTap(top_sound_file.0, type: top_sound_file.1)
                print("Pushed OK")
                self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
                
                return;
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion ended")
            //            let text = self.textView.text
            //            self.textView.text = text + "\nMotion ended"
        }
    }
    
    override func motionCancelled(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion cancelled")
            //            let text = self.textView.text
            //            self.textView.text = text + "\nMotion cancelled"
        }
    }

    
    // 認証ボタンタップ時 ooishi
    @IBAction func sendAuthData(_ sender: AnyObject) {
        print("sendAuthData")
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let alertController = UIAlertController(title: "確認", message: "認証します。よろしいですか？", preferredStyle: .alert)

        // キャンセル時
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
            action in print("Pushed cancel")
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            return;
        }
        
        // OK時
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in
            print("Pushed OK")
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            
            self.spinnerStart()
            
            // バック実行
            self.dispatch_async_global{

                let TerminalName = UIDevice.current.name
                //let TerminalName = "iPod 16-049B"

                let url = urlString + "SendAuthorization?TerminalName=" + TerminalName + "&TerminalID=" + TerminalID! + "&StoreKbn=" + store_kbn.description
                let encUrl = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                print(encUrl as Any)
                let json = JSON(url: encUrl!)
                print(json)
                
                // エラーの時
                if json.asError != nil {
                    print("ng")
                    self.dispatch_async_main{
                        self.spinnerEnd()
                        let alertController = UIAlertController(title: "通信エラー", message: "認証に失敗しました。\n通信状態を確認してください", preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "はい", style: .default){
                            action in
                            // タップ音
                            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                            print("Pushed はい")
                            return;
                        }
                        alertController.addAction(OKAction)
                        self.present(alertController, animated: true, completion: nil)
                        return;
                    }

                } else {
                    print(json)
                    
                    // メッセージ取得
                    var authErrMessageW : String=""
                    for (key, value) in json {
                        if key as! String == "Message" {
                             authErrMessage = value.toString()
                        }
                    }
                    print(authErrMessage)
                    
                    for (key, value) in json {
                        if key as! String == "Return" {
                            if value.toString() == "true" {
                                print("true")
                                self.dispatch_async_main{
                                    
                                    // サーバ認証フラグを1にする
                                    let serverAuth:checkServerAuth = checkServerAuth()
                                    let serverCertification_flag = serverAuth.checkCertification()
                                    if (serverCertification_flag == 0) {
                                        serverAuth.setCertification()
                                    }
                                    
                                    // デモ認証フラグも1にする
                                    let demoAuth:checkDemoAuth = checkDemoAuth()
                                    let certification_flag = demoAuth.checkCertification()
                                    if (certification_flag == 0) {
                                        demoAuth.setCertification()
                                    }
                                    
                                    // ボタンを非活性にする
                                    self.spinnerEnd()
                                    self.authButton.isEnabled = false
                                    self.authButton.alpha = 0.6
                                    self.authButton.setTitle("認証済",for:UIControlState())
                                    return;
                                }
                            }else if value.toString() == "false" {
                                print("false")
                                self.dispatch_async_main{
                                    self.spinnerEnd()
                                    /*
                                    let alertController = UIAlertController(title: "認証エラー", message: "認証に失敗しました。\nライセンス状況を確認してください。", preferredStyle: .alert)
                                    */
                                    let alertController = UIAlertController(title: "認証エラー", message: authErrMessage, preferredStyle: .alert)
                                    
                                    
                                    let OKAction = UIAlertAction(title: "はい", style: .default){
                                        action in
                                        // タップ音
                                        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                                        print("Pushed はい")
                                        return;
                                    }
                                    alertController.addAction(OKAction)
                                    self.present(alertController, animated: true, completion: nil)
                                    return;
                                }
                            }else if value.toString() == "reserve" { // 認証待ち
                                print("reserve")
                                self.dispatch_async_main{

                                    // サーバ認証フラグを2にする
                                    authErrMessageW = authErrMessage
                                    let serverAuth:checkServerAuth = checkServerAuth()
                                    let serverCertification_flag = serverAuth.checkCertification()
                                    if (serverCertification_flag == 0 || serverCertification_flag == 1) {
                                        // メッセージ変数がグローバルのため、退避し、DBにアップデートする
                                        authErrMessage = authErrMessageW
                                        serverAuth.setReserve()
                                    }
                                    
                                    // デモ認証フラグも1にする
                                    let demoAuth:checkDemoAuth = checkDemoAuth()
                                    let certification_flag = demoAuth.checkCertification()
                                    if (certification_flag == 0) {
                                        demoAuth.setCertification()
                                    }
                                    
                                    self.spinnerEnd()
                                    let alertController = UIAlertController(title: "確認", message: authErrMessage, preferredStyle: .alert)
                                    
                                    let OKAction = UIAlertAction(title: "はい", style: .default){
                                        action in
                                        // タップ音
                                        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                                        print("Pushed はい")
                                        return;
                                    }
                                    alertController.addAction(OKAction)
                                    self.present(alertController, animated: true, completion: nil)

                                    // ボタンを非活性にする
                                    self.spinnerEnd()
                                    self.authButton.isEnabled = false
                                    self.authButton.alpha = 0.6
                                    self.authButton.setTitle("認証待",for:UIControlState())
                                    
                                    return;
                                }

                            }
                        }
                    }
                }
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    let initVal = CustomProgressModel()
    
    func dispatch_async_main(_ block: @escaping () -> ()) {
        DispatchQueue.main.async(execute: block)
    }
    
    func dispatch_async_global(_ block: @escaping () -> ()) {
        DispatchQueue.global().async(execute: block)
    }
    
    func spinnerStart() {
        CustomProgress.Instance.title = "受信中..."
        CustomProgress.Create(self.view,initVal: initVal,modeView: EnumModeView.uiActivityIndicatorView)
        //ネットワーク接続中のインジケータを表示
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func spinnerEnd() {
        CustomProgress.Instance.mrprogress.dismiss(true)
        //ネットワーク接続中のインジケータを消去
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
