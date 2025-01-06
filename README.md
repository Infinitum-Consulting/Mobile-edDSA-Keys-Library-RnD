# edDSA Key Management on Mobile Devices (iOS & Android)

This README consolidates research and implementation details for securely managing **edDSA keys** (commonly on **Curve25519**) on both iOS and Android platforms. It covers:

1. Key generation  
2. Secure storage (Keychain, Secure Enclave on iOS, Android Keystore/TEE)  
3. Key rotation and recovery strategies  
4. Integration of passkeys/biometric prompts  
5. Cloud backup solutions  

These solutions aim to enable robust cryptographic operations while preserving user privacy and meeting enterprise-grade security requirements—especially relevant in **self-sovereign identity (SSI)**, **zero-knowledge proofs (ZKPs)**, and other privacy-preserving systems.

---

## Table of Contents

- [edDSA Key Management on Mobile Devices (iOS \& Android)](#eddsa-key-management-on-mobile-devices-ios--android)
  - [Table of Contents](#table-of-contents)
  - [1. Introduction](#1-introduction)
  - [2. Research Areas](#2-research-areas)
  - [3. Key Concepts (iOS \& Android)](#3-key-concepts-ios--android)
    - [iOS: Keychain \& Secure Enclave](#ios-keychain--secure-enclave)
    - [Android: Keystore \& KeyChain API](#android-keystore--keychain-api)
    - [Software-Backed vs. Hardware-Backed Security](#software-backed-vs-hardware-backed-security)
  - [4. Findings on iOS Key Management](#4-findings-on-ios-key-management)
  - [5. Findings on Android Key Management](#5-findings-on-android-key-management)
  - [6. Implementation Options (React Native \& Native)](#5-implementation-options-react-native--native)
    - [Expo SecureStore](#expo-securestore)
    - [React Native Keychain](#react-native-keychain)
    - [Native Android (Kotlin/Java)](#native-android-kotlinjava)
  - [7. Backup \& Recovery Strategies](#6-backup--recovery-strategies)
  - [8. Code Implementation Examples](#7-code-implementation-examples)
    - [iOS: edDSA (Curve25519) Key Storage in Keychain](#ios-eddsa-curve25519-key-storage-in-keychain)
    - [Android: Ed25519 Key Pair (React Native)](#android-ed25519-key-pair-react-native)
    - [Biometric Authentication (React Native)](#biometric-authentication-react-native)
    - [Native Kotlin: Ed25519 Key in Android Keystore](#native-kotlin-ed25519-key-in-android-keystore)
  - [9. Security Best Practices](#8-security-best-practices)
  - [10. Future Work](#9-future-work)
  - [11. Conclusion](#10-conclusion)
  - [12. Additional References](#11-additional-references)

---

## 1. Introduction

Mobile devices increasingly serve as secure enclaves for cryptographic operations, especially in **self-sovereign identity (SSI)** and **zero-knowledge** applications. This research focuses on **edDSA key management**—from generation and hardware-backed storage to user-friendly key rotation and cloud backup solutions. We consider both **iOS** (Keychain & Secure Enclave) and **Android** (Keystore & TEE) hardware features, aiming to achieve the highest levels of security without sacrificing usability.

---

## 2. Research Areas

1. **Secure Key Generation and Storage**  
   - Explore methods for generating and protecting keys using **iOS Secure Enclave** or **Android TEE**.  
   - Evaluate best practices for iOS Keychain usage vs. Android Keystore.

2. **Key Rotation**  
   - Investigate user-friendly methods for rotating keys without invalidating previously signed or encrypted data.

3. **Passkey Integration**  
   - Explore the use of **passkeys** to simplify and secure user authentication workflows.

4. **Cloud Backup and Recovery**  
   - Research encrypted cloud storage mechanisms for key backup and restoration.  
   - Consider hardware and software-based backup solutions.

---

## 3. Key Concepts (iOS & Android)

### iOS: Keychain & Secure Enclave

- **Keychain**  
  - Sandbox-protected system for storing sensitive data.  
  - Supports keys for Curve25519 (edDSA) and ECDSA (P256, P384, etc.).  
  - Integrates with Face ID/Touch ID (biometric prompts).

- **Secure Enclave**  
  - Hardware module providing **hardware-backed** key isolation.  
  - Currently supports only **P256** (ECDSA). **Not** compatible with Curve25519 keys.  
  - Typically used for Apple Pay, device authentication, etc.

### Android: Keystore & KeyChain API

- **Android Keystore**  
  - Lets an individual app store its own credentials.  
  - Supports hardware-backed security on devices with **StrongBox** or TEE.  
  - Keys are non-exportable by design.

- **KeyChain API**  
  - System-wide credentials (e.g., user certificates).  
  - Prompts user via system UI to allow or deny access.  
  - Typically for sharing credentials across multiple apps.

### Software-Backed vs. Hardware-Backed Security

- **Software-Backed (TEE)**  
  - Key operations occur in a Trusted Execution Environment.  
  - Vulnerable to physical attacks if the device is rooted or compromised.

- **Hardware-Backed (StrongBox, Secure Enclave)**  
  - Dedicated, tamper-resistant security chip.  
  - Keys never leave the chip, and cryptographic operations occur in hardware.  
  - Highest level of resistance to both software-based exploits and physical attacks.

---

## 4. Findings on iOS Key Management

1. **Key Storage Options**  
   - **Keychain**: Allows storing Curve25519 private keys. Can tie retrieval to biometric or passcode-based access.  
   - **Secure Enclave**: Only supports the P256 curve. Not suitable for edDSA on Curve25519.

2. **Supported Cryptographic Algorithms**  
   - **Curve25519**: Supported by CryptoKit for key exchange and signatures (edDSA).  
   - **P256, P384, P512**: Typically used for ECDSA.  
   - **HPKE**: For hybrid public key encryption.  
   - *Note*: The Secure Enclave exclusively supports P256, so if you need ed25519/Curve25519, store keys in the **Keychain**.

3. **Keychain Security Features**  
   - **App-Specific Isolation**  
   - **Biometric Authentication** via `LAContext`  
   - **Encrypted Cloud Backups**: By default, Keychain entries are encrypted when using iCloud backup.

---

## 5. Findings on Android Key Management

### Key Storage Options
- **Android Keystore System**: Provides secure storage for cryptographic keys. Allows storing Curve25519 private keys if using custom implementations. Android Keystore natively supports ECDSA with P256, P384, and P521.
- **Hardware-Backed Security**: If the device includes a hardware-backed keystore (e.g., Trusted Execution Environment or Secure Element), it can securely generate and store keys.
- **Key Storage Alternatives**: For applications needing edDSA on Curve25519, keys can be securely stored in encrypted SharedPreferences or custom storage solutions, combined with the Android Keystore for encryption.

### Supported Cryptographic Algorithms
- **Curve25519**: Not natively supported in the Android Keystore. However, libraries like [Bouncy Castle](https://www.bouncycastle.org/) or [Conscrypt](https://conscrypt.org/) provide support for edDSA signatures and key exchange on Curve25519.
- **P256, P384, P521**: Supported by the Android Keystore for ECDSA.
- **HPKE (Hybrid Public Key Encryption)**: Not natively supported but can be implemented via third-party libraries.
- **AES and RSA**: Widely supported by the Android Keystore for encryption and key wrapping.

### Key Management Features
- **Device-Specific Isolation**: Keys stored in the Android Keystore are tied to the device and cannot be extracted, even by root access (on devices with proper hardware-backed security).
- **Biometric Authentication**: Can restrict key access to biometric authentication (e.g., fingerprint or facial recognition) using the `setUserAuthenticationRequired` flag in the `KeyGenParameterSpec`.
- **Secure Backup**: Android Keystore does not allow exporting private keys, so they cannot be backed up directly. Applications requiring key backup must implement custom encrypted backup strategies, such as encrypting keys using a passphrase-derived key and securely storing them.

### Notes
- Unlike iOS, where the Secure Enclave does not support Curve25519, Android allows flexibility by enabling the use of third-party libraries for Curve25519 support. However, it lacks a built-in solution in the Keystore for ed25519.
- Applications using Curve25519-based cryptographic operations must manage key storage securely, as improper implementations may compromise key confidentiality.


## 6. Implementation Options (React Native & Native)

### Expo SecureStore

- **Cross-platform** approach for storing small sensitive data (tokens, passwords).  
- Not guaranteed to be **hardware-backed** on Android.  
- Suitable for storing strings or tokens, not complex key generation operations.

### React Native Keychain

- Wraps platform-specific storage (Keychain on iOS, Keystore on Android).  
- Provides simple APIs for saving and retrieving credentials, with optional biometric prompts.  
- Can specify `securityLevel: SECURE_HARDWARE` on Android to *attempt* hardware-backed storage if available.

### Native Android (Kotlin/Java)

- Use `KeyGenParameterSpec` and `KeyPairGenerator` for **Ed25519** (API 23+).  
- Allows direct usage of hardware-backed security if the device supports **StrongBox**.  
- More boilerplate, but grants full control over key usage policies, biometric constraints, etc.

---

## 7. Backup & Recovery Strategies

1. **Avoid Android Auto Backup**  
   - Keys in Keystore are non-exportable, so data encrypted with them cannot be restored on a different device.

2. **Encrypted Cloud Storage**  
   - Encrypt private keys locally (with a Key Encryption Key) before uploading to cloud (e.g., Google Drive, AWS S3).  
   - Retrieve and decrypt only when user re-authenticates.

3. **User-Input-Based Encryption**  
   - Derive a key from the user’s passphrase, then encrypt your private keys.  
   - Minimizes server compromise risks but requires user interaction.

4. **Hybrid Approaches**  
   - Combine on-device hardware-backed storage with remote backups of *encrypted* key material.

---

## 8. Code Implementation Examples

### iOS: edDSA (Curve25519) Key Storage in Keychain

Below is a Swift snippet demonstrating **Curve25519** private key storage secured by biometric prompts.

```swift
import CryptoKit
import LocalAuthentication

func saveKeys() {
    // Generate a new Curve25519 private key
    let key = Curve25519.Signing.PrivateKey()
    let privateKeyData = key.rawRepresentation
    let tag = "com.example.privatekey".data(using: .utf8)!

    var error: Unmanaged<CFError>?
    // Create access control with biometric authentication
    let accessControl = SecAccessControlCreateWithFlags(
        nil,
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly, // Key accessible only when unlocked
        .biometryCurrentSet, // Biometric required
        &error
    )
    if let error = error {
        print("Error creating access control: \(error.takeRetainedValue() as Error)")
        return
    }

    let context = LAContext()
    context.touchIDAuthenticationAllowableReuseDuration = 10

    // Define a query to add the key to the Keychain
    let addQuery: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrKeyType as String: kSecAttrKeyTypeEC,
        kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        kSecAttrApplicationTag as String: tag,
        kSecValueData as String: privateKeyData,
        kSecUseAuthenticationContext as String: context,
        kSecAttrAccessControl as String: accessControl as Any
    ]

    let status = SecItemAdd(addQuery as CFDictionary, nil)
    if status == errSecSuccess {
        print("Private key stored successfully.")
    } else if status == errSecDuplicateItem {
        print("Private key already exists in the Keychain.")
    } else {
        print("Error storing private key: \(status)")
    }

    // Output key details
    print("Public Key: \(key.publicKey)")
    print("Raw Private Key Representation: \(privateKeyData)")
}

func getStoredKey() -> (Data, OSStatus) {
    let tag = "com.example.privatekey".data(using: .utf8)!
    let context = LAContext()
    context.localizedReason = "Access your private key"

    let getQuery: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrKeyType as String: kSecAttrKeyTypeEC,
        kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        kSecAttrApplicationTag as String: tag,
        kSecReturnData as String: true,
        kSecUseAuthenticationContext as String: context
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
    if status == errSecSuccess, let privateKeyData = item as? Data {
        return (privateKeyData, status)
    } else if status == errSecItemNotFound {
        print("Private key not found in the Keychain.")
    } else {
        print("Error retrieving private key: \(status)")
    }
    return (Data(), status)
}
```

### Android: Ed25519 Key Pair (React Native)

Using **tweetnacl** or **@noble/ed25519** with **react-native-keychain**:

```js
import * as nacl from 'tweetnacl';
import * as naclUtil from 'tweetnacl-util';
import * as Keychain from 'react-native-keychain';

async function generateAndStoreKeyPair() {
  // 1. Generate Ed25519 key pair
  const keyPair = nacl.sign.keyPair();

  // 2. Encode keys for storage
  const publicKeyBase64 = naclUtil.encodeBase64(keyPair.publicKey);
  const privateKeyBase64 = naclUtil.encodeBase64(keyPair.secretKey);

  // 3. Store private key in Android Keystore (if available)
  await Keychain.setGenericPassword(publicKeyBase64, privateKeyBase64, {
    accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
    securityLevel: Keychain.SECURITY_LEVEL.SECURE_HARDWARE, // Attempt hardware-backed
  });

  console.log('Ed25519 keys generated and stored!');
}

async function retrieveStoredKeyPair() {
  const credentials = await Keychain.getGenericPassword();
  if (credentials) {
    const publicKey = naclUtil.decodeBase64(credentials.username);
    const privateKey = naclUtil.decodeBase64(credentials.password);
    return { publicKey, privateKey };
  }
  return null;
}
```

### Biometric Authentication (React Native)

```js
import * as Keychain from 'react-native-keychain';

async function saveCredentialsWithBiometrics(username, password) {
  try {
    await Keychain.setGenericPassword(username, password, {
      accessControl: Keychain.ACCESS_CONTROL.BIOMETRY_ANY,
      securityLevel: Keychain.SECURITY_LEVEL.SECURE_SOFTWARE,
    });
    console.log('Saved with biometrics!');
  } catch (error) {
    console.error('Error saving credentials:', error);
  }
}

async function retrieveCredentialsWithBiometrics() {
  try {
    const credentials = await Keychain.getGenericPassword({
      accessControl: Keychain.ACCESS_CONTROL.BIOMETRY_ANY,
    });
    if (credentials) {
      console.log('Retrieved credentials:', credentials);
    } else {
      console.log('No credentials found.');
    }
  } catch (error) {
    console.error('Error retrieving credentials:', error);
  }
}
```

### Native Kotlin: Ed25519 Key in Android Keystore

```kotlin
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.PublicKey
import java.security.Signature
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties

fun generateEd25519KeyInKeystore() {
    val keyPairGenerator = KeyPairGenerator.getInstance("Ed25519", "AndroidKeyStore")
    val parameterSpec = KeyGenParameterSpec.Builder(
        "Ed25519Key",
        KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
    )
        .setDigests(KeyProperties.DIGEST_NONE) // Ed25519 doesn't need a digest
        .build()
    keyPairGenerator.initialize(parameterSpec)
    keyPairGenerator.generateKeyPair()
}

fun getPublicKey(): PublicKey {
    val keystore = KeyStore.getInstance("AndroidKeyStore")
    keystore.load(null)
    return keystore.getCertificate("Ed25519Key").publicKey
}

fun getPrivateKey(): PrivateKey {
    val keystore = KeyStore.getInstance("AndroidKeyStore")
    keystore.load(null)
    return keystore.getKey("Ed25519Key", null) as PrivateKey
}

fun signData(privateKey: PrivateKey, data: String): ByteArray {
    val signature = Signature.getInstance("Ed25519")
    signature.initSign(privateKey)
    signature.update(data.toByteArray())
    return signature.sign()
}
```

---

## 9. Security Best Practices

1. **Disable Logging**  
   - Never log private keys or sensitive data.

2. **Use CSPRNGs**  
   - Ensure random number generation is cryptographically secure (`SecureRandom` in Kotlin/Java, `CryptoKit` in iOS, or `tweetnacl` for React Native).

3. **Rate Limiting / Access Control**  
   - Limit cryptographic operations to thwart brute-force attempts.  
   - Restrict usage behind biometrics or strong passcodes.

4. **Minimize Attack Surface**  
   - Restrict the number of functions or modules that can access private keys.  
   - Conduct regular code audits and minimize dependencies.

5. **Key Rotation Policies**  
   - Plan for key rotation every 90–180 days (or as required by compliance standards).  
   - Provide user-friendly flows so that older signatures remain valid while new keys are propagated.

---

## 10. Future Work

1. **Android Integration**  
   - Further refine passkey usage with Android Credential Manager.  
   - Explore advanced TEE capabilities, such as **StrongBox** attestation.

2. **Advanced Key Rotation Mechanisms**  
   - Automate rotation with minimal user friction.  
   - Investigate cryptographic continuity for existing signatures.

3. **Cloud Backup Solutions**  
   - Implement robust, encrypted remote backups (AWS KMS, Google Cloud KMS, etc.).  
   - Possibly incorporate offline or user-driven backup approaches (e.g., QR codes or hardware tokens).

4. **Compliance & Standards**  
   - Align implementations with **FIPS 140-2/3** and other government/industry certifications.

---

## 11. Conclusion

This research demonstrates how **iOS Keychain** and **Android Keystore** (with TEE/StrongBox) can securely manage edDSA keys for privacy-preserving applications. By leveraging hardware-backed features where possible, integrating biometrics or passkeys for user-friendly access, and employing robust backup strategies, we can achieve strong cryptographic assurances. Future work aims to unify these strategies across both platforms, ensuring standards compliance while remaining flexible and user-centric.

---

## 12. Additional References

- **iOS Security Docs**  
  - [Apple Keychain Services](https://developer.apple.com/documentation/security/keychain_services)  
  - [CryptoKit + Curve25519](https://developer.apple.com/documentation/cryptokit/curve25519)

- **Android Security Docs**  
  - [Android Keystore](https://developer.android.com/training/articles/keystore)  
  - [Play Integrity API](https://developer.android.com/google/play/integrity)
  - [Credential Manager](https://developer.android.com/training/sign-in/passkeys)
  - [Autofill framework](https://developer.android.com/guide/topics/text/autofill)
  - [Tink](https://developers.google.com/tink)

- **React Native Libraries**  
  - [react-native-keychain](https://github.com/oblador/react-native-keychain)  
  - [expo-secure-store](https://docs.expo.dev/versions/latest/sdk/securestore/)

- **Cryptographic Libraries**  
  - [zk-kit](https://github.com/privacy-scaling-explorations/zk-kit)  
  - [tweetnacl](https://www.npmjs.com/package/tweetnacl)  
  - [@noble/ed25519](https://www.npmjs.com/package/@noble/ed25519)  
  - [CryptoKit (Swift)](https://developer.apple.com/documentation/cryptokit)

- **Cloud Backup Services**  
  - [AWS KMS](https://aws.amazon.com/kms/)  
  - [Google Cloud KMS](https://cloud.google.com/kms)  
  - [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault/)

---

**Disclaimer**: The snippets and approaches herein are for illustrative purposes. Always perform security reviews, keep dependencies up to date, and follow platform-specific best practices to ensure robust protection of cryptographic keys and sensitive data.
