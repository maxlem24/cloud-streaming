package com.cloud_signature.signature;

import org.ejml.simple.SimpleMatrix;

import it.unisa.dia.gas.jpbc.Element;

// Données signées contenant le message, la signature et tous les pautres aramètres pour la vérification
public class Signed_Data {
    private Gen_seed paramA;
    private byte[] id_w;
    private SimpleMatrix v;
    private Signature sign;
    private byte[] data;
    private Element pk_v;

    public Signed_Data(Gen_seed paramA, byte[] id_w, SimpleMatrix v, Signature sign, byte[] data, Element pk_v) {
        this.paramA = paramA;
        this.id_w = id_w;
        this.v = v;
        this.sign = sign;
        this.data = data;
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

    public byte[] getData() {
        return data;
    }

    public SimpleMatrix getV() {
        return v;
    }

    @Override
    public String toString() {
        return String.format("paramA = %s\n" +
                "id_w = %s\n" +
                "sign = %s\n" +
                "data = %s\n" +
                "pk_v = %s", paramA, new String(id_w), sign, new String(data), pk_v);
    }
}
