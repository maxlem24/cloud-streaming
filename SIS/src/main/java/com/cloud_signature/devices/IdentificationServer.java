package com.cloud_signature.devices;

import java.io.Serializable;
import java.nio.charset.StandardCharsets;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.Base64.Encoder;
import java.util.Base64.Decoder;

import com.cloud_signature.signature.KeyPair;
import com.cloud_signature.utils.Globals;

import it.unisa.dia.gas.jpbc.Element;

// Serveur d'identification qui génère et distribue les paires de clés
// privées/publiques générées à partir de l'identité des utilisateurs
public class IdentificationServer implements Serializable{
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

    public String toString() {
        Encoder encoder = Base64.getEncoder();
        return String.format(
            "%s:%s",
            encoder.encodeToString(ts.toBytes()),
            encoder.encodeToString(pk_s.toBytes())
        );
    }

    public IdentificationServer(String str){
        String[] parts = str.split(":");
        
        Decoder decoder = Base64.getDecoder();
        this.ts = Globals.pairing.getZr().newElementFromBytes(decoder.decode(parts[0]));
        this.pk_s = Globals.pairing.getG1().newElementFromBytes(decoder.decode(parts[1]));
    }
}