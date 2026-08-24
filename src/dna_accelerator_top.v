//==========================================================
// dna_accelerator_top.v
// Top Module
//==========================================================

module dna_accelerator_top(

    input         clk,
    input         rst_n,

    // Control
    input         load_pattern,
    input         load_dna,

    // Inputs
    input  [15:0] pattern_in,
    input  [15:0] dna_in,

    // Outputs
    output [4:0]  similarity_out,
    output        match_out,
    output [31:0] position_out,

    // NEW: mutation-finding outputs
    output [15:0] mismatch_vector_out,  // packed 2-bit score per base (8 bases)
    output [7:0]  mismatch_mask_out,    // 1 bit per base: 1 = this base differs

    // NEW: unambiguous hardware-computed counts (each 0-8, always sum to 8)
    output [3:0]  exact_count_out,
    output [3:0]  transition_count_out,
    output [3:0]  transversion_count_out

);

    //------------------------------------------------------
    // Internal Signals
    //------------------------------------------------------

    wire [15:0] pattern_register;
    wire [15:0] dna_register;

    wire [31:0] position_counter;

    wire [1:0] score0;
    wire [1:0] score1;
    wire [1:0] score2;
    wire [1:0] score3;
    wire [1:0] score4;
    wire [1:0] score5;
    wire [1:0] score6;
    wire [1:0] score7;

    wire [4:0] similarity;

    //------------------------------------------------------
    // Registers
    //------------------------------------------------------

    registers reg_block(

        .clk(clk),
        .rst_n(rst_n),

        .load_pattern(load_pattern),
        .load_dna(load_dna),

        .pattern_in(pattern_in),
        .dna_in(dna_in),

        .pattern_register(pattern_register),
        .dna_register(dna_register),

        .position_counter(position_counter)

    );

    //------------------------------------------------------
    // Comparator
    //------------------------------------------------------

    comparator comp(

        .pattern(pattern_register),
        .dna(dna_register),

        .score0(score0),
        .score1(score1),
        .score2(score2),
        .score3(score3),
        .score4(score4),
        .score5(score5),
        .score6(score6),
        .score7(score7)

    );

    //------------------------------------------------------
    // Similarity Engine
    //------------------------------------------------------

    similarity_engine sim(

        .score0(score0),
        .score1(score1),
        .score2(score2),
        .score3(score3),
        .score4(score4),
        .score5(score5),
        .score6(score6),
        .score7(score7),

        .similarity(similarity)

    );

    //------------------------------------------------------
    // Mutation Counter (hardware-exact, unambiguous)
    //------------------------------------------------------

    wire [3:0] exact_count;
    wire [3:0] transition_count;
    wire [3:0] transversion_count;

    mutation_counter mcount(

        .score0(score0),
        .score1(score1),
        .score2(score2),
        .score3(score3),
        .score4(score4),
        .score5(score5),
        .score6(score6),
        .score7(score7),

        .exact_count(exact_count),
        .transition_count(transition_count),
        .transversion_count(transversion_count)

    );

    //------------------------------------------------------
    // Threshold Detector
    //------------------------------------------------------

    // Default threshold = 14
    assign match_out = (similarity == 5'd16);

    //------------------------------------------------------
    // Outputs
    //------------------------------------------------------

    assign similarity_out = similarity;

    assign position_out = position_counter;

    //------------------------------------------------------
    // Mutation-finding outputs
    //------------------------------------------------------
    // mismatch_vector: pack the raw per-base scores, base0 in bits[1:0],
    // base7 in bits[15:14]. Host decodes each 2-bit pair:
    //   10 = exact, 01 = transition, 00 = transversion.
    assign mismatch_vector_out = {score7, score6, score5, score4,
                                   score3, score2, score1, score0};

    // mismatch_mask: 1 bit per base, 1 = that base is NOT an exact match
    // (covers both transition and transversion). score[1] is the "exact"
    // bit, so "not exact" = ~score[1] | score[0].
    assign mismatch_mask_out[0] = ~score0[1] | score0[0];
    assign mismatch_mask_out[1] = ~score1[1] | score1[0];
    assign mismatch_mask_out[2] = ~score2[1] | score2[0];
    assign mismatch_mask_out[3] = ~score3[1] | score3[0];
    assign mismatch_mask_out[4] = ~score4[1] | score4[0];
    assign mismatch_mask_out[5] = ~score5[1] | score5[0];
    assign mismatch_mask_out[6] = ~score6[1] | score6[0];
    assign mismatch_mask_out[7] = ~score7[1] | score7[0];

    assign exact_count_out       = exact_count;
    assign transition_count_out  = transition_count;
    assign transversion_count_out = transversion_count;

endmodule
