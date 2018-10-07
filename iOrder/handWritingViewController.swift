//
//  handWritingViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/12.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import NextGrowingTextView
import FontAwesomeKit
import FMDB

class handWritingViewController: UIViewController, DrawableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate,UINavigationBarDelegate {

    fileprivate var onceTokenViewDidAppear: Int = 0

    var drawableView: DrawableView! = nil
//    var drawableView: SNDrawView? = nil
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var growingTextView: NextGrowingTextView!
    @IBOutlet weak var inputContainerViewBottom: NSLayoutConstraint!
    @IBOutlet weak var orderCountLabel: UILabel!
    @IBOutlet weak var textInputOKButton: UIButton!
    
    
    let targetLabel = OutLineLabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        // 確定ボタン
        iconImage = FAKFontAwesome.checkIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image, for: UIControlState())
        
        // クリアボタン
        iconImage = FAKFontAwesome.timesCircleIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_greenColor)
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        clearButton.setImage(Image, for: UIControlState())
        
        textInputOKButton.backgroundColor = iOrder_borderColor
        textInputOKButton.layer.cornerRadius = 4
        textInputOKButton.layer.borderWidth = 1.0
        textInputOKButton.layer.borderColor = iOrder_borderColor.cgColor
        
        if drawableView == nil {
            // Status Barの高さを取得する.
            let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
            
            // inputTextの高さを取得する
            self.inputContainerView.layoutIfNeeded()
            let inputTextHeight: CGFloat = hand_write_mode == 1 ? inputContainerView.frame.height : 0.0
            
            // Viewの高さを取得する.
            let displayHeight: CGFloat = self.view.frame.height - toolBarHeight
            
            drawableView = DrawableView(frame: CGRect(x: 0, y: barHeight + NavHeight, width: self.view.bounds.width, height: displayHeight - (barHeight + NavHeight + inputTextHeight)))
            
            drawableView.backgroundColor = UIColor.white
            drawableView.setLineColor(iOrder_blackColor.cgColor)
            drawableView.setLineWidth(5)

            drawableView.delegate = self

            if globals_image != nil && globals_image!.size != CGSize(width:0, height: 0){
                drawableView.setBackgroundImage(globals_image!)
                isUpdate = true
            }
            
            
            self.view.addSubview(drawableView)
            
            // 手書き入力画面での文字入力可否
            if hand_write_mode == 1 {
                inputContainerView.isHidden = false
                self.view.sendSubview(toBack: drawableView)
                self.view.bringSubview(toFront: inputContainerView)
            } else {
                inputContainerView.isHidden = true
            }

            
            

        }
        
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(handWritingViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handWritingViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.growingTextView.layer.cornerRadius = 4
        self.growingTextView.layer.borderWidth = 1.0
        self.growingTextView.layer.borderColor = iOrder_borderColor.cgColor
        self.growingTextView.backgroundColor = UIColor.clear
        self.growingTextView.textView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        
        // メニュー名
        self.navBar.topItem?.title = (globals_select_menu_no.menu_name)
        
        // オーダー数
        var orderCount = 0
        for smc in selectMenuCount {
            orderCount = orderCount + smc.MenuCount
        }
        
        orderCountLabel.text = orderCount.description

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)


        DemoLabel.Show(self.view)
        DemoLabel.modeChange()

        // アウトライン付きのラベルを生成
        self.targetLabel.backgroundColor = UIColor.clear
        
        self.targetLabel.font = UIFont(name: "YuGo-Bold",size: CGFloat(40))
        self.targetLabel.numberOfLines = 0
