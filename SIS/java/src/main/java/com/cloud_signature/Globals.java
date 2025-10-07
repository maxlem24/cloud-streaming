package com.cloud_signature;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Pairing;
import it.unisa.dia.gas.plaf.jpbc.pairing.PairingFactory;

public class Globals {
    public static Pairing pairing = PairingFactory.getPairing("curves\\a.properties");
    public static int size_l = 64;
    public static int size_m = 1536;
    public static int size_n = 8;
    public static int q = 4099;
    public static Element p = pairing.getG1().newRandomElement();
    
}