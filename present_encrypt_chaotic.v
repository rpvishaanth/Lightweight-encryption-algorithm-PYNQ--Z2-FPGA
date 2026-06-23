//======================================================================
//
// Design Name:    PRESENT Block Cipher — Chaotic S-Box Version
// Module Name:    PRESENT_ENCRYPT_CHAOTIC
//
// Description:    PRESENT Encryption with logistic-map chaotic S-Box.
//                 Structurally identical to PRESENT_ENCRYPT (present_encrypt.v)
//                 with one change: PRESENT_ENCRYPT_SBOX is replaced by
//                 PRESENT_ENCRYPT_SBOX_CHAOTIC in all 16 nibble positions
//                 and in the key schedule S-Box slot.
//
//                 This is the module packaged as IP in Vivado and
//                 connected to the PYNQ-Z2 PS via AXI GPIO.
//
// Port Map (matches PRESENT_ENCRYPT exactly):
//   odat [63:0]  — 64-bit ciphertext output
//   idat [63:0]  — 64-bit plaintext input
//   key  [79:0]  — 80-bit encryption key
//   load         — active-high load: latch idat+key, reset round to 1
//   clk          — clock (100 MHz FCLK_CLK0 from ZYNQ PS)
//
// Block Design Connection:
//   idat[63:0]  <- xlconcat_0.dout  (axi_gpio_0 ch1[31:0] + ch2[31:0])
//   key[79:0]   <- xlconcat_1.dout  (axi_gpio_1 ch1[31:0] + ch2[31:0]
//                                    + axi_gpio_2 ch1[15:0])
//   load        <- axi_gpio_2 ch2[0]  (single-bit control)
//   clk         <- ZYNQ FCLK_CLK0 (100 MHz)
//   odat[63:0]  -> xlslice_0 [63:32] + xlslice_1 [31:0]
//               -> axi_gpio_3 ch1[31:0] + ch2[31:0]
//
// Dependencies:
//   present_encrypt_sbox_chaotic.v   (logistic-map S-Box)
//   present_encrypt_pbox.v           (standard PRESENT P-Layer, unchanged)
//
// Language:    Verilog 2001
// Author:      Vishaanth R P (24MES1016)
// Supervisor:  Dr. Balakrishnan R, SENSE, VIT Chennai
// Date:        2024
// Platform:    PYNQ-Z2 (XC7Z020CLG400-1)
//
//======================================================================

`timescale 1ns/1ps

module PRESENT_ENCRYPT_CHAOTIC (
    output [63:0] odat,   // 64-bit ciphertext output
    input  [63:0] idat,   // 64-bit plaintext input
    input  [79:0] key,    // 80-bit key input
    input         load,   // load command (active high, 1 clock pulse)
    input         clk     // clock — 100 MHz from ZYNQ FCLK_CLK0
);

//---------wires, registers----------
reg  [79:0] kreg;               // key register
reg  [63:0] dreg;               // data register
reg  [4:0]  round;              // round counter (1..31)
wire [63:0] dat1, dat2, dat3;   // intermediate data buses
wire [79:0] kdat1, kdat2;       // intermediate subkey buses

//---------combinational processes----------

// AddRoundKey: XOR state with upper 64 bits of round key
assign dat1 = dreg ^ kreg[79:16];
assign odat = dat1;

// Key schedule: rotate 61 bits left
assign kdat1        = {kreg[18:0], kreg[79:19]};
assign kdat2[14:0 ] = kdat1[14:0 ];
assign kdat2[19:15] = kdat1[19:15] ^ round;   // XOR with round counter
assign kdat2[75:20] = kdat1[75:20];

//---------instantiations----------

// 16 chaotic S-Box instances (one per 4-bit nibble of 64-bit state)
genvar i;
generate
    for (i=0; i<64; i=i+4) begin: sbox_loop
        PRESENT_ENCRYPT_SBOX_CHAOTIC USBOX (
            .odat(dat2[i+3:i]),
            .idat(dat1[i+3:i])
        );
    end
endgenerate

// P-Layer (standard PRESENT bit permutation — unchanged)
PRESENT_ENCRYPT_PBOX UPBOX (
    .odat(dat3),
    .idat(dat2)
);

// Chaotic S-Box for key expansion (top nibble of rotated key)
PRESENT_ENCRYPT_SBOX_CHAOTIC USBOXKEY (
    .odat(kdat2[79:76]),
    .idat(kdat1[79:76])
);

//---------sequential processes----------

// Data register: latch plaintext on load, else advance pipeline
always @(posedge clk) begin
    if (load)
        dreg <= idat;
    else
        dreg <= dat3;
end

// Key register: latch key on load, else update via key schedule
always @(posedge clk) begin
    if (load)
        kreg <= key;
    else
        kreg <= kdat2;
end

// Round counter: reset to 1 on load, increment each clock
always @(posedge clk) begin
    if (load)
        round <= 5'd1;
    else
        round <= round + 5'd1;
end

endmodule
