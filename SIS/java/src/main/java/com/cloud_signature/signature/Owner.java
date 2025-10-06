package com.cloud_signature.signature;

public class Owner{

} 

// pub struct Owner {
//     pub id_w: i64, //Identity
//     pub s_w: i64,  //Secret Key, can be null if first connection
//     pub pk: i64,   //Public keys of visited zones
// }

// fn identification() {
//     // Send Identity ID_w to zone S and receive S_w_s adn Pk_s

//     // Compute the secret and the public key

//     // if S_w == null { S_w = S_w_s} else {S_w = S_w + S_w_s}
//     // if PK == null { PK = PK_s} else {pk_v = pk; pk = PK_v + PK_s}
// }

// fn data_sharing(data: i64) {
//     // Split data d_0...d_n

//     // Choose I_0, C_0, a, q
//     // param_A = (I_0, a, C_0)

//     // A = for i in 0...n( for j in 0...m(generator.next()))

//     // X = for i in 0...n( for j in 0...m(H3(d_i)))

//     // V = A * X mod q

//     // Signature

//     // P_1 = random(G_0)
//     // k = random(Z_p)
//     // r = e(P,P_1)**k
//     // w_1 = H2(V,param_A,r)
//     // w_2 = w_1*S_w + k*P1
//     // sign = (w_1,w_2)

//     // Publish param_a, id_w, v, sign,i,  d_i, pk_v across fog
// }
