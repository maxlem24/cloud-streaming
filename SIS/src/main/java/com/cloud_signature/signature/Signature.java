package com.cloud_signature.signature;

import it.unisa.dia.gas.jpbc.Element;

public class Signature {
    private Element w_1;
    private Element w_2;

    public Signature(Element w_1, Element w_2) {
        this.w_1 = w_1;
        this.w_2 = w_2;
    }

    public Element getW_1() {
        return w_1;
    }

    public Element getW_2() {
        return w_2;
    }

    @Override
    public String toString() {
        return String.format("(w1 = %s | w2 = %s)", w_1.toString(), w_2.toString());
    }
}
