//
//  menuSelectViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/07.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB
import Toast_Swift
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class menuSelectViewController: UIViewController ,UICollectionViewDataSource,UICollectionViewDelegate ,UITableViewDelegate,UITableViewDataSource,UIPopoverPresentationControllerDelegate,UINavigationBarDelegate{

    private lazy var __once: () = {
                self.loadData()
                
                //初期表示がカテゴリ番号が6以上の場合はカテゴリ2枚めを表示させる
                if self.category_no > 6 {
                    self.categoryScroll()
                }
            }()

    fileprivate var onceTokenViewDidAppear: Int = 0
    
    // カテゴリ要素
    struct category_data {
        var category_no:Int
        var category_name:String
        var category_coloer:UIColor
    }
    
    // カテゴリ
    var categorys:[category_data] = []

    // サブカテゴリ要素
    struct sub_category_data {
        var category_no:Int
        var category_no2:Int
        var category_name:String
    }

    // サブカテゴリ
    var categorys2:[sub_category_data] = []
    
    // メニュー要素
    struct menu_data {
        var menuNo:Int64
        var menuName:String
        var comment:String
        var comment2:String
        var r:Double
        var g:Double
        var b:Double
    }
    
    // メニュー
    var menus:[menu_data] = []
    
    // サブメニュー
    var sub_Menu:[Int64] = []
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        return dateFormatter
    }()
    
    // ローカルのオーダーNo最大値
    var max_oeder_no : Int?
    
    let category_Coloer = [iOrder_bargainsYellowColor,iOrder_blueColor,iOrder_greenColor,iOrder_pink,iOrder_lightBrownColor,iOrder_noticeRedColor,iOrder_bargainsYellowColor,iOrder_blueColor,iOrder_greenColor,iOrder_pink,iOrder_lightBrownColor,iOrder_noticeRedColor]

    
//    var category_Coloer2:[UIColor] = []
    
    // カテゴリの表示順（縦横を変えるため）
    var category_disp_no = [0,3,1,4,2,5,6,9,7,10,8,11]
    
    // 戻るボタンでの制御のための、カテゴリ
    // -1 のときはサブカテゴリなし、それ以外のときは選択されたカテゴリNO
    var select_category = -1
    
    var category_no = 1
    
    // ページコントロール
    var page = 1
    
    // リスト件数
    var count = -1
    
    // DBパス
    var _path = ""
    
    // indexPath
    var indexP:IndexPath?
    
    // メッセージエリアのtag番号
    var msgTag = 0
    
    // >イメージ
    var angleRightImage:UIImage?
    
    // 送信日時
    var sendTime = ""
    
    let detail_kbn = 9
    
    // サブカテゴリのイメージ
    var subCategoryImage:UIImage?
    
    let initVal = CustomProgressModel()
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var waitButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var categoryPageControl: UIPageControl!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var oderImage: UIImageView!
    @IBOutlet weak var userCountLabel: UILabel!
    @IBOutlet weak var orderCountLabel: UILabel!
    @IBOutlet weak var newLabel: UILabel!
    
    var tableViewMain = UITableView()
    @IBOutlet weak var collectionViewMain: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 背景色を白に設定する.
        self.view.backgroundColor = UIColor.white
        
        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor

        // 戻るボタン
        var iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        var Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        backButton.setImage(Image, for: UIControlState())
        
        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.pressedLong(_:)))
        
        backButton.addGestureRecognizer(longPress)
        
        // 確認ボタン
        iconImage = FAKFontAwesome.checkIcon(withSize: iconSize)
        
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image, for: UIControlState())

        // 待ちボタン
        iconImage = FAKFontAwesome.hourglass2Icon(withSize: iconSize)
        
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_greenColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        waitButton.setImage(Image, for: UIControlState())
        
        // 左ボタン
        iconImage = FAKFontAwesome.angleDoubleLeftIcon(withSize: iconSize)
        
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_blackColor)
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        leftButton.setImage(Image, for: UIControlState())
        
        // 右ボタン
        iconImage = FAKFontAwesome.angleDoubleRightIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_blackColor)
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        rightButton.setImage(Image, for: UIControlState())
        
        // ユーザーイメージ
        iconImage = FAKFontAwesome.userIcon(withSize: 20)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        iconImage?.addAttribute(NSBackgroundColorAttributeName, value: UIColor.whiteColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        userImage.image = Image

        // フードイメージ
        iconImage = FAKFontAwesome.coffeeIcon(withSize: 20)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        iconImage?.addAttribute(NSBackgroundColorAttributeName, value: UIColor.whiteColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        oderImage.image = Image
        
        // 右（>）イメージ
        iconImage = FAKFontAwesome.angleRightIcon(withSize: 20)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.gray)
        angleRightImage = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))

        // サブメニューアイコン
        iconImage = FAKFontAwesome.caretRightIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.black)
        subCategoryImage = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))

        
        // 件数表示（左側だけ丸くする）
        self.countLabel.layoutIfNeeded()
        let maskPath = UIBezierPath(roundedRect: self.countLabel.bounds,
                                    byRoundingCorners: [.topLeft, .bottomLeft],
                                    cornerRadii: CGSize(width: self.countLabel.bounds.height/2, height: self.countLabel.bounds.height/2))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.countLabel.bounds
        maskLayer.path = maskPath.cgPath
        self.countLabel.layer.mask = maskLayer
        
        
        // オーダー待ち機能OFF時はボタンを表示しない
        if is_order_wait != 1 {
            waitButton.isHidden = true
        }
        
        
        // 新規・追加
        switch globals_is_new {
        case 1:
            newLabel.text = "新規"
            // 初期表示カテゴリNoを設定する
            category_no = first_disp_new
        case 2:
            newLabel.text = "追加"
            // 初期表示カテゴリNoを設定する
            category_no = first_disp_add
        case 9:
            if demo_mode == 0 {
                if globals_is_new_wait == 1 {
                    newLabel.text = "新規"
                    // 初期表示カテゴリNoを設定する
                    category_no = first_disp_new
                } else {
                    newLabel.text = "追加"
                    // 初期表示カテゴリNoを設定する
                    category_no = first_disp_add
                }
                
            } else { // デモモードのとき
                newLabel.text = "新規"
                // 初期表示カテゴリNoを設定する
                category_no = first_disp_new
                
            }
        case 10:
            if demo_mode == 0 {
            } else { // デモモードのとき
                newLabel.text = "追加"
                // 初期表示カテゴリNoを設定する
                category_no = first_disp_add
            }
            
        default:
            break;
        }
        
//        if globals_is_new == 1{
////        if globals_is_new == 1 || globals_is_new == 9{
//            newLabel.text = "新規"
//            // 初期表示カテゴリNoを設定する
//            category_no = first_disp_new
//
//        } else {
//            newLabel.text = "追加"
//            // 初期表示カテゴリNoを設定する
//            category_no = first_disp_add
//        }
        
        // カテゴリ情報を取得する
        // 使用DB
        var use_db = production_db
        if demo_mode != 0{
            use_db = demo_db
        }
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        _path = (paths[0] as NSString).appendingPathComponent(use_db)
        
        // FMDatabaseクラスのインスタンスを作成
        // 引数にファイルまでのパスを渡す
        let db = FMDatabase(path: _path)
        
        // カテゴリを取得する
        db.open()
        categorys = []
