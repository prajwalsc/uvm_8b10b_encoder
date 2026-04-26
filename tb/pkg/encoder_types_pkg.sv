// =============================================================================
// encoder_types_pkg.sv
// 8B/10B encoding tables, K-code constants, and running-disparity utilities
//
// Encoding follows IEEE 802.3-2012 Section 36, Tables 36-1a and 36-2.
//
// Bit ordering convention (matches the spec's abcdei fghj notation):
//   Dout[0] = a  (first bit transmitted)
//   Dout[5] = i
//   Dout[6] = f
//   Dout[9] = j  (last bit transmitted)
//   i.e.  Dout[9:0] = { j, h, g, f, i, e, d, c, b, a }
// =============================================================================

package encoder_types_pkg;

    // -------------------------------------------------------------------------
    // Running-disparity type
    // -------------------------------------------------------------------------
    typedef enum logic { RD_NEG = 1'b0, RD_POS = 1'b1 } rd_t;

    // -------------------------------------------------------------------------
    // Special K code-group 10-bit values (RD- and RD+)
    // Values are { j, h, g, f, i, e, d, c, b, a }
    // -------------------------------------------------------------------------

    // K28.5  — COMMA  (used in /I1/, /I2/, /C1/, /C2/)
    // RD-: abcdei=001111, fghj=0101
    localparam logic [9:0] K28_5_RD_NEG = 10'b10_1011_1100;  // 0x2BC
    // RD+: abcdei=110000, fghj=1010
    localparam logic [9:0] K28_5_RD_POS = 10'b01_0100_0011;  // 0x143

    // K27.7  — /S/  Start-of-Packet delimiter
    // RD-: abcdei=110110, fghj=1000  → a=1,b=1,c=0,d=1,e=1,i=0,f=1,g=0,h=0,j=0
    localparam logic [9:0] K27_7_RD_NEG = 10'b00_0101_1011;  // 0x05B
    // RD+: abcdei=001001, fghj=0111  → a=0,b=0,c=1,d=0,e=0,i=1,f=0,g=1,h=1,j=1
    localparam logic [9:0] K27_7_RD_POS = 10'b11_1010_0100;  // 0x3A4

    // K29.7  — /T/  End-of-Packet delimiter part 1
    // RD-: abcdei=101110, fghj=1000  → a=1,b=0,c=1,d=1,e=1,i=0,f=1,g=0,h=0,j=0
    localparam logic [9:0] K29_7_RD_NEG = 10'b00_0101_1101;  // 0x05D
    // RD+: abcdei=010001, fghj=0111  → a=0,b=1,c=0,d=0,e=0,i=1,f=0,g=1,h=1,j=1
    localparam logic [9:0] K29_7_RD_POS = 10'b11_1010_0010;  // 0x3A2

    // K23.7  — /R/  Carrier_Extend / EPD2 / EPD3
    // RD-: abcdei=111010, fghj=1000  → a=1,b=1,c=1,d=0,e=1,i=0,f=1,g=0,h=0,j=0
    localparam logic [9:0] K23_7_RD_NEG = 10'b00_0101_0111;  // 0x057
    // RD+: abcdei=000101, fghj=0111  → a=0,b=0,c=0,d=1,e=0,i=1,f=0,g=1,h=1,j=1
    localparam logic [9:0] K23_7_RD_POS = 10'b11_1010_1000;  // 0x3A8

    // K30.7  — /V/  Error_Propagation
    // RD-: abcdei=011110, fghj=1000
    localparam logic [9:0] K30_7_RD_NEG = 10'b00_0101_1110;  // 0x05E
    // RD+: abcdei=100001, fghj=0111
    localparam logic [9:0] K30_7_RD_POS = 10'b11_1010_0001;  // 0x3A1

    // D5.6  — second code-group of /I1/ (RD-neutral; same encoding both RDs)
    // EDCBA=00101 → abcdei=101001(RD-)=101001(RD+) neutral
    // HGF=110     → fghj=0110 neutral
    // a=1,b=0,c=1,d=0,e=0,i=1,f=0,g=1,h=1,j=0
    localparam logic [9:0] D5_6_NEUTRAL  = 10'b01_1010_0101;  // 0x1A5

    // D16.2 — second code-group of /I2/
    // EDCBA=10000 → abcdei=011011(RD-), 100100(RD+)
    // HGF=010     → fghj=0101 neutral
    // RD-: a=0,b=1,c=1,d=0,e=1,i=1,f=0,g=1,h=0,j=1
    localparam logic [9:0] D16_2_RD_NEG = 10'b10_1011_0110;  // 0x2B6
    // RD+: a=1,b=0,c=0,d=1,e=0,i=0,f=0,g=1,h=0,j=1
    localparam logic [9:0] D16_2_RD_POS = 10'b10_1000_0101;  // 0x285

    // D21.5 — second code-group of /C1/ Config (informational)
    // D2.2  — second code-group of /C2/ Config (informational)

    // -------------------------------------------------------------------------
    // 5B/6B encoding tables [EDCBA index 0..31]
    //   enc5b6b_neg[i] = 6-bit abcdei for RD-
    //   enc5b6b_pos[i] = 6-bit abcdei for RD+
    // Bit order: [5]=a, [4]=b, [3]=c, [2]=d, [1]=e, [0]=i
    // -------------------------------------------------------------------------
    localparam logic [5:0] ENC5B6B_NEG [32] = '{
        6'b100111, // D0  00000
        6'b011101, // D1  00001
        6'b101101, // D2  00010
        6'b110001, // D3  00011
        6'b110101, // D4  00100
        6'b101001, // D5  00101
        6'b011001, // D6  00110
        6'b111000, // D7  00111
        6'b111001, // D8  01000
        6'b100101, // D9  01001
        6'b010101, // D10 01010
        6'b110100, // D11 01011
        6'b001101, // D12 01100
        6'b101100, // D13 01101
        6'b011100, // D14 01110
        6'b010111, // D15 01111
        6'b011011, // D16 10000
        6'b100011, // D17 10001
        6'b010011, // D18 10010
        6'b110010, // D19 10011
        6'b001011, // D20 10100
        6'b101010, // D21 10101
        6'b011010, // D22 10110
        6'b111010, // D23 10111
        6'b110011, // D24 11000
        6'b100110, // D25 11001
        6'b010110, // D26 11010
        6'b110110, // D27 11011
        6'b001110, // D28 11100
        6'b101110, // D29 11101
        6'b011110, // D30 11110
        6'b101011  // D31 11111
    };

    localparam logic [5:0] ENC5B6B_POS [32] = '{
        6'b011000, // D0
        6'b100010, // D1
        6'b010010, // D2
        6'b110001, // D3  (neutral)
        6'b001010, // D4
        6'b101001, // D5  (neutral)
        6'b011001, // D6  (neutral)
        6'b000111, // D7
        6'b000110, // D8
        6'b100101, // D9  (neutral)
        6'b010101, // D10 (neutral)
        6'b110100, // D11 (neutral)
        6'b001101, // D12 (neutral)
        6'b101100, // D13 (neutral)
        6'b011100, // D14 (neutral)
        6'b101000, // D15
        6'b100100, // D16
        6'b100011, // D17 (neutral)
        6'b010011, // D18 (neutral)
        6'b110010, // D19 (neutral)
        6'b001011, // D20 (neutral)
        6'b101010, // D21 (neutral)
        6'b011010, // D22 (neutral)
        6'b000101, // D23
        6'b001100, // D24
        6'b100110, // D25 (neutral)
        6'b010110, // D26 (neutral)
        6'b001001, // D27
        6'b001110, // D28 (neutral)
        6'b010001, // D29
        6'b100001, // D30
        6'b010100  // D31
    };

    // -------------------------------------------------------------------------
    // 3B/4B encoding tables [HGF index 0..7]
    //   enc3b4b_neg[i] = 4-bit fghj for RD-  (f=[3], g=[2], h=[1], j=[0])
    //   enc3b4b_pos[i] = 4-bit fghj for RD+
    // -------------------------------------------------------------------------
    localparam logic [3:0] ENC3B4B_NEG [8] = '{
        4'b1011, // x.0
        4'b1001, // x.1 (neutral)
        4'b0101, // x.2 (neutral)
        4'b1100, // x.3
        4'b1101, // x.4
        4'b1010, // x.5 (neutral)
        4'b0110, // x.6 (neutral)
        4'b1110  // x.7
    };

    localparam logic [3:0] ENC3B4B_POS [8] = '{
        4'b0100, // x.0
        4'b1001, // x.1 (neutral)
        4'b0101, // x.2 (neutral)
        4'b0011, // x.3
        4'b0010, // x.4
        4'b1010, // x.5 (neutral)
        4'b0110, // x.6 (neutral)
        4'b0001  // x.7
    };

    // Special case: Dx.7 alternate encoding for D17, D18, D20 (to avoid
    // generating a comma).  When those data bytes use x.7, the 4-bit group
    // flips compared to normal x.7.
    //   D17 = 8'h11 → EDCBA=10001, HGF=000 — not x.7, no issue
    //   The special Dx.7 cases apply when EDCBA ∈ {17,18,20} AND HGF=7
    //   In that situation:
    //     RD-: fghj = 0111 (instead of 1110)
    //     RD+: fghj = 1000 (instead of 0001)
    localparam logic [3:0] ENC3B4B_D7_ALT_NEG = 4'b0111;
    localparam logic [3:0] ENC3B4B_D7_ALT_POS = 4'b1000;

    // -------------------------------------------------------------------------
    // Running disparity calculation for a 6-bit sub-block
    // Returns new RD after transmitting sub6
    // -------------------------------------------------------------------------
    function automatic rd_t rd_after_6b(input logic [5:0] sub6, input rd_t rd_in);
        int ones = $countones(sub6);
        if      (ones > 3) return RD_POS;
        else if (ones < 3) return RD_NEG;
        else begin
            // Equal 0s and 1s — check special disparity-neutral sub-blocks
            if (sub6 == 6'b000111) return RD_POS; // forced positive
            if (sub6 == 6'b111000) return RD_NEG; // forced negative
            return rd_in; // neutral — carries through
        end
    endfunction

    // Running disparity for a 4-bit sub-block
    function automatic rd_t rd_after_4b(input logic [3:0] sub4, input rd_t rd_in);
        int ones = $countones(sub4);
        if      (ones > 2) return RD_POS;
        else if (ones < 2) return RD_NEG;
        else begin
            if (sub4 == 4'b0011) return RD_POS;
            if (sub4 == 4'b1100) return RD_NEG;
            return rd_in;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Main 8B/10B data encode function
    //   Returns 10-bit code-group in { j, h, g, f, i, e, d, c, b, a } order
    //   and updates rd_out.
    // -------------------------------------------------------------------------
    function automatic logic [9:0] encode_data(
        input  logic [7:0] byte_in,
        input  rd_t        rd_in,
        output rd_t        rd_out
    );
        logic [4:0] edcba;
        logic [2:0] hgf;
        logic [5:0] sub6;
        logic [3:0] sub4;
        rd_t        rd_mid;
        logic       alt_d7;

        edcba = byte_in[4:0];   // EDCBA = bits [4:0]
        hgf   = byte_in[7:5];   // HGF   = bits [7:5]

        // 5B/6B
        if (rd_in == RD_NEG)
            sub6 = ENC5B6B_NEG[edcba];
        else
            sub6 = ENC5B6B_POS[edcba];

        rd_mid = rd_after_6b(sub6, rd_in);

        // Dx.7 alternate encoding check
        alt_d7 = (hgf == 3'b111) &&
                 (edcba == 5'd17 || edcba == 5'd18 || edcba == 5'd20);

        // 3B/4B
        if (rd_mid == RD_NEG) begin
            if (alt_d7) sub4 = ENC3B4B_D7_ALT_NEG;
            else        sub4 = ENC3B4B_NEG[hgf];
        end else begin
            if (alt_d7) sub4 = ENC3B4B_D7_ALT_POS;
            else        sub4 = ENC3B4B_POS[hgf];
        end

        rd_out = rd_after_4b(sub4, rd_mid);

        // Assemble { j, h, g, f, i, e, d, c, b, a }
        // sub6 = {a,b,c,d,e,i} → [5]=a,[4]=b,[3]=c,[2]=d,[1]=e,[0]=i
        // sub4 = {f,g,h,j}     → [3]=f,[2]=g,[1]=h,[0]=j
        return { sub4[0],   // j  [9]
                 sub4[1],   // h  [8]
                 sub4[2],   // g  [7]
                 sub4[3],   // f  [6]
                 sub6[0],   // i  [5]
                 sub6[1],   // e  [4]
                 sub6[2],   // d  [3]
                 sub6[3],   // c  [2]
                 sub6[4],   // b  [1]
                 sub6[5]    // a  [0]
               };
    endfunction

    // -------------------------------------------------------------------------
    // Encode a K code-group (special) — look up from pre-defined constants
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        K_S  = 3'd0,   // K27.7 /S/
        K_T  = 3'd1,   // K29.7 /T/
        K_R  = 3'd2,   // K23.7 /R/
        K_V  = 3'd3,   // K30.7 /V/
        K28_5_CODE = 3'd4  // K28.5 comma
    } kcode_sel_t;

    function automatic logic [9:0] encode_kcode(
        input  kcode_sel_t k,
        input  rd_t        rd_in,
        output rd_t        rd_out
    );
        logic [9:0] cg;
        case (k)
            K_S:        cg = (rd_in == RD_NEG) ? K27_7_RD_NEG : K27_7_RD_POS;
            K_T:        cg = (rd_in == RD_NEG) ? K29_7_RD_NEG : K29_7_RD_POS;
            K_R:        cg = (rd_in == RD_NEG) ? K23_7_RD_NEG : K23_7_RD_POS;
            K_V:        cg = (rd_in == RD_NEG) ? K30_7_RD_NEG : K30_7_RD_POS;
            K28_5_CODE: cg = (rd_in == RD_NEG) ? K28_5_RD_NEG : K28_5_RD_POS;
            default:    cg = 10'hx;
        endcase
        // All K-codes above are disparity-inverting (4:6 or 6:4 in each sub-block)
        // Derive new RD from the 10-bit output
        rd_out = rd_after_4b(cg[9:6], rd_after_6b(cg[5:0], rd_in));
        return cg;
    endfunction

    // -------------------------------------------------------------------------
    // Encode one IDLE code-group.
    // /I/ alternates /I1/ (K28.5 + D5.6) and /I2/ (K28.5 + D16.2).
    // The first /I/ after a packet always uses /I1/ to force RD back to negative.
    // This function returns a single K28.5 or data second code-group per call;
    // the caller manages the /I1/ vs /I2/ selection.
    // -------------------------------------------------------------------------

endpackage : encoder_types_pkg
