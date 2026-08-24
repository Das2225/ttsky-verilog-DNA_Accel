//==========================================================
// comparator.v
// Compares 8 DNA bases and generates Ts/Tv-aware scores
//
// Score Encoding
// 2'b10 : Exact Match      (2 points)
// 2'b01 : Transition       (1 point)
// 2'b00 : Transversion     (0 points)
//==========================================================

module comparator(

    input  [15:0] pattern,
    input  [15:0] dna,

    output [1:0] score0,
    output [1:0] score1,
    output [1:0] score2,
    output [1:0] score3,
    output [1:0] score4,
    output [1:0] score5,
    output [1:0] score6,
    output [1:0] score7

);

    //======================================================
    // Base 0
    //======================================================
    wire lsb_eq0 = ~(pattern[0] ^ dna[0]);
    wire msb_eq0 = ~(pattern[1] ^ dna[1]);

    assign score0 = {lsb_eq0 & msb_eq0,
                     lsb_eq0 & ~msb_eq0};

    //======================================================
    // Base 1
    //======================================================
    wire lsb_eq1 = ~(pattern[2] ^ dna[2]);
    wire msb_eq1 = ~(pattern[3] ^ dna[3]);

    assign score1 = {lsb_eq1 & msb_eq1,
                     lsb_eq1 & ~msb_eq1};

    //======================================================
    // Base 2
    //======================================================
    wire lsb_eq2 = ~(pattern[4] ^ dna[4]);
    wire msb_eq2 = ~(pattern[5] ^ dna[5]);

    assign score2 = {lsb_eq2 & msb_eq2,
                     lsb_eq2 & ~msb_eq2};

    //======================================================
    // Base 3
    //======================================================
    wire lsb_eq3 = ~(pattern[6] ^ dna[6]);
    wire msb_eq3 = ~(pattern[7] ^ dna[7]);

    assign score3 = {lsb_eq3 & msb_eq3,
                     lsb_eq3 & ~msb_eq3};

    //======================================================
    // Base 4
    //======================================================
    wire lsb_eq4 = ~(pattern[8] ^ dna[8]);
    wire msb_eq4 = ~(pattern[9] ^ dna[9]);

    assign score4 = {lsb_eq4 & msb_eq4,
                     lsb_eq4 & ~msb_eq4};

    //======================================================
    // Base 5
    //======================================================
    wire lsb_eq5 = ~(pattern[10] ^ dna[10]);
    wire msb_eq5 = ~(pattern[11] ^ dna[11]);

    assign score5 = {lsb_eq5 & msb_eq5,
                     lsb_eq5 & ~msb_eq5};

    //======================================================
    // Base 6
    //======================================================
    wire lsb_eq6 = ~(pattern[12] ^ dna[12]);
    wire msb_eq6 = ~(pattern[13] ^ dna[13]);

    assign score6 = {lsb_eq6 & msb_eq6,
                     lsb_eq6 & ~msb_eq6};

    //======================================================
    // Base 7
    //======================================================
    wire lsb_eq7 = ~(pattern[14] ^ dna[14]);
    wire msb_eq7 = ~(pattern[15] ^ dna[15]);

    assign score7 = {lsb_eq7 & msb_eq7,
                     lsb_eq7 & ~msb_eq7};

endmodule
