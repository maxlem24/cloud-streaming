package com.cloud_signature.signature;

import org.ejml.simple.SimpleMatrix;

import it.unisa.dia.gas.jpbc.Element;

import com.cloud_signature.utils.Globals;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Base64.Encoder;
import java.util.Base64.Decoder;

// Données signées contenant le message, la signature et tous les pautres aramètres pour la vérification
public class Signed_Data {
    private Gen_seed paramA;
    private byte[] id_w;
    private SimpleMatrix v;
    private Signature sign;
    private byte[] d_i;
    private int i;
    private Element pk_v;

    public Signed_Data(Gen_seed paramA, byte[] id_w, SimpleMatrix v, Signature sign, byte[] d_i, int i, Element pk_v) {
        this.paramA = paramA;
        this.id_w = id_w;
        this.v = v;
        this.sign = sign;
        this.d_i = d_i;
        this.i = i;
        this.pk_v = pk_v;
    }

    public byte[] getId_w() {
        return id_w;
    }

    public Gen_seed getParamA() {
        return paramA;
    }

    public Element getPk_v() {
        return pk_v;
    }

    public Signature getSign() {
        return sign;
    }

    public byte[] getD_i() {
        return d_i;
    }

    public SimpleMatrix getV() {
        return v;
    }

    public int getI() {
        return i;
    }

    @Override
    public String toString() {
        Encoder encoder = Base64.getEncoder();

        return String.format("%s::%s::%s::%s::%s::%s::%s",
                paramA.toString(),
                encoder.encodeToString(id_w),
                encoder.encodeToString(Globals.matrixToString(v).getBytes()),
                sign.toString(),
                encoder.encodeToString(d_i),
                Integer.toString(i),
                encoder.encodeToString(pk_v.toBytes()));
    }

    public Signed_Data(String str) {
        String[] parts = str.split("::");
        Decoder decoder = Base64.getDecoder();

        this.paramA = new Gen_seed(parts[0]);
        this.id_w = decoder.decode(parts[1]);
        this.v = Globals.matrixFromString(new String(decoder.decode(parts[2])));
        this.sign = new Signature(parts[3]);
        this.d_i = decoder.decode(parts[4]);
        this.i = Integer.parseInt(parts[5]);
        this.pk_v = Globals.pairing.getG1().newElementFromBytes(decoder.decode(parts[6]));
    }
}
