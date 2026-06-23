//======================================================================
//
// Design Name:    PRESENT Block Cipher — Chaotic S-Box Testbench
// Module Name:    PRESENT_ENCRYPT_CHAOTIC_TB
//
// Description:    Testbench for PRESENT_ENCRYPT_CHAOTIC.
//                 Tests all original vectors from PRESENT_ENCRYPT_TB
//                 plus paper-specific vectors and avalanche checks.
//
//                 Expected outputs (logistic-map S-Box, r=3.99):
//
//                 PRESENT spec boundary vectors:
//                   P=0x0000000000000000, K=0x00..00 -> 0x10aca214fd5ddabc
//                   P=0xFFFFFFFFFFFFFFFF, K=0xFF..FF -> 0x6ebdfad80d10d641
//
//                 Paper test vector (HelloIOT):
//                   P=0x48656C6C6F494F54, K=0x00..00 -> 0x823665aa8b8b6d27
//
//                 Avalanche effect target: ~57.81% bit difference
//
// Language: Verilog 2001
// Author:   Vishaanth R P (24MES1016)
// Date:     2024
// Platform: PYNQ-Z2 (XC7Z020CLG400-1)
//
//======================================================================

`timescale 1ns/1ps
`define DEL 1

// Original test vectors (same as present_encrypt_tb.v)
`define PLAINTEXT0  64'h0000000000000000
`define PLAINTEXT1  64'h834349fd8e99a23b
`define PLAINTEXT2  64'h9281dcb8a883a38c
`define PLAINTEXT3  64'hd392f4ec58356aeb
`define PLAINTEXT4  64'h3e5380018fc28d70

`define KEY0   80'h00000000000000000000
`define KEY1   80'h3014f4d8c37d9cc7e689
`define KEY2   80'h88239f8276ec927c8dec
`define KEY3   80'h610dcecce9a001117102
`define KEY4   80'h01f43bbc9b2001545339

