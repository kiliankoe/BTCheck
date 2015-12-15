//
//  Coinbase.swift
//  BTCheck
//
//  Created by Kilian Költzsch on 15/12/15.
//  Copyright © 2015 Kilian Költzsch. All rights reserved.
//

import Foundation

class Coinbase {
	static func getAddressInfo(address: String, completion: ((address: Address?, error: CoinbaseError?) -> Void)) {
		guard address != "" else { completion(address: nil, error: .InvalidAddress); return }
		// Not sure if it'd be a good idea to validate BTC addresses here or just not give a fuck
		
		let url = NSURL(string: "https://bitcoin.toshi.io/api/v0/addresses/\(address)")!
		
		let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
			if let json = try? NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary {
				let addr = Address(hash: json["hash"] as! String, balance: json["balance"] as! Int, balanceUnconfirmed: json["unconfirmed_balance"] as! Int, received: json["received"] as! Int, sent: json["sent"] as! Int)
				completion(address: addr, error: nil)
			}
		}
		task.resume()
	}
	
	static func satoshiTo(currency: String, satoshi: Int, completion: (value: Double?, error: CoinbaseError?) -> Void) {
		
		let url = NSURL(string: "https://api.coinbase.com/v2/exchange-rates?currency=BTC")!
		
		let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
			if let json = try? NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary {
				let rate = json["data"]!["rates"]!![currency.uppercaseString] as! String
				let value = Double(rate)! * Double(satoshi) / 100_000_000
				completion(value: value, error: nil)
			}
		}
		task.resume()
	}
	
	static func lookupValueFor(address: String, currency: String, completion: (value: Double?, error: CoinbaseError?) -> Void) {
		getAddressInfo(address) { (address, error) in
			guard error == nil else {
				completion(value: nil, error: error)
				return
			}
			guard let address = address else {
				completion(value: nil, error: .InvalidAddress)
				return
			}
			
			satoshiTo(currency, satoshi: address.balance, completion: { (value, error) in
				guard error == nil else {
					completion(value: nil, error: error)
					return
				}
				guard let value = value else {
					completion(value: nil, error: .InvalidValue)
					return
				}
				
				completion(value: value, error: nil)
			})
		}
	}
}

struct Address {
	let hash: String
	let balance: Int
	let balanceUnconfirmed: Int
	let received: Int
	let sent: Int
}

enum CoinbaseError: ErrorType {
	case Request
	case Server
	case InvalidAddress
	case InvalidValue
}