//        category_Coloer2 = []

        var sql = "select * from categorys_master where facility_cd = 1 and timezone_kbn = 0 AND store_cd = " + shop_code.description + " and category_cd2 = 0 order by category_cd1"
        var results = db.executeQuery(sql, withArgumentsIn:[])
        while (results?.next())! {
            let cnum = Int((results?.int(forColumn:"category_cd1"))!)
            let cn = (results?.string(forColumn:"category_nm") != nil) ? results?.string(forColumn:"category_nm") :""
            
            let r:CGFloat = CGFloat((results?.double(forColumn:"background_color_r"))! / 255)
            let g:CGFloat = CGFloat((results?.double(forColumn:"background_color_g"))! / 255)
            let b:CGFloat = CGFloat((results?.double(forColumn:"background_color_b"))! / 255)

            self.categorys.append(category_data(
                category_no: cnum,
                category_name: cn!,
                category_coloer: UIColor(red: r, green: g, blue: b, alpha: 1.0)))
            
//            category_Coloer2.append(UIColor(red: r, green: g, blue: b, alpha: 1.0))
            
        }
        
        // カテゴリがなければエラーとする。
        let category_cnt = self.categorys.count
        if category_cnt <= 0 {
            let alertController = UIAlertController(title: "エラー！", message: "カテゴリ情報がありません。\nデータ取り込みを再度実施して下さい。", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default){
                action in print("Pushed OK")
                
                return;
            }
            
            alertController.addAction(okAction)
            UIApplication.shared.topViewController()?.present(alertController, animated: true, completion: nil)

        }
        
        // サブカテゴリを取得する
        categorys2 = []
        sql = "select * from categorys_master where facility_cd = 1 AND timezone_kbn = 0 and category_cd2 <> 0 order by category_cd1,category_disp_no"
        results = db.executeQuery(sql, withArgumentsIn:[])
        while (results?.next())! {
            let cnum = Int((results?.int(forColumn:"category_cd1"))!)
            let cnum2 = Int((results?.int(forColumn:"category_cd2"))!)
            let cn = (results?.string(forColumn:"category_nm") != nil) ? results?.string(forColumn:"category_nm") : ""
            self.categorys2.append(sub_category_data(
                category_no: cnum,
                category_no2: cnum2,
                category_name: cn!
                )
            )
        }
        
        db.close()
        
        var cate_count = 12
        let sort_cate = categorys.sorted(by: {$0.category_no > $1.category_no})
        let max_cate_no = sort_cate.first?.category_no
        
        // カテゴリ数が6以下の場合はボタンは表示させない
//        if categorys.count <= 6 {
        if max_cate_no <= 6 {
            leftButton.isHidden = true
            rightButton.isHidden = true
            categoryPageControl.isHidden = true
            
            cate_count = 6
        }
        for i in 0..<cate_count {
            let index = categorys.index(where: {$0.category_no == i + 1})
            if index == nil {
                self.categorys.append(category_data(
                    category_no: i + 1,
                    category_name: "",
                    category_coloer: UIColor()
                    )
                )
            }
        }
        
        // カテゴリ番号順にソートする
        categorys.sort(by: {$0.category_no < $1.category_no})
        
        // 表示カテゴリ番号がカテゴリにない場合は
        // 初期カテゴリを1にする
        
        let idx = categorys.index(where: {$0.category_no == category_no && $0.category_name != ""})
        
        if idx == nil {
            category_no = 1
            
            // toast with a specific duration and position
//            self.view.makeToast("設定カテゴリのメニューはありません。\nカテゴリ1のメニューを表示します。", duration: 1.0, position: .center)

        }
//        if max_cate_no < category_no {
//            category_no = 1
//        }
        
        globals_select_category.no1 = category_no
        globals_select_category.no2 = 0

        
        // お客様人数を取得する
        var uCount = 0
        for i in 0..<takeSeatPlayers.count {
            if takeSeatPlayers[i].holder_no != "" {
                uCount += 1
            }
        }
        
        // 人数
        userCountLabel.text = "\(uCount)"

        // テーブルNO
        self.navBar.topItem?.title = "テーブルNo：" + "\(globals_table_no)"
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 0秒遅延
        let delayTime = DispatchTime.now() + Double(Int64(0.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            _ = self.__once
        }
        
        tableViewMain.reloadData()
        
        DemoLabel.Show(self.view)
        DemoLabel.modeChange()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPathForSelectedRow = tableViewMain.indexPathForSelectedRow {
            tableViewMain.deselectRow(at: indexPathForSelectedRow, animated: true)
        }
        // オーダー数
        var orderCount = 0
        for m in MainMenu {
            let idx0 = seat.index(where: {$0.seat_name == m.seat})
            if idx0 != nil {
                let idx = takeSeatPlayers.index(where: {$0.seat_no == seat[idx0!].seat_no })
//                let idx = Section.indexOf({$0.seat == m.seat && $0.No == m.No})
                if idx != nil {
                    orderCount = orderCount + Int(m.Count)!
                }
            }
        }
        
        let idx = MainMenu.index(where: {Int($0.Count) != 0})
        if idx == nil {
            okButton.isEnabled = false
            okButton.alpha = 0.6
        } else {
            okButton.isEnabled = true
            okButton.alpha = 1.0
        }
        
        orderCountLabel.text = orderCount.description
        
        // バルーンを消す
        removeBalloon()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 画面を抜けるときに、元の設定に戻す
        if order_send_timer.isValid == true {
            // timerを破棄する
            order_send_timer.invalidate()
        }
        
    }
    
    
    // ステータスバーとナビゲーションバーの色を同じにする
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
    // ステータスバーの文字を白にする
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    

    // MARK: - CollectionView
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let categoryCell:UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath)
        
        let cate_name = categorys[category_disp_no[indexPath.row]].category_name
        // Tag番号を使ってLabelのインスタンス生成
        let categoryLabel = categoryCell.contentView.viewWithTag(1) as! UILabel
        let cellLabel = categorys[category_disp_no[indexPath.row]].category_name
        categoryLabel.text = cellLabel
        categoryLabel.textColor = iOrder_blackColor
