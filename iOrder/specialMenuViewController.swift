//
//  specialMenuViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/12.
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


class specialMenuViewController: UIViewController ,UICollectionViewDataSource,UICollectionViewDelegate ,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate{

    private lazy var __once: () = {
                self.loadData()
            }()

    fileprivate var onceTokenViewDidAppear: Int = 0

    // カテゴリ
    struct category {
        var category_name:String
        var category_no:Int
        var category_coloer:UIColor
        init(category_name:String,category_no:Int,category_coloer:UIColor){
            self.category_name = category_name
            self.category_no = category_no
            self.category_coloer = category_coloer
        }
    }
    var categorys:[category] = []
    
    // メニュー
    
    // 選択された特殊メニュー
    struct menu {
        var MenuNo:Int        // 特殊メニューNo
        var MenuName:String   // 特殊メニュー名
        var category:Int        // カテゴリNO
        var tanka:Int
        var tanka2:Int
        var tanka3:Int
        var is_Kubun:Bool
        
        init(MenuNo:Int, MenuName:String,category:Int,tanka:Int,tanka2:Int,tanka3:Int,is_Kubun:Bool){
            self.MenuNo = MenuNo
            self.MenuName = MenuName
            self.category = category
            self.tanka = tanka
            self.tanka2 = tanka2
            self.tanka3 = tanka3
            self.is_Kubun = is_Kubun
        }
    }
    
    var menus:[menu] = []
    
    // 一時保存用
    var selectSPmenus_back:[selectSPmenu] = []
    
    // カテゴリNO
    var category_No:[Int] = []

    let category_Coloer = [iOrder_grayColor,iOrder_blueColor,iOrder_greenColor,iOrder_pink,iOrder_lightBrownColor,iOrder_noticeRedColor,iOrder_bargainsYellowColor,iOrder_blueColor,iOrder_greenColor,iOrder_pink,iOrder_lightBrownColor,iOrder_noticeRedColor]
    
    var category_disp_no = [-1,2,0,3,1,4,5,8,6,9,7,10]
    var category_no = 0
    
    // ページコントロール
    var page = 1
    
    // リスト件数
    var count = -1
    
    // タイトル
    var selectMenuTitle = ""
    
    var titleLabel:UILabel?
    
    var tableViewMain = UITableView()
    @IBOutlet weak var collectionViewMain: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var categoryPageControl: UIPageControl!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var orderCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor

        selectMenuTitle = (globals_select_menu_no.menu_name)
        titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 440, height: 44))
        titleLabel!.backgroundColor = UIColor.clear
        titleLabel!.textColor = UIColor.white
        titleLabel!.numberOfLines = 0
        
        titleLabel!.adjustsFontSizeToFitWidth = true
        titleLabel!.minimumScaleFactor = 0.5
        titleLabel!.lineBreakMode = .byTruncatingMiddle
        titleLabel!.textAlignment = NSTextAlignment.center
        titleLabel!.text = selectMenuTitle
        
        let spMenu = self.makeTitle()
        
        if spMenu != "" {
            titleLabel!.text = spMenu + " " + selectMenuTitle
        } else {
            titleLabel!.text = selectMenuTitle
        }
        
        self.navBar.topItem?.titleView = titleLabel

        
        // 背景色を白に設定する.
        self.view.backgroundColor = UIColor.white
        
        // 戻るボタン
        var iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        var Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        backButton.setImage(Image, for: UIControlState())
        
        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.pressedLong(_:)))
        
        backButton.addGestureRecognizer(longPress)
        
        // 確定ボタン
        iconImage = FAKFontAwesome.checkIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image, for: UIControlState())

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

        
        self.countLabel.layoutIfNeeded()
        let maskPath = UIBezierPath(roundedRect: self.countLabel.bounds,
                                    byRoundingCorners: [.topLeft, .bottomLeft],
                                    cornerRadii: CGSize(width: self.countLabel.bounds.height/2, height: self.countLabel.bounds.height/2))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.countLabel.bounds
        maskLayer.path = maskPath.cgPath
        self.countLabel.layer.mask = maskLayer

        
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
        let _path = (paths[0] as NSString).appendingPathComponent(use_db)
        
        // FMDatabaseクラスのインスタンスを作成
        // 引数にファイルまでのパスを渡す
        let db = FMDatabase(path: _path)
        
        // カテゴリを取得する
        db.open()
        categorys = []

        let sql = "SELECT * FROM categorys_master WHERE facility_cd = 2 and category_cd2 = 0 and store_cd = ? order by category_cd1"
        let results = db.executeQuery(sql, withArgumentsIn:[shop_code])
        var i = 0
        while (results?.next())! {
            let cn = (results?.string(forColumn:"category_nm") != nil) ? results?.string(forColumn:"category_nm") :""
            
            let r:CGFloat = CGFloat((results?.double(forColumn:"background_color_r"))! / 255)
            let g:CGFloat = CGFloat((results?.double(forColumn:"background_color_g"))! / 255)
            let b:CGFloat = CGFloat((results?.double(forColumn:"background_color_b"))! / 255)
            
            var cate_color = category_Coloer[i]
            if !(r == 0.0 && g == 0.0 && b == 0.0) {
                cate_color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
            }
            
            self.categorys.append(category(
                category_name   : cn!,
                category_no     : Int((results?.int(forColumn:"category_cd1"))!),
                category_coloer : cate_color
                )
            )
            
            i += 1
        }
        db.close()
        
        var cate_count = 11
        
        let sort_cate = categorys.sorted(by: {$0.category_no > $1.category_no})
        let max_cate_no = sort_cate.first?.category_no
        
        // カテゴリ数が6以下の場合はボタンは表示させない
        if max_cate_no <= 5 {
            leftButton.isHidden = true
            rightButton.isHidden = true
            categoryPageControl.isHidden = true
            
            cate_count = 5
        }
        for i in 0..<cate_count {
            let index = self.categorys.index(where: {$0.category_no == i + 1})
            if index == nil {
                self.categorys.append(category(
                    category_name   : "",
                    category_no     : i + 1,
                    category_coloer : UIColor()
                    )
                )
            }
        }

        // カテゴリ番号順にソートする
        categorys.sort(by: {$0.category_no < $1.category_no})
        
