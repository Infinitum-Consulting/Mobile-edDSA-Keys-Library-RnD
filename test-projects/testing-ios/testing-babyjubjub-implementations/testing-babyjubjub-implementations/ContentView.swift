//
//  ContentView.swift
//  testing-babyjubjub-implementations
//
//  Created by Yash Goyal on 20/01/25.
//

import Foundation
import BigInt
import CryptoKit

/// Point type representing a point on the Baby Jubjub curve
public typealias Point = (x: BigInt, y: BigInt)

/// BabyJubJub implementation for elliptic curve operations
public struct BabyJubJub {
    // MARK: - Constants
    
    /// Prime order of the alt_bn128 curve
    static let r = BigInt("21888242871839275222246405745257275088548364400416034343698204186575808495617")
    
    /// Base point for generating other points on the Baby Jubjub curve
    static let Base8: Point = (
        x: BigInt("5299619240641551281634865583518297030282874472190772894086521144482721001553"),
        y: BigInt("16950150798460657717958625567821834550301663161624707787222815936182638968203")
    )
    
    /// Curve parameters from the equation 'ax^2 + y^2 = 1 + dx^2y^2'
    private static let a = BigInt("168700")
    private static let d = BigInt("168696")
    
    /// Order of the curve
    static let order = BigInt("21888242871839275222246405745257275088614511777268538073601725287587578984328")
    static let subOrder = order >> 3
    
    // MARK: - Field Operations
    
    /// Performs modular addition in the field
    private static func fieldAdd(_ a: BigInt, _ b: BigInt) -> BigInt {
        let result = (a + b) % r
        return result >= 0 ? result : result + r
    }
    
    /// Performs modular subtraction in the field
    private static func fieldSub(_ a: BigInt, _ b: BigInt) -> BigInt {
        let result = (a - b) % r
        return result >= 0 ? result : result + r
    }
    
    /// Performs modular multiplication in the field
    private static func fieldMul(_ a: BigInt, _ b: BigInt) -> BigInt {
        return (a * b) % r
    }
    
    /// Performs modular division in the field
    private static func fieldDiv(_ a: BigInt, _ b: BigInt) -> BigInt {
        return fieldMul(a, b.inverse(r)!)
    }
    
    // MARK: - Point Operations
    
    /// Adds two points on the Baby Jubjub curve
    /// - Parameters:
    ///   - p1: First point
    ///   - p2: Second point
    /// - Returns: Resulting point
    public static func addPoint(_ p1: Point, _ p2: Point) -> Point {
        let beta = fieldMul(p1.x, p2.y)
        let gamma = fieldMul(p1.y, p2.x)
        let delta = fieldMul(
            fieldSub(p1.y, fieldMul(a, p1.x)),
            fieldAdd(p2.x, p2.y)
        )
        
        let tau = fieldMul(beta, gamma)
        let dtau = fieldMul(d, tau)
        
        let x3 = fieldDiv(
            fieldAdd(beta, gamma),
            fieldAdd(1, dtau)
        )
        
        let y3 = fieldDiv(
            fieldAdd(delta, fieldSub(fieldMul(a, beta), gamma)),
            fieldSub(1, dtau)
        )
        
        return (x3, y3)
    }
    
    /// Performs scalar multiplication of a point
    /// - Parameters:
    ///   - base: Base point
    ///   - e: Scalar value
    /// - Returns: Resulting point
    public static func mulPointEscalar(_ base: Point, _ e: BigInt) -> Point {
        var res: Point = (BigInt(0), BigInt(1))
        var rem = e
        var exp = base
        
        while rem != 0 {
            if rem & 1 == 1 {
                res = addPoint(res, exp)
            }
            
            exp = addPoint(exp, exp)
            rem >>= 1
        }
        
        return res
    }
    
    /// Checks if a point lies on the curve
    /// - Parameter p: Point to check
    /// - Returns: True if point is on curve
    public static func inCurve(_ p: Point) -> Bool {
        let x2 = fieldMul(p.x, p.x)
        let y2 = fieldMul(p.y, p.y)
        
        let lhs = fieldAdd(fieldMul(a, x2), y2)
        let rhs = fieldAdd(1, fieldMul(fieldMul(x2, y2), d))
        
        return lhs == rhs
    }
    
    /// Packs a point into a single BigInt
    /// - Parameter point: Point to pack
    /// - Returns: Packed representation
    public static func packPoint(_ point: Point) -> BigInt {
        var bytes = point.y.magnitude.serialize()
        if bytes.count < 32 {
            bytes.append(contentsOf: Array(repeating: UInt8(0), count: 32 - bytes.count))
        }
        
        if point.x < 0 {
            bytes[31] |= 0x80
        }
        
        return BigInt(Data(bytes))
    }
    
    /// Unpacks a BigInt into a point
    /// - Parameter packed: Packed representation
    /// - Returns: Unpacked point or nil if invalid
    public static func unpackPoint(_ packed: BigInt) -> Point? {
        var bytes = packed.magnitude.serialize()
        let sign = (bytes[31] & 0x80) != 0
        bytes[31] &= 0x7f
        
        let y = BigInt(Data(bytes))
        if y >= r {
            return nil
        }
        
        let y2 = fieldMul(y, y)
        guard let x = tonelliShanks(fieldDiv(
            fieldSub(1, y2),
            fieldSub(a, fieldMul(d, y2))
        )) else {
            return nil
        }
        
        return (sign ? -x : x, y)
    }
    
