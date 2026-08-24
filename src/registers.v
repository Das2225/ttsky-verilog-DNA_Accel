//==========================================================
// registers.v
// Stores the pattern, DNA window and position counter
//==========================================================

module registers(
    input             clk,
    input             rst_n,

    // Control signals
    input             load_pattern,
    input             load_dna,

    // Inputs
    input      [15:0] pattern_in,
    input      [15:0] dna_in,

    // Outputs
    output reg [15:0] pattern_register,
    output reg [15:0] dna_register,
    output reg [31:0] position_counter
);

    //------------------------------------------------------
    // Pattern Register
    //------------------------------------------------------
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            pattern_register <= 16'b0;
        else if(load_pattern)
            pattern_register <= pattern_in;
    end

    //------------------------------------------------------
    // DNA Register
    //------------------------------------------------------
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            dna_register <= 16'b0;
        else if(load_dna)
            dna_register <= dna_in;
    end

    //------------------------------------------------------
    // Position Counter
    //------------------------------------------------------
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            position_counter <= 32'd0;
        else if(load_dna)
            position_counter <= position_counter + 1;
    end

endmodule
