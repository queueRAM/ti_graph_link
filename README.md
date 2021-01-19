TI Connectivity USB Graph Link (Silver)
---------------------------------------

## Hardware

* `U1`: `24LC64` 64kbit EEPROM: Microchip [24LC64 (PDF)](https://ww1.microchip.com/downloads/en/DeviceDoc/21189T.pdf)
* `U2`: `AQI` TI LOD Regulator, 3.3V [TPS715 (PDF)](https://www.ti.com/lit/ds/symlink/tps715.pdf) (TPS71533DCKR)
* `U3`: `TUSB3410` USB TI [TUSB3410 (PDF)](https://www.ti.com/lit/ds/symlink/tusb3410.pdf)
* `U4`: `H8` Toshiba transistor [RN2909FS (PDF)?](https://toshiba.semicon-storage.com/info/docget.jsp?did=18909&prodName=RN2908)
* `Y1`: `12.0F4K` 12MHz Chrystal
* `D1`: `D3G` Rohm Schottky barrier diode [RB471E (PDF)](http://rohmfs.rohm.com/en/products/databook/datasheet/discrete/diode/schottky_barrier/rb471et148-e.pdf)
* `D2`: `3F` Chenmko Schottky barrier diode [CH461FGP (PDF)](http://www.chenmko.com.tw/en/data/goods/201107/1310112518k0vqy.pdf)?
* `L1`, `L2`: `2R7` 2.7µH inductor

## GPIO connectivity
* tip (red): TUSB3410 P3.3
* ring (white): TUSB3410 P3.4

## EEPROM data

### Autoexec Binary Firmware:
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

## Firmware
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
