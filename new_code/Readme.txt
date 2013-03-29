**Overview**
I've had a million problems related to MIDI and serial-MIDI converters using the Arduino Uno, and until I figure out the problem, I've decided to send messages with OSC to Pure Data.  Processing_toPD is a processing sketch, which offers a variety of improvements over my previous Arduino sketch, MIDIarduinophone.

**Now the process is:**
1. Processing creates an OSC message (stands for open sound control; google it) when a note is hit
2. Pure Data (free download) takes OSC message and creates MIDI
3. If you're using a Mac (sorry everyone elseÉfor now) and have set up the IAC driver, this MIDI data can be sent to Garageband using the sendMIDI PD file (in the PD folder).  You should note, however, that there are lots of ways that you can use the OSC message to generate sound.  For example, you could substitute .wav or .mp4 files for MIDI. There are many possibilities if you're using Pure Data (or Max/MSP).  Google is your friend :)
4. For a simple MIDI generator, you can use the playMIDI PD file.  It's currently set up for 8 MIDI inputs.  You'll have to edit the PD file for additional notes.  

**Improvements over previous MIDI sketch**
-OSC has more options and Pure Data is awesome
-Simple visualizer/ keyboard in Processing that can be clicked and that shows when notes are triggered
-But I haven't actually tested it with my xylophone (if you can test it, lemme know if it works!)

**Requirements**
1. Due to a bug related to serial communication, you must install the unstable alpha 2.0 release of Processing.
2. Pure Data (open source) or Max/MSP : http://puredata.info/
3. PD patch from github
Currently sendMIDI.pd creates a MIDI note from the OSC message.  This PD file can be used send MIDI to Garageband. playMIDI.pd creates and plays MIDI notes from within Pure Data (no need for Garageband etc.).  You should open just one of these files depending upon your setup.
4. Processing Libraries:
- Arduino (maybe it's included in Processing by default; I can't remember)
- oscP5
- serial Processing (included by default?)

**Instructions (for Mac at the moment, sorry; I'm running Snow Leopard)**
0. Open Arduino software.  File > Examples > Firmata > Standard Firmata.  Compile and upload this sketch onto Arduino board.
1. Get all the requirements.  Note: The files may need to be in certain folders.  playMIDI.pd, for example, needs the tone.pd file to be in the same folder.
2. Open Audio MIDI Setup (search for it on your Mac)
3. Window > MIDI Studio (may not come up by default)
4. Click on IAC Driver
5. Make sure "Device is online" is checked
- if you're using Windows, I think you'll need MIDIyoke (Google).  This program routes MIDI to the correct channelsÉ

To send MIDI to Garageband
6. Open PD patch sendMIDI.pd
7. PD-Extended > Preferences > MIDI Setup > make the output device the IAC Driver
8. Open Garageband and make sure you select a software instrument
9. Open Processing sketch, "Processing_toPD.pde", make sure it compiles, run it 
10. If everything is working, you should hear MIDI notes in Garageband (I haven't actually tested this with the piezos)

To play MIDI in Pure Data
6. Open PD patch playMIDI.pd
7. Make sure that audio is enabled in PD
8. Open Processing sketch, "Processing_toPD.pde", make sure it compiles, run it 
9. If everything is working, you should hear MIDI notes.  You can test this by clicking on the keyboard in the Processing sketch.  Notice that there is a "amp" slider in the PD patch that you can pull up to increase volume.

**If you don't want to use a multiplexer (limit of 6 notes if you're using the Arduino Uno)**
1. upload Firmata Standard to the Arduino
2. download and run noMultiplex_toPD.pde (Processing sketch)
3. In this sketch, you can set the number of keys (6 max) by changing the value of the variable "numKeys."
4. The process to get sound is the same as with the other sketch (involves PD)