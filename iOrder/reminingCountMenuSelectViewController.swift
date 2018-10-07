//
//  reminingCountMenuSelectViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/25.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB
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


class reminingCountMenuSelectViewController: UIViewController, UICollectionViewDataSource,UICollectionViewDelegate ,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate {
    
    private lazy var __once: () = {
                self.loadData()
                
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
    
    // メニュー
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
    
    // 残数データ
    struct remain_count {
        var menu_no:Int
        var remain_cnt:Int
    }
    var remain_counts:[remain_count] = []
    
    
    let category_Coloer = [iOrder_bargainsYellowColor,iOrder_blueColor,iOrder_greenColor,iOrder_pink,iOrder_lightBrownColor,iOrder_noticeRedColor,iOrder_bargainsYellowColor,iOrder_blueColor,iOrder_greenColor,iOrder_pink,iOrder_lightBrownColor,iOrder_noticeRedColor]
    
    
//    var category_Coloer2:[UIColor] = []
    
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

    // サブカテゴリのイメージ
    var subCategoryImage:UIImage?
    
    var tableViewMain = UITableView()
    @IBOutlet weak var collectionViewMain: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var categoryPageControl: UIPageControl!
    
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
        
        // 左ボタン
        //        iconImage = FAKFontAwesome.chevronCircleLeftIconWithSize(iconSize)
        iconImage = FAKFontAwesome.angleDoubleLeftIcon(withSize: iconSize)
        
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_blackColor)
        //        iconImage?.addAttribute(NSBackgroundColorAttributeName, value: UIColor.whiteColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        leftButton.setImage(Image, for: UIControlState())
        
