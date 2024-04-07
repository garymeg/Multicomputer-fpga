-- This file is copyright by Grant Searle 2014
-- You are free to use this file in your own projects but must never charge for it nor use it without
-- acknowledgement.
-- Please ask permission from Grant Searle before republishing elsewhere.
-- If you use this file or any part of it, please add an acknowledgement to myself and
-- a link back to my main web site http://searle.hostei.com/grant/    
-- and to the "multicomp" page at http://searle.hostei.com/grant/Multicomp/index.html
--
-- Please check on the above web pages to see if there are any updates before using this file.
-- If for some reason the page is no longer available, please search for "Grant Searle"
-- on the internet to see if I have moved to another web hosting service.
--
-- Grant Searle
-- eMail address available on my main web page link above.

library ieee;
use ieee.std_logic_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity Microcomputer is
	port(
		n_reset		: in std_logic;
		clk			: in std_logic;

    --bankSwitch  : output std_logic_vector(2 downto 0);

		sramData		: inout std_logic_vector(7 downto 0);
		sramAddress	: out std_logic_vector(15 downto 0);
		n_sRamWE		: out std_logic;
		n_sRamCS		: out std_logic;
		n_sRamOE		: out std_logic;
		
		n_epromCS		: out std_logic;
		n_epromOE		: out std_logic;
		
		--VIAportA			: inout std_logic_vector(7 downto 0};
		--VIAportB			: inout std_logic_vector(7 downto 0};
		
		rxd1			: in std_logic;
		txd1			: out std_logic;
		rts1			: out std_logic;

		rxd2			: in std_logic;
		txd2			: out std_logic;
		rts2			: out std_logic;
		
		videoSync	: out std_logic;
		video			: out std_logic;

		videoR0		: out std_logic;
		videoG0		: out std_logic;
		videoB0		: out std_logic;
		videoR1		: out std_logic;
		videoG1		: out std_logic;
		videoB1		: out std_logic;
		hSync			: out std_logic;
		vSync			: out std_logic;

		ps2Clk		: inout std_logic;
		ps2Data		: inout std_logic;

		sdCS			: out std_logic;
		sdMOSI		: out std_logic;
		sdMISO		: in std_logic;
		sdSCLK		: out std_logic;
		driveLED		: out std_logic :='1';
    bankRegisterPins : out std_logic_vector(2 downto 0)	
  );
end Microcomputer;

architecture struct of Microcomputer is

	signal n_WR							: std_logic;
	signal n_RD							: std_logic;
	signal cpuAddress					: std_logic_vector(15 downto 0);
	signal cpuDataOut					: std_logic_vector(7 downto 0);
	signal cpuDataIn					: std_logic_vector(7 downto 0);

	signal basRomData					: std_logic_vector(7 downto 0);
	signal internalRam1DataOut		: std_logic_vector(7 downto 0);
	signal internalRam2DataOut		: std_logic_vector(7 downto 0);
	signal interface1DataOut		: std_logic_vector(7 downto 0);
	signal interface2DataOut		: std_logic_vector(7 downto 0);
	signal sdCardDataOut				: std_logic_vector(7 downto 0);

	signal n_memWR						: std_logic :='1';
	signal n_memRD 					: std_logic :='1';

	signal n_ioWR						: std_logic :='1';
	signal n_ioRD 						: std_logic :='1';
	
	signal n_MREQ						: std_logic :='1';
	signal n_IORQ						: std_logic :='1';	

	signal n_int1						: std_logic :='1';	
	signal n_int2						: std_logic :='1';	
	
	signal n_externalRamCS			: std_logic :='1';
	signal n_externalepromCS		: std_logic :='1';
	signal n_internalRam1CS			: std_logic :='1';
	signal n_internalRam2CS			: std_logic :='1';
	signal n_basRomCS					: std_logic :='1';
	signal n_interface1CS			: std_logic :='1';
	signal n_interface2CS			: std_logic :='1';
	signal n_sdCardCS					: std_logic :='1';

	signal serialClkCount			: std_logic_vector(15 downto 0);
	signal cpuClkCount				: std_logic_vector(5 downto 0); 
	signal sdClkCount					: std_logic_vector(5 downto 0); 	
	signal cpuClock					: std_logic;
	signal serialClock				: std_logic;
	signal sdClock						: std_logic;	

  signal BankSwitch         : std_logic_vector(2 downto 0) := (others => '1');
	
