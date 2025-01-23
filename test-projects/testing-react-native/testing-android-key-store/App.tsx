import React from 'react';
import {  Button, Text, StyleSheet, ScrollView } from 'react-native';
import { generateAndStoreED25519Keys, generateAndStoreJubJubKeys, retrieveKeys, deleteKeys, rotateKeys } from './services/KeychainService';
import 'react-native-get-random-values';

const App = () => {
  // ED25519 Actions
  const handleGenerateED25519Keys = async () => {
    await generateAndStoreED25519Keys();
  };

  // JubJub Actions
  const handleGenerateJubJubKeys = async () => {
    await generateAndStoreJubJubKeys();
  };

  const handleRetrieveKeys = async () => {
    const keys = await retrieveKeys();
    if (keys) {
      console.log('Public Key:', keys.publicKey);
      console.log('Private Key:', keys.privateKey);
    }
  };

  const handleDeleteKeys = async () => {
    await deleteKeys();
  };

  const handleRotateKeys = async () => {
    await rotateKeys();
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Key Management with ED25519 and JubJub</Text>

      <Text style={styles.subtitle}>ED25519 Keys</Text>
      <Button title="Generate & Store ED25519 Keys" onPress={handleGenerateED25519Keys} />
      <Text style={styles.subtitle}>BabyJubJub Keys</Text>
      <Button title="Generate & Store BabyJubJub Keys" onPress={handleGenerateJubJubKeys} />
      
      <Text style={styles.subtitle}>Common Actions</Text>
      <Button title="Retrieve Keys" onPress={handleRetrieveKeys} />
      <Button title="Rotate Keys" onPress={handleRotateKeys} />
      <Button title="Delete Keys" onPress={handleDeleteKeys} />
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  title: {
    fontSize: 22,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 18,
    marginTop: 20,
    marginBottom: 10,
    fontWeight: '600',
  },
});

export default App;
