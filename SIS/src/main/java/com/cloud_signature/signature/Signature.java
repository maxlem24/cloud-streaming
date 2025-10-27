package com.cloud_signature.signature;

import java.util.Base64;
import java.util.Base64.Decoder;
import java.util.Base64.Encoder;

import com.cloud_signature.utils.Globals;

import it.unisa.dia.gas.jpbc.Element;

/***
 * Signature, composée de w1 et de w2
 */
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

     public String toString() {
        Encoder encoder = Base64.getEncoder();
        return String.format(
            "%s:%s",
            encoder.encodeToString(w_1.toBytes()),
            encoder.encodeToString(w_2.toBytes())
        );
    }

    public Signature(String str){
        String[] parts = str.split(":");
        
        Decoder decoder = Base64.getDecoder();
        this.w_1 = Globals.pairing.getZr().newElementFromBytes(decoder.decode(parts[0]));
        this.w_2 = Globals.pairing.getG1().newElementFromBytes(decoder.decode(parts[1]));
    }
}
