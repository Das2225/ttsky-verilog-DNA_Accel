//==========================================================
// similarity_engine.v
// Computes the total similarity score with mutation weighting
//
// Scoring per base:
//   2'b10 (exact match)    → +2 to similarity
//   2'b01 (transition)     → +1 to similarity
//   2'b00 (transversion)   → +0 to similarity
//
// Total range: 0-16
// This encoding means the similarity ITSELF reveals mutation types:
//   similarity = 16   → all 8 bases exact
//   similarity = 15   → 7 exact + 1 transition
//   similarity = 14   → 6 exact + 2 transitions (or 7 exact + 1 transversion)
//   ...etc
//   similarity = 8    → all 8 bases are transitions (no transversions)
//   similarity = 7    → at least 1 transversion present
//   similarity = 0    → all 8 bases are transversions
//==========================================================

module similarity_engine(

    input [1:0] score0,
    input [1:0] score1,
    input [1:0] score2,
    input [1:0] score3,
    input [1:0] score4,
    input [1:0] score5,
    input [1:0] score6,
    input [1:0] score7,

    output [4:0] similarity

);

    // Per-base contribution: the 2-bit score IS the weight
    // score[1:0] = 2'b10 (exact)      → value 2
    // score[1:0] = 2'b01 (transition) → value 1
    // score[1:0] = 2'b00 (transversion)→ value 0
    // So we just sum all the 2-bit scores as numeric values
    
    wire [4:0] sum8 = {3'b000, score0} + {3'b000, score1} + 
                      {3'b000, score2} + {3'b000, score3} +
                      {3'b000, score4} + {3'b000, score5} +
                      {3'b000, score6} + {3'b000, score7};

    assign similarity = sum8;

endmodule
