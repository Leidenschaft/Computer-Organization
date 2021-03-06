----------------------------------------------------------------
-- Simple Microprocessor Design (ESD Book Chapter 3)
-- Copyright 2001 Weijun Zhang
--
-- data_path composed of Multiplexor, Register File and ALU
-- VHDL structural modeling
-- data_path.vhd
----------------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;  
use ieee.numeric_std.all;
entity data_path is				
port(	clock:	in 	std_logic;
	rst:		in 	std_logic;
--	downloadingButton: in std_logic;	
	RegDst: in std_logic_vector(1 downto 0);
	RegWrite: IN  std_logic_vector(2 downto 0);
   RegRead : IN  std_logic_vector(1 downto 0);
   MemtoReg: in std_logic_vector(1 downto 0);
	ALUSrcA: in std_logic_vector(1 downto 0);
	ALUSrcB: in std_logic_vector(1 downto 0);
	ALUOp: in std_logic_vector(3 downto 0);
	MemRead: in std_logic;
	MemWrite: in std_logic;
	IorD: in std_logic;
	IRWrite: in std_logic;
	PCWrite: in std_logic;
	PCSource: in std_logic;
	PCWriteCond: in std_logic;
	ALU_zero: out std_logic;
	SE: in std_logic_vector(2 downto 0);
	instructions: out std_logic_vector(15 downto 0);
	ram1_data: inout std_logic_vector(15 downto 0);
	ram1_addr: out std_logic_vector(15 downto 0);
   data_ready: in std_logic;
	ram1_oe,ram1_we,ram1_en,wrn,rdn: out std_logic;
	--clock: in std_logic;
	tbre,tsre: in std_logic;
	s1_out,s2_out,s3_out,s4_out,s6_out,s7_out,s8_out,s9_out,s10_out,s11_out,s12_out,s13_out,s14_out,s15_out: out std_logic_vector(15 downto 0);
	SWSP_Control: in std_logic;
	rxd: in std_logic;
	txd:out std_logic;
--	timerEnable: in std_logic;
--	IsOverFlow: out std_logic;
	seg1: out std_logic_vector(6 downto 0)
	--s16_out: out std_logic_vector(2 downto 0);
);
end data_path;

architecture struct of data_path is

component serial_buffer is
Port(
	clock,reset: in std_logic;
	--downloadingButton: in std_logic;
 	MemRead: in std_logic;
	MemWrite: in std_logic;
	s3: in std_logic_vector(15 downto 0);
	s4: in std_logic_vector(15 downto 0);
	ram1_data: inout std_logic_vector(15 downto 0);
	ram1_addr: out std_logic_vector(15 downto 0);
   data_ready: in std_logic;
	tbre,tsre: in std_logic;
	ram1_oe,ram1_we,ram1_en,wrn,rdn: out std_logic;
	rxd: in std_logic;
	txd:out std_logic;
	seg1: out std_logic_vector(6 downto 0);
	data_send_finished_from_port_2,data_received_from_port_2: out std_logic;
	SpecialAddrVisit:out std_logic_vector(1 downto 0);
	data_from_port_2: out std_logic_vector(7 downto 0)
	
	
	);
end component;
component register_file is
port ( 	clock	: 	in std_logic; 	
	rst	: 	in std_logic;
	RegWrite	: 	in std_logic_vector(2 downto 0);
	RegRead	: 	in std_logic_vector(1 downto 0);
	write_addr	: 	in std_logic_vector(2 downto 0);  
	read_1_addr	: 	in std_logic_vector(2 downto 0);
	read_2_addr	: 	in std_logic_vector(2 downto 0);
	write_data	: 	in std_logic_vector(15 downto 0);
	data_to_A	: 	out std_logic_vector(15 downto 0);
	data_to_B	:	out std_logic_vector(15 downto 0)
);
end component;

component alu is
port(	  
	reset:		in std_logic;
	input_1:	in std_logic_vector(15 downto 0);--MSB of A,B are sign bits.
	input_2: in std_logic_vector(15 downto 0);
	Sel: in std_logic_vector(3 downto 0);
	Res:	out std_logic_vector(15 downto 0);
   Zero: out std_logic
);
end component;

component multiplexor is
port(	  input_1:	in std_logic_vector(15 downto 0);--MSB of A,B are sign bits.
		  input_2:	in std_logic_vector(15 downto 0);
		  control_signal: in std_logic;
		  output: out std_logic_vector(15 downto 0)--make sure the input is finished;
);
end component;

component single_register is
port(	 clk,rst:	in std_logic;
		single_register_enable: in std_logic;
		single_register_in:	in std_logic_vector(15 downto 0);
		single_register_out:	out std_logic_vector(15 downto 0)
);
end component;
component multiplexor_two_bit is
generic(n:natural:=16);
port(	  input_1:	in std_logic_vector(n-1 downto 0);
		  input_2:	in std_logic_vector(n-1 downto 0);
		  input_3:  in std_logic_vector(n-1 downto 0);
		  control_signal: in std_logic_vector(1 downto 0);
		  output: out std_logic_vector(n-1 downto 0)
);
end component;
component multiplexor_three_bit is
generic(n:natural:=16);
port(	  input_1:	in std_logic_vector(n-1 downto 0);
		  input_2:	in std_logic_vector(n-1 downto 0);
		  input_3:  in std_logic_vector(n-1 downto 0);
		  input_4:  in std_logic_vector(n-1 downto 0);
		  input_5:  in std_logic_vector(n-1 downto 0);
		  input_6:  in std_logic_vector(n-1 downto 0);
		  control_signal: in std_logic_vector(2 downto 0);
		  output: out std_logic_vector(n-1 downto 0)
);
end component;
component dflip_flop_falling is
port(
      clk : in std_logic;
      rst : in std_logic;
      data_in : in std_logic_vector(15 downto 0);
      data_out : out std_logic_vector(15 downto 0)
);
end component;
signal s4,s3:std_logic_vector(15 downto 0);--ram1_data is ram1_data,ram1_addr<=s3;
signal s1,s2,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15,s17,s18,s19: std_logic_vector(15 downto 0); 
signal PCWriteTotal,data_send_finished_from_port_2,data_received_from_port_2:std_logic;
signal SpecialAddrVisit:std_logic_vector(1 downto 0);
signal serialStatusBits,data_from_port_2_extension: std_logic_vector(15 downto 0);
signal data_from_port_2: std_logic_vector(7 downto 0);
signal sign_extension_of_immediate_from_8,
	sign_extension_of_immediate_from_5,
	unsigned_extension_of_immediate_from_8,
	unsigned_extension_of_immediate_from_3,
	sign_extension_of_immediate_from_4,
	sign_extension_of_immediate_from_11:std_logic_vector(15 downto 0);
