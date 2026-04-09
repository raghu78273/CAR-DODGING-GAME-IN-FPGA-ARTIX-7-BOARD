## Car Dodging Game constraint template
## Fill in the PACKAGE_PIN values from your Artix-7 board master XDC or your VGA PMOD schematic.

## Clock
# set_property PACKAGE_PIN <CLK_PIN> [get_ports clk100mhz]
# set_property IOSTANDARD LVCMOS33 [get_ports clk100mhz]
# create_clock -period 10.000 -name clk100mhz [get_ports clk100mhz]

## Buttons
# set_property PACKAGE_PIN <BTN_LEFT_PIN>    [get_ports btn_left]
# set_property PACKAGE_PIN <BTN_RIGHT_PIN>   [get_ports btn_right]
# set_property PACKAGE_PIN <BTN_START_PIN>   [get_ports btn_start]
# set_property PACKAGE_PIN <BTN_PAUSE_PIN>   [get_ports btn_pause]
# set_property PACKAGE_PIN <BTN_RESTART_PIN> [get_ports btn_restart]
# set_property IOSTANDARD LVCMOS33 [get_ports {btn_left btn_right btn_start btn_pause btn_restart}]

## VGA output
## Map these to your onboard VGA connector or VGA PMOD resistor ladder.
# set_property PACKAGE_PIN <HSYNC_PIN> [get_ports vga_hsync]
# set_property PACKAGE_PIN <VSYNC_PIN> [get_ports vga_vsync]
# set_property PACKAGE_PIN <VGA_R0_PIN> [get_ports {vga_r[0]}]
# set_property PACKAGE_PIN <VGA_R1_PIN> [get_ports {vga_r[1]}]
# set_property PACKAGE_PIN <VGA_R2_PIN> [get_ports {vga_r[2]}]
# set_property PACKAGE_PIN <VGA_R3_PIN> [get_ports {vga_r[3]}]
# set_property PACKAGE_PIN <VGA_G0_PIN> [get_ports {vga_g[0]}]
# set_property PACKAGE_PIN <VGA_G1_PIN> [get_ports {vga_g[1]}]
# set_property PACKAGE_PIN <VGA_G2_PIN> [get_ports {vga_g[2]}]
# set_property PACKAGE_PIN <VGA_G3_PIN> [get_ports {vga_g[3]}]
# set_property PACKAGE_PIN <VGA_B0_PIN> [get_ports {vga_b[0]}]
# set_property PACKAGE_PIN <VGA_B1_PIN> [get_ports {vga_b[1]}]
# set_property PACKAGE_PIN <VGA_B2_PIN> [get_ports {vga_b[2]}]
# set_property PACKAGE_PIN <VGA_B3_PIN> [get_ports {vga_b[3]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {vga_hsync vga_vsync vga_r[*] vga_g[*] vga_b[*]}]
