//
//  ContentManager.swift
//  TbSWAMPSwiftSample
//
//  Created by Ueda on 2019/05/11.
//  Copyright © 2019 3bitter.com. All rights reserved.
//

import UIKit

// 正常判定用に予め割り振られたmajor番号 */
let assignedMajorValuesForType1Dynamic = [1001, 1002, 1003]

class ContentManager: NSObject {
    var currentMappedContents: [OurContent] = []
    
    static let sharedManager: ContentManager = ContentManager()
    
    private override init() {
        
    }
    
    // ビーコンに関係ない標準コンテンツ
    func defeaultContents() -> Array<OurContent> {
        let justAnotherContent1 :OurContent = OurContent(titled:"標準コンテンツ 1", contentDescription: "description 1", icon: UIImage(named:"normal_content1")!)
        
        let justAnotherContent2 :OurContent = OurContent(titled:"標準コンテンツ 2", contentDescription: "description 2", icon: UIImage(named:"normal_content2")!)
     
        return [justAnotherContent1, justAnotherContent2]
    }
    
    // 3B Dynamic Beacon領域に割り当てたコンテンツを取得する
    func getCotnentForDynamicBeacons(beacons:Array<CLBeacon>) -> NSInteger {
        
        for beacon in beacons {
            if let content = dummySearchWithDummyMap(targetBeacon: beacon) {    currentMappedContents.append(content)
            }
        }
        return currentMappedContents.count
    }
    
    // サーバや事前準備のデータストアから、ビーコン情報に合わせて取得
    // ※ ダミーのコンテンツ取得メソッド
    func dummySearchWithDummyMap(targetBeacon: CLBeacon) -> OurContent? {
        // 割り振られていないビーコンであるので対象外
        let majorValue: Int = targetBeacon.major.intValue
        if (!assignedMajorValuesForType1Dynamic.contains(majorValue)) {
            return nil
        }
        // Build dummy contents per major
        let contentTitile1 = "領域タイプ1限定コンテンツ".appendingFormat("(%ld)", majorValue)
        let mappedContent1 = OurContent(titled: contentTitile1, contentDescription: "Server side mapping may be better", icon: UIImage(named:"special_content1")!)
        
         let contentTitile2 = "領域タイプ2限定コンテンツ".appendingFormat("(%ld)", majorValue)
         let mappedContent2 = OurContent(titled: contentTitile2, contentDescription: "Assign another content for another major", icon: UIImage(named:"special_content2")!)
        
         let contentTitile3 = "領域タイプ3限定コンテンツ".appendingFormat("(%ld)", majorValue)
        let mappedContent3 = OurContent(titled: contentTitile3, contentDescription: "Assigned for major(index 2)", icon:UIImage(named:"special_content3")!)
        
        switch (majorValue % 2) {
        case 0:
            return mappedContent1
        case 1:
            return mappedContent2
        default:
            return mappedContent3
        }
    }
}