    // MARK: - Helper Functions
    
    /// Implementation of the Tonelli-Shanks algorithm for square root in finite fields
    private static func tonelliShanks(_ n: BigInt) -> BigInt? {
        // Implementation of square root calculation
        // This is a placeholder - you would need to implement the full algorithm
        // The actual implementation is quite complex and requires careful consideration
        // of the field arithmetic
        return nil // TODO: Implement proper Tonelli-Shanks
    }
    
    /// Hashes a message to a point on the curve
    /// - Parameter message: Message to hash
    /// - Returns: Point on the curve
    private static func hashToPoint(_ message: String) -> Point {
        // Create a SHA-256 hash of the message
        let messageData = message.data(using: .utf8)!
        var hasher = SHA256()
        hasher.update(data: messageData)
        let hash = hasher.finalize()
        
        // Convert hash to BigInt and ensure it's within the field
        let hashBigInt = BigInt(Data(hash)) % r
        
        // Map the hash to a point on the curve
        // This is a simplified implementation - in practice, you'd want to use
        // a more sophisticated point mapping function that ensures uniform distribution
        return mulPointEscalar(Base8, hashBigInt)
    }
    
    /// Signs a message using a private key
    /// - Parameters:
    ///   - message: Message to sign
    ///   - privateKey: Private key to sign with
    /// - Returns: Signature (R, S) points
    public static func sign(message: String, privateKey: BigInt) -> (R: Point, S: BigInt) {
        // Generate random nonce
        var randomBytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let k = BigInt(Data(randomBytes)) % order
        
        // Calculate R = k * Base8
        let R = mulPointEscalar(Base8, k)
        
        // Hash the message to a point
        let hm = hashToPoint(message)
        
        // Calculate h = H(R, A, M) where A is the public key
        let publicKey = mulPointEscalar(Base8, privateKey)
        let h = hashToPoint("\(R.x)\(R.y)\(publicKey.x)\(publicKey.y)\(message)")
        
        // Calculate S = (k + h * privateKey) mod order
        let S = (k + (BigInt(h.x) * privateKey)) % order
        
        return (R, S)
    }
    
    /// Verifies a signature for a message
    /// - Parameters:
    ///   - message: Original message
    ///   - signature: Signature (R, S) points
    ///   - publicKey: Signer's public key
    /// - Returns: True if signature is valid
    public static func verify(message: String, signature: (R: Point, S: BigInt), publicKey: Point) -> Bool {
        // Calculate h = H(R, A, M)
        let h = hashToPoint("\(signature.R.x)\(signature.R.y)\(publicKey.x)\(publicKey.y)\(message)")
        
        // Verify: S * Base8 = R + h * publicKey
        let lhs = mulPointEscalar(Base8, signature.S)
        let rhs = addPoint(signature.R, mulPointEscalar(publicKey, BigInt(h.x)))
        
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

// MARK: - SwiftUI Views

import SwiftUI

struct BabyJubJubDemoView: View {
    @State private var privateKey = ""
    @State private var publicKey: Point?
    @State private var message = ""
    @State private var signature: (R: Point, S: BigInt)?
    @State private var verificationResult: Bool?
    
    func generateRandomPrivateKey() -> String {
        // Generate a random private key within the valid range (less than subOrder)
        var randomBytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let randomBigInt = BigInt(Data(randomBytes)) % BabyJubJub.subOrder
        return randomBigInt.description
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Baby JubJub Demo")
                .font(.title)
            
            TextField("Enter private key (decimal)", text: $privateKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Generate Random Private Key") {
                privateKey = generateRandomPrivateKey()
            }
            .buttonStyle(.bordered)
            
            Button("Generate Public Key") {
                if let scalar = BigInt(privateKey) {
                    publicKey = BabyJubJub.mulPointEscalar(BabyJubJub.Base8, scalar)
                }
            }
            .disabled(privateKey.isEmpty)
            
            if let pubKey = publicKey {
                VStack(alignment: .leading) {
                    Text("Public Key:")
                        .font(.headline)
                    Text("X: \(pubKey.x.description)")
                        .lineLimit(2)
                    Text("Y: \(pubKey.y.description)")
                        .lineLimit(2)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            Divider()
                        
            VStack(spacing: 20) {
                Text("Message Signing")
                    .font(.headline)
                
                TextField("Enter message to sign", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Sign Message") {
                    print("Hello")
                    if let privKey = BigInt(privateKey) {
                        signature = BabyJubJub.sign(message: message, privateKey: privKey)
                        
                        // Auto-verify the signature
                        if let sig = signature, let pubKey = publicKey {
                            verificationResult = BabyJubJub.verify(
                                message: message,
                                signature: sig,
                                publicKey: pubKey
                            )
                        }
                    }
                }
                .disabled(message.isEmpty || privateKey.isEmpty)
                .buttonStyle(.bordered)
                
                if let sig = signature {
                    VStack(alignment: .leading) {
                        Text("Signature:")
                            .font(.headline)
                        Text("R.x: \(sig.R.x.description)")
                            .lineLimit(2)
                        Text("R.y: \(sig.R.y.description)")
                            .lineLimit(2)
                        Text("S: \(sig.S.description)")
                            .lineLimit(2)
                        
                        if let verified = verificationResult {
                            Text("Signature Verification: \(verified ? "✅ Valid" : "❌ Invalid")")
                                .foregroundColor(verified ? .green : .red)
                                .padding(.top)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

#Preview {
    BabyJubJubDemoView()
}
