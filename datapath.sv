`default_nettype none

/************************************************************/
// Datapath eh composto por:
// - Register FIle
// - ULA
/************************************************************/

module datapath #(parameter NBITS = 8, NREGS=32, WIDTH_ALUF=4) (
  input logic clock, reset,

  // Controller
  input logic  [$clog2(NREGS)-1:0] RS2,  RS1, RD,
  input logic signed [NBITS-1:0] IMM,
  input logic [WIDTH_ALUF-1:0] ALUControl,
  output logic Zero, Neg, Carry,
  input logic ALUSrc,
  input logic MemtoReg,
  input logic RegWrite,
  input logic link,  // valida pclink para ser salvo no registrador RD 
  input logic [NBITS-1:0] pclink, // valor proveniente do PC a ser salvo em registrador RD
  output logic [NBITS-1:0] PCReg, // registrador RS1 (SrcA) volta para o PC

  // Memoria ou cache
  output logic [NBITS-1:2] Address, 
  output logic [NBITS-1:0] WriteData,
  input logic [NBITS-1:0] ReadData,

  zoi z);

logic [NBITS-1:0] SrcA, SrcB;
logic signed [NBITS-1:0] SrcAs, SrcBs;  // SrcA e SrcB vistas como numeros inteiros
logic [NBITS-1:0] SUBResult;  // para poder recuperar o vai-um
logic [NBITS-1:0] ALUResult, Result;

// ****** banco de registradores
parameter SLT = 'b0010;

logic [NBITS-1:0] registrador [0:NREGS-1];

always_ff @(posedge clock)
  if (reset)
    for (int i=0; i < NREGS; i = i + 1)
      registrador[i] <= 0;
  else if(RD != 0 && RegWrite) registrador[RD] <= Result;

always_comb begin // barramentos indo para a ULA
  SrcA <= registrador[RS1];
  if (ALUSrc) SrcB <= IMM;
  else SrcB <= registrador[RS2];
  SrcAs <= SrcA;
  SrcBs <= SrcB;
end

// ****** ULA

always_comb
  case(ALUControl)
    SLT: ALUResult <= SrcA < SrcB;
    default ALUResult <= SrcA + SrcB;
  endcase

always_comb begin // barramentos vindo da ULA
  // o valor de um registrador pode ser usado para desvio e precisa ser repassado para o controller
  PCReg <= SrcA;

  // flags para desvio condicional, usadas para comparar os valores de dois resgistradores
  // por meio da operacao de subtracao da ULA
  {Carry,SUBResult} <= 0;
  Zero <= 0;   // valores SrcA e SrcB sao iguais
  Neg <= 0;    // SrcA < SrcB

  // barramentos indo para memoria de dados
  Address <= ALUResult[7:2]; // saida da ULA vai para endereco de memoria
  WriteData <= registrador[RS2];

  // mux para barramento Result, o qual esta indo para o banco de registradores
  if (link)
    // para salvar o valor proveniente do PC
    Result <= pclink;
  else 
    Result <= ALUResult;
end

// a zoiada
always_comb begin
  z.SrcA <= SrcA;
  z.SrcB <= SrcB;
  z.ALUResult <= ALUResult;
  z.Result <= Result;
  z.WriteData <= WriteData;
  z.ReadData <= ReadData;
  z.MemtoReg <= MemtoReg;
  z.RegWrite <= RegWrite;
  z.registrador <= registrador;
end

endmodule
