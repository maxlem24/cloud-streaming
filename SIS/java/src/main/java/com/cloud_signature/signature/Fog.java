package com.cloud_signature.signature;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.ejml.simple.SimpleMatrix;

import com.cloud_signature.Globals;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Pairing;

public class Fog {
    private Element pk_s;

    public Fog(IdentificationServer server) {
        this.pk_s = server.getPk_s();
    }

    public boolean verify_signature(Signed_Data signed_data) throws NoSuchAlgorithmException {
        int l = Globals.size_l;
        int m = Globals.size_m;
        int n = Globals.size_n;
        SimpleMatrix a = new SimpleMatrix(l, m);
        PRNG gen = new PRNG(signed_data.getParamA(), Globals.q);
        for (int i = 0; i < Globals.size_l; i++) {
            for (int j = 0; j < m; j++) {
                a.set(i, j, gen.getNext());
            }
        }

        byte[] data = signed_data.getData();
        SimpleMatrix x_prime = new SimpleMatrix(m, n);
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
                x_prime.set(j, i, hash_byte[j % hash_size] == '0' ? 0 : 1);
            }
        }

        SimpleMatrix v_prime = a.mult(x_prime);
        for (int i = 0; i < v_prime.getNumRows(); i++) {
            for (int j = 0; j < v_prime.getNumCols(); j++) {
                v_prime.set(i, j, v_prime.get(i, j) % Globals.q);
            }
        }

        Pairing pairing = Globals.pairing;
        Element p = Globals.p.duplicate();

        Element pk_prime = signed_data.getPk_v().duplicate();
        Element r_prime_left = pairing.pairing(signed_data.getSign().getW_2().duplicate(), p.duplicate());
        Element r_prime_right = pairing
                .pairing(Globals.h1(signed_data.getId_w()), pk_prime.negate())
                .mulZn(signed_data.getSign().getW_1());
        Element r_prime = r_prime_left.mul(r_prime_right);

        Sign_params params = new Sign_params(v_prime, signed_data.getParamA(), r_prime);
        byte[] params_bytes = params.toString().getBytes();

        Element w_1_prime = Globals.h2(params_bytes);
        return w_1_prime.isEqual(signed_data.getSign().getW_1());
    }

}
