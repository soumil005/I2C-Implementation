`timescale 1ns / 1ps
module master(clk, scl, sda, rw, targetAddr, writeData);
    
    input clk, rw;
    input [6:0] targetAddr;
    input [7:0] writeData;
    
    inout sda;
    output scl;
    
    reg reset;
    reg initiate;
    
    reg enable = 1'b0;
    reg drive_scl = 1'b0;
    reg sda_m;
    reg scl_m = 1'b0;
    
    assign sda = enable ? sda_m == 1'b0 ? 1'b0 : 1'bz : 1'bz;
    assign scl = drive_scl ? scl_m == 1'b0 ? 1'b0 : 1'bz : 1'bz;
    
    parameter IDLE = 4'd0, START = 4'd1, ADDR = 4'd2, ACK = 4'd5, READ = 4'd3, WRITE = 4'd4, WDATA = 4'd6, ACK2 = 4'd7, STOP = 4'd8, RDATA = 4'd9;
    
    reg [3:0] ps = IDLE;
    reg [3:0] counter = 4'd0;
    reg [3:0] addrCounter;
    reg [3:0] dataCounter;
    
    reg [7:0] readData;
    
    reg start;
    reg [1:0] count = 2'b0;
    
    always@(posedge clk) begin
        if(counter == 4'd9) begin
            scl_m <= ~scl_m;
            counter <= 4'd0;
        end
        else begin
            counter <= counter + 1;
        end
    end
    
    always@(posedge scl_m) begin
        if(reset == 1'b0 && ps == IDLE) begin
            ps <= START;
            initiate <= 1'b1;
        end
        else ps <= IDLE;
    end
    
    always@(negedge scl_m) begin
        if(!reset && initiate) begin
            case(ps)
                IDLE: begin
                    enable <= 1'b0;
                    drive_scl <= 1'b0;
                    initiate <= 1'b0;
                    reset <= 1'b1;
                end
                
                START: begin
                    drive_scl <= 1'b0;
                    enable <= 1'b1;
                    sda_m <= 1'b0;
                end
                
                ADDR: begin
                    if(count == 2'b01) begin
                        enable <= 1'b1;
                        sda_m <= targetAddr[addrCounter];
                    end
                    else begin
                        count <= count + 1;
                        start <= 1'b0;
                    end
                end
                
                READ: begin
                    enable <= 1'b1;
                    sda_m <= 1'b1;
                end

                WRITE: begin
                    enable <= 1'b1;
                    sda_m <= 1'b0;
                end         
                
                ACK: begin
                    enable <= 1'b0;
                end   
                
                RDATA: begin
                    enable <= 1'b0;
                end
                
                WDATA: begin
                    if(dataCounter > 4'd0) begin
                        enable <= 1'b1;
                        sda_m <= writeData[dataCounter - 1];
                    end
                    else begin
                        enable <= 1'b0;
                    end
                end
                 
                ACK2: begin
                    if(rw) begin
                        enable <= 1'b1;
                        sda_m <= 1'b0;
                    end
                    else begin
                        enable <= 1'b0;
                    end
                end
                
                STOP: begin
                    enable <= 1'b1;
                    sda_m <= 1'b1;
                end
                                
                
            endcase
        end
    end
    
    always@(posedge scl_m) begin
        if(!reset && initiate) begin
            case(ps)
                IDLE: begin
                
                end
                
                START: begin
                    drive_scl <= 1'b1;
                    ps <= ADDR;
                    start <= 1'b0;
                    count <= 1'b0;
                    addrCounter <= 4'd6;
                end
                
                ADDR: begin
                    if(count == 2'b01) begin
                        if(addrCounter == 4'd0) begin
                            if(rw) ps <= READ;
                            else ps <= WRITE;
                        end
                        else begin
                            ps <= ADDR;
                            if (count == 2'b01 && !start) begin
                                addrCounter <= 4'd6;
                                start <= 1'b1;
                            end
                            else if(start) addrCounter <= addrCounter - 1;
                        end
                    end

                end
                
                READ: begin
                    ps <= ACK;
                end

                WRITE: begin
                    ps <= ACK;
                end            
                
                ACK: begin
                    if(sda == 1'b0) begin   
                        if(rw) ps <= RDATA;
                        else ps <= WDATA;
                        dataCounter <= 4'd8;
                    end
                    else ps <= ACK;
                end
                
                WDATA: begin
                    if(dataCounter == 4'd0) begin
                        ps <= ACK2;
                    end
                    else begin
                        dataCounter <= dataCounter - 1;
                        ps <= WDATA;
                    end
                end
                
                RDATA: begin
                    if(dataCounter == 4'd0) begin
                        ps <= ACK2;
                    end
                    else begin
                        readData[ dataCounter - 1 ] <= sda;
                        dataCounter <= dataCounter - 1;
                        ps <= RDATA;
                    end
                end
                 
                ACK2: begin
                    if(rw) ps <= STOP;
                    else begin
                        if(sda == 1'b0) begin
                            ps <= STOP;
                        end
                        else ps <= ACK2;
                    end
                end
                
                STOP: begin

                    ps <= IDLE;
                end
                                
                
            endcase
        end
    end

endmodule