        // 右ボタン
        //        iconImage = FAKFontAwesome.chevronCircleRightIconWithSize(iconSize)
        iconImage = FAKFontAwesome.angleDoubleRightIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_blackColor)
        //        iconImage?.addAttribute(NSBackgroundColorAttributeName, value: UIColor.whiteColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        rightButton.setImage(Image, for: UIControlState())
        
        // サブメニューアイコン
        iconImage = FAKFontAwesome.caretRightIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.black)
        subCategoryImage = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        
        // 件数表示（左側だけ丸くする）
        self.countLabel.layoutIfNeeded()
        let maskPath = UIBezierPath(roundedRect: countLabel.bounds,
                                    byRoundingCorners: [.topLeft, .bottomLeft],
                                    cornerRadii: CGSize(width: countLabel.bounds.height/2, height: countLabel.bounds.height/2))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = countLabel.bounds
        maskLayer.path = maskPath.cgPath
        countLabel.layer.mask = maskLayer
        
        
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
                category_coloer: UIColor(red: r, green: g, blue: b, alpha: 1.0)
                )
            )
            
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
        sql = "select * from categorys_master where facility_cd = 1 and timezone_kbn = 0 AND category_cd2 <> 0 order by category_cd1,category_disp_no"
        results = db.executeQuery(sql, withArgumentsIn:[])
        while (results?.next())! {
            let cnum = Int((results?.int(forColumn:"category_cd1"))!)
            let cnum2 = Int((results?.int(forColumn:"category_cd2"))!)
            let cn = (results?.string(forColumn:"category_nm") != nil) ? results?.string(forColumn:"category_nm") : ""
            self.categorys2.append(sub_category_data(category_no: cnum,category_no2: cnum2, category_name: cn!))
        }
        
        // 残数データを取得する
        remain_counts = []
        sql = "select * from items_remaining"
        results = db.executeQuery(sql, withArgumentsIn:[])
        while (results?.next())! {
            self.remain_counts.append(remain_count(
                menu_no: Int((results?.int(forColumn:"item_no"))!),
                remain_cnt: Int((results?.int(forColumn:"remaining_count"))!)))
            
        }
        
        db.close()
        
        var cate_count = 12
        let sort_cate = categorys.sorted(by: {$0.category_no > $1.category_no})
        let max_cate_no = sort_cate.first?.category_no
        
        // カテゴリ数が6以下の場合はボタンは表示させない
        if max_cate_no <= 6 {
//        if categorys.count <= 6 {
            leftButton.isHidden = true
            rightButton.isHidden = true
            categoryPageControl.isHidden = true
            
            cate_count = 6
        }
        for i in 0..<cate_count {
            let index = categorys.index(where: {$0.category_no == i + 1})
            if index == nil {
                self.categorys.append(category_data(
                    category_no     : i + 1,
                    category_name   : "",
                    category_coloer : UIColor()
                    )
                )
            }
        }
        
        // カテゴリ番号順にソートする
        categorys.sort(by: {$0.category_no < $1.category_no})

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
            tableViewMain.reloadData()
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
//        categoryCell.backgroundColor = cate_name != "" ? category_Coloer2[category_disp_no[indexPath.row]] : iOrder_grayColor
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
                
                // メニューデータ作成
                self.tabledataMake()
                self.tableViewMain.reloadData()
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
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
        // セルに表示するデータを取り出す
        let cellData = menus[indexPath.row].menuName
        
        // アクセサリービューを消す
        cell.accessoryView = nil
        cell.accessoryType = .none
        
        // ラベルにテキストを設定する
        cell.menuName.text = cellData
        cell.menuName.baselineAdjustment = .alignCenters

        let remain_c = getremainCount(menus[indexPath.row].menuNo)
        if remain_c != -1 {
            // セレクトメニューの最終行でない
            if sub_Menu[indexPath.row] != -2 {
                // 残数表示ラベル
                let badgeLabel = UILabel()
                
                badgeLabel.font = UIFont(name: "YuGo-Medium",size: CGFloat(20))
                //            badgeLabel.adjustsFontSizeToFitWidth = false
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
                badgeLabel.backgroundColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
                // 角丸
                badgeLabel.layer.cornerRadius = badgeLabel.frame.height / 2
                badgeLabel.clipsToBounds = true
                // ボーダー幅
                //            button.layer.borderWidth = 1
                
                
                // accessoryviewにbadgeを追加する
                cell.accessoryView = badgeLabel

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
//            cell.categoryLine.backgroundColor = category_Coloer2[category_no - 1]
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
        
        //        return (tableViewMain.bounds.height / table_row[disp_row_height])
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
        
        globals_select_menu_no = (Int64(menus[indexPath.row].menuNo),0 ,menus[indexPath.row].menuName)
        

        
        
        //サブカテゴリの場合
        
        if sub_Menu[indexPath.row] == -2 {
            select_category = category_no
            let row = indexPath.row
            tabledataMake2(row)
            self.tableViewMain.reloadData()
        } else {
            performSegue(withIdentifier: "toreminingCountSetViewSegue",sender: nil)
        }
    }
    
    func tabledataMake(){
        
        let category_no_Array = categorys2.map{$0.category_no}
        let index = category_no_Array.index(of: category_no)
        // サブカテゴリが無い時
        if index == nil {
            let db = FMDatabase(path: _path)
            // メニューを取得する
            db.open()
            menus = []
            sub_Menu = []
            //        sub_Menu = []
            count = 0
            let sql = "select * from menus_master where category_no1 = ? order by sort_no"
            let results = db.executeQuery(sql, withArgumentsIn:[category_no])
            while (results?.next())! {
                count += 1
                let item = (results?.string(forColumn:"item_name") != nil) ? results?.string(forColumn:"item_name") :""
                let menu_no = results?.longLongInt(forColumn:"item_no")
                let comment1 = (results?.string(forColumn:"item_info") != nil) ? results?.string(forColumn:"item_info") :""
                let comment2 = (results?.string(forColumn:"item_info2") != nil) ? results?.string(forColumn:"item_info2") :""
                let r = results?.double(forColumn:"background_color_r")
                let g = results?.double(forColumn:"background_color_g")
                let b = results?.double(forColumn:"background_color_b")
                
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
            
        } else {        // サブカテゴリがある時
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
                let r = results?.double(forColumn:"background_color_r")
                let g = results?.double(forColumn:"background_color_g")
                let b = results?.double(forColumn:"background_color_b")
                
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
        
        // メニューを取得する
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
            
            
            let r = results?.double(forColumn:"background_color_r")
            let g = results?.double(forColumn:"background_color_g")
            let b = results?.double(forColumn:"background_color_b")
            
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
    
    
    // セクションの右ボタン
    @IBAction func rightButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        self.categoryScroll()
    }
    
    // セクションの左ボタン
    @IBAction func leftButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

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
    
    func getremainCount(_ menu_no:Int64) -> Int {
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
        
        let sql = "select * from items_remaining where item_no = ?;"
        let results = db.executeQuery(sql, withArgumentsIn: [NSNumber(value: menu_no as Int64)])
        
        var count = -1
        while (results?.next())! {
            count = Int((results?.int(forColumn:"remaining_count"))!)
        }
        db.close()
        
        return count
    }
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        if select_category != -1 {
            // メニューデータ作成
            self.tabledataMake()
            tableViewMain.reloadData()
            
            select_category = -1
        } else {
            self.performSegue(withIdentifier: "toTopSegue",sender: nil)
        }
        
    }
    
    // 戻るボタンで戻ってくるためのおまじない
    @IBAction func unwindToReminingCountMenuSelect(_ segue: UIStoryboardSegue) {
        
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
            self.performSegue(withIdentifier: "toTopSegue",sender: nil)
            
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
                self.performSegue(withIdentifier: "toTopSegue",sender: nil)
                
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
    
}
