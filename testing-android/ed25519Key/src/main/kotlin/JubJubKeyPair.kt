import java.math.BigInteger
import java.security.SecureRandom
import kotlin.math.pow

/**
 * Generator for BabyJubjub keys, using the twisted Edwards curve
 * a * x^2 + y^2 = 1 + d * x^2 * y^2
 * where:
 * a = 168700
 * d = 168696
 */
class BabyJubjubKeyGenerator {
    companion object {
        // BabyJubjub curve parameters
        private val PRIME = BigInteger("21888242871839275222246405745257275088548364400416034343698204186575808495617")
        private val SUB_ORDER = BigInteger("2736030358979909402780800718157159386076813972158567259200215660948447373041")
        private val CURVE_ORDER = PRIME.subtract(BigInteger.ONE)

        // Base point coordinates
        private val BASE_POINT_X = BigInteger("17777552123799933955779906779655732241715742912184938656739573121738514868268")
        private val BASE_POINT_Y = BigInteger("2626589144620713026669568689430873010625803728049924121243784502389097019475")
    }

    /**
     * Represents a point on the BabyJubjub curve
     */
    data class Point(val x: BigInteger, val y: BigInteger)

    /**
     * Represents a BabyJubjub key pair
     */
    data class KeyPair(
        val privateKey: BigInteger,
        val publicKey: Point
    )

    /**
     * Generates a new BabyJubjub key pair
     */
    fun generateKeyPair(): KeyPair {
        // Generate private key
        val privateKey = generatePrivateKey()

        // Calculate public key by multiplying base point with private key
        val publicKey = scalarMult(Point(BASE_POINT_X, BASE_POINT_Y), privateKey)

        return KeyPair(privateKey, publicKey)
    }

    /**
     * Generates a random private key within the valid range
     */
    private fun generatePrivateKey(): BigInteger {
        val random = SecureRandom()
        var privateKey: BigInteger

        do {
            val bytes = ByteArray(32)
            random.nextBytes(bytes)
            privateKey = BigInteger(1, bytes).mod(SUB_ORDER)
        } while (privateKey == BigInteger.ZERO)

        return privateKey
    }

    /**
     * Performs scalar multiplication of a point on the curve
     */
    private fun scalarMult(point: Point, scalar: BigInteger): Point {
        var result = Point(BigInteger.ZERO, BigInteger.ONE)
        var temp = point
        var n = scalar

        while (n > BigInteger.ZERO) {
            if (n.and(BigInteger.ONE) == BigInteger.ONE) {
                result = addPoints(result, temp)
            }
            temp = addPoints(temp, temp)
            n = n.shiftRight(1)
        }

        return result
    }

    /**
     * Adds two points on the BabyJubjub curve
     */
    private fun addPoints(p1: Point, p2: Point): Point {
        val x1 = p1.x
        val y1 = p1.y
        val x2 = p2.x
        val y2 = p2.y

        // BabyJubjub curve parameters
        val a = BigInteger("168700")
        val d = BigInteger("168696")

        // Point addition formulas for twisted Edwards curves
        val x3Num = (x1.multiply(y2).add(y1.multiply(x2))).mod(PRIME)
        val x3Den = (BigInteger.ONE.add(d.multiply(x1).multiply(x2).multiply(y1).multiply(y2))).mod(PRIME)
        val y3Num = (y1.multiply(y2).subtract(a.multiply(x1).multiply(x2))).mod(PRIME)
        val y3Den = (BigInteger.ONE.subtract(d.multiply(x1).multiply(x2).multiply(y1).multiply(y2))).mod(PRIME)

        val x3 = x3Num.multiply(x3Den.modInverse(PRIME)).mod(PRIME)
        val y3 = y3Num.multiply(y3Den.modInverse(PRIME)).mod(PRIME)

        return Point(x3, y3)
    }
}