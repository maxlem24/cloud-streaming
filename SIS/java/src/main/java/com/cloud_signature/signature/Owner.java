package com.cloud_signature.signature;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.ejml.simple.SimpleMatrix;

import com.cloud_signature.Globals;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Pairing;

public class Owner {
    private KeyPair keys;
    private byte[] id_w;

    public Owner(IdentificationServer server, byte[] id_w) {
        this.id_w = id_w;
        this.keys = server.verify_identity(id_w);
    }

    public void connect_new_IS(IdentificationServer new_server) {
        KeyPair new_keys = new_server.verify_identity(id_w);
        this.keys.add(new_keys);
    }

    public Signed_Data share_data(byte[] data) {
        int l = Globals.size_l;
        int m = Globals.size_m;
        int n = Globals.size_n;
        SimpleMatrix a = new SimpleMatrix(l, m);
        Gen_seed seed = new Gen_seed(15, 2, 4);
        PRNG gen = new PRNG(seed, Globals.q);
        for (int i = 0; i < Globals.size_l; i++) {
            for (int j = 0; j < m; j++) {
                a.set(i, j, gen.getNext());
            }
        }
        try {
            SimpleMatrix x = new SimpleMatrix(m, n);
            int data_block_size = data.length / n;

            MessageDigest md = MessageDigest.getInstance("SHA-512");
            int hash_size = 512;
            for (int i = 0; i < n; i++) {
                byte[] d_i = new byte[data_block_size];
                for (int bit_i = 0; bit_i < data_block_size; bit_i++) {
                    d_i[bit_i] = data[i * data_block_size + bit_i];
                }
                byte[] h_i = md.digest(d_i);
                BigInteger no = new BigInteger(1, h_i);
                String hashtext = no.toString(2);

                while (hashtext.length() < 512) {
                    hashtext = "0" + hashtext;
                }
                byte[] hash_byte = hashtext.getBytes();
                for (int j = 0; j < m; j++) {
                    x.set(j, i, hash_byte[j % hash_size] == '0' ? 0 : 1);
                }
            }
            SimpleMatrix v = a.mult(x);

            Pairing pairing = Globals.pairing;
            Element p = Globals.p.duplicate();

            Element p_1 = pairing.getG1().newRandomElement();
            Element k = pairing.getZr().newRandomElement();

            Element r = pairing.pairing(p, p_1).mulZn(k);
            Sign_params params = new Sign_params(seed, r, v);
            System.out.println(params);
            byte[] params_bytes = params.toString().getBytes();
            Element w_1 = pairing.getZr().newElementFromHash(params_bytes, 0, params_bytes.length);
            Element w_2 = keys.getS_w().duplicate().mulZn(w_1).add(p_1.duplicate().mulZn(k));

            Signature sign = new Signature(w_1, w_2);
            return new Signed_Data(seed, id_w, v, sign, data, keys.getP_k());

        } catch (NoSuchAlgorithmException ex) {
            System.err.println(ex);
        }
        return null;
    }

}

// pub struct Owner {
// pub id_w: i64, //Identity
// pub s_w: i64, //Secret Key, can be null if first connection
// pub pk: i64, //Public keys of visited zones
// }

// fn identification() {
// // Send Identity ID_w to zone S and receive S_w_s adn Pk_s

// // Compute the secret and the public key

// // if S_w == null { S_w = S_w_s} else {S_w = S_w + S_w_s}
// // if PK == null { PK = PK_s} else {pk_v = pk; pk = PK_v + PK_s}
// }

// fn data_sharing(data: i64) {
// // Split data d_0...d_n

// // Choose I_0, C_0, a, q
// // param_A = (I_0, a, C_0)

// // A = for i in 0...n( for j in 0...m(generator.next()))

// // X = for i in 0...n( for j in 0...m(H3(d_i)))

// // V = A * X mod q

// // Signature

// // P_1 = random(G_0)
// // k = random(Z_p)
// // r = e(P,P_1)**k
// // w_1 = H2(V,param_A,r)
// // w_2 = w_1*S_w + k*P1
// // sign = (w_1,w_2)

// // Publish param_a, id_w, v, sign,i, d_i, pk_v across fog
// }