//        categoryCell.backgroundColor = cate_name != "" ? categorys[category_disp_no[indexPath.row]].category_coloer : iOrder_grayColor
        categoryCell.backgroundColor = cate_name != "" ? categorys[category_disp_no[indexPath.row]].category_coloer : UIColor.clear
        
        return categoryCell
    }
    
    // スクリーンサイズに応じたセルサイズを返す
    // UICollectionViewDelegateFlowLayoutの設定が必要
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,sizeForItemAtIndexPath indexPath:IndexPath) -> CGSize{

        let layout:UICollectionViewFlowLayout =  collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        
        let cellSizeW: CGFloat = ((collectionView.frame.size.width)-(layout.sectionInset.left * 4))/3
        let cellSizeH: CGFloat = ((collectionView.frame.size.height)-(layout.sectionInset.bottom * 3))/2
        return CGSize(width: cellSizeW, height: cellSizeH)
    }
    
    // section  数の設定　今回は１
    func numberOfSections(in collectionView: UICollectionView) -> Int {

        return 1
    }
    

    // 行数を返す
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        // 行数はデータの個数
        var c_count = 0
        if categorys.count > 6 {
            c_count = 12
        } else {
            c_count = 6
        }
        return c_count
    }
    
    // カテゴリが選択された時
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {


        category_no = category_disp_no[indexPath.row] + 1
        let idx = categorys.index(where: {$0.category_no == category_no})
        if idx != nil {
            if categorys[idx!].category_name != "" {
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                
                globals_select_category.no1 = category_no
                globals_select_category.no2 = 0
                
                // メニューデータ作成
                self.tabledataMake()
                self.tableViewMain.reloadData()
                
                // バルーンを消す
                self.removeBalloon()
            }
        }
        
        

    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

        // バルーンを消す
        removeBalloon()
        
        if scrollView.tag == 1 {
            print("スクロールスタート")
            // 音
            TapSound.buttonTap("swish1", type: "mp3")
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        if scrollView.tag == 1 {
        
            if fmod(scrollView.contentOffset.x, (scrollView.frame.maxX - 15) ) == 0 {

                // ページの場所を切り替える.
                page = Int(scrollView.contentOffset.x / (scrollView.frame.maxX - 15)) + 1
                categoryPageControl.currentPage = page - 1
            }
        }
    }
    
    
    // MARK - TableView
    
    func loadData(){

        // テーブルビューを作る
        // Status Barの高さを取得する.
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        
        // UICollectionViewの高さを取得する
        let CollectionHeight: CGFloat = self.collectionViewMain.frame.height
        
        // Viewの高さと幅を取得する.
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height - toolBarHeight - 10
        
        // TableViewの生成する(status barの高さ分ずらして表示).
        self.tableViewMain = UITableView(frame: CGRect(x: 0, y: barHeight + NavHeight + CollectionHeight + 10, width: displayWidth, height: displayHeight - barHeight - NavHeight - CollectionHeight), style: UITableViewStyle.plain)
        
        // テーブルビューを追加する
        self.view.addSubview(self.tableViewMain)
        
        // テーブルビューのデリゲートとデータソースになる
        self.tableViewMain.delegate = self
        self.tableViewMain.dataSource = self
        
        // xibをテーブルビューのセルとして使う
        let xib = UINib(nibName: "menuTableViewCell", bundle: nil)
        self.tableViewMain.register(xib, forCellReuseIdentifier: "Cell")
        // メニューデータ作成
        self.tabledataMake()
    }
    
    
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        // 行数はセルデータの個数
        return menus.count
    }
    
    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! menuTableViewCell
        
        cell.accessoryType = .none
        cell.accessoryView = nil
        
        // セルに表示するデータを取り出す
        let cellData = menus[indexPath.row].menuName
        
        // ラベルにテキストを設定する

        cell.menuName.text = cellData
        cell.menuName.baselineAdjustment = .alignCenters
        
        let remain_c = getremainCount(menus[indexPath.row].menuNo)
        //残数がある場合
        if remain_c != -1 {
            // セレクトメニューの最終行でない
            if sub_Menu[indexPath.row] != -2 {
                // 残数表示ラベル
                let badgeLabel = UILabel()
                
                badgeLabel.font = UIFont(name: "YuGo-Medium",size: CGFloat(20))
                badgeLabel.adjustsFontSizeToFitWidth = true
                badgeLabel.minimumScaleFactor = 0.5 // 最小でも50%までしか縮小しない場合
                badgeLabel.textAlignment = .center
                badgeLabel.baselineAdjustment = .alignCenters
                badgeLabel.text = "\(remain_c)"
                // テキストの色
                badgeLabel.textColor = UIColor.white
                // サイズ
                badgeLabel.frame = CGRect(x: 0, y: 0,width: 30, height: 30)
                // 背景色
                badgeLabel.backgroundColor = iOrder_badge_backColoer
                // 角丸
                badgeLabel.layer.cornerRadius = badgeLabel.frame.height / 2
                badgeLabel.clipsToBounds = true
                // ボーダー幅
                //            button.layer.borderWidth = 1
                
                // コメントがない場合
                if menus[indexPath.row].comment == "" && menus[indexPath.row].comment2 == "" {
                    // accessoryviewにbadgeを追加する
                    let posX = badgeLabel.bounds.width / 2 + 3
                    badgeLabel.layer.position = CGPoint(x: posX, y: cell.bounds.height/2)

                    
                    // UIImageViewを作成する.
                    let angleRightImageView:UIImageView = UIImageView(frame: CGRect(x: 0,y: 0,width: iconSize,height: iconSize))
                    angleRightImageView.image = angleRightImage
                    
                    let posX2:CGFloat = posX + angleRightImageView.bounds.width
                    
                    angleRightImageView.layer.position = CGPoint(x: posX2, y: cell.bounds.height/2)
                    //                angleRightImageView.backgroundColor = UIColor.yellowColor()
                    
                    let v = UIView()
                    v.frame = CGRect(x: 0,y: 0,width: 47,height: cell.bounds.height)
                    //                                                    v.backgroundColor = UIColor.blueColor()
                    if sub_Menu[indexPath.row] > 0 {
                        v.addSubview(angleRightImageView)
                    }
                    v.addSubview(badgeLabel)
                    
                    cell.accessoryView = v

                
                // コメントがある場合
                } else {
                    // インフォメーションボタン
                    let infoButton = ExpansionButton()
                    infoButton.frame = CGRect(x: 0,y: 0,width: info_iconSizeL,height: info_iconSizeL)
                    // ボタンのタップ領域を増やす
                    infoButton.insets = UIEdgeInsetsMake(50, 50, 50, 50)
                    
                    let iconImage = FAKIonIcons.iosInformationOutlineIcon(withSize: info_iconSizeL)
                    
                    if menus[indexPath.row].comment != "" && menus[indexPath.row].comment2 == "" {
                        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_blueColor)
                        let Image = iconImage?.image(with: CGSize(width: info_iconSizeL, height: info_iconSizeL))
                        infoButton.setImage(Image, for: UIControlState())
                        
                    } else {
                        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.red)
                        let Image = iconImage?.image(with: CGSize(width: info_iconSizeL, height: info_iconSizeL))
                        infoButton.setImage(Image, for: UIControlState())
                        
                    }
                    
                    let posX = badgeLabel.bounds.width / 2
                    badgeLabel.layer.position = CGPoint(x: posX, y: cell.bounds.height/2)

                    let posX2 = posX + (infoButton.bounds.width) - 2
                    infoButton.layer.position = CGPoint(x: posX2, y: cell.bounds.height/2)
                    infoButton.addTarget(self, action: #selector(menuSelectViewController.PopUp(_:)), for: .touchUpInside)
                    
                    
                    // UIImageViewを作成する.
                    let angleRightImageView:UIImageView = UIImageView(frame: CGRect(x: 0,y: 0,width: iconSize,height: iconSize))
                    angleRightImageView.image = angleRightImage
                    
                    let posX3 = posX2 + (angleRightImageView.bounds.width)
                    
                    angleRightImageView.layer.position = CGPoint(x: posX3, y: cell.bounds.height/2)
                    
                    let v = UIView()
                    v.frame = CGRect(x: 0,y: 0,width: 83,height: cell.bounds.height)

                    v.addSubview(badgeLabel)
                    v.addSubview(infoButton)
                    if sub_Menu[indexPath.row] > 0 {
                        v.addSubview(angleRightImageView)
                    }
                    
                    cell.accessoryView = v
                    
                }
            }
        
        // 残数がない場合
        } else {
            // コメントがない場合
            if menus[indexPath.row].comment == "" && menus[indexPath.row].comment2 == "" {
                //            cell.accessoryType = .None
                // サブメニューがある場合
                if sub_Menu[indexPath.row] > 0 {
                    // UIImageViewを作成する.
                    let angleRightImageView:UIImageView = UIImageView(frame: CGRect(x: 0,y: 0,width: iconSize,height: iconSize))
                    angleRightImageView.image = angleRightImage
                    
                    let posX:CGFloat = angleRightImageView.bounds.width / 2
                    
                    angleRightImageView.layer.position = CGPoint(x: posX, y: cell.bounds.height/2)
                    let v = UIView()
                    v.frame = CGRect(x: 0,y: 0,width: 15,height: cell.bounds.height)
                    v.addSubview(angleRightImageView)
                    cell.accessoryView = v
                
                // サブメニューがない場合
                } else {
                    cell.accessoryType = .none
                    cell.accessoryView = nil
                }
            // コメントがある場合
            } else {
                // インフォメーションボタン
                let infoButton = ExpansionButton()
                infoButton.frame = CGRect(x: 0,y: 0,width: info_iconSizeL,height: info_iconSizeL)
                // ボタンのタップ領域を増やす
                infoButton.insets = UIEdgeInsetsMake(50, 50, 50, 50)

                let iconImage = FAKIonIcons.iosInformationOutlineIcon(withSize: info_iconSizeL)
                if menus[indexPath.row].comment != "" && menus[indexPath.row].comment2 == "" {
                    iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_blueColor)
                    let Image = iconImage?.image(with: CGSize(width: info_iconSizeL, height: info_iconSizeL))
                    infoButton.setImage(Image, for: UIControlState())
                
                } else {
                    iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.red)
                    let Image = iconImage?.image(with: CGSize(width: info_iconSizeL, height: info_iconSizeL))
                    infoButton.setImage(Image, for: UIControlState())
                
                }
                
                let posX:CGFloat = (infoButton.bounds.width / 2) - 2
                //                    infoButton.layer.position = CGPoint(x: 72-35, y: cell.bounds.height/2)
                infoButton.layer.position = CGPoint(x: posX, y: cell.bounds.height/2)
                infoButton.addTarget(self, action: #selector(menuSelectViewController.PopUp(_:)), for: .touchUpInside)
                
                
                
                // UIImageViewを作成する.
                let angleRightImageView:UIImageView = UIImageView(frame: CGRect(x: 0,y: 0,width: iconSize,height: iconSize))
                angleRightImageView.image = angleRightImage
                
                let posX2:CGFloat = posX + angleRightImageView.bounds.width
                
                angleRightImageView.layer.position = CGPoint(x: posX2, y: cell.bounds.height/2)
                
                let v = UIView()
                v.frame = CGRect(x: 0,y: 0,width: 47,height: cell.bounds.height)
                if sub_Menu[indexPath.row] > 0 {
                    v.addSubview(angleRightImageView)
                }
                v.addSubview(infoButton)
                
                cell.accessoryView = v

            }
        }
        
        cell.backgroundColor = UIColor.clear
        // コメント行の場合
        if menus[indexPath.row].menuNo == -1 {
            if !(menus[indexPath.row].r == 0.0 && menus[indexPath.row].g == 0.0 && menus[indexPath.row].b == 0.0) {
                cell.backgroundColor = UIColor(red: CGFloat(menus[indexPath.row].r) / 255.0, green: CGFloat(menus[indexPath.row].g) / 255.0, blue: CGFloat(menus[indexPath.row].b) / 255.0, alpha: 1.0)
                

            }
            // 左の線の色を出さない
            cell.categoryLine.backgroundColor = UIColor.clear
            select_cell_color = UIColor.clear
            cell.selectionStyle = .none
            
        } else {
            let idx = categorys.index(where: {$0.category_no == category_no})
            if idx != nil {
                cell.categoryLine.backgroundColor = categorys[idx!].category_coloer
                select_cell_color = categorys[idx!].category_coloer
                cell.selectionStyle = .default
                
            }
            
//            cell.categoryLine.backgroundColor = categorys[category_no - 1]
//            select_cell_color = category_Coloer2[category_no - 1]
//            cell.selectionStyle = .Default

        }

        // サブカテゴリの場合
        if sub_Menu[indexPath.row] == -2 {
            // 右に▶を出す
            // UIImageViewを作成する.
            let subCategoryImageView:UIImageView = UIImageView(frame: CGRect(x: 0,y: 0,width: iconSize,height: iconSize))
            subCategoryImageView.image = subCategoryImage
            
            cell.accessoryView = subCategoryImageView
            
        }

        
        // 設定済みのセルを戻す
        return cell
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // セクションヘッダーの高さ
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    // セルの高さを返す（UITableViewDelegate）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! menuTableViewCell
        // セルの高さ
        var cell_height = (tableViewMain.bounds.height / table_row[disp_row_height])
        
        if cell_height < cell.bounds.height {
           cell_height = cell.bounds.height
        }
        
        return cell_height
    }

    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        
        // コメント行は無視する
        if menus[indexPath.row].menuNo == -1 {
            tableViewMain.deselectRow(at: indexPath, animated: false)
            select_cell_color = UIColor.clear
            print("コメント行")
            return;
        }

        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // バルーンを消す
        removeBalloon()
        
        let idx = categorys.index(where: {$0.category_no == category_no})
        if idx != nil {
            select_cell_color = categorys[idx!].category_coloer
        }
