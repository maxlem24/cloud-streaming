// https://github.com/RustCrypto/elliptic-curves
// cargo add bls12_381
mod client;
mod fog;
mod generator;
mod owner;


use pairings::{engines};

// use bn::*;
// use pairings::{curves::g2, tools::arithmetic_interface::ArithmeticOperations, Bls12Curves, Pairings, PairingsEngine, BLS12};
// use rand_cor

fn main() {
    let mut g = generator::Generator::new(1, 2, 10, 2);

    for _ in 1..100 {
        let k = g.next().unwrap();
        println!("{:?}", k);
    }

    let engine = engines::bls12_381_engine();

    let p = engine.g1.random_point();

    /* Identification */
    // 1. Le serveur reçoit l'identité du owner
    let id_w = "Hello";

    // 2. Le serveur génère une clé publique et privée

    let ts = engine.fr.random_element();
    // let pk_s = p.multiply(&ts); // Serveur pubkey

    let pk_s = p * ts; // Server pubkey

    let s_sw =  ts * engine.g1.hash_to_field(id_w, 0); // Server privkey

    println!("{}", pk_s.to_string());
    println!("{}", s_sw.to_string());

    // TODO: 3. Le serveur envoie s_sw au owner de manière sécurisée
    // TODO: 4/5. mettre à jour la clé secrete du owner en fonction de la clé du serveur

    /* Signature */
    // 1. Choose random P1 in G1 and k in Zp
    let p_1 = engine.g2.random_point_trys();
    let k = engine.fr.random_element();

    // let p_1 = engine.g1.random_point();
    // let k = engine.fr.random_element();

    // 2. Compute r = e(P, P1)^k
    // let r = engine.paire(&p, p_1);

    // let w_1 = F::random(&mut rng);
    // let w_2 = s_sw * w_1 + p_1 * k;

    // let r = engine.paire(&p, &p_1);
    // let w_1 = engine.fr.random_element(); // TODO change
    // let w_2 = s_sw.multiply(&w_1).addto(&p_1.multiply(&k));

    // Two multiplicative cyclic groups of prime order r:
    // G0 ≅ G1 ≅ <r>, with generators P in G0 and Q in G1.
    // let P: G1Projective = G1Projective(); // generator of G0
    // let Q: G2Projective = G2Projective::generator(); // generator of G1

    // // Convert a list of bytes to a point in G1
    // let msg = b"hello world";
    // let dst = b"BLS12381G1_XMD:SHA-256_SSWU_RO_";
    // // let P_hash: G1Projective = HashToCurve::<G1Projective>::hash_to_curve(msg, dst);
    // G1Projective::from(value)
    // println!("Hashed point in G1: {:?}", P_hash);

    // Random exponents (mod r)
    // let a = Scalar::random(&mut OsRng);
    // let b = Scalar::random(&mut OsRng);

    // "Exponentiation" in source groups is scalar multiplication on the curve
    // let aP = a * P;
    // let bQ = b * Q;

    // Bilinear map e: G0 × G1 → GT (multiplicative target group)
    // let e_ab: Gt = pairing(&P, &Q);

    // // Optional: serialize generators
    // let p_bytes = P.to_affine().to_compressed();
    // let q_bytes = Q.to_affine().to_compressed();
    // println!("P in G0 (compressed): {:02x?}", p_bytes);
    // println!("Q in G1 (compressed): {:02x?}", q_bytes);
    // println!("e(aP, bQ) in GT: {:?}", e_ab);
}
