import processing.serial.*; //<>//
boolean firstContact = false;
Serial myPort;

// C64 colors

color C64Colors[] = {
  #000000, #FFFFFF, #744335, #7CACBA, #7B4890, #64974F, #403285, #BFCD7A, #7B5B2F, #4f4500, #a37265, #505050, #787878, #a4d78e, #786abd, #9f9f9f
};

// This tapes colorset
color colorSet[] = new color[6];

// Protocol header and end byte 
byte[] packetHeaderSeq = { 'T', 'L', 'H' }; // Tape Loop Header
byte packetLen = 3;
ArrayList<tapePacketData> tapePacketBuffer = new ArrayList<tapePacketData>();

packetRecorder pr = new packetRecorder();
byteRecorder br = new byteRecorder();

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

class tapeBit {
  public  int time; 
  public boolean state;
  // 0 = data, 1 = sync
  public int type;
}

class tapeByte {
  public tapeBit[] bit = new tapeBit[8];
}

PShape file;

void setup() {
  size(1024, 768);  
  printArray( Serial.list() );
  myPort = new Serial(this, Serial.list()[7], 115200);
  serialBuffer = new int[1023];

  setDeckMode('T');
  setDeckMode('T');

  for (int i=0; i < 1023; i++) {
    serialBuffer[i] = 0;
  }

  short_bin = new IntList();
  mid_bin = new IntList();
  long_bin = new IntList();

  file = loadShape("RU-Plot.svg");

  // translate(width/4, -height/4);

  newPalette();
  // renderVertizes(file.getChild(0));
  // println(file.getChild(0).getVertexCount());
  // tests();
}

void draw() {

  background(0,0,0);

  for (int i=0; i < serialBuffer.length; i++) {
    int val =  serialBuffer[i];

    if ( val <= t_short ) {
      stroke(colorSet[0]);
      line(i, height, i, height-val);

    } else if ( val <= t_mid ) {
      stroke(colorSet[2]);
      line(i, height, i, height-val);

    } else {
      stroke(colorSet[4]);
      line(i, height, i, height-val);

    }
  }

  displayAverages();
  // renderViz(); 

  // renderVertizes(file.getChild(0));

  // renderSVG(file);
}

void newPalette() {

  for (int i =0; i<6; i++) {
    int c = floor(random(15));
    colorSet[i] = C64Colors[c];
  }
};

void renderSVG(PShape file) {

  pushMatrix();
  pushStyle();

  translate(width/2, height/2);
  strokeWeight(2);

  stroke(255, 0, 0);
  point(0, 0);  

  int shape_widht = 600;
  int shape_height = 600;
  shape(file, -shape_widht/2, -shape_height/2, shape_widht, shape_height);

  popMatrix();
  popStyle();
}

void renderVertizes(PShape path) {

  pushMatrix();
  pushStyle();
  noFill();
  stroke(0);
  strokeWeight(1);
  String out = "";
  float max = 0;

  beginShape();

  for (int i = 0; i < path.getVertexCount(); i++) {

    PVector v = path.getVertex(i);

    int x = floor(v.x);
    int y = floor(v.y);

    vertex(x, y);

    // out = out + floor(v.x * 5) + "," + floor(v.y * 5) + ",";

    if ((max < floor(v.x * 5)))
    {
      //   max = floor(v.x * 5);
    }

    if ((max < floor(v.y * 5)))
    {
      //   max = floor(v.y * 5);
    }

    //print("X: " + x);
    //println(" Y: " + y);
  }
  endShape();
  popMatrix();
  popStyle();

  String[] o = new String[100];
  int k = 0;

  for (int i = 0; i < path.getVertexCount(); i++) {
    PVector v = path.getVertex(i);

    fill(0, 0, 0);
    int x = floor(v.x) * 6 + 2000;
    int y = floor(v.y) * 6 + 2000;

    // text(x+","+y,x,y);

    o[0] = o[0] + x + "," + y + ",";
  }

  saveStrings("points.txt", o);
  println(out);
}
void renderViz() {
  //drawCircle(lightblue, 2, 200, null);
  // drawCircle(lightgreen, 2, 210, null);
  // drawCircle(0, 2, 205, null);
}

