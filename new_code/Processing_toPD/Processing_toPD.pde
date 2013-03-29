/////////////////////////////////////////////////////////////
// OSCtoMIDIarduino
// jdeboi
// July 2012
// for more info- jdeboi.com
// Feel free to copy, distribute, improve, deconstruct...
/////////////////////////////////////////////////////////////


import oscP5.*;
import netP5.*;
import processing.serial.*;
import cc.arduino.*;

//////////set these values//////////
int baudRate = 57600;
int multiplexerNum = 1;
int numKeys = 8*multiplexerNum;
int [] PadNote = {60,62,64,65,67,69,71,72};	            //array containing MIDI note values,                                                           
int [] PadCutOff = {50,50,50,50,50,50,50,50};	    //array containing "threshold" values; up to 1023, but probably around 600                                                            //increase (up to 1023) in order to make piezos less sensitive  
int [] MaxPlayTime = {90,90,90,90,90,90,90,90};		    //"time" each note remains active												
int [] activePad = {0,0,0,0,0,0,0,0};                       // array of flags of pad currently playing
int [] PinPlayTime = {0,0,0,0,0,0,0,0};                     // counter since pad started to play
boolean VelocityFlag = false;				    // true = volume corresponds to force of hit
int winW = 600;
int winH = 400;
int sendPort = 12000;                                        //port over which sketch sends messages to audio software
int clickVolume = 1023;                                       //sets volume when key clicked on processing button
//////////////////////////////////////

Arduino arduino;
int hitavg = 0;
int pad = 0;
int analogPin = 0;
int liveKeys = 0;

int r0 = 0;      //value of select pin at the 4051 (s0)
int r1 = 0;      //value of select pin at the 4051 (s1)
int r2 = 0;      //value of select pin at the 4051 (s2)
int count = 0;   //which y pin we are selecting

int [] multiplex = new int [numKeys];
int keyW;
int keyH;
int [] x = new int [numKeys];
int [] y = new int [numKeys];

OscP5 oscP5;
//NetAddress myRemoteLocation;
NetAddress myRemoteLocation = new NetAddress("127.0.0.1", sendPort);

void setup() {
  size(winW, winH);
  arduino = new Arduino(this, Arduino.list()[0], baudRate);
  
  for (int i = 0; i <= 13; i++){
    arduino.pinMode(i, Arduino.INPUT);
  }
    
  arduino.pinMode(2, Arduino.OUTPUT);    // s0
  arduino.pinMode(3, Arduino.OUTPUT);    // s1
  arduino.pinMode(4, Arduino.OUTPUT);    // s2
  
  /* start oscP5, listening for incoming messages at port 13000; use this if you ever to listen for OSC messages */
  oscP5 = new OscP5(this, 13000);
  
  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the int padR, int padL, int padT, int padB, int padKsame, hence you will
   * send messages back to this sketch.
   */
    
    setKeyXY(30, 30, 50, 50, 5);    //set padding on visual keyboard: R, L, top, bottom, between keys
    flushKeys();
}  

//*******************************************************************************************************************
// Main Program   
//*******************************************************************************************************************

void draw (){
  readSensors();
  for(int i = 0; i < numKeys; i++){
    checkSensor(i);
  }
  
  for(int i = 0; i < numKeys; i++){
    if(activePad[i] == 1){
      fill(28, 234, 195);
    }
    else{
      fill(80);
    }
    stroke(255);
    strokeWeight(2);
    rect(x[i], y[i], keyW, keyH);
    fill(255);
    text(PadNote[i], x[i]+10, y[i]+20);
  }
}

void readSensors() {
  for (count=0; count<=7; count++) {
    
    /////////// select the bit for digital out sent to multiplexer to cycle through 8 inputs /////////////////// 
    r2 = count & 0x01;    	        // code that assigns values to digital pins
    r1 = (count>>1) & 0x01;     
    r0 = (count>>2) & 0x01;      
   
    arduino.digitalWrite(2, r0);        //sets the digital output pins to high or low (from values above)
    arduino.digitalWrite(3, r1);
    arduino.digitalWrite(4, r2);
  
    /////Read and store the input value at a location in the array/////////////
    for(int i = 0; i < multiplexerNum; i++){	
      int n = count + 8*i;
      multiplex[n] = arduino.analogRead(i);	  //each element of array "multiplex" corresponds to the  
      if(multiplex[n] > PadCutOff[n]){
        println(n + ": " + multiplex[n]);            //use to print the voltage (0 to 1023 corresponding to 0 to 5V)  
      }
    }                                                //voltage read at a particular piezo	
  }

}



void checkSensor(int i){		//function to get values of each piezo; only checking a single analog input pin
  hitavg = multiplex[i];			//variable hitavg equals the voltage (0-1023) of the piezo
  if((hitavg > PadCutOff[i])){		//if the voltage of the piezo is higher than the value of the 
                                                //"threshold" element in array PadCutOff, then:
      if((activePad[i] == 0)){	                //and if the pad wasn't already on or "active"  
        if(VelocityFlag == true){
          hitavg = (hitavg / 8) -1;		//set velocity on MIDI scale 
        }					//set voltage of piezo into volume (or "velocity") range of MIDI note (0-127)
        else{
          hitavg = 127;				//if you don't care, set velocity to max value
        }
        
        activePad[i] = 1;			//make the pin active (was inactive)
        liveKeys++;
        sendOSC(i, PadNote[i], hitavg);
              
    }
      
    else {					//if the pad was already active when it was hit, increment its play time
      PinPlayTime[i] = PinPlayTime[i] + 1;
      }
    }
  
    else if((activePad[i] == 1)){ 	        //the pad is active, but it is not greater than cutoff, increment play time
      PinPlayTime[i] = PinPlayTime[i] + 1;
    
      if(PinPlayTime[i] > MaxPlayTime[i]){	//but if it's already been on for the amount set in the MaxPlayTime array, 
        activePad[i] = 0;                       //turn it off
        
        PinPlayTime[i] = 0;                     //reset the pin play time
        sendOSC(i, PadNote[i],0);
        liveKeys--;			
      }
    }
}


void setKeyXY(int padR, int padL, int padT, int padB, int padK){
  x[0] = padR;
  y[0] = padT;
  keyW = (winW - padR - padL - (numKeys * padK))/numKeys;
  keyH = (winH - padT - padB);
  for(int i = 1; i < numKeys; i++){
    x[i] = x[i-1] + keyW + padK;
    y[i] = padT;
  }
}

void mousePressed(){
  for(int i = 0; i < numKeys; i++){
    if(squareContains(i, mouseX, mouseY)){
      multiplex[i] = clickVolume;
      checkSensor(i);
    }
  }
}

boolean squareContains(int i, int mX, int mY){
  if(mX > x[i] && mX < x[i] + keyW && mY > y[i] && mY < y[i] + keyH){
    return true;
  }
  else{
    return false;
  }
}
      

void sendOSC(int i, int note, int velocity){
  OscMessage myMessage = new OscMessage("/fromArd");
  myMessage.add(i+1);          //identifier for routing in PD
  myMessage.add(note);         // add an int to the osc message
  myMessage.add(velocity); 
  //send the message
  oscP5.send(myMessage, myRemoteLocation);
}

void flushKeys(){
  for(int i = 0; i < numKeys; i++){
    OscMessage myMessage = new OscMessage("/fromArd");
    myMessage.add(i+1);            //identifier for routing in PD
    myMessage.add(PadNote[i]);         // add an int to the osc message
    myMessage.add(0); 
    //send the message
    oscP5.send(myMessage, myRemoteLocation); 
  }
}

