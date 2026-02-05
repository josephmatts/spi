LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY spi_master IS
  GENERIC (DATA_LENGTH : INTEGER := 24);
  PORT (
    clk     : IN  STD_LOGIC;
    reset_n : IN  STD_LOGIC;
    enable  : IN  STD_LOGIC;
    cpol    : IN  STD_LOGIC;   -- idle clock polarity
    cpha    : IN  STD_LOGIC;   -- clock phase
    sclk    : OUT STD_LOGIC;
    ss_n    : OUT STD_LOGIC;
    mosi    : OUT STD_LOGIC;
    busy    : OUT STD_LOGIC;
    tx      : IN  STD_LOGIC_VECTOR(DATA_LENGTH-1 DOWNTO 0)
  );
END spi_master;

ARCHITECTURE rtl OF spi_master IS
  TYPE state_t IS (idle, assert_cs, transfer, finish);
  SIGNAL state      : state_t := idle;
  SIGNAL shreg      : STD_LOGIC_VECTOR(DATA_LENGTH-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL bit_cnt    : INTEGER RANGE 0 TO DATA_LENGTH := 0;
  SIGNAL sclk_int   : STD_LOGIC := '0';
  SIGNAL sclk_prev  : STD_LOGIC := '0';
  SIGNAL half_phase : STD_LOGIC := '0';  -- toggles every clk to divide by 2
BEGIN
  sclk <= sclk_int;

  PROCESS(clk)
  BEGIN
    IF reset_n='0' THEN
      state      <= idle;
      ss_n       <= '1';
      sclk_int   <= cpol;
      sclk_prev  <= cpol;
      mosi       <= '0';
      busy       <= '0';
      half_phase <= '0';
      bit_cnt    <= 0;

    ELSIF rising_edge(clk) THEN
      sclk_prev <= sclk_int;

      CASE state IS
        WHEN idle =>
          busy     <= '0';
          sclk_int <= cpol;
          mosi     <= '0';
          IF enable='1' THEN
            shreg <= std_logic_vector(shift_left(unsigned(tx), 1));
            bit_cnt  <= DATA_LENGTH-1;
            ss_n     <= '0';     -- assert CS
            busy     <= '1';
            state    <= assert_cs;
          END IF;

        WHEN assert_cs =>
          -- wait one extra cycle before clock starts
          half_phase <= '0';
          sclk_int   <= cpol;
          -- preload MOSI if CPHA=0
          IF cpha='0' THEN
            mosi <= shreg(bit_cnt);
          END IF;
          state <= transfer;

        WHEN transfer =>
          -- generate half-rate SCLK
          half_phase <= NOT half_phase;
          IF half_phase='1' THEN
            sclk_int <= NOT sclk_int;
          END IF;

          -- detect rising/falling edges
          IF (sclk_prev='0' AND sclk_int='1') OR (sclk_prev='1' AND sclk_int='0') THEN
            -- active edge depends on CPOL/CPHA
            IF ( (sclk_int='1' AND cpol='0') OR (sclk_int='0' AND cpol='1') ) XOR (cpha='1') THEN
              -- shift on active edge
              IF cpha='1' THEN
                mosi <= shreg(bit_cnt);
              END IF;

              IF bit_cnt=0 THEN
                state <= finish;
              ELSE
                bit_cnt <= bit_cnt-1;
              END IF;
            END IF;
          END IF;

        WHEN finish =>
          -- hold CS low for one more cycle after last edge
          sclk_int <= cpol;
          ss_n     <= '1';
          busy     <= '0';
          mosi     <= '0';
          state    <= idle;

      END CASE;
    END IF;
  END PROCESS;
END rtl;
