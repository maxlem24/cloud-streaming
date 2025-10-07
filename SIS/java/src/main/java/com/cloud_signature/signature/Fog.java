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

    public boolean verify_signature(Signed_Data signed_data) {
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

        try {
            byte[] data = signed_data.getData();
            SimpleMatrix x_prime = new SimpleMatrix(m, n);
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
                    x_prime.set(j, i, hash_byte[j % hash_size] == '0' ? 0 : 1);
                }
            }
            SimpleMatrix v_prime = a.mult(x_prime);
            Pairing pairing = Globals.pairing;
            Element p = Globals.p.duplicate();

            Element pk_prime = signed_data.getPk_v().duplicate().add(this.pk_s);
            Element r_prime_left = pairing.pairing(signed_data.getSign().getW_2().duplicate(), p.duplicate());
            Element r_prime_right = pairing
                    .pairing(pairing.getG1().newElementFromHash(signed_data.getId_w(), 0, signed_data.getId_w().length),
                            pk_prime.negate())
                    .mulZn(signed_data.getSign().getW_1());
            Element r_prime = r_prime_left.mul(r_prime_right);
            Sign_params params = new Sign_params(signed_data.getParamA(), r_prime, v_prime);
            System.out.println(params);
            byte[] params_bytes = params.toString().getBytes();
            Element w_1_prime = pairing.getZr().newElementFromHash(params_bytes, 0, params_bytes.length);
            return w_1_prime.isEqual(signed_data.getSign().getW_1());

        } catch (NoSuchAlgorithmException ex) {
            System.err.println(ex);
        }
        return false;
    }

}
