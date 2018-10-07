//
//  mainmanuViewContoroller.swift
//  iOrder
//
//  Created by 山尾守 on 2016/06/29.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
//import AVFoundation
import FontAwesomeKit
import FMDB
import MIBadgeButton_Swift
import Toast_Swift
import Alamofire

class mainmanuViewController: UIViewController,UINavigationBarDelegate,UIPopoverPresentationControllerDelegate {
    
    fileprivate var onceTokenViewDidAppear: Int = 0
    
    @IBOutlet weak var orderButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var resendButton: MIBadgeButton!
    @IBOutlet weak var staffButton: UIButton!
    @IBOutlet weak var remainingButton: UIButton!
    @IBOutlet weak var inportButton: UIButton!
    @IBOutlet weak var configButton: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var staffNameLabel: UILabel!
    @IBOutlet weak var rightBarButton: UIButton!
    @IBOutlet weak var leftBarButton: UIBarButtonItem!
    
//    @IBOutlet weak var demoLabel: UILabel!
    
    @IBOutlet weak var navBar: UINavigationBar!

    // お客様情報
    struct players_data {
        var shop_code       :Int
        var member_no       :String
        var member_category :Int
        var group_no        :Int
        var player_name_kana:String
        var player_name_kanji:String
        var birthday        :String
        var require_nm      :String
        var sex             :Int
        var message1        :String
        var message2        :String
        var message3        :String
        var price_tanka     :Int
        var status          :Int
        var pm_start_time   :String
        var created         :String
        var modified        :String
    }
    var players:[players_data] = []
    
    struct custmer_data {
        var store_cd:Int
        var kbn:Int64
        var cat1:Int
        var cat2:Int
        var sort_no:Int
        var r:Double
        var g:Double
        var b:Double
        var comment:String
        
        init(store_cd:Int,kbn:Int64,cat1:Int,cat2:Int,sort_no:Int,r:Double,g:Double,b:Double,comment:String){
            self.store_cd = store_cd
            self.kbn = kbn
            self.cat1 = cat1
            self.cat2 = cat2
            self.sort_no = sort_no
            self.r = r
            self.g = g
            self.b = b
            self.comment = comment
        }
    }
    var custmer_store_menu_cd:[custmer_data] = []

    struct menu_data {
        var menu_cd:Int64
        var menu_nm:String
        var store_cd:Int
        var temp_comment:String
        var comment:String
        
        init(menu_cd:Int64,menu_nm:String,store_cd:Int,temp_comment:String,comment:String){
            self.menu_cd = menu_cd
            self.menu_nm = menu_nm
            self.store_cd = store_cd
            self.temp_comment = temp_comment
            self.comment = comment
        }
    }
    var main_menu:[menu_data] = []
    
    struct custmer_sub_tie_data {
        var kbn:Int
        var default_sub_menu_cd:Int
        var menu_cd:Int64
        var sort_no:Int
        
        init(kbn:Int,default_sub_menu_cd:Int,menu_cd:Int64,sort_no:Int){
            self.kbn = kbn
            self.default_sub_menu_cd = default_sub_menu_cd
            self.menu_cd = menu_cd
            self.sort_no = sort_no
        }
    }
    var custmer_sub_menu_tie:[custmer_sub_tie_data] = []
    
    struct sub_menu_data {
        var sub_menu_kbn:Int
        var sub_menu_cd:Int
        var sub_menu_nm:String
        var menu_cd:Int64
        
        init(sub_menu_kbn:Int,sub_menu_cd:Int,sub_menu_nm:String,menu_cd:Int64){
            self.sub_menu_kbn = sub_menu_kbn
            self.sub_menu_cd = sub_menu_cd
            self.sub_menu_nm = sub_menu_nm
            self.menu_cd = menu_cd
        }
    }
    var custmer_sub_menu:[sub_menu_data] = []
    
    struct menu_price_data {
        var menu_cd:Int64
        var unit_price_kbn:Int
        var selling_price:Int
        
        init(menu_cd:Int64,unit_price_kbn:Int,selling_price:Int){
            self.menu_cd = menu_cd
            self.unit_price_kbn = unit_price_kbn
            self.selling_price = selling_price
        }
    }
    var custmer_menu_price:[menu_price_data] = []
    
    struct sp_menu_data{
        var spe_menu_cd:Int
        var spe_menu_nm:String
        var spe_menu_kbn:Int
        var store_cd:Int
        var menu_cd:Int64
        var r:Double
        var g:Double
        var b:Double
        init(spe_menu_cd:Int,spe_menu_nm:String,spe_menu_kbn:Int,store_cd:Int,menu_cd:Int64,r:Double,g:Double,b:Double){
            self.spe_menu_cd = spe_menu_cd
            self.spe_menu_nm = spe_menu_nm
            self.spe_menu_kbn = spe_menu_kbn
            self.store_cd = store_cd
            self.menu_cd = menu_cd
            self.r = r
            self.g = g
            self.b = b
        }
    }
    var special_menu:[sp_menu_data] = []
    
    struct seat_master_data {
        var table_no:Int
        var seat_no:Int
        var seat_nm:String
        var disp_position:Int
        var seat_kbn:Int
        
        init(table_no:Int,seat_no:Int,seat_nm:String,disp_position:Int,seat_kbn:Int){
            self.table_no = table_no
            self.seat_no = seat_no
            self.seat_nm = seat_nm
            self.disp_position = disp_position
            self.seat_kbn = seat_kbn
        }
    }
    var seat_master:[seat_master_data] = []
    
    struct table_master_data {
        var table_no:Int
        var table_nm:String
        var seat_nm:Int
        var section:Int
        
        init(table_no:Int,table_nm:String,seat_nm:Int,section:Int) {
            self.table_no = table_no
            self.table_nm = table_nm
            self.seat_nm = seat_nm
            self.section = section
        }
    }
    var table_master:[table_master_data] = []
    
    
    fileprivate var actInd : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0,y: 0, width: 150, height: 150)) as UIActivityIndicatorView
    
    var timer : Timer!
    var iTimer : Int = 0
    
    // Segue名
    let segue = ["toTableNoInputViewSegue",
                 "toCancelTableNoViewSegue",
                 "toResendingViewSegue",
                 "toStaffNoInputViewSegue",
                 "toReminingCountMenuSelectViewSegue",
                 "",
                 ""
//                 "toConfigViewSege"
    ]
    
    let interval:Float = 1/17
    
    
    //CustomProgressModelにあるプロパティが初期設定項目
    let initVal = CustomProgressModel()
    
    // DBファイルパス
    var _path:String = ""
    var _path_demo:String = ""
        
    var logoImageView: UIImageView!
    
    var is_not_resend_alert_disp = false
    
    var alamofireManager : Alamofire.SessionManager?
    let configuration = URLSessionConfiguration.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.exclusiveAllTouches()
        
        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor
        
        iTimer = 0
        
        // 通信タイムアウトの設定
        configuration.timeoutIntervalForResource = 10 // seconds

        let mp = makePassword()
        print(mp.check())
        
        //imageView作成
        self.view.backgroundColor = iOrder_titleBlueColor
        
        let myBoundSize: CGSize = UIScreen.main.bounds.size
        self.logoImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: myBoundSize.width, height: myBoundSize.height))
        //画面centerに
        self.logoImageView.center = self.view.center
        //logo設定
        self.logoImageView.image = UIImage(named: "Defaults-1024h")
        self.logoImageView.contentMode = UIViewContentMode.scaleAspectFill
        //viewに追加
        self.view.addSubview(self.logoImageView)
        
        
        // ボタンアイコン
        let iconImage:[FAKFontAwesome] = [
            .cutleryIcon(withSize: iconSize),
            .banIcon(withSize: iconSize),
            .repeatIcon(withSize: iconSize),
            .userIcon(withSize: iconSize),
            .cloudIcon(withSize: iconSize),
            .downloadIcon(withSize: iconSize),
            .signOutIcon(withSize: iconSize),
            ]

        
        // ボタンに画像をセットする
        var menuButton = [orderButton,cancelButton,resendButton,staffButton,remainingButton,inportButton,configButton]
        
        for num in 0..<7 {
            let button :UIButton = menuButton[num]!
            
            // 下記でアイコンの色も変えられます
            if num == 0 {
                iconImage[num].addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
                
            } else {
                iconImage[num].addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    button.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
                    button.titleEdgeInsets = UIEdgeInsetsMake(0,0, 0, 0)
                    button.imageEdgeInsets = UIEdgeInsetsMake(0, -20.0, 0, 0)
                } else {
                    switch num {
                    case 1:
                        button.contentEdgeInsets = UIEdgeInsetsMake(0, 10.0, 0, 0)
                        button.titleEdgeInsets = UIEdgeInsetsMake(40.0, -30.0, 0, 0)
                        button.imageEdgeInsets = UIEdgeInsetsMake(-30, 0, 0, -65)
                        
                        break
                    case 2:
                        button.contentEdgeInsets = UIEdgeInsetsMake(0, 10.0, 0, 0)
                        button.titleEdgeInsets = UIEdgeInsetsMake(40.0, -30.0, 0, 0)
                        button.imageEdgeInsets = UIEdgeInsetsMake(-30, 0, 0, -65)
                        break
                    case 3:
                        button.contentEdgeInsets = UIEdgeInsetsMake(0, 10.0, 0, 0)
                        button.titleEdgeInsets = UIEdgeInsetsMake(40.0, -30.0, 0, 0)
                        button.imageEdgeInsets = UIEdgeInsetsMake(-30, 0, 0, -100)
                        break
                    case 4:
                        button.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
                        button.titleEdgeInsets = UIEdgeInsetsMake(40.0, -15.0, 0, 15)
                        button.imageEdgeInsets = UIEdgeInsetsMake(-30, 45.0, 0, -55)
                        break
                    case 5:
                        button.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
                        button.titleEdgeInsets = UIEdgeInsetsMake(40.0, -15.0, 0, 15)
                        button.imageEdgeInsets = UIEdgeInsetsMake(-30, 45.0, 0, -55)

                        break
                    case 6:
                        button.contentEdgeInsets = UIEdgeInsetsMake(0, 10.0, 0, 0)
                        button.titleEdgeInsets = UIEdgeInsetsMake(40.0, -15.0, 0, 15)
                        button.imageEdgeInsets = UIEdgeInsetsMake(-30, 20, 0, -30)
                        break
                    default:
                        break
                    }
                    
                    
                }
                
            }
            //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
            let Image = iconImage[num].image(with: CGSize(width: iconSize, height: iconSize))
            button.setImage(Image, for: UIControlState())
            button.addTarget(self, action: #selector(mainmanuViewController.buttonTap), for: .touchUpInside)
            // 影をつけて立体的に見せる
            button.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
            button.layer.shadowOpacity = 0.3
            
        }
        
        let iconImage2 = FAKFontAwesome.cogIcon(withSize: iconSize)
        iconImage2?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image = iconImage2?.image(with: CGSize(width: iconSize, height: iconSize))
        rightBarButton.setImage(Image, for: UIControlState())

        // 注文取消し可否で４（常に不可）の場合のみボタンを、押せなくする
        if is_oder_cancel == 4 {
            cancelButton.isEnabled = false
            cancelButton.setTitleColor(UIColor.lightText, for: .disabled)
            cancelButton.alpha = 0.6
        }

        
        // バージョン表示
