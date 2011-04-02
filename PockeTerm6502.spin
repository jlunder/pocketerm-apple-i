CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
                                         
  Cursor     = 95
  VideoCls   = 0
  NUM        = %100
  CAPS       = %010
  SCROLL     = %001
  RepeatRate = 40
  video      = 16
  backspace  = $C8
'  semi       = 59
'  rowsnow    = 36
  
   r1 = 31          'PC serial port receive line
   t1 = 30          'PC serial port transmit line
   r2 = 25          'Host device receive line
   t2 = 24          'Host device transmit line

   EEPROMAddr        = %1010_0000
   EEPROM_Base       = $7FE0
   i2cSCL            = 28

OBJ

  text: "VGA_1024"                                                              ' VGA Terminal Driver
  kb:   "keyboard"                                                              ' Keyboard driver
  ser:  "FullDuplexSerial256"                                                   ' Full Duplex Serial Controller
  ser2: "FullDuplexSerial2562"                                                  ' 2nd Full Duplex Serial Controller
  i2c:  "basic_i2c_driver"
VAR

  word key
  Byte Index
  Byte Rx
  Byte rxbyte
'  Long Stack[100]
  Byte temp
  Byte serdata
  Long Baud
  Byte termcolor
  Long BR[8]
  Long CLR[11]
  long  i2cAddress, i2cSlaveCounter
  Byte pcport
  Byte ascii
  Byte curset
  word eepromLocation
  Byte CR
  Byte LNM
PUB Main
  i2c.Initialize(i2cSCL)
  'eepromLocation := EEPROM_Base                                                 'Point i2c to EEPROM storage
  'temp2 := i2c.ReadByte(i2cSCL, EEPROMAddr, eepromLocation)                     'read test byte to see if data stored
  text.start(video)
  text.color(CLR[termcolor])                                                                                                        
  kb.startx(26, 27, NUM, RepeatRate)                                            'Start Keyboard Driver
  ser.start(r1,t1,0,baud)                                                       'Start Port2 to PC
  ser2.start(r2,t2,0,baud)                                                      'Start Port1 to main device  
  text.cls()
  text.str("Hello world!")
  repeat
    key := kb.key                                                               'Go get keystroke, then return here
    if key <128 and key > 0                                                     'Is the keystroke PocketTerm compatible?    was 96
       text.out(key)                                                             'Yes, so send it
       if key == 13
         text.out(10)


       
'' END keyboard console routine


                                                                                           
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


