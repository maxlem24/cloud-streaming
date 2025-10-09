package com.cloud_signature.signature;

import com.cloud_signature.Globals;

public class Gen_seed {

    private int i_0;
    private int c_0;
    private int a;

    public Gen_seed() {
        int min = 1;
        int max = Globals.q - 1;
        this.i_0 = (int) ((Math.random() * (max - min)) + min);
        this.c_0 = (int) ((Math.random() * (max - min)) + min);
        this.a = (int) ((Math.random() * (max - min)) + min);
    }

    public Gen_seed(int i_0, int c_0, int a) {
        this.a = a;
        this.i_0 = i_0;
        this.c_0 = c_0;
    }

    public int getA() {
        return a;
    }

    public int getC_0() {
        return c_0;
    }

    public int getI_0() {
        return i_0;
    }

    @Override
    public String toString() {
        return String.format("%d|%d|%d", a, i_0, c_0);
    }

}
