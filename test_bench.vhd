-- test bench progetto reti logiche 2018
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity test_bench is
--  Port ( );
end test_bench;

architecture Behavioral of test_bench is


    component project_reti_logiche is
        port ( i_clk : in  std_logic;
               i_start : in  std_logic;
               i_rst : in  std_logic;
               i_data : in  std_logic_vector(7 downto 0);
               o_address : out std_logic_vector(15 downto 0);
               o_done : out std_logic;
               o_en  : out std_logic;
               o_we : out std_logic;
               o_data : out std_logic_vector (7 downto 0));
    end component;
    signal clk, start, rst, done, fsm_to_ram_en, fsm_to_ram_we: std_logic;
    signal ram_to_fsm_data, fsm_to_ram_data: STD_LOGIC_VECTOR(7 downto 0);
    signal fsm_to_ram_address: STD_LOGIC_VECTOR(15 downto 0);
    type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);
    -- caso di test presente nelle specifiche output atteso: 0x11
    signal RAM: ram_type := (0 => "10111001",
    						 1 =>"01001011",
    						 2 => "00100000", 
    						 3 => "01101111",
    						 4 => "11010101",
    						 5 => "01001111",
    						 6 => "00100001",
                           	 7 => "00000001", 
                             8 => "00100001", 
                           	 9 => "01010000", 
                             10 => "00100011", 
                             11 => "00001100", 
                             12 => "11111110", 
                             13 => "11010111", 
                             14 => "01001110",
                             15 => "11010011", 
                             16 => "01111001", 
                             17 => "01001110", 
                             18 => "00100001", 
                             others => (others =>'0'));
begin
    FSM: project_reti_logiche port map(i_clk => clk, i_start=> start, i_rst => rst, i_data=>ram_to_fsm_data, o_done => done, o_address => fsm_to_ram_address, o_en=>fsm_to_ram_en,
                                       o_we=>fsm_to_ram_we, o_data=>fsm_to_ram_data);


    process
    begin
        clk<= '0';
        wait for 50 ns;
        clk<= '1';
        wait for 50 ns;
    end process;

    MEM : process(clk)
       begin
        if clk'event and clk = '1' then
         if fsm_to_ram_en = '1' then
          if fsm_to_ram_we = '1' then
           RAM(conv_integer(fsm_to_ram_address))              <= fsm_to_ram_data;
           ram_to_fsm_data                      <= fsm_to_ram_data;
          else
           ram_to_fsm_data <= RAM(conv_integer(fsm_to_ram_address));
          end if;
         end if;
        end if;
       end process;

    process
    begin
          rst <= '1';
          wait for 10 ns;
          rst <= '0';
          start <= '1';

          wait on done until done = '1';
          -- a questo punto dovrebbe essere stato scritto in memoria il risultato
          start <= '0';
          wait for 200 ns;
          -- a questo punto la fsm dovrebbe essere tornata nello stato iniziale
          assert false report "simulation completed" severity failure; --termina simulazione
      end process;

  end Behavioral;
