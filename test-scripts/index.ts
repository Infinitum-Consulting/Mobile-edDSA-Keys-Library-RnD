import { Keypair } from "maci-domainobjs";

const key = new Keypair();

console.log(key.pubKey.serialize());

console.log("Hello via Bun!");
