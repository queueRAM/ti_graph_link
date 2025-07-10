##############################################
# SDCC Tools
##############################################
SDAS = sdas8051
SDCC = sdcc
MAKEBIN = makebin
GENERATE_EEPROM = ./tools/generate_eeprom.py

SDLDFLAGS = -mmcs51 --code-size 0x1400
SDASFLAGS = -lops
##############################################

##############################################
# gputils
##############################################
GPASM = gpasm
GPASMFLAGS =

#GPASM = gpasm -o ti_graph_link_serial_gray_pic16c54.hex ti_graph_link_serial_gray_pic16c54.asm && diff TI_Graph-Link_serial_gray_PIC16C54.hex ti_graph_link_serial_gray_pic16c54.hex

##############################################
# Targets
##############################################

SILVER_TARGET = ti_graph_link_silver
GRAY_TARGET = ti_graph_link_serial_gray

all: $(SILVER_TARGET).bin $(SILVER_TARGET).eep $(GRAY_TARGET).hex
	@sha1sum -c $(SILVER_TARGET).sha1 || echo "Silver link build succeeded, but does not match."
	@sha1sum -c $(GRAY_TARGET).sha1 || echo "Gray link build succeeded, but does not match."

SILVER_ASM_FILES = $(SILVER_TARGET).asm
SILVER_REL_FILES = $(SILVER_ASM_FILES:.asm=.rel)

GRAY_ASM_FILES = $(GRAY_TARGET).asm

%.rel: %.asm
	$(SDAS) $(SDASFLAGS) $<

%.bin: %.hex
	$(MAKEBIN) -p $< $@

%.eep: %.bin
	$(GENERATE_EEPROM) $< $@

$(SILVER_TARGET).hex: $(SILVER_REL_FILES)
	$(SDCC) $(SDLDFLAGS) $^ -o $@

$(GRAY_TARGET).hex: $(GRAY_ASM_FILES)
	$(GPASM) $(GPASMFLAGS) -o $@ $^

clean:
	$(RM) $(SILVER_REL_FILES) $(SILVER_TARGET).bin $(SILVER_TARGET).hex \
	       $(GRAY_TARGET).hex $(GRAY_TARGET).cod $(GRAY_TARGET).lst

.PHONY: all clean
