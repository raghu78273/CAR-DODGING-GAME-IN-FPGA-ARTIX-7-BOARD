set proj_dir [file normalize [file dirname [info script]]]
set src_dir [file join $proj_dir "car doging game.srcs" "sources_1" "new"]
set constr_dir [file join $proj_dir "car doging game.srcs" "constrs_1" "new"]

set design_files [list \
    [file join $src_dir "button_conditioner.v"] \
    [file join $src_dir "vga_sync.v"] \
    [file join $src_dir "lfsr16.v"] \
    [file join $src_dir "bin_to_bcd5.v"] \
    [file join $src_dir "collision_detector.v"] \
    [file join $src_dir "game_state.v"] \
    [file join $src_dir "enemy_controller.v"] \
    [file join $src_dir "font8x8.v"] \
    [file join $src_dir "game_renderer.v"] \
    [file join $src_dir "car_dodging_game_top.v"] \
]

foreach file_path $design_files {
    if {[llength [get_files -quiet $file_path]] == 0} {
        add_files -norecurse $file_path
    }
}

set xdc_path [file join $constr_dir "car_dodging_game_template.xdc"]
if {[llength [get_files -quiet $xdc_path]] == 0} {
    add_files -fileset constrs_1 -norecurse $xdc_path
}

set_property top car_dodging_game_top [current_fileset]
update_compile_order -fileset sources_1
