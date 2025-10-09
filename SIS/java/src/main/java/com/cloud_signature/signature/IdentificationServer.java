package com.cloud_signature.signature;

import java.security.NoSuchAlgorithmException;

import com.cloud_signature.Globals;

import it.unisa.dia.gas.jpbc.Element;

public class IdentificationServer {
    private Element ts;
    private Element pk_s;

    public IdentificationServer() {
        this.ts = Globals.pairing.getZr().newRandomElement();
        this.pk_s = Globals.p.duplicate().mulZn(ts);
    }

    public KeyPair verify_identity(byte[] id_w) throws NoSuchAlgorithmException {
        Element h1_id_w = Globals.h1(id_w);
        Element s_sw = h1_id_w.mulZn(ts);
        return new KeyPair(s_sw, pk_s);
    }

    public Element getPk_s() {
        return pk_s;
    }

}