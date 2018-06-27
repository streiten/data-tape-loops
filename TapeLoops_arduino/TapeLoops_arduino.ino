#include <StackArray.h>
StackArray <bool> data_buffer;
StackArray <int> timeings;

// PINs
const unsigned int PIN_READ = 2;
const unsigned int PIN_WRITE = 3;
const unsigned int PIN_SENSE = 4;

bool started = false;
bool data_sense_last = LOW; 

bool allwritten = false;


// config & defaults

// write output to back to serial instead of tape
// read timings instead of bits
bool debug = false;

// default mode is reading
char mode = 'R'; 

bool read_timings = false;

// PWM conversion timings
int t_short = 352 / 2; // 176
int t_mid = 512  / 2; // 256
int t_long = 673 / 2;  // 336

int t_short_read = 210; // 176
int t_mid_read = 290; // 256

int write_timing_offset = 0;
int read_timing_offset = 15;

// legacy 
int i = 0;

void setup() {
  pinMode(PIN_READ, INPUT);
  // attachInterrupt(digitalPinToInterrupt(PIN_READ), newDataInISR, HIGH);
  pinMode(PIN_WRITE, OUTPUT);
  pinMode(PIN_SENSE, INPUT_PULLUP);
  Serial.begin(115200);
  Serial.println("This is the Tapedrive speaking!");
}

void loop() {
  serialEvent(); //call the function
  

  bool data_read,data_sense; 
  
   switch(mode) {
   case 'R':
        data_sense = !digitalRead(PIN_SENSE);
        if(data_sense) {
            int duration = pulseIn(PIN_READ,HIGH) + read_timing_offset ; 
            switch(read_timings) {
                case false:
                  Serial.print(pulseToBit(duration));
                break;
                case true:
                  Serial.println(duration);
                break;
            }
        }
        
    break; 

    case 'W':
      
      if(!allwritten) {
        writeBitStream();
      }
      break;
    
    case 'r':
      allwritten = false;
    break;
    
    
  }
}

void serialEvent() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();

    // set the device mode
    switch(inChar) {

      // Read Bits (default)
      case 'R':
      mode = 'R';
      read_timings = false;
      Serial.println("Mode set to READ Bits") ;
      
      break;

      // Read Bytes
      case 'B':
      mode = 'R';
      Serial.println("Mode set to READ Bytes") ;
      break; 

      // Read Timings
      case 'T':
      mode = 'R';
      read_timings = true;
      Serial.println("Mode set to READ Bit Timings") ;
      break; 

      // reset allwritten
      case 'r':
      mode = 'r';
      Serial.write("allwritten reset!");
      break;

      // Write
      case 'W':
      mode = 'W';
      Serial.println("WRITEing now!") ;
      break;

      // Write to Serial instead of Tape
      case 'd':
      if(!debug) { 
        Serial.println("Debug ON") ;
        debug = true; 
      } else {
        Serial.println("Debug OFF") ;
        debug = false; 
      }
      break;

      default:
      Serial.println("Unsupported Command!") ;
      break;
      
    }    
  }
}

void pulseOut(int pulseLength) {
  if(!debug) {
    digitalWrite(PIN_WRITE, HIGH);
    delayMicroseconds(pulseLength + write_timing_offset );
    digitalWrite(PIN_WRITE, LOW);
    delayMicroseconds(pulseLength + write_timing_offset );
  } else {
    delayMicroseconds(pulseLength + write_timing_offset );
    Serial.print(String(pulseLength)) ;
    delayMicroseconds(pulseLength + write_timing_offset );
  }
}

void writeBitStream(){

    // StackArray <int> write_buffer_timings; 
    // String bitString = "2010111112111111112101010102";
    int pulseLength; 
    int starttime = millis();
        
    for(int j=0;j< 8;j++){
      
//        for(int i=0; i < bitString.length(); i++) {
//          pulseLength = bitToPulse(bitString.charAt(i));
//          pulseOut(pulseLength); 
//        }

       pulseLength = bitToPulse('2');
       pulseOut(pulseLength);
       for(int i = 0; i < 255; i++) {
         writeByte((char) i);
       }

//       pulseLength = bitToPulse('2');
//       pulseOut(pulseLength);
//
//      for(int i=0; i < 8; i++) {
//        pulseLength = bitToPulse('0');
//        pulseOut(pulseLength); 
//      }

    }

    int stoptime = millis();
    
    Serial.println("");
    Serial.println("Writing done in " + String((stoptime - starttime)) + " millis");
    allwritten = true;
}

void writeByte(byte data) {
  int pulseLength;
   pulseLength = bitToPulse('2');
   pulseOut(pulseLength);   
   for (byte mask = 00000001; mask>0; mask <<= 1) { 
      if(data & mask) {
        pulseLength = bitToPulse('1');
      } else {
        pulseLength = bitToPulse('0');
      }
      pulseOut(pulseLength);
  }  
}

int bitToPulse(int bit) {
     int pulseLength;
      if (bit == '0' ) {
        pulseLength = t_short; 
      } else if ( bit == '1' ) {
        pulseLength = t_mid; 
      } else if (bit == '2' ) {
        pulseLength = t_long; 
      }
      
      return pulseLength;
}

int pulseToBit(int pulseLength) {
      int bit; 
      if ( pulseLength <= t_short_read) {
        bit = 0; 
      } else if ( pulseLength <= t_mid_read ) {
        bit = 1;
      } else {
        bit = 2;
      }
      return bit;
} 

byte shiftRegister(int theByte, int theBit) {
  int shifted; 
  // shift byte left by theBit
  shifted = ( theByte << 1 ) | theBit;
  return (byte) shifted;
}




