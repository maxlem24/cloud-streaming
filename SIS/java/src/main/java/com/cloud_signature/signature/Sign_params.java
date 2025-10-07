package com.cloud_signature.signature;

import org.ejml.simple.SimpleMatrix;

import it.unisa.dia.gas.jpbc.Element;

public class Sign_params {

    private Gen_seed paramsA;
    private Element r;
    private SimpleMatrix v;

    public Sign_params(Gen_seed paramsA, Element r, SimpleMatrix v) {
        // assert v.getNumRows() == size_l;
        // assert v.getNumCols() == size_n;
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

    public SimpleMatrix getV() {
        return v;
    }

    @Override
    public String toString() {
        return String.format("%s|%s|%s", v ,paramsA,r); 
    }
}