void drawCircle(color dot_color, int dot_size, int rad, int data[]) {
  float x, y;
  pushMatrix();
  pushStyle();
  noFill();
  stroke(dot_color);
  strokeWeight(dot_size);

  translate(width/2, height/2);
  beginShape();
  for (int i=0; i < 361; i++)  {
    float noise = random(0, 10);
    x = (rad + noise) * cos (radians(i));
    y = (rad + noise) * sin (radians(i));
    vertex(x, y);
  }
  endShape();

  popMatrix();
  popStyle();
}

void serialEvent( Serial myPort ) {
  if (myPort.available() > 0) {
    String myString = myPort.readStringUntil(10);
    if (myString != null) {

      int pulseTime = parseInt(trim(myString));
      // byteRecorder br = new byteRecorder();
      // tapeBit p = new tapeBit();

      tapeBit p = br.timeToBit(pulseTime);

      int[] tempBuffer = new int[1023];
      // copy the current serialBuffer to tempBuffer
      arrayCopy(serialBuffer, 0, tempBuffer, 1, 1022);
      // add the new value at pos 0 
      tempBuffer[0] = p.time;
      // copy the whole thing back to serialBuffer
      arrayCopy(tempBuffer, 0, serialBuffer, 0, 1023);
    }
  }
}


void displayAverages() {
  pushStyle();
  pushMatrix();

  textSize(12);
  fill(192, 192, 192);

  if ( short_bin.size() > 0 ) {
    text( "short pulse avg:" + str(avg_sum[0] / short_bin.size() ), 10, 10);
  }

  if ( mid_bin.size()> 0  ) {
    text( "mid pulse avg:" + str(avg_sum[1] / mid_bin.size() ), 10, 20);
  }

  if (long_bin.size()> 0 ) {
    text( "long pulse avg:" +  str(avg_sum[2] / long_bin.size() ), 10, 30);
  }

  popStyle();
  popMatrix();
}

void setDeckMode (char mode) {
  switch(mode) {
  case 'R':
    myPort.write('R');
    break;

  case 'T':
    myPort.write('T');
    break;

  case 'W':
    myPort.write('W');
    break;

  case 'r':
    myPort.write('r');
    break;
  }
}

void keyPressed() {
  switch(key) {
  case 'R':
    setDeckMode('R');
    break; 

  case 'T':
    setDeckMode('T');

    break; 

  case 'W':
    setDeckMode('W');
    break;

  case 'r':
    setDeckMode('r');
    break;

  case 'c': 
    newPalette();
    break;
  }
}

void tests() {


  Byte byteseq[] = {84, 76, 72};

  // Function Bytesequence to teststring
  String testString = new String();
  for (int i = 0; i<byteseq.length; i++) {
    String byteString = new String(); 
    for (int j=0; j <8; j++) {
      byteString += "\"" +  byteToPulses(byteseq[i], true)[j] + "\",";
    } 
    testString += "\"310\"," + byteString;
  }
  // print(testString);

  String testHeaderSeq[] = { "310", "176", "256", "176", "256", "176", "256", "176", "176", "310", "176", "256", "176", "176", "256", "256", "176", "176", "310", "176", "256", "176", "176", "256", "176", "176", "176" };
  for (int i = 0; i < testHeaderSeq.length; i++) {
    br.newPulseIn(testHeaderSeq[i]);
    // br.printStatus();
  }

  String testDataSeq[] = { "310", "255", "256", "176", "120", "176", "256", "176", "176", "310", "176", "0", "176", "176", "256", "256", "176", "176", "310", "176", "256", "176", "176", "0", "176", "176", "176" };
  for (int i = 0; i < testDataSeq.length; i++) {
    br.newPulseIn(testDataSeq[i]);
    // br.printStatus();
  }

  String testHeaderSeq1[] = { "310", "176", "256", "176", "256", "176", "256", "176", "176", "310", "176", "256", "176", "176", "256", "256", "176", "176", "310", "176", "256", "176", "176", "256", "176", "176", "176" };
  for (int i = 0; i < testHeaderSeq1.length; i++) {
    br.newPulseIn(testHeaderSeq1[i]);
    // br.printStatus();
  }

  String testDataSeq1[] = { "310", "0", "0", "0", "0", "0", "0", "0", "255", "310", "0", "255", "255", "255", "255", "256", "255", "255", "310", "0", "0", "0", "0", "255", "255", "255", "255" };
  for (int i = 0; i < testDataSeq1.length; i++) {
    br.newPulseIn(testDataSeq1[i]);
    // br.printStatus();
  }

  for (int i = 0; i < tapePacketBuffer.size(); i++) {
    tapePacketBuffer.get(i).printData();
  }
};

