import * as LocalAuthentication from "expo-local-authentication";
import * as SecureStore from "expo-secure-store";
import { getRandomBytes } from "expo-crypto";
import { useState } from "react";
import { Button, Text, View } from "react-native";
import { Buffer } from "buffer";
import {
  derivePublicKey,
  signMessage,
  verifySignature,
} from "@zk-kit/eddsa-poseidon";

// Generate a random scalar to use as private key
export const generatePrivateKey = async (): Promise<Uint8Array> => {
  try {
    // Generate 32 random bytes
    const privateKeyBytes = getRandomBytes(32);
    // Convert to BigInt
    return privateKeyBytes;
  } catch (error) {
    console.error("Error generating private key:", error);
    throw error;
  }
};

// Store private key securely with biometric authentication
export const securelyStorePrivateKey = async (privateKey: Uint8Array) => {
  try {
    // Check if device supports biometric authentication
    const hasHardware = await LocalAuthentication.hasHardwareAsync();
    const isEnrolled = await LocalAuthentication.isEnrolledAsync();

    console.log("hasHardware", hasHardware);
    console.log("isEnrolled", isEnrolled);

    if (!hasHardware || !isEnrolled) {
      throw new Error("Biometric authentication not available");
    }

    // Request biometric authentication
    const result = await LocalAuthentication.authenticateAsync({
      promptMessage: "Authenticate to store private key",
      disableDeviceFallback: false,
      cancelLabel: "Cancel",
    });

    if (!result.success) {
      throw new Error("Authentication failed");
    }

    // Convert BigInt to string for storage
    const privateKeyStr = Buffer.from(privateKey).toString("hex");

    // Store the private key securely
    await SecureStore.setItemAsync("baby_jubjub_private_key", privateKeyStr, {
      keychainAccessible: SecureStore.WHEN_UNLOCKED,
    });

    return true;
  } catch (error) {
    console.error("Error storing private key:", error);
    throw error;
  }
};

// Retrieve private key with biometric authentication
export const retrievePrivateKey = async (): Promise<Uint8Array> => {
  try {
    // Request biometric authentication
    const result = await LocalAuthentication.authenticateAsync({
      promptMessage: "Authenticate to retrieve private key",
      disableDeviceFallback: false,
      cancelLabel: "Cancel",
    });

    if (!result.success) {
      throw new Error("Authentication failed");
    }

    // Retrieve the private key
    const privateKeyStr = await SecureStore.getItemAsync(
      "baby_jubjub_private_key"
    );

    if (!privateKeyStr) {
      throw new Error("Private key not found");
    }

    // Convert string back to BigInt
    return Uint8Array.from(Buffer.from(privateKeyStr, "hex"));
  } catch (error) {
    console.error("Error retrieving private key:", error);
    throw error;
  }
};

export default function BabyJubJubDemo() {
  const [status, setStatus] = useState("");

  const handleDemo = async () => {
    try {
      // Generate new private key
      setStatus("Generating private key...");
      const privateKey = await generatePrivateKey();

      // Generate public key
      setStatus("Deriving public key...");
      const publicKey = derivePublicKey(privateKey);

      // Store private key securely
      setStatus("Storing private key securely...");
      await securelyStorePrivateKey(privateKey);

      const retrievedPrivateKey = await retrievePrivateKey();

      // Sign message
      setStatus("Signing message...");
      const message = "hello world";
      const signature = signMessage(retrievedPrivateKey, message);

      // Verify signature
      setStatus("Verifying signature...");
      const isValid = verifySignature(message, signature, publicKey);

      setStatus(
        `Success! Signature valid: ${isValid}\nSignature: [${signature.R8}, ${signature.S}]`
      );
    } catch (error) {
      setStatus(`Error: ${(error as any).message}`);
    }
  };

  return (
    <View
      style={{
        flex: 1,
        justifyContent: "center",
        alignItems: "center",
        backgroundColor: "black",
      }}
    >
      <Button title="Run Demo" onPress={handleDemo} />
      <Text style={{ marginTop: 20, color: "white" }}>{status}</Text>
    </View>
  );
}
