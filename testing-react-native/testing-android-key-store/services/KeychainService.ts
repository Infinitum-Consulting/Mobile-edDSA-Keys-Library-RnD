import * as Keychain from 'react-native-keychain';
import nacl from 'tweetnacl';
import * as naclUtil from 'tweetnacl-util';

// Generate and store ED25519 key pair
export const generateAndStoreKeys = async (): Promise<void> => {
  try {
    // Generate ED25519 key pair
    const keyPair = nacl.sign.keyPair();

    // Convert keys to base64 for storage
    const publicKeyBase64 = naclUtil.encodeBase64(keyPair.publicKey);
    const privateKeyBase64 = naclUtil.encodeBase64(keyPair.secretKey);

    // Store the private key securely using Keychain
    await Keychain.setGenericPassword(publicKeyBase64, privateKeyBase64, {
      accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED_THIS_DEVICE_ONLY, // Keys accessible only when unlocked
      securityLevel: Keychain.SECURITY_LEVEL.SECURE_SOFTWARE, // Prefer hardware-backed storage
    });
    console.log('ED25519 key pair generated and stored securely.');
  } catch (error) {
    console.error('Error generating or storing ED25519 keys:', error);
  }
};

// Retrieve ED25519 key pair
export const retrieveKeys = async (): Promise<{
  publicKey: string;
  privateKey: string;
} | null> => {
  try {
    const credentials = await Keychain.getGenericPassword();
    if (credentials) {
      console.log('Keys retrieved from Keychain');
      return {
        publicKey: credentials.username,
        privateKey: credentials.password,
      };
    } else {
      console.log('No keys found in Keychain.');
      return null;
    }
  } catch (error) {
    console.error('Error retrieving keys:', error);
    return null;
  }
};

// Delete stored keys
export const deleteKeys = async (): Promise<void> => {
  try {
    await Keychain.resetGenericPassword();
    console.log('Keys deleted successfully from Keychain.');
  } catch (error) {
    console.error('Error deleting keys:', error);
  }
};