class tapePacketData {
  public byte[] data = new byte[3];

  void printData() {
    for (int i=0; i < 3; i++) {
      print(str(data[i]) + " ");
    }
    println();
  };
}

class packetRecorder {

  public boolean headerSeen = false;
  public boolean packetComplete = false;
  public boolean error = false;
  public int currentIndex = 0;

  public byte currentByte = 0;

  protected byte[] headerByteBuffer = {0, 0, 0};
  protected int headerByteBufferIndex = 0;
  protected byte[] dataBuffer = {0, 0, 0};

  public void printStatus() {
    println("PACKETRECORDER STATUS");
    println("SyncByte seen: " + headerSeen);
    println("Packet complete: " + packetComplete);
    println("Error: " + error);

    print("Sync Byte Buffer: ");
    for (int i=0; i<3; i++) {
      print(str(headerByteBuffer[i]) + " ");
    }
    println();

    println("CurrentIndex: " + currentIndex);
    println("CurrentByte: " + currentByte);
    print("Data Byte Buffer: ");
    for (int i=0; i<3; i++) {
      print(str(dataBuffer[i]) + " ");
    }
    println();
    println("---");
  }

  public void reset() {

    headerSeen = false;
    packetComplete = false;
    error = false;
    currentIndex = 0;
    currentByte = 0;
    for (int i=0; i<3; i++) { 
      headerByteBuffer[i] = 0;
    }
    for (int i=0; i<3; i++) { 
      dataBuffer[i] = 0;
    }
  }

  protected boolean checkHeaderSeq() {

    int headerBytesOK = 0;   
    int headerByteLen = 3;
    for (int i = 0; i < headerByteLen; i++) {
      if (packetHeaderSeq[headerByteLen-1-i] == headerByteBuffer[i]) {
        headerBytesOK++;
      }
    }
    if (headerBytesOK == 3) {
      return true;
    } else {
      return false;
    }
  }

  public void newByteIn(Byte byteIn) {

    currentByte = byteIn;

    // header seen ?
    if (!headerSeen) {

      byte[] tempBuffer = new byte[3];
      arrayCopy(headerByteBuffer, 0, tempBuffer, 1, 2);
      tempBuffer[0] = currentByte;
      arrayCopy(tempBuffer, headerByteBuffer);

      if (checkHeaderSeq()) {
        headerSeen = true; 
        for (int i = 0; i < 3; i++) {
          // headerByteBuffer[i] = 0;
        }
      }
    } else {

      if (currentIndex < packetLen) {
        dataBuffer[currentIndex] = currentByte;        
        currentIndex++;

        if (currentIndex == 3) {
          // got three bytes -> packet complete
          packetComplete = true; 
          // copy the data to the global data buffer ---> 

          tapePacketData data = new tapePacketData();
          for (int i=0; i<3; i++) {
            data.data[i] = dataBuffer[i];
          } 
          tapePacketBuffer.add(data); 

          reset();
        }
      } else {


        // if()// to much data 
        // error = true; 
        // println = "Err. More Data than specifieed."
      }
    }
  }
}

class byteRecorder {

  public boolean syncBitSeen = false; 
  public boolean byteComplete = false;
  public boolean error = false;
  public int currentIndex = 0;

  public tapeBit currentBit;
  public int currentByte;

  public void byteRecorder() {
  }