begin
  bankRegisterPins <= BankSwitch; -- Assign bank_register to output pins


-- ____________________________________________________________________________________
-- CPU CHOICE GOES HERE
cpu1 : entity work.T65
port map(
Enable => '1',
Mode => "00",
Res_n => n_reset,
Clk => cpuClock,
Rdy => '1',
Abort_n => '1',
IRQ_n => '1',
NMI_n => '1',
SO_n => '1',
R_W_n => n_WR,
A(15 downto 0) => cpuAddress,
DI => cpuDataIn,
DO => cpuDataOut
);
-- ____________________________________________________________________________________
-- ROM GOES HERE	
	rom1 : entity work.M6502_BASIC_ROM -- 8KB BASIC
  port map(
  address => cpuAddress(12 downto 0),
  clock => clk,
  q => basRomData
);
-- ____________________________________________________________________________________
-- RAM GOES HERE
-- 2K Ram
-- ram1: entity work.InternalRam2K
-- port map
-- (
-- address => cpuAddress(10 downto 0),
-- clock => clk,
-- data => cpuDataOut,
-- wren => not(n_memWR or n_internalRam1CS),
-- q => internalRam1DataOut
-- );

-- 4K Ram
-- ram1: entity work.InternalRam4K
-- port map
-- (
-- address => cpuAddress(11 downto 0),
-- clock => clk,
-- data => cpuDataOut,
-- wren => not(n_memWR or n_internalRam1CS),
-- q => internalRam1DataOut
-- );

-- Zero page and stack fixed ram
-- uses 256 bytes of internal memory for 0-page
-- 
ram1: entity work.InternalRam256bytes
  port map
  (
  address => cpuAddress(7 downto 0),
  clock => clk,
  data => cpuDataOut,
  wren => not(n_memWR or n_internalRam1CS),
  q => internalRam1DataOut
  );
-- Address decoding logic
process(clk) 
begin
    if rising_edge(clk) then
        -- Handle bank register at address 0x0000
        if cpuAddress = x"FF" then
            if n_WR = '0' then  -- Check for write enable signal
                -- Write operation to bank register
                bankSwitch <= cpuDataOut(2 downto 0);  -- Only update bank_register on a write operation

            end if;
        END IF;
    end if;
end process;

-- Enable External Ram
sramAddress(14 downto 0) <= cpuAddress(14 downto 0);
sramData <= cpuDataOut when n_WR='0' else (others => 'Z');
n_sRamWE <= n_memWR;
n_sRamOE <= n_memRD;
n_sRamCS <= n_externalRamCS;

--INPUT/OUTPUT DEVICES GO HERE	
io1 : entity work.bufferedUART
port map(
clk => clk,
n_wr => n_interface1CS or cpuClock or n_WR,
n_rd => n_interface1CS or cpuClock or (not n_WR),
n_int => n_int1,
regSel => cpuAddress(0),
dataIn => cpuDataOut,
dataOut => interface1DataOut,
rxClock => serialClock,
txClock => serialClock,
rxd => rxd1,
txd => txd1,
n_cts => '0',
n_dcd => '0',
n_rts => rts1
);

-- io1 : entity work.SBCTextDisplayRGB
-- generic map(
-- HORIZ_CHARS => 40,
-- CLOCKS_PER_PIXEL => 6,
-- CLOCKS_PER_SCANLINE => 3200,
-- DISPLAY_TOP_SCANLINE => 65,
-- VERT_SCANLINES => 312,
-- VERT_PIXEL_SCANLINES => 1,
-- VSYNC_SCANLINES => 4,
-- HSYNC_CLOCKS => 235,
-- DISPLAY_LEFT_CLOCK => 850
-- )

