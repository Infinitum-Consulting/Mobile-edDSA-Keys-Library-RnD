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

// Function to generate a new key pair, store it, and rotate keys
export const rotateKeys = async (): Promise<void> => {
  try {
    // 1. Generate a new ED25519 key pair
    const newKeyPair = nacl.sign.keyPair();

    // 2. Encode keys to Base64 for safe storage
    const newPublicKeyBase64 = naclUtil.encodeBase64(newKeyPair.publicKey);
    const newPrivateKeyBase64 = naclUtil.encodeBase64(newKeyPair.secretKey);

    // 3. Store the new private key securely using Keychain
    await Keychain.setGenericPassword(newPublicKeyBase64, newPrivateKeyBase64, {
      accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
      securityLevel: Keychain.SECURITY_LEVEL.SECURE_HARDWARE, // Use hardware-backed storage
    });

    console.log('New ED25519 key pair generated and stored securely.');

    // 4. Optionally, delete the old key pair if it exists
    await Keychain.resetGenericPassword();
    console.log('Old key pair deleted successfully.');
  } catch (error) {
    console.error('Error during key rotation:', error);
  }
};

// Function to retrieve the current key pair
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
