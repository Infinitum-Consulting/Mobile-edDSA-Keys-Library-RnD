import React from 'react';
import { View, Button, Text, StyleSheet } from 'react-native';
import { generateAndStoreKeys, retrieveKeys, deleteKeys } from './services/KeychainService';
import 'react-native-get-random-values';


const App = () => {
  const handleGenerateKeys = async () => {
    await generateAndStoreKeys();
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

  return (
    <View style={styles.container}>
      <Text style={styles.title}>ED25519 Key Management</Text>
      <Button title="Generate & Store Keys" onPress={handleGenerateKeys} />
      <Button title="Retrieve Keys" onPress={handleRetrieveKeys} />
      <Button title="Delete Keys" onPress={handleDeleteKeys} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  title: {
    fontSize: 20,
    marginBottom: 10,
  },
});

export default App;
