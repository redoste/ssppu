.PHONY: all
all: project

src/mmio/rom.vhdl: asm/rom.ssppu tools/ssppu_as.py tools/ssppu_as_template.head tools/ssppu_as_template.tail
	cpp $< | python3 tools/ssppu_as.py vhdl | cat tools/ssppu_as_template.head - tools/ssppu_as_template.tail > $@

.PHONY: project
project: vivado/ssppu.xpr
vivado/ssppu.xpr: tcl/project.tcl src/mmio/rom.vhdl
	vivado -mode batch -source $< -nolog -nojournal

.PHONY: synthesis
synthesis: vivado/ssppu.runs/synth_1/board.dcp
vivado/ssppu.runs/synth_1/board.dcp: tcl/synthesis.tcl vivado/ssppu.xpr
	vivado -mode batch -source $< -nolog -nojournal

.PHONY: implementation
implementation: vivado/ssppu.runs/impl_1/board_routed.dcp
vivado/sspuu.runs/impl_1/board_routed.dcp: tcl/implementation.tcl vivado/ssppu.xpr vivado/ssppu.runs/synth_1/board.dcp
	vivado -mode batch -source $< -nolog -nojournal

.PHONY: bitstream
bitstream: vivado/ssppu.runs/impl_1/board.bit
vivado/ssppu.runs/impl_1/board.bit: tcl/bitstream.tcl vivado/ssppu.xpr vivado/sspuu.runs/impl_1/board_routed.dcp
	vivado -mode batch -source $< -nolog -nojournal

.PHONY: clean
clean:
	rm -rv vivado/

.PHONY: gui
gui: vivado/ssppu.xpr
	vivado $< -nolog -nojournal
.PHONY: tcl
tcl: vivado/ssppu.xpr
	vivado $< -mode tcl -nolog -nojournal
