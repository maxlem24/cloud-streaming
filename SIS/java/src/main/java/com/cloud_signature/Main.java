package com.cloud_signature;

import com.cloud_signature.signature.Gen_seed;
import com.cloud_signature.signature.PRNG;
import com.cloud_signature.signature.Sign_params;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Pairing;

public class Main {

    public static void main(String[] args) {
        PRNG prng = new PRNG(new Gen_seed(5, 3, 7), 97);
        for (int i = 0; i < 10; i++) {
            System.out.println(prng.getNext());
        }


        
        Pairing pairing = Globals.pairing;
        Element p = pairing.getG1().newRandomElement(); // choix d'un générateur

        /// Identification
        // 1. Le serveur reçoit l'identité du owner
        String id_w = "Hello";
        // 2. Le serveur génère une clé publique et privée
        Element ts = pairing.getZr().newRandomElement();

        Element pk_s = p.duplicate().mulZn(ts); // Server pubkey
        // let pk_s = p.multiply(&ts); // Serveur pubkey

        byte[] id_w_bytes = id_w.getBytes();
        Element s_sw = pairing.getG1().newElementFromHash(id_w_bytes, 0, id_w_bytes.length).mulZn(ts);

        // TODO: 3. Le serveur envoie s_sw au owner de manière sécurisée
        // TODO: 4/5. mettre à jour la clé secrete du owner en fonction de la clé du serveur

        /// Signature
        // 1. Choose random P1 in G1 and k in Zp
        Element p_1 = pairing.getG1().newRandomElement();
        Element k = pairing.getZr().newRandomElement();

        Gen_seed gen_seed = new Gen_seed(1,2,4);

        // 2. Compute r = e(P, P1)^k
        Element r = pairing.pairing(p, p_1).mulZn(k);
        Sign_params params = new Sign_params(gen_seed,r,);
        Element w_1 = pairing.getZr().newElementFromHash(params_bytes, 0, params_bytes.length);

        Element w_2 = s_sw.duplicate().mulZn(w_1).add(p_1.duplicate().mulZn(k));

        System.out.println(w_1);
        System.out.println(w_2);
        // let w_2 = s_sw * w_1 + p_1 * k;
        // let r = engine.paire(&p, &p_1);
        // let w_1 = engine.fr.random_element(); // TODO change
        // let w_2 = s_sw.multiply(&w_1).addto(&p_1.multiply(&k));
        
    }

}
