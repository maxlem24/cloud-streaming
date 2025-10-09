package com.cloud_signature.signature;

import java.io.Serializable;

import it.unisa.dia.gas.jpbc.Element;

public class DelegationKeyPair implements Serializable {
    private Element dk_d;
    private Element pk_d;

    public DelegationKeyPair(Element dk_d, Element pk_d) {
        this.dk_d = dk_d;
        this.pk_d = pk_d;
    }

    public Element getDk_d() {
        return dk_d;
    }

    public Element getPk_d() {
        return pk_d;
    }

}
