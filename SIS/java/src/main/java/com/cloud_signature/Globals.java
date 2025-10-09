package com.cloud_signature;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Pairing;
import it.unisa.dia.gas.plaf.jpbc.pairing.PairingFactory;

public class Globals {
    public static Pairing pairing = PairingFactory.getPairing("curves\\a.properties");
    public static int size_l = 64;
    public static int size_m = 1536;
    public static int size_n = 8;
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
}