//
//  orderInputViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/08.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB
import Toast_Swift

class orderInputViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, AdaptiveItemSizeLayoutable,UINavigationBarDelegate,UIGestureRecognizerDelegate {

    fileprivate var onceTokenViewDidAppear: Int = 0

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var countSUMTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var listChangeButton: UIBarButtonItem!
    @IBOutlet weak var handWriteButton: UIButton!
    @IBOutlet weak var specialButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var allOrderButton: UIButton!

    var layout = AdaptiveItemSizeLayout()

    var listImage:UIImage!
    var cellImage:UIImage!
    
    var listOrCell: Bool!
    var cell : UICollectionViewCell?
    
    var swipeRecognizer:UISwipeGestureRecognizer?
    
    // セルデータの型
    struct CellData2 {
        var seat:String
        var seat_no:Int
        var holder:String
        var price:String
        var name:String
        var kana:String
        var message:String
        var tanka:String
        var status:Int
        var count:Int
    }
    
    // セルデータの配列
    var tableData:[CellData2] = []
    
    // cellのタッチ可能かどうか
    var selected:[Bool] = []
    
    // cellの選択状態
    var cell_Long_Tap:[Bool] = []
    
    //
    var selectMenuCount_save:[selectMenuCountData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listOrCell = true
        
        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor
        
        // 戻るボタン
        var iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        var Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        backButton.setImage(Image, for: UIControlState())
        
        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.pressedLong(_:)))
        
        backButton.addGestureRecognizer(longPress)

        // リスト切り替え
        iconImage = FAKFontAwesome.barsIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        listImage = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        listChangeButton.image = listImage
        // グリッド表示OFFか7名以上の場合
        if grid_disp == 0 || takeSeatPlayers.count >= 7 {
            listChangeButton.isEnabled = false
            listChangeButton.tintColor = UIColor(white: 1.0, alpha: 0.0)
            listChangeButton.accessibilityElementsHidden = false

            _ = decrementColumn()
            listOrCell = false
        } else {
            let grid = get_grid_disp()
            
            if grid == 0 {
                
                _ = decrementColumn()
                listOrCell = false
            }
        }
        
        
        iconImage = FAKFontAwesome.thLargeIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        cellImage = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))

        // 確定ボタン
        iconImage = FAKFontAwesome.checkIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image, for: UIControlState())
        
        // クリアボタン
        iconImage = FAKFontAwesome.timesCircleIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_greenColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        clearButton.setImage(Image, for: UIControlState())
        clearButton.addTarget(self, action: #selector(orderInputViewController.clearButtonTap), for: .touchUpInside)

        // 手書きボタン
        iconImage = FAKFontAwesome.handPointerOIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_greenColor)
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        handWriteButton.setImage(Image, for: UIControlState())
        handWriteButton.addTarget(self, action: #selector(orderInputViewController.handwriting), for: .touchUpInside)

        // 特殊ボタン
        iconImage = FAKFontAwesome.starIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_redColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        
        let Image_sp = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        specialButton.setImage(Image_sp, for: UIControlState())
        specialButton.addTarget(self, action: #selector(orderInputViewController.special(_:)), for: .touchUpInside)

        // 全員注文ボタン
        iconImage = FAKFontAwesome.usersIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        //        iconImage?.addAttribute(NSBackgroundColorAttributeName, value: UIColor.whiteColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        allOrderButton.setImage(Image, for: UIControlState())


        // メニュー名
        self.navBar.topItem?.title = (globals_select_menu_no.menu_name)
/*
        // toast with a specific duration and position
        self.view.makeToast("タップで＋、\n左スライドで−", duration: 3.0, position: .Bottom)
*/        
        // CollectionViewを複数選択可能にする
        self.collectionView.allowsMultipleSelection = true
        
        // 長押し
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(orderInputViewController.onLongPressAction(_:)))
//        longPressRecognizer.allowableMovement = 10
        longPressRecognizer.minimumPressDuration = 0.5
        self.collectionView.addGestureRecognizer(longPressRecognizer)
        
        
        // スワイプ
//        let directionList:[UISwipeGestureRecognizerDirection] = [.Up,.Down,.Left,.Right]
        let directionList:[UISwipeGestureRecognizerDirection] = [.left]

        swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(orderInputViewController.swipeLabel(_:)))

        for direction in directionList{
            swipeRecognizer!.direction = direction
        }

        swipeRecognizer!.delegate = self
        self.collectionView.addGestureRecognizer(swipeRecognizer!)

        self.cell_Long_Tap = [Bool]( repeating: false , count: takeSeatPlayers.count )
        
        self.loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // この画面だけ、強制的にアニメーションをOFFにする
        UIView.setAnimationsEnabled(false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 画面を抜けるときに、元の設定に戻す
        let is_animation = animation == 1 ? true : false
        
        UIView.setAnimationsEnabled(is_animation)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
        let sql = "select * from hand_image;"
        let results = db.executeQuery(sql, withArgumentsIn: [])
        selectMenuCount = []
        var handImage :UIImage? = UIImage()
        while (results?.next())!{
            if results?.data(forColumn: "hand_image") != nil {
                handImage = UIImage(data: (results?.data(forColumn:"hand_image"))!)
                selectMenuCount.append(selectMenuCountData(
                    seat        : (results?.string(forColumn:"seat"))!,
                    No          : (results?.string(forColumn:"holder_no"))!,
                    MenuNo      : (results?.string(forColumn:"order_no"))!,
                    BranchNo    : Int((results?.int(forColumn:"branch_no"))!),
                    MenuCount   : Int((results?.int(forColumn:"order_count"))!),
                    HandWrite   :handImage!)
                )
            } else {
                selectMenuCount.append(selectMenuCountData(
                    seat        : (results?.string(forColumn:"seat"))!,
                    No          : (results?.string(forColumn:"holder_no"))!,
                    MenuNo      : (results?.string(forColumn:"order_no"))!,
                    BranchNo    : Int((results?.int(forColumn:"branch_no"))!),
                    MenuCount   : Int((results?.int(forColumn:"order_count"))!),
                    HandWrite   :UIImage())
                )
            }
        }
        
        // 一人しかいない場合は常に選択状態にする
        let tableDataFilter = tableData.filter({$0.holder != ""})
        
        if tableDataFilter.count != 1 {
            for i in 0..<cell_Long_Tap.count {
                self.cell_Long_Tap[i] = false
            }
        }

        
        collectionView.reloadData()
        
        DemoLabel.Show(self.view)
        DemoLabel.modeChange()

    }

    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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

        self.tableData = []
        self.selected = []
//        print("seat0",seat)
        
        // 表示順にする
        if listOrCell == true {
            // 表示順にする
            seat.sort(by: {$0.disp_position < $1.disp_position})
   
        } else {
            // シートNO順にする
            seat.sort(by: {$0.seat_no < $1.seat_no})
            
        }
        
