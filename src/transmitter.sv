/***********************************************************************************
 * Copyright (C) 2023 Kirill Turintsev <billiscreezo228@gmail.com>
 * See LICENSE file for licensing details.
 *
 * This file contains Gold code transmitter module
 *
 ***********************************************************************************/

package transmitter_p;

endpackage 

module transmitter #(
        int SYS_CLK                 = 100,  // MHz
        int SYM_LEN                 = 100,  // ns

        int M_WIDTH                 = 31,
        bit [M_WIDTH-1:0] M0_VAL    = 'b1111100110100100001010111011000,
        bit [M_WIDTH-1:0] M1_VAL    = 'b1111101110001010110100001100100,

        int CODE_DELAY              = 1     // usec
     )(
        
        input   logic           aresetn,
        input   logic           strobe,

        input   logic           s_axis_aclk,
        axistream_if.slave      s_axis,

        output  logic           phase_out

    );
   
// ==============================================
// ===================== Defines
// ==============================================

// ===================== Delay counters
    localparam int SYM_DELAY_NUM    = int'($ceil((SYM_LEN * SYS_CLK) / 1000));
    localparam int CODE_DELAY_NUM   = int'($ceil(CODE_DELAY * SYS_CLK)) + SYM_DELAY_NUM; // code delay + 1 sym delay

    logic [$clog2(SYM_DELAY_NUM):0] sym_del_cnt;

    logic [$clog2(CODE_DELAY_NUM):0] code_del_cnt;

    logic [$clog2(M_WIDTH)-1:0] gold_bit_number;

// ===================== M-sequences
    logic [$clog2(M_WIDTH)-1:0] m_number;
    logic [M_WIDTH-1:0] m_sh, m_out;

// ===================== FSM
    typedef enum {
        S_IDLE,         //  Waiting for strobe signal
        S_GET_NUMBER,   //  Getting the Gold code number
        S_MAKE_CODE,    //  Getting the Gold code
        S_CODE_OUT,     //  Gold code issuance
        S_PAUSE         //  Pause between Gold codes
    } state_t;

    state_t state;

// ==============================================
// ===================== Getting the Gold code
// ==============================================

    assign m_number = s_axis.tdata;         // Getting the Gold code number

    always_ff @(posedge s_axis_aclk)        // Sequence shift for Gold code
        if(s_axis.tvalid && s_axis.tready)
            m_sh <= (M1_VAL << (M_WIDTH-m_number)) | (M1_VAL >> m_number);

    always_ff @(posedge s_axis_aclk)        // Getting ^ sequences (Getting the Gold code)
        if(state == S_MAKE_CODE)
            m_out <= M0_VAL ^ m_sh;

// ==============================================
// ===================== FSM
// ==============================================

    always_ff @(posedge s_axis_aclk)
        if(!aresetn) begin
            state           <= S_IDLE;
            s_axis.tready   <= '0;
        end else begin
            (* full_case, parallel_case *) case(state)

                S_IDLE: begin
                    if(strobe) begin

                        s_axis.tready <= '1;

                        state <= S_GET_NUMBER;

                    end
                end

                S_GET_NUMBER: begin
                    if(s_axis.tvalid && s_axis.tready) begin

                        s_axis.tready   <= '0;

                        gold_bit_number <= '0;
                        sym_del_cnt     <= '0;

                        state <= S_MAKE_CODE;

                    end
                        

                end

                S_MAKE_CODE: begin
                    state <= S_CODE_OUT;
                end

                S_CODE_OUT: begin
                    if(sym_del_cnt == SYM_DELAY_NUM - 1) begin
                        gold_bit_number <= gold_bit_number + 1'b1;
                        sym_del_cnt     <= '0;
                    end else
                        sym_del_cnt     <= sym_del_cnt     + 1'b1; 

                    if(gold_bit_number == M_WIDTH - 1) begin

                        code_del_cnt    <= '0;
                        state           <= S_PAUSE;

                    end

                end

                S_PAUSE: begin
                    if(code_del_cnt == CODE_DELAY_NUM - 1)
                        state           <= S_IDLE;
                    else
                        code_del_cnt    <= code_del_cnt + 1'b1; 
                end

            endcase
        end

// ==============================================
// ===================== Gold code issuance
// ==============================================

    assign phase_out = m_out[gold_bit_number];
  

endmodule : transmitter
