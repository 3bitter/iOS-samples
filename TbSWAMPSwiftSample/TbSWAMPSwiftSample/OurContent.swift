//
//  OurContent.swift
//  TbSWAMPSwiftSample
//
//  Created by Ueda on 2019/05/11.
//  Copyright © 2019 3bitter.com. All rights reserved.
//

import UIKit

class OurContent: NSObject {
    var title: String?
    var contentDescription:String?
    var icon:UIImage?

    init(titled title: String, contentDescription:String,
         icon: UIImage) {
        self.title = title
        self.contentDescription = contentDescription
        self.icon = icon
    }
}
