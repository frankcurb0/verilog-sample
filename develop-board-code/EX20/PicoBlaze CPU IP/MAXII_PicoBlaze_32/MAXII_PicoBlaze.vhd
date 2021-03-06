--////////////////////////////////////////////////////////////////////////////////
--//  Company: 成都锐创智能科技 Ruichuang Smart Technology                      //
--//           http://ruicstech.taobao.com                                      // 
--//  Engineer:      Youzhiyu                                                   //
--//  QQ      :      4016682                                                    //
--//  Target Device: MAXII240T100C5N                                            //
--//  Tool versions: Quartus II 7.2                                             //
--//  Create Date:   2007-09-06 10:09                                           //
--//  Description:                                                              //
--//                                                                            //
--////////////////////////////////////////////////////////////////////////////////
--// 	   Copyright (C) 2011-2012  Youzhiyu   All rights reserved              //
--//----------------------------------------------------------------------------//
--////////////////////////////////////////////////////////////////////////////////
------------------------------------------------------------------------------------
-- Standard IEEE libraries
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--
------------------------------------------------------------------------------------
--
--
entity MAXII_PicoBlaze is
    Port (
          output  : out std_logic_vector(7 downto 0);
          reset_n : in std_logic;
          clk     : in std_logic
         );
end MAXII_PicoBlaze;
--
------------------------------------------------------------------------------------
--
-- Start of test achitecture
--
architecture Behavioral of MAXII_PicoBlaze is
--
------------------------------------------------------------------------------------
--
--
  component clkdiv
	port( 
	      clkin     : in std_logic;
		  reset_n   : in std_logic;
		  clkout    : out std_logic
		);
  end component;
	
  component picoblaze
    Port ( 
                address : out std_logic_vector(7 downto 0);
            instruction : in std_logic_vector(15 downto 0);
                port_id : out std_logic_vector(7 downto 0);
           write_strobe : out std_logic;
               out_port : out std_logic_vector(7 downto 0);
            read_strobe : out std_logic;
                in_port : in std_logic_vector(7 downto 0);
              interrupt : in std_logic;
                  reset :  in std_logic;
                    clk : in std_logic
          );
 end component;
--
-- declaration of program ROM
--
  component ROM_test
    Port (
       address : in std_logic_vector(7 downto 0);
          dout : out std_logic_vector(15 downto 0);
           clk : in std_logic
         );
 end component;
--
------------------------------------------------------------------------------------
--
-- Signals used to connect picoblaze to program ROM and I/O logic
--
signal address      : std_logic_vector(7 downto 0);
signal instruction  : std_logic_vector(15 downto 0);
signal port_id      : std_logic_vector(7 downto 0);
signal out_port     : std_logic_vector(7 downto 0);
signal in_port      : std_logic_vector(7 downto 0);
signal write_strobe : std_logic;
signal read_strobe  : std_logic;
signal interrupt_event : std_logic;

signal reset : std_logic;
signal divclk: std_logic;
--
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Start of circuit description
--
begin

  reset<=not reset_n;

 clk_div:clkdiv
        PORT MAP(
                  clkin   =>clk,
                  reset_n =>reset_n,
		          clkout  =>divclk
                );
	
  -- Inserting picoblaze and the program memory
  --
  processor: picoblaze
    port map(      address => address,
               instruction => instruction,
                   port_id => port_id,
              write_strobe => write_strobe,
                  out_port => out_port,
               read_strobe => read_strobe,
                   in_port => in_port,
                 interrupt => interrupt_event,
                     reset => reset,
                       clk => divclk);

  program: ROM_test
    port map(address => address,
             dout => instruction,
             clk => divclk);

  -- Unused inputs on processor

  in_port <= "00000000";
  interrupt_event <= '0';

  -- adding the output registers to the processor

  IO_registers: process(divclk)
  begin

    -- waveform register at address 01

    if divclk'event and divclk='1' then
      if port_id(0)='1' and write_strobe='1' then
        output <= out_port;
      end if;
   end if;

  end process IO_registers;

end Behavioral;

------------------------------------------------------------------------------------
--
-- END OF FILE demo.VHD
--
------------------------------------------------------------------------------------

