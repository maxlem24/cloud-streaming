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

    public Owner(IdentificationServer server, byte[] id_w) throws NoSuchAlgorithmException {
        this.id_w = id_w;
        this.keys = server.verify_identity(id_w);
    }

    public void connect_new_IS(IdentificationServer new_server) throws NoSuchAlgorithmException {
        KeyPair new_keys = new_server.verify_identity(id_w);
        this.keys.add(new_keys);
    }

    public Signed_Data share_data(byte[] data) throws NoSuchAlgorithmException {
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
        SimpleMatrix x = new SimpleMatrix(m, n);
        int data_block_size = data.length / n;

        int hash_size = 512;
        for (int i = 0; i < n; i++) {
            byte[] d_i = new byte[data_block_size];
            for (int bit_i = 0; bit_i < data_block_size; bit_i++) {
                d_i[bit_i] = data[i * data_block_size + bit_i];
            }
            byte[] h_i = Globals.h3(d_i);
            BigInteger no = new BigInteger(1, h_i);
            String hashtext = no.toString(2);

            while (hashtext.length() < hash_size) {
                hashtext = "0" + hashtext;
            }
            byte[] hash_byte = hashtext.getBytes();
            for (int j = 0; j < m; j++) {
                x.set(j, i, hash_byte[j % hash_size] == '0' ? 0 : 1);
            }
        }
        SimpleMatrix v = a.mult(x);
        for (int i = 0; i < v.getNumRows(); i++) {
            for (int j = 0; j < v.getNumCols(); j++) {
                v.set(i, j, v.get(i, j) % Globals.q);
            }
        }

        Pairing pairing = Globals.pairing;
        Element p = Globals.p.duplicate();

        Element p_1 = pairing.getG1().newRandomElement();
        Element k = pairing.getZr().newRandomElement();

        Element r = pairing.pairing(p, p_1).mulZn(k);
        Sign_params params = new Sign_params(v, seed, r);
        byte[] params_bytes = params.toString().getBytes();
        Element w_1 = Globals.h2(params_bytes);
        Element w_2 = keys.getS_w().duplicate().mulZn(w_1).add(p_1.duplicate().mulZn(k));

        Signature sign = new Signature(w_1, w_2);
        return new Signed_Data(seed, id_w, v, sign, data, keys.getP_k());

    }

    

}
