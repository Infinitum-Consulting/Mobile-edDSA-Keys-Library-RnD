import { Keypair, VerifyingKey, PubKey } from "maci-domainobjs";
import { verifySignature } from "@zk-kit/eddsa-poseidon";

const pubKey = PubKey.deserialize(
  "macipk.7047f0637202d9edcc24d9ddfcb7a2abbd951e1d1f12e066289b5edf33cd3f3c"
  // "macipk.0f217d6d048a38d0e7ccbc17dc7cea1d2c5b9e91928184c4e7b084a873253036"
);

console.log(pubKey);

// verifySignature("Hello", "", pubKey);

const key = new Keypair();

console.log(key.pubKey.serialize());

console.log("Hello via Bun!");
