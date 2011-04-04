CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
                                         
  Cursor     = 95
  NumLock    = %100
  CapsLock   = %010
  ScrollLock = %001
  RepeatRate = 40
  video      = 16

   r1 = 31          'PC serial port receive line
   t1 = 30          'PC serial port transmit line
   r2 = 25          'Host device receive line
   t2 = 24          'Host device transmit line

   EEPROMAddr        = %1010_0000
   EEPROM_Base       = $7FE0
   i2cSCL            = 28

OBJ
  sim:  "6502async"
  'text: "VGA_1024"                                                              ' VGA Terminal Driver
  vga:  "VGA_HiRes_Text"
  kb:   "Keyboard"                                                              ' Keyboard driver
  ser:  "FullDuplexSerial256"                                                   ' Full Duplex Serial Controller
  ser2: "FullDuplexSerial2562"                                                  ' 2nd Full Duplex Serial Controller
  i2c:  "Basic_I2C_Driver"

VAR
  long SimRam[4096 / 4]         ' long to ensure alignment
  long SimRom[12288 / 4]
  long SimVram[4096 / 4]        ' screen character buffer

  long SimParams[11]
  long sync
  word key
  'long  i2cAddress, i2cSlaveCounter
  'word eepromLocation

PUB Main
  bytefill(@SimVram, 0, 4096)
  bytefill(@SimVram, 32, 80 * 40)
  wordfill(@SimVram + 4096 - 512, $1020, 40)
  SimVram[4096 - 8 + 2] := %110
  vga.start(video, @SimVram, @SimVram + 4096 - 512, @SimVram + 4096 - 8, @sync)

  'i2c.Initialize(i2cSCL)
  kb.startx(26, 27, NumLock, RepeatRate)                                            'Start Keyboard Driver
  'ser.start(r1,t1,0,2400)                                                       'Start Port2 to PC
  'ser2.start(r2,t2,0,2400)                                                      'Start Port1 to main device

  waitcnt(clkfreq / 10 + cnt)    'wait 100 ms for cogs to start

  bytemove(@SimRam, @Code, @CodeEnd - @Code)
  sim.start($0000, @SimRom, @SimRam, @SimVram)

  repeat
    key := kb.key               'Go get keystroke, then return here
    if key == " "
      sim.pause
    if key == 13
      sim.resume

DAT
Code          byte $A2,$00                      ' 0000 START  LDX #$00        A2 00
              byte $BD,$13,$00                  ' 0002 LOOP   LDA DATA,X      BD 13 00
              byte $C9,$00                      ' 0005        CMP #$00        C9 00
              byte $F0,$07                      ' 0007        BEQ STOP        F0 07
              byte $9D,$00,$80                  ' 0009        STA $8000,X     9D 00 80
              byte $E8                          ' 000C        INX             E8
              byte $4C,$02,$00                  ' 000D        JMP LOOP        4C 02 00
              byte $4C,$10,$00                  ' 0010 STOP   JMP STOP        4C 10 00
              byte "Hello world from the 6502!"

CodeEnd

