//
//  exchangeSeatViewController.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/01/13.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB

class exchangeSeatViewController: UIViewController, UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate {

    fileprivate var onceTokenViewDidAppear: Int = 0
 
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var fromView: UIView!
    @IBOutlet weak var toView: UIView!
    @IBOutlet weak var allExchangeButton: UIButton!
    @IBOutlet weak var LtoRExchangeButton: UIButton!
    @IBOutlet weak var RtoLExchangeButton: UIButton!
    
    var exchangeImageView = UIImageView()
    
    fileprivate var initialIndexPath: IndexPath?
    fileprivate var currentLocationIndexPath: IndexPath?
    fileprivate var draggingView: UIView?
    fileprivate var scrollRate = 0.0
    fileprivate var scrollDisplayLink: CADisplayLink?
    
    // セルデータの型
    struct exchangeCellData{
        var seatNo:Int
        var saatName:String
        var holderNo:String
        var playerName:String
        var playerKana:String
    }
    
    var fromSeat:[exchangeCellData] = []
    var toSeat:[exchangeCellData] = []

    var fromSeatColor:[UIColor] = []
    var toSeatColor:[UIColor] = []
    
    var fColor = iOrder_darkGrayColor
    var tColor = iOrder_sakura
    
    // シートの名称データ
    var seatName:[String] = []

    // 着席情報のバックアップ
    var takeSeatPlayers_backup:[takeSeatPlayer] = []
    var takeSeatPlayers_to_backup:[takeSeatPlayer] = []
    
    //CustomProgressModelにあるプロパティが初期設定項目
    let initVal = CustomProgressModel()
    
    var fromTableView = UITableView()
    var toTableView = UITableView()
//    var toTableView = LPDROPTableView()
    
