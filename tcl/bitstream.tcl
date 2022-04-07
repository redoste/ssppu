open_project vivado/ssppu.xpr
launch_runs impl_1 -to_step write_bitstream -jobs 6
wait_on_run impl_1