//        select_cell_color = category_Coloer2[category_no - 1]
        
        // 新規のメニュー選択の場合は、枝番を-1にする。
        let branch = -1
        
        globals_select_menu_no = (menus[indexPath.row].menuNo,branch,menus[indexPath.row].menuName)

        self.tableViewMain.reloadRows(at: [indexPath], with: .none)
        
        //サブメニューがある場合
        if sub_Menu[indexPath.row] > 0 {
            performSegue(withIdentifier: "toSelectMenuViewSegue",sender: nil)
        
        //サブカテゴリの場合
        } else if sub_Menu[indexPath.row] == -2 {
            select_category = category_no
            let row = indexPath.row
            tabledataMake2(row)
            self.tableViewMain.reloadData()
        } else {
            selectMenuCount = []
            selectSPmenus = []
            performSegue(withIdentifier: "toOrderInputViewSegue",sender: nil)
        }
    }

    // Cellの選択が外れたときに呼び出される
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let idx = categorys.index(where: {$0.category_no == category_no})
        if idx != nil {
            select_cell_color = categorys[idx!].category_coloer
        }
        self.tableViewMain.reloadRows(at: [indexPath], with: .none)
    }
    
    // Cellのアクセサリービューがタップされた場合
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // バルーンを消す
        removeBalloon()

        performSegue(withIdentifier: "toSelectMenuViewSegue",sender: nil)
    }
    
    func tabledataMake(){
        let category_no_Array = categorys2.map{$0.category_no}
        let index = category_no_Array.index(of: category_no)
        // サブカテゴリが無い時
        if index == nil {
            select_category = -1
            
            let db = FMDatabase(path: _path)
            
            // メニューを取得する
            db.open()
            menus = []
            sub_Menu = []
            count = 0
            let sql = "select * from menus_master where category_no1 = ? order by sort_no"
            let results = db.executeQuery(sql, withArgumentsIn:[category_no])
            while (results?.next())! {
                count += 1
                let item = (results?.string(forColumn:"item_name") != nil) ? results?.string(forColumn:"item_name") :""
                let menu_no = results?.longLongInt(forColumn:"item_no")
//                print(menu_no,item)
                let comment1 = (results?.string(forColumn:"item_info") != nil) ? results?.string(forColumn:"item_info") :""
                let comment2 = (results?.string(forColumn:"item_info2") != nil) ? results?.string(forColumn:"item_info2") :""
                let r = results?.double(forColumn: "background_color_r")
                let g = results?.double(forColumn: "background_color_g")
                let b = results?.double(forColumn: "background_color_b")
                
                self.menus.append(menu_data(
                    menuNo:menu_no!,
                    menuName:item!,
                    comment:comment1!,
                    comment2: comment2!,
                    r:r!,
                    g:g!,
                    b:b!
                    )
                )
                self.sub_Menu.append(-1)
                
                //            let menu_no = Int(results?.int(forColumn:"item_no"))
                let sql2 = "select count(*) from sub_menus_master where menu_no = ?"
                let rs = db.executeQuery(sql2, withArgumentsIn:[NSNumber(value: menu_no!)])
                while (rs?.next())! {
                    if (rs?.int(forColumnIndex:0))! > 0 {
                        self.sub_Menu[sub_Menu.count-1] = menu_no!
                    }
                }
            }
            db.close()
        
        // サブカテゴリがある時
        } else {
            select_category = -1
            
            menus = []
            sub_Menu = []
            count = 0
            
            let cate2_filter = categorys2.filter({$0.category_no == category_no})
            if cate2_filter.count > 0 {
                for sub_c in cate2_filter {
                    count += 1
                    menus.append(menu_data(
                        menuNo: Int64(sub_c.category_no2),
                        menuName: sub_c.category_name,
                        comment:"",
                        comment2: "",
                        r:0,
                        g:0,
                        b:0
                        )
                    )
                    self.sub_Menu.append(-2)
                }
                
            }
            
//            for sub_c in categorys2 {
//                if category_no == sub_c.category_no {
//                    count += 1
//                    menus.append(menu_data(
//                        menuNo: Int64(sub_c.category_no2),
//                        menuName: sub_c.category_name,
//                        comment:"",
//                        comment2: "",
//                        r:0,
//                        g:0,
//                        b:0
//                        )
//                    )
//                    self.sub_Menu.append(-2)
//                }
//            }
            
            let db = FMDatabase(path: _path)
            
            db.open()
            let sql = "select * from menus_master where category_no1 = ? AND category_no2 = 0 order by sort_no"
            let results = db.executeQuery(sql, withArgumentsIn:[category_no])
            while (results?.next())! {
                count += 1
                let item = (results?.string(forColumn:"item_name") != nil) ? results?.string(forColumn:"item_name") :""
                let menu_no = results?.longLongInt(forColumn:"item_no")
                let comment1 = (results?.string(forColumn:"item_info") != nil) ? results?.string(forColumn:"item_info") :""
                let comment2 = (results?.string(forColumn:"item_info2") != nil) ? results?.string(forColumn:"item_info2") :""
                let r = results?.double(forColumn: "background_color_r")
                let g = results?.double(forColumn: "background_color_g")
                let b = results?.double(forColumn: "background_color_b")
                
                self.menus.append(menu_data(
                    menuNo:menu_no!,
                    menuName:item!,
                    comment:comment1!,
                    comment2: comment2!,
                    r:r!,
                    g:g!,
                    b:b!
                    )
                )
                self.sub_Menu.append(-1)
                
                let sql2 = "select count(*) from sub_menus_master where menu_no = ?"
                let rs = db.executeQuery(sql2, withArgumentsIn:[NSNumber(value: menu_no!)])
                while (rs?.next())! {
                    if (rs?.int(forColumnIndex:0))! > 0 {
                        self.sub_Menu[sub_Menu.count-1] = menu_no!
                    }
                }
                
            }
            db.close()
        } 
    }
    
    // サブカテゴリがある場合の表示用データ作成
    func tabledataMake2(_ row:Int){
        let db = FMDatabase(path: _path)
        
        // メニューを取得する
        let category_no2 = Int(menus[row].menuNo)
        
        globals_select_category.no2 = category_no2
        
        db.open()
        menus = []
        sub_Menu = []
        count = 0
        let sql = "select * from menus_master where category_no1 = ? and category_no2 = ? order by sort_no"
        let results = db.executeQuery(sql, withArgumentsIn:[category_no,category_no2])
        while (results?.next())! {
            count += 1
            let item = (results?.string(forColumn:"item_name") != nil) ? results?.string(forColumn:"item_name") :""
            let menu_no = results?.longLongInt(forColumn:"item_no")
            let comment1 = (results?.string(forColumn:"item_info") != nil) ? results?.string(forColumn:"item_info") :""
            let comment2 = (results?.string(forColumn:"item_info2") != nil) ? results?.string(forColumn:"item_info2") :""
            
            let r = results?.double(forColumn: "background_color_r")
            let g = results?.double(forColumn: "background_color_g")
            let b = results?.double(forColumn: "background_color_b")
            
            self.menus.append(menu_data(
                menuNo:menu_no!,
                menuName:item!,
                comment:comment1!,
                comment2: comment2!,
                r:r!,
                g:g!,
                b:b!
                )
            )

            self.sub_Menu.append(-1)
            
            let sql2 = "select count(*) from sub_menus_master where menu_no = ?"
            let rs = db.executeQuery(sql2, withArgumentsIn:[NSNumber(value: menu_no!)])
            while (rs?.next())! {
                if (rs?.int(forColumnIndex:0))! > 0 {
                    self.sub_Menu[sub_Menu.count-1] = menu_no!
                }
            }
        }
        db.close()

    }
    
    // インフォメーションボタンと残数がある場合はこちらが呼ばれる
    func PopUp(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let btn = sender as! UIButton
        let cell = btn.superview?.superview as! menuTableViewCell

        let point = self.tableViewMain.convert(sender.frame.origin, from: sender.superview)

        let point2 = self.view.convert(sender.frame.origin, from: sender.superview)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)

        if msgTag == 100 + indexPath!.row {
            // バルーンを消す
            removeBalloon()
            return;
        } else {
            // バルーンを消す
            removeBalloon()
        }
        
        let viewPoint: CGFloat = 2.6
        let popupViewWidth: CGFloat =  self.view.frame.width - 80
        let popupViewHeight: CGFloat = cell.bounds.height * viewPoint
        
        let balloon = BalloonView(frame: CGRect(x: 10, y: point2.y - (popupViewHeight / 2) + (cell.bounds.height / 2),width: popupViewWidth, height: popupViewHeight ))
        BalloonView.permittedArrowDirections.arrow = .right
        
        
        // TextView生成する.
        let myTextView: UITextView = UITextView(frame: CGRect(x: 0.0, y: 0.0, width: popupViewWidth - 13.0, height: cell.bounds.height * viewPoint))
        // TextViewの背景を白色に設定する.
        myTextView.backgroundColor = UIColor.white
        
        let cellData = menus[indexPath!.row]
        
        // 表示させるテキストを設定する.
        var comment = ""
        var attrText:NSMutableAttributedString?
        
        if cellData.comment2 != "" {
            let cnt = cellData.comment2.characters.count
            comment = cellData.comment2
            if cellData.comment != "" {
                comment = comment + "\n" + cellData.comment
            }
            attrText = NSMutableAttributedString(string: comment)
            attrText!.addAttribute(NSForegroundColorAttributeName, value: UIColor.red, range: NSMakeRange(0, cnt))
        } else {
            if cellData.comment != "" {
                comment = cellData.comment
                attrText = NSMutableAttributedString(string: comment)
            }
            
        }
        
        myTextView.attributedText = attrText
        // 角に丸みをつける.
        myTextView.layer.masksToBounds = true
        // 丸みのサイズを設定する.
        myTextView.layer.cornerRadius = 10.0
        // 枠線の太さを設定する.
        myTextView.layer.borderWidth = 3.0
        // 枠線の色を黒に設定する.
        myTextView.layer.borderColor = UIColor.darkGray.cgColor
        // フォントの設定をする.
        //        myTextView.font = UIFont.systemFontOfSize(CGFloat(20))
        myTextView.font = UIFont(name: "YuGo-Medium",size: CGFloat(16))
        // フォントの色の設定をする.
