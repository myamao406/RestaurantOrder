//
//  namesearchViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/04.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit

class namesearchViewController: UIViewController,UINavigationBarDelegate,UIGestureRecognizerDelegate {

    fileprivate var onceTokenViewDidAppear: Int = 0
    
    @IBOutlet weak var abutton: UIButton!
    @IBOutlet weak var kabutton: UIButton!
    @IBOutlet weak var sabutton: UIButton!
    @IBOutlet weak var tabutton: UIButton!
    @IBOutlet weak var nabutton: UIButton!
    @IBOutlet weak var habutton: UIButton!
    @IBOutlet weak var mabutton: UIButton!
    @IBOutlet weak var yabutton: UIButton!
    @IBOutlet weak var rabutton: UIButton!
    @IBOutlet weak var wabutton: UIButton!
    @IBOutlet weak var otherbutton: UIButton!
    @IBOutlet weak var ABC123Button: UIButton!

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!

    // あ、い、う、え、お
//    var labelArr:[UILabel?] = [UILabel(),UILabel(),UILabel(),UILabel()]
    var labelArr:[UILabel?] = [UILabel(),UILabel(),UILabel(),UILabel(),UILabel()]
    
    var xy:[[CGPoint?]] = []
    var labelCenterx:CGFloat?
    var labelCentery:CGFloat?
    
    var selectButtonTag = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor

        // なまえボタン名
        let kanaButton = [abutton,kabutton,sabutton,tabutton,nabutton,habutton,mabutton,yabutton,rabutton,wabutton,otherbutton,ABC123Button]
        
        for kButton in kanaButton {
            let button :UIButton = kButton!
            // 指が触れた時点でのアクション
            button.addTarget(self, action: #selector(namesearchViewController.btnTouch(_:)), for: .touchDown)

            // 指が離れた時点でのアクション
//            button.addTarget(self, action: #selector(namesearchViewController.btnCancel2(_:)), forControlEvents: .TouchCancel)
            button.addTarget(self, action: #selector(namesearchViewController.btnCancel(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(namesearchViewController.btnCancel(_:)), for: .touchUpOutside)
//            button.addTarget(self, action: #selector(namesearchViewController.btnCancel3(_:)), forControlEvents: .TouchDragOutside)
            let directionList:[UISwipeGestureRecognizerDirection] = [.up,.down,.left,.right]
            
            for direction in directionList{
                let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(namesearchViewController.swipeLabel(_:)))
                swipeRecognizer.direction = direction
                swipeRecognizer.delegate = self
                button.addGestureRecognizer(swipeRecognizer)
            }
            // パン
            let tapGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(namesearchViewController.selectLabel(_:)))
            tapGestureRecognizer.delegate = self
            button.addGestureRecognizer(tapGestureRecognizer)
        }
        
        
        let iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        
        // 下記でアイコンの色も変えられます
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
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

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DemoLabel.Show(self.view)
        DemoLabel.modeChange()
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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

