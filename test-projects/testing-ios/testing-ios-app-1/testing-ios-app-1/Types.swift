//
//  Types.swift
//  testing-ios-app-1
//
//  Created by Yash Goyal on 08/11/24.
//

import Foundation

struct Message: Encodable, Decodable {
    var action: String
}

struct GetIdResponse: Encodable, Decodable {
    var action: String
    var id: String
}

struct ConnectRequest: Encodable {
    var action: String
    var peerId: String
    var publicKey: String
}

struct QrCodeData: Decodable {
    var webId: String
}
