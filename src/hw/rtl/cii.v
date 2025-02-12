module cii (
    input   wire		clk,
	input	wire		reset_n,
	input 	wire        cii_req,         
	input 	wire        cii_hdr_poisoned,
	input 	wire [3:0]  cii_hdr_first_be,
	input 	wire        cii_wr,          
	input 	wire [9:0]  cii_addr,        
	input 	wire [31:0] cii_dout,        
	output  wire        cii_override_en, 
	output  wire [31:0] cii_override_din,
	output  wire        cii_halt        
);

	reg	    cii_override_en_q;
	reg [31:0]  cii_override_din_q;
	reg 	    cii_halt_q;
	reg [6:0]   cii_req_q;

	wire	    deassert_halt;
	
	// output assignment
	assign cii_halt = cii_halt_q;
	assign cii_override_en = cii_override_en_q;
	assign cii_override_din = cii_override_din_q;

	// cii_req shift register
	always @(posedge clk or negedge reset_n)
	  if (!reset_n)
            cii_req_q <= 7'h00;
          else
	        cii_req_q <= {cii_req_q[5:0],cii_req};

	// deassert cii_halt upon cii_req
	assign deassert_halt = cii_req & ~cii_req_q[0];

	always @(posedge clk or negedge reset_n)
	  begin
	    if (!reset_n) begin
	       cii_halt_q <= 1'b1;
	       cii_override_en_q <= 1'b0;
	       cii_override_din_q <= 32'd0;
	       end 
	    else begin
			if (deassert_halt) begin
				cii_halt_q <= 1'b0;

				// Override Capabilities Pointer at byte offset 0x34
				if (cii_addr == 10'h00d) begin          // dword addr=0x00d
					if (!cii_wr) begin
						cii_override_en_q <= 1'b1;	    // override
						cii_override_din_q <= 32'h060;  // read data with 0x60
					end
				end
				
				// Insert VPD Capability at byte offset 0x60
				if (cii_addr == 10'h018) begin          // dword addr=0x018
					if (!cii_wr) begin
						cii_override_en_q <= 1'b1;		  // override read data
						cii_override_din_q <= 32'h04003;  // next cap. ptr=0x40, ID=0x03
					end
				end
			end
			else begin
				cii_halt_q <= 1'b1;
				cii_override_en_q <= 1'b0;
				cii_override_din_q <= 32'h00000000;
			end 
		end
	 end
endmodule