//        self.versionLabel.text = "Ver:" + ("\(version)") + "  build:" + build
        self.versionLabel.text = "Ver:" + ("\(version)")
        
        // デモモード確認
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        _path = (paths[0] as NSString).appendingPathComponent(production_db)
        _path_demo = (paths[0] as NSString).appendingPathComponent(demo_db)
        print(_path)
        
        // FMDatabaseクラスのインスタンスを作成
        // 引数にファイルまでのパスを渡す
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        let sql = "SELECT count(*) FROM app_config;"
        
        let results = db.executeQuery(sql, withArgumentsIn: [])
        while (results?.next())! {
            // カラムのインデックスを指定して取得
            let data_count = results?.int(forColumnIndex:0)
            // DB未登録の場合、デフォルト値を設定する
            if data_count! <= 0 {
                var argumentArray:Array<Any> = []
                let now = Date() // 現在日時の取得
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                dateFormatter.timeStyle = .medium
                dateFormatter.dateStyle = .medium
                        
                let created = dateFormatter.string(from: now)
                let modified = dateFormatter.string(from: now)
                argumentArray.append("1")
                argumentArray.append(created)
                argumentArray.append(modified)
                        
                let sql_insert = "INSERT INTO app_config (shop_code,created,modified) VALUES (?,?,?);"
                        
                // INSERT文を実行
                let success = db.executeUpdate(sql_insert, withArgumentsIn: argumentArray)
                if !success {
                    // エラー時
                    print(success.description)
                }
            } else {
                let sql_select = "SELECT * FROM app_config;"
                let results_select = db.executeQuery(sql_select, withArgumentsIn: [])
                while (results_select?.next())! {
                    demo_mode = Int((results_select?.int(forColumn:"is_demo"))!)
                    
                    guide_mode = Int((results_select?.int(forColumn:"is_guide"))!)
                    first_disp_new = Int((results_select?.int(forColumn:"new_order_category_DEFAULT"))!)
                    first_disp_add = Int((results_select?.int(forColumn:"add_order_category_DEFAULT"))!)
                    hand_write_mode = Int((results_select?.int(forColumn:"is_handwrite"))!)
                    search_mode = Int((results_select?.int(forColumn:"is_search"))!)
                    shop_code = Int((results_select?.string(forColumn:"shop_code"))!)!
                    
                    // 表示設定
                    disp_row_height = Int((results_select?.int(forColumn:"row_height"))!)
                    furigana = Int((results_select?.int(forColumn:"is_kana_show"))!)
                    cost_disp = Int((results_select?.int(forColumn:"is_price"))!)
                    text_size = Int((results_select?.int(forColumn:"is_holder_show_large"))!)
                    animation = Int((results_select?.int(forColumn:"is_animation"))!)
                    grid_disp = Int((results_select?.int(forColumn:"is_grid"))!)
                    
                    // サウンド設定
                    tap_sound = Int((results_select?.int(forColumn:"is_tapsound"))!)
                    err_sound = Int((results_select?.int(forColumn:"is_errorbeep"))!)
                    top_sound = Int((results_select?.int(forColumn:"topreturn_sound"))!)
                    not_send_alert.sound_interval = Int((results_select?.int(forColumn:"is_senddata"))!)
                    not_send_alert.sound_no = Int((results_select?.int(forColumn:"is_senddata_sound"))!)
                    not_send_alert.interval = Int((results_select?.int(forColumn:"is_senddata_interval"))!)
                    
                    data_not_send_alert.sound_interval = Int((results_select?.int(forColumn:"is_senderror"))!)
                    data_not_send_alert.sound_no = Int((results_select?.int(forColumn:"is_senderror_sound"))!)
                    data_not_send_alert.interval = Int((results_select?.int(forColumn:"is_senderror_interval"))!)
                    
                    order_start2end_alert.sound_interval = Int((results_select?.int(forColumn:"is_order_s2e"))!)
                    order_start2end_alert.sound_no = Int((results_select?.int(forColumn:"is_order_s2e_sound"))!)
                    order_start2end_alert.interval = Int((results_select?.int(forColumn:"is_order_s2e_interval"))!)
                    // OS通知
                    notification = Int((results_select?.int(forColumn:"is_bbsinfo"))!)
                    notification_centre = Int((results_select?.int(forColumn:"is_bbsinfocenter"))!)
                    notification_sound = Int((results_select?.int(forColumn:"is_bbssound"))!)
                    notification_badge = Int((results_select?.int(forColumn:"is_bbsbadge"))!)
                    notification_lock = Int((results_select?.int(forColumn:"is_bbslock"))!)
                    
                    is_timezone = Int((results_select?.int(forColumn:"is_timezone"))!)
                }
                for i in 0..<configtableData.count {
                    for j in 0..<configtableData[i].count {
                        switch configtableData[i][j].item {
                        case "is_demo":
                            configtableData[i][j].defaultNo = demo_mode
                            break;
                        case "is_guide":
                            configtableData[i][j].defaultNo = guide_mode
                            break;
                        case "new_order_category_DEFAULT" :
                            configtableData[i][j].defaultNo = first_disp_new
                            break;
                        case "add_order_category_DEFAULT":
                            configtableData[i][j].defaultNo = first_disp_add
                            break;
                        case "is_handwrite":
                            configtableData[i][j].defaultNo = hand_write_mode
                            break;
                        case "is_search":
                            configtableData[i][j].defaultNo = search_mode
                            break;
                        case "row_height":
                            configtableData[i][j].defaultNo = disp_row_height
                            break;
                        case "is_kana_show":
                            configtableData[i][j].defaultNo = furigana
                            break;
                        case "is_price":
                            configtableData[i][j].defaultNo = cost_disp
                            break;
                        case "is_holder_show_large":
                            configtableData[i][j].defaultNo = text_size
                            break;
                        case "is_animation":
                            configtableData[i][j].defaultNo = animation
                            break;
                        case "is_grid":
                            configtableData[i][j].defaultNo = grid_disp
                            break;
                        case "is_tapsound":
                            configtableData[i][j].defaultNo = tap_sound
                            break;
                        case "is_errorbeep":
                            configtableData[i][j].defaultNo = err_sound
                            break;
                        case "topreturn_sound":
                            configtableData[i][j].defaultNo = top_sound
                            break;
                        case "is_senddata":
                            configtableData[i][j].defaultNo =  not_send_alert.sound_interval
                            break;
                        case "is_senderror":
                            configtableData[i][j].defaultNo = data_not_send_alert.sound_interval
                            break;
                        case "is_order_s2e":
                            configtableData[i][j].defaultNo = order_start2end_alert.sound_interval
                            break;
                        case "is_bbsinfo":
                            configtableData[i][j].defaultNo = notification
                            break;
                        case "is_bbsinfocenter":
                            configtableData[i][j].defaultNo = notification_centre
                            break;
                        case "is_bbssound":
                            configtableData[i][j].defaultNo = notification_sound
                            break;
                        case "is_bbsbadge":
                            configtableData[i][j].defaultNo = notification_badge
                            break;
                        case "is_bbslock":
                            configtableData[i][j].defaultNo = notification_lock
                            break;
                        case "license":
                            break;
                        case "version":
                            break;
                        case "shop_code":
                            configtableData[i][j].defaultNo = shop_code
                            break;
                        default:
                            break;
                        }
                        
                    }
                }
                
            }
        }
    
        let setup_key = ["TABLET_MINUS_QTY","TABLET_ORDER_CANCEL","TABLET_ORDER_WAITING","TABLET_PAYER_ALLOCATION","TABLET_TICKET_AUTOLINK","TABLET_TIME_ZONE","TABLET_ITEM_PRICE_KBN"]
        let sql1 = "SELECT * FROM pc_config WHERE setup_key = ?;"
        
        for (i,key) in setup_key.enumerated() {
            
            let results1 = db.executeQuery(sql1, withArgumentsIn: [key])
            while (results1?.next())! {
                switch i {
                case 0: is_minus_qty        = Int((results1?.int(forColumn:"value"))!)
                case 1: is_oder_cancel      = Int((results1?.int(forColumn:"value"))!)
                case 2: is_order_wait       = Int((results1?.int(forColumn:"value"))!)
                case 3: is_payer_allocation = Int((results1?.int(forColumn:"value"))!)
                case 4: is_ticket_autolink  = Int((results1?.int(forColumn:"value"))!)
                case 5: is_timezone         = Int((results1?.int(forColumn:"value"))!)
                case 6: is_unit_price_kbn   = Int((results1?.int(forColumn:"value"))!)
                default: break;
                }
            }
        }
        
        db.close()

        // サウンドファイル取得
        let sound_no = [tap_sound,err_sound,top_sound,not_send_alert.sound_no,data_not_send_alert.sound_no,order_start2end_alert.sound_no]
//        var sound_file = [tap_sound_file,err_sound_file,top_sound_file,not_send_alert_file,data_not_send_alert_file]
        db.open()
        // 操作音
        for i in 0..<sound_no.count {
            let sql_sound = "select * from app_config_sound where sound_no = ?;"
            let rs_sound = db.executeQuery(sql_sound, withArgumentsIn: [sound_no[i]])
            while (rs_sound?.next())! {
                switch i {
                case 0:
                    tap_sound_file.sound_file = (rs_sound?.string(forColumn:"sound_file"))!
                    tap_sound_file.file_type = (rs_sound?.string(forColumn:"file_type"))!
                case 1:
                    err_sound_file.sound_file = (rs_sound?.string(forColumn:"sound_file")!)!
                    err_sound_file.file_type = (rs_sound?.string(forColumn:"file_type"))!
                case 2:
                    top_sound_file.sound_file = (rs_sound?.string(forColumn:"sound_file"))!
                    top_sound_file.file_type = (rs_sound?.string(forColumn:"file_type"))!
                case 3:
                    not_send_alert_file.sound_file = (rs_sound?.string(forColumn:"sound_file"))!
                    not_send_alert_file.file_type = (rs_sound?.string(forColumn:"file_type"))!
                case 4:
                    data_not_send_alert_file.sound_file = (rs_sound?.string(forColumn:"sound_file"))!
                    data_not_send_alert_file.file_type = (rs_sound?.string(forColumn:"file_type"))!
                case 5:
                    order_start2end_alert_file.sound_file = (rs_sound?.string(forColumn:"sound_file"))!
                    order_start2end_alert_file.file_type = (rs_sound?.string(forColumn:"file_type"))!
                default:
                    break
                }
            }
        }
        db.close()

        let notiSettings = UIUserNotificationSettings(types:[.badge], categories:nil)
        UIApplication.shared.registerUserNotificationSettings(notiSettings)
        UIApplication.shared.registerForRemoteNotifications()
        
        //ローカル通知