//        myTextView.textColor = iOrder_blackColor
        // 左詰めの設定をする.
        myTextView.textAlignment = NSTextAlignment.left
        // リンク、日付などを自動的に検出してリンクに変換する.
//        myTextView.dataDetectorTypes = UIDataDetectorTypes.All
        // 影の濃さを設定する.
        //        myTextView.layer.shadowOpacity = 0.5
        // テキストを編集不可にする.
        myTextView.isEditable = false
        // TextViewをViewに追加する.
        
        
        balloon.addSubview(myTextView)
        balloon.backgroundColor = UIColor.clear
        balloon.tag = 100 + indexPath!.row
        msgTag = 100 + indexPath!.row
        view.addSubview(balloon)

        
    }

 
 
    func adaptivePresentationStyle(for controller: UIPresentationController)
        -> UIModalPresentationStyle {
            return .none
    }
    
    // セクションの右ボタン
    @IBAction func rightButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // バルーンを消す
        removeBalloon()

        self.categoryScroll()
    }

    // セクションの左ボタン
    @IBAction func leftButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // バルーンを消す
        removeBalloon()

        self.categoryScroll()
    }
    
    func categoryScroll(){
       

        if page == 1 {
            self.collectionViewMain.setContentOffset(CGPoint(x: self.self.collectionViewMain.contentSize.width - self.collectionViewMain.frame.size.width,y: 0),animated: true);
            
            page = 2

        } else {
            self.collectionViewMain.setContentOffset(CGPoint.zero, animated: true);
            page = 1
        }
        categoryPageControl.currentPage = page - 1
    }
    
    // オーダー確認ボタンタップ
    @IBAction func orderCheckButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
