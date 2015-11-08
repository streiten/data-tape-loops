#include <StackArray.h>
StackArray <bool> data_buffer;
StackArray <int> timeings;

int i = 0;
bool started = false;
bool data_sense_last = LOW; 
char mode = 'R'; 

// calculated timings
int t_short = 352 / 2;
int t_mid = 512  / 2;
int t_long = 673 / 2;


int time = 0;

// Hardware
const unsigned int PIN_READ = 2;
const unsigned int PIN_WRITE = 3;
const unsigned int PIN_SENSE = 4;


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
  data_sense = !digitalRead(PIN_SENSE);

  if(data_sense) {
      int duration = pulseIn(PIN_READ,HIGH);
      Serial.println(duration);
      //Serial.print(pulseToBit(duration));
  }

//    // If theres data on the buffer push it to the shift register / collect byte
//  if(!data_buffer.isEmpty()) {
//    Serial.println(data_buffer.pop());
//    Serial.println(data_buffer.count());   
//  }
//
//  if (!data_sense_last && data_sense) {
//    Serial.println("Started!");
//    data_sense_last = HIGH;
//  }
//
//  if (data_sense) {
//    // Serial.print(data_read);
//  }
//
//  if (data_sense_last && !data_sense) {
//    Serial.println("Stopped!");
//    data_sense_last = LOW;
//  }

}

void serialEvent() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    mode = inChar; 
    Serial.print("RX");
    Serial.println(inChar);
  }
}


void testWrite() {
  digitalWrite(PIN_WRITE, HIGH);
  delayMicroseconds(150); // Approximately 10% duty cycle @ 1KHz
  digitalWrite(PIN_WRITE, LOW);
  delayMicroseconds(150);
}

int pulseToBit(int pulseLength) {
      int bit; 
      
      if ( pulseLength <= t_short ) {
        bit = 0; 
      } else if ( pulseLength <= t_mid ) {
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

boolean checkSyncByte( int theByte, int syncByte) { 
  boolean result; 
  result = theByte == syncByte;
  return result; 
}

void testShiftAndSync() {

  // Serial.println(newByte,BIN); 
  int test; 

  int theByte; 
  byte newByte = 0; 
  int syncByte = B00001010;

  
  int bit = 0; 
  if(i % 2 == 0) bit = 1;
  
  newByte= shiftRegister(newByte,bit);
  Serial.print(newByte,BIN);
  Serial.println();
  
  if(checkSyncByte(syncByte,newByte)) {
    Serial.println("Sync!"); 
  }
  
}



