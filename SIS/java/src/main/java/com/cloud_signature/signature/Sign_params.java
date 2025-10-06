package com.cloud_signature.signature;

import static com.cloud_signature.Globals.size_l;
import static com.cloud_signature.Globals.size_n;

import it.unisa.dia.gas.jpbc.Element;

public class Sign_params {

    private Gen_seed paramsA;
    private Element r;
    private int[][] v;

    public Sign_params(Gen_seed paramsA, Element r, int[][] v) {
        assert v.length == size_l;
        assert v[0].length == size_n;
        this.paramsA = paramsA;
        this.r = r;
        this.v = v;
    }

    public Gen_seed getParamsA() {
        return paramsA;
    }

    public Element getR() {
        return r;
    }

    public int[][] getV() {
        return v;
    }

    @Override
    public String toString() {
        return String.format("%s|%s|%s", "V" ,paramsA.toString(),r.toString()); // TO DO
    }
}
