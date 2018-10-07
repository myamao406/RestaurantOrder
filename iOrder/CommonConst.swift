//
//  CommonConst.swift
//  PNChart-Swift
//
//  Created by 山尾守 on 2015/03/27.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//
//  改定履歴
//  Ver 1.0.2
//      Build 20170530 
//      --デモモード：午後スタート時間を入力しても、保持していない件、修正
//      --デモモード：新規からの保留、追加からの保留で呼び出した時、新規、追加になっていない件、修正
//      Build 20170607
//      --待ちを選択した時、通信エラーが表示される前に、前画面に戻ってしまうと、エラー時の音が消えない不具合を修正
//      Build 20170608
//      --注文数入力画面でオプションがダブって登録される不具合を修正
//      Build 20170609
//      --注文数入力画面で他の画面から戻ってきた時は選択状態を解除するよう修正
//      --注文数入力画面で一度そのメニューでオプションメニューを選択すると、数量を0にしてもオプションメニューが消えない不具合を修正
//      Build 20170614
//      --テーブル番号入力で誰も座っていないテーブルで尚且つ、サーバーからの返答が追加注文の時、E席、F席の情報が正常に表示されない不具合を修正
//      --お客様設定画面で引っ張って更新を追加
// Ver 1.0.3
//      Build 20170915
//      --認証機能を追加
//      --swift3.1対応
//      build 20170923
//      --NSURLRequest -> URLRequest
//      --戻るボタン長押し 機器シェイク時にメニューに戻る処理抜け
//      --デモモードのパスワード生成ロジックの修正

import UIKit

// 制御設定
// デモモード（初期値は0:本番　1:取込データでデモモード　2:デモデータでデモモード）
var demo_mode: Int = 0
var guide_mode: Int = 0
var first_disp_new: Int = 1
var first_disp_add: Int = 1
var hand_write_mode: Int = 1
var search_mode: Int = 0
var shop_code: Int = 1

// 表示設定
var disp_row_height: Int = 0
var furigana: Int = 1
var cost_disp: Int = 1
var text_size: Int = 0
var animation: Int = 1
var grid_disp: Int = 1

// サウンド設定
var tap_sound: Int = 1
var err_sound: Int = 100
var top_sound: Int = 200
var not_send_alert: (sound_interval:Int,sound_no:Int,interval:Int) = (3,100,0)
var data_not_send_alert: (sound_interval:Int,sound_no:Int,interval:Int) = (3,100,0)
var order_start2end_alert: (sound_interval:Int,sound_no:Int,interval:Int) = (10,100,0)

var tap_sound_file: (sound_file:String,file_type:String) = ("","")
var err_sound_file: (sound_file:String,file_type:String) = ("","")
var top_sound_file: (sound_file:String,file_type:String) = ("","")
var not_send_alert_file: (sound_file:String,file_type:String) = ("","")
var data_not_send_alert_file: (sound_file:String,file_type:String) = ("","")
var order_start2end_alert_file: (sound_file:String,file_type:String) = ("","")

// OS通知
var notification: Int = 1
var notification_centre: Int = 1
var notification_sound: Int = 1
var notification_badge: Int = 1
var notification_lock: Int = 1

// 店舗区分
var store_kbn: Int = 1

// マイナス数量入力可否（デフォルト：許可しない）
var is_minus_qty: Int = 0

// 注文取消し可否（0：常に許可（デフォルト）1：チェックアウト済みは不可 2：配膳済みは不可 3：調理済みは不可 4：常に不可）
var is_oder_cancel: Int = 0

// オーダー待ち機能可否（デフォルト：許可）
var is_order_wait: Int = 1

// 精算者振り替え機能可否（デフォルト：許可）
var is_payer_allocation: Int = 1

// 割引券自動入力可否（デフォルト：使用しない）
var is_ticket_autolink: Int = 0

// 時間帯区分を使用するか（デフォルト：使用する）
var is_timezone: Int = 1

// 単価区分変更可否（デフォルト：変更可）
var is_unit_price_kbn: Int = 1

// テーブルNO（初期値は0）
var globals_table_no: Int = 0

// 移動先テーブルNO（初期値は0）
var globals_exchange_table_no: Int = 0

// 選択席番号（初期値は−1）
var globals_select_seat_no = -1

// 選択メニューNO
var globals_select_menu_no:(menu_no:Int64,branch_no:Int,menu_name:String) = (0,0,"")

// 選択セレクトメニューNO
var globals_select_selectmenu_no:(select_menu_no:Int,branch_no:Int,select_menu_name:String) = (0,0,"")

// 選択メニューのカテゴリNO
var globals_select_category:(no1:Int,no2:Int) = (0,0)

// セレクトメニュー選択行
var globals_select_row = 0

// 新規・追加モード（1:新規 2:追加 3:取消 9:保留）
var globals_is_new: Int = 0

// 保留時の新規・追加モード（1:新規 2:追加）
var globals_is_new_wait: Int = 0

// ユーザー検索時の選択文字
var globals_select_kana = ""

// 手書き画面に渡すイメージ
var globals_image: UIImage? = UIImage()

// メニュー設定詳細に渡す情報
var globals_config_info: SectionItemData?
//var globals_config_info: (Int,Int,String,String)?

// 午後スタート時刻
var globals_pm_start_time = ""

// お客様情報取得用日付（yyyy/mm/dd）
var globals_today = ""

// テーブル行数(一画面に表示させる行数)
var table_row: [CGFloat] = [7.5,6.5,5.5]

// フォントサイズ(倍数)
var font_scale: [Float] = [1.0,1.5]

// 選択されたホルダNO
var globals_select_holder:(seat:String,holder:String) = ("","")

var globals_timezone = 0

// 再送信用NO
var globals_resend_id = 0
var globals_resend_no:(Int,Int) = (0,0)

