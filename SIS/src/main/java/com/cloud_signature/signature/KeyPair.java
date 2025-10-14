package com.cloud_signature.signature;

import java.io.Serializable;

import it.unisa.dia.gas.jpbc.Element;

import java.util.Base64;
import java.util.Base64.Encoder;
import java.util.Base64.Decoder;

import com.cloud_signature.utils.Globals;


// Paire de clés secrète (s_w) et publique (p_k) basées sur une identité
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

    @Override
    public String toString() {
        Encoder encoder = Base64.getEncoder();
        return String.format(
            "%s:%s", 
            encoder.encodeToString(s_w.toBytes()), 
            encoder.encodeToString(p_k.toBytes())
        );
    }

    public KeyPair(String str) {
        String[] parts = str.split(":");

        Decoder decoder = Base64.getDecoder();
        
        this.s_w = Globals.pairing.getG1().newElementFromBytes(decoder.decode(parts[0]));
        this.p_k = Globals.pairing.getG1().newElementFromBytes(decoder.decode(parts[1]));
    }

}