    // タッチを感知した際に呼ばれるメソッド
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
    }
    
    // ドラッグを感知した際に呼ばれるメソッド（ドラッグ中何度も呼ばれる）
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesMoved")
        // タッチイベントを取得
        let aTouch = touches.first
        
        // 移動した先の座標を取得
        let location = aTouch!.location(in: self.view)
        print(location)
    }
    
    // 指が離れたことを感知した際に呼ばれるメソッド
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesEnded")
        
    }
    
    
    // ボタンに触れた時のアクション
    func btnTouch(_ sender:UIButton){
        sender.backgroundColor = UIColor.blue
        print("touch")

        var posX:CGFloat?
        var posY:CGFloat?

        selectButtonTag = sender.tag
        
        // 初期化
        xy = []
        
        // 起点となるボタンを支点とする
        // 相対位置を絶対位置に変更
        let absolutePosition = sender.superview!.convert(sender.frame, to: nil)
        labelCenterx = absolutePosition.origin.x + sender.frame.width / 2
        labelCentery = absolutePosition.origin.y + sender.frame.height / 2
        
        for i in 0..<4{
            labelArr[i]!.frame = CGRect(x: 0, y: 0, width: sender.frame.width / 2, height: sender.frame.height / 2)
            
            switch i{
            case 0:     // 上
                posX = absolutePosition.origin.x
                posY = absolutePosition.origin.y + (sender.frame.height / 2)
            case 1:     // 右
                posX = absolutePosition.origin.x + (sender.frame.width / 2)
                posY = absolutePosition.origin.y
            case 2:     // 下
                posX = absolutePosition.origin.x + sender.frame.width
                posY = absolutePosition.origin.y + (sender.frame.height / 2)
            case 3:     // 左
                posX = absolutePosition.origin.x + (sender.frame.width / 2)
                posY = absolutePosition.origin.y + sender.frame.height
            default:
                break
            }
            xy.append([CGPoint(x: posX!, y: posY!),CGPoint(x: posX! + (sender.frame.width / 2), y: posY! + (sender.frame.height / 2))])

            labelArr[i]!.text = aiueo[sender.tag][i + 1]
            if labelArr[i]!.text != "" {
                labelArr[i]!.layer.position = CGPoint(x: posX! , y: posY!)
                labelArr[i]!.backgroundColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.7)
                let fontName = "YuGo-Medium"    // "YuGo-Bold"
                let fontSize : CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 44.0 : 22.0
                labelArr[i]!.font = UIFont(name: fontName,size: fontSize)
                labelArr[i]!.textAlignment = NSTextAlignment.center
//                labelArr[i]!.userInteractionEnabled = true
                self.view.addSubview(labelArr[i]!)

            } else {
                labelArr[i]!.removeFromSuperview()
            }
        }
        labelArr[4]!.frame = CGRect(x: 0, y: 0, width: sender.frame.width, height: sender.frame.height)
        labelArr[4]!.layer.position = CGPoint(x: labelCenterx! , y: labelCentery!)
        labelArr[4]!.backgroundColor = UIColor.clear
        self.view.addSubview(labelArr[4]!)
        
        globals_select_kana = sender.titleLabel!.text!
    }
    
    
    // ボタンから指が離れた時
    func btnCancel(_ sender:UIButton){
        print("離れた  \(globals_select_kana)")
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        if globals_select_kana != "" {
            performSegue(withIdentifier: "toPleyerNameSelectViewSegue",sender: nil)
        }
        for i in 0..<5{
            if labelArr[i] != nil{
                self.labelArr[i]!.removeFromSuperview()
            }
        }
        sender.backgroundColor = sender.tintColor
    }
    

    func swipeLabel(_ sender:UISwipeGestureRecognizer){
        var kanaButton = [abutton,kabutton,sabutton,tabutton,nabutton,habutton,mabutton,yabutton,rabutton,wabutton,otherbutton,ABC123Button]
        var select_kana = ""
        switch(sender.direction){
        case UISwipeGestureRecognizerDirection.up:
            print("上",labelArr[1]!.text as Any)
            select_kana = labelArr[1]!.text!

        case UISwipeGestureRecognizerDirection.down:
            print("下",labelArr[3]!.text as Any)
            select_kana = labelArr[3]!.text!

        case UISwipeGestureRecognizerDirection.left:
            print("左",labelArr[0]!.text as Any)
            select_kana = labelArr[0]!.text!

        case UISwipeGestureRecognizerDirection.right:
            print("右",labelArr[2]!.text as Any)
            select_kana = labelArr[2]!.text!

        default:
            print("default")
            break
        }
        
        if select_kana != "" {
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

            globals_select_kana = select_kana
            performSegue(withIdentifier: "toPleyerNameSelectViewSegue",sender: nil)
        }
        for i in 0..<5{
            if labelArr[i] != nil{
                self.labelArr[i]!.removeFromSuperview()
            }
        }
        
        kanaButton[selectButtonTag]?.backgroundColor = kanaButton[selectButtonTag]?.tintColor

    }
    
    func selectLabel(_ sender:UIPanGestureRecognizer){
        var kanaButton = [abutton,kabutton,sabutton,tabutton,nabutton,habutton,mabutton,yabutton,rabutton,wabutton,otherbutton,ABC123Button]

        switch (sender.state) {
        case .ended:
            print("ended  \(globals_select_kana)")
            if globals_select_kana != "" {
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

                performSegue(withIdentifier: "toPleyerNameSelectViewSegue",sender: nil)
            }
            for i in 0..<5{
                if labelArr[i] != nil{
                    self.labelArr[i]!.removeFromSuperview()
                }
            }
            
            kanaButton[selectButtonTag]?.backgroundColor = kanaButton[selectButtonTag]?.tintColor
            
            break;
        default:

            // subViewの中でpanが入っているviewを返す
            let tappedViews = self.view.subviews.filter({(subview: UIView) -> Bool in
                return subview.bounds.contains(sender.location(in: subview))
            })
            
            // panが入っている
            if tappedViews.count > 0 {
                // 配列になっているので、一つづつ取り出す
                var is_Label = false
                
                for tappedView in tappedViews{
//                    print(tappedView)
                    // 今回はUILabelのものだけを取り出す
                    if tappedView is UILabel {
                        for i in 0..<4{
                            // い、う、え、おボタンかどうか？
                            if self.labelArr[i] == tappedView as? UILabel {
                                is_Label = !is_Label
                                self.labelColor(i)
                                globals_select_kana = self.labelArr[i]!.text!
                                kanaButton[selectButtonTag]?.backgroundColor = kanaButton[selectButtonTag]?.tintColor
                            }
                        }
                    }
                    // panがどこのsubviewにも入っていない場合
                    if !is_Label {
                        if tappedView is UILabel {
                            if self.labelArr[4] == tappedView as? UILabel {
                                globals_select_kana = (kanaButton[selectButtonTag]?.titleLabel!.text!)!
                                kanaButton[selectButtonTag]?.backgroundColor = kanaButton[selectButtonTag]?.tintColor
                            }
                        } else {
                            for i in 0..<4{
                                labelArr[i]!.backgroundColor = iOrder_kana_back
                                // 文字の色を変える
                                labelArr[i]!.textColor = UIColor.black
                            }
                            globals_select_kana = ""
                            kanaButton[selectButtonTag]?.backgroundColor = kanaButton[selectButtonTag]?.tintColor
                            
                        }

                    }
                }
            } else {
                for i in 0..<4{
                    labelArr[i]!.backgroundColor = iOrder_kana_back
                    // 文字の色を変える
                    labelArr[i]!.textColor = UIColor.black
                }
                globals_select_kana = ""
                kanaButton[selectButtonTag]?.backgroundColor = kanaButton[selectButtonTag]?.tintColor
                
            }
            break;
        }
    }
    
    // ラベルと文字の色を変える
    fileprivate func labelColor(_ position:Int){
        for i in 0..<4{
            if i == position {
                labelArr[i]!.backgroundColor = UIColor.blue
                // 文字の色を変える
                labelArr[i]!.textColor = UIColor.white
            } else {
                labelArr[i]!.backgroundColor = iOrder_kana_back
                // 文字の色を変える
                labelArr[i]!.textColor = UIColor.black
            }
        }
    }
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        performSegue(withIdentifier: "toHoldernoinputViewSegue",sender: nil)
        
    }
    
        
    // 次の画面から戻ってくるときに必要なsegue情報
    @IBAction func unwindToNameSearch(_ segue: UIStoryboardSegue) {
        
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
        }
    }
    
    override func motionCancelled(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion cancelled")
        }
    }

    
}
