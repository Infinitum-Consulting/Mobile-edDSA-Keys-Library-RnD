//fun main() {
//    val keyGenerator = Ed25519KeyGenerator()
//    val keyPair = keyGenerator.generateKeyPair()
//
//    println("Private key (Base64): ${Base64.getEncoder().encodeToString(keyPair.privateKey)}")
//    println("Public key (Base64): ${Base64.getEncoder().encodeToString(keyPair.publicKey)}")
//}

fun main() {
    val generator = BabyJubjubKeyGenerator()
    val keyPair = generator.generateKeyPair()

    println("BabyJubjub Key Pair Generated:")
    println("Private Key: ${keyPair.privateKey}")
    println("Public Key X: ${keyPair.publicKey.x}")
    println("Public Key Y: ${keyPair.publicKey.y}")
}

//import java.security.KeyPair
//import java.security.KeyPairGenerator
//
//fun generateEd25519KeysBase64(): Pair<String, String> {
//    // Generate key pair
//    val keyPairGenerator = KeyPairGenerator.getInstance("Ed25519")
//    val keyPair: KeyPair = keyPairGenerator.generateKeyPair()
//
//    // Encode keys to Base64
//    val publicKeyBase64 = java.util.Base64.getEncoder().encodeToString(keyPair.public.encoded)
//    val privateKeyBase64 = java.util.Base64.getEncoder().encodeToString(keyPair.private.encoded)
//
//    return Pair(publicKeyBase64, privateKeyBase64)
//}
//
//fun main() {
//    val (publicKeyBase64, privateKeyBase64) = generateEd25519KeysBase64()
//
//    println("Public Key (Base64): $publicKeyBase64")
//    println("Private Key (Base64): $privateKeyBase64")
//}