//        let notification = UILocalNotification()
//        //ロック中にスライドで〜〜のところの文字
//        notification.alertAction = "アプリを開く"
//        notification.alertTitle = "テスト"
//        //通知の本文
//        notification.alertBody = "ごはんたべよう！"
//        //通知される時間（とりあえず10秒後に設定）
//        notification.fireDate = NSDate(timeIntervalSinceNow:10)
//        //通知音
//        notification.soundName = UILocalNotificationDefaultSoundName
        //アインコンバッジの数字
        UIApplication.shared.applicationIconBadgeNumber = 1

        
        TapSound.buttonTap("spo_ge_golf_cup01", type: "mp3")

    }
    
    override func viewDidAppear(_ animated: Bool) {
        //少し縮小するアニメーション
        UIView.animate(withDuration: 0.3,
                                   delay: 1.0,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: { () in
                                    self.logoImageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }, completion: { (Bool) in
                
        })
        
        //拡大させて、消えるアニメーション
        UIView.animate(withDuration: 0.2,
                                   delay: 1.3,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: { () in
                                    self.logoImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                                    self.logoImageView.alpha = 0
            }, completion: { (Bool) in
                self.logoImageView.removeFromSuperview()
                self.view.backgroundColor = UIColor.white

                // すべてが表示された後にバッジを表示させる
                DemoLabel.Show(self.view)
                DemoLabel.modeChange()

        })
        
        
        
        let notiSettings = UIUserNotificationSettings(types:[.badge], categories:nil)
        UIApplication.shared.registerUserNotificationSettings(notiSettings)
        UIApplication.shared.registerForRemoteNotifications()
        

        
        // 使用DB
        let use_db = demo_mode != 0 ? demo_db : production_db
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        let _path = (paths[0] as NSString).appendingPathComponent(use_db)
        
        //        print(_path)
        // FMDatabaseクラスのインスタンスを作成
        // 引数にファイルまでのパスを渡す
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        var resending_count = 0
        let sql = "SELECT count(*) FROM resending WHERE resend_kbn in (1,2);"
        let results = db.executeQuery(sql, withArgumentsIn: [])
        while (results?.next())! {
            resending_count = Int((results?.int(forColumnIndex:0))!)
        }
        
        if resending_count > 0 {
            //アインコンバッジの数字
            UIApplication.shared.applicationIconBadgeNumber = resending_count

            resendButton.badgeString = "\(resending_count)"
            if not_send_alert.sound_interval > 0 {
                if order_resend_time <= 0 && order_time <= 0 {
                    if !(order_resend_timer.isValid) {
                        is_not_resend_alert_disp = true
                        updating_resend()
                    }
                    
                }
                
            }
        } else {
            //アインコンバッジの数字
            UIApplication.shared.applicationIconBadgeNumber = 0
            resendButton.badgeString = ""
            
            is_not_resend_alert_disp = true
            
            // タイマー破棄
            if order_resend_timer.isValid {
                // タイマーをリセット
                order_time = 0
                order_resend_time = 0
                order_resend_timer.invalidate()
            }
            
        }
        

        // データのクリア
        common.clear()
//        select_menu_categories = []
//        Section = []
//        MainMenu = []
//        SubMenu = []
//        SpecialMenu = []
        fmdb.remove_hand_image()
        globals_pm_start_time = ""
        
        // 注文取消し可否で４（常に不可）の場合のみボタンを、押せなくする
        if is_oder_cancel == 4 {
            cancelButton.isEnabled = false
            cancelButton.setTitleColor(UIColor.lightText, for: .disabled)
            cancelButton.alpha = 0.6
        } else {
//            cancelButton.enabled = true
//            cancelButton.setTitleColor(UIColor.darkGrayColor(), forState: .Disabled)
//            cancelButton.alpha = 1.0
        }

        staff_name_disp()
        
        // オーダー押下から5分でエラーのタイマーはメインメニューに戻った時点でリセットする。
        if order_timer.isValid == true {
            
            //timerを破棄する.
            order_timer.invalidate()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // ステータスバーとナビゲーションバーの色を同じにする
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
    // ステータスバーの文字を白にする
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func buttonTap(_ sender: UIButton) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.sound_file, type: tap_sound_file.file_type)
        
        switch sender.tag {
        case 3:         // 再送信ボタン
            
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
            
            //        print(_path)
            // FMDatabaseクラスのインスタンスを作成
            // 引数にファイルまでのパスを渡す
            let db = FMDatabase(path: _path)
            
            // データベースをオープン
            db.open()
            
            var resending_count = 0
            let sql = "SELECT count(*) FROM resending WHERE resend_kbn in (1,2);"
            let results = db.executeQuery(sql, withArgumentsIn: [])
            while (results?.next())! {
                resending_count = Int((results?.int(forColumnIndex:0))!)
            }

            if resending_count <= 0 {
                // 確認のアラート画面を出す
                // タイトル
                let alert: UIAlertController = UIAlertController(title: "エラー", message: "未送信のデータはありません", preferredStyle: UIAlertControllerStyle.alert)
                // アクションの設定
                let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) -> Void in
                    print("OK")
                })
                
                // UIAlertControllerにActionを追加
                alert.addAction(defaultAction)
                
                // Alertを表示
                present(alert, animated: true, completion: nil)

            } else {
                self.performSegue(withIdentifier: self.segue[sender.tag - 1],sender: nil)
            }
        
        case 2,5:         // 取消し、残数登録
            // 残数取得
            if demo_mode == 0 {  // 本番モードのときだけ
                self.spinnerStart2()
                
                // 残数取得
                self.dispatch_async_global{
                    let json = JSON(url:urlString + "RemainNumSend?Store_CD=" + shop_code.description)
//                    print(json)
                    if json.asError == nil {
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
                        // データベースをオープン
                        db.open()
                        
                        var sql = "DELETE FROM items_remaining;"
                        let _ = db.executeUpdate(sql, withArgumentsIn: [])
                        
                        
                        sql = "INSERT INTO items_remaining (item_no , remaining_count, created , modified) VALUES (?,?,?,?);"
                        
                        let now = Date() // 現在日時の取得
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                        dateFormatter.timeStyle = .medium
                        dateFormatter.dateStyle = .medium
                        
                        let created = dateFormatter.string(from: now)
                        let modified = created

                        for (_,remain) in json["t_remain_num"]{
                            var argumentArray:Array<Any> = []
                            
                            if remain["menu_cd"].type == "Int" && remain["remain_num"].type == "Int" {
                                argumentArray.append(NSNumber(value: remain["menu_cd"].asInt64! as Int64))
                                argumentArray.append(remain["remain_num"].asInt!)
                                
                                argumentArray.append(created)
                                argumentArray.append(modified)
                                
                                db.beginTransaction()
                                let success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                                if !success {
                                    print("insert error!!")
                                }
                                db.commit()
                            }
                        }
                        db.close()
                        self.dispatch_async_main{
                            self.spinnerEnd2()
                            self.performSegue(withIdentifier: self.segue[sender.tag - 1],sender: nil)
                        }
                        
                    } else {
                        self.dispatch_async_main{
                            // エラー音
                            TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)
                            self.spinnerEnd2()
                            let e = json.asError
                            self.jsonError()
                            print(e as Any)
                            self.performSegue(withIdentifier: self.segue[sender.tag - 1],sender: nil)
                            
                        }
                    }
                    
                }

            } else {
                self.performSegue(withIdentifier: self.segue[sender.tag - 1],sender: nil)

            }
            
        case 4: //担当者設定ボタン ooishi
           
            // ooishi
            // デモモード認証
            let demoAuth:checkDemoAuth = checkDemoAuth()
            var certification_flag = 0
            if (demo_mode == 2) {
                certification_flag = demoAuth.checkCertification()
            }

            // デモモード（デモデータ使用）
            if (demo_mode == 2 && certification_flag == 0) { // デモ未認証

                let alertDemo:UIAlertController = UIAlertController(title:"デモモード認証",message: "デモモード使用のためのパスワードを入力してください。",preferredStyle: UIAlertControllerStyle.alert)
                let cancelActionDemo:UIAlertAction = UIAlertAction(title: "キャンセル",style: UIAlertActionStyle.cancel,handler:{(action:UIAlertAction!) ->
                    Void in
                    print("Cancel")
                })
                let defaultActionDemo:UIAlertAction = UIAlertAction(title: "OK",style: UIAlertActionStyle.default,handler:{(action:UIAlertAction!) ->
                    Void in
                    print("OK")
                    
                    // パスワードの判定
                    var passtxt:String = ""
                    let textFields2:Array<UITextField>? =  alertDemo.textFields as Array<UITextField>?
                    for textField:UITextField in textFields2! {
                        passtxt = textField.text!
                    }
                    let mp = makePassword()
                    
                    // 認証OKの場合、認証フラグを1にする
                    if passtxt == mp.check(){
                        demoAuth.setCertification()
                        
                        // 画面遷移
                        self.performSegue(withIdentifier: "toStaffNoInputViewSegue",sender: nil)
                        
                    }else{
                        // パスが異なる場合
                        let alert3:UIAlertController = UIAlertController(title:"デモモード認証",message: "パスワードが間違っています。",preferredStyle: UIAlertControllerStyle.alert)
                        let defaultAction3:UIAlertAction = UIAlertAction(title: "OK",style: UIAlertActionStyle.default,handler:{(action:UIAlertAction!) ->
                            Void in
                            print("OK")
                        })
                        alert3.addAction(defaultAction3)
                        self.present(alert3, animated: true, completion: nil)
                    }
                })
                alertDemo.addAction(cancelActionDemo)
                alertDemo.addAction(defaultActionDemo)
                //textfiledの追加
                alertDemo.addTextField(configurationHandler: {(alertText:UITextField!) -> Void in
                    // キーボードは数字のみ
                    alertText.keyboardType = .numberPad
                    alertText.isSecureTextEntry = true
                })
                present(alertDemo, animated: true, completion: nil)

            
            }else if(demo_mode == 2 && certification_flag == 1 ) { // デモ認証済

                // 画面遷移
                self.performSegue(withIdentifier: "toStaffNoInputViewSegue",sender: nil)
                
                
            }else{ // 本番モード
                
                // ooishi
                // 認証確認
                let serverAuth:checkServerAuth = checkServerAuth()
                let serverCertification_flag = serverAuth.checkCertification()
                if (serverCertification_flag == 0 || serverCertification_flag == 2) { // 未認証、または認証待ちの場合
                    /*
                    let alert3:UIAlertController = UIAlertController(title:"認証エラー",message: "認証されていません。\n設定画面から認証ボタンを\nタップしてください。",preferredStyle: UIAlertControllerStyle.alert)
                    */
                    let alert3:UIAlertController = UIAlertController(title:"認証エラー",message: authErrMessage,preferredStyle: UIAlertControllerStyle.alert)
                    
                    let defaultAction3:UIAlertAction = UIAlertAction(title: "OK",style: UIAlertActionStyle.default,handler:{(action:UIAlertAction!) ->
                        Void in
                        print("OK")
                    })
                    alert3.addAction(defaultAction3)
                    self.present(alert3, animated: true, completion: nil)
                
                }else{ // 認証済みの場合
                    
                    // 担当者画面遷移
                    self.performSegue(withIdentifier: "toStaffNoInputViewSegue",sender: nil)
                }
            }
        
        case 6: // データ取り込み
            
            // ooishi
            // デモモード認証
            let demoAuth:checkDemoAuth = checkDemoAuth()
            var certification_flag = 0
            if (demo_mode == 2) {
                certification_flag = demoAuth.checkCertification()
            }
            
            // デモモード（デモデータ使用）データ認証アラート表示
            if (demo_mode == 2 && certification_flag == 0) { // デモモード且つ、未認証の場合
                let alert1:UIAlertController = UIAlertController(title:"デモモード認証",message: "デモモード使用のためのパスワードを入力してください。",preferredStyle: UIAlertControllerStyle.alert)
                let cancelAction1:UIAlertAction = UIAlertAction(title: "キャンセル",style: UIAlertActionStyle.cancel,handler:{(action:UIAlertAction!) ->
                    Void in
                    print("Cancel")
                })
                let defaultAction1:UIAlertAction = UIAlertAction(title: "OK",style: UIAlertActionStyle.default,handler:{(action:UIAlertAction!) ->
                    Void in
                    print("OK")
                    
                    // 入力値を取得
                    var passtxt:String = ""
                    let textFields2:Array<UITextField>? =  alert1.textFields as Array<UITextField>?
                    for textField:UITextField in textFields2! {
                        passtxt = textField.text!
                    }
                    
                    // パスワード生成
                    let mp = makePassword()
                    print(mp.check())
                    
                    // パスワード判定
                    if passtxt == mp.check(){
                        
                        // 認証OKの場合、認証フラグを1にする
                        demoAuth.setCertification()
                        
                        // デモデータ取り込みの確認アラート画面を出す
                        let alert: UIAlertController = UIAlertController(title: "データを取り込み直します", message: "よろしいですか？", preferredStyle: UIAlertControllerStyle.alert)
                        // アクションの設定
                        let defaultAction: UIAlertAction = UIAlertAction(title: "確定", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) -> Void in
                            // タップ音
                            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                            // デモデータ取り込み
                            self.getDemoData()
                            
                        })
                        // キャンセルボタン
                        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler: {(action: UIAlertAction!) -> Void in
                            // タップ音
                            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                            //　print("キャンセル")
                        })
                        
                        // Alertを表示
                        alert.addAction(cancelAction)
                        alert.addAction(defaultAction)
                        self.present(alert, animated: true, completion: nil)
                    }else{
                        // パスワードが異なる場合
                        let alert3:UIAlertController = UIAlertController(title:"デモモード認証",message: "パスワードが間違っています。",preferredStyle: UIAlertControllerStyle.alert)
                        let defaultAction3:UIAlertAction = UIAlertAction(title: "OK",style: UIAlertActionStyle.default,handler:{(action:UIAlertAction!) ->
                            Void in
                            print("OK")
                        })
                        alert3.addAction(defaultAction3)
                        self.present(alert3, animated: true, completion: nil)
                    }
                })
                //アラートにボタンとtextfiledの追加
                alert1.addAction(cancelAction1)
                alert1.addAction(defaultAction1)
                alert1.addTextField(configurationHandler: {(alertText:UITextField!) -> Void in
                    alertText.keyboardType = .numberPad // キーボードは数字のみ
                    alertText.isSecureTextEntry = true
                })
                present(alert1, animated: true, completion: nil)
            }
            
            // 認証済みの場合、データ取り込みの確認のアラート画面を出す
            // タイトル
            let alert: UIAlertController = UIAlertController(title: "データを取り込み直します", message: "よろしいですか？", preferredStyle: UIAlertControllerStyle.alert)
            // アクションの設定
            let defaultAction: UIAlertAction = UIAlertAction(title: "確定", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) -> Void in
                
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                
                // デモモード（デモデータ使用）
                if demo_mode == 2 {
                    
                    self.getDemoData()
                    
                    // 本番モード
                } else if demo_mode == 0 || demo_mode == 1 {
                   
                    // ooishi
                    // 認証確認
                    let serverAuth:checkServerAuth = checkServerAuth()
                    let serverCertification_flag = serverAuth.checkCertification()
                    if (serverCertification_flag == 0 || serverCertification_flag == 2) { // 未認証の場合
                        /*
                        let alert3:UIAlertController = UIAlertController(title:"認証エラー",message: "認証されていません。\n設定画面から認証ボタンを\nタップしてください。",preferredStyle: UIAlertControllerStyle.alert)
                        */
                        
                        let alert3:UIAlertController = UIAlertController(title:"認証エラー",message: authErrMessage,preferredStyle: UIAlertControllerStyle.alert)
                        
                        let defaultAction3:UIAlertAction = UIAlertAction(title: "OK",style: UIAlertActionStyle.default,handler:{(action:UIAlertAction!) ->
                            Void in
                            print("OK")
                        
                            //ログオフ状態
                            self.staff_logoff()

                        })
                        alert3.addAction(defaultAction3)
                        self.present(alert3, animated: true, completion: nil)
                        
                        
                    /*
                    }else if (serverCertification_flag == 2) { // 認証待ちの場合
                        
                        let alert3:UIAlertController = UIAlertController(title: "確認",message: authErrMessage,preferredStyle: UIAlertControllerStyle.alert)
                        
                        let defaultAction3:UIAlertAction = UIAlertAction(title: "OK",style: UIAlertActionStyle.default,handler:{(action:UIAlertAction!) ->
                            Void in
                            print("OK")
                            
                            //ログオフ状態
                            self.staff_logoff()
                            
                        })
                        alert3.addAction(defaultAction3)
                        self.present(alert3, animated: true, completion: nil)
                    */

                    }else{ // 認証済みの場合
                        if demo_mode == 0 {
                            self.JsonGet_serverAuth()
                        } else {
                            // デモモード（取込データ使用）
                            CustomProgress.Create(self.view,initVal: self.initVal,modeView: EnumModeView.mrCircularProgressView)
                            
                            // デモDBリネーム
                            let paths = NSSearchPathForDirectoriesInDomains(
                                .documentDirectory,
                                .userDomainMask, true)
                            let oldPath: String = self._path_demo
                            let newPath: String = (paths[0] as NSString).appendingPathComponent("iOrder2_demo_back.db")
                            let manager: FileManager = .default
                            try! manager.moveItem(atPath: oldPath, toPath: newPath)
                            
                            let delay = 0.5 * Double(NSEC_PER_SEC)
                            let time  = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                                CustomProgress.Instance.progressChange += 0.3
                            })
                            
                            // 本番DBコピー
                            try! manager.copyItem(atPath: self._path, toPath: self._path_demo)
                            
                            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                                CustomProgress.Instance.progressChange += 0.3
                            })
                            
                            // リネームDB削除
                            try! manager.removeItem(atPath: newPath)
                            
                            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                                CustomProgress.Instance.progressChange += 0.4
                            })
                            
                            self.spinnerEnd()
                        }
                    }
                    // デモモード（取込データ使用）
