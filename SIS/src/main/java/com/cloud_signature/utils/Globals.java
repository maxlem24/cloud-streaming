package com.cloud_signature.utils;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.ejml.simple.SimpleMatrix;

import com.cloud_signature.signature.Gen_seed;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Pairing;
import it.unisa.dia.gas.plaf.jpbc.pairing.PairingFactory;

public class Globals {
    public static Pairing pairing = PairingFactory.getPairing("curves\\a.properties");
    public static int l = 64;
    public static int m = 1536;
    public static int n = 8;
    public static int q = 4099;
    public static Element p = pairing.getG1().newRandomElement();

    public final static Element h1(byte[] data) throws NoSuchAlgorithmException {
        MessageDigest md = MessageDigest.getInstance("SHA-512");
        byte[] hash = md.digest(data);
        Element hash_G1 = pairing.getG1().newElementFromHash(hash, 0, hash.length);
        return hash_G1;
    }

    public final static Element h2(byte[] data) throws NoSuchAlgorithmException {
        MessageDigest md = MessageDigest.getInstance("SHA-512");
        byte[] hash = md.digest(data);
        Element hash_Zn = pairing.getZr().newElementFromHash(hash, 0, hash.length);
        return hash_Zn;
    }

    public final static byte[] h3(byte[] data) throws NoSuchAlgorithmException {
        MessageDigest md = MessageDigest.getInstance("SHA-512");
        byte[] hash = md.digest(data);
        return hash;
    }

    public final static SimpleMatrix getV(Gen_seed seed, byte[] data) throws NoSuchAlgorithmException {
        SimpleMatrix a = new SimpleMatrix(l, m);
        PRNG gen = new PRNG(seed, q);
        for (int i = 0; i < l; i++) {
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
            byte[] h_i = h3(d_i);
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
                v.set(i, j, v.get(i, j) % q);
            }
        }

        return v;
    }
}