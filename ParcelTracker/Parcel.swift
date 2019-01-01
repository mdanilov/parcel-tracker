//
//  Tracker.swift
//  ParcelTracker
//
//  Created by Максим Данилов on 23/11/2018.
//  Copyright © 2018 Maxim Danilov. All rights reserved.
//

import Foundation

class Carrier: Codable {
    let code: String
    let name: String
    
    init(code: String, name: String) {
        self.code = code
        self.name = name
    }
}

class Event: Codable {
    let date: Date
    let operation: String
    let location: String?
    let delivered: Bool?
    let arrived: Bool?
    let accepted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case date = "eventDate"
        case operation
        case location
        case delivered
        case arrived
        case accepted
    }
    
    init(date: Date, operation: String, location: String? = nil, delivered: Bool? = nil, arrived: Bool? = nil, accepted: Bool? = nil) {
        self.date = date
        self.location = location
        self.operation = operation
        self.delivered = delivered
        self.arrived = arrived
        self.accepted = accepted
    }
}

class ParcelStatus: Codable {
    var delivered: Bool?
    var events: [Event] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deliveringTime: Int?
    var weight: Float?
}

class Parcel: Codable, Equatable {
    var name: String
    var barcode: String
    var carrier: Carrier
    var status: ParcelStatus?
    var pinCode: String?
    
    init(name: String, barcode: String, carrier: Carrier) {
        self.name = name
        self.barcode = barcode
        self.carrier = carrier
    }
    
    func statusAvailable() -> Bool {
        if let events = status?.events {
            return events.count > 0
        }
        else {
            return false
        }
    }
    
    static func ==(lhs: Parcel, rhs: Parcel) -> Bool {
        return
            lhs.barcode == rhs.barcode &&
            lhs.carrier.code == rhs.carrier.code
    }
}