//                } else if demo_mode == 1  {
//                    CustomProgress.Create(self.view,initVal: self.initVal,modeView: EnumModeView.mrCircularProgressView)
//                    
//                    // デモDBリネーム
//                    let paths = NSSearchPathForDirectoriesInDomains(
//                        .documentDirectory,
//                        .userDomainMask, true)
//                    let oldPath: String = self._path_demo
//                    let newPath: String = (paths[0] as NSString).appendingPathComponent("iOrder2_demo_back.db")
//                    let manager: FileManager = .default
//                    try! manager.moveItem(atPath: oldPath, toPath: newPath)
//                    
//                    let delay = 0.5 * Double(NSEC_PER_SEC)
//                    let time  = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
//                    DispatchQueue.main.asyncAfter(deadline: time, execute: {
//                        CustomProgress.Instance.progressChange += 0.3
//                    })
//                    
//                    // 本番DBコピー
//                    try! manager.copyItem(atPath: self._path, toPath: self._path_demo)
//                    
//                    DispatchQueue.main.asyncAfter(deadline: time, execute: {
//                        CustomProgress.Instance.progressChange += 0.3
//                    })
//                    
//                    // リネームDB削除
//                    try! manager.removeItem(atPath: newPath)
//                    
//                    DispatchQueue.main.asyncAfter(deadline: time, execute: {
//                        CustomProgress.Instance.progressChange += 0.4
//                    })
//                    
//                    self.spinnerEnd()
                }
                
            })
            // キャンセルボタン
            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler: {(action: UIAlertAction!) -> Void in
                
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                
                //            print("キャンセル")
            })
            
            // UIAlertControllerにActionを追加
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            
            // Alertを表示
            present(alert, animated: true, completion: nil)
        case 7:
            // 終了ボタンタップ
            
            // 確認のアラート画面を出す
            // タイトル
            let alert: UIAlertController = UIAlertController(title: "確認", message: "ログオフします。よろしいですか？", preferredStyle: UIAlertControllerStyle.alert)
            // アクションの設定
            let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) -> Void in
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

                print("OK")
                // スタッフをログオフする。
                self.staff_logoff()
                
            })
            // キャンセルボタン
            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler: {(action: UIAlertAction!) -> Void in
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

                print("キャンセル")
            })
            
            // UIAlertControllerにActionを追加
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            
            // Alertを表示
            present(alert, animated: true, completion: nil)
            
        default:
            if sender.tag == 1 {
                //バックグラウンドでも実行したい処理
                updating()
                order_time = 0
                is_alert_disp = true
            }
            self.performSegue(withIdentifier: self.segue[sender.tag - 1],sender: nil)
        }

    }
    
    // プログレスバーの処理
    func update() {
        if iTimer < 10 {
            CustomProgress.Instance.progressChange += 0.1
            iTimer += 1
        } else {
            //timerが動いてるなら.
            if timer.isValid == true {
                
                //timerを破棄する.
                timer.invalidate()
                _ = CustomProgress.isEnabledProgress()
                iTimer = 0
                resendButton.badgeString = ""
            }
        }
    }

    // スタッフログオフ
    func staff_logoff(){

        // 使用DB
        var path = _path
        if demo_mode != 0{
            path = _path_demo
        }
        
        let db = FMDatabase(path: path)
        db.open()
        let sql = "DELETE FROM staffs_now;"
        let _ = db.executeUpdate(sql, withArgumentsIn: [])
        db.close()
        
        staff_name_disp()
        
        staffNameLabel.text = ""
    }
    
    func staff_name_disp(){
        
        var menuButton = [orderButton,cancelButton,resendButton,staffButton,remainingButton,inportButton,configButton]
        
        staffNameLabel.text = ""
        
        // 担当者を取得する
        var path_usedb = _path
        if demo_mode != 0{
            path_usedb = _path_demo
        }
        
        let db_usedb = FMDatabase(path: path_usedb)
        
        // データベースをオープン
        db_usedb.open()
        
        // メニューがあるかチェック
        let sql_menu = "SELECT count(*) FROM menus_master;"
        let results = db_usedb.executeQuery(sql_menu, withArgumentsIn: [])
        
        var cnt = 0
        while (results?.next())! {
            cnt = Int((results?.int(forColumnIndex:0))!)
        }

        
        let sql_staffnow = "SELECT count(*) FROM staffs_now;"
        
        let results_staffnow = db_usedb.executeQuery(sql_staffnow, withArgumentsIn: [])
        while (results_staffnow?.next())! {
            // 担当者が選択されていない場合
            if (results_staffnow?.int(forColumnIndex:0))! <= 0 {
                // 担当者設定ボタン以外使用不可にする
                for num in 0..<7 {
                    let button :UIButton = menuButton[num]!
                    if num != 3 && num != 5 {
                        button.setTitleColor(UIColor.lightText, for: .disabled)
                        button.alpha = 0.6
                        button.isEnabled = false
                    }
                }
            } else {
                var staff_no = ""
                let sql_select_staff = "SELECT * FROM staffs_now;"
                let rs_select_staff = db_usedb.executeQuery(sql_select_staff, withArgumentsIn: [])
                while (rs_select_staff?.next())! {
                    staff_no = (rs_select_staff?.string(forColumn:"staff_no"))!
                    staffNameLabel.text = "担当者No:" + staff_no + "(" + (rs_select_staff?.string(forColumn:"staff_name_kanji"))! + ")"
                    // メニューがない場合はボタンの使用不可を解除しない
                    if cnt > 0 {
                        for num in 0..<7 {
                            let button :UIButton = menuButton[num]!
                            
                            button.alpha = 1.0
                            button.isEnabled = true
                        }
                    }

                }
                
                // オーダー入力画面の表示モード
                let sql_disp_mode = "SELECT COUNT(*) FROM disp_mode WHERE staff_no = ?;"
                let rs_disp_mode = db_usedb.executeQuery(sql_disp_mode, withArgumentsIn: [Int(staff_no)!])
                while (rs_disp_mode?.next())! {
                    if (rs_disp_mode?.int(forColumnIndex:0))! <= 0 {
                        let sql_insert = "INSERT INTO disp_mode (staff_no, disp_mode) VALUES (?,?)"
                        let rs_insert = db_usedb.executeUpdate(sql_insert, withArgumentsIn: [Int(staff_no)!,grid_disp])
                        if !rs_insert {
                            print(rs_insert.description)
                        }
                    }
                }
            }
            
            // 注文取消し可否で４（常に不可）の場合のみボタンを、押せなくする
            if is_oder_cancel == 4 {
                cancelButton.isEnabled = false
                cancelButton.setTitleColor(UIColor.lightText, for: .disabled)
                cancelButton.alpha = 0.6
            }
        }
        db_usedb.close()

    }
    
    
    // 認証確認 ooishi
    func JsonGet_serverAuth() {

        
      /*
        let url = urlString + "GetAuthorization?TerminalId=" + TerminalID! + "&StoreKbn=" + store_kbn.description
        let encUrl = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        print(encUrl)
        let json = JSON(url: encUrl!)
        print(json)
        
        // エラーの時
        if json.asError != nil {
            print("ng")
            self.dispatch_async_main{
                self.spinnerEnd()
                let alertController = UIAlertController(title: "確認", message: "認証に失敗しました。\n通信状態を確認してください", preferredStyle: .Alert)
                let OKAction = UIAlertAction(title: "はい", style: .Default){
                    action in
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    print("Pushed はい")
                    return;
                }
                alertController.addAction(OKAction)
                self.presentViewController(alertController, animated: true, completion: nil)
                return;
            }
        
        // エラーなし
        } else {
            print(json)
            for (key, value) in json {
                if key as! String == "Return" {
                    if value.toString() == "true" {
                        print("true")
        */

                        // データ取得
                        CustomProgress.Instance.title = "カテゴリ−情報\n受信中..."
                        self.spinnerStart()

                        self.jsonGet_category()
          /*
                    }else{
                        print("false")
                        self.dispatch_async_main{
                            self.spinnerEnd()
                            
                            // サーバ認証フラグを0にする
                            let serverAuth:checkServerAuth = checkServerAuth()
                            let serverCertification_flag = serverAuth.checkCertification()
                            if (serverCertification_flag == 1) {
                                serverAuth.setNoCertification()
                            }
                            
                            // ボタン非活性
                            /*
                            var menuButton = [self.orderButton,self.cancelButton,self.resendButton,self.staffButton,self.remainingButton,self.inportButton,self.configButton]
                            for num in 0..<7 {
                                let button :UIButton = menuButton[num]
                                if num != 3 && num != 5 {
                                    button.setTitleColor(UIColor.lightTextColor(), forState: .Disabled)
                                    button.alpha = 0.6
                                    button.enabled = false
                                }
                            }
                            */
                            
                            //ログオフ状態
                            self.staff_logoff()

                            // エラーメッセージ
                            let alertController = UIAlertController(title: "確認", message: "認証されていません。\n設定画面から認証ボタンを\nタップしてください。", preferredStyle: .Alert)
                            let OKAction = UIAlertAction(title: "はい", style: .Default){
                                action in
                                // タップ音
                                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                                print("Pushed はい")
                                return;
                            }
                            alertController.addAction(OKAction)
                            self.presentViewController(alertController, animated: true, completion: nil)
                            return;
                        }
                    }
                }
            }
        }
    */
    }

    func jsonGet_category() {
        // メニュー情報
        // カテゴリ
        self.dispatch_async_global {
            let url = urlString + "GetMenu"
            
//            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
//            configuration.timeoutIntervalForResource = 10 // seconds
            
            self.alamofireManager = Alamofire.SessionManager(configuration: self.configuration)
            self.alamofireManager!.request(url, parameters: ["Store_CD":shop_code.description,"Table_ID":1])
                .responseJSON{ response in
                    // エラーの時
                    if response.result.error != nil {
                        self.dispatch_async_main {
                            let e = response.result.description
                            self.jsonError()
                            print("e1",e)
                            self.spinnerEnd()
                            return;
                        }
                        
                        
                    } else {
                        let json = JSON(response.result.value!)
//                        print(json)
                        if json.asError != nil {
                            self.dispatch_async_main {
                                let e = json.asError
                                self.jsonError()
                                print("e2",e as Any)
                                self.spinnerEnd()
                                return;
                            }
                        } else {
                            let db = FMDatabase(path: self._path)
                            db.open()
                            
                            // 一旦すべて削除
                            let sql:String = "DELETE FROM categorys_master;"
                            let _ = db.executeUpdate(sql, withArgumentsIn: [])
                            
                            for (_,custmer) in json["m_category"]{
//                                print(custmer)
                                var success = true
                                let sql = "INSERT INTO categorys_master (facility_cd, store_cd, timezone_kbn, category_cd1, category_cd2, category_nm, category_disp_no,background_color_r, background_color_g, background_color_b, modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
                                
                                var argumentArray:Array<Any> = []
                                argumentArray.append(custmer["facility_cd"].asInt!)
                                argumentArray.append(custmer["store_cd"].asInt!)
                                argumentArray.append(custmer["timezone_kbn"].asInt!)
                                argumentArray.append(custmer["category_cd1"].asInt!)
                                argumentArray.append(custmer["category_cd2"].asInt!)
                                argumentArray.append(custmer["category_nm"].asString!)
                                argumentArray.append(custmer["sort_no"].asInt!)
                                
                                if custmer["category_cd2"].asInt! == 0 {
                                    argumentArray.append(custmer["background_color_r"].asDouble!)
                                    argumentArray.append(custmer["background_color_g"].asDouble!)
                                    argumentArray.append(custmer["background_color_b"].asDouble!)
                                } else {
                                    argumentArray.append(0.0)
                                    argumentArray.append(0.0)
                                    argumentArray.append(0.0)
                                }
                                let now = Date() // 現在日時の取得
                                let dateFormatter = DateFormatter()
                                dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                                dateFormatter.timeStyle = .medium
                                dateFormatter.dateStyle = .medium
                                
                                let modified = dateFormatter.string(from: now)
                                argumentArray.append(modified)
                                
                                // INSERT文を実行
                                success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                                // INSERT文の実行に失敗した場合
                                if !success {
                                    print("error",errno.description)
                                    // ループを抜ける
                                    break
                                }
                            }
                            
                            db.close()
                            self.dispatch_async_main {
                                self.spinnerMove("メニュー情報\n受信中...")
                            }
                            print("categoly end")
                            // メニュー
                            self.jsonGet_menu()
                            
                        }
                        
                    }
                    
            }
            /*
             print(urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=1")
             let json = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=1")
             //        print(json)
             if json.asError == nil {
             
             let db = FMDatabase(path: _path)
             db.open()
             
             // 一旦すべて削除
             let sql:String = "DELETE FROM categorys_master;"
             let _ = db.executeUpdate(sql, withArgumentsIn: [])
             
             for (_,custmer) in json["m_category"]{
             var success = true
             let sql = "INSERT INTO categorys_master (facility_cd, store_cd, timezone_kbn, category_cd1, category_cd2, category_nm, background_color_r, background_color_g, background_color_b, modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
             
             var argumentArray:Array<Any> = []
             argumentArray.append(custmer["facility_cd"].asInt!)
             argumentArray.append(custmer["store_cd"].asInt!)
             argumentArray.append(custmer["timezone_kbn"].asInt!)
             argumentArray.append(custmer["category_cd1"].asInt!)
             argumentArray.append(custmer["category_cd2"].asInt!)
             argumentArray.append(custmer["category_nm"].asString!)
             
             if custmer["category_cd2"].asInt! == 0 {
             argumentArray.append(custmer["background_color_r"].asDouble!)
             argumentArray.append(custmer["background_color_g"].asDouble!)
             argumentArray.append(custmer["background_color_b"].asDouble!)
             } else {
             argumentArray.append(0.0)
             argumentArray.append(0.0)
             argumentArray.append(0.0)
             }
             let now = Date() // 現在日時の取得
             let dateFormatter = DateFormatter()
             dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
             dateFormatter.timeStyle = .medium
             dateFormatter.dateStyle = .medium
             
             let modified = dateFormatter.stringFromDate(now)
             argumentArray.append(modified)
             
             // INSERT文を実行
             success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
             // INSERT文の実行に失敗した場合
             if !success {
             print("error",errno.description)
             // ループを抜ける
             break
             }
             }
             
             db.close()
             self.dispatch_async_main {
             self.spinnerMove("メニュー情報\n受信中...")
             }
             print("categoly end")
             
             } else {
             self.dispatch_async_main {
             let e = json.asError
             self.jsonError()
             print(e)
             self.spinnerEnd()
             }
             }
             */
            print("return")

        
        }

        return
    }
    
    fileprivate func jsonGet_menu() {
        // メニュー
        self.dispatch_async_global {
//            let url = urlString + "GetMenu"
//            self.alamofireManager = Alamofire.SessionManager(configuration: self.configuration)
//            self.alamofireManager!.request( url, parameters: ["Store_CD":shop_code.description,"Table_ID":2])
//                .responseJSON{ response in
//                    // エラーの時
//                    if response.result.error != nil {
//                        self.dispatch_async_main {
//                            let e = response.result.description
//                            self.jsonError()
//                            print("e1",e)
//                            self.spinnerEnd()
//                            return;
//                        }
//                    } else {
//                        let json_menu = JSON(response.result.value!)
//                        if json_menu.asError != nil {
//                            self.dispatch_async_main {
//                                let e = json_menu.asError
//                                self.jsonError()
//                                print(e)
//                            }
//                            return ;
//                            
//                        }
//                    }
//            }
            

            print(urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=2",Date())
            
            let json_menu = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=2")
//                    print("json1", json_menu)
            if json_menu.asError != nil {
                self.dispatch_async_main {
                    let e = json_menu.asError
                    self.jsonError()
                    print(e as Any)
                }
                return ;
                
            }

            self.dispatch_async_main {
                self.spinnerMove("セレクト\nメニュー情報\n受信中...")
            }
            
            // サブメニュー
            print(urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=3",Date())
            
            let json_sub_menu = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=3")
            if json_sub_menu.asError != nil {
                let e = json_sub_menu.asError
                self.jsonError()
                print(e as Any)
                return ;
            }

            self.dispatch_async_main {
                self.spinnerMove("セレクト\nメニュー紐付け\nマスタ\n受信中...")
            }
            
            print(urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=4",Date())

            // サブメニュー紐付けマスター
            let json_sub_menu_tie = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=4")
            if json_sub_menu_tie.asError != nil {
                let e = json_sub_menu.asError
                self.jsonError()
                print(e as Any)
                return;
            }
            self.dispatch_async_main {
                self.spinnerMove("オプション\nメニュー\n受信中...")
            }
            
            print(urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=5",Date())

            // 特殊メニュー
            let json_special_menu = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=5")
            if json_special_menu.asError != nil {
                let e = json_special_menu.asError
                self.jsonError()
                print(e as Any)
                return ;
            }
            self.dispatch_async_main {
                self.spinnerMove("メニュー\n単価マスタ\n受信中...")
            }
            
            // メニュー単価マスタ
            let json_menu_price = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=6")
            if json_menu_price.asError != nil {
                let e = json_menu_price.asError
                self.jsonError()
                print(e as Any)
                return ;
            }
            self.dispatch_async_main {
                self.spinnerMove("店舗別\nメニューマスタ\n受信中...")
            }

            // 店舗別メニュー明細マスタ
            let json_store_menu = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=7")
//            print(json_store_menu)
            if json_store_menu.asError != nil {
                let e = json_store_menu.asError
                self.jsonError()
                print(e as Any)
                return ;
            }
            
            // コードマスタ
            self.dispatch_async_main {
                self.spinnerMove("設定マスタ\n受信中...")
            }
            
            // 設定マスタ
            let json_setup = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=9")
            if json_setup.asError != nil {
                let e = json_setup.asError
                self.jsonError()
                print(e as Any)
                return ;
            }
            
            print("JSON END",Date())
            let now = Date() // 現在日時の取得
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
            dateFormatter.timeStyle = .medium
            dateFormatter.dateStyle = .medium
            
            let created = dateFormatter.string(from: now)
            let modified = dateFormatter.string(from: now)
            
            
            let db = FMDatabase(path: self._path)
            db.open()
            
            // 一旦すべて削除
            var sql:String = "DELETE FROM menus_master;"
            let _ = db.executeUpdate(sql, withArgumentsIn: [])
            
            // menus_master
            var success = true
            sql = "INSERT INTO menus_master (item_no ,item_name,item_short_name,category_no1,category_no2,shop_code,item_info,item_info2 ,sort_no , background_color_r , background_color_g , background_color_b ,created ,modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?, ?, ?, ?);"
            
            db.beginTransaction()
            
            let today = Date();
            let sec = today.timeIntervalSince1970
            let millisec = UInt64(sec * 1000) // intだとあふれるので注意
            print("開始",millisec)
            
            self.dispatch_async_main {
                self.spinnerMove("メニュー\n登録中...")
            }

            var custmer_store_menu_cd:[custmer_data] = []
            
            //        print("m_store_menu",json_store_menu["m_store_menu"])
            // 店舗別メニューマスタのJSONデータをローカルに保存
            for (_,custmer_store_menu) in json_store_menu["m_store_menu"]{
                //            print(custmer_store_menu)
                if custmer_store_menu["kbn"].asInt! == 1 {
                    // タイプチェック
                    if custmer_store_menu["menu_cd"].type == "Int" &&
                        custmer_store_menu["category_cd1"].type == "Int" &&
                        custmer_store_menu["category_cd2"].type == "Int" {
                        custmer_store_menu_cd.append(custmer_data(
                            store_cd:custmer_store_menu["store_cd"].asInt!,
                            kbn: custmer_store_menu["menu_cd"].asInt64!,
                            cat1: custmer_store_menu["category_cd1"].asInt!,
                            cat2: custmer_store_menu["category_cd2"].asInt!,
                            sort_no:custmer_store_menu["sort_no"].asInt!,
                            r:0.0,
                            g:0.0,
                            b:0.0,
                            comment:""
                            )
                        )
                    }
                } else if custmer_store_menu["kbn"].asInt! == 2{
                    custmer_store_menu_cd.append(custmer_data(
                        store_cd:custmer_store_menu["store_cd"].asInt!,
                        kbn: -1,
                        cat1: custmer_store_menu["category_cd1"].asInt!,
                        cat2: custmer_store_menu["category_cd2"].asInt!,
                        sort_no:custmer_store_menu["sort_no"].asInt!,
                        r:custmer_store_menu["comment_color_r"].type == "String" ? 0.0 : custmer_store_menu["comment_color_r"].asDouble!,
                        g:custmer_store_menu["comment_color_g"].type == "String" ? 0.0 : custmer_store_menu["comment_color_g"].asDouble!,
                        b:custmer_store_menu["comment_color_b"].type == "String" ? 0.0 :custmer_store_menu["comment_color_b"].asDouble!,
                        comment:custmer_store_menu["comment_text"].asString!
                        )
                    )
                }
            }
            
            
            print("2",Date())
            
            var main_menu:[menu_data] = []
//            print(json_menu["m_menu"])
            // メニューマスタのJSONデータをローカルに保存
            for (_,custmer_menu) in json_menu["m_menu"]{
                // 名称に¥が入っていたときの処理
                let menu_name = custmer_menu["menu_nm"].asString!
                let menu_name2 = menu_name.replacingOccurrences(of: "\\", with: "¥")
                
                main_menu.append(menu_data(
                    menu_cd: custmer_menu["menu_cd"].asInt64!,
//                    menu_nm: custmer_menu["menu_nm"].asString!,
                    menu_nm: menu_name2,
                    store_cd: custmer_menu["store_cd"].asInt!,
                    temp_comment: custmer_menu["temp_comment"].asString!,
                    comment: custmer_menu["comment"].asString!))
            }
            
            print("4",Date())
            //        print(main_menu)
            for custmer_menu in main_menu {
                let store_menu_cd = custmer_store_menu_cd.filter({$0.kbn == custmer_menu.menu_cd})
                if store_menu_cd.count > 0 {
                    for smc in store_menu_cd {
                        var argumentArray:Array<Any> = []
                        //                        print(custmer_menu)
                        argumentArray.append(NSNumber(value: custmer_menu.menu_cd as Int64))
                        argumentArray.append(custmer_menu.menu_nm)
                        argumentArray.append(custmer_menu.menu_nm)
                        argumentArray.append(smc.cat1)
                        argumentArray.append(smc.cat2)
                        argumentArray.append(custmer_menu.store_cd)
                        // \\は￥に変更
                        argumentArray.append((custmer_menu.comment).replacingOccurrences(of: "\\", with: "¥"))
                        argumentArray.append((custmer_menu.temp_comment).replacingOccurrences(of: "\\", with: "¥"))
                        argumentArray.append(smc.sort_no)
                        argumentArray.append(smc.r)
                        argumentArray.append(smc.g)
                        argumentArray.append(smc.b)
                        argumentArray.append(created)
                        argumentArray.append(modified)
                        
                        
                        // INSERT文を実行
                        //                    print(argumentArray)
                        success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                        // INSERT文の実行に失敗した場合
                        if !success {
                            print("menuError",errno.description)
                            // ループを抜ける
                            break
                        }
                    }
                }
                
            }
            
            let custmer_comments = custmer_store_menu_cd.filter({$0.kbn == -1})
            if custmer_comments.count > 0 {
                for custmer_comment in custmer_comments {
                    var argumentArray:Array<Any> = []
                    argumentArray.append(NSNumber(value: custmer_comment.kbn as Int64))
                    argumentArray.append(custmer_comment.comment)
                    argumentArray.append(custmer_comment.comment)
                    argumentArray.append(custmer_comment.cat1)
                    argumentArray.append(custmer_comment.cat2)
                    argumentArray.append(custmer_comment.store_cd)
                    argumentArray.append("")
                    argumentArray.append("")
                    argumentArray.append(custmer_comment.sort_no)
                    argumentArray.append(custmer_comment.r)
                    argumentArray.append(custmer_comment.g)
                    argumentArray.append(custmer_comment.b)
                    argumentArray.append(created)
                    argumentArray.append(modified)
                    
                    
                    // INSERT文を実行
                    //                    print(argumentArray)
                    success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                    // INSERT文の実行に失敗した場合
                    if !success {
                        print("menuError",errno.description)
                        // ループを抜ける
                        break
                    }
                }
            }
            
            
            
            let today2 = Date();
            let sec2 = today2.timeIntervalSince1970
            let millisec2 = UInt64(sec2 * 1000) // intだとあふれるので注意
            print("終了",millisec2,millisec2 - millisec)
            
            
            if success {
                // 全てのINSERT文が成功した場合はcommit
                db.commit()
            } else {
                // 1つでも失敗したらrollback
                db.rollback()
            }
            
            print("menu end",Date())
            
            self.dispatch_async_main {
                self.spinnerMove("セレクト\nメニュー\n登録中...")
            }

            // 一旦すべて削除
            sql = "DELETE FROM sub_menus_master;"
            let _ = db.executeUpdate(sql, withArgumentsIn: [])
            
            sql = "INSERT INTO sub_menus_master (item_name,item_short_name,menu_no,sub_menu_group,sub_menu_no,is_default,price1,price2,price3 ,created ,modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
            
            self.custmer_sub_menu = []
            for (_,custmer_sub) in json_sub_menu["m_sub_menu"]{
                let sub_menu_name = custmer_sub["sub_menu_nm"].asString!
                let sub_menu_name2 = sub_menu_name.replacingOccurrences(of: "\\", with: "¥")
                
                self.custmer_sub_menu.append(sub_menu_data(
                    sub_menu_kbn: custmer_sub["sub_menu_kbn"].asInt!,
                    sub_menu_cd: custmer_sub["sub_menu_cd"].asInt!,
//                    sub_menu_nm: custmer_sub["sub_menu_nm"].asString!,
                    sub_menu_nm: sub_menu_name2,
                    
                    menu_cd:custmer_sub["menu_cd"].asString == "" ? 0 : custmer_sub["menu_cd"].asInt64!)
                )
            }
            
            self.custmer_sub_menu_tie = []
            for (_,custmer_sub_tie) in json_sub_menu_tie["m_sub_menu_tie"]{
                self.custmer_sub_menu_tie.append(custmer_sub_tie_data(
                    kbn : custmer_sub_tie["sub_menu_kbn"].asInt!,
                    default_sub_menu_cd : custmer_sub_tie["default_sub_menu_cd"].type != "Int" ? 0 : custmer_sub_tie["default_sub_menu_cd"].asInt!,
                    menu_cd : custmer_sub_tie["menu_cd"].asInt64!,
                    sort_no : custmer_sub_tie["sort_no"].asInt!)
                )
            }
            
            self.custmer_menu_price = []
            //        print(json_menu_price["m_menu_price"])
            for (_,menu_price) in json_menu_price["m_menu_price"]{
                self.custmer_menu_price.append(menu_price_data(
                    menu_cd         : menu_price["menu_cd"].asInt64!,
                    unit_price_kbn  : menu_price["unit_price_kbn"].asInt!,
                    selling_price   : menu_price["selling_price"].isNull ? 0 : menu_price["selling_price"].asInt!)
                )
            }
            
            db.beginTransaction()
            
            success = true
            // sub_menus_master
            for sub_menu in self.custmer_sub_menu {
                let sub_menu_ties = self.custmer_sub_menu_tie.filter({$0.kbn == sub_menu.sub_menu_kbn})
                for sub_menu_tie in sub_menu_ties {
                
//                for sub_menu_tie in self.custmer_sub_menu_tie {
//                    if sub_menu.sub_menu_kbn == sub_menu_tie.kbn {
                        var argumentArray:Array<Any> = []
                        argumentArray.append(sub_menu.sub_menu_nm)
                        argumentArray.append((sub_menu_tie.sort_no).description)
                        argumentArray.append(NSNumber(value: sub_menu_tie.menu_cd as Int64))
                        argumentArray.append(sub_menu.sub_menu_kbn)
                        argumentArray.append(sub_menu.sub_menu_cd)
                        
                        if sub_menu.sub_menu_cd == sub_menu_tie.default_sub_menu_cd {
                            argumentArray.append(1)
                        } else {
                            argumentArray.append(0)
                        }
                        
                        argumentArray.append(NSNull())
                        argumentArray.append(NSNull())
                        argumentArray.append(NSNull())
                        
                        for menu_price in self.custmer_menu_price{
                            if sub_menu.menu_cd != 0 {
                                let price = menu_price.selling_price
                                if menu_price.menu_cd == sub_menu.menu_cd {
                                    switch menu_price.unit_price_kbn {
                                    case 1:
                                        argumentArray[6] = price
                                    case 2:
                                        argumentArray[7] = price
                                    case 3:
                                        argumentArray[8] = price
                                    default:
                                        break
                                    }
                                }
                            }
                        }
                        argumentArray.append(created)
                        argumentArray.append(modified)
                        //                    print(argumentArray)
                        // INSERT文を実行
                        success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                        // INSERT文の実行に失敗した場合
                        if !success {
                            print(errno.description)
                            // ループを抜ける
                            break
                        }
                        
//                    }
                }
            }
            
            if success {
                // 全てのINSERT文が成功した場合はcommit
                db.commit()
            } else {
                // 1つでも失敗したらrollback
                db.rollback()
            }
            
            print("sub_menu end")
            
            self.dispatch_async_main {
                self.spinnerMove("セレクト\nメニュー\n単価情報\n登録中...")
            }

            // 2017/2/14 add start yamao
            // セレクトメニュー、オプションメニューの単価情報
            // 一旦すべて削除
            sql = "DELETE FROM menus_price WHERE order_kbn = 2;"
            let _ = db.executeUpdate(sql, withArgumentsIn: [])
            
            sql = "INSERT INTO menus_price (facility_cd ,store_cd ,order_kbn ,menu_cd ,parent_menu_cd, category_no ,unit_price_kbn ,price ,tax_included ,created , modified ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
            
            db.beginTransaction()
            
            let today3 = Date();
            let sec3 = today3.timeIntervalSince1970
            let millisec3 = UInt64(sec3 * 1000) // intだとあふれるので注意
            print("開始1",millisec3)
            success = true
            // sub_menus_master
            let sub_menus = self.custmer_sub_menu.filter({$0.menu_cd != 0})
            for sub_menu in sub_menus {
                let sub_menu_ties = self.custmer_sub_menu_tie.filter({$0.kbn == sub_menu.sub_menu_kbn})
                for sub_menu_tie in sub_menu_ties {
                    let menu_prices = self.custmer_menu_price.filter({$0.menu_cd == sub_menu.menu_cd})
                    for menu_price in menu_prices {
                        let price = menu_price.selling_price
                        var argumentArray:Array<Any> = []
                        argumentArray.append(1)                     // facility_cd
                        argumentArray.append(shop_code)             // store_cd
                        argumentArray.append(order_select_menu)     // order_kbn
                        argumentArray.append(sub_menu.sub_menu_cd)  // メニューコード
                        argumentArray.append(NSNumber(value: sub_menu_tie.menu_cd as Int64))  // 親メニューコード
                        argumentArray.append(sub_menu.sub_menu_kbn) // カテゴリNO
                        argumentArray.append(menu_price.unit_price_kbn) // unit_price_kbn
                        argumentArray.append(price)                 // 単価
                        argumentArray.append(0)                     // 内税額
                        argumentArray.append(created)
                        argumentArray.append(modified)
                        
                        //                    print(argumentArray)
                        success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                        // INSERT文の実行に失敗した場合
                        if !success {
                            print(errno.description)
                            // ループを抜ける
                            break
                        }
                        
                    }
                    
                }
                
            }
            
            let today4 = Date();
            let sec4 = today4.timeIntervalSince1970
            let millisec4 = UInt64(sec4 * 1000) // intだとあふれるので注意
            print("終了1",millisec4,millisec4-millisec3)
            
            //        for sub_menu in custmer_sub_menu {
            //            for sub_menu_tie in custmer_sub_menu_tie {
            //                if sub_menu.sub_menu_kbn == sub_menu_tie.kbn {
            //                    for menu_price in custmer_menu_price{
            //                        if sub_menu.menu_cd != 0 {
            //                            let price = menu_price.selling_price
            //                            if menu_price.menu_cd == sub_menu.menu_cd {
            //
            //                                var argumentArray:Array<Any> = []
            //                                argumentArray.append(1)                     // facility_cd
            //                                argumentArray.append(shop_code)             // store_cd
            //                                argumentArray.append(order_select_menu)     // order_kbn
            //                                argumentArray.append(sub_menu.sub_menu_cd)  // メニューコード
            //                                argumentArray.append(sub_menu_tie.menu_cd)  // 親メニューコード
            //                                argumentArray.append(sub_menu.sub_menu_kbn) // カテゴリNO
            //                                argumentArray.append(menu_price.unit_price_kbn) // unit_price_kbn
            //                                argumentArray.append(price)                 // 単価
            //                                argumentArray.append(0)                     // 内税額
            //                                argumentArray.append(created)
            //                                argumentArray.append(modified)
            //
            ////                                                    print(argumentArray)
            //                                // INSERT文を実行
            ////                                success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
            ////                                // INSERT文の実行に失敗した場合
            ////                                if !success {
            ////                                    print(errno.description)
            ////                                    // ループを抜ける
            ////                                    break
            ////                                }
            //
            //                            }
            //                        }
            //                    }
            //
            //                }
            //            }
            //        }
            //
            //        let today5 = Date();
            //        let sec5 = today5.timeIntervalSince1970
            //        let millisec5 = UInt64(sec5 * 1000) // intだとあふれるので注意
            //        print("終了２",millisec5,millisec5-millisec4)
//            success = true
            
            if success {
                // 全てのINSERT文が成功した場合はcommit
                db.commit()
            } else {
                // 1つでも失敗したらrollback
                db.rollback()
            }
            
            // 2017/2/14 add end yamao
            
            self.dispatch_async_main {
                self.spinnerMove("オプション\nメニュー\n登録中...")
            }

            // 一旦すべて削除
            
            sql = "DELETE FROM special_menus_master;"
            let _ = db.executeUpdate(sql, withArgumentsIn: [])
            
            sql = "INSERT INTO special_menus_master (item_no ,item_name,item_short_name,category_no,shop_code,price1,price2,price3 ,created ,modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
            
            self.special_menu = []
//            print(json_special_menu["m_spe_menu"])
            for (_,custmer_special_menu) in json_special_menu["m_spe_menu"]{
                // 名称に¥が入っていたときの処理
                let spe_menu_name = custmer_special_menu["spe_menu_nm"].asString!
                let spe_menu_name2 = spe_menu_name.replacingOccurrences(of: "\\", with: "¥")

                
                
                self.special_menu.append(sp_menu_data(
                    spe_menu_cd : custmer_special_menu["spe_menu_cd"].asInt!,
//                    spe_menu_nm : custmer_special_menu["spe_menu_nm"].asString!,
                    spe_menu_nm : spe_menu_name2,
                    spe_menu_kbn: custmer_special_menu["spe_menu_kbn"].asInt!,
                    store_cd    : custmer_special_menu["store_cd"].asInt!,
                    menu_cd     : custmer_special_menu["menu_cd"].asString == "" ? 0 : custmer_special_menu["menu_cd"].asInt64!,
                    
                    r:custmer_special_menu["background_color_r"].type == "String" ? 0.0 : custmer_special_menu["background_color_r"].asDouble!,
                    g:custmer_special_menu["background_color_g"].type == "String" ? 0.0 : custmer_special_menu["background_color_g"].asDouble!,
                    b:custmer_special_menu["background_color_b"].type == "String" ? 0.0 :custmer_special_menu["background_color_b"].asDouble!
                    )
                )
            }
            
            db.beginTransaction()
            
            success = true
            // special_menus_master
            for sp_menu in self.special_menu {
                if sp_menu.spe_menu_cd > 0 {
                    var argumentArray:Array<Any> = []
                    argumentArray.append(sp_menu.spe_menu_cd)
                    argumentArray.append(sp_menu.spe_menu_nm)
                    argumentArray.append(sp_menu.spe_menu_nm)
                    argumentArray.append(sp_menu.spe_menu_kbn)
                    argumentArray.append(sp_menu.store_cd)
                    
                    argumentArray.append(NSNull())
                    argumentArray.append(NSNull())
                    argumentArray.append(NSNull())
                    
                    for menu_price in self.custmer_menu_price{
                        if menu_price.menu_cd != 0 {
                            if menu_price.menu_cd == sp_menu.menu_cd {
                                let price = menu_price.selling_price
                                
                                switch menu_price.unit_price_kbn {
                                case 1:
                                    argumentArray[5] = price
                                    break
                                case 2:
                                    argumentArray[6] = price
                                    break
                                case 3:
                                    argumentArray[7] = price
                                    break
                                default:
                                    break
                                }
                                
                            }
                            
                        }
                        
                    }
                    argumentArray.append(created)
                    argumentArray.append(modified)
                    
                    // INSERT文を実行
                    success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                    // INSERT文の実行に失敗した場合
                    if !success {
                        print(errno.description)
                        // ループを抜ける
                        break
                    }
                    
                } else {
                    
                    let sql = "INSERT INTO categorys_master (facility_cd, store_cd, timezone_kbn, category_cd1, category_cd2, category_nm, background_color_r, background_color_g, background_color_b,created, modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
                    
                    var argumentArray:Array<Any> = []
                    argumentArray.append(2)
                    argumentArray.append(sp_menu.store_cd)
                    argumentArray.append(0)
                    argumentArray.append(sp_menu.spe_menu_kbn)
                    argumentArray.append(0)
                    argumentArray.append(sp_menu.spe_menu_nm)
                    
                    argumentArray.append(sp_menu.r)
                    argumentArray.append(sp_menu.g)
                    argumentArray.append(sp_menu.b)
                    argumentArray.append(created)
                    argumentArray.append(modified)
                    
                    // INSERT文を実行
                    success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                    // INSERT文の実行に失敗した場合
                    if !success {
                        print(errno.description)
                        // ループを抜ける
                        break
                    }
                    
                }
            }
            if success {
                // 全てのINSERT文が成功した場合はcommit
                db.commit()
            } else {
                // 1つでも失敗したらrollback
                db.rollback()
            }
            
            //        db.close()
            self.dispatch_async_main {
                self.spinnerMove("オプション\nメニュー単価\n登録中...")
            }
 
            // 2017/2/14 add start yamao
            // セレクトメニュー、オプションメニューの単価情報
            // 一旦すべて削除
            sql = "DELETE FROM menus_price WHERE order_kbn = 3;"
            let _ = db.executeUpdate(sql, withArgumentsIn: [])
            
            sql = "INSERT INTO menus_price (facility_cd ,store_cd ,order_kbn ,menu_cd ,parent_menu_cd, category_no ,unit_price_kbn ,price ,tax_included ,created , modified ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
            
            db.beginTransaction()
            
            success = true
            // special_menus_master
            let sp_menus = self.special_menu.filter({$0.spe_menu_cd > 0})
            for sp_menu in sp_menus {
                let menu_prices = self.custmer_menu_price.filter({$0.menu_cd != 0 && $0.menu_cd == sp_menu.menu_cd})
                for menu_price in menu_prices {
                    let price = menu_price.selling_price
                    var argumentArray:Array<Any> = []
                    argumentArray.append(1)                     // facility_cd
                    argumentArray.append(shop_code)             // store_cd
                    argumentArray.append(order_option_menu)     // order_kbn
                    argumentArray.append(sp_menu.spe_menu_cd)   // メニューコード
                    argumentArray.append(0)                     // 親メニューコード
                    argumentArray.append(sp_menu.spe_menu_kbn)  // カテゴリNO
                    argumentArray.append(menu_price.unit_price_kbn) // unit_price_kbn
                    argumentArray.append(price)                 // 単価
                    argumentArray.append(0)                     // 内税額
                    argumentArray.append(created)
                    argumentArray.append(modified)
                    
                    //                    print(argumentArray)
                    // INSERT文を実行
                    success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                    // INSERT文の実行に失敗した場合
                    if !success {
                        print(errno.description)
                        // ループを抜ける
                        break
                    }

                }
                
            }
            
//            for sp_menu in self.special_menu {
//                if sp_menu.spe_menu_cd > 0 {
//                    for menu_price in self.custmer_menu_price{
//                        if menu_price.menu_cd != 0 {
//                            if menu_price.menu_cd == sp_menu.menu_cd {
//                                let price = menu_price.selling_price
//                                
//                                var argumentArray:Array<Any> = []
//                                argumentArray.append(1)                     // facility_cd
//                                argumentArray.append(shop_code)             // store_cd
//                                argumentArray.append(order_option_menu)     // order_kbn
//                                argumentArray.append(sp_menu.spe_menu_cd)   // メニューコード
//                                argumentArray.append(0)                     // 親メニューコード
//                                argumentArray.append(sp_menu.spe_menu_kbn)  // カテゴリNO
//                                argumentArray.append(menu_price.unit_price_kbn) // unit_price_kbn
//                                argumentArray.append(price)                 // 単価
//                                argumentArray.append(0)                     // 内税額
//                                argumentArray.append(created)
//                                argumentArray.append(modified)
//                                
//                                //                    print(argumentArray)
//                                // INSERT文を実行
//                                success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
//                                // INSERT文の実行に失敗した場合
//                                if !success {
//                                    print(errno.description)
//                                    // ループを抜ける
//                                    break
//                                }
//                                
//                            }
//                            
//                        }
//                        
//                    }
//                }
//            }
            if success {
                // 全てのINSERT文が成功した場合はcommit
                db.commit()
            } else {
                // 1つでも失敗したらrollback
                db.rollback()
            }
            
            db.close()
            
            // 2017/2/14 add end yamao
            
            
            // その他設定
            // special_menus_master
            let setup_key = ["TABLET_MINUS_QTY","TABLET_ORDER_CANCEL","TABLET_ORDER_WAITING","TABLET_PAYER_ALLOCATION","TABLET_TICKET_AUTOLINK","TABLET_TIME_ZONE","TABLET_ITEM_PRICE_KBN"]
            //        print(json_setup["m_setup"])
            for (_,custmer_setup) in json_setup["m_setup"]{
                for i in 0..<setup_key.count {
                    if custmer_setup["setup_key"].asString! == setup_key[i] {
                        let value = custmer_setup["setup_num_value1"].asInt!
                        switch i {
                        case 0: is_minus_qty = value
                        case 1: is_oder_cancel = value
                        case 2: is_order_wait = value
                        case 3: is_payer_allocation = value
                        case 4: is_ticket_autolink = value
                        case 5: is_timezone = value
                        case 6: is_unit_price_kbn = value
                        default: break;
                            
                        }
                    }
                }
            }
            self.dispatch_async_main {
                self.spinnerMove("コードマスター\n情報\n受信中...")
            }
            
            db.open()
            sql = "DELETE FROM pc_config;"
            let _ = db.executeUpdate(sql, withArgumentsIn: [])
            
            sql = "INSERT OR REPLACE INTO pc_config (setup_key,value) VALUES(?,?);"
            
            db.beginTransaction()
            for (i,key) in setup_key.enumerated() {
                var argumentArray:Array<Any> = []
                argumentArray.append(key)        // setup_key
                
                switch i {
                case 0: argumentArray.append(is_minus_qty)
                case 1: argumentArray.append(is_oder_cancel)
                case 2: argumentArray.append(is_order_wait)
                case 3: argumentArray.append(is_payer_allocation)
                case 4: argumentArray.append(is_ticket_autolink)
                case 5: argumentArray.append(is_timezone)
                case 6: argumentArray.append(is_unit_price_kbn)
                default: break;
                }
                // INSERT文を実行
                success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                // INSERT文の実行に失敗した場合
                if !success {
                    print(errno.description)
                    // ループを抜ける
                    break
                }
                
            }
            db.commit()
            db.close()
            //                    print(argumentArray)
            
            // コードマスタ
            self.jsonGet_codemaster()
            print("special menu end")

        }
    }
    
    
    fileprivate func jsonGet_codemaster(){
        // コードマスタ
        self.dispatch_async_global {
            let json = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=8")
            if json.asError == nil {
                //            print("json1コードマスタ", json)
                let db = FMDatabase(path: self._path)
                db.open()
                
                // 一旦消す
                let sql2 = "DELETE FROM timezone;"
                let _ = db.executeUpdate(sql2, withArgumentsIn: [])
                
                // 一旦消す
                let sql3 = "DELETE FROM unit_price_kbn;"
                let _ = db.executeUpdate(sql3, withArgumentsIn: [])
                
                
                for (_,custmer) in json["m_code"]{
                    var sql = ""
                    var success = true
                    var argumentArray:Array<Any> = []
                    if custmer["kbn"].asString! == "TIMEZONE_KBN" {
                        
                        sql = "INSERT INTO timezone (id, timezone,  icon_image, created, modified) VALUES (?, ?, ?, ?, ?);"
                        
                        let menu_cd = (custmer["code"].type == "Int") ? custmer["code"].asInt! : 0
                        argumentArray.append(menu_cd)
                        argumentArray.append((custmer["name"].asString!))
                        
                        let imageString = (custmer["iconfile"].asString!)
                        argumentArray.append(imageString)
                        
                    } else {
                        
                        sql = "INSERT INTO unit_price_kbn(price_kbn_no, price_kbn_name, created, modified) VALUES(?,?,?,?);"
                        
                        let menu_cd = (custmer["code"].type == "Int") ? custmer["code"].asInt! :0
                        argumentArray.append(menu_cd)
                        argumentArray.append((custmer["name"].asString!))
                    }
                    
                    let now = Date() // 現在日時の取得
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                    dateFormatter.timeStyle = .medium
                    dateFormatter.dateStyle = .medium
                    
                    let created = dateFormatter.string(from: now)
                    let modified = created
                    argumentArray.append(created)
                    argumentArray.append(modified)
                    
                    // INSERT文を実行
                    
                    success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                    // INSERT文の実行に失敗した場合
                    if !success {
                        print(errno.description)
                        // ループを抜ける
                        break
                    }
                    
                }
                db.close()
                self.dispatch_async_main {
                    self.spinnerMove("設定マスタ情報\n受信中...")
                }
                
                print("jsonGet_codemaster  end")
                // セットアップマスター
                self.jsonGet_setup()
                
            } else {
                let e = json.asError
                self.jsonError()
                print(e as Any)
            }
        }
    }
    
    fileprivate func jsonGet_setup(){
        // 設定マスタ
        self.dispatch_async_global {
            let json = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=9")
            if json.asError == nil {
                //            print("json1", json)
                let db = FMDatabase(path: self._path)
                db.open()
                
                // トランザクションを開始
                db.beginTransaction()
                
                for (_,custmer) in json["m_setup"]{
                    if custmer["setup_nm"].asString == "[タブレット]時間帯区分" {
                        var success = true
                        is_timezone = custmer["setup_num_value1"].asInt!
                        let sql = "UPDATE app_config SET is_timezone = ?,modified = ?;"
                        
                        var argumentArray:Array<Any> = []
                        
                        argumentArray.append(custmer["setup_num_value1"].asInt!)
                        let now = Date() // 現在日時の取得
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                        dateFormatter.timeStyle = .medium
                        dateFormatter.dateStyle = .medium
                        
                        let modified = dateFormatter.string(from: now)
                        argumentArray.append(modified)
                        
                        // INSERT文を実行
                        success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                        // INSERT文の実行に失敗した場合
                        if !success {
                            print(errno.description)
                            // ループを抜ける
                            break
                        }
                        
                    }
                }
                db.commit()
                
                db.close()
                self.dispatch_async_main {
                    self.spinnerMove("座席情報\n受信中...")
                }
                
                print("jsonGet_setup  end")
                //            self.jsonGet_seat()
                // 座席マスタ
                self.jsonGet_seat()
            } else {
                let e = json.asError
                self.jsonError()
                print(e as Any)
            }
        }
    }
    
    fileprivate func jsonGet_seat(){
        // 座席マスタ
        self.dispatch_async_global {
            let json = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=10")
            if json.asError == nil {
                //            print("json1", json)
                let db = FMDatabase(path: self._path)
                db.open()
                
                self.seat_master = []
                
                for (_,custmer) in json["m_seat"]{
                    self.seat_master.append(seat_master_data(
                        table_no: custmer["table_no"].asInt!,
                        seat_no: custmer["seat_no"].asInt! - 1,
                        seat_nm: custmer["seat_nm"].asString!,
                        disp_position: custmer["disp_position"].asInt!,
                        seat_kbn: custmer["seat_kbn"].asInt!)
                    )
                    
                }
                
                var success = true
                
                var sql = "DELETE FROM seat_master"
                let _ = db.executeUpdate(sql, withArgumentsIn: [])
                
                
                sql = "INSERT OR REPLACE INTO seat_master (table_no,seat_no,seat_name,disp_position,seat_kbn,created ,modified) VALUES(?,?,?,?,?,?,?);"
                
                // トランザクションを開始
                db.beginTransaction()
                
                for seat in self.seat_master {
                    var argumentArray:Array<Any> = []
                    
                    argumentArray.append(seat.table_no)
                    argumentArray.append(seat.seat_no)
                    argumentArray.append(seat.seat_nm)
                    argumentArray.append(seat.disp_position)
                    argumentArray.append(seat.seat_kbn)
                    
                    let now = Date() // 現在日時の取得
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                    dateFormatter.timeStyle = .medium
                    dateFormatter.dateStyle = .medium
                    
                    let created = dateFormatter.string(from: now)
                    let modified = created
                    argumentArray.append(created)
                    argumentArray.append(modified)
                    
                    // INSERT文を実行
                    success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                    // INSERT文の実行に失敗した場合
                    if !success {
                        print(errno.description)
                        // ループを抜ける
                        break
                    }
                    
                }
                db.commit()
                
                db.close()
                self.dispatch_async_main {
                    self.spinnerMove("テーブル情報\n受信中...")
                }
                
                print("jsonGet_seat  end")
                // テーブルマスタ
                self.jsonGet_table()
            } else {
                let e = json.asError
                self.jsonError()
                print(e as Any)
            }
        
        }
    }
    
    fileprivate func jsonGet_table(){
        // テーブルマスタ
        self.dispatch_async_global {
            let json = JSON(url:urlString + "GetMenu?Store_CD=" + shop_code.description + "&Table_ID=11")
            if json.asError == nil {
                //            print("json1", json)
                let db = FMDatabase(path: self._path)
                db.open()
                
                //            print(json["m_table"])
                self.table_master = []
                for (_,custmer) in json["m_table"]{
                    self.table_master.append(table_master_data(
                        table_no: custmer["table_no"].asInt!,
                        table_nm: custmer["table_nm"].asString!,
                        seat_nm: custmer["seat_num"].type != "Int" ? 0 : custmer["seat_num"].asInt!,
                        section: custmer["section"].type != "Int" ? 0 : custmer["section"].asInt!)
                    )
                    
                }
                var success = true
                let sql = "INSERT OR REPLACE INTO table_no (table_no, table_name, seat_count, section , created, modified) VALUES (?, ?, ?, ?, ?, ?);"
                
                db.beginTransaction()
                for table in self.table_master {
                    var argumentArray:Array<Any> = []
                    
                    argumentArray.append(table.table_no)
                    argumentArray.append(table.table_nm)
                    argumentArray.append(table.seat_nm)
                    argumentArray.append(table.section)
                    
                    let now = Date() // 現在日時の取得
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                    dateFormatter.timeStyle = .medium
                    dateFormatter.dateStyle = .medium
                    
                    let created = dateFormatter.string(from: now)
                    let modified = created
                    argumentArray.append(created)
                    argumentArray.append(modified)
                    
                    // INSERT文を実行
                    success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                    // INSERT文の実行に失敗した場合
                    if !success {
                        print(errno.description)
                        // ループを抜ける
                        break
                    }
                    
                    
                }
                db.commit()
                db.close()
                
                db.close()
                self.dispatch_async_main {
                    self.spinnerMove("来場者情報\n受信中...")
                }
                
                self.jsonGet_player()
                
                print("jsonGet_table  end")
            } else {
                let e = json.asError
                self.jsonError()
                print(e as Any)
            }
        }
    }
    
    fileprivate func jsonGet_player(){
        // デモモードのときは抜ける
        if demo_mode != 0 { return }
        
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        let _path = (paths[0] as NSString).appendingPathComponent(production_db)
        
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        // お客様情報の取得
        playersClass.get()
        
        self.dispatch_async_main {
            CustomProgress.Instance.compliteTitle = "データ取込\n終了！！"
            CustomProgress.Instance.progressChange = 1.0
            self.spinnerEnd()
            
            self.staff_name_disp()
        }
    }
    
    
    //Segue animation on/off
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        segue.destination.dismiss(animated: false, completion: nil)
        
        let is_animation = animation == 1 ? true : false
        
        UIView.setAnimationsEnabled(is_animation)
    }
    
    @IBAction func configButtonTap(_ sender: AnyObject) {
        // タップ音
        
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        self.performSegue(withIdentifier: "toConfigViewSege",sender: nil)
    }
    
    
    // 戻るボタンで戻ってくるためのおまじない
    @IBAction func unwindToTop(_ segue: UIStoryboardSegue) {
        
    }
    
    func dispatch_async_main(_ block: @escaping () -> ()) {
        DispatchQueue.main.async(execute: block)
    }
    
    func dispatch_async_global(_ block: @escaping () -> ()) {
        DispatchQueue.global().async (execute: block)
    }
    
    func spinnerStart() {
        CustomProgress.Create(self.view,initVal: self.initVal,modeView: EnumModeView.mrCircularProgressView)
        //ネットワーク接続中のインジケータを表示
        CustomProgress.Instance.progressChange = 0
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

    }
    
    func spinnerEnd() {
        let delayTime = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            CustomProgress.Instance.mrprogress.dismiss(true)
            //ネットワーク接続中のインジケータを消去
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func spinnerMove(_ title:String) {
        CustomProgress.Instance.title = title
        CustomProgress.Instance.progressChange += self.interval
    }

    func spinnerStart2() {
        CustomProgress.Instance.title = "受信中..."
        CustomProgress.Create(self.view,initVal: initVal,modeView: EnumModeView.uiActivityIndicatorView)
        
        //ネットワーク接続中のインジケータを表示
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func spinnerEnd2() {
        CustomProgress.Instance.mrprogress.dismiss(true)
        //ネットワーク接続中のインジケータを消去
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    
    func jsonError(){
        // エラー音
        TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)
        // エラー表示
        self.spinnerEnd()
        
        self.dispatch_async_main {
        
            let alertController = UIAlertController(title: "エラー！", message: "メニュー取り込みに失敗しました。\nデータ取込を再度実行してください。", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default){
                action in print("Pushed OK")
                self.spinnerEnd()
                return;
            }
            
            alertController.addAction(okAction)
            UIApplication.shared.topViewController()?.present(alertController, animated: true, completion: nil)

        }
    }
    
    //StringをUIImageに変換する
    func String2Image(_ imageString:String) -> UIImage?{
        
        //空白を+に変換する
        let base64String = imageString.replacingOccurrences(of: " ", with:"+")
        
        //BASE64の文字列をデコードしてNSDataを生成
        let decodeBase64:Data? =
            Data(base64Encoded:base64String, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)
        //NSDataの生成が成功していたら
        if let decodeSuccess = decodeBase64 {
            
            //NSDataからUIImageを生成
            let img = UIImage(data: decodeSuccess)
            
            //結果を返却
            return img
        }
        
        return nil
        
    }
    
    
    
    func updating()  {
        if order_timer.isValid {
            order_timer.invalidate()
        }
        
        order_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updating), userInfo: nil, repeats: true)
        if order_time >= (order_start2end_alert.sound_interval)*60 {
        
//        if order_time >= order_elapsed_time {
            if is_alert_disp == true {
                is_alert_disp = !is_alert_disp
                // 音をだす
                // エラー音
                TapSound.errorBeep(order_start2end_alert_file.sound_file, type: order_start2end_alert_file.file_type)
                print("オーダー開始から5分経ちました。")
                
                let alertController = UIAlertController(title: "エラー！", message: "オーダー開始から" + (order_start2end_alert.sound_interval).description + "分経ちました。\nオーダー送信を忘れていませんか？", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default){
                    action in print("Pushed OK")
                    if order_timer.isValid == true {
                        // timerを破棄する
                        order_timer.invalidate()
                        TapSound.errorBeep_stop()
                        order_time = 0
                    }
                    return;
                }
                
                alertController.addAction(okAction)
                UIApplication.shared.topViewController()?.present(alertController, animated: true, completion: nil)
                
            }
            
            
        } else {
           order_time += 1
        }
        
//        print("updating_now_time:" + Date().description,order_time,order_start2end_alert.sound_interval)
    }
    
    func updating_resend() {
        
        if order_resend_timer.isValid {
            order_resend_timer.invalidate()
        }
        
        order_resend_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updating_resend), userInfo: nil, repeats: true)
        
//        print(order_resend_time,not_send_alert.sound_interval)
        if order_resend_time >= (not_send_alert.sound_interval) * 60 {
            
            if is_not_resend_alert_disp == true {
                is_not_resend_alert_disp = !is_not_resend_alert_disp
                // 音をだす
                // エラー音
                
                print("未送信のデータがあります" + (not_send_alert.sound_interval).description + "分経ちました。")
                
                let alertController = UIAlertController(title: "エラー！", message: "未送信データがあります。" + "\n再送して下さい" + "(" + (not_send_alert.sound_interval).description + ")", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default){
                    action in print("Pushed OK")
                    if order_resend_timer.isValid == true {
                        // timerを破棄する
                        order_resend_timer.invalidate()
                        TapSound.errorBeep_stop()
                    }
                    
                    if not_send_alert.interval > 0 {       // 繰り返しあり
                        self.updating_resend_interval()
                        order_resend_interval = 0
                        self.is_not_resend_alert_disp = true
                    }
                    return;
                }
                
                alertController.addAction(okAction)
                UIApplication.shared.topViewController()?.present(alertController, animated: true, completion: nil)
                // エラー音
                TapSound.errorBeep(not_send_alert_file.sound_file, type: not_send_alert_file.file_type)
            }

        } else {
            order_resend_time += 1
        }
    }
    
    func updating_resend_interval() {
        
        if order_resend_timer.isValid {
            order_resend_timer.invalidate()
        }
        
        order_resend_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updating_resend_interval), userInfo: nil, repeats: true)
        
        if order_resend_interval >= (not_send_alert.interval * 60) {
           
            
            if is_not_resend_alert_disp == true {
                is_not_resend_alert_disp = !is_not_resend_alert_disp
                // エラー音
                TapSound.errorBeep(not_send_alert_file.sound_file, type: not_send_alert_file.file_type)
                
                print("未送信のデータがあります" + (not_send_alert.interval).description + "分経ちました。")
                
                let alertController = UIAlertController(title: "エラー！", message: "未送信データがあります。" + "\n再送して下さい" + "(" + (not_send_alert.interval).description + "分)", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default){
                    action in print("Pushed OK")
                    if order_resend_timer.isValid == true {
                        // timerを破棄する
                        order_resend_timer.invalidate()
                        TapSound.errorBeep_stop()
                    }
                    
                    if not_send_alert.interval > 0 {       // 繰り返しあり
                        self.updating_resend_interval()
                        order_resend_interval = 0
                        self.is_not_resend_alert_disp = true
                    }
                    return;
                }
                
                alertController.addAction(okAction)
                UIApplication.shared.topViewController()?.present(alertController, animated: true, completion: nil)
                
            }
            
        } else {
            order_resend_interval += 1
        }
        
