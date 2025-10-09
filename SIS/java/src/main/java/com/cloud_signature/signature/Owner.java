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

    public DelegationKeyPair create_delegation(byte[] id_d) throws NoSuchAlgorithmException {
        Element y = Globals.pairing.getZr().newRandomElement();
        Element pk_d = Globals.p.duplicate().mulZn(y);
        Element dk_d = keys.getS_w().duplicate().add(Globals.h1(id_d).mulZn(y));
        return new DelegationKeyPair(dk_d, pk_d);
    }

    public Signed_Data share_data(byte[] data) throws NoSuchAlgorithmException {
        Gen_seed seed = new Gen_seed();
        SimpleMatrix v = Globals.getV(seed, data);

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

    public byte[] getId_w() {
        return id_w;
    }

    public Element getP_k() {
        return keys.getP_k();
    }
}
