package com.cloud_signature;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.ObjectOutputStream;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.NoSuchAlgorithmException;

import com.cloud_signature.devices.*;
import com.cloud_signature.signature.Gen_seed;
import com.cloud_signature.signature.KeyPair;
import com.cloud_signature.signature.NoDelegationException;
import com.cloud_signature.signature.Signed_Data;
import com.cloud_signature.signature.Signed_Data_Delegated;
import com.cloud_signature.utils.Globals;

public class Main {

    public static void main(String[] args) {
        /*
         * --mode=identification init
         * --mode=identification pseudo:mdp
         * 
         * --mode=client verify_signature --signature="X"
         * --data_file="chemin/du/fichier"
         * 
         * --mode=fog verify_signature --signature="X" --data_file="chemin/du/fichier"
         * --mode=fog sign_data --data_file="chemin/du/fichier"
         * --mode=fog delegate_keys --owner_pubkey="X"
         * 
         * --mode=owner sign_data --data_file="chemin/du/fichier"
         * --mode=owner create_delegation --id=edge-id
         */

        // try {
        // IdentificationServer s_1 = new IdentificationServer();
        // Owner o_1 = new Owner(s_1, "maxlem24".getBytes());
        // Signed_Data[] signed_data_array = o_1.share_data("Ceci est un
        // stream".getBytes());

        // Fog f_1 = new Fog(s_1, "Fog 1".getBytes());
        // System.out.println(f_1.verify_signature(signed_data_array[0]));
        // System.out.println(f_1.verify_signature(signed_data_array[2]));

        // f_1.getDelegatedKeys(o_1);
        // Signed_Data_Delegated[] signed_data_delegated_array = f_1
        // .delegated_sign("Ceci est un stream delegue".getBytes());
        // Client c_1 = new Client();
        // System.out.println(c_1.verify_signature(signed_data_array[7]));
        // System.out.println(c_1.verify_signature(signed_data_delegated_array[5]));
        // } catch (NoSuchAlgorithmException | NoDelegationException e) {
        // e.printStackTrace();
        // }

        String mode = "";
        if (args.length != 0) {
            mode = args[0];
        }

        // Create signature directory if it does not exist
        switch (mode) {
            case "id":
            case "identification": {
                identification(args);
                return;
            }

            case "owner": {
                owner(args);
                return;
            }

            case "client": {
                client(args);
                return;
            }

            case "fog": {
                fog(args);
                return;
            }

            default:
                System.err.println(
                        "Usage:\n" +
                                "identification <identity>\n" +
                                "client verify <signed_data>\n" +
                                "client merge <chemin/du/fichier>" +
                                "fog init <identity> <server_keys>\n" +
                                "fog verify <signed_data>\n" +
                                "fog verify -f <chemin/du/fichier>\n" +
                                // "fog sign_data <chemin/du/fichier>\n" +
                                // "fog delegate_keys <owner_pubkey>\n" +
                                "owner init <identity> <base64_keys>\n" +
                                "owner sign <chemin/du/fichier> <data_id>"
                // "owner create_delegation <edge-id>"
                );
                return;
        }

    }