  public void reset() {
    syncBitSeen = false; 
    byteComplete = false;
    error = false;
    currentIndex = 0;
    currentByte = 0;

    tapeBit currentBit = new tapeBit();
  }


  // public boolean crc;
  public void newPulseIn(String pulseTimeString) {

    int pulseTime = parseInt(pulseTimeString.trim());
    currentBit = timeToBit(pulseTime);

    // check if bit is sync or data, if so reset and we start over
    if (currentBit.type == 1 || error) {
      syncBitSeen = true;
      byteComplete = false;
      currentByte = 0;
      error = false;
      currentIndex = 0;
    } else {

      // probably a data bit
      // push it in the register
      if (syncBitSeen) {
        if (currentIndex <= 7) {
          shiftByte(currentBit.state);

          if (currentIndex == 7) {
            println(currentByte);
            pr.newByteIn((byte)currentByte);
            byteComplete = true;
            syncBitSeen = false; 
            currentIndex = 0;
            return;
          } else {
            currentIndex++;
          }
        } else {
          println("Error: Databit seen. Syncbit expected.");
          error = true;
        }
      } else {
        error = true;
        println("Error: Databit but syncbit not set!");
      }
    }
  }

  public tapeBit timeToBit(int pulseTime) {
    tapeBit bit = new tapeBit();
    bit.time = pulseTime;

    if ( bit.time <= t_short ) {
      bit.state = false;

      short_bin.append(bit.time);
      avg_sum[0] += bit.time;
    } else if ( bit.time <= t_mid ) {
      bit.state = true;

      mid_bin.append(bit.time);
      avg_sum[1] += bit.time;
    } else {
      bit.state = true; 
      bit.type = 1;

      long_bin.append(bit.time); 
      avg_sum[2] += bit.time;
    }
    return bit;
  }

  public byte getByte() {
    return byte(currentByte);
  }

  public void shiftByte(boolean theBit) {
    int shifted; 
    // shift byte left by theBit
    currentByte = ( currentByte << 1 ) | int(theBit);
  }

  public void printStatus() {
    println("BITRECORDER STATUS");
    println("Syncbit seen: " + syncBitSeen);
    println("CurrentIndex: " + currentIndex);
    println("Currentbit State: " + currentBit.state );
    println("Currentbit Time: " + currentBit.time );
    println("Currentbit Type: " + currentBit.type );

    println("Bytecomplete: " + byteComplete);
    println("CurrentByte: " + currentByte);
    println("Error: " + error);
    println("---");
  }
}

public tapeBit tapeBitToPulse(tapeBit bit) {
  if (bit.type == 0) {
    if (bit.state == false ) {
      bit.time = t_short;
    } else if ( bit.state == true ) {
      bit.time = t_mid;
    }
  } else {
    bit.time = t_long;
  }
  return bit;
}

public int bitToPulse(int bit) {
  int time = 0;
  if (bit == 0) {
    time = t_short;
  } else if ( bit == 1 ) {
    time = t_mid;
  } else if ( bit == 2 ) {
    time = t_long;
  }
  return time;
}

public String[] byteToPulses(int theByte, boolean order) {

  String[] ret = new String[8]; 

  int mask = 1;
  for (int i = 0; i < 8; i++) { 
    if ((mask & theByte) >= 1) {
      ret[i] = str(bitToPulse(1));
    } else {
      ret[i] = str(bitToPulse(0));
    }
    mask = mask << 1;
  }

  if (order) { 
    return reverse(ret);
  };
  return ret;
}

//public tapeByte byteToTapeByte(byte regByte) {

//   tapeByte tapeByte = new tapeByte();
//   tapeBit tapeBit = new tapeBit();
//   int mask = 1;

//   for(int i = 0; i < 8 ; i++) { 

//     if((mask & regByte) >= 1) {
//       tapeBit.state = true;
//        tapeByte.bit[i] = bitToPulse(tapeBit);
//        println(tapeByte.bit[i].time);

//      } else {

//        tapeBit.state = false;
//        tapeByte.bit[i] = bitToPulse(tapeBit);
//        println(tapeByte.bit[i].time);

//      }
//      mask = mask << 1; 

//  }  
//  return tapeByte;
//}