//        self.targetLabel.layer.position = CGPoint(x: 10, y:10)
        self.targetLabel.frame = CGRect(x: 10, y: 10, width: drawableView.frame.size.width - 20,height: 0)

        self.drawableView.addSubview(targetLabel)
        
        // Pan Gesture で移動出来るようにする
        self.targetLabel.isUserInteractionEnabled = true
        let pan :UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handWritingViewController.moveText(_:)))
        self.targetLabel.addGestureRecognizer(pan)
        
        self.view.sendSubview(toBack: drawableView)
        self.view.bringSubview(toFront: inputContainerView)
    }
    
    // ステータスバーとナビゲーションバーの色を同じにする
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
    // ステータスバーの文字を白にする
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    func keyboardWillHide(_ sender: Notification) {
        if let userInfo = sender.userInfo {
            if let _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                //key point 0,
                self.inputContainerViewBottom.constant = 0
                //textViewBottomConstraint.constant = keyboardHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in self.view.layoutIfNeeded() })
            }
        }
    }
    func keyboardWillShow(_ sender: Notification) {
        if let userInfo = sender.userInfo {
            if let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                self.inputContainerViewBottom.constant = keyboardHeight - toolBarHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    @IBAction func handleSendButton(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        self.targetLabel.text = self.growingTextView.textView.text
        
        
        self.targetLabel.sizeToFit()
        isUpdate = true
        self.growingTextView.textView.text = ""
        self.view.endEditing(true)
    }
    
    // text field が変更された時に呼ばれる
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // テキストを編集
        self.targetLabel.text = textField.text
        self.targetLabel.sizeToFit()
        isUpdate = true
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボード以外の場所をタップするとキーボードを閉じる
        self.view.endEditing(true)
    }
    
    // キーボードのリターンで編集を終了
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.targetLabel.text = textField.text
        self.targetLabel.sizeToFit()
       
        textField.resignFirstResponder()
        return true
    }
    
    internal func moveText(_ pgr:UIPanGestureRecognizer) {
        // pan で動かす
        
        pgr.view?.center = pgr.location(in: self.drawableView)
    }
    
    func saveImage() {
        
        // 変更無しの場合はなにもしない
        if isUpdate == false {
            return;
        }
        
        // photo libraryに保存する
        UIGraphicsBeginImageContext(self.drawableView.frame.size)
        self.drawableView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let viewImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIImageWriteToSavedPhotosAlbum(viewImage, self, nil, nil)
        UIGraphicsEndImageContext()
        
        print("viewImage",viewImage as Any)
        
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

        for (i,smc) in selectMenuCount.enumerated() {
            
            print(smc)
            // すでに存在していれば、UPDATE　なければ、INSERT
            let sql = "SELECT COUNT(*) FROM hand_image WHERE seat = ? AND holder_no = ? AND branch_no = ? AND order_no = ?"
            let result = db.executeQuery(sql, withArgumentsIn: [smc.seat, smc.No,smc.BranchNo,smc.MenuNo])
            
            var image_count = 0
            while (result?.next())! {
                image_count = Int((result?.int(forColumnIndex:0))!)
            }
            
            let imageData: Data?
            if viewImage != nil {
                //            let imageData: NSData? = UIImagePNGRepresentation(viewImage!)
                imageData = UIImageJPEGRepresentation(viewImage!, 0.9)
                selectMenuCount[i].HandWrite = viewImage
                
            } else {
                //            let imageData: NSData? = UIImagePNGRepresentation(viewImage!)
                imageData = nil
                selectMenuCount[i].HandWrite = nil
                
            }
////            let imageData: NSData? = UIImagePNGRepresentation(viewImage!)
//            let imageData: NSData? = UIImageJPEGRepresentation(viewImage!, 0.9)
//            smc.HandWrite = viewImage

            var sql2 = ""
            var argumentArray:Array<Any> = []
            if image_count > 0 {
                print("update")
                sql2 = "UPDATE hand_image SET hand_image = ? WHERE holder_no = ? AND order_no = ? AND branch_no = ? AND seat = ?;"
                argumentArray.append(imageData!)
                argumentArray.append(smc.No)
                argumentArray.append(smc.MenuNo)
                argumentArray.append(smc.BranchNo)
                argumentArray.append(smc.seat)
                
            } else {
                print("insert")
                sql2 = "INSERT INTO hand_image (hand_image,holder_no,order_no,branch_no,order_count,seat) VALUES(?,?,?,?,?,?);"
                argumentArray.append(imageData!)
                argumentArray.append(smc.No)
                argumentArray.append(smc.MenuNo)
                argumentArray.append(smc.BranchNo)
                argumentArray.append(smc.MenuCount)
                argumentArray.append(smc.seat)
            }
            
            let results2 = db.executeUpdate(sql2, withArgumentsIn: argumentArray)
            if !results2 {
                // エラー時
                print(results2.description)
            }
        
        }
        
        
        // シャッターエフェクトをつけてみる
        let stop = UIView(frame: CGRect(x: 0,y: 500,width: 320,height: 500))
        let sbottom = UIView(frame: CGRect(x: 0,y: -500,width: 320,height: 500))
        
        stop.backgroundColor = UIColor.black
        sbottom.backgroundColor = UIColor.black
        self.view.addSubview(stop)
        self.view.addSubview(sbottom)
        UIView.animate(withDuration: 0.3, animations: {
            stop.center = self.view.center
            sbottom.center = self.view.center
            }, completion: { (finished:Bool) in
                UIView.animate(withDuration: 0.3, animations: {
                stop.center = CGPoint(x: 160, y: 800)
                sbottom.center = CGPoint(x: 160, y: -500)
                    }, completion: {(finished: Bool) in
                stop.removeFromSuperview()
                sbottom.removeFromSuperview()
                })
        })
        
        
    }
    
    func load() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            let ipc: UIImagePickerController = UIImagePickerController()
            ipc.delegate = self
            ipc.allowsEditing = true
            
            ipc.sourceType = UIImagePickerControllerSourceType.photoLibrary
            
            self.present(ipc, animated:true, completion:nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismiss(animated: true, completion: nil)
        
        drawableView.setBackgroundImage(image)
    }
    
    func onUpdateDrawableView() {
        
    }
    
    
    func onFinishSave() {
        let alertController = UIAlertController(title: "Saved!", message: "saved to camera roll.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        if (self.presentingViewController as? orderInputViewController) != nil {
            self.performSegue(withIdentifier: "unwindToOrderInputSegue",sender: nil)
        }

    }

    
    
    // クリアボタンタップ
    @IBAction func clearButtonTap(_ sender: AnyObject) {
//        if drawableView != nil {
//            drawableView.clear()
//        }
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        drawableView.clear()

        self.targetLabel.text = ""
        self.targetLabel.frame = CGRect(x: 10, y: 10, width: self.drawableView.frame.size.width - 20,height: 0)
//        self.targetLabel.frame = CGRectMake(10, 10, 0,0)
        
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
        
        for (i,smc) in selectMenuCount.enumerated() {
            
            let sql = "DELETE FROM hand_image WHERE seat = ? AND holder_no = ? AND order_no = ? AND branch_no = ?;"
            let _ = db.executeUpdate(sql, withArgumentsIn: [smc.seat,smc.No,smc.MenuNo,smc.BranchNo])
            
            selectMenuCount[i].HandWrite = UIImage()
        }
        
        // 更新フラグOFF
        isUpdate = false
        
    }
    
    // 確定ボタンタップ
    @IBAction func imageSave(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        self.saveImage()
        isUpdate = false
        if (self.presentingViewController as? orderInputViewController) != nil {
            self.performSegue(withIdentifier: "unwindToOrderInputSegue",sender: nil)
        }
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

class OutLineLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let shadowOffset = self.shadowOffset
        let textColor = self.textColor
        let c = UIGraphicsGetCurrentContext()
        c!.setLineWidth(4)
        c!.setLineJoin(CGLineJoin.round)
        c!.setTextDrawingMode(CGTextDrawingMode.stroke)
        self.textColor = UIColor.white
        super.drawText(in: rect)
        c!.setTextDrawingMode(CGTextDrawingMode.fill)
        self.textColor = textColor
        self.shadowOffset = CGSize(width: 0, height: 0)
        super.drawText(in: rect)
        self.shadowOffset = shadowOffset
    }
}

extension UITextView {
    func _firstBaselineOffsetFromTop() {}
    func _baselineOffsetFromBottom() {}
}
