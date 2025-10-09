package com.cloud_signature;

import java.security.NoSuchAlgorithmException;

import com.cloud_signature.signature.Fog;
import com.cloud_signature.signature.IdentificationServer;
import com.cloud_signature.signature.Owner;
import com.cloud_signature.signature.Signed_Data;

public class Main {

    public static void main(String[] args) {
        try {
            IdentificationServer s_1 = new IdentificationServer();
            Owner o_1 = new Owner(s_1, "maxlem24".getBytes());
            Signed_Data signed_data = o_1.share_data("Ceci est un stream".getBytes());
            Fog f_1 = new Fog(s_1);
            System.out.println(f_1.verify_signature(signed_data));

            Signed_Data error_data = new Signed_Data(signed_data.getParamA(),
                    signed_data.getId_w(),
                    signed_data.getV(),
                    signed_data.getSign(),
                    "Ceci n'est pas un stream".getBytes(),
                    signed_data.getPk_v());
            System.out.println(f_1.verify_signature(error_data));
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
    }

}
