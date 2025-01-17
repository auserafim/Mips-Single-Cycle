library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;

----- MIPS datapath -----

entity datapath is  
    port (
        clk, reset: in STD_LOGIC;
        memtoreg, pcsrc: in STD_LOGIC;
        alusrc, regdst: in STD_LOGIC;
        regwrite, jump: in STD_LOGIC;
        alucontrol: in STD_LOGIC_VECTOR (2 downto 0);
        zero: out STD_LOGIC;
        pc: buffer STD_LOGIC_VECTOR (31 downto 0);
        instr: in STD_LOGIC_VECTOR(31 downto 0);
        aluout, writedata: buffer STD_LOGIC_VECTOR (31 downto 0);
        readdata: in STD_LOGIC_VECTOR(31 downto 0)
    );
end;

architecture struct of datapath is

    -- Componentes
    component ula
        port(
            a, b: in STD_LOGIC_VECTOR(31 downto 0);
            alucontrol: in STD_LOGIC_VECTOR(2 downto 0);
            result: buffer STD_LOGIC_VECTOR(31 downto 0);
            zero: out STD_LOGIC
        );
    end component;

    component regfile
        port(
            clk: in STD_LOGIC;
            we3: in STD_LOGIC;
            ra1, ra2, wa3: in STD_LOGIC_VECTOR(4 downto 0);
            wd3: in STD_LOGIC_VECTOR(31 downto 0);
            rd1, rd2: out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    component adder
        port(
            a, b: in STD_LOGIC_VECTOR(31 downto 0);
            y: out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    component sl2
        port(
            a: in STD_LOGIC_VECTOR(31 downto 0);
            y: out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    component signext
        port(
            a: in STD_LOGIC_VECTOR(15 downto 0);
            y: out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    component reg 
        generic (width: integer);
        port(
            clk, reset: in STD_LOGIC;
            d: in STD_LOGIC_VECTOR(width - 1 downto 0);
            q: out STD_LOGIC_VECTOR(width - 1 downto 0)
        );
    end component;

    component mux2 
        generic (width: integer);
        port(
            d0, d1: in STD_LOGIC_VECTOR(width-1 downto 0);
            s: in STD_LOGIC;
            y: out STD_LOGIC_VECTOR(width- 1 downto 0)
        );
    end component;

    -- Sinais
    signal writereg: STD_LOGIC_VECTOR(4 downto 0);
    signal pcjump, pcnext, pcnextbr, pcplus4, pcbranch: STD_LOGIC_VECTOR(31 downto 0);
    signal signimm, signimmsh: STD_LOGIC_VECTOR(31 downto 0);
    signal srca, srcb, result: STD_LOGIC_VECTOR(31 downto 0);
	 
	 
begin
    -- Next PC logic
    pcjump <= pcplus4(31 downto 28) & instr(25 downto 0) & "00";

    pcreg: reg generic map(32) port map(
						 clk, 
						 reset, 
						 pcnext, 
						 pc
	 );
	 
    pcadd1: adder port map(
						 pc, 
						 X"00000004",
						 pcplus4
	 );
	 
	 
	 
    immsh: sl2 port map( 
					 signimm, 
					 signimmsh
	 );
	 
	 
    pcadd2: adder port map(
					 pcplus4, 
					 signimmsh,
					 pcbranch
	 );

    pcbrmux: mux2 generic map(32) port map(
					 pcplus4, 
					 pcbranch, 
					 pcsrc, 
					 pcnextbr
	 );
	 
	 
    pcmux: mux2 generic map(32) port map(
					 pcnextbr, 
					 pcjump, 
					 jump, 
					 pcnext
	 );

    -- Register file logic
	 
	 
    rf: regfile port map(
					 clk,
					 regwrite, 
					 instr(25 downto 21), 
					 instr(20 downto 16), 
					 writereg, 
					 result, 
					 srca, 
					 writedata
	 );
	 
    wrmux: mux2 generic map(5) port map(
					 instr(20 downto 16), 
					 instr(15 downto 11), 
					 regdst, 
					 writereg
	 );
	 
	 
    resmux: mux2 generic map(32) port map(
					 aluout, 
					 readdata,
					 memtoreg,
					 result
	 );
	 
    se: signext port map(
					 instr(15 downto 0), 
					 signimm
	 );

    -- ALU logic
	 
    srcbmux: mux2 generic map(32) port map(
					 writedata, 
					 signimm, 
					 alusrc, 
					 srcb
	 );
	 
    mainalu: ula port map(
					 srca, 
					 srcb, 
					 alucontrol, 
					 aluout, 
					 zero
	 );

end;