    // DBファイルパス
    var _path:String = ""

    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        return dateFormatter
    }()

    // ローカルのオーダーNo最大値
    var max_oeder_no : Int?

    let from_seat = 0
    let to_seat = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("ファイル",#function)
        
        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor
        
        // 戻るボタン
        let iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        backButton.setImage(Image, for: UIControlState())
        
        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.pressedLong(_:)))
        
        backButton.addGestureRecognizer(longPress)
        
        // 次へボタン
        let iconImage2 = FAKFontAwesome.chevronCircleRightIcon(withSize: iconSize)
        iconImage2?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image2 = iconImage2?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image2, for: UIControlState())
        
        // クリアボタン
        let iconImage3 = FAKFontAwesome.rotateLeftIcon(withSize: iconSize)
        iconImage3?.addAttribute(NSForegroundColorAttributeName, value: iOrder_greenColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image3 = iconImage3?.image(with: CGSize(width: iconSize, height: iconSize))
        clearButton.setImage(Image3, for: UIControlState())

        // 交換ボタン
        let iconImage4 = FAKFontAwesome.exchangeIcon(withSize: iconSize)
        iconImage4?.addAttribute(NSForegroundColorAttributeName, value: UIColor.black)
        let Image4 = iconImage4?.image(with: CGSize(width: iconSize, height: iconSize))
        allExchangeButton.setImage(Image4, for: UIControlState())
        // 表示枠をつける
        allExchangeButton.layer.borderWidth = 2.0
        // 枠の色を設定する
        allExchangeButton.layer.borderColor = iOrder_borderColor.cgColor
        // 角を丸くする
        allExchangeButton.layer.cornerRadius = 5

        // →ボタン
        let iconImage5 = FAKFontAwesome.longArrowRightIcon(withSize: iconSize)
        iconImage5?.addAttribute(NSForegroundColorAttributeName, value: UIColor.black)
        let Image5 = iconImage5?.image(with: CGSize(width: iconSize, height: iconSize))
        LtoRExchangeButton.setImage(Image5, for: UIControlState())
        // 表示枠をつける
        LtoRExchangeButton.layer.borderWidth = 2.0
        // 枠の色を設定する
        LtoRExchangeButton.layer.borderColor = iOrder_borderColor.cgColor
        // 角を丸くする
        LtoRExchangeButton.layer.cornerRadius = 5

        // ←ボタン
        let iconImage6 = FAKFontAwesome.longArrowLeftIcon(withSize: iconSize)
        iconImage6?.addAttribute(NSForegroundColorAttributeName, value: UIColor.black)
        let Image6 = iconImage6?.image(with: CGSize(width: iconSize, height: iconSize))
        RtoLExchangeButton.setImage(Image6, for: UIControlState())
        // 表示枠をつける
        RtoLExchangeButton.layer.borderWidth = 2.0
        // 枠の色を設定する
        RtoLExchangeButton.layer.borderColor = iOrder_borderColor.cgColor
        // 角を丸くする
        RtoLExchangeButton.layer.cornerRadius = 5

        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        
        // 使用DB
        var use_db = production_db
        if demo_mode != 0{
            use_db = demo_db
        }
        
        _path = (paths[0] as NSString).appendingPathComponent(use_db)

        // Viewの高さと幅を取得する.
        let displayWidth: CGFloat = (self.view.frame.width - 32) / 2
        let displayHeight: CGFloat = self.view.frame.height - toolBarHeight - barHeight - NavHeight

        
        // テーブルビューを作る
        // ここのLPRTableView　を　変更しよう
//        self.fromTableView = LPRTableView(frame: CGRect(x: 0, y: 0, width: displayWidth, height: displayHeight), style: UITableViewStyle.Plain)
        self.fromTableView = UITableView(frame: CGRect(x: 0, y: 0, width: displayWidth, height: displayHeight), style: UITableViewStyle.plain)
        
        let longPress1 = UILongPressGestureRecognizer(target: self, action: #selector(exchangeSeatViewController.pressedLongCell1(_:)))
        
        fromTableView.addGestureRecognizer(longPress1)

        // テーブルビューを追加する
        fromTableView.tag = 1
        self.fromView.insertSubview(self.fromTableView, belowSubview: allExchangeButton)
//        self.fromView.addSubview(self.fromTableView)
        
//        self.toTableView = LPDROPTableView(frame: CGRect(x: 0, y: 0, width: displayWidth, height: displayHeight), style: UITableViewStyle.Plain)
        self.toTableView = UITableView(frame: CGRect(x: 0, y: 0, width: displayWidth, height: displayHeight), style: UITableViewStyle.plain)
//        self.toTableView = LPRTableView(frame: CGRect(x: 0, y: 0, width: displayWidth, height: displayHeight), style: UITableViewStyle.Plain)

        let longPress2 = UILongPressGestureRecognizer(target: self, action: #selector(exchangeSeatViewController.pressedLongCell2(_:)))
        
        toTableView.addGestureRecognizer(longPress2)

        toTableView.tag = 2
        self.toView.insertSubview(self.toTableView, belowSubview: allExchangeButton)
//        self.toView.addSubview(self.toTableView)
        
        // テーブルビューのデリゲートとデータソースになる
        self.fromTableView.delegate = self
        self.fromTableView.dataSource = self
        
        self.toTableView.delegate = self
        self.toTableView.dataSource = self

        // xibをテーブルビューのセルとして使う
        let xib = UINib(nibName: "exchangeSeatTableViewCell", bundle: nil)
        self.fromTableView.register(xib, forCellReuseIdentifier: "Cell")
        self.toTableView.register(xib, forCellReuseIdentifier: "Cell")
        
        // シートNO順でソート
        seat.sort{$0.seat_no < $1.seat_no}
        print(seat)
        fromSeatColor = []
        for s in seat {
            self.seatName.append(s.seat_name)
            fromSeatColor.append(fColor)
        }

        toSeatColor = []
        for _ in seat_to {
            toSeatColor.append(tColor)
        }
        
        // 移動元、移動先の在席情報を保存する
        takeSeatPlayers_backup = takeSeatPlayers
        takeSeatPlayers_to_backup = takeSeatPlayers_to
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ファイル",#function)
        self.loadData()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("ファイル",#function)
        DemoLabel.Show(self.view)
        DemoLabel.modeChange()
        
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
        print("ファイル",#function)
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        // 表示順でソート
        seat.sort{$0.seat_no < $1.seat_no}
        
        // シート数分ループ(FROM)
//        print("FROM",takeSeatPlayers)
        self.fromSeat = []
        
        for s in seat {
            let index = takeSeatPlayers.index(where: {$0.seat_no == s.seat_no})
            if index != nil {
                let p_no = takeSeatPlayers[index!].holder_no
                if p_no != "" {
//                    let sql = "select * from players where member_no in (?);"
                    
                    let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [p_no,shop_code,globals_today + "%"])
//                    let results = db.executeQuery(sql, withArgumentsIn: [p_no])
                    var is_no = true
                    while (results?.next())! {
                        is_no = false
                        let mn = (results?.string(forColumn:"member_no") != nil) ? results!.string(forColumn:"member_no") : ""
                        
                        let pnkana = (results?.string(forColumn:"player_name_kana") != nil) ? results?.string(forColumn:"player_name_kana") : ""
                        let pnkanji = (results?.string(forColumn:"player_name_kanji") != nil) ? results?.string(forColumn:"player_name_kanji") : ""
                        
                        self.fromSeat.append(exchangeCellData(
                            seatNo: s.seat_no,
                            saatName: s.seat_name,
                            holderNo: mn!,
                            playerName: pnkanji!,
                            playerKana: pnkana!
                            )
                        )
                    }
                    
                    // レコードが存在しない場合
                    if is_no == true {
                        self.fromSeat.append(exchangeCellData(
                            seatNo: s.seat_no,
                            saatName: s.seat_name,
                            holderNo: p_no,
                            playerName: "",
                            playerKana: ""
                            )
                        )
                        
                    }
                } else {    // 空き席の分を作る
                    self.fromSeat.append(exchangeCellData(
                        seatNo: s.seat_no,
                        saatName: s.seat_name,
                        holderNo: "",
                        playerName: "",
                        playerKana: ""
                        )
                    )
                    
                }
            } else {
                self.fromSeat.append(exchangeCellData(
                    seatNo: s.seat_no,
                    saatName: s.seat_name,
                    holderNo: "",
                    playerName: "",
                    playerKana: ""
                    )
                )
                
            }
        }
        print("FROM",fromSeat)
        
        // 表示順でソート
        seat_to.sort{$0.seat_no < $1.seat_no}
        
        // シート数分ループ(TO)
        
        self.toSeat = []
        for s in seat_to {
            let index = takeSeatPlayers_to.index(where: {$0.seat_no == s.seat_no})
            if index != nil {
                let p_no = takeSeatPlayers_to[index!].holder_no
                if p_no != "" {
//                    let sql = "select * from players where member_no in (?);"
                    

                    
                    let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [p_no,shop_code,globals_today + "%"])
//                    let results = db.executeQuery(sql, withArgumentsIn: [p_no])
                    var is_no = true
                    while results!.next() {
                        is_no = false
                        let mn = (results!.string(forColumn: "member_no") != nil) ? results!.string(forColumn: "member_no") : ""
                        
                        let pnkana = (results!.string(forColumn: "player_name_kana") != nil) ? results!.string(forColumn: "player_name_kana") : ""
                        let pnkanji = (results!.string(forColumn: "player_name_kanji") != nil) ? results!.string(forColumn: "player_name_kanji") : ""
                        
                        self.toSeat.append(exchangeCellData(
                            seatNo: s.seat_no,
                            saatName: s.seat_name,
                            holderNo: mn!,
                            playerName: pnkanji!,
                            playerKana: pnkana!
                            )
                        )
                        
                    }
                    
                    // レコードが存在しない場合
                    if is_no == true {
                        self.toSeat.append(exchangeCellData(
                            seatNo: s.seat_no,
                            saatName: s.seat_name,
                            holderNo: p_no,
                            playerName: "",
                            playerKana: ""
                            )
                        )
                        
                    }
                } else {    // 空き席の分を作る
                    self.toSeat.append(exchangeCellData(
                        seatNo: s.seat_no,
                        saatName: s.seat_name,
                        holderNo: "",
                        playerName: "",
                        playerKana: ""
                        )
                    )
                    
                }
            } else {
                self.toSeat.append(exchangeCellData(
                    seatNo: s.seat_no,
                    saatName: s.seat_name,
                    holderNo: "",
                    playerName: "",
                    playerKana: ""
                    )
                )
                takeSeatPlayers_to.append(takeSeatPlayer(
                    seat_no: s.seat_no,
                    holder_no: ""
                    )
                )
            }
        }
        
        db.close()
        print("TO",toSeat)

        
        self.fromTableView.reloadData()
        self.toTableView.reloadData()
    }
    
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 行数はセルデータの個数
        var line = 0
        if tableView.tag == 1 {
            line = seat.count
        } else {
            line = seat_to.count
        }
        
        return line
    }

    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        print("ファイル",#function)
        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! exchangeSeatTableViewCell
        
//        print("tableview",tableView.tag,indexPath)
        // セルに表示するデータを取り出す
        if tableView.tag == 1 {         // FROM
            if fromSeat.count >= indexPath.row {
                let cellData = fromSeat[indexPath.row]
                let cellColor = fromSeatColor[indexPath.row]
                
                let seat    = cellData.saatName
                let holder  = cellData.holderNo
                let name    = cellData.playerName
                let kana    = cellData.playerKana
                
                cell.exchangeCellSeat.text = seat
                cell.exchangeCellSeat.backgroundColor = cellColor
                cell.exchangeCellHolder.text = holder
                cell.exchangeCellName.text = name
                cell.exchangeCellKana.text = kana
                
            }
            
        } else {                        // TO
            if toSeat.count >= indexPath.row {
                let cellData = toSeat[indexPath.row]
                let cellColor = toSeatColor[indexPath.row]
                
                let seat    = cellData.saatName
                let holder  = cellData.holderNo
                let name    = cellData.playerName
                let kana    = cellData.playerKana
                
                cell.exchangeCellSeat.text = seat
                cell.exchangeCellSeat.backgroundColor = cellColor
                cell.exchangeCellHolder.text = holder
                cell.exchangeCellName.text = name
                cell.exchangeCellKana.text = kana
            }
        }
        
        
        return cell
    }
    
    // セルの編集モード設定
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // スワイプして右にボタンを出す
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        var myDeleteButton: UITableViewRowAction?

        
        // Deleteボタン.
        myDeleteButton = UITableViewRowAction(style: .normal, title: "削除") { (action, index) -> Void in
            
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            tableView.isEditing = false
            print("delete")
            
            if tableView.tag == 1 {
                let index = takeSeatPlayers.index(where: {$0.holder_no == self.fromSeat[indexPath.row].holderNo})
                if index != nil {
                    takeSeatPlayers[index!].holder_no = ""
                    self.fromSeatColor[indexPath.row] = self.fColor
                    self.loadData()
                }
            } else {
                let index = takeSeatPlayers_to.index(where: {$0.holder_no == self.toSeat[indexPath.row].holderNo})
                if index != nil {
                    takeSeatPlayers_to[index!].holder_no = ""
                    self.toSeatColor[indexPath.row] = self.tColor
                    self.loadData()
                }
            }
        }
        myDeleteButton!.backgroundColor = UIColor.red
        return [myDeleteButton!]
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // セルの高さを返す（UITableViewDelegate）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
//        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! exchangeSeatTableViewCell
        
        let cell_height:CGFloat = tableView.bounds.height / 5
        
        
        // セルの高さ
        return cell_height
    }

    // セクションヘッダーの高さ
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    // セクションのタイトルを詳細に設定
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        print("ファイル",#function)
        let headerView = UITableViewHeaderFooterView()
        headerView.backgroundView?.backgroundColor = UIColor.green

        let fontName = "YuGo-Bold"    // "YuGo-Bold"
        
        let tableNoLabel = UILabel()
        let w:CGFloat = tableView.bounds.width - 10
        tableNoLabel.frame = CGRect(x: 5, y: 2, width: w, height: 40)
        //        countLabel.backgroundColor = iOrder_greenColor
        tableNoLabel.textAlignment = .natural
        tableNoLabel.textColor = iOrder_blackColor
        // フォント名の指定はPostScript名
        tableNoLabel.font = UIFont(name: fontName,size: CGFloat(20))

        tableNoLabel.numberOfLines = 1
        tableNoLabel.adjustsFontSizeToFitWidth = true
        tableNoLabel.minimumScaleFactor = 0.5
        tableNoLabel.lineBreakMode = .byTruncatingTail
        tableNoLabel.baselineAdjustment = UIBaselineAdjustment.alignCenters
        let tn = tableView.tag == 1 ? globals_table_no : globals_exchange_table_no
        tableNoLabel.text = "テーブルNO：" + "\(tn)"
        headerView.addSubview(tableNoLabel)
        return headerView
        
    }
    
    // 全入れ替えボタンタップ
    @IBAction func allExchangeButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let left = takeSeatPlayers
        let right = takeSeatPlayers_to
        
        let left_c = fromSeatColor
        let right_c = toSeatColor
        
        takeSeatPlayers = []
        takeSeatPlayers_to = []
        
        
        takeSeatPlayers = right
        takeSeatPlayers_to = left
        
        fromSeatColor = []
        for (i,_) in seat.enumerated() {
            if right_c.count > i {
                fromSeatColor.append(right_c[i])
            } else {
                fromSeatColor.append(fColor)
            }
        }
