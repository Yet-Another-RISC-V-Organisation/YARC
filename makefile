CC = iverilog
FLAGS = -Wall -Winfloop
EXE = tb.out
SRCS = alu_control.v tb.v alu.v control.v cpu.v forward.v hazard.v immGen.v PC.v memory.v RegFile.v
WAVE = surfer

all:
	$(CC) $(FLAGS) -o $(EXE) $(SRCS)
	vvp $(EXE)
	$(WAVE) tb_dumpfile.vcd waveform.gtkw

clean:
	rm -rf $(EXE)