// 人別単価区分
var globals_price_kbn:[Int] = []

// 画像更新フラグ
var isUpdate = false

// 選択されたセルの色
var select_cell_color = UIColor.clear

// 本番DB
let production_db = "iOrder2.db"
// デモDB
let demo_db = "iOrder2_demo.db"

// デモラベル
let demo_label:(String,String) = ("TRAINING","DEMO")

// IPアドレス
var ip_address:String?

// 店舗コード変更可否（デフォルトは不可）
var is_shop_code_change = false

// メニュー区分
let order_menu = 1
let order_select_menu = 2
let order_option_menu = 3

// iPhone(iPod) or iPad size Scale
let size_scale : CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 2.0 : 1.0

// UUID
var TerminalID:String?


// 認証確認時のエラーメッセージ
var authErrMessage:String = "認証されていません。\n設定画面から認証ボタンを\nタップしてください。"

// URL
//let urlString = "http://" + 192.168.8.223 + "/Iorder_WebService/WebService.asmx/"    // for test
var urlString = "http://" + ip_address! + "/Iorder_WebService/WebService.asmx/"

let aiueo:[[String]] = [["あ","い","う","え","お"],["か","き","く","け","こ"],["さ","し","す","せ","そ"],["た","ち","つ","て","と"],["な","に","ぬ","ね","の"],["は","ひ","ふ","へ","ほ"],["ま","み","む","め","も"],["や","","ゆ","","よ"],["ら","り","る","れ","ろ"],["わ","を","ん","",""],["","","","",""],["英数","英","数","",""]]

//let iOrder_titleBlueColor       = UIColor(red: 0.000, green: 0.400, blue: 0.800, alpha: 1.000)
let iOrder_titleBlueColor       = UIColor(red: 0.023, green: 0.180, blue: 0.513, alpha: 1.000)
let iOrder_blueColor            = UIColor(red: 0.000, green: 0.480, blue: 1.000, alpha: 1.000)
let iOrder_greenColor           = UIColor(red: 0.545, green: 0.678, blue: 0.000, alpha: 1.000)
let iOrder_bargainsYellowColor  = UIColor(red: 1.000, green: 0.667, blue: 0.000, alpha: 1.000)
let iOrder_orangeColor          = UIColor(red: 1.000, green: 0.498, blue: 0.000, alpha: 1.000)
let iOrder_redColor             = UIColor(red: 0.937, green: 0.678, blue: 0.000, alpha: 1.000)
let iOrder_noticeRedColor       = UIColor(red: 0.898, green: 0.188, blue: 0.239, alpha: 1.000)
let iOrder_lightBrownColor      = UIColor(red: 0.800, green: 0.631, blue: 0.498, alpha: 1.000)
let iOrder_blackColor           = UIColor(red: 0.282, green: 0.267, blue: 0.196, alpha: 1.000)
let iOrder_darkGrayColor        = UIColor(red: 0.482, green: 0.467, blue: 0.412, alpha: 1.000)
let iOrder_grayColor            = UIColor(red: 0.639, green: 0.627, blue: 0.565, alpha: 1.000)
let iOrder_borderColor          = UIColor(red: 0.859, green: 0.859, blue: 0.808, alpha: 1.000)
let iOrder_pink                 = UIColor(red: 1.000, green: 0.631, blue: 0.691, alpha: 1.000)
let iOrder_sakura               = UIColor(red: 0.992, green: 0.850, blue: 0.850, alpha: 1.000)
let iOrder_kana_back            = UIColor(red: 0.700, green: 0.700, blue: 0.700, alpha: 0.700)
let iOrder_subMenuColor         = UIColor(red: 0.862, green: 0.407, blue: 0.243, alpha: 1.000)
let iOrder_specialMenuColor     = UIColor(red: 0.062, green: 0.447, blue: 0.713, alpha: 1.000)
let iOrder_orderInputBackColor  = UIColor(red: 0.900, green: 0.900, blue: 0.921, alpha: 1.000)
let iOrder_badge_backColoer     = UIColor(red: 0.700, green: 0.200, blue: 0.200, alpha: 1.000)


// Status Barの高さを取得する.
let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height

// Navigetion Barの高さを取得する.
let NavHeight: CGFloat = 44.0

// Tool Barエリアの高さを取得する
let toolBarHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 140 : 70.0

// ボタンアイコンのサイズ
let iconSizeS: CGFloat = 20.0
let iconSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 50.0 : 25.0
let iconSizeL: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 80.0 : 40.0
let info_iconSizeL: CGFloat = 40.0
let sort_iconSize: CGFloat = 25.0

// TableViewHeaderの高さを取得する.
let tableViewHeaderHeight: CGFloat = 50.0

// テーブルNO最大桁数
let tableNoMaxLength: Int = 3

// タイマー
var order_timer = Timer()
var order_time = 0
var order_interval = 0

var order_resend_timer = Timer()
var order_resend_time = 0
var order_resend_interval = 0

var order_send_timer = Timer()
var order_send_time = 0
var order_send_interval = 0

// オーダー開始からオーダー送信までの最大作業時間（分）
//var order_elapsed_time: Int = order_start2end_alert.interval
var order_elapsed_time: Int = 10


// アラート表示フラグ
var is_alert_disp = false

// 設定画面
let configTitle:[String] = ["制御設定","表示設定","サウンド設定","OS通知","管理PC設定","ライセンス"]

// バージョン情報
let version: Any = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!


let build: Any = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!
let buil1: String! = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String

// セクションデータの型
struct SectionItemData {
    var item:String         // セクションアイテム名
    var itemName:String     // セクションアイテム名
    var cellMode:Int        // セルの種類（0:通常,1:スイッチ,2:セグメンテーションコントロール）
    var defaultNo:Int       // 初期値
    var defaultSt:String    // 初期値
    var icon:String         // アイコン名（http://fontawesome.io/icons/）fa-XXXXX (fa- 以下を指定してください。)何も指定しない場合はスマイルマークが表示されます。
    var isDisabled:Bool     // false:使用・true:未使用
    
