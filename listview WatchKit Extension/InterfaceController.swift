//
//  InterfaceController.swift
//  listview WatchKit Extension
//
//  Created by HeejaeKim on 10/07/2019.
//  Copyright © 2019 HeejaeKim. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    let REQUEST_LIST_URL: String = "https://api.upbit.com/v1/market/all"
    let REQUEST_ITEM_URL: String = "https://api.upbit.com/v1/candles/days?market="
    let REQUEST_INTERVAL: Double = 0.2
    let CELL_HEIGHT: CGFloat = 50.0

    @IBOutlet var tableView: WKInterfaceTable!

    var names: Dictionary<String, String> = [:]
    var items: [Coin] = []
    var requestCount = 0

    struct Coin {
        var name: String
        var changeRate: Float
        var price: Float
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        request(url: REQUEST_LIST_URL, completion: onReceiveList)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func onReceiveList(data: String?) {
        if let jsonArray = toJson(str: data) {
            var delay = 0.0
            for json in jsonArray {
                let unit = json["market"] as! String
                if unit.contains("KRW") {
                    names.updateValue(json["english_name"] as! String, forKey: unit)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                        self.requestUnit(unit: unit)
                    })
                    delay += REQUEST_INTERVAL
                    requestCount += 1
                }
            }
        }
    }

    func requestUnit(unit: String) {
        request(url: REQUEST_ITEM_URL + unit, completion: onReceiveData)
    }

    func onReceiveData(data: String?) {
        if let jsonArray = toJson(str: data) {
            for json in jsonArray {
                createItem(json: json)
            }
        }

        DispatchQueue.main.async {
            self.updateTable()
        }
    }

    func updateTable() {
        tableView.setNumberOfRows(items.count, withRowType: "CoinRow")
        var i: Int = 0
        for coin in items {
            if let cell = tableView.rowController(at: i) as? CoinRow {
                if let name = names[coin.name] {
                    cell.name.setText(name)
                } else {
                    cell.name.setText(coin.name)
                }

                cell.changeRate.setText("   " + String(round(coin.changeRate * 10000) / 100) + "%")
                if coin.changeRate > 0.0 {
                    cell.price.setTextColor(UIColor.red)
                    cell.changeRate.setTextColor(UIColor.red)
                    cell.status.setImageNamed("up")
                } else if coin.changeRate < 0.0 {
                    cell.price.setTextColor(UIColor.blue)
                    cell.changeRate.setTextColor(UIColor.blue)
                    cell.status.setImageNamed("down")
                } else {
                    cell.price.setTextColor(UIColor.black)
                    cell.changeRate.setTextColor(UIColor.black)
                    cell.status.setImageNamed("equal")
                }

                let formatter = NumberFormatter()
                formatter.usesGroupingSeparator = true
                formatter.numberStyle = .currencyAccounting
                formatter.locale = Locale(identifier: "kr_KR")

                let price = coin.price
                if (price >= 100.0) {
                    cell.price.setText(formatter.string(from: NSNumber(value: price)))
                } else {
                    cell.price.setText(formatter.string(from: NSNumber(value: price)))
                }
            }
            i += 1
        }
    }

    func createItem(json: Dictionary<String,Any>) {
        if let name = json["market"] as? String,
            let price = (json["trade_price"] as? NSNumber)?.floatValue,
            let changeRate = (json["change_rate"] as? NSNumber)?.floatValue {
            items.append(Coin(name: name, changeRate: changeRate, price: price))
        }
    }

    func request(url: String, completion: @escaping (_: String?) -> Void) {
        var requester = URLRequest(url: URL(string: url)!)
        requester.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
        requester.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: requester) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                completion(nil)
                return
            }
            if let response = String(data: data, encoding: .utf8) {
                completion(response)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }

    func toJson(str: String?) -> [Dictionary<String,Any>]? {
        if str == nil {
            return nil
        }

        let data = str!.data(using: .utf8)!
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [Dictionary<String,Any>] {
                return jsonArray
            } else {
                print("bad json: " + str!)
                return nil
            }
        } catch let error as NSError {
            print(error)
            return nil
        }
    }
}
