package com.cloud_signature.devices;

import java.io.Serializable;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Date;

import org.ejml.simple.SimpleMatrix;

import com.cloud_signature.signature.DelegationKeyPair;
import com.cloud_signature.signature.Gen_seed;
import com.cloud_signature.signature.NoDelegationException;
import com.cloud_signature.signature.Sign_params;
import com.cloud_signature.signature.Signature;
import com.cloud_signature.signature.Signed_Data;
import com.cloud_signature.signature.Signed_Data_Delegated;
import com.cloud_signature.utils.Globals;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Pairing;

import java.util.Base64;
import java.util.Base64.Encoder;
import java.util.Base64.Decoder;

/***
 * Noeud de donnée, capable de vérifier l'intégrité de la donnée reçue grâce à
 * la signature, mais qui peut aussi faire de la signature déléguée
 */
public class Fog {
    private byte[] id_d;
    private Element pk_s;
    private DelegationKeyPair delegated_keys;
    private byte[] id_w;

    /**
     * Initialisation du fog dans le même programme que le serveur d'identification
     * 
     * @param server le serveur d'authentification
     * @param id_d   l'id du fog
     */
    public Fog(IdentificationServer server, byte[] id_d) {
        this.id_d = id_d;
        this.pk_s = server.getPk_s();
        this.delegated_keys = null;
        this.id_w = null;
    }

    /**
     * Ajout d'une délégation de signature dans le même programme
     * 
     * @param owner le propriétaire des données
     * @throws NoSuchAlgorithmException
     */
    public void addDelegation(Owner owner) throws NoSuchAlgorithmException {
        this.delegated_keys = owner.delegateSign(id_d);
        this.id_w = owner.getId_w();
    }

    /***
     * Implémentation de la vérification de la signature selon le SIS
     * 
     * @param signed_data La structure contenant la signature ainsi que tous les
     *                    paramètres nécessaires à la vérification
     * @return si la signature est vérifiée
     * @throws NoSuchAlgorithmException
     */
    public boolean verify_signature(Signed_Data signed_data) throws NoSuchAlgorithmException {
        SimpleMatrix v_i = Globals.calcVi(signed_data.getParamA(), signed_data.getD_i());
        SimpleMatrix v_prime = signed_data.getV();
        v_prime.setColumn(signed_data.getI(), v_i);

        Pairing pairing = Globals.pairing;
        Element p = Globals.p.duplicate();

        Element pk_prime = signed_data.getPk_v().duplicate();
        Element r_prime_left = pairing.pairing(signed_data.getSign().getW_2().duplicate(), p.duplicate());
        Element r_prime_right = pairing
                .pairing(Globals.h1(signed_data.getId_w()), pk_prime.negate())
                .mulZn(signed_data.getSign().getW_1());
        Element r_prime = r_prime_left.mul(r_prime_right);
        Sign_params params = new Sign_params(v_prime, signed_data.getParamA(), r_prime);
        byte[] params_bytes = params.toString().getBytes();

        Element w_1_prime = Globals.h2(params_bytes);

        return w_1_prime.isEqual(signed_data.getSign().getW_1());
    }

    /**
     * Implémentation de la signature déléguée
     * 
     * @param data    la donnée à signer
     * @param data_id l'id de la donnée, utilisée pour identifier la donnée après
     *                signature
     * @return un tableau contenant les différents morceaux de la signature
     *         déléguée
     * @throws NoSuchAlgorithmException
     * @throws NoDelegationException    si aucune délégation a été mise en place
     */
    public Signed_Data_Delegated[] delegated_sign(byte[] data, long data_id)
            throws NoSuchAlgorithmException, NoDelegationException {
        if (delegated_keys == null || id_w == null) {
            throw new NoDelegationException();
        }
        Gen_seed seed = new Gen_seed();
        SimpleMatrix v = Globals.calcV(seed, data);

        Pairing pairing = Globals.pairing;
        Element p = Globals.p.duplicate();

        Element p_1 = pairing.getG1().newRandomElement();
        Element k = pairing.getZr().newRandomElement();

        Element r = pairing.pairing(p, p_1).mulZn(k);
        Sign_params params = new Sign_params(v, seed, r);
        byte[] params_bytes = params.toString().getBytes();
        Element w_1 = Globals.h2(params_bytes);
        Element w_2 = delegated_keys.getDk_d().duplicate().mulZn(w_1).add(p_1.duplicate().mulZn(k));

        Signature sign = new Signature(w_1, w_2);

        Signed_Data_Delegated[] signed_data_tab = new Signed_Data_Delegated[Globals.n];
        byte[][] splited_data = Globals.split_data(data);

        for (int i = 0; i < Globals.n; i++) {
            signed_data_tab[i] = new Signed_Data_Delegated(data_id, seed, id_w, v, sign,
                    splited_data[i], i,
                    pk_s, id_d,
                    delegated_keys.getPk_d());
        }

        return signed_data_tab;
    }

    /**
     * Création d'un fog à partir de la clé de zone et de son identité
     * 
     * @param pk_s la clé publique de la zone
     * @param id_d l'id du serveur edge
     */
    public Fog(Element pk_s, byte[] id_d) {
        this.id_d = id_d;
        this.pk_s = pk_s;
        this.delegated_keys = null;
        this.id_w = null;
    }

    /**
     * Ajout d'une délégation de signature à partir des données en base 64
     * 
     * @param str les informations de délagation en base 64
     */
    public void addDelegation(String str) {
        Decoder decoder = Base64.getDecoder();
        String[] parts = str.split("::");
        this.delegated_keys = new DelegationKeyPair(parts[0]);
        this.id_w = decoder.decode(parts[1]);
    }

    @Override
    public String toString() {
        Encoder encoder = Base64.getEncoder();
        if ((delegated_keys == null) || (id_w == null)) {
            return String.format(
                    "%s::%s",
                    encoder.encodeToString(id_d),
                    encoder.encodeToString(pk_s.toBytes()));
        } else {
            return String.format(
                    "%s::%s::%s::%s",
                    encoder.encodeToString(id_d),
                    encoder.encodeToString(pk_s.toBytes()),
                    delegated_keys.toString(),
                    encoder.encodeToString(id_w));
        }

    }

    /**
     * Initialisation du serveur fog à partir des informations encodées en base 64
     * 
     * @param str le fog en base 64
     */
    public Fog(String str) {
        String[] parts = str.split("::");
        Decoder decoder = Base64.getDecoder();

        this.id_d = decoder.decode(parts[0]);
        this.pk_s = Globals.pk_sFromString(parts[1]);
        if (parts.length == 4) {
            this.delegated_keys = new DelegationKeyPair(parts[2]);
            this.id_w = decoder.decode(parts[3]);
        }
    }

}