//        print(fromSeatColor)
        
        toSeatColor = []
        for (j,_) in seat_to.enumerated() {
            if left_c.count > j {
                toSeatColor.append(left_c[j])
                
            } else {
                toSeatColor.append(tColor)
                
            }
        }
//        print(toSeatColor)
        self.loadData()
        
    }
    
    // 左から右に移動ボタンタップ
    @IBAction func LtoRExchangeButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let left = takeSeatPlayers
        let right = takeSeatPlayers_to
        
        let left_c = fromSeatColor
        let right_c = toSeatColor
        
        takeSeatPlayers = []
        takeSeatPlayers_to = []
        
        
        takeSeatPlayers = right

        for i in 0..<takeSeatPlayers.count {
            takeSeatPlayers[i].holder_no = ""
        }
        
        takeSeatPlayers_to = left
        
        fromSeatColor = []
        for (i,_) in seat.enumerated() {
            if right_c.count > i {
                fromSeatColor.append(right_c[i])
            } else {
                fromSeatColor.append(fColor)
            }
        }
        
        toSeatColor = []
        for (j,_) in seat_to.enumerated() {
            if left_c.count > j {
                toSeatColor.append(left_c[j])
                
            } else {
                toSeatColor.append(tColor)
                
            }
        }
        self.loadData()

    }
    
    // 右から左に移動ボタンタップ
    @IBAction func RtoLExchangeButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        let left = takeSeatPlayers
        let right = takeSeatPlayers_to
        
        let left_c = fromSeatColor
        let right_c = toSeatColor
        
        takeSeatPlayers = []
        takeSeatPlayers_to = []
        
        
        takeSeatPlayers = right
        takeSeatPlayers_to = left
        for i in 0..<takeSeatPlayers_to.count {
            takeSeatPlayers_to[i].holder_no = ""
        }
        
        
        fromSeatColor = []
        for (i,_) in seat.enumerated() {
            if right_c.count > i {
                fromSeatColor.append(right_c[i])
            } else {
                fromSeatColor.append(fColor)
            }
        }
        
        toSeatColor = []
        for (j,_) in seat_to.enumerated() {
            if left_c.count > j {
                toSeatColor.append(left_c[j])
                
            } else {
                toSeatColor.append(tColor)
                
            }
        }
        self.loadData()

    }
    
    // 確定ボタンタップ
    @IBAction func OKButton(_ sender: UIButton) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // 確認のアラート画面を出す
        // タイトル
        let alert: UIAlertController = UIAlertController(title: "確認", message: "座席移動します。よろしいですか？", preferredStyle: UIAlertControllerStyle.alert)
      
        // アクションの設定
        let defaultAction: UIAlertAction = UIAlertAction(title: "右側のテーブルでオーダーを取る", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) -> Void in
            print("OK")
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

            // 本番モード
            if demo_mode == 0 {
                self.exchangeSeatInfoSend(1,from_s: self.to_seat)

                
            } else {    // デモモード
                
                self.take_seat_player_save()
                globals_table_no = globals_exchange_table_no
                
                takeSeatPlayers = []
                takeSeatPlayers = takeSeatPlayers_to
                
                seat = []
                seat = seat_to
                
                self.seat_holder_save()
                self.performSegue(withIdentifier: "toPlayerssetSegue2",sender: nil)
            }
            
        })
        
        // アクションの設定
        let defaultRightAction: UIAlertAction = UIAlertAction(title: "左側のテーブルでオーダーを取る", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) -> Void in
            print("OK")
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            
            // 本番モード
            if demo_mode == 0 {
                self.exchangeSeatInfoSend(1,from_s: self.from_seat)
                
                
            } else {    // デモモード
                self.take_seat_player_save()

                self.seat_holder_save()
                
                self.performSegue(withIdentifier: "toPlayerssetSegue2",sender: nil)
            }
        })
        
        let changeOnlyAction:UIAlertAction = UIAlertAction(title: "席移動のみ行う", style: .default , handler: {(action: UIAlertAction!) -> Void in
            print("キャンセル")
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            
            // 本番モード
            if demo_mode == 0 {
                self.exchangeSeatInfoSend(2,from_s: self.to_seat)
            } else {
                self.take_seat_player_save()

                self.seat_holder_save()
                self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
            }
        })
        
        // キャンセルボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler: {(action: UIAlertAction!) -> Void in
            print("キャンセル")
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            
        })
        
        // UIAlertControllerにActionを追加
        alert.addAction(cancelAction)
        alert.addAction(changeOnlyAction)
        alert.addAction(defaultAction)
        alert.addAction(defaultRightAction)
        
        // Alertを表示
        present(alert, animated: true, completion: nil)

    }
    
    // 元に戻すボタンタップ
    @IBAction func clearButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        self.recovery_seat()
        
        self.loadData()

    }

        
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // 戻るときは、席情報を元にもどしてから
        
        self.recovery_seat()
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        self.performSegue(withIdentifier: "toEexchangeTableNoInputViewSegue",sender: nil)
    }

    func recovery_seat() {
        takeSeatPlayers = []
        takeSeatPlayers_to = []
        
        takeSeatPlayers = takeSeatPlayers_backup
        takeSeatPlayers_to = takeSeatPlayers_to_backup
        
        fromSeatColor = []
        for _ in seat {
            fromSeatColor.append(fColor)
        }
        
        toSeatColor = []
        for _ in seat_to {
            toSeatColor.append(tColor)
        }

    }
    
    // 移動元セルを長押ししたときの処理
    @IBAction func pressedLongCell1(_ sender: UILongPressGestureRecognizer!) {
//        print("long press　Cell1")
        let point: CGPoint = sender.location(in: self.fromTableView)
        let cnvPoint = fromTableView.convert(point, to: self.view)
        let indexPath = self.fromTableView.indexPathForRow(at: point)
        
        // ジェスチャーの状態に応じて処理を分ける
        switch sender.state {
        case .began:
            if let indexPath = indexPath {
                if let cell = self.fromTableView.cellForRow(at: indexPath) {
                    print("began1",cell.frame)
                    
                    let rect:CGRect = cell.frame
                    
                    cell.setSelected(false, animated: false)
                    cell.setHighlighted(false, animated: false)
                    
                                        
                    // Make an image from the pressed table view cell.
                    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, false, 0.0)
                    cell.layer.render(in: UIGraphicsGetCurrentContext()!)
                    
                    let cellImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    draggingView = UIImageView(image: cellImage)
                    
                    if let draggingView = draggingView {
                        self.view.addSubview(draggingView)

                        let absolutePosition = fromTableView.convert(rect, to: self.view)
                        print("absolutePosition",absolutePosition)
                        draggingView.frame = CGRect(x: absolutePosition.origin.x, y: absolutePosition.origin.y,width: draggingView.bounds.width, height: draggingView.bounds.height)
//                        print("absolutePosition2",draggingView.frame)

                        UIView.beginAnimations("LongPressReorder-ShowDraggingView", context: nil)
                        
                        UIView.commitAnimations()
                        
                        // Add drop shadow to image and lower opacity.
                        draggingView.layer.masksToBounds = false
                        draggingView.layer.shadowColor = UIColor.black.cgColor
                        draggingView.layer.shadowOffset = CGSize.zero
                        draggingView.layer.shadowRadius = 4.0
                        draggingView.layer.shadowOpacity = 0.7
                        draggingView.layer.opacity = 0.85
                        
                        // Zoom image towards user.
                        UIView.beginAnimations("LongPressReorder-Zoom", context: nil)
                        
                        draggingView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)

                        UIView.commitAnimations()
                        
                    }
                    
                    cell.isHidden = true
                    currentLocationIndexPath = indexPath
                    initialIndexPath = indexPath
                }
            }
            
            break
        case .changed:
            // 移動量を取得する
            let move:CGPoint = CGPoint(x: cnvPoint.x, y: cnvPoint.y)
