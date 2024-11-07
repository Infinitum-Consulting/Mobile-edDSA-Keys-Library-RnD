//
//  ContentView.swift
//  testing-ios-app-1
//
//  Created by Yash Goyal on 02/11/24.
//

import SwiftUI
import CryptoKit
import Security
import LocalAuthentication
import WebKit

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

struct ContentView: View {
    @State var scanResult = "No QR code detected"
    @State var scanning = false
    @ObservedObject var websocket = Websocket()

    
    var message = Message(action: "get-id")
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello World")
            Button("Get Id", action: {
                websocket.sendMsg(message)
            })
                .padding(.horizontal)
                .background(Color.red)
                .foregroundColor(.white)
                .padding()
            Button("Show", action: click)
                .padding(.horizontal)
                .background(Color.red)
                .foregroundColor(.white)
                .padding()
            Button("Retreive", action: retrieve)
                .padding(.horizontal)
                .background(Color.red)
                .foregroundColor(.white)
            Button("Scan", action: { scanning.toggle() })
            if scanning {
                QrCodeScannerView(onScan: onScan)
            } else {
                Text("Scanning...")
            }
        }
        .padding()
    }
    
    func onScan(_ result: String) {
        // TODO: validate the scan result here
        print(result)
        
        let jsonData = Data(result.utf8)
        let decoder = JSONDecoder()

        do {
            let (privateKeyData, status) = getStoredKey()
            
            if status == errSecSuccess {
                let retrievedPrivateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
                let publicKey = Data(base64Encoded: retrievedPrivateKey.publicKey.rawRepresentation.base64EncodedString())!
                let res = try decoder.decode(QrCodeData.self, from: jsonData)
                let request = ConnectRequest(action: "connect", peerId: res.webId, publicKey: publicKey.hexEncodedString())
                
                let encoder = JSONEncoder()
                
                let data = try encoder.encode(request)
                let messageStr = String(data: data, encoding: .utf8)!
                
                websocket.sendMessage(messageStr)
                
                print(request)
                
                print("Private key retrieved successfully.")
                
                let message = "Hello, World!".data(using: .utf8)!
                let signature = try retrievedPrivateKey.signature(for: message)
                print(signature.base64EncodedString())
                // Use `retrievedPrivateKey` as needed
            } else if status == errSecItemNotFound {
                print("Private key not found in the Keychain.")
            } else {
                print("Error retrieving private key: \(status)")
            }
        } catch {
            print(error.localizedDescription)
        }

        scanning = false
    }
    
    func getStoredKey() -> (Data, OSStatus) {
        let tag = "consulting.infinitum.testing-ios-app-1.privatekey".data(using: .utf8)!
        
        let context = LAContext()
        context.localizedReason = "Access your password on the keychain"
                
        let getQuery: [String: Any] = [
            kSecClass as String:            kSecClassKey,
            kSecAttrKeyType as String:      kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String:     kSecAttrKeyClassPrivate,
            kSecAttrApplicationTag as String: tag,
            kSecReturnData as String:       true,
            kSecUseAuthenticationContext as String: context,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
        
        if status == errSecSuccess {
            if let privateKeyData = item as? Data {
                // Reconstruct the private key from the data
                return (privateKeyData, status)
                // Use `retrievedPrivateKey` as needed
            }
        } else if status == errSecItemNotFound {
            print("Private key not found in the Keychain.")
        } else {
            print("Error retrieving private key: \(status)")
        }
        return (Data(), status)
    }

    func retrieve() {
        do {
            let (privateKeyData, status) = getStoredKey()
            
            if status == errSecSuccess {
                let retrievedPrivateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
                let data = Data(base64Encoded: retrievedPrivateKey.publicKey.rawRepresentation.base64EncodedString())!
                print(data.hexEncodedString())
                print("Private key retrieved successfully.")
                
                let message = "Hello, World!".data(using: .utf8)!
                let signature = try retrievedPrivateKey.signature(for: message)
                print(signature.base64EncodedString())
                // Use `retrievedPrivateKey` as needed
            } else if status == errSecItemNotFound {
                print("Private key not found in the Keychain.")
            } else {
                print("Error retrieving private key: \(status)")
            }
        } catch {
            print("Error generating private key: \(error.localizedDescription)")
        }
    }
    
    func click() {
        let key = Curve25519.Signing.PrivateKey()
        let privateKeyData = key.rawRepresentation
        let tag = "consulting.infinitum.testing-ios-app-1.privatekey".data(using: .utf8)!
        
        // Delete any existing key
        // let deleteQuery: [String: Any] = [
           //  kSecClass as String:            kSecClassKey,
           //  kSecAttrKeyType as String:      kSecAttrKeyTypeEC,
           //  kSecAttrKeyClass as String:     kSecAttrKeyClassPrivate,
        // kSecAttrApplicationTag as String: tag
        // ]
        // SecItemDelete(deleteQuery as CFDictionary)
        
        var error: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &error
        )

        if let error = error {
            print("Error creating access control: \(error.takeRetainedValue() as Error)")
            // Handle the error appropriately
        }
        
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 10
        
        let addQuery: [String: Any] = [
            kSecClass as String:            kSecClassKey,
            kSecAttrKeyType as String:      kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String:     kSecAttrKeyClassPrivate,
            kSecAttrApplicationTag as String: tag,
            kSecValueData as String:        privateKeyData,
            kSecUseAuthenticationContext as String: context as Any,
            kSecAttrAccessControl as String:   accessControl as Any
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)

        if status == errSecSuccess {
            print("Private key stored successfully.")
        } else if status == errSecDuplicateItem {
            print("Private key already exists in the Keychain.")
        } else {
            print("Error storing private key: \(status)")
        }
        
        
        print(key.publicKey)
        print(key.rawRepresentation)
    }
}

#Preview {
    ContentView()
}
