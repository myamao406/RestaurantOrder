//
//  timezoneViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/06/30.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB

class timezoneViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate {

    fileprivate var onceTokenViewDidAppear: Int = 0
    
    // セルデータの型
    struct CellData {
        var id:Int
        var text:String
        var iconName:String
        var rgb:String
        var iconImage:UIImage?
    }
    
    // セルデータの配列
    var tableData:[CellData] = []
    var timezone:String?
    
//    let size_scale : CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 2.0 : 1.0
    
    var tableViewMain = UITableView()
    
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 背景色を白に設定する.
        self.view.backgroundColor = UIColor.white
        
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

        let selectedAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        let barItem = UIBarButtonItem(title: "テーブルNo: " + "\(globals_table_no)", style: .done, target: self, action: nil)
        
        barItem.setTitleTextAttributes(selectedAttributes, for: UIControlState())
        barItem.setTitleTextAttributes(selectedAttributes, for: .disabled)
        
        barItem.isEnabled = false
        navBar.topItem?.setRightBarButton(barItem, animated: false)

        
        self.loadData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 一番手前にする
//        dispatch_once(&self.onceTokenViewDidAppear) {
            DemoLabel.Show(self.view)
//        }
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
        self.tableData = []
        self.tableData.append (CellData(id:0,text :"朝",iconName :"coffee",rgb :"0.800,0.631,0.498",iconImage: UIImage()))
        self.tableData.append (CellData(id:1,text :"昼",iconName :"sun-o",rgb :"0.898,0.188,0.239",iconImage: UIImage()))
        self.tableData.append (CellData(id:2,text :"晩",iconName :"moon-o",rgb :"1.000,0.667,0.000",iconImage: UIImage()))
        self.tableData.append (CellData(id:3,text :"パーティ",iconName :"trophy",rgb :"1.000,0.667,0.000",iconImage: UIImage()))

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
        let sql = "SELECT count(*) FROM timezone;"
        let results = db.executeQuery(sql, withArgumentsIn: [])
        while (results?.next())! {
            // データがある場合
            if (results?.int(forColumnIndex:0))! > 0 {
                self.tableData = []
                let sql2 = "SELECT * FROM timezone ORDER BY id;"
                let results2 = db.executeQuery(sql2, withArgumentsIn: [])
                while (results2?.next())! {
                    let id = Int((results2?.int(forColumn:"id"))!)
                    let tz = (results2?.string(forColumn:"timezone") != nil) ? results2?.string(forColumn:"timezone") :""
                    let icon = (results2?.string(forColumn:"icon_Name") != nil) ? results2?.string(forColumn:"icon_Name") : ""
                    let rgb = (results2?.string(forColumn:"rgb") != nil) ? results2?.string(forColumn:"rgb") : "0/0/0"
                    
                    var setIcon = UIImage()
                    let iconImage = String2Image((results2?.string(forColumn:"icon_image"))!)
                    if iconImage != nil {
                        setIcon = iconImage!
                    }
                    
                    
                    self.tableData.append(CellData(id: id,text :tz!,iconName: icon!,rgb: rgb!,iconImage:setIcon))
                }
            }
        }
        
        // テーブルビューを作る
        // Status Barの高さを取得する.
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height

        // Viewの高さと幅を取得する.
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height - toolBarHeight
        
        // TableViewの生成する(status barの高さ分ずらして表示).
        self.tableViewMain = UITableView(frame: CGRect(x: 0, y: barHeight + NavHeight, width: displayWidth, height: displayHeight - barHeight - NavHeight), style: UITableViewStyle.plain)
                    
        // テーブルビューを追加する
        self.view.addSubview(self.tableViewMain)
                    
        // テーブルビューのデリゲートとデータソースになる
        self.tableViewMain.delegate = self
        self.tableViewMain.dataSource = self
                    
        // xibをテーブルビューのセルとして使う
        let xib = UINib(nibName: "TableViewCell", bundle: nil)
        self.tableViewMain.register(xib, forCellReuseIdentifier: "Cell")

        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 行数はセルデータの個数
        return tableData.count
    }
    
    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! TableViewCell
        // セルに表示するデータを取り出す
        let cellData = tableData[indexPath.row]

        let iconName = "fa-" + cellData.iconName
        let allIcons:NSDictionary = NSDictionary(dictionary: FAKFontAwesome.allIcons())
        
        var Image = UIImage()

        
        if cellData.iconImage != nil && cellData.iconImage?.size != CGSize.zero {
            Image = cellData.iconImage!
        } else {

            let resultCode = allIcons.object(forKey: iconName)
            if (resultCode == nil) {
//                // アイコンが設定されていない時はスマイルマークを出す
//                resultCode = allIcons.objectForKey("fa-smile-o")
                
                Image = UIImage()
            } else {
                let button = FAKFontAwesome(code: resultCode as! String, size: iconSize)
                
                // 色
                let str = cellData.rgb
                let arr = str.components(separatedBy: "/")
                
                let r:CGFloat = (arr[0] != "") ? CGFloat(NumberFormatter().number(from: arr[0])!) : 0.0
                let g:CGFloat = (arr[1] != "") ? CGFloat(NumberFormatter().number(from: arr[1])!) : 0.0
                let b:CGFloat = (arr[2] != "") ? CGFloat(NumberFormatter().number(from: arr[2])!) : 0.0
                button?.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: r, green: g, blue: b, alpha: 1.000))
                Image = (button?.image(with: CGSize(width: iconSize, height: iconSize)))!
            }
        }

        cell.cellImage.image = Image
        
        // ラベルにテキストを設定する
        cell.cellLabel.text = cellData.text
        
        // 設定済みのセルを戻す
        return cell
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // セクションのタイトル（UITableViewDataSource）
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "テーブルNo:" + "\(globals_table_no)"
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! TableViewCell
            // セルの高さと同じ
            return cell.bounds.height * size_scale
        }

        return UITableViewAutomaticDimension
    }
    
    // セルの高さを返す（UITableViewDelegate）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! TableViewCell
        // セルの高さ
        
        return cell.bounds.height * size_scale
    }
    
    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // SubViewController へ遷移するために Segue を呼び出す
        // セルに表示するデータを取り出す
        let cellData = tableData[indexPath.row]
        timezone = cellData.text
        globals_timezone = cellData.id
        performSegue(withIdentifier: "toPlayerSetViewSegue",sender: nil)
    }
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        performSegue(withIdentifier: "toTableNoInputViewSegue",sender: nil)
    }
    
    
    // Segue 準備
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
//        if (segue.identifier == "toPlayerSetViewSegue") {
////            let navigationController = segue.destinationViewController as! UINavigationController
////            let subVC: FeelingCheckViewController = navigationController.viewControllers[0] as FeelingCheckViewController
////            subVC.feelid = sid
//        }
//    }
    
    // 次の画面から戻ってくるときに必要なsegue情報
    @IBAction func unwindToTimezone(_ segue: UIStoryboardSegue) {
        
    }
    
    // MARK: - Override methods
    
    override var canBecomeFirstResponder : Bool {
        return true
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

    //StringをUIImageに変換する
    func String2Image(_ imageString:String) -> UIImage?{
        
        //空白を+に変換する
        let base64String = imageString.replacingOccurrences(of: " ", with:"+")
        
        //BASE64の文字列をデコードしてNSDataを生成
        let decodeBase64:Data? =
            Data(base64Encoded:base64String, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)

        if let decodeSuccess = decodeBase64 {
            
            //NSDataからUIImageを生成
            let img = UIImage(data: decodeSuccess)
            
            //結果を返却
            return img
        }
        
        return nil
        
    }

}
