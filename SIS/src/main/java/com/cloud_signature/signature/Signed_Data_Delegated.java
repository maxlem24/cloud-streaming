package com.cloud_signature.signature;

import org.ejml.simple.SimpleMatrix;

import it.unisa.dia.gas.jpbc.Element;

// Données signées par délégation qui incluent en plus l'identité et la clé publique du propriétaire originel
public class Signed_Data_Delegated extends Signed_Data {
    private byte[] id_d;
    private Element pk_d;

    public Signed_Data_Delegated(Gen_seed paramA, byte[] id_w, SimpleMatrix v, Signature sign, byte[] d_i, int i,
            Element pk_v, byte[] id_d, Element pk_d) {
        super(paramA, id_w, v, sign, d_i, i, pk_v);
        this.id_d = id_d;
        this.pk_d = pk_d;
    }

    public byte[] getId_d() {
        return id_d;
    }

    public Element getPk_d() {
        return pk_d;
    }

    @Override
    public String toString() {
        return super.toString() + String.format("\nid_d = %s", new String(id_d));
    }
}
