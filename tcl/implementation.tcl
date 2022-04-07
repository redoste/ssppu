open_project vivado/ssppu.xpr
reset_run impl_1
launch_runs impl_1 -jobs 6
wait_on_run impl_1
