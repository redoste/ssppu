# ====================
#        Clocks
# ====================

set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
# Basys 3 100MHz clock
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]
# CPU 10MHz clock
create_generated_clock -name cpu_clk -source [get_ports clk] -divide_by 10 [get_pins cpu_clk_reg/Q]
# UART 9600Hz - 115207Hz clocks
# We check constraints with the maximum frequency
create_generated_clock -name uart_tx_clk -source [get_ports clk] -divide_by 868 [get_pins lgpio_controller/uart_tx_clk_reg/Q]
# NOTE : The RX clock will intentionally drift to make sure that the rising edge is at the middle of a bit
create_generated_clock -name uart_rx_clk -source [get_ports clk] -divide_by 868 [get_pins lgpio_controller/uart_rx_clk_reg/Q]
# VGA 5MHz clock
create_generated_clock -name pixel_clk -source [get_pins cpu_clk_reg/Q] -divide_by 2 [get_pins lvga_controller/pixel_clk_reg/Q]

# ====================
#         GPIO
# ====================

# UART
set_property PACKAGE_PIN A18 [get_ports uart_txd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_txd]
set_property PACKAGE_PIN B18 [get_ports uart_rxd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rxd]

set_output_delay -clock [get_clocks uart_tx_clk] 0.000 [get_ports {uart_txd}]
set_input_delay -clock [get_clocks uart_rx_clk] 0.000 [get_ports uart_rxd]

# Switches
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
set_property PACKAGE_PIN W15 [get_ports {sw[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[4]}]
set_property PACKAGE_PIN V15 [get_ports {sw[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[5]}]
set_property PACKAGE_PIN W14 [get_ports {sw[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[6]}]
set_property PACKAGE_PIN W13 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[7]}]
set_property PACKAGE_PIN V2 [get_ports {sw[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[8]}]
set_property PACKAGE_PIN T3 [get_ports {sw[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[9]}]
set_property PACKAGE_PIN T2 [get_ports {sw[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[10]}]
set_property PACKAGE_PIN R3 [get_ports {sw[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[11]}]
set_property PACKAGE_PIN W2 [get_ports {sw[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[12]}]
set_property PACKAGE_PIN U1 [get_ports {sw[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[13]}]
set_property PACKAGE_PIN T1 [get_ports {sw[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[14]}]
set_property PACKAGE_PIN R2 [get_ports {sw[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[15]}]

# LEDs
set_property PACKAGE_PIN U16 [get_ports {leds[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[0]}]
set_property PACKAGE_PIN E19 [get_ports {leds[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[1]}]
set_property PACKAGE_PIN U19 [get_ports {leds[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[2]}]
set_property PACKAGE_PIN V19 [get_ports {leds[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[3]}]
set_property PACKAGE_PIN W18 [get_ports {leds[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[4]}]
set_property PACKAGE_PIN U15 [get_ports {leds[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[5]}]
set_property PACKAGE_PIN U14 [get_ports {leds[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[6]}]
set_property PACKAGE_PIN V14 [get_ports {leds[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[7]}]
set_property PACKAGE_PIN V13 [get_ports {leds[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[8]}]
set_property PACKAGE_PIN V3 [get_ports {leds[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[9]}]
set_property PACKAGE_PIN W3 [get_ports {leds[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[10]}]
set_property PACKAGE_PIN U3 [get_ports {leds[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[11]}]
set_property PACKAGE_PIN P3 [get_ports {leds[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[12]}]
set_property PACKAGE_PIN N3 [get_ports {leds[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[13]}]
set_property PACKAGE_PIN P1 [get_ports {leds[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[14]}]
set_property PACKAGE_PIN L1 [get_ports {leds[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[15]}]

set_output_delay -clock [get_clocks cpu_clk] 0.000 [get_ports {{leds[0]} {leds[1]} {leds[2]} {leds[3]} {leds[4]} {leds[5]} {leds[6]} {leds[7]} {leds[8]} {leds[9]} {leds[10]} {leds[11]} {leds[12]} {leds[13]} {leds[14]} {leds[15]}}]

# 7 segments display
set_property PACKAGE_PIN W7 [get_ports {sseg_ca[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_ca[0]}]
set_property PACKAGE_PIN W6 [get_ports {sseg_ca[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_ca[1]}]
set_property PACKAGE_PIN U8 [get_ports {sseg_ca[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_ca[2]}]
set_property PACKAGE_PIN V8 [get_ports {sseg_ca[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_ca[3]}]
set_property PACKAGE_PIN U5 [get_ports {sseg_ca[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_ca[4]}]
set_property PACKAGE_PIN V5 [get_ports {sseg_ca[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_ca[5]}]
set_property PACKAGE_PIN U7 [get_ports {sseg_ca[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_ca[6]}]
set_property PACKAGE_PIN V7 [get_ports {sseg_ca[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_ca[7]}]
set_property PACKAGE_PIN U2 [get_ports {sseg_an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_an[0]}]
set_property PACKAGE_PIN U4 [get_ports {sseg_an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_an[1]}]
set_property PACKAGE_PIN V4 [get_ports {sseg_an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_an[2]}]
set_property PACKAGE_PIN W4 [get_ports {sseg_an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_an[3]}]

# Buttons
set_property PACKAGE_PIN U18 [get_ports {btn[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[4]}]
set_property PACKAGE_PIN T18 [get_ports {btn[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[0]}]
set_property PACKAGE_PIN W19 [get_ports {btn[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]
set_property PACKAGE_PIN T17 [get_ports {btn[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[2]}]
set_property PACKAGE_PIN U17 [get_ports {btn[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[3]}]

# PS/2
set_property PACKAGE_PIN C17 [get_ports ps2_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_clk]
set_property PULLUP true [get_ports ps2_clk]
set_property PACKAGE_PIN B17 [get_ports ps2_data]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_data]
set_property PULLUP true [get_ports ps2_data]

# ====================
#         VGA
# ====================

set_property PACKAGE_PIN G19 [get_ports {vga_red[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[0]}]
set_property PACKAGE_PIN H19 [get_ports {vga_red[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[1]}]
set_property PACKAGE_PIN J19 [get_ports {vga_red[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[2]}]
set_property PACKAGE_PIN N19 [get_ports {vga_red[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[3]}]
set_property PACKAGE_PIN N18 [get_ports {vga_blue[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[0]}]
set_property PACKAGE_PIN L18 [get_ports {vga_blue[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[1]}]
set_property PACKAGE_PIN K18 [get_ports {vga_blue[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[2]}]
set_property PACKAGE_PIN J18 [get_ports {vga_blue[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[3]}]
set_property PACKAGE_PIN J17 [get_ports {vga_green[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[0]}]
set_property PACKAGE_PIN H17 [get_ports {vga_green[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[1]}]
set_property PACKAGE_PIN G17 [get_ports {vga_green[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[2]}]
set_property PACKAGE_PIN D17 [get_ports {vga_green[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[3]}]
set_property PACKAGE_PIN P19 [get_ports vga_hs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hs]
set_property PACKAGE_PIN R19 [get_ports vga_vs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vs]

set_output_delay -clock [get_clocks pixel_clk] 0.000 [get_ports {{vga_red[0]} {vga_red[1]} {vga_red[2]} {vga_red[3]} {vga_blue[0]} {vga_blue[1]} {vga_blue[2]} {vga_blue[3]} {vga_green[0]} {vga_green[1]} {vga_green[2]} {vga_green[3]} {vga_hs} {vga_vs}}]

# ====================
#        Config
# ====================

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
