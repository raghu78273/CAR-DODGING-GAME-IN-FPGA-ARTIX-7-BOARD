## Car Dodging Game constraints for the EDGE Artix-7 board.
## This reuses the same clock, VGA, and 5-button mapping already used in the
## other VGA projects in this workspace targeting xc7a35tftg256-1.

## 50 MHz system clock
set_property -dict { PACKAGE_PIN N11 IOSTANDARD LVCMOS33 } [get_ports { clk50mhz }];
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports { clk50mhz }];

## Push buttons
## Top    -> pause
## Bottom -> restart
## Left   -> move left
## Right  -> move right
## Center -> start
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { btn_pause }];
set_property -dict { PACKAGE_PIN L14 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { btn_restart }];
set_property -dict { PACKAGE_PIN M12 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { btn_left }];
set_property -dict { PACKAGE_PIN L13 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { btn_right }];
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { btn_start }];

## VGA sync
set_property -dict { PACKAGE_PIN F14 IOSTANDARD LVCMOS33 } [get_ports { vga_hsync }];
set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports { vga_vsync }];

## VGA red
set_property -dict { PACKAGE_PIN D15 IOSTANDARD LVCMOS33 } [get_ports { vga_r[0] }];
set_property -dict { PACKAGE_PIN F12 IOSTANDARD LVCMOS33 } [get_ports { vga_r[1] }];
set_property -dict { PACKAGE_PIN F13 IOSTANDARD LVCMOS33 } [get_ports { vga_r[2] }];
set_property -dict { PACKAGE_PIN E16 IOSTANDARD LVCMOS33 } [get_ports { vga_r[3] }];

## VGA green
set_property -dict { PACKAGE_PIN D16 IOSTANDARD LVCMOS33 } [get_ports { vga_g[0] }];
set_property -dict { PACKAGE_PIN F15 IOSTANDARD LVCMOS33 } [get_ports { vga_g[1] }];
set_property -dict { PACKAGE_PIN E15 IOSTANDARD LVCMOS33 } [get_ports { vga_g[2] }];
set_property -dict { PACKAGE_PIN H11 IOSTANDARD LVCMOS33 } [get_ports { vga_g[3] }];

## VGA blue
set_property -dict { PACKAGE_PIN G12 IOSTANDARD LVCMOS33 } [get_ports { vga_b[0] }];
set_property -dict { PACKAGE_PIN H12 IOSTANDARD LVCMOS33 } [get_ports { vga_b[1] }];
set_property -dict { PACKAGE_PIN H13 IOSTANDARD LVCMOS33 } [get_ports { vga_b[2] }];
set_property -dict { PACKAGE_PIN G14 IOSTANDARD LVCMOS33 } [get_ports { vga_b[3] }];
