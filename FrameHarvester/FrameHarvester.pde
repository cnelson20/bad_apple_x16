PImage frame;
String numstring;

char mode = 't';

ArrayList<Integer> bytes;

void setup() {
  size(80,60);
  frameRate(30);
  if (mode == 'a') {
    byte[] b = loadBytes("ALL.BIN");
    bytes = new ArrayList();
    for (int i = 0; i < b.length; i++) {
      bytes.add((b[i] >= 0) ? (b[i]) : (b[i] + 256));  
    } 
  }
}
int frame_index = 1;
int all_index = 2;

void draw() {
  if (frame_index >= 6573) {
    background(color(255,0,0));
    return; 
  }
  numstring = frame_index + "";
  while (numstring.length() < 4) {
    numstring = "0" + numstring; 
  }
  if (mode == 'r') {
    println("../output/" + numstring + ".bin");
    byte[] f = loadBytes("../output/" + numstring + ".bin");
    background(0);
    int x = 0;
    int y = 0;
    color curr = color(0);
    for (int i = 0; i < f.length; i++) {
      int j = f[i];
      if (j < 0) {j += 256;}
      /* print("(" + i + "," + hex((byte)j) + ") "); */
      
      if (j == 255) {break;}
      while (j > 0) {
        set(x, y, curr);
        if (++x >= width) {
          x = 0;
          y++;
        }
        j--;
      }
      curr = (curr == color(0)) ? (color(255)) : (color(0));
    }
    while (y < 30) {
      while (x < 40) {
        set(x, y, curr);
        x++;  
      }
      x = 0;
      y++;
    }
    /* println(""); */
    frame_index++; 
  } else if (mode == 'a') {
    color curr = color(0);
    int x = 0;
    int y = 0;
    background(curr);
    //all_index += 2;
    while (all_index < bytes.size() && bytes.get(all_index) != 0xFF) {
      int i = bytes.get(all_index);  
      while (i > 0) {
        i--; 
        set(x,y,curr);
        if (++x >= 40) {
          x = 0;
          y++;  
        }
      }
      curr = (curr == color(0)) ? color(255) : color(0);
      all_index++;
    }
    if (all_index >= bytes.size()) {
      frame_index = 10000;  
    }
    all_index++;
    
  } else if (mode == 'w' || mode == 'x' || mode == 't') {
    frame = loadImage("frames/img" + numstring + ".png");
    frame.resize(width,height);
    frame.filter(THRESHOLD, 0.45f);
  
    image(frame,0,0);
    
    int value = 0;
    color curr = color(0);
    if (mode == 'w' || frame_index == 1) {
      bytes = new ArrayList();
      bytes.add((int)'f');
      bytes.add((int)'k');
    }
    for (int i = 0; i < frame.pixels.length; i++) {
      if (frame.pixels[i] != curr) {
        curr = frame.pixels[i];
        if (bytes.size() > 0 && bytes.get(bytes.size() - 1) == 254) { 
           bytes.add(0);  
        }
        bytes.add(value);
        value = 1; 
      } else {
        if (++value >= 254) {
          if (bytes.size() > 0 && bytes.get(bytes.size() - 1) == 254) { 
            bytes.add(0);  
          }
          bytes.add(254);
          value = 0;  
        }
      }
    }
    if (bytes.size() > 0 && bytes.get(bytes.size() - 1) == 254) { 
      bytes.add(0);
    }
    bytes.add(value);
    bytes.add(255);
    
    if (mode != 't' && (frame_index == 6572 || (mode == 'w'))) {
      byte[] to_save = new byte[bytes.size()]; 
      for (int i = 0; i < to_save.length; i++) {
        int from_array = bytes.get(i);
        to_save[i] = (from_array >= 128) ? ((byte)(from_array - 256)) : ((byte)from_array);
      }
      saveBytes((mode == 'x') ? "ALL.BIN" : ("OUTPUT/" + numstring + ".BIN"), to_save); 
    }
    
    frame_index++; 
  }
  //println(frame_index);
}