//        print(categorys)

        // オーダー数
        var orderCount = 0
        for i in 0..<selectSP.count {
            orderCount = orderCount + selectSP[i].MenuCount
        }
        
        orderCountLabel.text = orderCount.description
        
        selectSPmenus_back = []
        selectSPmenus_back = selectSPmenus
        
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
            DemoLabel.Show(self.view)
            DemoLabel.modeChange()
        }

        // 選択済みのセルは選択状態にする
        
        for (i,menu) in menus.enumerated() {
            let selectSPmenu = selectSPmenus.filter({$0.menuNo == (globals_select_menu_no.menu_no) && $0.spMenuNo == menu.MenuNo && $0.spMenuName == menu.MenuName})
            for sp in selectSPmenu {
                var allSelect_flags = Array(repeating: false, count: selectSP.count)
                for (j,selectS) in selectSP.enumerated() {
                    if selectS.No == sp.holderNo {
                        allSelect_flags[j] = true
                    }
                }
                
                let idx = allSelect_flags.index(where: {!$0})    // falseがあるか？
                if idx == nil {
                    let indexPath = IndexPath(item: i, section: 0)
                    tableViewMain.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                }
            }

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
        let categoryCell:UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "categorySPCell", for: indexPath)
        
        // Tag番号を使ってLabelのインスタンス生成
        let categoryLabel = categoryCell.contentView.viewWithTag(1) as! UILabel
        
        var cellLabel = ""
        if category_disp_no[indexPath.row] == -1 {
            cellLabel = "すべて"
            categoryCell.backgroundColor = iOrder_grayColor
        } else {
            cellLabel = categorys[category_disp_no[indexPath.row]].category_name
            categoryCell.backgroundColor = cellLabel != "" ? categorys[category_disp_no[indexPath.row]].category_coloer : UIColor.clear
        }

        categoryLabel.text = cellLabel
        categoryLabel.textColor = iOrder_blackColor
       
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
        if categorys.count > 5 {
            c_count = 12
        } else {
            c_count = 6
        }
        
        return c_count
    }
    
    // カテゴリが選択された時
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
//        let categoryCell:UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("categorySPCell", forIndexPath: indexPath)

        if category_disp_no[indexPath.row] == -1 {
            // すべての場合はしょりしない
        } else {
            let categoryLabel = categorys[category_disp_no[indexPath.row]].category_name
            // カテゴリ名が無いものは処理しない
            if categoryLabel == "" {
                return;
            }
        }

        
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        category_no = category_disp_no[indexPath.row] + 1
        // メニューデータ作成
        self.tabledataMake()
        tableViewMain.reloadData()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if categorys.count <= 5 { return; }
        
        if scrollView.tag == 1 {
            print("スクロールスタート")
            // 音
            TapSound.buttonTap("swish1", type: "mp3")
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if categorys.count <= 5 { return; }
        
        if scrollView.tag == 1 {
            
            // スクロール数が1ページ分になったら時.
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
        let displayHeight: CGFloat = self.view.frame.size.height - toolBarHeight - 10
        
        // TableViewの生成する(status barの高さ分ずらして表示).
        self.tableViewMain = UITableView(frame: CGRect(x: 0, y: barHeight + NavHeight + CollectionHeight + 10, width: displayWidth, height: displayHeight - barHeight - NavHeight - CollectionHeight), style: UITableViewStyle.plain)
        
        // trueで複数選択・falseで単一選択
        self.tableViewMain.allowsMultipleSelection = true
        
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
        
        if count >= 0 {
            let str = "\(count) 件"
            let attrText = NSMutableAttributedString(string: str)
            let range1:Range? = str.range(of: " 件")
            
            // フォント(Bold、サイズはUILabelの標準サイズ)
            attrText.addAttributes([NSFontAttributeName: UIFont(name: "YuGo-Medium",size: CGFloat(15))!],range: NSRange(location: str.characters.distance(from: str.startIndex, to: range1!.lowerBound),length: str.characters.distance(from: (range1?.lowerBound)!, to: (range1?.upperBound)!)))
            
            countLabel.attributedText = attrText
        }

        // 行数はセルデータの個数
        return menus.count
    }
    
    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! menuTableViewCell
        // セルに表示するデータを取り出す
        let cellData = menus[indexPath.row]
        
        // すべてのセルのアクセサリービューをまずは消去する
        cell.accessoryView = nil
        cell.accessoryType = .none
        
        // ラベルにテキストを設定する
        cell.menuName.baselineAdjustment = .alignCenters
        cell.menuName.text = cellData.MenuName
        
        let idx = categorys.index(where: {$0.category_no == category_No[indexPath.row]})
        if idx != nil {
            cell.categoryLine.backgroundColor = categorys[idx!].category_coloer
            select_cell_color = categorys[idx!].category_coloer
        }
        
        if cellData.is_Kubun == true {
            // ボタン
            let button = UIButton()
            // 表示されるテキスト
            var text = ""
            if cellData.tanka != 0 {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                
                // 単価区分が一つしかない場合はそれを表示させる。
                var prices = ("",0)
                if globals_price_kbn.count > 0 {
                    globals_price_kbn.sort(by: {$0 < $1})
                    
                    prices = fmdb.getOptionTanka(cellData.category, spe_menu_no: cellData.MenuNo, unit_price_kbn: globals_price_kbn[0])
                }
                
                text = formatter.string(from: NSNumber(value:prices.1))!
                
            }
            
            button.contentHorizontalAlignment = .right
            button.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10)
            button.setTitle(text, for: UIControlState())
            // テキストの色
            button.setTitleColor(UIColor.black, for: UIControlState())
            // サイズ
            button.frame = CGRect(x: 0, y: 0, width: 70, height: 30)
            button.layer.cornerRadius = 15
            button.clipsToBounds = true

            if globals_price_kbn.count > 1 {
                button.backgroundColor = iOrder_borderColor
                button.addTarget(self, action: #selector(specialMenuViewController.checkButtonTapped(_:event:)), for: .touchUpInside)
                
            } else {
                button.backgroundColor = UIColor.clear
            }
            if cell.accessoryView == nil {
                cell.accessoryView = button
            }

        }
        
//        select_cell_color = category_Coloer2[category_No[indexPath.row] - 1]
        // 選択済みのセルは選択状態にする
        
        let selectSPmenu = selectSPmenus.filter({$0.menuNo == (globals_select_menu_no.menu_no) && $0.spMenuNo == menus[indexPath.row].MenuNo && $0.spMenuName == menus[indexPath.row].MenuName})

        var allSelect_flags = Array(repeating: false, count: selectSP.count)
        for (j,selectS) in selectSP.enumerated() {
            let idx0 = selectSPmenu.index(where: {$0.holderNo == selectS.No})
            if idx0 != nil {
                allSelect_flags[j] = true
            }
        }
        
        let idx2 = allSelect_flags.index(where: {!$0})    // falseがあるか？
        if idx2 == nil {
            tableViewMain.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }


        
/*
        for sp in selectSPmenus {
//        for sp in selectSPmenus_tmp {
            // 同じシートの人だけ
            let index = selectSP.indexOf({$0.seat == sp.seat})
            
            if index != nil {
                if sp.menuNo == (globals_select_menu_no.menu_no) && sp.spMenuName == menus[indexPath.row].MenuName {
                    // 一人選択の場合のみ
//                    if selectSP.count == 1 {
                        if sp.holderNo == selectSP[0].No {
                            print(indexPath.section,indexPath.row)
                            tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
                            
                        }
//                    }
                }
                
            }
            
        }
*/
        // 設定済みのセルを戻す
        return cell
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
//    // セクションのタイトル（UITableViewDataSource）
//    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        
//        
//        //println(listTitle)
//        return categorys[category_no - 1]
//    }

    // セクションヘッダーの高さ
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    // セルの高さを返す（UITableViewDelegate）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! menuTableViewCell
        var cell_height = (tableViewMain.bounds.height / table_row[disp_row_height])
        
        if cell_height < cell.bounds.height {
            cell_height = cell.bounds.height
        }
        
        return cell_height
//        return (tableViewMain.bounds.height / table_row[disp_row_height])
    }
 
    
    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let selectMenuNo = menus[indexPath.row].MenuNo
        let selectMenuName = menus[indexPath.row].MenuName
        let category = menus[indexPath.row].category
        
        let idx = categorys.index(where: {$0.category_no == category_No[indexPath.row]})
        if idx != nil {
            select_cell_color = categorys[idx!].category_coloer
        }
        
        for selectHolder in selectSP {
            let holdrNo = selectHolder.No
            let seat = selectHolder.seat
            
            selectSPmenus.append(selectSPmenu(
                seat: seat,
                holderNo: holdrNo,
                menuNo: (globals_select_menu_no.menu_no),
                BranchNo: globals_select_menu_no.branch_no,
                spMenuNo: selectMenuNo,
                spMenuName: selectMenuName,
                category:category
                )
            )
        }
        
        
        let spMenu = self.makeTitle()
        
        if spMenu != "" {
            titleLabel!.text = spMenu + " " + selectMenuTitle
        } else {
            titleLabel!.text = selectMenuTitle
        }

        self.navBar.topItem?.titleView = titleLabel
 
        self.tableViewMain.reloadRows(at: [indexPath], with: .none)
    }
    
    
    // Cellの選択が外れたときに呼び出される
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let selectMenuName = menus[indexPath.row].MenuName
        
        let idx = categorys.index(where: {$0.category_no == category_No[indexPath.row]})
        if idx != nil {
            select_cell_color = categorys[idx!].category_coloer
        }
        
        for selectHolder in selectSP {
            let holdrNo = selectHolder.No
            // 合致しないものだけ保存
            
            selectSPmenus = selectSPmenus.filter { !($0.spMenuName == selectMenuName && $0.holderNo == holdrNo) }
        }

