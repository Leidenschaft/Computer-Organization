----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:53:33 04/13/2012 
-- Design Name: 	Gao XueCheng
-- Module Name:    Controler_seven - Behavioral 
-- Project Name: Controler_seven
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Controler_seven is
    Port ( rst : in  STD_LOGIC;
           clk : in  STD_LOGIC;--one step clock
           instructions : in  STD_LOGIC_VECTOR (15 downto 0);
			  PCWrite,PCWriteCond,PCSource: out std_logic ;
			  ALUOp : out std_logic_vector(3 downto 0) ;
			  ALUSrcA : out std_logic_vector(1 downto 0) ;
			  ALUSrcB : out std_logic_vector(1 downto 0) ;
			  MemRead : out std_logic ;
			  MemWrite : out std_logic ;
			  IRWrite : out std_logic ;
			  MemtoReg :out  std_logic_vector(1 downto 0) ;
			  RegWrite : out std_logic_vector(2 downto 0) ;
			  RegDst : out std_logic_vector(1 downto 0) ;
			  IorD : out std_logic;
			  SE: out std_logic_vector(2 downto 0);
			  bZero_ctrl: in std_logic;
			  state_code: out std_logic_vector(3 downto 0);
			  RegRead: out std_logic_vector(1 downto 0);
			  SWSP_Control: out std_logic;
			  CPUDisable: in std_logic			  
		--	  timerEnable: in std_logic;
		--	  IsOverFlow: out std_logic
);
end Controler_seven;

architecture Behavioral of Controler_seven is