//        print("seat1",seat)
        
        for sd in seat {
            let index = takeSeatPlayers.index(where: {$0.seat_no == sd.seat_no})
            if index != nil {
                if takeSeatPlayers[index!].holder_no == "" {
                    self.tableData.append (CellData2(
                        seat    :sd.seat_name,
                        seat_no :sd.seat_no,
                        holder  :"",
                        price   :"",
                        name    :"",
                        kana    :"",
                        message :"",
                        tanka   :"一般",
                        status  :0,
                        count   :0
                        
                        )
                    )
                    
                    self.selected.append(false)
                } else {
                    let holder_no = takeSeatPlayers[index!].holder_no
//                    let sql = "select * from players where member_no in (?);"
                    
                    let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [holder_no,shop_code,globals_today + "%"])
//                    let results = db.executeQuery(sql, withArgumentsIn: [holder_no])
                    var user_count = 0
                    while results!.next() {
                        let mn = (results!.string(forColumn: "member_no") != nil) ? results!.string(forColumn: "member_no") : ""
                        var mc = ""
                        switch results!.int(forColumn: "member_category") {
                        case 1:
                            mc = "メンバー"
                        case 2:
                            mc = "ビジター"
                        default:
                            mc = ""
                        }
                        
                        let pnkana = (results!.string(forColumn: "player_name_kana") != nil) ? results!.string(forColumn: "player_name_kana") : ""
                        let pnkanji = (results!.string(forColumn: "player_name_kanji") != nil) ? results!.string(forColumn: "player_name_kanji") : ""
                        let m1 = (results!.string(forColumn: "message1") != nil) ? results!.string(forColumn: "message1") : ""
                        let status = Int(results!.int(forColumn: "status"))
                        //                    let m2 = (results?.string(forColumn:"message2") != nil) ? results?.string(forColumn:"message2") : ""
                        var pk = ""
                        switch results!.int(forColumn: "price_tanka") {
                        case 1:
                            pk = "一般"
                        case 2:
                            pk = "従業員"
                        case 3:
                            pk = "その他"
                        default:
                            pk = ""
                        }
                        
                        self.tableData.append (CellData2(
                            seat    :sd.seat_name,
                            seat_no :sd.seat_no,
                            holder  :mn!,
                            price   :mc,
                            name    :pnkanji!,
                            kana    :pnkana!,
                            message :m1!,
                            tanka   :pk,
                            status  :status,
                            count   :0
                            )
                        )
                        
                        self.selected.append(true)
                        user_count += 1
                    }
                    if user_count <= 0 {
                        self.tableData.append (CellData2(
                            seat    :sd.seat_name,
                            seat_no :sd.seat_no,
                            holder  :holder_no,
                            price   :"",
                            name    :"",
                            kana    :"",
                            message :"",
                            tanka   :"一般",
                            status  :0,
                            count   :0
                            )
                        )
                        
                        self.selected.append(true)
                    }

                }
            }
        }

        
        // 一人しかいない場合は常に選択状態にする
        let tableDataFilter = tableData.filter({$0.holder != ""})
        
        if tableDataFilter.count == 1 {
            let index = tableData.index(where: {$0.holder != ""})
            if index != nil {
                let indexPath = IndexPath(item: index!, section: 0)
                self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition())
                
                self.cell_Long_Tap[index!] = true
            }
        }
        
    }
    
    // 行数を返す
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 行数はデータの個数
        return tableData.count
    }
    
    // コレクションビューにデータをセット
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {


        if listOrCell == true{
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdaptiveSizeCollectionViewCell", for: indexPath)
            let circleImage = cell!.contentView.viewWithTag(10) as! UIImageView
            
            // 円
            let iconImage = FAKFontAwesome.circleIcon(withSize: 50*size_scale)
            iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.darkGray)
            let Image = iconImage?.image(with: CGSize(width: 50*size_scale, height: 50*size_scale))
            circleImage.image = Image
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdaptiveSizeCollectionViewCell2", for: indexPath)
        }
        
        let seatLabel = cell!.contentView.viewWithTag(1) as! UILabel
        let holderLabel = cell!.contentView.viewWithTag(2) as! UILabel
        let kanaLabel = cell!.contentView.viewWithTag(3) as! UILabel
        let playerNameLabel = cell!.contentView.viewWithTag(4) as! UILabel
        let handButton = cell!.contentView.viewWithTag(5) as! UIButton
        let spButton = cell!.contentView.viewWithTag(6) as! UIButton
        let countText = cell!.contentView.viewWithTag(7) as! UILabel
        let holderLabel2 = cell!.contentView.viewWithTag(8) as! UILabel
        
        countText.layer.borderWidth = 0.5
        countText.layer.borderColor = iOrder_borderColor.cgColor
        //現在のラベルのフォントサイズを取得
//        let beforeFontPoint: CGFloat = holderLabel.font.pointSize
//        let afterFontPoint: CGFloat = beforeFontPoint * CGFloat(font_scale[text_size])
        
//        var afterFontPoint: CGFloat = 0.0
//        if listOrCell == true{
//            afterFontPoint = 20.0 * CGFloat(font_scale[text_size])
//        } else {
//            afterFontPoint = 25.0 * CGFloat(font_scale[text_size])
//        }
        
        
        
        if text_size == 0 {
            holderLabel.isHidden = false
            holderLabel2.isHidden = true
        } else {            
            holderLabel.isHidden = true
            holderLabel2.isHidden = false
            
        }
        
        