signal rx,ry,rz,s16: std_logic_vector(2 downto 0);
--signal immediate_after_extension: std_logic_vector(15 downto 0);
begin		
  PCWriteTotal<=PCWrite or PCWriteCond;
  serialStatusBits<="00000000000000" &  data_received_from_port_2 &data_send_finished_from_port_2;
 
  sign_extension_of_immediate_from_8<=(s6(7)& s6(7)&s6(7)&s6(7)&s6(7)&s6(7)&s6(7)&s6(7)& s6(7 downto 0));
  sign_extension_of_immediate_from_5<=(s6(4)& s6(4)&s6(4)&s6(4)&s6(4)&s6(4)&s6(4)&s6(4)&s6(4)&s6(4)&s6(4)& s6(4 downto 0));
  unsigned_extension_of_immediate_from_8<="00000000"&s6(7 downto 0);
  unsigned_extension_of_immediate_from_3<="0000000000000"&s6(4 downto 2);
  sign_extension_of_immediate_from_4<=(s6(3)&s6(3)&s6(3)&s6(3)&s6(3)&s6(3)&s6(3)&s6(3)&s6(3)&s6(3)&s6(3)&s6(3)&s6(3 downto 0));
  sign_extension_of_immediate_from_11<=(s6(10)&s6(10)&s6(10)&s6(10)&s6(10)&s6(10 downto 0));
  rx<=s6(10 downto 8);
  ry<=s6(7 downto 5);
  rz<=s6(4 downto 2);
  instructions<=s6;
  data_from_port_2_extension<="00000000" & data_from_port_2;
--  data_from_port_2_out<=data_from_port_2;
  	--for test purpose only
	s1_out<=s1;s2_out<=s2;s8_out<=s8;s10_out<=s10;s11_out<=s11;s12_out<=s12;s13_out<=s13;
	s15_out<=s15;s7_out<=s7;s4_out<=s4;
	s6_out<=s6;s9_out<=s9;s14_out<=s14;s3_out<=s3;
	--for test purpose only
	U_SerialBuffer: serial_buffer port map(clock,rst,MemRead,MemWrite,
   s3,s4,ram1_data,ram1_addr,data_ready,
   tbre,tsre,ram1_oe,ram1_we,ram1_en,wrn,rdn,rxd,txd,seg1,
	data_send_finished_from_port_2,data_received_from_port_2,
	SpecialAddrVisit,data_from_port_2);
  
	
  U_A: dflip_flop_falling port map(clock,rst,s8,s14);
  U_B: dflip_flop_falling port map(clock,rst,s9,s18);
  U_ALU_Result_Register: dflip_flop_falling port map(clock,rst,s12,s13);
  U_DR: dflip_flop_falling port map(clock,rst,ram1_data,s15);

  U_Register_File: register_file port map(clock,rst,RegWrite,RegRead,s16,
  rx,ry,s19,s8,s9);
  U_ALU: alu port map(rst,s10,s11,ALUOp,s12,ALU_zero);
  U_MemtoReg: multiplexor_two_bit generic map(16) port map(s12,s15,unsigned_extension_of_immediate_from_8,MemtoReg,s7);
  U_ALUSrcA: multiplexor_two_bit generic map(16) port map(s2,s14,s18,ALUSrcA,s10);
  U_ALUSrcB: multiplexor_two_bit generic map(16) port map(s18,"0000000000000001",s17,ALUSrcB,s11);

  U_IorD: multiplexor port map(s2,s13,IorD,s3);
  U_SE: multiplexor_three_bit port map(sign_extension_of_immediate_from_8,
  sign_extension_of_immediate_from_5,
  unsigned_extension_of_immediate_from_8,
  unsigned_extension_of_immediate_from_3,
  sign_extension_of_immediate_from_4,
  sign_extension_of_immediate_from_11,SE,s17);
  U_PCSource: multiplexor port map(s12,s13,PCSource,s1);
  U_IR: single_register port map(clock,rst,IRWrite,ram1_data,s6);
  U_PC: single_register port map(clock,rst,PCWriteTotal,s1,s2);
  U_SWSP_Multiplexor: multiplexor port map(s18,s14,SWSP_Control,s4);
  U_RegDst: multiplexor_two_bit generic map(3) port map(rx,rz,ry,RegDst,s16);
  U_ExternalOrInternalChoice: multiplexor_two_bit generic map(16) port map(s7,serialStatusBits,
  	data_from_port_2_extension,
	SpecialAddrVisit,s19);	
end struct;
