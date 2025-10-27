package com.cloud_signature.signature;

import java.io.Serializable;

import it.unisa.dia.gas.jpbc.Element;

import com.cloud_signature.utils.Globals;

import java.util.Base64;
import java.util.Base64.Encoder;
import java.util.Base64.Decoder;

/***
 * Ensemble clé publique du signataire délégué et clé de signature
 */
public class DelegationKeyPair {
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

    @Override
    public String toString() {
        Encoder encoder = Base64.getEncoder();
        return String.format(
                "%s:%s",
                encoder.encodeToString(dk_d.toBytes()),
                encoder.encodeToString(pk_d.toBytes()));
    }

    public DelegationKeyPair(String str) {
        String[] parts = str.split(":");

        Decoder decoder = Base64.getDecoder();

        this.dk_d = Globals.pairing.getG1().newElementFromBytes(decoder.decode(parts[0]));
        this.pk_d = Globals.pairing.getG1().newElementFromBytes(decoder.decode(parts[1]));
    }
}