    init(item: String,itemName: String, cellMode: Int, defaultNo: Int, defaultSt: String, icon:String,isDisabled:Bool){
        self.item = item
        self.itemName = itemName
        self.cellMode = cellMode
        self.defaultNo = defaultNo
        self.defaultSt = defaultSt
        self.icon = icon
        self.isDisabled = isDisabled
    }
}

let normalCell = 0
let switchCell = 1
let segmentCell = 2
let stepperCell = 3

var configtableData:[[SectionItemData]] =
    [[SectionItemData(item:"is_demo",itemName: "デモモード",cellMode: normalCell,defaultNo: 0,defaultSt: "",icon: "heart",isDisabled: false),
        SectionItemData(item:"is_guide",itemName: "ガイドモード",cellMode: switchCell,defaultNo: 0,defaultSt: "",icon:"info",isDisabled: true),
        SectionItemData(item:"new_order_category_DEFAULT",itemName: "初期表示カテゴリ（新規）",cellMode: normalCell,defaultNo: 1,defaultSt: "",icon:"plus-circle",isDisabled: false),
        SectionItemData(item:"add_order_category_DEFAULT",itemName: "初期表示カテゴリ（追加）",cellMode: normalCell,defaultNo: 1,defaultSt: "",icon:"plus",isDisabled: false),
        SectionItemData(item:"is_handwrite",itemName: "手書き入力での文字入力",cellMode: switchCell,defaultNo: 1,defaultSt: "",icon:"pencil-square-o",isDisabled: false),
        SectionItemData(item:"is_search",itemName: "商品検索を使用",cellMode: switchCell,defaultNo: 0,defaultSt: "",icon:"search",isDisabled: true),
        SectionItemData(item:"shop_code",itemName: "店舗コード",cellMode: normalCell,defaultNo: 1,defaultSt: "",icon:"home",isDisabled: false)
        ],
     
     [SectionItemData(item:"row_height",itemName: "表示行の高さ",cellMode: segmentCell,defaultNo: 0,defaultSt: "",icon:"arrows-v",isDisabled: false),
        SectionItemData(item:"is_kana_show",itemName: "フリガナ表示する",cellMode: switchCell,defaultNo: 1,defaultSt: "",icon:"font",isDisabled: false),
        SectionItemData(item:"is_price",itemName: "資格（料金）表示する",cellMode: switchCell,defaultNo: 1,defaultSt: "",icon:"jpy",isDisabled: false),
        SectionItemData(item:"is_holder_show_large",itemName: "顧客コード表示サイズ大",cellMode: switchCell,defaultNo: 0,defaultSt: "",icon:"text-width",isDisabled: false),
        SectionItemData(item:"is_animation",itemName: "画面アニメーションする",cellMode: switchCell,defaultNo: 1,defaultSt: "",icon:"film",isDisabled: false),
        SectionItemData(item:"is_grid",itemName: "オーダー画面グリッド表示",cellMode: switchCell,defaultNo: 1,defaultSt: "",icon:"th-large",isDisabled: false)
        ],
     
     [SectionItemData(item:"is_tapsound",itemName: "操作音",cellMode: normalCell,defaultNo: 1,defaultSt: "",icon:"music",isDisabled: false),
        SectionItemData(item:"is_errorbeep",itemName: "エラー音",cellMode: normalCell,defaultNo: 100,defaultSt: "",icon:"volume-up",isDisabled: false),
        SectionItemData(item:"topreturn_sound",itemName: "トップに戻る音",cellMode: normalCell,defaultNo: 0,defaultSt: "",icon:"volume-up",isDisabled: false),
        SectionItemData(item:"is_senddata",itemName: "データ送信失敗時の設定",cellMode: stepperCell,defaultNo: 3,defaultSt: "",icon:"volume-up",isDisabled: false),
        SectionItemData(item:"is_senderror",itemName: "データ未送信時の設定",cellMode: stepperCell,defaultNo: 3,defaultSt: "",icon:"volume-up",isDisabled: false),
        SectionItemData(item:"is_order_s2e",itemName: "オーダー開始から送信までの設定",cellMode: stepperCell,defaultNo: 10,defaultSt: "",icon:"volume-up",isDisabled: false)],
     
     [SectionItemData(item:"is_bbsinfo",itemName: "通知を許可",cellMode: switchCell,defaultNo: 1,defaultSt: "",icon:"exclamation",isDisabled: true),
        SectionItemData(item:"is_bbsinfocenter",itemName: "通知センターに表示",cellMode: switchCell,defaultNo: 1,defaultSt: "",icon:"tablet",isDisabled: true),
        SectionItemData(item:"is_bbssound",itemName: "サウンド",cellMode: switchCell,defaultNo: 1,defaultSt: "",icon:"music",isDisabled: true),
        SectionItemData(item:"is_bbsbadge",itemName: "Appアイコンバッジ",cellMode: switchCell,defaultNo: 1,defaultSt: "",icon:"",isDisabled: true),
        SectionItemData(item:"is_bbslock",itemName: "ロック画面",cellMode: switchCell,defaultNo: 1,defaultSt: "",icon:"lock",isDisabled: true)],
     
     [SectionItemData(item:"is_minus_qty",itemName: "マイナス数量入力",cellMode: normalCell,defaultNo: 0,defaultSt: "",icon:"desktop",isDisabled: true),
        SectionItemData(item:"is_oder_cancel",itemName: "注文取消し",cellMode: normalCell,defaultNo: 0,defaultSt: "",icon:"desktop",isDisabled: true),
        SectionItemData(item:"is_order_wait",itemName: "オーダー待ち機能",cellMode: normalCell,defaultNo: 1,defaultSt: "",icon:"desktop",isDisabled: true),
        SectionItemData(item:"is_payer_allocation",itemName: "精算者振り替え",cellMode: normalCell,defaultNo: 1,defaultSt: "",icon:"desktop",isDisabled: true),
        SectionItemData(item:"is_timezone",itemName: "時間帯区分を使用する",cellMode: normalCell,defaultNo: 1,defaultSt: "",icon:"desktop",isDisabled: true),
        SectionItemData(item:"is_unit_price_kbn",itemName: "単価区分を変更出来る",cellMode: normalCell,defaultNo: 1,defaultSt: "",icon:"desktop",isDisabled: true)],
     
     [SectionItemData(item:"license",itemName: "ライセンス情報",cellMode: 0,defaultNo: -1,defaultSt: "",icon:"file-text-o",isDisabled: false),
        SectionItemData(item:"version",itemName: "バージョン情報",cellMode: 0,defaultNo: -1,defaultSt: "\(version)",icon:"",isDisabled: false),
        SectionItemData(item:"build",itemName: "ビルド番号",cellMode: 0,defaultNo: -1,defaultSt: "\(build)",icon:"",isDisabled: false)]]