//        print(selectSPmenus)
        
        let spMenu = self.makeTitle()
        
        if spMenu != "" {
            titleLabel!.text = spMenu + " " + selectMenuTitle
        } else {
            titleLabel!.text = selectMenuTitle
        }
        self.navBar.topItem?.titleView = titleLabel
        
        self.tableViewMain.reloadRows(at: [indexPath], with: .none)

    }
    
    func tabledataMake(){
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
        
        // メニューを取得する
        db.open()
        menus = []
        category_No = []
        count = 0
        
        //すべてを選択
        var sql:String = ""
        var results:FMResultSet!
        if category_no == 0 {
            sql = "select * from special_menus_master order by category_no and item_no"
            results = db.executeQuery(sql, withArgumentsIn:[])
        } else {
            sql = "select * from special_menus_master where category_no = ? order by item_no"
            results = db.executeQuery(sql, withArgumentsIn:[category_no])
        }
        
        while (results?.next())! {
            count += 1
            let item = (results?.string(forColumn: "item_name") != nil) ? results?.string(forColumn: "item_name") :""
            let menuNo = Int((results?.int(forColumn: "item_no"))!)
            let category = Int((results?.int(forColumn: "category_no"))!)
            let tanka = Int((results?.int(forColumn: "price1"))!)
            let tanka2 = Int((results?.int(forColumn: "price2"))!)
            let tanka3 = Int((results?.int(forColumn: "price3"))!)
            
            var is_Kubun = false
            if tanka > 0 || tanka2 > 0 || tanka3 > 3 {
                is_Kubun = true
            }
            
            self.menus.append(menu(
                MenuNo: menuNo,
                MenuName: item!,
                category: category,
                tanka: tanka,
                tanka2: tanka2,
                tanka3: tanka3,
                is_Kubun: is_Kubun
                )
            )
            
            self.category_No.append(category)
        }
        db.close()
        
    }

    @IBAction func rightButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        self.categoryScroll()
    }
    
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
    
    // 確定ボタンタップ
    @IBAction func okButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // オーダー確認画面からきた場合
        if (self.presentingViewController as? orderMakeSureViewController) != nil {
            
            // 特殊メニュー
            // 選択されている人のオプションメニューを削除する
            
            

            SpecialMenu = SpecialMenu.filter({!($0.id == selectedID)})
            
            for spMenu in selectSPmenus {
                // 選択されている人のオプションメニューだけを追加する。
                for select_user in selectSP {
                    if spMenu.holderNo == select_user.No && spMenu.seat == select_user.seat && spMenu.menuNo.description == select_user.MenuNo {
                        SpecialMenu.append(SpecialMenuData(
                            id      : selectedID,
                            seat    : spMenu.seat,
                            No      : spMenu.holderNo,
                            MenuNo  : "\(spMenu.menuNo)",
                            BranchNo: select_user.BranchNo,
                            Name    : spMenu.spMenuName,
                            category: spMenu.category
                            )
                        )
                    }
                }
            }
            
            self.performSegue(withIdentifier: "toOrderMakeSureViewSegue2",sender: nil)
        } else if (self.presentingViewController as? orderInputViewController) != nil {
            print("SpecialMenu",SpecialMenu)
            print("selectSPmenus",selectSPmenus)
            self.performSegue(withIdentifier: "toOrderInputView",sender: nil)
        }

    }
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        selectSPmenus = []
        selectSPmenus = selectSPmenus_back
        
        if (self.presentingViewController as? orderMakeSureViewController) != nil {
            self.performSegue(withIdentifier: "toOrderMakeSureViewSegue2",sender: nil)
        } else if (self.presentingViewController as? orderInputViewController) != nil {
            self.performSegue(withIdentifier: "toOrderInputView",sender: nil)
        }
    }
    
