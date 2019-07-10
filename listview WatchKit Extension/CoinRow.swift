//
//  CoinRow.swift
//  listview WatchKit Extension
//
//  Created by HeejaeKim on 10/07/2019.
//  Copyright © 2019 HeejaeKim. All rights reserved.
//

import WatchKit

class CoinRow: NSObject {
    @IBOutlet var status: WKInterfaceImage!
    @IBOutlet var name: WKInterfaceLabel!
    @IBOutlet var price: WKInterfaceLabel!
    @IBOutlet var changeRate: WKInterfaceLabel!
}