    public static void identification(String[] args) {
        if (args.length != 2) {
            System.err.println("Usage:\n" +
                    "identification <identity>");
            System.exit(1);
        }

        File file = new File("signature/id_server.keys");
        file.getParentFile().mkdirs();

        // Create
        IdentificationServer i_s = null;
        if (!file.exists()) {
            try {
                i_s = new IdentificationServer();
                PrintWriter out = new PrintWriter(file);
                out.print(i_s.toString());
                out.close();
            } catch (Exception e) {
                e.printStackTrace();
                System.exit(1);
            }
        } else {
            try {
                String str = Files.readString(file.toPath(), StandardCharsets.UTF_8);
                i_s = new IdentificationServer(str);
            } catch (Exception e) {
                e.printStackTrace();
                System.exit(1);
            }
        }

        String identity = args[1];
        try {
            KeyPair keys = i_s.verify_identity(identity.getBytes());
            System.out.println(keys.toString());
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
        return;
    }

    public static void client(String[] args) {
        if (args.length < 3) {
            System.err.println("Usage:\n" +
                    "client verify <signed_data>\n" +
                    "client merge <chemin du fichier>");
            System.exit(1);
        }
        String action = args[1];
        Client client = new Client();

        switch (action) {
            case "verify":
                if (args.length != 3) {
                    System.err.println("Usage:\n" +
                            "client verify <signed_data>");
                    System.exit(1);
                }

                String signature = args[2].trim();

                try {
                    int length = signature.split("::").length;
                    if (length == 8) {
                        Signed_Data signed_data = new Signed_Data(signature);
                        System.out.println(client.verify_signature(signed_data)
                                ? signed_data.getData_id() + " " + signed_data.getI()
                                : "X");
                    } else if (length == 10) {
                        // TODO
                        System.err.println("Vérification de signature déléguée non implémentée");
                        System.exit(1);
                    } else {
                        System.err.println("Signature invalide");
                        System.exit(1);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
                break;
            case "merge":
                if (args.length != 3) {
                    System.err.println("Usage:\n" +
                            "client merge <chemin du fichier>");
                    System.exit(1);
                }

                String file_path = args[2];
                try {
                    ByteArrayOutputStream os = new ByteArrayOutputStream();
                    File file = new File(file_path);
                    String[] input = Files.readString(file.toPath(), StandardCharsets.UTF_8)
                            .split("\n");
                    Signed_Data[] signed_data_tab = new Signed_Data[Globals.n];
                    for (int i = 0; i < Globals.n; i++) {
                        Signed_Data sd = new Signed_Data(input[i].trim());
                        signed_data_tab[sd.getI()] = sd;
                    }
                    for (Signed_Data sd : signed_data_tab) {
                        os.write(sd.getD_i());
                    }
                    byte output[] = os.toByteArray();

                    File file_out = File.createTempFile(randomChars(32), ".png");
                    System.out.println(file_out.getAbsolutePath());

                    FileOutputStream stream = new FileOutputStream(file_out);
                    stream.write(output);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                break;
            default:
                System.err.println(
                        "Usage:\n" +
                                "client verify <signed_data>\n" +
                                "client merge <chemin du fichier>"
                // "owner create_delegation <edge-id>"
                );
                return;
        }

    }

    public static void owner(String[] args) {
        if (args.length < 3) {
            System.err.println("Usage:\n" +
                    "owner init <identity> <base64_keys>\n" +
                    "owner sign <chemin/du/fichier> <data_id>"
            // "owner create_delegation <edge-id>"
            );
            System.exit(1);
        }

        File file = new File("signature/id_owner.keys");
        file.getParentFile().mkdirs();

        Owner owner = null;
        switch (args[1]) {
            case "init": {
                if (args.length != 4) {
                    System.err.println("Usage:\n" +
                            "owner init <identity> <base64_keys>");
                    System.exit(1);
                }

                String id_w = args[2];
                String keys_str = args[3];
                try {
                    owner = new Owner(new KeyPair(keys_str), id_w.getBytes());
                    PrintWriter out = new PrintWriter(file);
                    out.print(owner);
                    out.close();
                } catch (Exception e) {
                    e.printStackTrace();
                    System.exit(1);
                }
                return;
            }
            case "sign": {
                if (args.length != 4) {
                    System.err.println("Usage:\n" +
                            "owner sign <chemin/du/fichier> <data_id>");
                    System.exit(1);
                }
                try {
                    String str = Files.readString(file.toPath(), StandardCharsets.UTF_8);
                    owner = new Owner(str);
                } catch (Exception e) {
                    e.printStackTrace();
                    System.exit(1);
                }

                try {
                    String file_path = args[2];
                    long data_id = Long.parseLong(args[3]);
                    File data_file = new File(file_path);
                    byte[] data = Files.readAllBytes(data_file.toPath());

                    Signed_Data[] signed_data_tab = owner.share_data(data, data_id);
                    for (Signed_Data sd : signed_data_tab) {
                        System.out.println(sd);
                        // System.out.println(sd.toString().equals(new
                        // Signed_Data(sd.toString()).toString()));
                    }

                } catch (Exception e) {
                    e.printStackTrace();
                    System.exit(1);
                }

                return;
            }
            case "create_delegation":
                System.out.println("Va voir ailleurs si j'y suis :eyes:");
                System.exit(0xBEEF);
                return;
            default:
                System.err.println(
                        "Usage:\n" +

                                "owner init <identity> <base64_keys>\n" +
                                "owner sign <chemin/du/fichier>");
                return;
        }
    }

    public static void fog(String[] args) {
        if (args.length < 3) {
            System.err.println("Usage:\n" +
                    "fog init <identity> <server_keys>\n" +
                    "fog verify <signed_data>\n" +
                    "fog verify -f <chemin/du/fichier>");
            System.exit(1);
        }

        File file = new File("signature/id_fog.keys");
        file.getParentFile().mkdirs();

        String action = args[1];
        Fog fog;

        switch (action) {
            case "init": {
                if (args.length != 4) {
                    System.err.println("Usage:\n" +
                            "fog init <identity> <server_keys>");
                    System.exit(1);
                }

                String id_d = args[2];
                String pk_String = args[3];
                try {
                    fog = new Fog(Globals.pk_sFromString(pk_String.split(":")[1]), id_d.getBytes());
                    PrintWriter out = new PrintWriter(file);
                    out.print(fog);
                    out.close();
                } catch (Exception e) {
                    e.printStackTrace();
                    System.exit(1);
                }
                return;
            }
            case "verify":
                if (args[2].equals("-f")) {
                    if (args.length != 4) {
                        System.err.println("Usage:\n" +
                                "fog verify -f <chemin/du/fichier>");
                        System.exit(1);
                    }

                    String file_path = args[3];
                    try {
                        String str = Files.readString(file.toPath(), StandardCharsets.UTF_8);
                        fog = new Fog(str);
                        File data_file = new File(file_path);
                        String[] signature_array = Files.readString(data_file.toPath(), StandardCharsets.UTF_8)
                                .split("\n");
                        for (String signature : signature_array) {
                            int length = signature.split("::").length;
                            if (length == 8) {
                                Signed_Data signed_data = new Signed_Data(signature.trim());
                                System.out.println(fog.verify_signature(signed_data)
                                        ? signed_data.getData_id() + " " + signed_data.getI()
                                        : "X");
                            } else if (length == 10) {
                                // TODO
                                System.err.println("Vérification de signature déléguée non implémentée");
                                System.exit(1);
                            } else {
                                System.err.println("Signature invalide");
                                System.exit(1);
                            }
                        }

                    } catch (Exception e) {
                        e.printStackTrace();
                    }

                } else {
                    if (args.length != 3) {
                        System.err.println("Usage:\n" +
                                "fog verify <signed_data>");
                        System.exit(1);
                    }

                    String signature = args[2];

                    try {
                        String str = Files.readString(file.toPath(), StandardCharsets.UTF_8);
                        fog = new Fog(str);
                        int length = signature.split("::").length;
                        if (length == 8) {
                            Signed_Data signed_data = new Signed_Data(signature);
                            System.out.println(fog.verify_signature(signed_data)
                                    ? signed_data.getData_id() + " " + signed_data.getI()
                                    : "X");
                        } else if (length == 10) {
                            // TODO
                            System.err.println("Vérification de signature déléguée non implémentée");
                            System.exit(1);
                        } else {
                            System.err.println("Signature invalide");
                            System.exit(1);
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }

                return;

            default:
                System.err.println(
                        "Usage:\n" +
                                "fog init <identity> <server_keys>\n" +
                                "fog verify <signature>\n" +
                                "fog verify -f <chemin/du/fichier>");
                return;
        }
    }

    public static String randomChars(int length) {
        StringBuilder sb = new StringBuilder();
        String characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        for (int i = 0; i < length; i++) {
            int index = (int) (Math.random() * characters.length());
            sb.append(characters.charAt(index));
        }
        return sb.toString();
    }

}
