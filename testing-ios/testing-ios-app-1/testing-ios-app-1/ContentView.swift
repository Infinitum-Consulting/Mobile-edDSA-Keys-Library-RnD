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

struct ContentView: View {
    @State var scanResult = "No QR code detected"
    @State var scanning = false
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello World")
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
                QrCodeScannerView(scanning: $scanning, scanResult: $scanResult)
            } else {
                Text("Scanning...")
            }
        }
        .padding()
    }
    
    func retrieve() {
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
        do {
            var item: CFTypeRef?
            let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
            
            if status == errSecSuccess {
                if let privateKeyData = item as? Data {
                    // Reconstruct the private key from the data
                    let retrievedPrivateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
                    print(retrievedPrivateKey.publicKey)
                    print("Private key retrieved successfully.")
                    
                    let message = "Hello, World!".data(using: .utf8)!
                    let signature = try retrievedPrivateKey.signature(for: message)
                    print(signature.base64EncodedString())
                    // Use `retrievedPrivateKey` as needed
                }
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
