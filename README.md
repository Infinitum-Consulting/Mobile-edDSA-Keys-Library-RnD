### **Research on edDSA Key Management on Mobile Devices**

#### **Introduction**
This research explores methods for securely managing edDSA keys on mobile devices, focusing on key generation, storage, rotation, recovery, and the integration of passkeys. The research leverages mobile hardware features such as the Secure Enclave (iOS) and Trusted Execution Environment (TEE) (Android) to develop solutions that ensure high levels of security while maintaining usability. These solutions are designed to address use cases in privacy-preserving systems, including self-sovereign identity (SSI) and zero-knowledge (zk) systems.

---

### **Research Areas**

1. **Secure Key Generation and Storage**
   - Explore secure methods for generating and storing cryptographic keys using mobile hardware.
   - Investigate hardware-specific features like iOS Secure Enclave and Android Keystore.

2. **Key Rotation**
   - Research user-friendly methods for key rotation without compromising prior uses of the keys.

3. **Passkey Integration**
   - Explore passkeys for seamless and secure user authentication.

4. **Cloud Backup and Recovery**
   - Investigate encrypted cloud storage mechanisms for secure key recovery.

5. **Compliance**
   - Study cryptographic standards like FIPS 140-2/3 for compliance in secure key management.

---

### **Findings on iOS Key Management**

#### **1. Key Storage Options**
Two main approaches for storing cryptographic keys on iOS are:

1. **Keychain**
   - A secure, sandboxed storage system for sensitive data.
   - Supports storage of various key types, including Curve25519.
   - Keys can be protected with biometrics or passcodes using Apple’s `LocalAuthentication` framework.
   - Allows inter-app key sharing with explicit configuration.

2. **Secure Enclave**
   - A secure hardware-based storage module for sensitive cryptographic operations.
   - Provides hardware-backed key isolation, ensuring high security.
   - Only supports the P256 curve, making it unsuitable for edDSA cryptography (Curve25519).

---

#### **2. Supported Cryptographic Algorithms**
The CryptoKit framework on iOS supports the following cryptographic algorithms:
- **Curve25519**: Used for edDSA and key exchange.
- **P256, P384, P512**: Typically used for ECDSA cryptography.
- **HPKE**: For hybrid public key encryption.

The Secure Enclave only supports the P256 curve, which is widely used in ECDSA cryptography but not compatible with edDSA. For edDSA (Curve25519), keys must be stored in the Keychain instead of the Secure Enclave.

---

#### **3. Keychain Security Features**
- **App-Specific Isolation**: Keys stored in the Keychain are isolated by default and cannot be accessed by other apps unless explicitly shared.
- **Biometric Authentication**: The Keychain integrates with iOS’s biometric authentication system (Face ID/Touch ID) to provide an additional layer of protection.
- **Encrypted Cloud Backups**: Keychain data is automatically encrypted during device backups to iCloud, ensuring security during storage and transfer.

---

#### **Code Implementation Examples**

##### **Saving Keys in Keychain**
The following code snippet demonstrates how to securely generate and store a private key in the Keychain, protected by biometrics.

```swift
func saveKeys() {
    // Generate a new Curve25519 private key
    let key = Curve25519.Signing.PrivateKey()
    let privateKeyData = key.rawRepresentation
    let tag = "com.example.privatekey".data(using: .utf8)!
    
    var error: Unmanaged<CFError>?
    
    // Create access control with biometric authentication
    let accessControl = SecAccessControlCreateWithFlags(
        nil,
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly, // Key accessible only when the device is unlocked
        .biometryCurrentSet,                          // Require current biometric credentials
        &error
    )
    
    if let error = error {
        print("Error creating access control: \(error.takeRetainedValue() as Error)")
        return // Handle the error appropriately
    }
    
    let context = LAContext()
    context.touchIDAuthenticationAllowableReuseDuration = 10 // Allowable reuse duration for biometric authentication
    
    // Define a query to add the key to the Keychain
    let addQuery: [String: Any] = [
        kSecClass as String:            kSecClassKey,                     // Key class
        kSecAttrKeyType as String:      kSecAttrKeyTypeEC,                // Key type (Elliptic Curve)
        kSecAttrKeyClass as String:     kSecAttrKeyClassPrivate,          // Key class (Private Key)
        kSecAttrApplicationTag as String: tag,                           // Application-specific tag
        kSecValueData as String:        privateKeyData,                  // Private key data
        kSecUseAuthenticationContext as String: context as Any,          // Authentication context
        kSecAttrAccessControl as String:   accessControl as Any          // Access control settings
    ]
    
    let status = SecItemAdd(addQuery as CFDictionary, nil) // Add key to the Keychain
    
    // Handle the result of the Keychain operation
    if status == errSecSuccess {
        print("Private key stored successfully.")
    } else if status == errSecDuplicateItem {
        print("Private key already exists in the Keychain.")
    } else {
        print("Error storing private key: \(status)")
    }
    
    // Output the generated key details
    print("Public Key: \(key.publicKey)")
    print("Raw Private Key Representation: \(key.rawRepresentation)")
}
```

##### **Retrieving Keys from Keychain**
The following snippet retrieves a previously stored private key from the Keychain:

```swift
func getStoredKey() -> (Data, OSStatus) {
    let tag = "com.example.privatekey".data(using: .utf8)!
    
    let context = LAContext()
    context.localizedReason = "Access your password on the Keychain"
    
    let getQuery: [String: Any] = [
        kSecClass as String:            kSecClassKey,
        kSecAttrKeyType as String:      kSecAttrKeyTypeEC,
        kSecAttrKeyClass as String:     kSecAttrKeyClassPrivate,
        kSecAttrApplicationTag as String: tag,
        kSecReturnData as String:       true,
        kSecUseAuthenticationContext as String: context
    ]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
    
    if status == errSecSuccess {
        if let privateKeyData = item as? Data {
            return (privateKeyData, status)
        }
    } else if status == errSecItemNotFound {
        print("Private key not found in the Keychain.")
    } else {
        print("Error retrieving private key: \(status)")
    }
    return (Data(), status)
}
```

---

#### **Security Best Practices**
1. **Disable Logging**: Prevent sensitive data from being logged.
2. **Use CSPRNGs**: Ensure random number generation is cryptographically secure.
3. **Rate Limiting**: Limit cryptographic operations to prevent timing attacks.
4. **Access Control**: Use biometrics and passcodes to restrict access.
5. **Minimize Attack Surface**: Restrict the number of functions that access the private key.

---

#### **Future Work**
1. **Android Integration**: Explore key storage and management using Android Keystore and TEE.
2. **Key Rotation Mechanisms**: Investigate solutions for secure key rotation.
3. **Cloud Backup Solutions**: Develop encrypted cloud backup and recovery mechanisms.
4. **Compliance and Standards**: Align implementations with cryptographic standards like FIPS 140-2/3.

---

#### **Conclusion**
The research demonstrates how iOS hardware and APIs like Keychain and Secure Enclave can be used for secure edDSA key management. These findings provide a foundation for developing robust cryptographic solutions while ensuring compliance with security standards. Future work will extend these insights to Android platforms and refine cloud backup and key rotation mechanisms to enhance usability and resilience in cryptographic applications.
