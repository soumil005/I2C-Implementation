`timescale 1ns / 1ps

module slave(sda_s, scl_s);
    parameter RADDR = 3'b000, ACK = 3'b001, RDATA = 3'b010, ACK_2 = 3'b011;
    parameter address = 7'b1101111;
  
    inout sda_s;
    inout scl_s;
    
    reg sda;
   
    reg [2:0] state = 0;
    reg [7:0] data_reg; 
    reg [7:0] address_reg;
    
    reg [3:0] count = 4'b1000;
    reg m; //matching address
    reg write_enable = 0;
    reg start = 0;
    
    assign sda_s = (write_enable == 1) ? sda : 'bz;
    
    always@(negedge sda_s) begin
        if(start == 0 && scl_s == 1) begin
            start <= 1;
            count <= 4'b1000;
        end
    end
    
    always @(posedge sda_s) begin
		if (start == 1 && scl_s == 1) begin
			state <= RADDR;
			start <= 0;
			write_enable <= 0;
		end
	end
    
    always@(posedge scl_s) begin
        if(start == 1) begin
            case(state)
                RADDR: begin
                    if(count != 4'b0000) begin
                        address_reg[count - 1] <= sda_s;
                        count <= count - 1;
                    end
                    
                    else if(count == 4'b0000) begin
                        state <= ACK;
                    end
                end
                
                ACK: begin
                    if(address_reg[7:1] == address) begin
                        count <= 4'b1000;
                        state <= RDATA;
                    end
                end
                
                RDATA: begin
                    if(count != 4'b0000) begin
                        data_reg[count - 1] <= sda_s;
                        count <= count - 1;
                    end
                    else if(count == 4'b0000) begin
						state <= ACK_2;
					end
                     
                end
                
                ACK_2: begin
                    state <= RADDR;
                end
                
            endcase
        end
        
    end
    
    always@(negedge scl_s) begin
        case(state)
            RADDR: begin
                write_enable <= 1'b0;
            end
            
            ACK: begin
                sda <= 1'b0;
                write_enable <= 1'b1;
            end
            
            RDATA: begin
                write_enable <= 1'b0;
            end
            
            ACK_2: begin
                sda <= 1'b0;
                write_enable <= 1'b1;
            end
            
        endcase
        
    end
    
endmodule