//        print("updating_resend_interval:",order_resend_interval)
    }

    func sendSynchronize(_ request:URLRequest,completion: @escaping (Data?, URLResponse?, NSError?) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        let subtask = URLSession.shared.dataTask(with: request, completionHandler: { data, res, error in
            completion(data, res, error as NSError?)
            semaphore.signal()
        })
        subtask.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
    
    @IBAction func playerGet(_ sender: AnyObject) {
        self.jsonGet_player()
        
    }
    
    
    // デモデータ取得
    fileprivate func getDemoData(){

        self.spinnerStart()
        let db_count:Float = 1.0/(Float(demo_Delete.count) + Float(demo_csv.count))
        // print(demo_Delete.count,demo_csv.count)
        
        self.dispatch_async_global {
            
            let db = FMDatabase(path: self._path_demo)
            
            // seat_holder テーブルの中身を削除
            db.open()
            // トランザクションを開始
            db.beginTransaction()
            
            // デモデータ削除
            for del in demo_Delete {
                let sql:String = String(del)
                let _ = db.executeUpdate(sql, withArgumentsIn: [])
                CustomProgress.Instance.progressChange += db_count
            }
            db.commit()
            
            //
            for csv in demo_csv {
                //                    print(demo_csv[num])
                //CSVファイル読み込み
                let csvBundle = Bundle.main.path(forResource: csv[0], ofType: csv[1])
                do {
                    let csvData: String = try String(contentsOfFile: csvBundle!, encoding: String.Encoding.utf8)
                    
                    let csvArray = csvData.lines
                    
                    var success = true
                    // トランザクションの開始
                    db.beginTransaction()
                    
                    for line in csvArray {
                        //                                                            print(line)
                        var staff_info:Array<Any> = []
                        let parts = line.components(separatedBy: ",")
                        
                        for part in parts {
                            staff_info.append(part)
                            //                                print(part)
                        }
                        let now = Date() // 現在日時の取得
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                        dateFormatter.timeStyle = .medium
                        dateFormatter.dateStyle = .medium
                        //                            print(dateFormatter.stringFromDate(now)) // -> 2014/06/24 11:14:17
                        
                        let created = dateFormatter.string(from: now)
                        let modified = dateFormatter.string(from: now)
                        
                        staff_info.append(created)
                        staff_info.append(modified)
                        //                                                            print(staff_info)
                        
                        let sql_insert = csv[2]
                        
                        // INSERT文を実行
                        success = db.executeUpdate(sql_insert, withArgumentsIn: staff_info)
                        // INSERT文の実行に失敗した場合
                        if !success {
                            print(staff_info)
                            // ループを抜ける
                            break
                        }
                    }
                    if success {
                        // 全てのINSERT文が成功した場合はcommit
                        print("success")
                        db.commit()
                        self.dispatch_async_main {
                            CustomProgress.Instance.progressChange += db_count
                        }
                        
                    } else {
                        print("not success")
                        // 1つでも失敗したらrollback
                        db.rollback()
                        
                        
                    }
                } catch let error as NSError {
                    
                    print(error.localizedDescription)
                }
            }
            self.dispatch_async_main {
                self.spinnerEnd()
            }
            db.close()
        }
    }
    
    
}
