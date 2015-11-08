import processing.serial.*;
boolean firstContact = false;
Serial myPort;

// calculated timings
int t_short = 352 / 2;
int t_mid = 512  / 2;
int t_long = 673 / 2;

// Bins for averaging
IntList short_bin;
IntList mid_bin;
IntList long_bin;
int[] avg_sum = new int[3];

int[] serialBuffer;

color lightblue = color(0, 136, 255);
color lightgreen = color(170, 255, 102);

void setup() {
  size(1024, 480);  
  printArray( Serial.list() );
  myPort = new Serial(this, Serial.list()[7], 115200);
  serialBuffer = new int[1023];
  setDeckMode('R');

  for (int i=0; i < 1023; i++) {
    serialBuffer[i] = 0;
  }

  short_bin = new IntList();
  mid_bin = new IntList();
  long_bin = new IntList();
}

void draw() {
  background(255);
  stroke(lightblue);

  for (int i=0; i < serialBuffer.length; i++) {

    int val =  serialBuffer[i];

    if ( val <= t_short ) {
      stroke(lightblue);
    } else if ( val <= t_mid ) {
      stroke(lightgreen);
    } else {
      stroke(192, 192, 192);
    }    
    line(i, height, i, height-val);
  }

  textSize(12);
  fill(32, 32, 32);

  if ( short_bin.size() > 0 ) {
    text( "short pulse avg:" + str(avg_sum[0] / short_bin.size() ), 10, 10);
  }

  if ( mid_bin.size()> 0  ) {
    text( "mid pulse avg:" + str(avg_sum[1] / mid_bin.size() ), 10, 20);
  }

  if (long_bin.size()> 0 ) {

    text( "long pulse avg:" +  str(avg_sum[2] / long_bin.size() ), 10, 30);
  }
}

void serialEvent( Serial myPort ) {

  if (myPort.available() > 0) {
    String myString = myPort.readStringUntil(10);
    if (myString != null) {
      int p = parseInt(myString.trim());
      int[] tempBuffer = new int[1023];
      // copy the current serialBuffer to tempBuffer
      arrayCopy(serialBuffer, 0, tempBuffer, 1, 1022);
      // add the new value at pos 0 
      tempBuffer[0] = p;
      // copy the whole thing back to serialBuffer
      arrayCopy(tempBuffer, 0, serialBuffer, 0, 1023);


      if ( p <= t_short ) {
        short_bin.append(p);
        avg_sum[0] += p;
      } else if ( p <= t_mid ) {
        mid_bin.append(p);
        avg_sum[1] += p;
      } else {
        long_bin.append(p); 
        avg_sum[2] += p;
      }
    }
  }
}

void setDeckMode (char mode) {
  switch(mode) {
  case 'R':
    myPort.write('R');
    break;

  case 'W':
    myPort.write('W');
    break;
  }
}