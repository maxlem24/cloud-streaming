package com.cloud_signature;

import java.security.NoSuchAlgorithmException;

import com.cloud_signature.devices.*;
import com.cloud_signature.signature.NoDelegationException;
import com.cloud_signature.signature.Signed_Data;
import com.cloud_signature.signature.Signed_Data_Delegated;

public class Main {

    public static void main(String[] args) {
        try {
            IdentificationServer s_1 = new IdentificationServer();
            Owner o_1 = new Owner(s_1, "maxlem24".getBytes());
            Signed_Data signed_data = o_1.share_data("Ceci est un stream".getBytes());
            Fog f_1 = new Fog(s_1, "Fog 1".getBytes());
            System.out.println(f_1.verify_signature(signed_data));

            Signed_Data error_data = new Signed_Data(signed_data.getParamA(),
                    signed_data.getId_w(),
                    signed_data.getV(),
                    signed_data.getSign(),
                    "Ceci n'est pas un stream".getBytes(),
                    signed_data.getPk_v());
            System.out.println(f_1.verify_signature(error_data));

            f_1.getDelegatedKeys(o_1);
            Signed_Data_Delegated signed_data_delegated = f_1.delegated_sign("Ceci est un stream delegue".getBytes());
            Signed_Data_Delegated error_data_delegated = new Signed_Data_Delegated(signed_data_delegated.getParamA(),
                    signed_data_delegated.getId_w(), signed_data_delegated.getV(), signed_data_delegated.getSign(),
                    "Delegation modifiée".getBytes(), signed_data_delegated.getPk_v(), signed_data_delegated.getId_d(),
                    signed_data_delegated.getPk_d());
            Client c_1 = new Client("Client 1".getBytes());
            System.out.println(c_1.verify_signature(signed_data));
            System.out.println(c_1.verify_signature(error_data));
            System.out.println(c_1.verify_signature(signed_data_delegated));
            System.out.println(c_1.verify_signature(error_data_delegated));
        } catch (NoSuchAlgorithmException | NoDelegationException e) {
            e.printStackTrace();
        }
    }

}