//        //新しいフォントサイズの反映
//        holderLabel.font = holderLabel.font.fontWithSize(afterFontPoint)
/*
        // データの個数
        let t_count = tableData.count

        var seatLabel_font:Float = 0.0
        var holderLabel_font:Float = 0.0
        var playerNameLabel_font:Float = 0.0
        var countText_font:Float = 0.0
        
        var font_size : Float = 0.0
        
        if listOrCell == true{
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("AdaptiveSizeCollectionViewCell", forIndexPath: indexPath)
            
            switch t_count {
            case 1..<5 :
                font_size = 30.0 * Float(size_scale)
                break;
            case 5..<7 :
                font_size = 20.0 * Float(size_scale)
                break;
            default:
                font_size = 30.0 * Float(size_scale)
                break;
            }
            seatLabel_font = font_size*0.8
            holderLabel_font = font_size
            playerNameLabel_font = font_size
            countText_font = font_size

            
            let circleImage = cell!.contentView.viewWithTag(10) as! UIImageView
            // 円
            let iconImage = FAKFontAwesome.circleIconWithSize(50*size_scale)
            iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.darkGrayColor())
            let Image = iconImage?.imageWithSize(CGSizeMake(50*size_scale, 50*size_scale))
            circleImage.image = Image
            
        } else {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("AdaptiveSizeCollectionViewCell2", forIndexPath: indexPath)
//            holderLabel_font = 20.0
            switch t_count {
            case 1..<5 :
                font_size = 25.0 * Float(size_scale)
                seatLabel_font = font_size
                holderLabel_font = font_size
                playerNameLabel_font = font_size
                countText_font = font_size
                break;
            case 5 :
                font_size = 20.0 * Float(size_scale)
                seatLabel_font = font_size
                holderLabel_font = 18.0 * Float(size_scale)
                playerNameLabel_font = font_size
                countText_font = font_size
                break;
            default:
                font_size = 23.0 * Float(size_scale)
                seatLabel_font = font_size
                holderLabel_font = 20.0 * Float(size_scale)
                playerNameLabel_font = font_size
                countText_font = font_size
                break;
            }
        }
 

        let seatLabel = cell!.contentView.viewWithTag(1) as! UILabel
//        seatLabel.font = UIFont(name: "YuGo-Bold",size: CGFloat(seatLabel_font))
        seatLabel.numberOfLines = 0
        seatLabel.adjustsFontSizeToFitWidth = true
        
        let holderLabel = cell!.contentView.viewWithTag(2) as! UILabel
        holderLabel.font = UIFont(name: "YuGo-Medium",size: CGFloat(holderLabel_font*font_scale[text_size]))
        holderLabel.numberOfLines = 0
        holderLabel.adjustsFontSizeToFitWidth = true
        
        let kanaLabel = cell!.contentView.viewWithTag(3) as! UILabel
        kanaLabel.numberOfLines = 0
        kanaLabel.baselineAdjustment = .AlignCenters
        
        let playerNameLabel = cell!.contentView.viewWithTag(4) as! UILabel
//        playerNameLabel.font = UIFont(name: "YuGo-Bold",size: CGFloat(playerNameLabel_font))
        playerNameLabel.numberOfLines = 0
        playerNameLabel.adjustsFontSizeToFitWidth = true
        playerNameLabel.baselineAdjustment = .AlignCenters
        
        let handButton = cell!.contentView.viewWithTag(5) as! UIButton
        let spButton = cell!.contentView.viewWithTag(6) as! UIButton
        let countText = cell!.contentView.viewWithTag(7) as! UITextField
        
//        countText.font = UIFont(name: "YuGo-Bold",size: CGFloat(countText_font))
        
        countText.adjustsFontSizeToFitWidth = true
        countText.minimumFontSize = 0
//        let cellButton = cell!.contentView.viewWithTag(8) as! UIButton
*/
        // ふりがな表示しない場合
        if furigana == 0 {
            kanaLabel.isHidden = true
        } else {
            kanaLabel.isHidden = false
        }
        
        
        // 手書きボタン
        var iconImage = FAKFontAwesome.handPointerOIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_greenColor)

        handButton.backgroundColor = UIColor.clear
        
        // セルに表示するデータを取り出す
        
        let index = getIndex(indexPath)

        // ホルダ番号があって、名前がない場合は再度確認する
        if tableData[index].holder != "" && tableData[index].name == "" {
            tableData[index].name = fmdb.getPlayerName(tableData[index].holder)
            tableData[index].kana = fmdb.getNameKana(tableData[index].holder)
            tableData[index].status = fmdb.getPlayerStatus(tableData[index].holder)
        }

        
//        let cellData = tableData[indexPath.row]
        let cellData = tableData[index]
        
//        print("cellData",cellData)
        // 枝番が−1の場合は新規メニューの為
//        if globals_select_menu_no.branch_no == -1 {
            for smc in selectMenuCount {
                if cellData.holder == smc.No && globals_select_menu_no.menu_no == Int64(smc.MenuNo) && cellData.seat == smc.seat && smc.BranchNo == -1 {
                    if smc.HandWrite != nil && (smc.HandWrite!.size) != CGSize(width: 0,height: 0) {
                        
                        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
                        handButton.backgroundColor = iOrder_greenColor
                        break;
                    }
                }
            }
//        }
        

        var Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        handButton.setImage(Image, for: UIControlState())

        // 特殊ボタン（オプションボタン）
        iconImage = FAKFontAwesome.starIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        
        spButton.backgroundColor = UIColor.clear
        
        // 枝番が−1の場合は新規メニューの為
//        if globals_select_menu_no.branch_no == -1 {
            for ssp in selectSPmenus {
                if cellData.holder == ssp.holderNo && globals_select_menu_no.menu_no == ssp.menuNo && cellData.seat == ssp.seat && ssp.BranchNo == -1{
                    iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
                    spButton.backgroundColor = iOrder_bargainsYellowColor
                }
            }
