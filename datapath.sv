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

// TODO: implementar na prova
// funct7  funct3         instruction
/* 0000000 0000 */ parameter ADD  = 'b0000; // operando +
/* 0100000 1000 */ parameter SUB  = 'b1000; // operando -
/* 0000000 0001 */ parameter SLL  = 'b0001; // operando <<
/* 0000000 0010 */ parameter SLT  = 'b0010; // operando < (argumentos numeros inteiros)
/* 0000000 0011 */ parameter SLTU = 'b0011; // operando < (argumentos numeros naturais c/ zero)
/* 0000000 0100 */ parameter XOR  = 'b0100; // operando ^
/* 0000000 0101 */ parameter SRL  = 'b0101; // operando >>
/* 0100000 1101 */ parameter SRA  = 'b1101; // operando >>>
/* 0000000 0110 */ parameter OR   = 'b0110; // operando |
/* 0000000 0111 */ parameter AND  = 'b0111; // operando &

logic [NBITS-1:0] registrador [0:NREGS-1];

always_ff @(posedge clock)
  if (reset)
    for (int i=0; i < NREGS; i = i + 1)
      registrador[i] <= 0;
  else registrador[0] <= 0;

// TODO: implementar na prova
always_comb begin // barramentos indo para a ULA
  SrcA <= registrador[RS1];
  if(ALUSrc) SrcB <= IMM;
  else SrcB <= registrador[RS2];
  SrcAs <= SrcA;
  SrcBs <= SrcB;
end

// ****** ULA
// TODO: implementar na prova
always_comb
  case(ALUControl)
    SUB: ALUResult <= $signed(SrcA) - $signed(SrcB);
    SUBU: ALUResult <= SrcA - SrcB;
    OR: ALUResult <= SrcA | SrcB;
    AND: ALUResult <= SrcA & SrcB;
    XOR: ALUResult <= SrcA * SrcB;
    SLL: ALUResult <= SrcA << SrcB;
    SRA: ALUResult <= SrcA >>> SrcB;
    SLR: ALUResult <= SrcA >> SrcB;
    SLT: ALUResult <= $signed(SrcA) < $signed(SrcB);
    SLTU: ALUResult <= SrcA < SrcB;
    default ALUResult <= SrcA * SrcB;
  endcase

// TODO: implementar na prova
always_comb begin // barramentos vindo da ULA
  // o valor de um registrador pode ser usado para desvio e precisa ser repassado para o controller
  PCReg <= SrcA;

  // flags para desvio condicional, usadas para comparar os valores de dois resgistradores
  // por meio da operacao de subtracao da ULA
  {Carry,SUBResult} <= 0;
  Zero <= (ALUResult == 0);   // valores SrcA e SrcB sao iguais
  Neg <= (ALUResult < 0);    // SrcA < SrcB

  // barramentos indo para memoria de dados
  Address <= ALUResult[7:2]; // saida da ULA vai para endereco de memoria
  WriteData <= registrador[RS2];

  // mux para barramento Result, o qual esta indo para o banco de registradores
  if (link)
    // para salvar o valor proveniente do PC
    Result <= pclink;
  else 
    if (MemtoReg) Result <= ReadData;
    else Result <= ALUResult;
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
