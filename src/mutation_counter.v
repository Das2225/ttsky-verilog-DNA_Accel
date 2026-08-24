//==========================================================
// mutation_counter.v
// Directly counts, in hardware, how many of the 8 bases are
// exact matches, transitions, or transversions.
//
// This removes the ambiguity that a single weighted similarity
// number has (e.g. similarity=14 could mean "6 exact + 2
// transitions" or "7 exact + 1 transversion" - you can't tell
// which from the number alone). These three counts are exact
// and unambiguous, each 0-8, and always sum to 8.
//
// Score encoding (same as comparator.v):
//   2'b10 = exact match
//   2'b01 = transition
//   2'b00 = transversion
//==========================================================

module mutation_counter(

    input [1:0] score0,
    input [1:0] score1,
    input [1:0] score2,
    input [1:0] score3,
    input [1:0] score4,
    input [1:0] score5,
    input [1:0] score6,
    input [1:0] score7,

    output [3:0] exact_count,
    output [3:0] transition_count,
    output [3:0] transversion_count

);

    // is_exact[i]      = score[i] == 2'b10  (score[1]=1, score[0]=0)
    // is_transition[i] = score[i] == 2'b01  (score[1]=0, score[0]=1)
    // is_transversion[i]=score[i] == 2'b00  (score[1]=0, score[0]=0)
    //
    // These three conditions are mutually exclusive and exhaustive
    // for every base (a base is always exactly one of the three),
    // so each adder tree below is a simple parallel popcount.

    wire is_exact0 = score0[1] & ~score0[0];
    wire is_exact1 = score1[1] & ~score1[0];
    wire is_exact2 = score2[1] & ~score2[0];
    wire is_exact3 = score3[1] & ~score3[0];
    wire is_exact4 = score4[1] & ~score4[0];
    wire is_exact5 = score5[1] & ~score5[0];
    wire is_exact6 = score6[1] & ~score6[0];
    wire is_exact7 = score7[1] & ~score7[0];

    wire is_trans0 = ~score0[1] & score0[0];
    wire is_trans1 = ~score1[1] & score1[0];
    wire is_trans2 = ~score2[1] & score2[0];
    wire is_trans3 = ~score3[1] & score3[0];
    wire is_trans4 = ~score4[1] & score4[0];
    wire is_trans5 = ~score5[1] & score5[0];
    wire is_trans6 = ~score6[1] & score6[0];
    wire is_trans7 = ~score7[1] & score7[0];

    wire is_tv0 = ~score0[1] & ~score0[0];
    wire is_tv1 = ~score1[1] & ~score1[0];
    wire is_tv2 = ~score2[1] & ~score2[0];
    wire is_tv3 = ~score3[1] & ~score3[0];
    wire is_tv4 = ~score4[1] & ~score4[0];
    wire is_tv5 = ~score5[1] & ~score5[0];
    wire is_tv6 = ~score6[1] & ~score6[0];
    wire is_tv7 = ~score7[1] & ~score7[0];

    assign exact_count = is_exact0 + is_exact1 + is_exact2 + is_exact3 +
                          is_exact4 + is_exact5 + is_exact6 + is_exact7;

    assign transition_count = is_trans0 + is_trans1 + is_trans2 + is_trans3 +
                               is_trans4 + is_trans5 + is_trans6 + is_trans7;

    assign transversion_count = is_tv0 + is_tv1 + is_tv2 + is_tv3 +
                                 is_tv4 + is_tv5 + is_tv6 + is_tv7;

endmodule
