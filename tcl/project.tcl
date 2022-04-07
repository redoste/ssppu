create_project ssppu vivado/ -part xc7a35tcpg236-1
set_property -name "board_part" -value "digilentinc.com:basys3:part0:1.2" -objects [current_project]
set_property -name "platform.board_id" -value "basys3" -objects [current_project]

add_files -fileset constrs_1 constrs/basys3.xdc
add_files src/

set_property top board [current_fileset]