// 座席情報
struct seat_info {
    var seat_no:Int
    var seat_name:String
    var disp_position:Int
    var seat_kbn:Int
    
    init(seat_no:Int,seat_name:String,disp_position:Int,seat_kbn:Int){
        self.seat_no = seat_no
        self.seat_name = seat_name
        self.disp_position = disp_position
        self.seat_kbn = seat_kbn
    }
}
var seat:[seat_info] = []

var seat_to:[seat_info] = []

// 席に座った人の情報
struct takeSeatPlayer {
    var seat_no:Int         // シート番号
    var holder_no:String    // ホルダNO
    
    init(seat_no: Int, holder_no: String){
        self.seat_no = seat_no
        self.holder_no = holder_no
    }
}

var takeSeatPlayers:[takeSeatPlayer] = []
var takeSeatPlayers_temp:[takeSeatPlayer] = []

var takeSeatPlayers_to:[takeSeatPlayer] = []

// オーダーデータ
struct SectionData {
    var seat_no:Int         // シート番号
    var seat:String         // 座席名、支払座席名
    var No:String           // ホルダNo、メニュー表示の時はメニューNo
    var Name:String         // お客様名、メニュー表示の時はメニュー名
    
    init(seat_no:Int,seat: String, No: String, Name: String){
        self.seat_no = seat_no
        self.seat = seat
        self.No = No
        self.Name = Name
    }
}

// セルデータの型
struct CellData {
    var id:Int              // id
    var No:String           // ホルダNo
    var seat:String         // 配膳先座席名
    var MenuNo:String       // メニューNo
    var BranchNo:Int        // メニューNoの枝番
    var Name:String         // メニュー名、ホルダNo＋お客様名
    var Count:String        // 注文数
    var Hand:Bool           // 手書き有無
    var MenuType:Int        // メニュー種別（１：メニュー　２：サブメニュー　３：スペシャルメニュー）
    var payment_seat_no:Int // 支払い者座席NO

    init(id:Int,seat: String, No: String, Name: String, MenuNo: String, BranchNo:Int,Count: String, Hand: Bool, MenuType: Int,payment_seat_no:Int){
        self.id = id
        self.seat = seat
        self.No = No
        self.Name = Name
        self.MenuNo = MenuNo
        self.BranchNo = BranchNo
        self.Count = Count
        self.Hand = Hand
        self.MenuType = MenuType
        self.payment_seat_no = payment_seat_no
    }
}

struct SubMenuData {
    var id:Int
    var seat:String         // 配膳先シート名
    var No:String           // ホルダNo
    var MenuNo:String       // メニューNo
    var BranchNo:Int        // メニューNoの枝番
    var sub_menu_no:Int     // サブメニューNo
    var sub_menu_group:Int // サブメニューグループ
    var Name:String         // サブメニュー名

    init(id:Int,seat:String,No: String, MenuNo: String, BranchNo:Int,Name: String,sub_menu_no:Int,sub_menu_group:Int){
        self.id = id
        self.seat = seat
        self.MenuNo = MenuNo
        self.BranchNo = BranchNo
        self.No = No
        self.Name = Name
        self.sub_menu_no = sub_menu_no
        self.sub_menu_group = sub_menu_group
    }
}

struct SpecialMenuData {
    var id:Int
    var seat:String         // 配膳先シート名
    var No:String           // ホルダNo
    var MenuNo:String       // メニューNo
    var BranchNo:Int        // メニューNoの枝番
    var Name:String         // 特殊メニュー名
    var category:Int        // カテゴリNO

    init(id:Int,seat:String,No: String, MenuNo: String, BranchNo:Int,Name: String, category:Int){
        self.id = id
        self.seat = seat
        self.MenuNo = MenuNo
        self.BranchNo = BranchNo
        self.No = No
        self.Name = Name
        self.category = category
    }
}

var Section:[SectionData] = []
var MainMenu:[CellData] = []
var SubMenu:[SubMenuData] = []
var SpecialMenu:[SpecialMenuData] = []

// 選択されたメニューのカテゴリNO
struct select_menu_category {
    var id:Int
    var category1:Int
    var category2:Int
    
    init(id:Int,category1:Int,category2:Int){
        self.id = id
        self.category1 = category1
        self.category2 = category2
    }
}

var select_menu_categories:[select_menu_category] = []