// Paper-specific test vectors
`define HELLO_IOT   64'h48656C6C6F494F54   // "HelloIOT" ASCII
`define ALL_ONES    64'hFFFFFFFFFFFFFFFF
`define KEY_ONES    80'hFFFFFFFFFFFFFFFFFFFF

// Avalanche test: 1-bit flip in plaintext bit 0
`define AVAL_P0     64'h0000000000000000
`define AVAL_P1     64'h0000000000000001

// Avalanche test: 1-bit flip in key bit 0
`define KEYSENS_K0  80'h00000000000000000000
`define KEYSENS_K1  80'h00000000000000000001

//----------------------------------------------------------------------
module PRESENT_ENCRYPT_CHAOTIC_TB;

    // DUT signals
    wire [63:0] odat;
    reg  [63:0] idat  = 64'h0;
    reg  [79:0] key   = 80'h0;
    reg         load  = 1'b0;
    reg         clk   = 1'b0;

    // For avalanche analysis
    reg  [63:0] ref_cipher;
    integer     diff_bits, k;

    // Instantiate DUT
    PRESENT_ENCRYPT_CHAOTIC dut (
        .odat(odat),
        .idat(idat),
        .key (key),
        .load(load),
        .clk (clk)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    //------------------------------------------------------------------
    initial begin
        $display("=============================================================");
        $display("  PRESENT Cipher — Chaotic Logistic-Map S-Box (r=3.99)");
        $display("  Author   : Vishaanth R P (24MES1016), VIT Chennai");
        $display("  Platform : PYNQ-Z2 (XC7Z020CLG400-1)");
        $display("=============================================================");

        // ---- Block 1: All original vectors with KEY0 --------------------
        #10  load=1; idat=`PLAINTEXT0; key=`KEY0;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT1; key=`KEY0;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT2; key=`KEY0;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT3; key=`KEY0;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT4; key=`KEY0;
        #10  load=0;

        // ---- Block 2: Original vectors with KEY1 ------------------------
        #400 load=1; idat=`PLAINTEXT0; key=`KEY1;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT1; key=`KEY1;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT2; key=`KEY1;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT3; key=`KEY1;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT4; key=`KEY1;
        #10  load=0;

        // ---- Block 3: Original vectors with KEY2 ------------------------
        #400 load=1; idat=`PLAINTEXT0; key=`KEY2;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT1; key=`KEY2;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT2; key=`KEY2;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT3; key=`KEY2;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT4; key=`KEY2;
        #10  load=0;

        // ---- Block 4: Original vectors with KEY3 ------------------------
        #400 load=1; idat=`PLAINTEXT0; key=`KEY3;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT1; key=`KEY3;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT2; key=`KEY3;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT3; key=`KEY3;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT4; key=`KEY3;
        #10  load=0;

        // ---- Block 5: Original vectors with KEY4 ------------------------
        #400 load=1; idat=`PLAINTEXT0; key=`KEY4;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT1; key=`KEY4;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT2; key=`KEY4;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT3; key=`KEY4;
        #10  load=0;
        #400 load=1; idat=`PLAINTEXT4; key=`KEY4;
        #10  load=0;

        // ---- Paper test: All-zeros boundary -----------------------------
        $display("\n--- Paper Boundary Test: All-Zeros ---");
        #400 load=1; idat=`PLAINTEXT0; key=`KEY0;
        #10  load=0;
        #400;
        $display("P=0x0000000000000000 K=0x00..00 -> C=0x%016h", odat);
        $display("Expected             : 0x10aca214fd5ddabc");

        // ---- Paper test: All-ones boundary ------------------------------
        $display("\n--- Paper Boundary Test: All-Ones ---");
        #10  load=1; idat=`ALL_ONES; key=`KEY_ONES;
        #10  load=0;
        #400;
        $display("P=0xFFFFFFFFFFFFFFFF K=0xFF..FF -> C=0x%016h", odat);
        $display("Expected             : 0x6ebdfad80d10d641");

        // ---- Paper test: HelloIOT ---------------------------------------
        $display("\n--- Paper Test: HelloIOT ---");
        #10  load=1; idat=`HELLO_IOT; key=`KEY0;
        #10  load=0;
        #400;
        $display("P=HelloIOT(0x48656C6C6F494F54) K=0x00..00 -> C=0x%016h", odat);
        $display("Expected                       : 0x823665aa8b8b6d27");

        // ---- Avalanche effect: 1-bit plaintext flip ---------------------
        $display("\n--- Avalanche Effect Test (1-bit plaintext flip) ---");
        #10  load=1; idat=`AVAL_P0; key=`KEY0;
        #10  load=0;
        #400 ref_cipher = odat;

        #10  load=1; idat=`AVAL_P1; key=`KEY0;
        #10  load=0;
        #400;

        diff_bits = 0;
        for (k=0; k<64; k=k+1)
            if (ref_cipher[k] !== odat[k]) diff_bits = diff_bits + 1;

        $display("C(P=0x00..00) = 0x%016h", ref_cipher);
        $display("C(P=0x00..01) = 0x%016h", odat);
        $display("Bits flipped  = %0d/64 (%0.2f%%)", diff_bits, (diff_bits*100.0)/64.0);
        $display("Target        = ~57.81%%  (37 bits)");

        // ---- Key sensitivity: 1-bit key flip ----------------------------
        $display("\n--- Key Sensitivity Test (1-bit key flip) ---");
        #10  load=1; idat=`PLAINTEXT0; key=`KEYSENS_K0;
        #10  load=0;
        #400 ref_cipher = odat;

        #10  load=1; idat=`PLAINTEXT0; key=`KEYSENS_K1;
        #10  load=0;
        #400;

        diff_bits = 0;
        for (k=0; k<64; k=k+1)
            if (ref_cipher[k] !== odat[k]) diff_bits = diff_bits + 1;

        $display("C(K=0x00..00) = 0x%016h", ref_cipher);
        $display("C(K=0x00..01) = 0x%016h", odat);
        $display("Bits flipped  = %0d/64 (%0.2f%%)", diff_bits, (diff_bits*100.0)/64.0);

        #400;
        $display("\n=============================================================");
        $display("  Simulation Complete");
        $display("=============================================================");
        $finish;
    end

    // VCD dump for GTKWave
    initial begin
        $dumpfile("present_encrypt_chaotic_tb.vcd");
        $dumpvars(0, PRESENT_ENCRYPT_CHAOTIC_TB);
    end

endmodule