-- port map (
-- n_reset => n_reset,
-- clk => clk,

-- -- RGB video signals
-- hSync => hSync,
-- vSync => vSync,
-- videoR0 => videoR0,
-- videoR1 => videoR1,
-- videoG0 => videoG0,
-- videoG1 => videoG1,
-- videoB0 => videoB0,
-- videoB1 => videoB1,

-- -- Monochrome video signals (when using TV timings only)
-- sync => videoSync,
-- video => video,

-- n_wr => n_interface1CS or cpuClock or n_WR,
-- n_rd => n_interface1CS or cpuClock or (not n_WR),
-- n_int => n_int1,
-- regSel => cpuAddress(0),
-- dataIn => cpuDataOut,
-- dataOut => interface1DataOut,
-- ps2Clk => ps2Clk,
-- ps2Data => ps2Data
-- );

sd1 : entity work.sd_controller
port map(
sdCS => sdCS,
sdMOSI => sdMOSI,
sdMISO => sdMISO,
sdSCLK => sdSCLK,
n_wr => n_sdCardCS or cpuClock or n_WR,
n_rd => n_sdCardCS or cpuClock or (not n_WR),
n_reset => n_reset,
dataIn => cpuDataOut,
dataOut => sdCardDataOut,
regAddr => cpuAddress(2 downto 0),
driveLED => driveLED,
clk => sdClock -- twice the spi clk
);
-- ____________________________________________________________________________________
-- MEMORY READ/WRITE LOGIC GOES HERE
n_memRD <= not(cpuClock) nand n_WR;
n_memWR <= not(cpuClock) nand (not n_WR);
-- ____________________________________________________________________________________
-- CHIP SELECTS GO HERE
  n_basRomCS <= '0' when cpuAddress(15 downto 13) = "111" else '1'; --8K at top of memory
  n_interface1CS <= '0' when cpuAddress(15 downto 1) = "111111111101000" else '1'; -- 2 bytes FFD0-FFD1
  n_interface2CS <= '0' when cpuAddress(15 downto 1) = "111111111101001" else '1'; -- 2 bytes FFD2-FFD3
  n_sdCardCS <= '0' when cpuAddress(15 downto 3) = "1111111111011" else '1'; -- 8 bytes FFD8-FFDF

--Ram Selection

  n_internalRam1CS <= '0' when cpuAddress(15 downto 8 ) = "00000000" else '1'; -- 256b Internal Ram
--n_internalRam1CS <= '0' when cpuAddress(15 downto 11) = "00000" else '1'; -- 2K Internal Ram
--n_internalRam1CS <= '0' when cpuAddress(15 downto 12) = "0000" else '1'; -- 4K Internal Ram
--n_externalRamCS <= '0' when cpuAddress(15) = '0' else '1'; -- 32K External SRAM
	n_externalRamCS<= not n_basRomCS;
  --n_externalepromCS<= n_basRomCS;
	
-- ____________________________________________________________________________________
-- BUS ISOLATION GOES HERE

cpuDataIn <=
interface1DataOut when n_interface1CS = '0' else
interface2DataOut when n_interface2CS = '0' else
sdCardDataOut when n_sdCardCS = '0' else
basRomData when n_basRomCS = '0' else
internalRam1DataOut when n_internalRam1CS= '0' else
sramData when n_externalRamCS= '0' else
x"FF";

-- ____________________________________________________________________________________
-- SYSTEM CLOCKS GO HERE

-- SUB-CIRCUIT CLOCK SIGNALS
serialClock <= serialClkCount(15);
process (clk)
begin

if rising_edge(clk) then

if cpuClkCount < 4 then -- 4 = 10MHz, 3 = 12.5MHz, 2=16.6MHz, 1=25MHz
cpuClkCount <= cpuClkCount + 1;
else
cpuClkCount <= (others=>'0');
end if;
if cpuClkCount < 2 then -- 2 when 10MHz, 2 when 12.5MHz, 2 when 16.6MHz, 1 when 25MHz
cpuClock <= '0';
else
cpuClock <= '1';
end if;

if sdClkCount < 49 then -- 1MHz
sdClkCount <= sdClkCount + 1;
else
sdClkCount <= (others=>'0');
end if;
if sdClkCount < 25 then
sdClock <= '0';
else
sdClock <= '1';
end if;

-- Serial clock DDS
-- 50MHz master input clock:
-- Baud Increment
-- 115200 2416
-- 38400 805
-- 19200 403
-- 9600 201
-- 4800 101
-- 2400 50
serialClkCount <= serialClkCount + 2416;
end if;
end process;
-- ____________________________________________________________________________________
-- END of file
end;