//        }
        
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        spButton.setImage(Image, for: UIControlState())

        
        seatLabel.text = cellData.seat
        holderLabel.text = cellData.holder
        

        holderLabel.backgroundColor = UIColor.clear
        holderLabel.textColor = UIColor.black
        holderLabel.textAlignment = .center
        holderLabel.layer.cornerRadius = 5.0
        holderLabel.clipsToBounds = true
        holderLabel.layer.borderColor = UIColor.clear.cgColor
        holderLabel.layer.borderWidth = 0.0
        holderLabel.textAlignment = .center
        
        holderLabel2.text = cellData.holder
        holderLabel2.backgroundColor = UIColor.clear
        holderLabel2.textColor = UIColor.black
        holderLabel2.textAlignment = .center
        holderLabel2.layer.cornerRadius = 5.0
        holderLabel2.clipsToBounds = true
        holderLabel2.layer.borderColor = UIColor.clear.cgColor
        holderLabel2.layer.borderWidth = 0.0
        holderLabel2.textAlignment = .center

        
        switch cellData.status {
        case 0,1:       // チェックイン
            break;
        case 2:         // チェックアウト
            holderLabel.backgroundColor = iOrder_grayColor
            holderLabel.textColor = UIColor.white

            holderLabel2.backgroundColor = iOrder_grayColor
            holderLabel2.textColor = UIColor.white
            
            break;
        case 3:         // キャンセル
            holderLabel.backgroundColor = iOrder_grayColor
            holderLabel.textColor = UIColor.white

            holderLabel2.backgroundColor = iOrder_grayColor
            holderLabel2.textColor = UIColor.white

            break;
        case 9:         // 予約
            holderLabel.layer.borderColor = iOrder_grayColor.cgColor
            holderLabel.layer.borderWidth = 1.0

            holderLabel2.layer.borderColor = iOrder_grayColor.cgColor
            holderLabel2.layer.borderWidth = 1.0

//            holderLabel.backgroundColor = iOrder_grayColor
//            holderLabel.textColor = UIColor.whiteColor()
            break;
        default:
            break;
        }

        if cellData.holder != "" && cellData.name == "" {
            holderLabel.layer.borderColor = iOrder_grayColor.cgColor
            holderLabel.layer.borderWidth = 1.0
            
            holderLabel2.layer.borderColor = iOrder_grayColor.cgColor
            holderLabel2.layer.borderWidth = 1.0
        }
        
        
        kanaLabel.text = cellData.kana
        playerNameLabel.text = cellData.name
        countText.text = cellData.count.description
        
        // 手書きボタンにイベントをつける
        handButton.addTarget(self, action: #selector(orderInputViewController.handwriting), for: .touchUpInside)
        // 特殊ボタンにイベントをつける
        spButton.addTarget(self, action: #selector(orderInputViewController.special), for: .touchUpInside)
        
        
        // 無人の席はバックをグレーにする
//        if selected[indexPath.row] == false {
        if selected[index] == false {
            cell!.backgroundColor = iOrder_orderInputBackColor
            countText.backgroundColor = iOrder_orderInputBackColor
        } else {
//            if self.cell_Long_Tap[indexPath.row] == true {
            if self.cell_Long_Tap[index] == true {
                cell!.backgroundColor = iOrder_sakura
                countText.backgroundColor = UIColor.white
            } else {
                cell!.backgroundColor = UIColor.white
                countText.backgroundColor = UIColor.white
            }
//            cell!.backgroundColor = UIColor.whiteColor()
//            countText.backgroundColor = UIColor.whiteColor()
        }
        
        return cell!
    }
    
    // スクリーンサイズに応じたセルサイズを返す
    // UICollectionViewDelegateFlowLayoutの設定が必要
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,sizeForItemAtIndexPath indexPath:IndexPath) -> CGSize{


        
        let layout:UICollectionViewFlowLayout =  collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0
        
        
        if listOrCell == true{
            width = (((collectionView.frame.size.width)-(layout.sectionInset.left * 3))/2 )
            height = ((collectionView.frame.size.height)-(layout.sectionInset.bottom * 3))/2
            
            if tableData.count > 4 && tableData.count <= 6 {
                height = ((collectionView.frame.size.height)-(layout.sectionInset.bottom * 4))/3
                
            } else if tableData.count > 6 {
                height = ((collectionView.frame.size.height)-(layout.sectionInset.bottom * 3))/2.5
            }
            
        } else {
            width = collectionView.frame.size.width
            height = ((collectionView.frame.size.height)-(5.0*4)) / 4
            if tableData.count == 5  {
                height = ((collectionView.frame.size.height)-(5.0*5)) / 5
                
            } else if tableData.count > 5 {
                height = ((collectionView.frame.size.height)-(5.0*4)) / 4.5
            }
            
        }

        return CGSize(width: width, height: height)
    }
    
    // タップされたセルのindexPathを取得
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {


        let index = getIndex(indexPath)
        if listOrCell == true {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdaptiveSizeCollectionViewCell", for: indexPath)
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdaptiveSizeCollectionViewCell2", for: indexPath)
        }

        
        // 無人の席はタップ無効
        if selected[index] == false {
            return;
        }
        

        cell!.isUserInteractionEnabled = false
        let delay = 0.02 * Double(NSEC_PER_SEC)
        let time  = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            self.cell!.isUserInteractionEnabled = true
        })

        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        tableData[index].count += 1
        collectionView.reloadData()
        
        var countSUM:Int = 0
        if countSUMTextField.text != "" {
            countSUM = Int(countSUMTextField.text!)! + 1
        } else  {
            countSUM = 1
        }
        countSUMTextField.text = countSUM.description
    }
    
    // 全員注文ボタンタップ
    @IBAction func allOrderButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        var cnt = 0
        for i in 0..<tableData.count {
            let index = seat.index(where: {$0.seat_no == tableData[i].seat_no})
            if index != nil {
                // 席区分が1の席だけ
                if seat[index!].seat_kbn == 1 {
                    if selected[i] == true {
                        tableData[i].count += 1
                        cnt += 1
                    }
                }
            }
        }
        collectionView.reloadData()
        
        var countSUM:Int = 0
        if countSUMTextField.text != "" {
            countSUM = Int(countSUMTextField.text!)! + cnt
        } else  {
            countSUM = cnt
        }
        countSUMTextField.text = countSUM.description
    }
    
    // section数の設定　今回は１
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    fileprivate func initLayout() {
        layout.delegate = self
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
    
    func sizeForItemAtIndexPath(_ indexPath: IndexPath) -> CGSize {
        return cellSize
    }
    
    
    fileprivate var cellSize: CGSize {
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0

        let layout:CGFloat =  5.0
        
        if listOrCell == true{
            width = (((collectionView.frame.size.width)-(layout * 3))/2 )
            height = ((collectionView.frame.size.height)-(layout * 3))/2
            
            if tableData.count > 4 && tableData.count <= 6 {
                height = ((collectionView.frame.size.height)-(layout * 4))/3
                
            } else if tableData.count > 6 {
                height = ((collectionView.frame.size.height)-(layout * 3))/2.5
            }
            
        } else {
            width = collectionView.frame.size.width
            height = ((collectionView.frame.size.height)-(5.0*4)) / 4
            if tableData.count == 5  {
                height = ((collectionView.frame.size.height)-(5.0*5)) / 5
                
            } else if tableData.count > 5 {
                height = ((collectionView.frame.size.height)-(5.0*4)) / 4.5
            }
            
        }

        
        return CGSize(width: width, height: height)
    }
    
    func swipeLabel(_ sender:UISwipeGestureRecognizer){
        
        let point: CGPoint = sender.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: point)
        
        if indexPath != nil {
            let index = getIndex(indexPath!)
            
            
            // 無人の席はタップ無効
            if selected[index] == false {
                return;
            }
            
            switch(sender.direction){
            case UISwipeGestureRecognizerDirection.up:
                print("上")
                
            case UISwipeGestureRecognizerDirection.down:
                print("下")
                
            case UISwipeGestureRecognizerDirection.left:
                print("左")
                
                // 音
                TapSound.buttonTap("swish1", type: "mp3")
                
                if is_minus_qty != 0 {      // マイナス入力を許可する
                    tableData[index].count -= 1
                } else {
                    if tableData[index].count > 0 {
                        tableData[index].count -= 1
                    }
                }
                collectionView.reloadData()
                
                var countSUM:Int = 0
                if countSUMTextField.text != "" {
                    
                    countSUM = tableData.reduce(0, {$0 + $1.count})
                    
                    if is_minus_qty != 0 {      // マイナス入力を許可する
                        
                    } else {
                        if countSUM <= 0 {
                            countSUM = 0
                        }
                    }
                } else  {
                    countSUM = 0
                }
                countSUMTextField.text = countSUM.description
                
                
                
            case UISwipeGestureRecognizerDirection.right:
                print("右")
                
            default:
                break
            }
        }
    }

    func handwriting(_ sender:UIButton){

        let point = self.collectionView.convert(sender.frame.origin, from: sender.superview)
        
        let indexPath = self.collectionView.indexPathForItem(at: point)
        
        selectMenuCount_save = []
        selectMenuCount_save = selectMenuCount
        selectMenuCount = []
  
        globals_image = UIImage()
        
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

        
        // セル内のボタンをタップされた場合
        if sender.tag == 5 {
            
            let index = getIndex(indexPath!)
            
            // 無人の席はタップ無効
            if selected[index] == false {
                return;
            }
            
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

            let sql = "select count(*) from hand_image WHERE seat = ? AND holder_no = ? AND branch_no = ? AND order_no = ?;"
            let results = db.executeQuery(sql, withArgumentsIn: [tableData[index].seat, tableData[index].holder,globals_select_menu_no.branch_no,NSNumber(value: globals_select_menu_no.menu_no as Int64)])
            
            while (results?.next())!{
                if (results?.int(forColumnIndex:0))! <= 0 {
                    var argumentArray:Array<Any> = []
                    let imageData = Data()
                    argumentArray.append(tableData[index].holder)
                    argumentArray.append(NSNumber(value: globals_select_menu_no.menu_no as Int64))
                    argumentArray.append(globals_select_menu_no.branch_no)
                    argumentArray.append(tableData[index].count)
                    argumentArray.append(imageData)
                    argumentArray.append(tableData[index].seat)
                    
                    let sql2 = "INSERT INTO hand_image(holder_no, order_no, branch_no,order_count, hand_image,seat) VALUES(?,?,?,?,?,?);"
                    let results2 = db.executeUpdate(sql2, withArgumentsIn: argumentArray)
                    if !results2 {
                        // エラー時
                        print(results2.description)
                    }
                    
                } else {
                    let sql2 = "UPDATE hand_image SET order_count = :COUNT WHERE holder_no = :HOLDER AND order_no = :ORDER AND branch_no = :BRANCH AND seat = :SEAT;"
                    
                    // 名前を付けたパラメータに値を渡す
                    let results2 = db.executeUpdate(sql2, withParameterDictionary: ["COUNT":tableData[index].count, "HOLDER":tableData[index].holder,"ORDER":NSNumber(value: globals_select_menu_no.menu_no as Int64),"BRANCH":globals_select_menu_no.branch_no,"SEAT":tableData[index].seat])
                    if !results2 {
                        // エラー時
                        print(results2.description)
                    }
                    
                    let sql3 = "select * from hand_image WHERE seat = ? AND holder_no = ? AND branch_no = ? AND order_no = ?;"
                    let results3 = db.executeQuery(sql3, withArgumentsIn: [tableData[index].seat,tableData[index].holder,globals_select_menu_no.branch_no,NSNumber(value: globals_select_menu_no.menu_no as Int64)])
                    
                    while (results3?.next())!{
                        var handImage:UIImage? = UIImage()
                        if results3?.data(forColumn: "hand_image") != nil {
                            handImage = UIImage(data: (results3?.data(forColumn:"hand_image")!)!)
                        }
                        globals_image = handImage
                    }

                }
                
            }
//            print("A",index,tableData[index])
            selectMenuCount.append(selectMenuCountData(
                seat        : tableData[index].seat,
                No          : tableData[index].holder,
                MenuNo      : "\(globals_select_menu_no.menu_no)",
                BranchNo    : (globals_select_menu_no.branch_no),
                MenuCount   : tableData[index].count,
                HandWrite   : globals_image!)
            )
            
//            print("globals_image",globals_image)
            self.performSegue(withIdentifier: "toHandWritingViewSegue",sender: nil)
        } else {
            let index1 = cell_Long_Tap.index(of: true)
            
            if index1 != nil {
                
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

                var handImage_NSData:Data? = nil
                var is_same_image = true
                
                for i in 0..<cell_Long_Tap.count {
                    if cell_Long_Tap[i] == true {
                        
                        if cell_Long_Tap.count == 1 {
                            for j in 0..<selectMenuCount_save.count {
                                if selectMenuCount_save[j].No == takeSeatPlayers[i].holder_no {
                                    if selectMenuCount_save[j].HandWrite != nil {
                                        globals_image = selectMenuCount_save[j].HandWrite!
                                    }
                                    
                                }
                                
                            }
                        }
                        
                        let sql = "select count(*) from hand_image WHERE seat = ? AND holder_no = ? AND branch_no = ? AND order_no = ?;"
                        let results = db.executeQuery(sql, withArgumentsIn: [tableData[i].seat,takeSeatPlayers[i].holder_no,globals_select_menu_no.branch_no, NSNumber(value: globals_select_menu_no.menu_no as Int64)])
                        
                        while (results?.next())!{
                            if (results?.int(forColumnIndex:0))! <= 0 {
                                var argumentArray:Array<Any> = []
                                let imageData = Data()
                                argumentArray.append(tableData[i].holder)
                                argumentArray.append(NSNumber(value: globals_select_menu_no.menu_no as Int64))
                                argumentArray.append(globals_select_menu_no.branch_no)
                                argumentArray.append(tableData[i].count)
                                argumentArray.append(imageData)
                                argumentArray.append(tableData[i].seat)
                                
                                let sql2 = "INSERT INTO hand_image(holder_no, order_no, branch_no,order_count, hand_image,seat) VALUES(?,?,?,?,?,?);"
                                let results2 = db.executeUpdate(sql2, withArgumentsIn: argumentArray)
                                if !results2 {
                                    // エラー時
                                    print(results2.description)
                                }
                                
                            } else {
                                let sql2 = "UPDATE hand_image SET order_count = :COUNT WHERE holder_no = :HOLDER AND order_no = :ORDER AND branch_no = :BRANCH AND seat = :SEAT;"
                                
                                // 名前を付けたパラメータに値を渡す
                                let results2 = db.executeUpdate(sql2, withParameterDictionary: ["COUNT":tableData[i].count, "HOLDER":tableData[i].holder,"ORDER":NSNumber(value: globals_select_menu_no.menu_no as Int64),"BRANCH":globals_select_menu_no.branch_no,"SEAT":tableData[i].seat])
                                if !results2 {
                                    // エラー時
                                    print(results2.description)
                                }
                            }

                        }
//                        print("B",i,tableData[i])
                        
                        let sql3 = "select * from hand_image WHERE seat = ? AND holder_no = ? AND branch_no = ? AND order_no = ?;"
                        let results3 = db.executeQuery(sql3, withArgumentsIn: [tableData[i].seat,takeSeatPlayers[i].holder_no,globals_select_menu_no.branch_no, NSNumber(value: globals_select_menu_no.menu_no as Int64)])
                        
                        var handImage:UIImage? = UIImage()
                        while (results3?.next())!{
                            
                            if results3?.data(forColumn: "hand_image") != nil {
                                if handImage_NSData == nil {
                                    handImage_NSData = results3?.data(forColumn:"hand_image")
                                } else {
                                    if !(handImage_NSData == results3?.data(forColumn: "hand_image") && handImage_NSData != nil) {
                                        is_same_image = false
                                    }
                                    
//                                    if ((handImage_NSData?.isEqualToData(results3.data(forColumn:"hand_image"))) != nil) {
//                                        
//                                    } else {
//                                        is_same_image = false
//                                    }
                                }
                                handImage = UIImage(data: (results3?.data(forColumn:"hand_image")!)!)
                            } else {
                                handImage = UIImage()
                                is_same_image = false
                            }
                        }

                        selectMenuCount.append(selectMenuCountData(
                            seat:tableData[i].seat,
                            No: tableData[i].holder,
                            MenuNo: (globals_select_menu_no.menu_no).description,
                            BranchNo: globals_select_menu_no.branch_no,
                            MenuCount: tableData[i].count,
                            HandWrite:handImage!)
                        )
                    }
                }
                
                if is_same_image && handImage_NSData != nil{
                    globals_image = UIImage(data: handImage_NSData!)
                }
                
                print("globals_image",globals_image as Any)
                self.performSegue(withIdentifier: "toHandWritingViewSegue",sender: nil)
            } else {
                // エラー表示
                let alertController = UIAlertController(title: "エラー！", message: "手書き入力したいお客様を選択してください。", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "閉じる", style: .cancel){
                    action in
                    return;
                }
                alertController.addAction(cancelAction)
                present(alertController, animated: true, completion: nil)
                
            }
        }
        db.close()
    }
    
    func special(_ sender:UIButton){

        let point = self.collectionView.convert(sender.frame.origin, from: sender.superview)
        
        let indexPath = self.collectionView.indexPathForItem(at: point)
        
        
        
        selectSP = []
        
        // セル内のボタンをタップされた場合
        if sender.tag == 6 {
            
            let index = getIndex(indexPath!)
            
            // 無人の席はタップ無効
            if selected[index] == false {
                return;
            }
            
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            
            selectSP.append(selectMenuCountData(
                seat        : self.tableData[index].seat,
                No          : self.tableData[index].holder,
                MenuNo      : (globals_select_menu_no.menu_no).description,
                BranchNo    : globals_select_menu_no.branch_no,
                MenuCount   : self.tableData[index].count,
                HandWrite   : globals_image!)
            )
            
            self.performSegue(withIdentifier: "toSpecialMenuViewSegue",sender: nil)
        } else {
            let index = cell_Long_Tap.index(of: true)
            
            if index != nil {
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

                for i in 0..<cell_Long_Tap.count {
                    if cell_Long_Tap[i] == true {
                        selectSP.append(selectMenuCountData(
                            seat        : tableData[i].seat,
                            No          : tableData[i].holder,
                            MenuNo      : (globals_select_menu_no.menu_no).description,
                            BranchNo    : globals_select_menu_no.branch_no,
                            MenuCount   : tableData[i].count,
                            HandWrite   :globals_image!
                            )
                        )

                    }
                }
                self.performSegue(withIdentifier: "toSpecialMenuViewSegue",sender: nil)
            } else {
                // エラー表示
                let alertController = UIAlertController(title: "エラー！", message: "オプション入力したいお客様を選択してください。", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "閉じる", style: .cancel){
                    action in
                    return;
                }
                alertController.addAction(cancelAction)
                present(alertController, animated: true, completion: nil)
  
            }
        }
        
    }
    
    // cell 長押し時の選択
    func onLongPressAction(_ sender: UILongPressGestureRecognizer) {
        let point: CGPoint = sender.location(in: self.collectionView)
//        print(point)
        let indexPath = self.collectionView.indexPathForItem(at: point)
//        print(indexPath)
     
        
        if indexPath != nil {
            let index = getIndex(indexPath!)
            
            let cell = self.collectionView.cellForItem(at: indexPath!)!
            
            // 無人の席はタップ無効
            if selected[index] == false {
                return;
            }

            
            switch sender.state {
            case .began:
                // 一人しかいない場合は常に選択状態にする
                let tableDataFilter = tableData.filter({$0.holder != ""})
                
                if tableDataFilter.count != 1 {
                    self.cell_Long_Tap[index] = !self.cell_Long_Tap[index]
                    if self.cell_Long_Tap[index] == true {
                        cell.backgroundColor = iOrder_sakura
                    } else {
                        cell.backgroundColor = UIColor.white
                    }
                }
            case .ended:
                break
            default:
                break
            }
        }
    }
    
    // クリアボタンタップ
    @IBAction func clearButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
