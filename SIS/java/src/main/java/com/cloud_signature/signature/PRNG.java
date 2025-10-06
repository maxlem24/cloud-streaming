package com.cloud_signature.signature;

public class PRNG {
    private int in;
    private int cn;
    private final int a;
    private final int q;

    public PRNG(Gen_seed gen_seed, int q) {
        this.a = gen_seed.getA();
        this.cn = gen_seed.getC_0();
        this.in = gen_seed.getI_0();
        this.q = q;
    }

    public int getNext() {
        int temp = this.a * this.in + this.cn;

        this.in = temp % this.q;
        this.cn = temp / this.q;

        return this.in;
    }
}