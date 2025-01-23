import React, { useState } from 'react';
import { View, Text, Button, StyleSheet, Alert } from 'react-native';
import * as SecureStore from 'expo-secure-store';
import * as ed25519 from '@noble/ed25519';
import { getRandomBytes } from 'expo-crypto';
import { sha512 } from '@noble/hashes/sha512';
import { Buffer } from 'buffer';

(ed25519.etc as any).sha512Sync = (...m: Uint8Array[]) => sha512(ed25519.etc.concatBytes(...m));
(ed25519.etc as any).sha512Async = (...m: Uint8Array[]) =>
  Promise.resolve((ed25519.etc as any).sha512Sync(...m));

export default function SecureKeyStorageApp() {
  const [publicKey, setPublicKey] = useState<string | null>(null);
  const [storedKeys, setStoredKeys] = useState<{
    privateKey: string | null;
    publicKey: string | null;
  } | null>(null);
  const [signature, setSignature] = useState<string | null>(null);

  const message = 'AxleGaming Test Message';

  // Generate key pair and create signature
  const generateKeyPairAndSign = async () => {
    try {
      // Generate private key
      const privateKeyBuffer = getRandomBytes(32);
      const publicKeyBuffer = await ed25519.getPublicKey(privateKeyBuffer);

      const privateKeyHex = Buffer.from(privateKeyBuffer).toString('hex');
      const publicKeyHex = Buffer.from(publicKeyBuffer).toString('hex');

      // Sign the message
      const messageBuffer = Buffer.from(message);
      const signatureBuffer = await ed25519.sign(messageBuffer, privateKeyBuffer);
      const signatureHex = Buffer.from(signatureBuffer).toString('hex');

      // Store keys and signature securely
      await SecureStore.setItemAsync('privateKey', privateKeyHex);
      await SecureStore.setItemAsync('publicKey', publicKeyHex);
      await SecureStore.setItemAsync('signature', signatureHex);

      // Update state
      setPublicKey(publicKeyHex);
      setSignature(signatureHex);
    } catch (error) {
      console.error('Key pair and signature generation error:', error);
    }
  };

  // Retrieve stored keys and signature
  const retrieveStoredKeysAndSignature = async () => {
    try {
      const storedPrivateKey = await SecureStore.getItemAsync('privateKey');
      const storedPublicKey = await SecureStore.getItemAsync('publicKey');
      const storedSignature = await SecureStore.getItemAsync('signature');

      setStoredKeys({
        privateKey: storedPrivateKey,
        publicKey: storedPublicKey,
      });
      setSignature(storedSignature);
    } catch (error) {
      console.error('Key and signature retrieval error:', error);
    }
  };

  // Rotate key pair and regenerate signature
  const rotateKeyPair = async () => {
    try {
      // Retrieve existing keys for backup
      const oldPrivateKey = await SecureStore.getItemAsync('privateKey');
      const oldPublicKey = await SecureStore.getItemAsync('publicKey');
      const oldSignature = await SecureStore.getItemAsync('signature');

      // Backup old keys and signature
      // console.log('Old Keys Backup:', {
      //   privateKey: oldPrivateKey,
      //   publicKey: oldPublicKey,
      //   signature: oldSignature,
      // });

      // Generate new key pair
      const privateKeyBuffer = getRandomBytes(32);
      const publicKeyBuffer = await ed25519.getPublicKey(privateKeyBuffer);

      const newPrivateKeyHex = Buffer.from(privateKeyBuffer).toString('hex');
      const newPublicKeyHex = Buffer.from(publicKeyBuffer).toString('hex');

      // Sign the message with the new key pair
      const messageBuffer = Buffer.from(message);
      const newSignatureBuffer = await ed25519.sign(messageBuffer, privateKeyBuffer);
      const newSignatureHex = Buffer.from(newSignatureBuffer).toString('hex');

      // Store new keys and signature securely
      await SecureStore.setItemAsync('privateKey', newPrivateKeyHex);
      await SecureStore.setItemAsync('publicKey', newPublicKeyHex);
      await SecureStore.setItemAsync('signature', newSignatureHex);

      // Update state
      setPublicKey(newPublicKeyHex);
      setSignature(newSignatureHex);
      setStoredKeys({
        privateKey: newPrivateKeyHex,
        publicKey: newPublicKeyHex,
      });

      Alert.alert('Key Rotation Successful', 'New keys and signature have been generated.');
    } catch (error) {
      console.error('Key rotation error:', error);
      Alert.alert('Key Rotation Failed', 'An error occurred while rotating keys.');
    }
  };

  // Verify the signature
  const verifySignature = async () => {
    try {
      const storedPublicKeyHex = await SecureStore.getItemAsync('publicKey');
      const storedSignatureHex = await SecureStore.getItemAsync('signature');

      if (!storedPublicKeyHex || !storedSignatureHex) {
        Alert.alert('Verification Failed', 'Public key or signature not found.');
        return;
      }

      const publicKeyBuffer = Buffer.from(storedPublicKeyHex, 'hex');
      const signatureBuffer = Buffer.from(storedSignatureHex, 'hex');
      const messageBuffer = Buffer.from(message);

      const isValid = await ed25519.verify(signatureBuffer, messageBuffer, publicKeyBuffer);

      if (isValid) {
        Alert.alert('Signature Verified', 'The signature is valid!');
      } else {
        Alert.alert('Verification Failed', 'The signature is invalid.');
      }
    } catch (error) {
      console.error('Signature verification error:', error);
      Alert.alert('Verification Error', 'An error occurred while verifying the signature.');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Secure Key Storage, Signing & Verification Demo</Text>

      <Button title="Generate Key Pair and Sign" onPress={generateKeyPairAndSign} />

      <Button title="Retrieve Stored Keys and Signature" onPress={retrieveStoredKeysAndSignature} />

      <Button title="Rotate Key Pair" onPress={rotateKeyPair} color="orange" />

      <Button title="Verify Signature" onPress={verifySignature} color="green" />

      {publicKey && (
        <View style={styles.keySection}>
          <Text style={styles.keyLabel}>Active Public Key:</Text>
          <Text style={styles.keyValue}>{publicKey}</Text>
        </View>
      )}

      {signature && (
        <View style={styles.keySection}>
          <Text style={styles.keyLabel}>Signature:</Text>
          <Text style={styles.keyValue}>{signature}</Text>
        </View>
      )}

      {storedKeys && (
        <View style={styles.keySection}>
          <Text style={styles.keyLabel}>Stored Private Key:</Text>
          <Text style={styles.keyValue}>{storedKeys.privateKey}</Text>

          <Text style={styles.keyLabel}>Stored Public Key:</Text>
          <Text style={styles.keyValue}>{storedKeys.publicKey}</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
    backgroundColor: '#f0f0f0',
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  keySection: {
    marginTop: 20,
    padding: 10,
    backgroundColor: 'white',
    borderRadius: 5,
  },
  keyLabel: {
    fontWeight: 'bold',
    marginBottom: 5,
  },
  keyValue: {
    backgroundColor: '#e0e0e0',
    padding: 5,
    borderRadius: 3,
    fontFamily: 'monospace',
    overflow: 'hidden',
  },
});
