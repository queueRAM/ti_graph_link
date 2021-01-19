AS = sdas8051
CC = sdcc
MAKEBIN = makebin

LDFLAGS = -mmcs51 --code-size 0x1400
ASFLAGS = -lops

TARGET = ti_graph_link_silver

all: $(TARGET).bin

ASM_FILES = ti_graph_link_silver.asm
REL_FILES = $(ASM_FILES:.asm=.rel)

%.rel: %.asm
	$(AS) $(ASFLAGS) $<

%.bin: %.hex
	$(MAKEBIN) -p $< $@

$(TARGET).hex: $(REL_FILES)
	$(CC) $(LDFLAGS) $^ -o $@

clean:
	$(RM) $(REL_FILES) $(TARGET).bin $(TARGET).hex