//    // Segue 準備
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
//        if (segue.identifier == "toMainMenuViewController") {
//            //            let navigationController = segue.destinationViewController as! UINavigationController
//            //            let subVC: FeelingCheckViewController = navigationController.viewControllers[0] as FeelingCheckViewController
//            //            subVC.feelid = sid
//        }
//    }

    func checkButtonTapped(_ sender: UIButton, event: UIEvent) {
        
        // toggle "tap to dismiss" functionality
        ToastManager.shared.tapToDismissEnabled = true
        
        // toggle queueing behavior
        ToastManager.shared.queueEnabled = true
        
        let point = self.tableViewMain.convert(sender.frame.origin, from: sender.superview)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)!
        
        let disp_data = menus[indexPath.row]
        
        globals_price_kbn.sort(by: {$0 < $1})
        
        var msg = ""
        var prices = ("",0)
        for (i,kbn) in globals_price_kbn.enumerated() {
            prices = fmdb.getOptionTanka(disp_data.category, spe_menu_no: disp_data.MenuNo, unit_price_kbn: kbn)
            if i == 0 {
                msg = prices.0 + ":" + (prices.1).description
            } else {
                msg = msg + "\n"
                msg = msg + prices.0 + ":" + (prices.1).description
            }
            
        }

        
//        var msg = "　一般：" + "\(menus[indexPath.row].tanka)"
//        msg = msg + "\n"
//        msg = msg + "従業員：" + "\(menus[indexPath.row].tanka2)"
//        msg = msg + "\n"
//        msg = msg + "その他：" + "\(menus[indexPath.row].tanka3)"
        
        
        // toast with a specific duration and position
        self.view.makeToast(msg, duration: 5.0, position: .center)
    }

    
    func makeTitle() -> String {
        var spMenu = ""
        
//        if selectSP.count != 1 {
//            return spMenu;
//        }
        
        // メニュー名
        var mn:[String] = []
        
        // 選択されたメニューの中からメニュー名だけを取り出す
        for sp in selectSPmenus {
            if sp.holderNo == selectSP[0].No {
                mn.append(sp.spMenuName)
            }
        }
        // 重複した値を外す
        let mnSet = Set(mn)
        
        if mnSet.count > 0 {
            for m in mnSet {
                if spMenu != "" {
                    spMenu = spMenu + "・" + m
                } else {
                    spMenu = "※" + m
                }
            }
        }
        return spMenu
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

}
