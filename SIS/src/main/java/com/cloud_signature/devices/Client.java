package com.cloud_signature.devices;

import java.security.NoSuchAlgorithmException;

import org.ejml.simple.SimpleMatrix;

import com.cloud_signature.signature.Sign_params;
import com.cloud_signature.signature.Signed_Data;
import com.cloud_signature.signature.Signed_Data_Delegated;
import com.cloud_signature.utils.Globals;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Pairing;

// Client final qui vérifie l'authenticité des données signées (avec ou sans délégation)
public class Client {
    private byte[] id_c;

    public Client(byte[] id_c) {
        this.id_c = id_c;
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

    public boolean verify_signature(Signed_Data_Delegated signed_data) throws NoSuchAlgorithmException {
        SimpleMatrix v_prime = Globals.getV(signed_data.getParamA(), signed_data.getData());

        Pairing pairing = Globals.pairing;
        Element p = Globals.p.duplicate();

        Element pk_prime = signed_data.getPk_v().duplicate();
        Element r_prime_left = pairing.pairing(signed_data.getSign().getW_2().duplicate(), p.duplicate());
        Element r_prime_right = pairing
                .pairing(Globals.h1(signed_data.getId_w()), pk_prime.negate())
                .mulZn(signed_data.getSign().getW_1());
        Element r_prime_up = r_prime_left.mul(r_prime_right);
        Element r_prime_down = pairing.pairing(signed_data.getPk_d(), Globals.h1(signed_data.getId_d()))
                .mulZn(signed_data.getSign().getW_1());

        Element r_prime = r_prime_up.div(r_prime_down);

        Sign_params params = new Sign_params(v_prime, signed_data.getParamA(), r_prime);
        byte[] params_bytes = params.toString().getBytes();

        Element w_1_prime = Globals.h2(params_bytes);
        return w_1_prime.isEqual(signed_data.getSign().getW_1());
    }
}
