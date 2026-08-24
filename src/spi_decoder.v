module bioaccel_spi_decoder(

    input  wire       sclk,
    input  wire       rst_n,
    input  wire       cs_n,

    input  wire [7:0] rx_data,
    input  wire       rx_valid,

    output reg  [7:0] tx_data,

    output reg        load_pattern,
    output reg        load_dna,

    output reg [15:0] pattern_in,
    output reg [15:0] dna_in,

    input  wire [4:0] similarity,
    input  wire       match,
    input  wire [31:0] position,

    // NEW: mutation-finding readback
    input  wire [15:0] mismatch_vector,
    input  wire [7:0]  mismatch_mask,

    // NEW: unambiguous hardware-computed counts
    input  wire [3:0]  exact_count,
    input  wire [3:0]  transition_count,
    input  wire [3:0]  transversion_count

);

    localparam CMD_WRITE  = 8'h01;
    localparam CMD_READ   = 8'h02;
    localparam CMD_STREAM = 8'h03;

localparam WAIT_CMD   = 3'd0;
localparam WAIT_ADDR  = 3'd1;
localparam WAIT_DATA  = 3'd2;
localparam WAIT_SPACER = 3'd5;   // NEW: absorbs one extra "wait" byte after
                                   // ADDR, giving tx_data time to settle
                                   // before spi_lite_tx needs to load it
localparam WAIT_DUMMY = 3'd3;
localparam STREAM     = 3'd4;

    reg [2:0] state;

    reg [7:0] command;
    reg [3:0] address;   // widened 3->4 bits: addresses 0-7 were already
                          // all used (0-3 write, 4-7 read), so the new
                          // mutation-readback addresses (8-10) need a
                          // 4th bit. The wire protocol is unchanged -
                          // address still arrives as a full 8-bit byte,
                          // we're just using one more bit of it.

always @(posedge sclk or negedge rst_n)
begin

    if(!rst_n)
    begin

        state <= WAIT_CMD;

        command <= 8'h00;
        address <= 4'd0;

        pattern_in <= 16'h0000;
        dna_in     <= 16'h0000;

        load_pattern <= 1'b0;
        load_dna     <= 1'b0;

        tx_data <= 8'h00;

    end

    else
    begin

        load_pattern <= 1'b0;
        load_dna     <= 1'b0;

        if(cs_n)
        begin

            state <= WAIT_CMD;

        end

        else if(rx_valid)
        begin

            case(state)

            WAIT_CMD:
            begin

                command <= rx_data;

                case(rx_data)

                    CMD_WRITE:
                        state <= WAIT_ADDR;

                    CMD_READ:
                        state <= WAIT_ADDR;

                    CMD_STREAM:
                        state <= STREAM;

                    default:
                        state <= WAIT_CMD;

                endcase

            end

            WAIT_ADDR:
            begin

                address <= rx_data[3:0];

                if(command == CMD_WRITE)
                begin

                    state <= WAIT_DATA;

                end

                else if(command == CMD_READ)
                begin

                    case(rx_data[3:0])

                        4'd4:
                            tx_data <= {3'b000, similarity};

                        4'd5:
                            tx_data <= {7'b0000000, match};

                        4'd6:
                            tx_data <= position[7:0];

                        4'd7:
                            tx_data <= position[15:8];

                        4'd8:
                            tx_data <= mismatch_vector[7:0];    // bases 0-3

                        4'd9:
                            tx_data <= mismatch_vector[15:8];   // bases 4-7

                        4'd10:
                            tx_data <= mismatch_mask;           // 1 bit/base

                        4'd11:
                            tx_data <= {4'b0000, exact_count};       // 0-8, exact

                        4'd12:
                            tx_data <= {4'b0000, transition_count};  // 0-8, transitions

                        4'd13:
                            tx_data <= {4'b0000, transversion_count};// 0-8, transversions

                        default:
                            tx_data <= 8'h00;

                    endcase

                    state <= WAIT_SPACER;

                end

                else
                begin

                    state <= WAIT_CMD;

                end

            end

            WAIT_DATA:
            begin

                case(address)

                    3'd0:
                    begin
                        $display(">>> PATTERN LOW: addr=%0d rx=%02h", address, rx_data);
                        pattern_in[7:0] <= rx_data;

                    end

                    3'd1:
                    begin
                        $display(">>> PATTERN HIGH: rx=%02h", rx_data);

                        pattern_in[15:8] <= rx_data;

                        load_pattern <= 1'b1;

                    end

                    3'd2:
                    begin
                        $display(">>> DNA LOW: rx=%02h", rx_data);

                        dna_in[7:0] <= rx_data;

                    end

                    3'd3:
                    begin
                        $display(">>> DNA HIGH: rx=%02h", rx_data);

                        dna_in[15:8] <= rx_data;

                        load_dna <= 1'b1;

                    end

                    default:
                    begin
                            $display(">>> DEFAULT CASE! address=%0d", address);
                    end

                endcase

                state <= WAIT_CMD;

            end

            WAIT_SPACER:
            begin

                // Just absorbs one full byte's worth of clock edges,
                // ignoring rx_data entirely. This guarantees tx_data
                // (computed in WAIT_ADDR, one edge after that byte's
                // rx_valid) has long since settled before the NEXT byte's
                // byte_start fires and spi_lite_tx loads it.

                state <= WAIT_DUMMY;

            end

            WAIT_DUMMY:
            begin

                state <= WAIT_CMD;

            end

            STREAM:
            begin

                dna_in <= {dna_in[7:0], rx_data};

                load_dna <= 1'b1;

                state <= STREAM;

            end

            default:
            begin

                state <= WAIT_CMD;

            end

            endcase

        end

    end

end

endmodule
