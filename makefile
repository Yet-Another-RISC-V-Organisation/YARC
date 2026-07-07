CC = iverilog
FLAGS = -Wall -Winfloop
EXE = tb.out
SRCS = alu_control.v tb.v alu.v control.v cpu.v forward.v hazard.v immGen.v PC.v memory.v RegFile.v
WAVE = surfer

all:
	$(CC) $(FLAGS) -o $(EXE) $(SRCS)
	vvp $(EXE)
	$(WAVE) cpu.vcd 
	#if you're using surfer, make sure to save the state of the waveform for future runs!!

clean:
	rm -rf $(EXE)