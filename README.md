TI USB Graph Link (Silver)
--------------------------

There are two hardware models of the Silver Graph Link USB cable: "A" and "B" as denoted by the last character of its production code. Most graph link cables contain a production code on the back label in the following format: `FMMYYH`:
 * `F` - Factory: `I` (Taiwan), `S` (China), `P` (China)
 * `MM` - Month of manufacture
 * `YY` - Year of manufacture
 * `H` - Hardware: either "A" or "B" (see description below)

The "A" version uses a Cypress CY7C64013 chipset and was manufactured from sometime in the early 2000s through March 2003. Starting around April 2003 through 2010, the "B" hardware version using the TI TUSB3410 was manufactured.

## Silver Link "A": Cypress CY7C64013

Some info about the "A" TI Silver Link is documented here: http://merthsoft.com/linkguide/usbdevices/SilverLink%20USB.txt
![Silver Link "A" CY7C64013](https://user-images.githubusercontent.com/129774/110289584-7d60fa80-7f9e-11eb-8a68-530d083bfea7.png)

### Hardware List

* `D1`: `D3G` Rohm Schottky barrier diode [RB471E (PDF)](http://rohmfs.rohm.com/en/products/databook/datasheet/discrete/diode/schottky_barrier/rb471et148-e.pdf)
* `L4`, `L4`: `2R7` 2.7µH inductor
* `U1`: `DQF` Voltage Regulator, 3.3V [S-812XXSG (PDF)](http://www.sih.com.hk/sih_eng/products/ic/pdf/s812-e.pdf) (81233SGUP)
* `U2`: `H8` Rohm Bias resistor transistor [IMH8A (PDF)](http://rohmfs.rohm.com/en/products/databook/datasheet/discrete/transistor/digital/umh8ntr-e.pdf)
* `U3`: `CY7C64013` Cypress USB [CY7C64013,113 (PDF)](https://media.digikey.com/pdf/Data%20Sheets/Cypress%20PDFs/CY7C64013,113.pdf)
* `X1`: `6.0F2D` 6MHz Crystal

### Cypress CY7C64013

Cypress M8 Series (M8 Core w/ 8K EPROM)

The CY7C64013 is a Full-Speed USB microcontroller made by Cypress. It uses a 6MHz external clock source.
The CPU uses a proprietary 8-bit RISC M8 architecture and is clocked at 12MHz.

* [Cypress Website on CY7C64013](https://web.archive.org/web/20010405082135/http://www.cypress.com/cypress/prodgate/usb/cy7c64x13.htm)
* [Cypress Website about USB Programming Tools](https://web.archive.org/web/20010617083043/http://www.cypress.com/design/progprods/usb/usbprog.html)

### GPIO connectivity
Graph Link   | GPIO  | SOIC Pin
-------------|-------|---------
Tip (red)    | P0[0] | 17
Ring (white) | P0[1] | 13

## Silver Link "B": TI TUSB3410

![Silver Link "B" TUSB3410](https://user-images.githubusercontent.com/129774/110289260-09265700-7f9e-11eb-9754-fe21131d1783.png)

### Hardware List

* `D1`: `D3G` Rohm Schottky barrier diode [RB471E (PDF)](http://rohmfs.rohm.com/en/products/databook/datasheet/discrete/diode/schottky_barrier/rb471et148-e.pdf)
* `D2`: `3F` Chenmko Schottky barrier diode [CH461FGP (PDF)](http://www.chenmko.com.tw/en/data/goods/201107/1310112518k0vqy.pdf)
* `L1`, `L2`: `2R7` 2.7µH inductor
* `U1`: `24LC64` 64kbit EEPROM: Microchip [24LC64 (PDF)](https://ww1.microchip.com/downloads/en/DeviceDoc/21189T.pdf)
* `U2`: `AQI` TI LOD Regulator, 3.3V [TPS715 (PDF)](https://www.ti.com/lit/ds/symlink/tps715.pdf) (TPS71533DCKR)
* `U3`: `TUSB3410` USB TI [TUSB3410 (PDF)](https://www.ti.com/lit/ds/symlink/tusb3410.pdf)
* `U4`: `H8` Rohm Bias resistor transistor [IMH8A (PDF)](http://rohmfs.rohm.com/en/products/databook/datasheet/discrete/transistor/digital/umh8ntr-e.pdf)
* `Y1`: `12.0F4K` 12MHz Crystal

### GPIO connectivity
Graph Link   | GPIO | VQFN Pin
-------------|------|---------
Tip (red)    | P3.3 | 30
Ring (white) | P3.4 | 29

### EEPROM data

The EEPROM data contains a header which is first read by the bootloader in the TUSB3410 ROM. If the header matches the expected format, the size as is described in the header is read out from the EEPROM into Code RAM. The bootloader then jumps to this code.

#### Autoexec Binary Firmware:
OFFSET | TYPE                 | SIZE   | VALUE | DESCRIPTION
-------|----------------------|--------|-------|--------------------------
0x0000 | Signature0           | 1      | 0x10  | FUNCTION_PID_L
0x0001 | Signature1           | 1      | 0x34  | FUNCTION_PID_H
0x0002 | Data Type            | 1      | 0x07  | Autoexec binary firmware
0x0003 | Data Size(low byte)  | 1      | 0x00  | 0x1400 bytes of application code
0x0004 | Data Size(high byte) | 1      | 0x14  |
0x0005 | Check Sum            | 1      | 0x5a  | Checksum of the following firmware
0x0006 | Program              | 0x1400 |       | Binary application code
0x1406 | Data Type            | 1      | 0x00  | End of header

### Firmware
TUSB3410 contains an 8052 microprocessor. The application code contained within the EEPROM
is responsible for receiving commands over USB and communicating with the calculator over its
PORT3 GPIO.

### Building
The disassembled firmware can be build with [sdcc](http://sdcc.sourceforge.net)

```sh
$ make
sdas8051 -lops ti_graph_link_silver.asm
sdcc -mmcs51 --code-size 0x1400 ti_graph_link_silver.rel -o ti_graph_link_silver.hex
makebin -p ti_graph_link_silver.hex ti_graph_link_silver.bin
```
