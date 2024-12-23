import * as Keychain from 'react-native-keychain';
import nacl from 'tweetnacl';
import * as naclUtil from 'tweetnacl-util';
import {jubjub} from '@noble/curves/jubjub';
import {randomBytes} from '@noble/hashes/utils';
import {Buffer} from 'react-native-buffer';

// ----- ED25519 Key Management -----

export const generateAndStoreED25519Keys = async (): Promise<void> => {
  try {
    // Generate ED25519 key pair
    const keyPair = nacl.sign.keyPair();

    // Convert to base64 for storage
    const publicKeyBase64 = naclUtil.encodeBase64(keyPair.publicKey);
    const privateKeyBase64 = naclUtil.encodeBase64(keyPair.secretKey);

    // Store keys securely
    await Keychain.setGenericPassword(publicKeyBase64, privateKeyBase64, {
      accessControl: Keychain.ACCESS_CONTROL.BIOMETRY_ANY,
      accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED,
    });
    console.log('ED25519 key pair generated and stored securely.');
  } catch (error) {
    console.error('Error generating ED25519 keys:', error);
  }
};

// ----- BabyJubJub Key Management -----
export const generateAndStoreJubJubKeys = async (): Promise<void> => {
  try {
    // Generate random private key (32 bytes)
    const privateKey = randomBytes(32);

    // Derive the public key
    const publicKey = jubjub.getPublicKey(privateKey);

    // Convert to hex strings for storage
    const privateKeyHex = Buffer.from(privateKey).toString('hex');
    const publicKeyHex = Buffer.from(publicKey).toString('hex');

    // Store keys securely
    await Keychain.setGenericPassword(publicKeyHex, privateKeyHex);
    console.log('BabyJubJub key pair generated and stored securely.');
  } catch (error) {
    console.error('Error generating JubJub keys:', error);
  }
};

// ----- Retrieve Keys -----
export const retrieveKeys = async (): Promise<{
  publicKey: string;
  privateKey: string;
} | null> => {
  try {
    const credentials = await Keychain.getGenericPassword({
      accessControl: Keychain.ACCESS_CONTROL.BIOMETRY_ANY,
    });
    if (credentials) {
      console.log('Keys retrieved successfully!');
      return {
        publicKey: credentials.username,
        privateKey: credentials.password,
      };
    } else {
      console.log('No keys found.');
      return null;
    }
  } catch (error) {
    console.error('Error retrieving keys:', error);
    return null;
  }
};

// ----- Delete Keys -----
export const deleteKeys = async (): Promise<void> => {
  try {
    await Keychain.resetGenericPassword();
    console.log('Keys deleted successfully.');
  } catch (error) {
    console.error('Error deleting keys:', error);
  }
};

// ----- Rotate Keys -----
export const rotateKeys = async (): Promise<void> => {
  try {
    console.log('Rotating keys...');
    await deleteKeys(); // Delete old keys
    await generateAndStoreED25519Keys(); // Generate new keys
    console.log('Keys rotated successfully.');
  } catch (error) {
    console.error('Error rotating keys:', error);
  }
};