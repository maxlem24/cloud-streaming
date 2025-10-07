package com.cloud_signature.signature;

import java.io.Serializable;

import it.unisa.dia.gas.jpbc.Element;

public class KeyPair implements Serializable {
    private Element s_w;
    private Element p_k;

    public KeyPair(Element s_w, Element p_k) {
        this.s_w = s_w;
        this.p_k = p_k;
    }

    public Element getS_w() {
        return s_w;
    }

    public Element getP_k() {
        return p_k;
    }

    public void add(KeyPair k_p) {
        this.s_w = this.s_w.add(k_p.getS_w());
        this.p_k = this.p_k.add(k_p.getP_k());
    }

}
