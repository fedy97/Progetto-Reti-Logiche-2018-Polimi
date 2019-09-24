library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;


entity project_reti_logiche is
port (
i_clk : in std_logic;
i_start : in std_logic;
i_rst : in std_logic;
i_data : in std_logic_vector(7 downto 0);
o_address : out std_logic_vector(15 downto 0);
o_done : out std_logic;
o_en : out std_logic;
o_we : out std_logic;
o_data : out std_logic_vector (7 downto 0)
) ;
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is 
    type STATUS is (modifica_uscita,confronta_minimo,calcola_dist_manhattan,calcola_dist_parziali,RST,req_vector_corr,risp_vector,wait_risp_vector,check,wait_final,conclusion,endd);
    
    signal S_CORR: STATUS;
    signal ADDRESS: std_logic_vector(15 downto 0);
    signal distx_corr,disty_corr,maschera,x_corr,y_corr,punto_x,punto_y: std_logic_vector(7 downto 0);
    signal min: std_logic_vector(8 downto 0);
    signal cont_c: std_logic_vector(3 downto 0);
    signal uscita: std_logic_vector(7 downto 0);
    signal disttot_corr: std_logic_vector(8 downto 0);
    signal req_vector: std_logic_vector(1 downto 0);
    signal bool_c_y: std_logic;

begin   
     
    operativo: process (i_clk)        
    begin        
    if (rising_edge(i_clk)) then
        if (i_rst = '1') then
            S_CORR <= RST;
        elsif (i_rst = '0') then                
        case S_CORR is
          when RST => 
                    bool_c_y <= '0';  --lettura punto x del centroide corrente
                    req_vector <= "00";  --lettura centroide iniziale
                    o_done <= '0';
                    ADDRESS <= "0000000000000000";  --indirizzo 0 della ram, 16 bit  
                    uscita <= "00000000"; --valore di appoggio per l'output
                    maschera <= "00000000"; --maschera dei centroidi da considerare
                    x_corr <= "00000000"; --x del centroide corrente
                    y_corr <= "00000000"; --y del centroide corrente
                    punto_x <= "00000000"; --x del punto da cui calcolare la distanza
                    punto_y <= "00000000"; --y del punto da cui calcolare la distanza
                    disttot_corr <= "000000000"; --distanza totale corrente, dal centroide corrente al punto
                    distx_corr <= "00000000"; --distanza x corrente dal centroide corr al punto
                    disty_corr <= "00000000"; --distanza y corrente dal centroide corr al punto
                    min <= "111111111"; --valore iniziale minimo della distanza dal punto
                    cont_c <= "0000"; --contatore modulo 8 dei centroidi, quando arriva a 7 termina la lettura
                    if (i_start = '1') then     
                        o_en <= '1'; --manda 1 alla ram x comunicare             
                        o_we <= '0';       
                        S_CORR <= req_vector_corr;                                        
                    end if;
          when req_vector_corr => --si inizia a leggere la ram partendo dalla maschera in ADDRESS 0             
                o_address <= ADDRESS;
                S_CORR <= wait_risp_vector;
          when wait_risp_vector =>
                S_CORR <= risp_vector;                                                          
          when risp_vector =>                      
                if (req_vector = "00") then --00 significa leggere maschera
                    maschera <= i_data; --assegna la maschera memorizzata nella RAM al signal maschera
                    ADDRESS <= ADDRESS + 17; --vai all indirizzo della coordinata x del punto, ADDRESS 17
                    req_vector <= "01";
                    S_CORR <= req_vector_corr;
                elsif (req_vector = "01") then --01 significa leggere x punto
                    punto_x <= i_data;
                    ADDRESS <= ADDRESS + 1; --indirizzo della coordinata y del punto, ADDRESS 18
                    req_vector <= "10";
                    S_CORR <= req_vector_corr;
                elsif (req_vector = "10") then --10 significa leggere x punto
                    punto_y <= i_data;
                    ADDRESS <= ADDRESS - 17; --imposta l'indirizzo della cella contenente la coordinata x del primo centroide
                    req_vector <= "11";
                    S_CORR <= check;
                elsif (req_vector = "11") then --11 significa leggere centroide corrente
                    if (bool_c_y = '0') then --se legge la x
                        x_corr <= i_data;
                        ADDRESS <= ADDRESS + 1;
                        bool_c_y <= '1'; --poi leggera la y
                        S_CORR <= req_vector_corr; --rifai per leggere la y,entra nel ramo else adesso
                    else
                        y_corr <= i_data;
                        ADDRESS <= ADDRESS + 1;
                        bool_c_y <= '0'; --poi leggera la x
                        S_CORR <= calcola_dist_parziali; --ha letto tutto il centroide,calcola minimo ora
                    end if;
                end if;                           
          when check =>  
            if (conv_integer(cont_c) /= 8) then  --controlla se devo ancora leggere qualche centroide
                if (maschera(conv_integer(cont_c)) = '0') then --controlla se il centroide non va considerato
                    ADDRESS <= ADDRESS + 2; --vai al prossimo centroide e rifai il check
                    S_CORR <= check;
                else --vado a leggere le coordinate del centroide
                    S_CORR <= req_vector_corr;
                end if;
                cont_c <= cont_c + 1;
            else --se tutti i centroidi sono stati esaminati vado a scrivere il risultato nella RAM
                S_CORR <= wait_final;
            end if;
          when calcola_dist_parziali => 
                if (punto_x > x_corr) then --per non avere differenza negativa,differenza tra centroide corrente_x e punto_x
                    distx_corr <= punto_x - x_corr;
                else
                    distx_corr <= x_corr - punto_x;
                end if;
                if (punto_y > y_corr) then --stessa cosa ma con la y
                    disty_corr <= punto_y - y_corr;
                else
                    disty_corr <= y_corr - punto_y;				      
                end if;
                S_CORR <= calcola_dist_manhattan;
          when calcola_dist_manhattan =>	  	
                disttot_corr <= (('0'&disty_corr) + ('0'&distx_corr)); --somma distanza
                S_CORR <= confronta_minimo;
          when confronta_minimo =>	  	
                if (disttot_corr <= min) then --confronta col minimo che all inizio vale 111111111
                    if(disttot_corr < min) then
                         uscita <= "00000000";
                         min <= disttot_corr; --nuovo valore minimo e scrittura '1' sull output
                    end if;
                    S_CORR <= modifica_uscita;
                else S_CORR <= check;
                end if;          	  	
                 --controlla se devo continuare la lettura dei centroidi
          when modifica_uscita =>
                uscita(conv_integer(cont_c-1)) <= '1';
                S_CORR <= check;
          when wait_final => --siam pronti a scrivere il valore in ram
                o_we <= '1'; 
                o_address <= "0000000000010011"; --address di scrittura risultato,19
                o_data <= uscita;
                S_CORR <= conclusion;
          when conclusion =>
                o_we <= '0';
                o_done <= '1';
                o_en <= '0';
                S_CORR <= endd; 
          when endd =>
          if (i_start = '0') then
                o_done <= '0';
                S_CORR <= RST;
          end if;
       end case; 
       end if;
       end if;              
    end process ;
    
end Behavioral;