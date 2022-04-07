open_project vivado/ssppu.xpr
reset_run synth_1
launch_runs synth_1 -jobs 6
wait_on_run synth_1
