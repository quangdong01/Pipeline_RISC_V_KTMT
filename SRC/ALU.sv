//---------------------------------------------------------------
//                        RISC-V Core
module execute (
  input               clk               ,    // Clock
  input               reset_n           ,  // Asynchronous reset active low
  input               ID_EX_mem_to_reg  ,
  input               ID_EX_reg_write   ,
  input               ID_EX_mem_write   ,
  input               ID_EX_mem_read    ,
  input               ID_EX_alu_src     ,
  input        [ 1:0] ID_EX_alu_op      ,
  input        [31:0] ID_EX_data1       ,
  input        [31:0] ID_EX_data2       ,
  input        [31:0] ID_EX_imm_gen     ,
  input        [ 4:0] ID_EX_rs1         ,
  input        [ 4:0] ID_EX_rs2         ,
  input        [ 4:0] ID_EX_rd          ,
  input        [ 3:0] ID_EX_inst_func   ,
  input        [ 1:0] forward_a         ,
  input        [ 1:0] forward_b         ,
  input        [31:0] wb_data           ,
  output logic [31:0] EX_MEM_alu_out    ,
  output logic        EX_MEM_mem_to_reg ,
  output logic        EX_MEM_reg_write  ,
  output logic        EX_MEM_mem_write  ,
  output logic        EX_MEM_mem_read   ,
  output logic [31:0] EX_MEM_dataB      ,
  output logic [ 4:0] EX_MEM_rd         ,
  output logic [31:0] alu_out           
);

//----------------------------------------------------------------
//         Signal Declaration
//----------------------------------------------------------------
logic [31:0] dataA;
logic [31:0] dataB;
logic [ 3:0] alu_ctrl;
logic [31:0] alu_inB;

//----------------------------------------------------------------
//         ALU Operations
//----------------------------------------------------------------
localparam [3:0]  ADD = 4'b0010,
                  SUB = 4'b0110,
                  AND = 4'b0000,
                  OR  = 4'b0001,
                  XOR = 4'b0111;

localparam [1:0]  R = 2'b10,
                  I = 2'b00,
                  B = 2'b01;

//----------------------------------------------------------------
//         ALU Cotrol
//----------------------------------------------------------------
always_comb begin : proc_alu_control
  case (ID_EX_alu_op)
  I: alu_ctrl = ADD;
  B: alu_ctrl = SUB;
  R: begin
      case (ID_EX_inst_func)
      4'b0000: alu_ctrl = ADD;
      4'b1000: alu_ctrl = SUB;
      4'b0111: alu_ctrl = AND;
      4'b0110: alu_ctrl = OR ;
      4'b0100: alu_ctrl = XOR;
        default : alu_ctrl = 4'b1111;
      endcase
  end
    default : alu_ctrl = 4'b1111;
  endcase
end

//----------------------------------------------------------------
//         ALU block
//----------------------------------------------------------------
always_comb begin : proc_ALU
  // DataA
  case (forward_a)
  2'b01: dataA = wb_data;
  2'b10: dataA = EX_MEM_alu_out;
    default : dataA = ID_EX_data1;
  endcase
  // DataB
  case (forward_b)
  2'b01: dataB = wb_data;
  2'b10: dataB = EX_MEM_alu_out;
    default : dataB = ID_EX_data2;
  endcase
  // ALU inputB
  alu_inB = (ID_EX_alu_src) ? ID_EX_imm_gen : dataB;
  // ALU output
  case (alu_ctrl)
  ADD: alu_out = dataA + alu_inB;
  SUB: alu_out = dataA - alu_inB;
  AND: alu_out = dataA & alu_inB;
  OR : alu_out = dataA | alu_inB;
  XOR: alu_out = dataA ^ alu_inB;
    default : alu_out = dataA;
  endcase
end

//----------------------------------------------------------------
//         Register EX/MEM
//----------------------------------------------------------------
always_ff @(posedge clk or negedge reset_n) begin : proc_EX_MEM_register
  if(~reset_n) begin
    EX_MEM_alu_out    <= 0;
    EX_MEM_mem_to_reg <= 0;
    EX_MEM_reg_write  <= 0;
    EX_MEM_mem_write  <= 0;
    EX_MEM_mem_read   <= 0;
    EX_MEM_dataB      <= 0;
    EX_MEM_rd         <= 0;
  end
  else begin
    EX_MEM_alu_out    <= alu_out;
    EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
    EX_MEM_reg_write  <= ID_EX_reg_write;
    EX_MEM_mem_write  <= ID_EX_mem_write;
    EX_MEM_mem_read   <= ID_EX_mem_read;
    EX_MEM_dataB      <= dataB;
    EX_MEM_rd         <= ID_EX_rd;
  end
end

endmodule : execute
