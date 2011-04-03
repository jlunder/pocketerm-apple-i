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
  word key
  'long  i2cAddress, i2cSlaveCounter
  'word eepromLocation
  byte SimRam[4096]
  byte SimRom[12288]
  long SimParams[11]
  byte SimVram[4096]           ' screen character buffer
  long sync

PUB Main
  i2c.Initialize(i2cSCL)
  'eepromLocation := EEPROM_Base                                                 'Point i2c to EEPROM storage
  'temp2 := i2c.ReadByte(i2cSCL, EEPROMAddr, eepromLocation)                     'read test byte to see if data stored
  'text.start(video, false, 0, 0, 0, 0)
  'text.color($1020)
  kb.startx(26, 27, NumLock, RepeatRate)                                            'Start Keyboard Driver
  ser.start(r1,t1,0,2400)                                                       'Start Port2 to PC
  ser2.start(r2,t2,0,2400)                                                      'Start Port1 to main device
  'text.cls
  'text.str(string("Hello world!"))
  bytemove(@SimRam, @Code, @CodeEnd - @Code)

''start vga
  bytefill(@SimVram, 0, 4096)
  bytefill(@SimVram, 32, 80 * 40)
  wordfill(@SimVram + 4096 - 512, $1020, 40)
  SimVram[4096 - 8 + 2] := %110
  SimVram[0] := "A"
  SimVram[1] := "!"

  vga.start(video, @SimVram, @SimVram + 4096 - 512, @SimVram + 4096 - 8, @sync)

  waitcnt(clkfreq * 1 + cnt)    'wait 1 second for cogs to start
  'sim.start($0000, @SimRom, @SimRam, @SimVram)
  repeat
    key := kb.key                                                               'Go get keystroke, then return here
{    if key <128 and key > 0                                                     'Is the keystroke PocketTerm compatible?    was 96
       text.out(key)                                                             'Yes, so send it
       if key == 13
         text.out(10)
}
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

'LOOK FOR SERIAL INPUT HERE
{
    if pcport == 0                                                              'Is PC turned on at console for checking?
       remote2 := ser.rxcheck                                                   'Yes, look at the port for data                  
       if (remote2 > -1)                                                        'remote = -1 if no data
          ser2.tx(remote2)                                                      'Send the data out to the host device
          waitcnt(clkfreq/200 + cnt)                                            'Added to attempt eliminate dropped characters
    remote := ser2.rxcheck                                                      'Look at host device port for data
    if (remote > -1)
       if ascii == 1 'yes force 7 bit ascii
          if (remote > 127)
             remote := remote -128
       if pcport == 0       
          ser.tx(remote)
}

{
PUB EEPROM | eepromData
        eepromLocation := EEPROM_Base
        
        i2c.WriteLong(i2cSCL, EEPROMAddr, eepromLocation, 55)
        eepromLocation +=4
        i2c.WriteLong(i2cSCL, EEPROMAddr, eepromLocation, Baud)
        eepromLocation +=4
        i2c.WriteLong(i2cSCL, EEPROMAddr, eepromLocation, termcolor)
        eepromLocation +=4
        i2c.WriteLong(i2cSCL, EEPROMAddr, eepromLocation, pcport)
        eepromLocation +=4
        i2c.WriteLong(i2cSCL, EEPROMAddr, eepromLocation, ascii)
        eepromLocation +=4
        i2c.WriteLong(i2cSCL, EEPROMAddr, eepromLocation, curset)
        eepromLocation +=4
        i2c.WriteLong(i2cSCL, EEPROMAddr, eepromLocation, CR)
        waitcnt(clkfreq/200 + cnt)
        }


