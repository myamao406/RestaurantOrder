//
//  checkServerAuth.swift
//  iOrder2
//
//  Created by iOrder on 2017/09/04.
//  Copyright © 2017年 CIS. All rights reserved.
//

import Foundation
import FMDB
class checkServerAuth{
    init(){
    }
    
    fileprivate func getDBPath() -> String{
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        let _path = (paths[0] as NSString).appendingPathComponent(production_db)
        return _path
    }
    
    func checkCertification() -> intptr_t {
        
        var certification_flag = 0
        let db_usedb = FMDatabase(path: getDBPath())
        // データベースをオープン
        db_usedb.open()
        
        // 認証済みフラグ存在確認
        let sql1 = "SELECT count(*) FROM server_certification;"
        let results1 = db_usedb.executeQuery(sql1, withArgumentsIn: [])
        
        var data_count = 0
        while (results1?.next())! {
            data_count = Int((results1?.int(forColumnIndex:0))!)
        }
        print("data_count")
        print(data_count)
        db_usedb.close()
        
        // 認証済みフラグが無い場合、インサート
        if data_count == 0{
            db_usedb.open()
            
            let sql = "INSERT INTO server_certification (certification_flag, message, created, modified) VALUES (?, ?, ?, ?);"
            db_usedb.beginTransaction()
            var argumentArray:Array<Any> = []
            argumentArray.append("0")
            
            
            print("インサートメッセージ")
            print(authErrMessage)
            argumentArray.append(authErrMessage)
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
            let success = db_usedb.executeUpdate(sql, withArgumentsIn: argumentArray)
            // INSERT文の実行に成功した場合
            if success {
                db_usedb.commit()
            }
            db_usedb.close()
            certification_flag = 0
            
        }else{ // 認証済みフラグがある場合、取得する
            db_usedb.open()
            
            // 認証フラグ取得
            let sql_menu = "SELECT certification_flag,message FROM server_certification;"
            let results = db_usedb.executeQuery(sql_menu, withArgumentsIn: [])
            
            while (results?.next())! {
                certification_flag = Int((results?.int(forColumnIndex:0))!)
                authErrMessage = (results?.string(forColumnIndex:1))!
            }
            print(certification_flag)
            db_usedb.close()
        }
        return certification_flag
    }
    
    //　Certification_flagを1にする
    func setCertification() {
        let db_usedb = FMDatabase(path: getDBPath())
        db_usedb.open()
        db_usedb.beginTransaction()
        let sql:String = "UPDATE server_certification SET certification_flag = 1,message = '" + authErrMessage + "';"
        let _ = db_usedb.executeUpdate(sql, withArgumentsIn: [])
        db_usedb.commit()
        db_usedb.close()
    }

    //　Certification_flagを0にする
    func setNoCertification() {
        let db_usedb = FMDatabase(path: getDBPath())
        db_usedb.open()
        db_usedb.beginTransaction()
        let sql:String = "UPDATE server_certification SET certification_flag = 0,message = '" + authErrMessage + "';"
        let _ = db_usedb.executeUpdate(sql, withArgumentsIn: [])
        db_usedb.commit()
        db_usedb.close()
    }

    //　Certification_flagを0にする
    func setNoCertificationNotSaveMessage() {
        let db_usedb = FMDatabase(path: getDBPath())
        db_usedb.open()
        db_usedb.beginTransaction()
        let sql:String = "UPDATE server_certification SET certification_flag = 0;"
        let _ = db_usedb.executeUpdate(sql, withArgumentsIn: [])
        db_usedb.commit()
        db_usedb.close()
    }

    //　Certification_flagを2にする(認証待ち)
    func setReserve() {
        print("setReserveのメッセージ")
        print(authErrMessage)
        let db_usedb = FMDatabase(path: getDBPath())
        db_usedb.open()
        db_usedb.beginTransaction()
        let sql:String = "UPDATE server_certification SET certification_flag = 2,message = '" + authErrMessage + "';"
        let _ = db_usedb.executeUpdate(sql, withArgumentsIn: [])
        db_usedb.commit()
        db_usedb.close()
    }
    
    
    
}
