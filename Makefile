AS = sdas8051
CC = sdcc
MAKEBIN = makebin
GENERATE_EEPROM = ./tools/generate_eeprom.py

LDFLAGS = -mmcs51 --code-size 0x1400
ASFLAGS = -lops

TARGET = ti_graph_link_silver

all: $(TARGET).bin $(TARGET).eep
	@sha1sum -c $(TARGET).sha1 || echo "Build succeeded, but does not match."

ASM_FILES = ti_graph_link_silver.asm
REL_FILES = $(ASM_FILES:.asm=.rel)

%.rel: %.asm
	$(AS) $(ASFLAGS) $<

%.bin: %.hex
	$(MAKEBIN) -p $< $@

%.eep: %.bin
	$(GENERATE_EEPROM) $< $@

$(TARGET).hex: $(REL_FILES)
	$(CC) $(LDFLAGS) $^ -o $@

clean:
	$(RM) $(REL_FILES) $(TARGET).bin $(TARGET).hex