// オーダー数量入力から手書き画面に移動時の情報
struct selectMenuCountData {
    var seat:String         // 配膳先シート名
    var No:String           // ホルダNo
    var MenuNo:String       // メニューNo
    var BranchNo:Int        // メニューNoの枝番
    var MenuCount:Int       // メニューオーダー数
    var HandWrite:UIImage?  // 手書きイメージ
    
    init(seat:String,No: String, MenuNo: String, BranchNo:Int,MenuCount: Int, HandWrite: UIImage){
        self.seat = seat
        self.MenuNo = MenuNo
        self.BranchNo = BranchNo
        self.No = No
        self.MenuCount = MenuCount
        self.HandWrite = HandWrite
    }
}

var selectMenuCount:[selectMenuCountData] = []
var selectSP:[selectMenuCountData] = []

// オーダー確認画面で選択されたメニューのID番号
var selectedID:Int = 0

// 選択された特殊メニュー
struct selectSPmenu {
    var seat:String         // 配膳先シート名
    var holderNo:String     // ホルダ番号
    var menuNo:Int64        // メニューNo
    var BranchNo:Int        // メニューNoの枝番
    var category:Int        // カテゴリNO
    var spMenuNo:Int        // 特殊メニューNo
    var spMenuName:String   // 特殊メニュー名
    
    init(seat:String,holderNo:String,menuNo:Int64,BranchNo:Int,spMenuNo:Int, spMenuName:String,category:Int){
        self.seat = seat
        self.holderNo = holderNo
        self.menuNo = menuNo
        self.BranchNo = BranchNo
        self.spMenuNo = spMenuNo
        self.spMenuName = spMenuName
        self.category = category
    }
}
var selectSPmenus:[selectSPmenu] = []

struct DecisionMainMenuData {
    var No:String           // ホルダNo
    var seat:String         // 座席名、支払座席名
    var MenuNo:String       // メニューNo
    var Count:String        // 注文数
    
    init(seat: String, No: String, MenuNo: String, Count: String){
        self.seat = seat
        self.No = No
        self.MenuNo = MenuNo
        self.Count = Count
    }
}

struct DecisionSubMenuData {
    var MenuNo:String       // メニューNo
    var subMenuNo:Int       // サブメニュー番号
    var subMenuGroup:Int    // サブメニューグループ番号
    var Name:String         // サブメニュー名
    
    init(MenuNo: String,subMenuNo:Int, subMenuGroup:Int,Name: String){
        self.MenuNo = MenuNo
        self.subMenuNo = subMenuNo
        self.subMenuGroup = subMenuGroup
        self.Name = Name
    }
}

struct DecisionSpecialMenuData {
    var No:String           // ホルダNo
    var MenuNo:String       // メニューNo
    var Name:String         // 特殊メニュー名
    
    init(No: String, MenuNo: String, Name: String){
        self.MenuNo = MenuNo
        self.No = No
        self.Name = Name
    }
}

// オーダー数量入力から手書き画面に移動時の情報
struct DecisionHandWriteData {
    var No:String           // ホルダNo
    var MenuNo:String       // メニューNo
    var HandWrite:UIImage?  // 手書きイメージ
    
    init(No: String, MenuNo: String, HandWrite: UIImage){
        self.MenuNo = MenuNo
        self.No = No
        self.HandWrite = HandWrite
    }
}

var DecisionMainMenu:[DecisionMainMenuData] = []
var DecisionSubMenu:[DecisionSubMenuData] = []
var DecisionSpecialMenu:[DecisionSpecialMenuData] = []
var DecisionHandWrite:[DecisionHandWriteData] = []

// 取消用セルデータの型
struct cancel_cellData {
    var id:Int              // ID
    var No:String           // ホルダNo
    var seat:String         // 座席名、支払座席名
    var serve_seat:String   //
    var MenuNo:String       // メニューNo
    var BranchNo:Int        // メニューNo枝番
    var timezone_kbn:Int    // 時間帯区分
    var Name:String         // メニュー名、ホルダNo＋お客様名
    var Count:String        // 注文数
    var Hand:Bool           // 手書き有無
    var MenuType:Int        // メニュー種別（１：メニュー　２：サブメニュー　３：スペシャルメニュー）
    var time:String         // 経過時間
    var payment_customer_no:String
    var payment_seat_no:Int
    var Slip_NO:String      // 伝票NO
    var order_no:Int        // オーダーNO
    var order_branch:Int    // オーダーNO枝番
    
    init(id: Int,seat: String,serve_seat:String, No: String, Name: String, MenuNo: String,BranchNo:Int, timezone_kbn:Int,Count: String, Hand: Bool, MenuType: Int, time: String,payment_customer_no:String,payment_seat_no:Int,Slip_NO:String,order_no:Int,order_branch:Int){
        self.id = id
        self.seat = seat
        self.serve_seat = serve_seat
        self.No = No
        self.Name = Name
        self.MenuNo = MenuNo
        self.BranchNo = BranchNo
        self.timezone_kbn = timezone_kbn
        self.Count = Count
        self.Hand = Hand
        self.MenuType = MenuType
        self.time = time
        self.payment_customer_no = payment_customer_no
        self.payment_seat_no = payment_seat_no
        self.Slip_NO = Slip_NO
        self.order_no = order_no
        self.order_branch = order_branch
    }
}

var cancel_Disp:[[cancel_cellData]] = []

// MARK: - テーブル設定

// 従業員情報
let staffs_info     = "CREATE TABLE IF NOT EXISTS staffs_info (staff_no INTEGER PRIMARY KEY, staff_name_kana TEXT, staff_name_kanji TEXT, created TEXT, modified TEXT);"

//　メニューカテゴリ情報
let categorys_master = "CREATE TABLE IF NOT EXISTS categorys_master ( facility_cd INTEGER, store_cd INTEGER, timezone_kbn INTEGER, category_cd1 INTEGER, category_cd2 INTEGER, category_nm TEXT, category_disp_no INTEGER, background_color_r REAL, background_color_g REAL, background_color_b REAL,  created TEXT, modified TEXT, PRIMARY KEY(facility_cd, store_cd,timezone_kbn, category_cd1, category_cd2));"