//        AVAudioPlayerUtil.play()

        // バルーンを消す
        removeBalloon()

        // セクション
        Section = []
        // シート順にする
        seat.sort(by: {$0.seat_no < $1.seat_no})
        for s in seat {
            let index = takeSeatPlayers.index(where: {$0.seat_no == s.seat_no})
            if index != nil {
                if takeSeatPlayers[index!].holder_no != "" {
                    Section.append(SectionData(
                        seat_no : s.seat_no,
                        seat    : s.seat_name,
                        No      : takeSeatPlayers[index!].holder_no,
                        Name    : fmdb.getPlayerName(takeSeatPlayers[index!].holder_no))
                    )
                    
                }
            }
        }
        
        
//        print("Section",Section)
        
//        print("SubMenu",SubMenu)

        makeOptionMenu()
        
        
        // サブメニュー、特殊メニュー　クリア
        DecisionSubMenu = []
        
        self.performSegue(withIdentifier: "toOrderMakeSureSegue",sender: nil)
    }

    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // バルーンを消す
        removeBalloon()

        if select_category != -1 {
            // メニューデータ作成
            self.tabledataMake()
            tableViewMain.reloadData()
            
            select_category = -1
        } else {
            self.performSegue(withIdentifier: "toPlayerssetViewSegue",sender: nil)
            
        }
        
        
    }
    
    
    func makeOptionMenu() {
        // 特殊メニュー
        for spMenu in selectSPmenus {
            let sp_menu_no = "\(spMenu.menuNo)"
            
            
            
            let index = SpecialMenu.index(where: {$0.No == spMenu.holderNo &&  $0.MenuNo == sp_menu_no && $0.seat == spMenu.seat})
            
//            print(index)
            if index == nil {
                SpecialMenu.append(SpecialMenuData(
                    id:-1,
                    seat    :spMenu.seat,
                    No      :spMenu.holderNo,
                    MenuNo  :sp_menu_no,
                    BranchNo: spMenu.BranchNo,
                    Name    :spMenu.spMenuName,
                    category:spMenu.category
                    )
                )
            }
        }
//        print("SpecialMenu",SpecialMenu)
        
        // 手書き
        for hand in selectMenuCount {
            DecisionHandWrite.append(DecisionHandWriteData(
                No: hand.No,
                MenuNo: hand.MenuNo,
                HandWrite: hand.HandWrite!))
        }

    }
    
    // 一時保留ボタンタップ
    @IBAction func waitButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // バルーンを消す
        removeBalloon()

        // 確認のアラート画面を出す
        // タイトル
        let alert: UIAlertController = UIAlertController(title: "確認", message: "入力中のデータを保存します。\nよろしいですか？", preferredStyle: UIAlertControllerStyle.alert)
        // アクションの設定
        let defaultAction: UIAlertAction = UIAlertAction(title: "はい", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) -> Void in
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

            print("はい")
            
            self.spinnerStart()
            
            // 本番モード
            if demo_mode == 0 {
                
                // セクション
                Section = []
                for takeSeatPlayer in takeSeatPlayers {
                    if takeSeatPlayer.holder_no != "" {
                        let index = seat.index(where: {$0.seat_no == takeSeatPlayer.seat_no})
                        var seat_no = 0
                        var seat_name = ""

                        if index != nil {
                            seat_no = seat[index!].seat_no
                            seat_name = seat[index!].seat_name
                        }
                        
                        Section.append(SectionData(
                            seat_no:seat_no,
                            seat: seat_name,
                            No: takeSeatPlayer.holder_no,
                            Name: fmdb.getPlayerName(takeSeatPlayer.holder_no))
                        )
                        print("SectionData",Section)
                    }
                }
//                print("Section",Section)
//                print("SubMenu",SubMenu)
                
                self.makeOptionMenu()
                
                
                var params:[[String:Any]] = [[:]]
                
                let now = Date() // 現在日時の取得
                self.dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                self.dateFormatter.timeStyle = .medium
                self.dateFormatter.dateStyle = .short
                
                self.sendTime = self.dateFormatter.string(from: now)
                
                params[0]["Process_Div"] = globals_is_new != 9 ? globals_is_new : 3
                
                var cnt = 0
                
                let db = FMDatabase(path: self._path)
                // データベースをオープン
                db.open()
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
                    self.max_oeder_no = dateInt + Int((rs6?.int(forColumnIndex:0))!) + 1
                }

                for sec in Section {
                
                    // プライス区分取得
                    var price_kbn = "1"     // 存在しないプレイヤーの場合
                    
                    let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [Int(sec.No)!,shop_code,globals_today + "%"])
                    
                    while (results?.next())! {
                        price_kbn = ((results?.int(forColumn:"price_tanka"))?.description)!
                    }
                    
                    
                    let mm = MainMenu.filter({$0.No == sec.No && $0.seat == sec.seat})
                    // メニューNOが0の場合か、注文をしていない人の場合は空データを送信する。
                    if (mm.count == 1 && mm[0].MenuNo == "0") || mm.count <= 0 {
                        cnt += 1
                        
                        params.append([String:Any]())
                        params[cnt]["Store_CD"] = shop_code.description
                        params[cnt]["Table_NO"] = "\(globals_table_no)"
                        params[cnt]["Detail_KBN"] = self.detail_kbn.description
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
                        params[cnt]["SendTime"] = self.sendTime // 送信日時（yyyy/mm/dd HH:mm:ss）（拡張用）
                        params[cnt]["Selling_Price"] = ""               // 金額（拡張用）
                        params[cnt]["TerminalID"] = TerminalID          // 端末ID（拡張用）
                        params[cnt]["Reference"] = ""                   // メニュー名
                        params[cnt]["Payment_Customer_Seat_No"] = ""    // 支払者のシートNO
                        params[cnt]["Slip_NO"] = ""             // 伝票NO

                    } else {
                        var pay_No = ""
                        var pay_seat_no = 0
                        var detail_id = 0
                        var main_slip = 0
                        
                        
                        for md in MainMenu {
                            
                            if sec.No == md.No && md.seat == sec.seat{
                                cnt += 1
                                
                                params.append([String:Any]())
                                params[cnt]["Store_CD"] = shop_code.description
                                params[cnt]["Table_NO"] = "\(globals_table_no)"
                                params[cnt]["Detail_KBN"] = self.detail_kbn.description
                                params[cnt]["Order_KBN"] = "1"
                                params[cnt]["Seat_NO"] = "\(sec.seat_no + 1)"
                                params[cnt]["Menu_CD"] = md.MenuNo
                                params[cnt]["Menu_SEQ"] = (md.BranchNo).description
                                params[cnt]["Store_Menu_CD"] = "1"
                                params[cnt]["Sub_Menu_KBN"] = ""
                                params[cnt]["Sub_Menu_CD"] = ""
                                params[cnt]["Spe_Menu_KBN"] = ""
                                params[cnt]["Spe_Menu_CD"] = ""
                                
                                // カテゴリ番号取得
                                var cc1 = ""
                                var cc2 = ""
                                
                                let idx_cate = select_menu_categories.index(where: {$0.id == md.id})
                                if idx_cate != nil {
                                    cc1 = (select_menu_categories[idx_cate!].category1).description
                                    cc2 = (select_menu_categories[idx_cate!].category2).description
                                }
                                
                                params[cnt]["Category_CD1"] = cc1
                                params[cnt]["Category_CD2"] = cc2
                                params[cnt]["Timezone_KBN"] = "\(globals_timezone)"
                                params[cnt]["Qty"] = md.Count
                                params[cnt]["Serve_Customer_NO"] = sec.No
                                
                                // 支払い者のホルダ番号取得
                                var seat_nm = ""
                                let idx = seat.index(where: {$0.seat_no == md.payment_seat_no})
                                if idx != nil {
                                    seat_nm = seat[idx!].seat_name
                                }
                                
                                let index = Section.index(where: {$0.seat == seat_nm})
                                if index != nil {
                                    pay_No = Section[index!].No
                                    pay_seat_no = Section[index!].seat_no + 1
                                }
                                
                                params[cnt]["Payment_Customer_NO"] = pay_No
                                
                                params[cnt]["Employee_CD"] = staff
                                params[cnt]["Unit_Price_KBN"] = price_kbn
                                params[cnt]["Pm_Start_Time"] = globals_pm_start_time
                                
                                // 手書き情報取得
                                var pngData:Data?
                                var image_string = ""
                                                                
                                pngData = fmdb.get_PngData(sec.seat,holder_no: sec.No, menu_no: md.MenuNo,branch_no: md.BranchNo)
                                image_string = pngData!.base64EncodedString(options: .lineLength64Characters)
                                
                                let urlencodeString = image_string.replacingOccurrences(of: "+", with: "%2B")
                                params[cnt]["Handwriting"] = urlencodeString
                                params[cnt]["SendTime"] = self.sendTime            // 送信日時（yyyy/mm/dd HH:mm:ss）（拡張用）
                                params[cnt]["Selling_Price"] = ""       // 金額（拡張用）
                                params[cnt]["TerminalID"] = TerminalID          // 端末ID（拡張用）
                                params[cnt]["Reference"] = md.Name      // メニュー名
                                params[cnt]["Payment_Customer_Seat_No"] = pay_seat_no.description   // 支払者のシートNO
                                params[cnt]["Slip_NO"] = ""             // 伝票NO
                                detail_id += 1
                                main_slip += 1
                                
                            }
                        }
                        
                        // セレクトメニュー（サブメニュー）
                        for sd in SubMenu {
                            if sd.No == sec.No && sd.seat == sec.seat {
                                cnt += 1
                                params.append([String:Any]())
                                params[cnt]["Store_CD"] = shop_code.description
                                params[cnt]["Table_NO"] = "\(globals_table_no)"
                                params[cnt]["Detail_KBN"] = self.detail_kbn.description
                                params[cnt]["Order_KBN"] = "2"
                                params[cnt]["Seat_NO"] = "\(sec.seat_no + 1)"
                                params[cnt]["Menu_CD"] = sd.MenuNo
                                params[cnt]["Menu_SEQ"] = (sd.BranchNo).description
                                params[cnt]["Store_Menu_CD"] = "1"
                                
                                // メニュー区分、サブメニューコード取得
                                var menu_kbn = ""
                                var sub_menu_code = ""
                                let sql = "SELECT * from sub_menus_master WHERE menu_no = ? AND item_name = ?;"
                                let rs = db.executeQuery(sql, withArgumentsIn: [sd.MenuNo,sd.Name])
                                while (rs?.next())! {
                                    menu_kbn = ((rs?.int(forColumn:"sub_menu_group"))?.description)!
                                    sub_menu_code = ((rs?.int(forColumn:"sub_menu_no"))?.description)!
                                }
                                
                                let cellDatas = MainMenu.filter({$0.No == sd.No && $0.MenuNo == sd.MenuNo})
                                var qty = ""
                                for celldata in cellDatas {
                                    qty = celldata.Count
                                }
                                
                                params[cnt]["Sub_Menu_KBN"]     = menu_kbn
                                params[cnt]["Sub_Menu_CD"]      = sub_menu_code
                                params[cnt]["Spe_Menu_KBN"]     = ""
                                params[cnt]["Spe_Menu_CD"]      = ""
                                params[cnt]["Category_CD1"]     = ""
                                params[cnt]["Category_CD2"]     = ""
                                params[cnt]["Timezone_KBN"]     = "\(globals_timezone)"
                                params[cnt]["Qty"]              = qty
                                params[cnt]["Serve_Customer_NO"] = sec.No
                                
                                // 支払い者ホルダ番号取得
                                var pay_seat_no = -1
                                let idx = MainMenu.index(where: {$0.id == sd.id})
                                if idx != nil {
                                    pay_seat_no = MainMenu[idx!].payment_seat_no
                                }
                                
                                // 支払い者のホルダ番号取得
                                var seat_nm = ""
                                let idx1 = seat.index(where: {$0.seat_no == pay_seat_no})
                                if idx1 != nil {
                                    seat_nm = seat[idx1!].seat_name
                                }
                                
                                let index = Section.index(where: {$0.seat == seat_nm})
                                if index != nil {
                                    pay_No = Section[index!].No
                                    pay_seat_no = Section[index!].seat_no + 1
                                }

                                params[cnt]["Payment_Customer_NO"] = pay_No
                                params[cnt]["Employee_CD"]      = staff
                                params[cnt]["Unit_Price_KBN"]   = price_kbn
                                params[cnt]["Pm_Start_Time"]    = globals_pm_start_time
                                params[cnt]["Handwriting"]      = ""
                                params[cnt]["SendTime"] = self.sendTime            // 送信日時（yyyy/mm/dd HH:mm:ss）（拡張用）
                                params[cnt]["Selling_Price"] = ""       // 金額（拡張用）
                                params[cnt]["TerminalID"] = TerminalID          // 端末ID（拡張用）
                                params[cnt]["Reference"] = sd.Name      // メニュー名
                                params[cnt]["Payment_Customer_Seat_No"] = pay_seat_no    // 支払者のシートNO
                                params[cnt]["Slip_NO"] = ""             // 伝票NO

                                detail_id += 1
                                main_slip += 1
                            }
                        }
                        
                        // オプションメニュー（特殊メニュー）
                        for spd in SpecialMenu {
                            if spd.No == sec.No && spd.seat == sec.seat{
                                cnt += 1
                                params.append([String:Any]())
                                params[cnt]["Store_CD"] = shop_code.description
                                params[cnt]["Table_NO"] = "\(globals_table_no)"
                                params[cnt]["Detail_KBN"] = self.detail_kbn.description
                                params[cnt]["Order_KBN"] = "3"
                                params[cnt]["Seat_NO"] = "\(sec.seat_no + 1)"
                                params[cnt]["Menu_CD"] = spd.MenuNo
                                params[cnt]["Menu_SEQ"] = (spd.BranchNo).description
                                params[cnt]["Store_Menu_CD"] = "1"
                                
                                // 特殊メニュー区分、特殊メニューコード取得
                                var spe_menu_kbn = ""
                                var spe_menu_code = ""
                                let sql = "SELECT * from special_menus_master WHERE item_name = ?;"
                                let rs = db.executeQuery(sql, withArgumentsIn: [spd.Name])
                                while (rs?.next())! {
                                    spe_menu_kbn = ((rs?.int(forColumn:"category_no"))?.description)!
                                    spe_menu_code = ((rs?.int(forColumn:"item_no"))?.description)!
                                }
                                
                                let cellDatas = MainMenu.filter({$0.No == spd.No && $0.MenuNo == spd.MenuNo})
                                var qty = ""
                                for celldata in cellDatas {
                                    qty = celldata.Count
                                }
                                
                                params[cnt]["Sub_Menu_KBN"] = ""
                                params[cnt]["Sub_Menu_CD"] = ""
                                params[cnt]["Spe_Menu_KBN"] = spe_menu_kbn
                                params[cnt]["Spe_Menu_CD"] = spe_menu_code
                                params[cnt]["Category_CD1"] = ""
                                params[cnt]["Category_CD2"] = ""
                                params[cnt]["Timezone_KBN"] = "\(globals_timezone)"
                                params[cnt]["Qty"] = qty
                                params[cnt]["Serve_Customer_NO"] = sec.No
                                
                                // 支払い者ホルダ番号取得
                                
                                var pay_seat_no = -1
                                let idx = MainMenu.index(where: {$0.id == spd.id})
                                if idx != nil {
                                    pay_seat_no = MainMenu[idx!].payment_seat_no
                                }
                                
                                
                                // 支払い者のホルダ番号取得
                                var seat_nm = ""
                                let idx1 = seat.index(where: {$0.seat_no == pay_seat_no})
                                if idx1 != nil {
                                    seat_nm = seat[idx1!].seat_name
                                }
                                
                                let index = Section.index(where: {$0.seat == seat_nm})
                                if index != nil {
                                    pay_No = Section[index!].No
                                    pay_seat_no = Section[index!].seat_no + 1
                                }

                                
                                params[cnt]["Payment_Customer_NO"] = pay_No
                                params[cnt]["Employee_CD"] = staff
                                params[cnt]["Unit_Price_KBN"] = price_kbn
                                params[cnt]["Pm_Start_Time"] = globals_pm_start_time
                                params[cnt]["Handwriting"] = ""
                                params[cnt]["SendTime"] = self.sendTime            // 送信日時（yyyy/mm/dd HH:mm:ss）（拡張用）
                                params[cnt]["Selling_Price"] = ""       // 金額（拡張用）
                                params[cnt]["TerminalID"] = TerminalID          // 端末ID（拡張用）
                                params[cnt]["Reference"] = spd.Name     // メニュー名
                                params[cnt]["Payment_Customer_Seat_No"] = pay_seat_no    // 支払者のシートNO
                                params[cnt]["Slip_NO"] = ""             // 伝票NO

                                
                                detail_id += 1
                                main_slip += 1
                                
                            }
                            
                        }
                    
                    }
                    
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
                
                let configuration = URLSessionConfiguration.default
                let session = URLSession(configuration: configuration, delegate:nil, delegateQueue:OperationQueue.main)
                
                let task = session.dataTask(with: request, completionHandler: {
                    (data, response, error) -> Void in
                    do {
                        if error == nil {       // エラーじゃない時
                            let json2 = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments ) as! NSDictionary
                            print(json2)
                            
                            for j2 in json2 {
                                if j2.key as! String == "Return" {
                                    if j2.value as! String == "true" {
                                        // すべての情報をクリアする
                                        common.clear()
                                        selectSPmenus = []
                                        
                                        // 手書きイメージのテーブルの中身を削除
                                        fmdb.remove_hand_image()
                                        
                                        if order_timer.isValid == true {
                                            //timerを破棄する.
                                            order_timer.invalidate()
                                        }

                                        self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
                                        
                                        self.spinnerEnd()
                                        return;
                                    }
                                    
                                }
                                if j2.key as! String == "Message" {
                                    if j2.value as! String != "" {
                                        let msg = j2.value as! String
                                        self.return_error(msg)
                                        
                                        self.spinnerEnd()
                                        return;
                                        
                                    }
                                    
                                }
                            }
                        } else {
                            
                            // 再送データにする
                            print("ERROR",error?.localizedDescription as Any)
                            self.send_error()
                            self.spinnerEnd()
                            return;

                        }
                        
                    } catch {
                        // 再送データにする
                        self.send_error()
                        print("ERROR",error)
                        self.spinnerEnd()
                        //エラー処理
                    }
                    
                })
                
                task.resume()
                db.close()
            } else {        // デモモード
                // セクション
                Section = []
                for takeSeatPlayer in takeSeatPlayers {
                    if takeSeatPlayer.holder_no != "" {
                        let index = seat.index(where: {$0.seat_no == takeSeatPlayer.seat_no})
                        var seat_no = 0
                        var seat_name = ""
                        
                        if index != nil {
                            seat_no = seat[index!].seat_no
                            seat_name = seat[index!].seat_name
                        }
                        
                        Section.append(SectionData(
                            seat_no:seat_no,
                            seat: seat_name,
                            No: takeSeatPlayer.holder_no,
                            Name: fmdb.getPlayerName(takeSeatPlayer.holder_no))
                        )
                        print("SectionData",Section)
                    }
                }

                var kbn = 0
                switch globals_is_new {
                case 1,9:
                    kbn = 9
                    break;
                case 2,10:
                    kbn = 10
                    break;
                default:
                    break;
                }
                
                fmdb.db_save(self.sendTime,detail_kbn: kbn)
                // メインメニュー画面に戻る
                self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
            }

            
        })
        // キャンセルボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "いいえ", style: UIAlertActionStyle.cancel, handler: {(action: UIAlertAction!) -> Void in
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            
            // ボタン押下可とする。
            self.button_enable()
            
            print("いいえ")
        })
        
        // UIAlertControllerにActionを追加
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        // Alertを表示
        present(alert, animated: true, completion: nil)
        
        // 二重送信を防ぐためにOKを押したときは、ボタン押下不可とする。
        self.button_enable(false)

    }
    
    // 残数情報を取得する
    func getremainCount(_ menu_no:Int64) -> Int {
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        let sql = "select * from items_remaining where item_no = ?;"
        let results = db.executeQuery(sql, withArgumentsIn: [NSNumber(value: menu_no as Int64)])
        
        var count = -1
        while (results?.next())! {
            count = Int((results?.int(forColumn:"remaining_count"))!)
        }
        db.close()
        
        return count
    }

    
    // 次の画面から戻ってくるときに必要なsegue情報
    @IBAction func unwindToMenuSelect(_ segue: UIStoryboardSegue) {
        
    }

    // ボタンを長押ししたときの処理
    @IBAction func pressedLong(_ sender: UILongPressGestureRecognizer!) {

        // バルーンを消す
        removeBalloon()

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

    
    // MARK: - Override methods
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion began")

            // バルーンを消す
            removeBalloon()
            
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
    
    func removeBalloon() {
        if msgTag > 0 {
            let fetchedView = view.viewWithTag(msgTag)
            fetchedView!.removeFromSuperview()
            msgTag = 0
        }
    }

    func return_error(_ msg:String){
        let alertController = UIAlertController(title: "エラー！", message: msg , preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            // ボタン押下可とする。
            self.button_enable()
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
    func send_error(){
        
        let error_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(error_beep), userInfo: nil, repeats: true)
        
        
        let alertController = UIAlertController(title: "エラー！", message: "送信エラーが発生しました。\n再送信を行ってください。" , preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            
            // タイマー破棄
            error_timer.invalidate()
            fmdb.resend_db_save(self.max_oeder_no!,send_time: self.sendTime)
            fmdb.db_save(self.sendTime,detail_kbn: 9)
            
            self.performSegue(withIdentifier: "toTopViewSegue",sender: nil);
            // ボタン押下可とする。
            self.button_enable()
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }

    func error_beep(_ sender:Timer){
        // エラー音
        TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)
    }

    func dispatch_async_main(_ block: @escaping () -> ()) {
        DispatchQueue.main.async(execute: block)
    }
    
    func dispatch_async_global(_ block: @escaping () -> ()) {
        DispatchQueue.global().async (execute: block)
    }
    
    func spinnerStart() {
        CustomProgress.Instance.title = "送信中..."
        CustomProgress.Create(self.view,initVal: initVal,modeView: EnumModeView.uiActivityIndicatorView)
        
        //ネットワーク接続中のインジケータを表示
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func spinnerEnd() {
        CustomProgress.Instance.mrprogress.dismiss(true)
        //ネットワーク接続中のインジケータを消去
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func button_enable(_ mode:Bool = true) {
        let alfa:CGFloat = mode ? 1.0 : 0.6
        
        if mode {
            let idx = MainMenu.index(where: {Int($0.Count) != 0})
            if idx == nil {
                okButton.isEnabled = false
                okButton.alpha = 0.6
            } else {
                okButton.isEnabled = true
                okButton.alpha = 1.0
            }
            
        } else {
            self.okButton.isEnabled = mode
            self.okButton.alpha = alfa
            
        }
        
        self.waitButton.isEnabled = mode
        self.waitButton.alpha = alfa
        self.backButton.isEnabled = mode
        self.backButton.alpha = alfa
        
        
        
    }

    
}

