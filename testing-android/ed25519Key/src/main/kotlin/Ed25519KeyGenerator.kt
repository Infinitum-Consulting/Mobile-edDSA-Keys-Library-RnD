import org.bouncycastle.asn1.pkcs.PrivateKeyInfo
import org.bouncycastle.asn1.x509.SubjectPublicKeyInfo
import org.bouncycastle.crypto.AsymmetricCipherKeyPair
import org.bouncycastle.crypto.generators.Ed25519KeyPairGenerator
import org.bouncycastle.crypto.params.Ed25519KeyGenerationParameters
import org.bouncycastle.crypto.params.Ed25519PrivateKeyParameters
import org.bouncycastle.crypto.params.Ed25519PublicKeyParameters
import org.bouncycastle.crypto.util.PrivateKeyInfoFactory
import org.bouncycastle.crypto.util.SubjectPublicKeyInfoFactory
import java.security.SecureRandom

class Ed25519KeyGenerator {
    fun generateKeyPair(): KeyPair {
        // Initialize the key pair generator
        val keyPairGenerator = Ed25519KeyPairGenerator()
        keyPairGenerator.init(Ed25519KeyGenerationParameters(SecureRandom()))

        // Generate the key pair
        val keyPair: AsymmetricCipherKeyPair = keyPairGenerator.generateKeyPair()

        // Get the private and public key parameters
        val privateKey = keyPair.private as Ed25519PrivateKeyParameters
        val publicKey = keyPair.public as Ed25519PublicKeyParameters

        // Convert to standard formats
        val privateKeyInfo: PrivateKeyInfo = PrivateKeyInfoFactory.createPrivateKeyInfo(privateKey)
        val publicKeyInfo: SubjectPublicKeyInfo = SubjectPublicKeyInfoFactory.createSubjectPublicKeyInfo(publicKey)

        // Get the encoded keys
        val privateKeyEncoded = privateKeyInfo.encoded
        val publicKeyEncoded = publicKeyInfo.encoded

        return KeyPair(
            privateKey = privateKeyEncoded,
            publicKey = publicKeyEncoded
        )
    }

    data class KeyPair(
        val privateKey: ByteArray,
        val publicKey: ByteArray
    ) {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (javaClass != other?.javaClass) return false

            other as KeyPair

            if (!privateKey.contentEquals(other.privateKey)) return false
            if (!publicKey.contentEquals(other.publicKey)) return false

            return true
        }

        override fun hashCode(): Int {
            var result = privateKey.contentHashCode()
            result = 31 * result + publicKey.contentHashCode()
            return result
        }
    }
}