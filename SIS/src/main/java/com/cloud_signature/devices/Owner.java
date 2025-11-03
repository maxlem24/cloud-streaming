package com.cloud_signature.devices;

import com.cloud_signature.signature.DelegationKeyPair;
import com.cloud_signature.signature.Gen_seed;
import com.cloud_signature.signature.KeyPair;
import com.cloud_signature.signature.Sign_params;
import com.cloud_signature.signature.Signature;
import com.cloud_signature.signature.Signed_Data;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Pairing;
import java.security.NoSuchAlgorithmException;
import org.ejml.simple.SimpleMatrix;

import com.cloud_signature.utils.Globals;
import java.util.Base64;
import java.util.Date;
import java.util.Base64.Encoder;
import java.util.Base64.Decoder;

/***
 * Propriétaire de la donnée, qui effectue une signature de sa donnée, et peut donner des droits pour déléguer la signature.
 */
public class Owner {
    private KeyPair keys;
    private byte[] id_w;

    /**
     * Initialisation du streamer dans un même programme
     * 
     * @param server la variable du serveur d'authentification
     * @param id_w   l'identité du streamer
     * @throws NoSuchAlgorithmException
     */
    public Owner(IdentificationServer server, byte[] id_w) throws NoSuchAlgorithmException {
        this.id_w = id_w;
        this.keys = server.verify_identity(id_w);
    }

    /**
     * Initialisation du streamer a partir de sa clé privée, de la clé publique de
     * la zone et de son identité
     * 
     * @param keys l'ensemble clé privée et clé publique de la zone
     * @param id_w l'identité du streamer
     * @throws NoSuchAlgorithmException
     */
    public Owner(KeyPair keys, byte[] id_w) throws NoSuchAlgorithmException {
        this.id_w = id_w;
        this.keys = keys;
    }

    /**
     * Connection à une nouvelle zone
     * 
     * @param new_server le serveur de la nouvelle zone
     * @throws NoSuchAlgorithmException
     */
    public void connect_new_IS(IdentificationServer new_server) throws NoSuchAlgorithmException {
        KeyPair new_keys = new_server.verify_identity(id_w);
        this.keys.add(new_keys);
    }

    /**
     * Calcul de la clé délégué d'un serveur fog
     * 
     * @param id_d l'identité du serveur fog
     * @return la clé publique du fog et la clé de délégation
     * @throws NoSuchAlgorithmException
     */
    public DelegationKeyPair delegateSign(byte[] id_d) throws NoSuchAlgorithmException {
        Element y = Globals.pairing.getZr().newRandomElement();
        Element pk_d = Globals.p.duplicate().mulZn(y);
        Element dk_d = keys.getS_w().duplicate().add(Globals.h1(id_d).mulZn(y));
        return new DelegationKeyPair(dk_d, pk_d);
    }

    /**
     * Implémentation de la signature
     * 
     * @param data    la donnée à signer
     * @param data_id l'id de la donnée, utilisée pour identifier la donnée après
     *                signature
     * @return un tableau contenant les différents morceaux de la signature
     * @throws NoSuchAlgorithmException
     */
    public Signed_Data[] share_data(byte[] data, long data_id) throws NoSuchAlgorithmException {
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
        Element w_2 = keys.getS_w().duplicate().mulZn(w_1).add(p_1.duplicate().mulZn(k));
        Signature sign = new Signature(w_1, w_2);

        Signed_Data[] signed_data_tab = new Signed_Data[Globals.n];
        byte[][] splited_data = Globals.split_data(data);

        for (int i = 0; i < Globals.n; i++) {
            signed_data_tab[i] = new Signed_Data(data_id, seed, id_w, v, sign, splited_data[i], i, keys.getP_k());
        }

        return signed_data_tab;

    }

    /**
     * 
     * @return l'identité du streamer
     */
    public byte[] getId_w() {
        return id_w;
    }

    /**
     * 
     * @return la clé publique de la zone
     */
    public Element getP_k() {
        return keys.getP_k();
    }

    @Override
    public String toString() {
        Encoder encoder = Base64.getEncoder();
        return String.format(
                "%s::%s",
                encoder.encodeToString(id_w),
                keys.toString());
    }

    /**
     * Initialisation du streamer à partir de sa représentation en base 64
     * @param str la représentation en base 64
     */
    public Owner(String str) {
        String[] parts = str.split("::");

        Decoder decoder = Base64.getDecoder();

        this.id_w = decoder.decode(parts[0]);
        this.keys = new KeyPair(parts[1]);
    }

}
