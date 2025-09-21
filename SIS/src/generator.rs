pub struct Generator {
    pub i_n: i64,
    pub c_n: i64,
    pub q: i64,
    pub a: i64,
}

impl Generator {
    pub fn new(i_n: i64, c_n: i64, q: i64, a: i64) -> Self{
        Generator { i_n, c_n, q, a }
    }
}

impl Iterator for Generator {
    type Item = i64;
    fn next(&mut self) -> Option<Self::Item> {
        let i_n1: i64 = (self.a * self.i_n + self.c_n) % self.q;
        let c_n1: i64 = (self.a * self.i_n + self.c_n) / self.q;
        self.i_n = i_n1;
        self.c_n = c_n1;
        return Some(self.i_n);
    }
}


fn setup() {
    // Generate G0, G1, P, p, e


    // Define I0, C0, q, a


    // t_s = random()
    // MSK = t_s
    // PKs = t_s * P // Clé publique
}

fn verify_identity(id : i64){
    // Do something...

    // return Ssw = t_s*H_1(id)
}