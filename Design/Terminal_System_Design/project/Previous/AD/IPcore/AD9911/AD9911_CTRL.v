module AD9911_FREQW_UPDATE #(parameter start_freqw = 0)(
    input     wire              CLK,
    input     wire              RESET_N,
    input     wire              OVER,
    input     wire   [31:0]     FREQW,          // ad9911 CTW0
    input     wire              FREQW_UPDATE,   // active on low level

    output    reg               INIT_OK,
    output    reg               FREQW_UPDATE_OVER,
    output    reg               TR,
    output    reg    [ 7:0]     ADDR,
    output    reg    [31:0]     DATA
    );

    reg  [31:0]   REGS[10:0];
    reg  [ 3:0]   STATE = 0;
    reg  [ 4:0]   NUM = 0;



    initial begin
        FREQW_UPDATE_OVER <= 0;
        TR <= 0;
        INIT_OK <= 0;
        REGS[0] <= 32'b00000000_00000000_00000000_00100000; //CSR
        REGS[1] <= 32'b00000000_10110011_00000100_00000000; //FR1
        REGS[2] <= 0;                                  //FR2
        REGS[3] <= 32'b00000000_11000000_00000011_00000000; //CFR
        REGS[4] <= 8947849*2 + start_freqw;//f/480*2^32                //CTW0   536880000  8948   FREQW * 480M / 2^32 = Fout
        REGS[5] <= 0;                                       //CPOW0
        REGS[6] <= 32'b00000000_00000001_11011111_11111111; //ACR
        REGS[7] <= 32'b00000000_00000000_00000000_00000000; //LSR
        REGS[8] <= 32'b00000000_00000000_00000000_00000000; //RDW
        REGS[9] <= 32'b00000000_00000000_00000000_00000000; //FDW
        REGS[10]<= 32'b10000000_00000000_00000000_00000000; //CTW1
    end



    always @(posedge CLK) begin
        if (!RESET_N) begin
            TR <= 0;
            NUM <= 0;
            INIT_OK <= 0;
            FREQW_UPDATE_OVER <= 0;
            STATE <= 0;
        end else begin
            case (STATE)
                0 : begin
                        INIT_OK <= 0;
                        TR <= 0;
                        NUM <= 0;
                        FREQW_UPDATE_OVER <= 0;
                        STATE <= 1;
                    end
                1 : begin
                        if (NUM>=11) begin
                            INIT_OK <= 1;
                            STATE <= 6;
                        end else begin
                            STATE <= 2;
                        end
                    end
                2 : begin
                        ADDR <= NUM;
                        DATA <= REGS[NUM];
                        STATE <= 3;
                    end
                3 : begin
                        TR <= 1;
                        STATE <= 4;
                    end
                4 : begin
                        NUM <= NUM+1;
                        STATE <= 5;
                    end
                5 : begin
                        if (OVER) begin
                            STATE <= 1;
                        end else begin
                            TR <= 0;
                        end
                    end
                6 : begin
                        if (FREQW_UPDATE) begin
                            ADDR <= 4; // address of ad9911 reg CTW0 
                            DATA <= start_freqw + FREQW; // 41.4MHz : 370440929
                            FREQW_UPDATE_OVER <= 0;
                            STATE <= 7;
                        end
                    end
                7 : begin
                        TR <= 1;
                        STATE <= 8;
                    end
                8 : begin
                        STATE <= 9;
                    end
                9 : begin
                        TR <= 0;
                        STATE <= 10;
                    end
                10: begin
                        if (OVER) begin
                            FREQW_UPDATE_OVER <= 1;
                            STATE <= 6;
                        end
                    end
                default: STATE <= 0;
            endcase
        end
    end
    
endmodule
