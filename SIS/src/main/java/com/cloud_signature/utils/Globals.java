package com.cloud_signature.utils;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.bouncycastle.jce.provider.JDKDSASigner.stdDSA;
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
    public static Element p = pairing.getG1().newElementFromBytes("Clément et Maxime à 2h de mat".getBytes());

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

    public final static byte[][] split_data(byte[] data) {
        int data_block_size = data.length / n;
        byte[][] splited_data = new byte[n][];
        for (int i = 0; i < n - 1; i++) {
            byte[] d_i = new byte[data_block_size];
            for (int bit_i = 0; bit_i < data_block_size; bit_i++) {
                d_i[bit_i] = data[i * data_block_size + bit_i];
            }
            splited_data[i] = d_i;
        }
        byte[] d_n_1 = new byte[data.length - (n - 1) * data_block_size];
        for (int bit_i = 0; bit_i < data.length - (n - 1) * data_block_size; bit_i++) {
            d_n_1[bit_i] = data[(n - 1) * data_block_size + bit_i];
        }
        splited_data[n - 1] = d_n_1;
        return splited_data;
    }

    public final static SimpleMatrix genA(Gen_seed seed) {
        SimpleMatrix a = new SimpleMatrix(l, m);
        PRNG gen = new PRNG(seed, q);
        for (int i = 0; i < l; i++) {
            for (int j = 0; j < m; j++) {
                a.set(i, j, gen.getNext());
            }
        }
        return a;
    }

    public final static SimpleMatrix calcV(Gen_seed seed, byte[] data) throws NoSuchAlgorithmException {
        SimpleMatrix a = genA(seed);
        SimpleMatrix x = new SimpleMatrix(m, n);
        byte[][] splited_data = split_data(data);
        int hash_size = 512;

        for (int i = 0; i < n; i++) {
            byte[] h_i = h3(splited_data[i]);
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

    public final static SimpleMatrix calcVi(Gen_seed seed, byte[] d_i) throws NoSuchAlgorithmException {
        SimpleMatrix a = genA(seed);
        SimpleMatrix x = new SimpleMatrix(m, 1);
        int hash_size = 512;

        byte[] h_i = h3(d_i);
        BigInteger no = new BigInteger(1, h_i);
        String hashtext = no.toString(2);

        while (hashtext.length() < hash_size) {
            hashtext = "0" + hashtext;
        }

        byte[] hash_byte = hashtext.getBytes();
        for (int j = 0; j < m; j++) {
            x.set(j, 0, hash_byte[j % hash_size] == '0' ? 0 : 1);
        }

        SimpleMatrix v_i = a.mult(x);
        for (int i = 0; i < v_i.getNumRows(); i++) {
            v_i.set(i, 0, v_i.get(i, 0) % q);
        }

        return v_i;
    }

    public final static String matrixToString(SimpleMatrix m) {
        String outputString = m.getNumRows() + " " + m.getNumCols();
        for (int i = 0; i < m.getNumRows(); i++) {
            for (int j = 0; j < m.getNumCols(); j++) {
                outputString += " " + (int) m.get(i, j);
            }
        }
        return outputString;
    }

    public final static SimpleMatrix matrixFromString(String s) {
        String[] parts = s.split(" ");

        int rows = Integer.parseInt(parts[0]);
        int cols = Integer.parseInt(parts[1]);

        SimpleMatrix res = new SimpleMatrix(rows, cols);

        for (int i = 0; i < rows; i++)
            for (int j = 0; j < cols; j++)
                res.set(i, j, Integer.parseInt(parts[2 + i * cols + j]));

        return res;
    }
}