//        AVAudioPlayerUtil.play()

        // セルが選択されているかチェック
        let index = cell_Long_Tap.index(of: true)
        
        if index != nil {
            var totalCount = 0
            for i in 0..<cell_Long_Tap.count {
                if cell_Long_Tap[i] == true {
                    totalCount = totalCount + tableData[i].count
                    tableData[i].count = 0
                }
            }
            
            var countSUM:Int = 0
            if countSUMTextField.text != "" {
                countSUM = Int(countSUMTextField.text!)! - totalCount
                if countSUM < 0 {
                    countSUM = 0
                }
            } else  {
                countSUM = 0
            }
            collectionView.reloadData()
            countSUMTextField.text = countSUM.description
            self.reset_select()
        } else {
            // エラー表示
            let alertController = UIAlertController(title: "エラー！", message: "数をクリアしたいお客様を選択してください。", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "閉じる", style: .cancel){
                action in
                return;
            }
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
            
        }

        
    }
    
    // リスト変更ボタンタップ
    @IBAction func listToCell(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        
        if grid_disp != 0 {
            if listOrCell == true{
                
                _ = decrementColumn()
                listOrCell = false
                listChangeButton.image = cellImage
                self.set_grid_mode(0)
                self.collectionView.reloadData()
                
            } else {
                _ = incrementColumn()
                listOrCell = true
                listChangeButton.image = listImage
                self.set_grid_mode(1)
                self.collectionView.reloadData()

            }
        }
        
    }

    
    
    @IBAction func didRecognizedPinchGesture(_ sender: UIPinchGestureRecognizer) {
        if case .ended = sender.state {
            if sender.scale > 1.0 {
                _ = decrementColumn()
            } else if sender.scale < 1.0 {
                _ = incrementColumn()
            }
        }
    }

    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // 注文数が0のものは、手書き情報を削除する。
        
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
        let sql_delete = "DELETE FROM hand_image WHERE order_no = ? AND branch_no = -1;"
        
        db.open()
        let _ = db.executeUpdate(sql_delete, withArgumentsIn: [NSNumber(value: globals_select_menu_no.menu_no as Int64)])
        
        db.close()
        
        if (self.presentingViewController as? subMenuViewController) != nil {
            self.performSegue(withIdentifier: "toSubMenuViewSegue",sender: nil)
        } else if (self.presentingViewController as? selectMenuViewController) != nil {
            self.performSegue(withIdentifier: "toSelectMenuViewSegue",sender: nil)
        } else if (self.presentingViewController as? menuSelectViewController) != nil {
            self.performSegue(withIdentifier: "toMenuSelectViewSegue",sender: nil)
        }
    }

    // 確定ボタンタップ
    @IBAction func okButtonTap(_ sender: AnyObject) {
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // 注文数が０以下およびマイナス入力を許可しない場合
        let index = tableData.index(where: {$0.count != 0})
        
        if index == nil {
//        if Int(countSUMTextField.text!)! <= 0 && is_minus_qty == 0 {
            // エラー表示
            let alertController = UIAlertController(title: "エラー！", message: "オーダーがセットされていません。", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "閉じる", style: .cancel){
                action in
                return;
            }
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)

        } else {
        
            // メニュー残数登録のあるオーダーの場合、注文数をチェックする
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
            let sql = "select * from items_remaining WHERE item_no = ?;"
            let results = db.executeQuery(sql, withArgumentsIn: [NSNumber(value: globals_select_menu_no.menu_no as Int64)])
        
            var r_count = -1
            while (results?.next())!{
                print(results?.int(forColumn:"remaining_count") as Any)
                r_count = Int((results?.int(forColumn:"remaining_count"))!)
            }
            db.close()
            
            if r_count != -1 && r_count < Int(countSUMTextField.text!)! {
                // エラー表示
                let alertController = UIAlertController(title: "エラー！", message: "残数より注文数が多いです。", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                    action in
                    return;
                }
                alertController.addAction(cancelAction)
                present(alertController, animated: true, completion: nil)
                
            } else {
        
                // メインメニュー
//                print("tableData",tableData)
                for mainM in tableData {
                    // ホルダ番号があるデータのみ
                    if mainM.holder != "" {
//                        // 手書き情報の有無
//                        var isHand:Bool = false
//                        for h in selectMenuCount{
//                            if h.No == mainM.holder {
//                                if h.HandWrite != nil && h.HandWrite?.size != CGSize(width: 0, height: 0) {
//                                isHand = true
//                                    break;
//                                }
//                            }
//                        }
                        // オーダー数が0の人は登録しない
                        if mainM.count != 0 {
                            // メインメニューの登録
                            let seat_nm = mainM.seat
                            let custmer_no = mainM.holder
                            let menu_no = "\(globals_select_menu_no.menu_no)"

                            // 手書き情報の有無
                            var isHand:Bool = false
                            for h in selectMenuCount{
                                if h.No == mainM.holder && h.seat == seat_nm && h.MenuNo == menu_no && h.BranchNo == globals_select_menu_no.branch_no{
                                    if h.HandWrite != nil && h.HandWrite?.size != CGSize(width: 0, height: 0) {
                                        isHand = true
                                        break;
                                    }
                                }
                            }
                            
                            
                            
                            var branchNo = 0
                            var id = 0
                            
                            if MainMenu.count > 0 {
                                let branch = MainMenu.filter({$0.seat == seat_nm && $0.No == custmer_no && $0.MenuNo == menu_no})
                                if branch.count > 0 {
                                    // ブランチNOの最大値を取得
                                    branchNo = branch.reduce(branch[0].BranchNo, {max($0,$1.BranchNo)}) + 1
                                }
                                
                                let sortedID = MainMenu.sorted{$0.id < $1.id}
                                id = sortedID.last!.id + 1
                            }
                            
//                            let id = MainMenu.count
                            
                            MainMenu.append(CellData(
                                id      : id,
                                seat    : mainM.seat,
                                No      : mainM.holder,
                                Name    : (globals_select_menu_no.menu_name),
                                MenuNo  : "\(globals_select_menu_no.menu_no)",
                                BranchNo: branchNo,
                                Count   : "\(mainM.count)",
                                Hand    : isHand,
                                MenuType: 1,
                                payment_seat_no: mainM.seat_no
                                )
                            )

                            select_menu_categories.append(select_menu_category(
                                id: id,
                                category1: globals_select_category.no1,
                                category2: globals_select_category.no2
                                )
                            )
                            
//                            // 一旦選択メニューのセレクトメニューを削除
//                            if SubMenu.count > 0 {
//
//                                let sub_menu_b = SubMenu
//                                SubMenu = []
//                                for submenu0 in sub_menu_b {
//                                    if submenu0.No != mainM.holder || submenu0.MenuNo != "\(globals_select_menu_no.menu_no)" || submenu0.seat != mainM.seat || submenu0.BranchNo != branchNo{
//                                        SubMenu.append(submenu0)
//                                    }
//                                }
//                            }
                            
                            // 確定したセレクトメニューを登録
                            for submenu in DecisionSubMenu {
                                if "\(globals_select_menu_no.menu_no)" == submenu.MenuNo {
                                    SubMenu.append(SubMenuData(
                                        id:id,
                                        seat:mainM.seat,
                                        No: mainM.holder,
                                        MenuNo: submenu.MenuNo,
                                        BranchNo: branchNo,
                                        Name: submenu.Name,
                                        sub_menu_no: submenu.subMenuNo,
                                        sub_menu_group: submenu.subMenuGroup)
                                    )
                                }
                            }

                            // オプションメニューの登録
                            let spMenus = selectSPmenus.filter({$0.seat == mainM.seat && $0.holderNo == mainM.holder && $0.menuNo == globals_select_menu_no.menu_no})
                            if spMenus.count > 0 {
                                for spMenu in spMenus {
                                    
                                    let sp_menu_no = "\(spMenu.menuNo)"
                                  
                                    // 重複データは保存しない
                                    let idx = SpecialMenu.index(where: {$0.id == id && $0.MenuNo == sp_menu_no && $0.category == spMenu.category && $0.Name == spMenu.spMenuName})
                                    if idx == nil {
                                        SpecialMenu.append(SpecialMenuData(
                                            id      : id,
                                            seat    : mainM.seat,
                                            No      : spMenu.holderNo,
                                            MenuNo  : sp_menu_no,
                                            BranchNo: branchNo,
                                            Name    : spMenu.spMenuName,
                                            category: spMenu.category
                                            )
                                        )                                        
                                    }
                                    
                                }
                                
                            }

                            // イメージデータの情報更新
                            db.open()
                            
                            let sql2 = "UPDATE hand_image SET branch_no = ? WHERE holder_no = ? AND order_no = ? AND branch_no = ? AND seat = ?;"
                            var argumentArray:Array<Any> = []
                            argumentArray.append(branchNo)
                            argumentArray.append(mainM.holder)
                            argumentArray.append(NSNumber(value: globals_select_menu_no.menu_no as Int64))
                            argumentArray.append(-1)
                            argumentArray.append(mainM.seat)
                            
                            let results2 = db.executeUpdate(sql2, withArgumentsIn: argumentArray)
                            if !results2 {
                                // エラー時
                                print(results2.description)
                            }
                            
                            db.close()
                            
                            
                            
                            // 同じメニューを頼んでいる人は、数量だけを更新する
//                            var is_same = false
//                            for i in 0..<MainMenu.count {
//                                if (mainM.seat == MainMenu[i].seat) && (mainM.holder == MainMenu[i].No) && ("\(globals_select_menu_no.0)" == MainMenu[i].MenuNo) {
//                                    is_same = !is_same
//                                    MainMenu[i].Count = "\(Int(MainMenu[i].Count)! + mainM.count)"
//                                    
//                                }
//                            }
                            
//                            if is_same == false {
//                                MainMenu.append(CellData(
//                                    seat: mainM.seat,
//                                    No: mainM.holder,
//                                    Name: (globals_select_menu_no.1),
//                                    MenuNo: "\(globals_select_menu_no.0)",
//                                    BranchNo: 1,
//                                    Count: "\(mainM.count)",
//                                    Hand: isHand,
//                                    MenuType: 1)
//                                )
//                            }

                            

//                            // サブメニューの削除
//                            if SubMenu.count > 0 {
//                                let sub_menu_b = SubMenu
//                                SubMenu = []
//                                for submenu0 in sub_menu_b {
//                                    if submenu0.No != mainM.holder || submenu0.MenuNo != "\(globals_select_menu_no.0)" {
//                                        SubMenu.append(submenu0)
//                                    }
//                                }
//                            }
//                            
//                            // サブメニューの登録
//                            for submenu in DecisionSubMenu {
//                                if "\(globals_select_menu_no.0)" == submenu.MenuNo {
//                                    SubMenu.append(SubMenuData(
//                                        seat    : mainM.seat,
//                                        No      : mainM.holder,
//                                        MenuNo  : submenu.MenuNo,
//                                        Name    : submenu.Name)
//                                    )
//                                }
//                            }

                        } else {
                            // オーダー数が0でも特殊メニュー（オプションメニュー)を選んでいる場合は消す。
                            print(mainM.holder ,selectSPmenus)
                            selectSPmenus = selectSPmenus.filter({!($0.holderNo == mainM.holder && $0.menuNo == globals_select_menu_no.menu_no && $0.seat == mainM.seat)})
                            print(mainM.holder ,selectSPmenus)

                            // オーダー数0の手書き情報を消す。
                            selectMenuCount = selectMenuCount.filter({!($0.No == mainM.holder && $0.MenuNo == (globals_select_menu_no.menu_no).description && $0.seat == mainM.seat)})
                            
                            db.open()
                            let sql = "DELETE from hand_image WHERE seat = ? AND holder_no = ? AND order_no = ? AND branch_no = ?;"
                            
                            var argumentArray:Array<Any> = []
                            argumentArray.append(mainM.seat)
                            argumentArray.append(mainM.holder)
                            argumentArray.append(NSNumber(value: globals_select_menu_no.menu_no as Int64))
                            argumentArray.append(-1)
                            
                            let _ = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                            
                            db.close()
                            
                        }
                    }
                }
                DecisionSubMenu = []
                selectSPmenus = []
                
//                print("mainmenu",MainMenu)
//                print("option",SpecialMenu)
                
                self.performSegue(withIdentifier: "toMenuSelectViewSegue",sender: nil)
            }
        }
    }
    
    
    // 次の画面から戻ってくるときに必要なsegue情報
    @IBAction func unwindToOrderInput(_ segue: UIStoryboardSegue) {
        
        
    }

    func reset_select() {
        
        // 一人しかいない場合は常に選択状態にする
        let tableDataFilter = tableData.filter({$0.holder != ""})
        if tableDataFilter.count != 1 {
            for i in 0..<cell_Long_Tap.count {
                cell_Long_Tap[i] = false
            }
        }
        
    }
    
    //UIImageをデータベースに格納できるStringに変換する
    func Image2String(_ image:UIImage) -> String? {
        
        //画像をNSDataに変換
//        let data:NSData = UIImagePNGRepresentation(image)!
        let data:Data? = UIImageJPEGRepresentation(image,0.9)
        
        //NSDataへの変換が成功していたら
        if let pngData:Data = data {
            
            //BASE64のStringに変換する
            let encodeString:String =
                pngData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
            
            return encodeString
            
        }
        
        return nil
        
    }
    
    //StringをUIImageに変換する
    func String2Image(_ imageString:String) -> UIImage?{
        
        //空白を+に変換する
//        var base64String = imageString.stringByReplacingOccurrencesOfString(" ", withString:"+",options: nil, range:nil)
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
    
    // ボタンを長押ししたときの処理
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

    // 表示モード取得
    func get_grid_disp() -> Int {
        var grid = 1
        
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
        let sql = "SELECT * FROM staffs_now;"
        
        var staff = 0
        
        // 今接客している、従業員情報取得
        let rs = db.executeQuery(sql, withArgumentsIn: [])
        while (rs?.next())! {
            staff = Int((rs?.int(forColumn:"staff_no"))!)
        }

        let sql1 = "SELECT * FROM disp_mode WHERE staff_no = ?;"
        let rs1 = db.executeQuery(sql1, withArgumentsIn: [staff])
        while (rs1?.next())! {
            grid = Int((rs1?.int(forColumn:"disp_mode"))!)
        }
        
        return grid
    }
    
    // 表示モード保存
    func set_grid_mode(_ mode:Int) {
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
        let sql = "SELECT * FROM staffs_now;"
        
        var staff = 0
        
        // 今接客している、従業員情報取得
        let rs = db.executeQuery(sql, withArgumentsIn: [])
        while (rs?.next())! {
            staff = Int((rs?.int(forColumn:"staff_no"))!)
        }
        
        let sql1 = "INSERT OR REPLACE INTO disp_mode (staff_no ,disp_mode) VALUES (?, ?);"
        let rs1 = db.executeUpdate(sql1, withArgumentsIn: [staff,mode])
        if !rs1 {
            print(rs1.description)
        }
    }
    
    func getIndex(_ indexPath:IndexPath) -> Int {
        var index = 0
        if listOrCell == true {
            // 表示順にする
            index = seat.index(where: {$0.disp_position == indexPath.row + 1})!
        } else {
            // シートNO順にする
            index = seat.index(where: {$0.seat_no == indexPath.row})!
        }
        
        return index
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
        }
    }
    
    override func motionCancelled(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion cancelled")
        }
    }

    
    
}