// メインメニュー情報
let menus_master    = "CREATE TABLE IF NOT EXISTS menus_master (item_no INTEGER, item_name TEXT, item_short_name TEXT, category_no1 INTEGER, category_no2 INTEGER, shop_code INTEGER, item_info TEXT,item_info2 TEXT,sort_no INTEGER, background_color_r REAL, background_color_g REAL, background_color_b REAL, created TEXT, modified TEXT,PRIMARY KEY(item_no,category_no1,category_no2,sort_no));"

// セレクトメニュー情報
let sub_menus_master    = "CREATE TABLE IF NOT EXISTS sub_menus_master (item_name TEXT, item_short_name TEXT, menu_no INTEGER, sub_menu_group INTEGER, sub_menu_no INTEGER, is_default INTEGER, price1 INTEGER, price2 INTEGER, price3 INTEGER, item_info TEXT, created TEXT, modified TEXT, PRIMARY KEY(menu_no, sub_menu_group, sub_menu_no) );"

// オプションメニュー情報
let special_menus_master    = "CREATE TABLE IF NOT EXISTS special_menus_master (item_no INTEGER , item_name TEXT, item_short_name TEXT, category_no INTEGER, shop_code INTEGER, price1 INTEGER, price2 INTEGER, price3 INTEGER, item_info TEXT, created TEXT, modified TEXT, PRIMARY KEY(item_no,category_no));"

// 残数ありメニュー情報
let items_remaining = "CREATE TABLE IF NOT EXISTS items_remaining (item_no INTEGER PRIMARY KEY, remaining_count INTEGER, created TEXT, modified TEXT);"

// 来場者情報
let players_state   = "CREATE TABLE IF NOT EXISTS players_state (holder_no INTEGER, member_no TEXT, player_name_kana TEXT, player_name_kanji TEXT, round_day TEXT, is_payoff INTEGER, group_id TEXT, supplemental_message TEXT, start_time TEXT, price_division INTEGER, created TEXT, modified TEXT,PRIMARY KEY(holder_no,round_day));"

// 来場者情報
let players         = "CREATE TABLE IF NOT EXISTS players (shop_code INTEGER DEFAULT 0,member_no TEXT, member_category INTEGER, group_no INTEGER, player_name_kana TEXT, player_name_kanji TEXT, birthday TEXT, require_nm TEXT,sex INTEGER, message1 TEXT, message2 TEXT, message3 TEXT, price_tanka INTEGER, status INTEGER ,pm_start_time TEXT,created TEXT, modified TEXT,PRIMARY KEY(shop_code,member_no));"

let players_item_master = "CREATE TABLE IF NOT EXISTS players_item_master (item_id INTEGER PRIMARY KEY, item_name TEXT, created TEXT, modified TEXT);"

let players_item_comment = "CREATE TABLE IF NOT EXISTS players_item_comment (member_no TEXT, item_id INTEGER, item_name TEXT, comment TEXT, is_priority INTEGER, created TEXT, modified TEXT,PRIMARY KEY(member_no,item_id));"

let players_bottle  = "CREATE TABLE IF NOT EXISTS players_bottle (member_no TEXT, sales_date TEXT, keep_date TEXT, bottle_name TEXT, expire_date TEXT, memo TEXT, created TEXT, modified TEXT);"

// コース情報
let course_master   = "CREATE TABLE IF NOT EXISTS course_master (course_no INTEGER PRIMARY KEY, course_name TEXT, created TEXT, modified TEXT);"

// 設定情報
let app_config      = "CREATE TABLE IF NOT EXISTS app_config (is_timezone INTEGER DEFAULT 1,topreturn_sound INTEGER DEFAULT 200,is_Eseat INTEGER DEFAULT 0,row_height INTEGER DEFAULT 0,is_kana_show INTEGER DEFAULT 1,is_name_show INTEGER DEFAULT 1,is_holder_show_large INTEGER DEFAULT 0,new_order_category_DEFAULT INTEGER DEFAULT 1,add_order_category_DEFAULT INTEGER DEFAULT 1,special_order_category_DEFAULT INTEGER DEFAULT 1,is_animation INTEGER DEFAULT 1,is_demo INTEGER DEFAULT 0,row_height_user INTEGER DEFAULT 0,shop_code INTEGER DEFAULT 1,seat_no INTEGER DEFAULT 1,is_guide INTEGER DEFAULT 0,is_handwrite INTEGER DEFAULT 1,is_search INTEGER DEFAULT 0,is_price INTEGER DEFAULT 1,is_grid INTEGER DEFAULT 1,is_tapsound INTEGER DEFAULT 0,is_errorbeep INTEGER DEFAULT 100,is_senddata INTEGER DEFAULT 3,is_senddata_sound INTEGER DEFAULT 100,is_senddata_interval INTEGER DEFAULT 0, is_senderror INTEGER DEFAULT 3,is_senderror_sound INTEGER DEFAULT 100,is_senderror_interval INTEGER DEFAULT 0,is_order_s2e INTEGER DEFAULT 10,is_order_s2e_sound INTEGER DEFAULT 100,is_order_s2e_interval INTEGER DEFAULT 0, is_bbsinfo INTEGER DEFAULT 1,is_bbsinfocenter INTEGER DEFAULT 1,is_bbssound INTEGER DEFAULT 1,is_bbsbadge INTEGER DEFAULT 1,is_bbslock INTEGER DEFAULT 1, created TEXT, modified TEXT);"