type controler_state is (instruction_fetch,decode,execute,
mem_control,write_reg,interrupt,empty,empty_branch);
signal state : controler_state;
signal CPUDisable_inner: std_logic;
begin
 process(clk,rst)
  begin
	 if(rst='0') then
	 CPUDisable_inner<='0';
	 elsif(rising_edge(CPUDisable)) then
	 CPUDisable_inner<=not CPUDisable_inner;
	 end if;
	end process;

	

	
	process(rst,clk)
	begin
		if(rst = '0') then
			state <= instruction_fetch;
			state_code <= "0000"; --IF
			IorD <= '0' ;
			IRWrite <= '0' ;
			MemRead <= '0' ;
			MemWrite <= '0' ;
			MemtoReg <= "00" ;
			ALUOp <= "0000" ;
			ALUSrcA <= "00" ;
			ALUSrcB <= "00" ;
			SWSP_Control<='0';
			PCWrite <= '0' ;
			SE<="000";  
			RegDst <= "00" ;
			RegWrite <= "000" ;
			RegRead<="00";
			SWSP_Control<='0';
		elsif falling_edge(clk) then
			case state is
				when instruction_fetch =>
					if(CPUDisable_inner='1') then
							state <= instruction_fetch;
							ALUSrcA<="10";
							ALUSrcB<="00";
							ALUOp<="0001";
							IorD<='1';
					else
						SWSP_Control <='0';
						ALUSrcA <= "00" ;
						IorD <= '0' ;
						ALUOp <= "0000";
						RegWrite <= "000" ;
						MemtoReg <= "00";
						MemRead <= '1' ;
						ALUSrcB <= "01" ;
						PCWrite <= '1' ;
						RegRead<="00";					
						IRWrite <= '1' ;
						state <= decode ;
						state_code <= "0001" ; --DE					
					end if;
				when decode =>
					MemRead <= '0';
					PCWrite <= '0';
					ALUSrcA <= "00";
					ALUSrcB <= "10";
					SE <="000";
					ALUOp<="0000";
					state <= execute ;
					state_code <= "0010"; --EXE
				when execute =>    						
					IRWrite <= '0';
					case instructions(15 downto 11) is 
						when "00001" =>                         -------------Temporarily NOP
							case instructions(10 downto 0) is 
								when "00000000000" =>   -------------NOP ok
									state<=instruction_fetch;
									state_code<="0000"; --IF
								when others=>
									null;
							end case;
                  when "00010" =>             -------------B  ok
                     ALUSrcA <= "00";
							ALUSrcB <= "10";
							ALUOp <= "0000" ;
                     SE<="101";
							PCWrite <= '1';
							state <= instruction_fetch ;
							state_code <= "0000" ; --IF
						when "00100" =>				-------------BEQZ  ok
							ALUSrcA <= "01";        
							ALUOp <= "1010";
							state <= instruction_fetch ;
							state_code <= "0000" ; --IF
                  when "00101" =>				-------------BNEZ  ok
                     ALUSrcA <= "01";
							ALUOp <= "1010";
							state <= instruction_fetch ;
							state_code <= "0000" ; --IF   
                  when "01101" =>							-------------LI ok
							SE<="010";
							MemtoReg<="10";
							RegDst <= "00";
							RegWrite <= "001";
                     state <= instruction_fetch;
							state_code <= "0000"; --WB  
                  when "10010" =>             -------------LW_SP  ok
                     RegRead<="10";
							ALUSrcA <= "01";
                     ALUSrcB <= "10" ;
                     ALUOp <= "0000" ;  
							SE <="000";  
							state <= empty ;
							state_code <= "1110" ; --empty
						when "10011" =>				-------------LW	ok
							ALUSrcA <= "01" ;
							ALUSrcB <= "10" ;
							ALUOp <= "0000" ;  
							SE<="001";
							state <= mem_control ;
							state_code <= "0011" ; --MEM
						when "11011" =>				-------------SW	ok
							ALUSrcA <= "01";
							ALUSrcB <= "10" ;
							SE<="001";							
							ALUOp <= "0000" ;   
							state <= mem_control ;
							state_code <= "0011"; --MEM
						when "11100" =>					
									RegDst <= "01";
									RegWrite <= "001" ;	
									MemToReg<="00";
									state_code <= "0000";
									state<=instruction_fetch;
							case instructions(1 downto 0) is
								when "01" =>			-------------ADDU   ok
									ALUSrcA <= "01";
									ALUSrcB <= "00";
									ALUOp <= "0000" ;
								when "11" =>			-------------SUBU   ok
									ALUSrcA <= "01";
									ALUSrcB <= "00";
									ALUOp <= "0001" ;
								when others =>
									null ;
							end case ;
						when "01001" =>				------------ADDIU   ok
							ALUSrcA <= "01";
							ALUSrcB <= "10";
							ALUOp <= "0000";
							RegDst <= "00";
							RegWrite <= "001"; 
							MemtoReg <= "00" ;
							state <= instruction_fetch;
							state_code <= "0000";
                  when "01000" =>				------------ADDIU3   ok
                     ALUSrcA <= "01";
							ALUSrcB <= "10";
							ALUOp <= "0000";
							SE <= "100";
							RegWrite<="001";
							RegDst<="10";
							MemtoReg<="00";
							state <= write_reg;
							state_code <= "0100"; --WB
                  when "00000" =>				------------ADDSP3   ok
							RegRead <="10";
                     ALUSrcA <= "01";
							ALUSrcB <= "10";
							ALUOp <= "0000";
							state <= write_reg;
							state_code <= "0100"; --WB
                  when "01100" =>				
                     case instructions(10 downto 8) is
                        when "011" =>		------------ADDSP      ok
									RegRead <= "10";
                           ALUSrcA <= "01";
									ALUSrcB <= "10";
									ALUOp <= "0000";
									RegWrite<="010";
									MemtoReg<="00";
									state <= write_reg;
									state_code <= "0100";
								when "000" =>       ------------BTEQZ  ok
									RegRead<="01";
									state <= empty_branch ;
									state_code <= "1101" ;
                         when "100" =>		------------MTSP     ok
                           ALUSrcA <= "00";
									ALUSrcB <= "00";
									ALUOp <= "1011";
									RegWrite <= "010"; 
									MemtoReg <= "00" ;
									state <= instruction_fetch;
                           state_code <= "0000";
                         when others =>
                           null;
							 end case;
						 when "11101" =>
								 state<=instruction_fetch;
								 state_code<="0000";
							 case instructions(4 downto 0) is 
								when "01101" =>		------------OR    ok
									RegDst <= "00";
								   RegWrite <= "001";
								   MemtoReg <= "00" ;
									ALUSrcA <= "01";
									ALUSrcB <= "00";
									ALUOp <= "0011";
								when "01110" =>		------------XOR   ok
									RegDst <= "00";
								   RegWrite <= "001";
								   MemtoReg <= "00" ;
									ALUSrcA <= "01";
									ALUSrcB <= "00";
									ALUOp <= "0100";
								when "01100" =>		------------AND   ok
									RegDst <= "00";
								   RegWrite <= "001";
								   MemtoReg <= "00" ;
									ALUSrcA <= "01";
									ALUSrcB <= "00";
									ALUOp <= "0010";
								when "01010" =>		------------CMP    ok
                           ALUSrcA <= "01";
									ALUSrcB <= "00";
									RegWrite <= "011";
									MemtoReg <= "00" ; 
									ALUOp <= "1101";  --0 equ, 1 ine
								when "00100" =>			-------------SLLV    ok
                           RegDst <= "10";
								   RegWrite <= "001";
								   MemtoReg <= "00" ;
									ALUSrcA <= "01";
									ALUSrcB <= "00";
									ALUOp <= "1100";
								when "00011" =>			-------------SLTU  ok
                           ALUSrcA <= "01";
									ALUSrcB <= "00";
									ALUOp <= "1110";   --0 larger/equal, 1 smaller
									RegWrite <= "011";
									MemtoReg <= "00" ;
									state <= instruction_fetch ;
									state_code <= "0000" ; --WB
								when "00000" =>
									case instructions(7 downto 5) is
										when "000" =>	------------JR   ok
											ALUSrcA<="01";
											ALUOp<="1010";
											PCWrite <= '1';
                             when "010" =>  ------------MFPC  ok
											ALUSrcA <= "00";
											ALUOp <= "1010"; 
											RegDst<="00";
											RegWrite<="001";
											MemtoReg<="00";
										when others =>
										null ;
									end case;
								when others =>
									null ;
								end case ;
                  when "01110" =>        --------------CMPI   ok
                     ALUSrcA <= "01";
							ALUSrcB <= "10";
							ALUOp <= "1101"; --cmp
							RegWrite <= "011";
							MemtoReg <= "00" ; 
							state <= instruction_fetch ;
							state_code <= "0000" ; 
						when "11111" => 				-------------INT
							state <= interrupt;
						--	ALUSrcA<="10";
						--	ALUSrcB<="00";
						--	ALUOp<="0001";
							IorD<='1';
							state_code <= "1111";
						when "11110"=>
                           case instructions(1 downto 0) is
                            when "00" =>		-----------MFIH       ok
                            		ALUSrcA <= "01";
											ALUSrcB <= "01";
											RegRead<="11";
											ALUOp <= "1010"; --A
											RegDst <= "00";
											RegWrite <= "001";
											MemtoReg <= "00" ;
											state <= write_reg ;
											state_code <= "0100" ; 
                            when "01" =>		-----------MTIH        ok
                                 ALUSrcA <= "01";
											ALUSrcB <= "01";
											ALUOp <= "1010"; --A
											RegWrite <= "101";
											MemtoReg <= "00" ; 
											state <= instruction_fetch ;
											state_code <= "0000" ;
                            when others =>
                                 null;
                           end case;
                   when "01111" => 			------------MOVE    ok
                     ALUSrcA <= "00";
							ALUSrcB <= "00";
							ALUOp <= "1011";
							RegDst<="00";
							RegWrite<="001";
							MemtoReg<="00";
							state <= instruction_fetch ;
							state_code <= "0000" ; 
                   when "00110" =>
                           RegDst <= "00";
									RegWrite <= "001";
									MemtoReg <= "00" ; 
									state <= instruction_fetch;
									state_code <= "0000" ;
                           ALUSrcA <= "10";  
									ALUSrcB <= "10";
									SE <= "011";  
                    if(instructions(1 downto 0)="00") then
                   			ALUOp <= "0110";------------SLL  ok
						  else	------------SRA    ok
									ALUOp <= "1000";
						  end if;
						when "11010" =>		------------SW_SP   ok
							RegRead<="10";
							ALUSrcA <= "01";
							ALUSrcB <= "10";
							ALUOp <= "0000";
							state <= empty ;
							SWSP_Control <='1';
							state_code <= "1110"; --empty
						when others =>
							state <= instruction_fetch ;
							state_code <= "0000"; --IF
					end case ;
				when mem_control =>         
					PCWrite <= '0' ;
					RegWrite <= "000" ;
					case instructions(15 downto 11) is 
                     when "10010" =>				-------------LW_SP
                     MemRead <= '1' ;
							IorD <= '1' ;
							state <= write_reg ;
							state_code <= "0100"; --WB
						when "10011" =>				-------------LW	
							MemRead <= '1' ;
							IorD <= '1' ;
							state <= write_reg ;
							state_code <= "0100"; --WB
						when "11011" =>				-------------SW	
							MemWrite <= '1' ;
							IorD <= '1' ;
							state <= write_reg ;
							state_code <= "0100"; --WB
                   when "11010"=>				-------------SW_SP
                     MemWrite <= '1' ;
							IorD <= '1' ;
							state <= write_reg ;
							state_code <= "0100"; --WB                               
						when others =>
							null ;
					end case;
				when write_reg =>                
					MemWrite <= '0' ;
					MemRead <= '0' ;
					case instructions(15 downto 11) is 
						when "10010" =>				-------------LW_SP
                     RegDst <= "00";
							RegWrite <= "001";
							MemtoReg <= "01" ;	
						when "10011" =>				-------------LW	
							RegDst <= "10";
							MemRead<='0';
							RegWrite <= "001";
							MemtoReg <= "01" ;
						when "11011" =>				-------------SW	
							MemWrite <= '0' ;
							IorD <= '0' ;
						when "01000" =>				---------------ADDIU3
                                				RegDst <= "10";
								RegWrite <= "001"; 
								MemtoReg <= "00" ;
						when "00000" =>				---------------ADDSP3
                        RegDst <= "00";
								RegWrite <= "001"; 
								MemtoReg <= "00" ;
						when "01100" =>
                        case instructions(10 downto 8) is
                          when "011" =>		------------ADDSP
										RegWrite <= "010"; 
										MemtoReg <= "00" ;
									when "100" =>		------------MTSP
										RegWrite <= "010"; 
										MemtoReg <= "00" ;
                          when others =>
                             null;
								end case;
						when "11110" =>
                            				case instructions(1 downto 0) is
                            					when "00" =>		-----------MFIH
                            						RegDst <= "00";
									RegWrite <= "001";
									MemtoReg <= "00" ; 
                                				when "01" =>		-----------MTIH
                                    					RegWrite <= "101";
									MemtoReg <= "00" ; 
                                				when others =>
                                    					null;
                             				end case;
						when "11101" =>
							case instructions(4 downto 0) is
								when "01010" =>		------------CMP
									RegWrite <= "011";
									MemtoReg <= "00" ; 
								when "00000" =>		------------MFPC
                           RegDst <= "00";
									RegWrite <= "001";
									MemtoReg <= "00" ;
                        when "00011" =>			-------------SLTU
									RegWrite <= "011";
									MemtoReg <= "00" ;
								when others =>
									null ;
							end case ;
                    when "01110" =>        --------------CMPI
							RegWrite <= "011";
							MemtoReg <= "00" ;
                  when "11010" =>				------------SW_SP
                     MemWrite <= '0' ; 
							IorD <= '0' ;
						when others =>
							null ;
					end case ;
					state <= instruction_fetch ;
					state_code <="0000"; --IF
				when interrupt =>
					state<=interrupt;
					ALUSrcA<="10";
					ALUSrcB<="00";
					ALUOp<="0001";
				when empty =>		   --LW_SP,SW_SP
					ALUSrcA<="01";
					RegRead<="00";
					state<=mem_control;
					state_code<="0011";
				when empty_branch => --BTEQZ
					ALUSrcA <= "01";
					ALUOp <= "1010";
					state<=instruction_fetch;
					state_code<="0000";
			end case;
		end if ;
	end process;

	process(rst,clk,bZero_Ctrl)
	begin
		if(rst='0') then
			PCSource <= '0';
			PCWriteCond<='0';
		elsif(rising_edge(clk)) then
		 case state is
		 when instruction_fetch =>
		 case instructions(15 downto 11) is --last instruction
			when "00100" =>				-------------BEQZ
				PCSource<='1' and bZero_Ctrl;
				PCWriteCond<=bZero_Ctrl;
			when "00101" =>            -------------BNEZ
				PCSource<='1' and not(bZero_Ctrl);
				PCWriteCond<=not(bZero_Ctrl);
			when "00010" =>            -------------B
				PCSource<='0';
			when "01100" =>
				if (instructions(10 downto 8) = "000") then ----BTEQZ
					PCSource<='1' and bZero_Ctrl;
					PCWriteCond<=bZero_Ctrl;
				end if;
			when others =>
				null;
		 end case;
		 when others =>
				PCWriteCond<='0';
				PCSource<='0';
		 end case;
		end if;
	end process;



end Behavioral;

