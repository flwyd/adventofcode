{
  // jnz 0
  A_8_9: 0,
  B_8_9: 1,  // stays from output
  C_8_9: 'whatever',
  // adv 3 (divide A by 8, result in A)
  A_7_9: self.A_8_9,
  B_7_9: 1,  // stays from output
  C_7_9: self.C_8_9,
  // out 5 (print from B)
  A_6_9: self.A_7_9,
  B_6_9: 1,  // output
  C_6_9: self.C_7_9,
  // bxc 4 (xor B and C, result in B)
  A_5_9: self.A_6_9,
  B_5_9: std.xor(self.B_6_9, self.C_7_9),
  C_5_9: self.C_6_9,
  // bxl 3 (xor B and 3, result in B)
  A_4_9: self.A_5_9,
  B_4_9: std.xor(self.B_5_9, 3),
  C_4_9: self.C_5_9,
  // cdv 5 (divide A by 2^B, result in C)
  A_3_9: self.A_4_9,
  B_3_9: self.B_4_9,
  C_3_9: std.floor(self.A_3_9 / std.pow(2, self.B_3_9)),
  // bxl 2 (xor B and 2, result in B)
  A_2_9: self.A_3_9,
  B_2_9: std.xor(self.B_3_9, 2),
  C_2_9: self.C_3_9,
  // bst 4 (A mod 8, result in B)
  A_1_9: self.A_2_9,
  B_1_9: std.mod(self.A_1_9, 8),
  C_1_9: self.C_2_9,
}