//            print("changed1",move)
            // ドラッグした部品の座標に移動量を加算する
            draggingView!.center = move
            
            break

        case .cancelled:
            print("cancel")
            break
        case .ended:
            print("end")
            // Remove scrolling CADisplayLink.
            scrollDisplayLink?.invalidate()
            scrollDisplayLink = nil
            scrollRate = 0.0
            
            
            // 離した位置が toTableView の中か？
            print(point)
            // toTableViewの絶対位置を取得
            let absolutePosition = toTableView.superview!.convert(toTableView.frame, to: nil)
            let w:CGFloat = toTableView.bounds.width
            let h:CGFloat = toTableView.bounds.height
            let x:CGFloat = absolutePosition.origin.x
            let y:CGFloat = absolutePosition.origin.y
            
            print(w,h,x,y)
            if (cnvPoint.x >= x && cnvPoint.x <= (x + w)) && (cnvPoint.y >= y && cnvPoint.y <= (y + h)){
                // toTableView内の位置
//                let p = CGPointMake(point.x - x , point.y)
                // 移動ポイントの絶対位置をテーブル内のポイントに変更
                let cnvP = fromView.superview?.convert(cnvPoint, to: toTableView)
                
//                print(p,cnvP,cnvPoint)
//                let indexPath_to = self.toTableView.indexPathForRowAtPoint(p)
                let indexPath_to = self.toTableView.indexPathForRow(at: cnvP!)
                
                if let indexPath_to = indexPath_to {
                    print(indexPath_to)
                    let f_cell = takeSeatPlayers[(self.currentLocationIndexPath?.row)!]
                    let f_color = fromSeatColor[(self.currentLocationIndexPath?.row)!]
                    
                    let t_cell = takeSeatPlayers_to[indexPath_to.row]
                    let t_color = toSeatColor[indexPath_to.row]
                    
                    
                    print(f_cell,currentLocationIndexPath as Any)
                    print(t_cell,indexPath_to)
                    takeSeatPlayers[(self.currentLocationIndexPath?.row)!].holder_no = t_cell.holder_no
                    takeSeatPlayers_to[indexPath_to.row].holder_no = f_cell.holder_no
                    
                    fromSeatColor[(self.currentLocationIndexPath?.row)!] = t_color
                    
                    toSeatColor[indexPath_to.row] = f_color
                    
                    self.loadData()
                    
                    if let draggingView = self.draggingView {
                        draggingView.removeFromSuperview()
                    }
                    
                    // Reload the rows that were affected just to be safe.
                    
                    self.currentLocationIndexPath = nil
                    self.draggingView = nil
                    
                } else {
                    if let draggingView = self.draggingView {
                        draggingView.removeFromSuperview()
                        fromTableView.reloadData()
                    }
                }
                

                
            } else {
                if let draggingView = self.draggingView {
                    draggingView.removeFromSuperview()
                    fromTableView.reloadData()
                }
            }
            
            break
        case .failed:
            print("failed")
            break
        default:
            break
        }
    }

    // 移動先セルを長押ししたときの処理
    @IBAction func pressedLongCell2(_ sender: UILongPressGestureRecognizer!) {
//        print("long press　Cell2")
        let point: CGPoint = sender.location(in: self.toTableView)
        let cnvPoint = toTableView.convert(point, to: self.view)
        let indexPath = self.toTableView.indexPathForRow(at: point)
//        let convPoint: CGPoint = sender.locationInView(self.view)

        
        // ジェスチャーの状態に応じて処理を分ける
        switch sender.state {
        case .began:
            
            if let indexPath = indexPath {
                if let cell = self.toTableView.cellForRow(at: indexPath) {
                    print("began2",cell.frame)
                    cell.setSelected(false, animated: false)
                    cell.setHighlighted(false, animated: false)
                    
                    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, false, 0.0)
                    cell.layer.render(in: UIGraphicsGetCurrentContext()!)
                    
                    let cellImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    draggingView = UIImageView(image: cellImage)
                    
                    if let draggingView = draggingView {
                        self.view.addSubview(draggingView)
                        
                        let absolutePosition = toTableView.convert(cell.frame, to: self.view)
//                        draggingView.frame = CGRectOffset(draggingView.bounds, absolutePosition.origin.x, absolutePosition.origin.y)
                        draggingView.frame = CGRect(x: absolutePosition.origin.x, y: absolutePosition.origin.y,width: draggingView.bounds.width, height: draggingView.bounds.height)
                        UIView.beginAnimations("LongPressReorder-ShowDraggingView", context: nil)
                        UIView.commitAnimations()
                        
                        // Add drop shadow to image and lower opacity.
                        draggingView.layer.masksToBounds = false
                        draggingView.layer.shadowColor = UIColor.black.cgColor
                        draggingView.layer.shadowOffset = CGSize.zero
                        draggingView.layer.shadowRadius = 4.0
                        draggingView.layer.shadowOpacity = 0.7
                        draggingView.layer.opacity = 0.85
                        
                        // Zoom image towards user.
                        UIView.beginAnimations("LongPressReorder-Zoom", context: nil)
                        
                        draggingView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                        
//                        let move:CGPoint = CGPointMake(convPoint.x, point.y + ((draggingView.bounds.height  * 1.1) / 2))
//                        draggingView.center = move
                        UIView.commitAnimations()
                        
                    }
                    
                    cell.isHidden = true
                    currentLocationIndexPath = indexPath
                    initialIndexPath = indexPath
                }
            }
            
            break
        case .changed:
            // 移動量を取得する
            let move:CGPoint = CGPoint(x: cnvPoint.x, y: cnvPoint.y)
//            print("changed2",move)
            // ドラッグした部品の座標に移動量を加算する
            draggingView!.center = move
            
            break
            
        case .cancelled:
            print("cance2")
            break
        case .ended:
            print("end2")
            // Remove scrolling CADisplayLink.
            scrollDisplayLink?.invalidate()
            scrollDisplayLink = nil
            scrollRate = 0.0
            
            // 離した位置が toTableView の中か？
            print(point,cnvPoint)
            // fromTableViewの絶対位置を取得
            let absolutePosition = fromTableView.superview!.convert(fromTableView.frame, to: nil)
            let w:CGFloat = fromTableView.bounds.width
            let h:CGFloat = fromTableView.bounds.height
            let x:CGFloat = absolutePosition.origin.x
            let y:CGFloat = absolutePosition.origin.y
            
            print(w,h,x,y)
            if (cnvPoint.x >= x && cnvPoint.x <= (x + w)) && (cnvPoint.y >= y && cnvPoint.y <= (y + h)){
                // fromTableView内の位置
//                let p = CGPointMake(cnvPoint.x - x , cnvPoint.y)
                // 移動ポイントの絶対位置をテーブル内のポイントに変更
                let cnvP = toTableView.convert(point, to: fromTableView)
                print(point,cnvP,cnvPoint)
                let indexPath_to = self.fromTableView.indexPathForRow(at: cnvP)
                
                if let indexPath_to = indexPath_to {
                    let f_cell = takeSeatPlayers[indexPath_to.row]
                    let f_color = fromSeatColor[indexPath_to.row]
                    
                    let t_cell = takeSeatPlayers_to[(self.currentLocationIndexPath?.row)!]
                    let t_color = toSeatColor[(self.currentLocationIndexPath?.row)!]
                    
                    
                    print(f_cell,indexPath_to)
                    print(t_cell,currentLocationIndexPath as Any)
                    takeSeatPlayers[indexPath_to.row].holder_no = t_cell.holder_no
                    takeSeatPlayers_to[(self.currentLocationIndexPath?.row)!].holder_no = f_cell.holder_no
                    
                    fromSeatColor[indexPath_to.row] = t_color
                    
                    toSeatColor[(self.currentLocationIndexPath?.row)!] = f_color
                    
                    self.loadData()
                    
                    if let draggingView = self.draggingView {
                        draggingView.removeFromSuperview()
                    }
                    
                    // Reload the rows that were affected just to be safe.
                    
                    self.currentLocationIndexPath = nil
                    self.draggingView = nil
                } else {
                    if let draggingView = self.draggingView {
                        draggingView.removeFromSuperview()
                        toTableView.reloadData()
                    }
                }
                
                
                
            } else {
                if let draggingView = self.draggingView {
                    draggingView.removeFromSuperview()
                    toTableView.reloadData()
                }
            }
            
            break
        case .failed:
            print("failed")
            break
        default:
            break
        }

    }

    // 戻るボタンを長押ししたときの処理
    @IBAction func pressedLong(_ sender: UILongPressGestureRecognizer!) {
        
        let alertController = UIAlertController(title: "戻るが長押しされました", message: "メインメニューに戻りますか？\n入力中の内容がすべて消去されます！", preferredStyle: .alert)
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
        }
    }
    
    override func motionCancelled(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion cancelled")
        }
    }
    
    func dispatch_async_main(_ block: @escaping () -> ()) {
        DispatchQueue.main.async(execute: block)
    }
    
    func dispatch_async_global(_ block: @escaping () -> ()) {
        DispatchQueue.global().async (execute: block)
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
    
    func jsonError(){
        // エラー音
        TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)

        // エラー表示        
        self.spinnerEnd()
        let alertController = UIAlertController(title: "エラー！", message: "残数取り込みに失敗しました。", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }

    
    
    // 席移動情報の送信
    func exchangeSeatInfoSend(_ mode:Int,from_s:Int) {
        var table = [takeSeatPlayers,takeSeatPlayers_to]
        var t_no = [globals_table_no,globals_exchange_table_no]
        var seat_temp = [seat,seat_to]
        if from_s == from_seat {
            table = [takeSeatPlayers_to,takeSeatPlayers]
            t_no = [globals_exchange_table_no,globals_table_no]
            seat_temp = [seat_to,seat]
        }
        
        
        for fromTo in 0...1{
            // セクション
            Section = []
            
            for s in seat_temp[fromTo] {
                let index = table[fromTo].index(where: {$0.seat_no == s.seat_no})
                if index != nil {
                    Section.append(SectionData(
                        seat_no:s.seat_no,
                        seat: s.seat_name,
                        No: table[fromTo][index!].holder_no,
                        Name: fmdb.getPlayerName(table[fromTo][index!].holder_no)
                        )
                    )
                    
                } else {        // 人がいない場合は空データをセットする
                    Section.append(SectionData(
                        seat_no:s.seat_no,
                        seat: s.seat_name,
                        No: "",
                        Name: ""
                        )
                    )
                }
            }
            print("exchange",fromTo,Section)
            
            var params:[[String:Any]] = [[:]]
            
            params[0]["Process_Div"] = "1"
            
            var cnt = 0
            
            let db = FMDatabase(path: self._path)
            // データベースをオープン
            db.open()
//            let sql = "SELECT * FROM players WHERE member_no in (?);"
            //              let sql1 = "SELECT * FROM menus_master WHERE item_no = ?"
            let sql2 = "SELECT * FROM staffs_now;"
            
            let sql6 = "SELECT COUNT(*) FROM iOrder WHERE facility_cd = 1 AND store_cd = " + shop_code.description + " AND order_no > ?"
            
            self.dateFormatter.locale = Locale.current
            self.dateFormatter.dateFormat = "MMddyy"
            
            // 2016/11/1 の場合 201611010000 にする
            let datestr = self.dateFormatter.string(from: Date())
            let dateInt = Int(datestr)! * 10000
            var staff = ""
            
            // 担当者名を取得
            let rs2 = db.executeQuery(sql2, withArgumentsIn: [])
            while (rs2?.next())! {
                staff = (rs2?.string(forColumn:"staff_no"))!
            }
            // 内部で保持しているオーダーNOの最大値取得
            let rs6 = db.executeQuery(sql6, withArgumentsIn: [dateInt])
            while (rs6?.next())! {
                self.max_oeder_no = dateInt + Int((rs2?.int(forColumnIndex:0))!) + 1
            }
            
            for sec in Section {
                // プライス区分取得
                var price_kbn = "1"     // 存在しないプレイヤーの場合
                
                if sec.No != "" {
                    
                    let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [Int(sec.No)!,shop_code,globals_today + "%"])
//                    let results = db.executeQuery(sql, withArgumentsIn: [Int(sec.No)!])
                    
                    while results!.next() {
                        
                        price_kbn = "\(results!.int(forColumn: "price_tanka"))"
                    }
                }
                
                //                    let mm = MainMenu.filter({$0.No == sec.No})
                // 席移動の場合は空データを送信する。
                cnt += 1
                
                params.append([String:Any]())
                params[cnt]["Store_CD"] = shop_code.description
                params[cnt]["Table_NO"] = "\(t_no[fromTo])"
                params[cnt]["Detail_KBN"] = "2"
                params[cnt]["Order_KBN"] = "1"
                params[cnt]["Seat_NO"] = "\(sec.seat_no + 1)"
                params[cnt]["Menu_CD"] = ""
                params[cnt]["Menu_SEQ"] = ""
                params[cnt]["Store_Menu_CD"] = "1"
                params[cnt]["Sub_Menu_KBN"] = ""
                params[cnt]["Sub_Menu_CD"] = ""
                params[cnt]["Spe_Menu_KBN"] = ""
                params[cnt]["Spe_Menu_CD"] = ""
                params[cnt]["Category_CD1"] = ""
                params[cnt]["Category_CD2"] = ""
                params[cnt]["Timezone_KBN"] = "\(globals_timezone)"
                params[cnt]["Qty"] = ""
                params[cnt]["Serve_Customer_NO"] = sec.No
                params[cnt]["Payment_Customer_NO"] = ""
                params[cnt]["Employee_CD"] = staff
                params[cnt]["Unit_Price_KBN"] = price_kbn
                params[cnt]["Pm_Start_Time"] = globals_pm_start_time
                params[cnt]["Handwriting"] = ""
                params[cnt]["SendTime"] = ""                    // 送信日時（yyyy/mm/dd HH:mm:ss）（拡張用）
                params[cnt]["Selling_Price"] = ""               // 金額（拡張用）
                params[cnt]["TerminalID"] = TerminalID          // 端末ID（拡張用）
                params[cnt]["Reference"] = ""                   // メニュー名
                params[cnt]["Payment_Customer_Seat_No"] = "\(sec.seat_no + 1)"    // 支払い者シートNo　2/23 Add
                params[cnt]["Slip_NO"] = ""                     // 伝票番号 2/23 Add
            }
            
            let json = JSON(params)
            
            let str = "sJson=" + json.toString()
            let strData = str.data(using: String.Encoding.utf8)
            
            let url = URL(string:urlString + "SendOrder")
            var request = URLRequest(url: url!)
            
            print(str)
            
            request.httpMethod = "POST"
            request.httpBody = strData
            request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 10.0
            
            print("START")
           
//            self.dispatch_async_global{
                self.sendSynchronize(request, completion:{ data, res, error in
                    if error == nil {       // エラーじゃない時
                        do {
                            let json2 = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments ) as! NSDictionary
                            print(json2)
                            for j2 in json2 {
                                if j2.key as! String == "Return" {
                                    if j2.value as! String == "true" {
                                        if fromTo == 1 {
                                            if from_s == self.to_seat {
                                                globals_table_no = globals_exchange_table_no
                                                
                                                takeSeatPlayers = []
                                                takeSeatPlayers = takeSeatPlayers_to
                                                
                                                seat = []
                                                seat = seat_to
                                            }
                                            
                                            // seat_holder テーブルの中身を削除
                                            db.open()
                                            let sql10 = "DELETE FROM seat_holder;"
                                            let _ = db.executeUpdate(sql10, withArgumentsIn: [])
                                            
                                            let sql11 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
                                            db.beginTransaction()
                                            for takeSeatPlayer in takeSeatPlayers {
                                                let success = db.executeUpdate(sql11, withArgumentsIn: [takeSeatPlayer.seat_no,takeSeatPlayer.holder_no])
                                                if !success {
                                                    print("insert error!!")
                                                }
                                            }
                                            db.commit()
                                            
                                            
                                            self.dispatch_async_main{
                                                var identiferName = ""
                                                if mode == 1 {
                                                    identiferName = "toPlayerssetSegue2"
                                                } else {
                                                    //                                                    identiferName = "toTableNoInputViewSegue"
                                                    // 席移動のみの場合はトップに戻る（2017/03/16）
                                                    identiferName = "toTopViewSegue"
                                                }
                                                self.performSegue(withIdentifier: identiferName,sender: nil)
                                            }
                                            
                                        }
                                    }
                                    
                                }
                                if j2.key as! String == "Message" {
                                    if j2.value as! String != "" {
                                        let msg = j2.value as! String
                                        print(msg)
                                        self.dispatch_async_main{
                                            self.return_error(msg)
                                        }
                                        break
                                    }
                                    
                                }
                            }

                            
                        } catch  {
                            // エラー処理
                            print("ERROR",error)
                        }
                    
                    } else {
                        print("ERROR",error as Any)
                    }
                })
            
            
/*
                self.sendSynchronize(request, completion:{data, res, error in
                    do {
                        if error == nil {       // エラーじゃない時
                            let json2 = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.AllowFragments ) as! NSDictionary
                            print(json2)
                            for j2 in json2 {
                                if j2.key as! String == "Return" {
                                    if j2.value as! String == "true" {
                                        if fromTo == 1 {
                                            if from_s == self.to_seat {
                                                globals_table_no = globals_exchange_table_no
                                                
                                                takeSeatPlayers = []
                                                takeSeatPlayers = takeSeatPlayers_to
                                                
                                                seat = []
                                                seat = seat_to
                                            }
                                            
                                            // seat_holder テーブルの中身を削除
                                            db.open()
                                            let sql10 = "DELETE FROM seat_holder;"
                                            let _ = db.executeUpdate(sql10, withArgumentsIn: [])
                                            
                                            let sql11 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
                                            db.beginTransaction()
                                            for takeSeatPlayer in takeSeatPlayers {
                                                let success = db.executeUpdate(sql11, withArgumentsIn: [takeSeatPlayer.seat_no,takeSeatPlayer.holder_no])
                                                if !success {
                                                    print("insert error!!")
                                                }
                                            }
                                            db.commit()
                                            
                                            
                                            self.dispatch_async_main{
                                                var identiferName = ""
                                                if mode == 1 {
                                                    identiferName = "toPlayerssetSegue2"
                                                } else {
//                                                    identiferName = "toTableNoInputViewSegue"
                                                    // 席移動のみの場合はトップに戻る（2017/03/16）
                                                    identiferName = "toTopViewSegue"
                                                }
                                                self.performSegue(withIdentifier:identiferName,sender: nil)
                                            }
                                            
                                        }
                                    }
                                    
                                }
                                if j2.key as! String == "Message" {
                                    if j2.value as! String != "" {
                                        let msg = j2.value as! String
                                        print(msg)
                                        self.dispatch_async_main{
                                            self.return_error(msg)
                                        }
                                        break
                                    }
                                    
                                }
                            }
                        } else {
                            
                            print("ERROR",error)
                            
                        }
                    } catch {
                        
                        print("ERROR",error)
                    }
                })
*/
//            }
            print("END")
        }
    }

    
    func return_error(_ msg:String){
        let alertController = UIAlertController(title: "エラー！", message: msg , preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
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
    
    func seat_holder_save() {
        // seat_holder テーブルの中身を削除
        let db = FMDatabase(path: self._path)
        db.open()
        let sql10 = "DELETE FROM seat_holder;"
        let _ = db.executeUpdate(sql10, withArgumentsIn: [])
        
        let sql11 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
        db.beginTransaction()
        for takeSeatPlayer in takeSeatPlayers {
            let success = db.executeUpdate(sql11, withArgumentsIn: [takeSeatPlayer.seat_no,takeSeatPlayer.holder_no])
            if !success {
                print("insert error!!")
            }
        }
        
        let sql_del_iorder_detail = "DELETE FROM iOrder_detail WHERE order_no in ( SELECT order_no FROM iOrder WHERE store_cd = ? AND table_no = ?)"
        
        print(#function,globals_table_no)
        let _ = db.executeUpdate(sql_del_iorder_detail, withArgumentsIn: [shop_code,globals_table_no])
        
        let sql_del = "DELETE FROM iOrder WHERE store_cd = ? AND table_no = ?;"
        let _ = db.executeUpdate(sql_del, withArgumentsIn: [shop_code,globals_table_no])

        
        db.commit()
        db.close()
    }
    
    func take_seat_player_save() {
        //
        // seat_masterの情報を更新
        let db = FMDatabase(path: fmdb.path)
        
        // データベースをオープン
        db.open()
        
        let sql_update_seat_master = "UPDATE seat_master SET holder_no = ?,order_kbn = ? WHERE table_no = ? AND seat_no = ?"
        // 左保存
        for s in seat {
            var argumentArray:Array<Any> = []
            let idx = takeSeatPlayers.index(where: {$0.seat_no == s.seat_no})
            if idx != nil {
                argumentArray.append(takeSeatPlayers[idx!].holder_no)
            } else {
                argumentArray.append(NSNull.self)
            }
            argumentArray.append(2)
            argumentArray.append(globals_table_no)
            argumentArray.append(s.seat_no)
            
            let _ = db.executeUpdate(sql_update_seat_master, withArgumentsIn: argumentArray)
        }
        
        // 右保存
        for s1 in seat_to {
            var argumentArray:Array<Any> = []
            let idx = takeSeatPlayers_to.index(where: {$0.seat_no == s1.seat_no})
            if idx != nil {
                argumentArray.append(takeSeatPlayers_to[idx!].holder_no)
            } else {
                argumentArray.append(NSNull.self)
            }
            argumentArray.append(2)
            argumentArray.append(globals_exchange_table_no)
            argumentArray.append(s1.seat_no)
            
            let _ = db.executeUpdate(sql_update_seat_master, withArgumentsIn: argumentArray)
        }
        
        db.close()
        
    }
    
}
