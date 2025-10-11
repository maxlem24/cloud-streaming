package com.cloud_signature.devices;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

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

// Noeud du fog qui vérifie les signatures et peut signer des données par délégation
public class Fog {
    private byte[] id_d;
    private Element pk_s;
    private DelegationKeyPair delegated_keys;
    private Owner delegatedOwner;

    public Fog(IdentificationServer server, byte[] id_d) {
        this.id_d = id_d;
        this.pk_s = server.getPk_s();
        this.delegated_keys = null;
        this.delegatedOwner = null;
    }

    public void getDelegatedKeys(Owner owner) throws NoSuchAlgorithmException {
        this.delegated_keys = owner.create_delegation(id_d);
        this.delegatedOwner = owner;
    }

    public boolean verify_signature(Signed_Data signed_data) throws NoSuchAlgorithmException {
        SimpleMatrix v_prime = Globals.getV(signed_data.getParamA(), signed_data.getData());

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

    public Signed_Data_Delegated delegated_sign(byte[] data) throws NoSuchAlgorithmException, NoDelegationException {
        if (delegated_keys == null || delegatedOwner == null) {
            throw new NoDelegationException();
        }
        Gen_seed seed = new Gen_seed();
        SimpleMatrix v = Globals.getV(seed, data);

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
        return new Signed_Data_Delegated(seed, delegatedOwner.getId_w(), v, sign, data, delegatedOwner.getP_k(), id_d,
                delegated_keys.getPk_d());
    }

}