let app_config_rowheight = "CREATE TABLE IF NOT EXISTS app_config_rowheight (disp_no INTEGER , disp_name TEXT, height_pixel INTEGER, created TEXT, modified TEXT);"
let app_config_categoryfirst = "CREATE TABLE IF NOT EXISTS app_config_categoryfirst (disp_no INTEGER , disp_name TEXT, created TEXT, modified TEXT);"
let app_config_sound = "CREATE TABLE IF NOT EXISTS app_config_sound (sound_no INTEGER , disp_name TEXT, sound_file TEXT, file_type TEXT,created TEXT, modified TEXT);"
let app_config_seatname = "CREATE TABLE IF NOT EXISTS app_config_seatname (group_no INTEGER , seat_no INTEGER, display_order INTEGER, display_name TEXT, created TEXT, modified TEXT,PRIMARY KEY(group_no,seat_no,display_order));"

// オーダー情報
let iorder = "CREATE TABLE IF NOT EXISTS iorder(facility_cd INTEGER, store_cd INTEGER, order_no INTEGER,entry_date TEXT, table_no INTEGER, status_kbn INTEGER, pm_start_time TEXT,Timezone_KBN INTEGER,Employee_CD INTEGER, SendTime TEXT,TerminalID TEXT,created TEXT, modified TEXT, PRIMARY KEY(facility_cd,store_cd,order_no));"

// オーダー詳細情報
let iorder_detail = "CREATE TABLE IF NOT EXISTS iorder_detail(facility_cd INTEGER,store_cd INTEGER,order_no INTEGER,branch_no INTEGER,detail_kbn INTEGER,order_kbn INTEGER,seat_no INTEGER,category_cd1 INTEGER,category_cd2 INTEGER,menu_cd INTEGER,menu_name TEXT,menu_branch INTEGER,parent_menu_cd INTEGER,hand_image BLOB,qty INTEGER,unit_price_kbn INTEGER,serve_customer_no INTEGER,payment_customer_no INTEGER,payment_customer_seat_no INTEGER,Selling_Price INTEGER,created TEXT,modified TEXT,PRIMARY KEY(facility_cd, store_cd, order_no,  branch_no));"

let timezone        = "CREATE TABLE IF NOT EXISTS timezone(id INTEGER PRIMARY KEY,timezone TEXT, icon_Name TEXT,rgb TEXT,icon_image BLOB,created TEXT, modified TEXT);"
let staffs_now      = "CREATE TABLE IF NOT EXISTS staffs_now ( staff_no INTEGER PRIMARY KEY, staff_name_kana TEXT, staff_name_kanji TEXT, created TEXT, modified TEXT);"

// テーブル番号テーブル
let tableNo         = "CREATE TABLE IF NOT EXISTS table_no ( table_no INTEGER PRIMARY KEY, table_name TEXT, seat_count INTEGER, section INTEGER, created TEXT, modified TEXT);"
let new_or_edit     = "CREATE TABLE IF NOT EXISTS new_or_edit ( is_new INTEGER , table_no INTEGER, created TEXT, modified TEXT);"
let seat_holder     = "CREATE TABLE IF NOT EXISTS seat_holder ( seat_no INTEGER , holder_no TEXT);"

// 手書き情報一時保存
let hand_image      = "CREATE TABLE IF NOT EXISTS hand_image (seat TEXT,holder_no TEXT, order_no INTEGER, branch_no INTEGER,order_count INTEGER, hand_image BLOB, PRIMARY KEY(seat,holder_no,order_no,branch_no))";

// 席番号テーブル
let seat_master     = "CREATE TABLE IF NOT EXISTS seat_master (table_no INTEGER, seat_no INTEGER, seat_name TEXT, disp_position INTEGER, seat_kbn INTEGER, holder_no TEXT,order_kbn INTEGER,holder_no9 TEXT,order_kbn9 INTEGER,created TEXT, modified TEXT, PRIMARY KEY(table_no,seat_no));"

let UNIT_PRICE_KBN = "CREATE TABLE IF NOT EXISTS unit_price_kbn (price_kbn_no INTEGER, price_kbn_name TEXT, created TEXT, modified TEXT);"

let GROUP_INFO      = "CREATE TABLE IF NOT EXISTS gropu_info(group_no INTEGER PRIMARY KEY,pm_start_time TEXT, created TEXT, modified TEXT );"

let resend          = "CREATE TABLE IF NOT EXISTS resending(id INTEGER PRIMARY KEY AUTOINCREMENT, resend_kbn INTEGER, resend_no INTEGER, resend_count INTEGER, sendtime TEXT);"

let disp_mode       = "CREATE TABLE IF NOT EXISTS disp_mode(staff_no INTEGER PRIMARY KEY ,disp_mode INTEGER);"

// セレクトメニュー、オプションメニューの単価情報
let menus_price     = "CREATE TABLE IF NOT EXISTS menus_price(facility_cd INTEGER,store_cd INTEGER,order_kbn INTEGER,menu_cd INTEGER,parent_menu_cd INTEGER,category_no INTEGER,unit_price_kbn INTEGER,price INTEGER,tax_included INTEGER ,created TEXT, modified TEXT);"

let once_a_day      = "CREATE TABLE IF NOT EXISTS once_a_day(day TEXT,version REAL);"

let pc_cinfig       = "CREATE TABLE IF NOT EXISTS pc_config(setup_key TEXT,value INTEGER)"

// 端末・デモ認証用 ooishi
let demo_certification       = "CREATE TABLE IF NOT EXISTS demo_certification(certification_flag INTEGER DEFAULT 0,created TEXT, modified TEXT );"

let server_certification       = "CREATE TABLE IF NOT EXISTS server_certification(certification_flag INTEGER DEFAULT 0,message TEXT, created TEXT, modified TEXT );"


//let config          = "CREATE TABLE IF NOT EXISTS config(section INTEGER,);"

