import { Keypair, VerifyingKey } from "maci-domainobjs";
import { verifySignature } from "@zk-kit/eddsa-poseidon";

verifySignature("Hello", "", "");

const key = new Keypair();

console.log(key.pubKey.serialize());

console.log("Hello via Bun!");
