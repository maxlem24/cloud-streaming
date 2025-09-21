// https://github.com/RustCrypto/elliptic-curves
// cargo add bls12_381
mod generator;
mod client;
mod fog;
mod owner;

use bls12_381::{G1Projective, G2Projective, Gt, Scalar, pairing};
use rand_core::OsRng;

fn main() {
    let mut g = generator::Generator::new(1, 2, 10, 2);

    for _ in 1..100 {
        let k = g.next().unwrap();
        println!("{:?}", k);
    }

    // Two multiplicative cyclic groups of prime order r:
    // G0 ≅ G1 ≅ <r>, with generators P in G0 and Q in G1.
    let P: G1Projective = G1Projective::generator(); // generator of G0
    let Q: G2Projective = G2Projective::generator(); // generator of G1

    // Random exponents (mod r)
    // let a = Scalar::random(&mut OsRng);
    // let b = Scalar::random(&mut OsRng);

    // "Exponentiation" in source groups is scalar multiplication on the curve
    // let aP = a * P;
    // let bQ = b * Q;

    // Bilinear map e: G0 × G1 → GT (multiplicative target group)
    let e_ab: Gt = pairing(&P, &Q);

    // Optional: serialize generators
    let p_bytes = P.to_affine().to_compressed();
    let q_bytes = Q.to_affine().to_compressed();
    println!("P in G0 (compressed): {:02x?}", p_bytes);
    println!("Q in G1 (compressed): {:02x?}", q_bytes);
    println!("e(aP, bQ) in GT: {:?}", e_ab);
}