let sql = [staffs_info,categorys_master,menus_master,sub_menus_master,special_menus_master,items_remaining,players_state,players,players_item_master,players_item_comment,players_bottle,course_master,app_config,app_config_rowheight,app_config_categoryfirst,app_config_sound,app_config_seatname,iorder,iorder_detail,timezone,staffs_now,tableNo,new_or_edit,seat_holder,hand_image,seat_master,UNIT_PRICE_KBN,GROUP_INFO,resend,disp_mode,once_a_day,menus_price,pc_cinfig,demo_certification,server_certification]

let sql_demo = [staffs_info,categorys_master,menus_master,sub_menus_master,special_menus_master,items_remaining,players_state,players,players_item_master,players_item_comment,players_bottle,course_master,app_config,app_config_rowheight,app_config_categoryfirst,app_config_sound,app_config_seatname,iorder,iorder_detail,timezone,staffs_now,tableNo,new_or_edit,seat_holder,hand_image,seat_master,UNIT_PRICE_KBN,GROUP_INFO,resend,disp_mode,once_a_day,menus_price,pc_cinfig,demo_certification,server_certification]

let demo_csv:[[String]] = [
    ["staffs_info","csv","INSERT INTO staffs_info (staff_no, staff_name_kana, staff_name_kanji, created, modified) VALUES (?, ?, ?, ?, ?);"],
    ["timezone","csv","INSERT INTO timezone (id, timezone, icon_Name, rgb, icon_image, created, modified) VALUES (?, ?, ?, ?, ?, ?, ?);"],
    ["table_no","csv","INSERT INTO table_no (table_no, table_name, seat_count, section , created, modified) VALUES (?, ?, ?, ?, ?, ?);"],
    ["players","csv","INSERT INTO players (shop_code,member_no ,member_category,group_no,player_name_kana ,player_name_kanji ,birthday ,require_nm,sex,message1,message2 ,message3,price_tanka,status,pm_start_time,created ,modified) VALUES (?,?,?, ?, ?, ?,?,?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"],
    ["categorys_master","csv","INSERT INTO categorys_master (facility_cd, store_cd, timezone_kbn, category_cd1, category_cd2, category_nm, background_color_r, background_color_g, background_color_b, created, modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"],
    ["menus_master","csv","INSERT INTO menus_master (item_no ,item_name,item_short_name,category_no1,category_no2,shop_code,item_info ,item_info2 ,sort_no,background_color_r,background_color_g,background_color_b,created ,modified) VALUES (?,?,?,?,?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"],
    ["special_menus_master","csv","INSERT INTO special_menus_master (item_no ,item_name,item_short_name,category_no,shop_code,price1,price2,price3,item_info ,created ,modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"],
    ["sub_menus_master","csv","INSERT INTO sub_menus_master (item_name,item_short_name,menu_no,sub_menu_group,sub_menu_no,is_default,price1,price2,price3,item_info ,created ,modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"],
    ["config_sound","csv","INSERT INTO app_config_sound (sound_no , disp_name, sound_file, file_type, created, modified) VALUES(?,?,?,?,?,?);"],
    ["seat_master","csv","INSERT INTO seat_master (table_no,seat_no,seat_name,disp_position,seat_kbn,created ,modified) VALUES(?,?,?,?,?,?,?);"],
    ["unit_price_kbn","csv", "INSERT INTO unit_price_kbn (price_kbn_no, price_kbn_name, created, modified) VALUES(?,?,?,?);"],
    ["menus_price","csv", "INSERT INTO menus_price (facility_cd,store_cd,order_kbn,menu_cd,parent_menu_cd,category_no,unit_price_kbn,price,tax_included,created, modified) VALUES(?,?,?,?,?,?,?,?,?,?,?);"],
]

let demo_Delete:[String] = ["DELETE FROM staffs_info;","DELETE FROM timezone;","DELETE FROM table_no;","DELETE FROM players ;","DELETE FROM categorys_master;","DELETE FROM menus_master;","DELETE FROM special_menus_master;","DELETE FROM sub_menus_master;","DELETE FROM app_config_sound;","DELETE FROM seat_master;","DELETE FROM unit_price_kbn;","DELETE FROM menus_price"]

let staffs_now_insert = "INSERT INTO staffs_now (staff_no, staff_name_kana, staff_name_kanji, created, modified) VALUES (?, ?, ?, ?, ?);"
let new_or_edit_insert = "INSERT INTO new_or_edit (is_new, table_no, created, modified) VALUES (?, ?, ?, ?);"
let players_insert = "INSERT INTO players (shop_code,member_no ,member_category,group_no,player_name_kana ,player_name_kanji ,birthday ,sex,message1,message2,message3 ,price_tanka,status,created ,modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"

let INSERT_OR_REPLACE_INTO_iOrder = "INSERT OR REPLACE INTO iOrder (facility_cd, store_cd, order_no ,entry_date, table_no, status_kbn, pm_start_time,Timezone_KBN, Employee_CD,SendTime,TerminalID,created, modified) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?);"

let INSERT_INTO_iorder_detail = "INSERT INTO iorder_detail (facility_cd,store_cd,order_no,branch_no,detail_kbn,order_kbn,seat_no,category_cd1,category_cd2,menu_cd,menu_name,menu_branch,parent_menu_cd,hand_image,qty,unit_price_kbn,serve_customer_no,payment_customer_no,payment_customer_seat_no,Selling_Price,created,modified) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);"

let SELECT_PLAYERS = "SELECT * FROM players WHERE member_no = ? AND shop_code IN (0,?)  AND created LIKE ? ORDER BY cast(member_no as integer)"

//let SELECT_PLAYERS_DEMO = "SELECT * FROM players WHERE member_no = ? AND shop_code IN (0,?) ORDER BY cast(member_no as integer)"
