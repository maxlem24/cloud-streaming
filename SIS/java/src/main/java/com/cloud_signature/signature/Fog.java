package com.cloud_signature.signature;

public class Fog {

}

// fn integrity_check(
//     param_a: [i64; 3],
//     id_w: i64,
//     v: i64,
//     sign: [i64; 2],
//     index: i64,
//     d_i: i64,
//     pk_v: i64,
// ) {
//     // x_prime_i = [for j in 0...m (h3(d_i)]
//     // A = for i in 0...l( for j in 0...m(generator.next()))

//     // v_prime_i = (A * x_prime_i) % q

//     // v_prime = for i in 0...n ( if i == index {v_prime_i} else {v[i]})

//     // pk_prime = pk_v + pk_s

//     // r_prime = e(w2,P).e(h1(id_w),−pk_prime)**w1

//     // if h2(v_prime,param_a,r_prime) == w_1 { return true}
// }
