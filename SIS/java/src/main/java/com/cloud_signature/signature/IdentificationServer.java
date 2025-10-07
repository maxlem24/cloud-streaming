package com.cloud_signature.signature;

import com.cloud_signature.Globals;

import it.unisa.dia.gas.jpbc.Element;

public class IdentificationServer {
    private Element ts;
    private Element pk_s;

    public IdentificationServer() {
        this.ts = Globals.pairing.getZr().newRandomElement();
        this.pk_s = Globals.p.duplicate().mulZn(ts);
    }

    public KeyPair verify_identity(byte[] id_w) {
        Element s_sw = Globals.pairing.getG1().newElementFromHash(id_w, 0, id_w.length).mulZn(this.ts);
        return new KeyPair(s_sw, pk_s);
    }

    public Element getPk_s() {
        return pk_s;
    }

}