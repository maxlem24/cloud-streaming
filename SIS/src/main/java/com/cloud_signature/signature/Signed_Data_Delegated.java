package com.cloud_signature.signature;

import java.util.Base64;
import java.util.Base64.Decoder;
import java.util.Base64.Encoder;

import org.ejml.simple.SimpleMatrix;

import com.cloud_signature.utils.Globals;

import it.unisa.dia.gas.jpbc.Element;

/***
 * Données signée par délégation, qui contiennent tous les éléments nécessaire à
 * la vérification de la signature
 */
public class Signed_Data_Delegated extends Signed_Data {
    private byte[] id_d;
    private Element pk_d;

    public Signed_Data_Delegated(long data_id, Gen_seed paramA, byte[] id_w, SimpleMatrix v, Signature sign,
            byte[] d_i, int i,
            Element pk_v, byte[] id_d, Element pk_d) {
        super(data_id, paramA, id_w, v, sign, d_i, i, pk_v);
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
        Encoder encoder = Base64.getEncoder();

        return String.format("%s::%s::%s",
                super.toString(),
                encoder.encodeToString(id_d),
                encoder.encodeToString(pk_d.toBytes()));
    }

    public Signed_Data_Delegated(String str) {
        super(str); // Seules les 8 premieres parties vont être utilisées
        String[] parts = str.split("::");
        Decoder decoder = Base64.getDecoder();

        this.id_d = decoder.decode(parts[8]);
        this.pk_d = Globals.pairing.getG1().newElementFromBytes(decoder.decode(parts[9]));
    }

}
