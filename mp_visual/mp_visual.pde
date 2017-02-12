import oscP5.*;
import netP5.*;

import ddf.minim.*;

OscP5 oscP5;

Minim minim;
AudioInput in;

float mult;
float x, y, z;

class Agent {
  float x, y, z;
  float cx, cy, cz;
  float bx, by, bz;
  int ix, iy, iz;
  Agent left, right, up, down, far, near;
  float size;

  Agent(int _ix, int _iy, int _iz, float _x, float _y, float _z) {
    x = _x;
    y = _y;
    z = _z;
    ix = _ix;
    iy = _iy;
    iz = _iz;
    size = 0;

    if (ix > 0) {
      left = agents[iz][iy][ix - 1];
      left.right = this;
    }
    if (iy > 0) {
      up = agents[iz][iy - 1][ix];
      up.down = this;
    }
    if (iz > 0) {
      near = agents[iz - 1][iy][ix];
      near.far = this;
    }
  }

  void propagateMaximum() {
    float maxSize = size;
    if (left != null) {
      maxSize = max(maxSize, left.size);
    }
    if (right != null) {
      maxSize = max(maxSize, right.size);
    }
    if (up != null) {
      maxSize = max(maxSize, up.size);
    }
    if (down != null) {
      maxSize = max(maxSize, down.size);
    }
    if (near != null) {
      maxSize = max(maxSize, near.size);
    }
    if (far != null) {
      maxSize = max(maxSize, far.size);
    }

    size = maxSize;
  }

  void propagatePositiveAverage() {
    int count = 16;
    float avgSize = size * 16;
    if (left != null) {
      count++;
      avgSize += left.size;
    }
    //if(right != null) {
    //  count++;
    //  avgSize += right.size;
    //}
    if (up != null) {
      count++;
      avgSize += up.size;
    }
    //if(down != null) {
    //  count++;
    //  avgSize += down.size;
    //}
    if (near != null) {
      count++;
      avgSize += near.size;
    }
    //if(far != null) {
    //  count++;
    //  avgSize += far.size;
    //}

    size = avgSize / count;
  }

  void propagateAverage() {
    int count = 4;
    float avgSize = size * 4;
    if (left != null) {
      count++;
      avgSize += left.size;
    }
    if (right != null) {
      count++;
      avgSize += right.size;
    }
    if (up != null) {
      count++;
      avgSize += up.size;
    }
    if (down != null) {
      count++;
      avgSize += down.size;
    }
    if (near != null) {
      count++;
      avgSize += near.size;
    }
    if (far != null) {
      count++;
      avgSize += far.size;
    }

    size = avgSize / count;
  }

  void cameraThis() {
    camera(x, y, z, cx, cy, cz, 0, 1, 0);
  }

  void draw() {
    float moveCoeff = 0.5;
    int shakeBox = 0;
    if (shakeBox > 0 && abs(in.left.get(0) * 50 * mult * 0.5) > 5) {
      float offset = 100;
      x = x * (1 - moveCoeff) + moveCoeff * (height * 1.00 / Nx * (ix - Nx / 2 + 0.5) + offset * sin(frameCount * 0.1 + map(iy, 0, Ny, 0, 2*PI)));
      y = y * (1 - moveCoeff) + moveCoeff * height * 1.00 / Ny * (iy - Ny / 2 + 0.5);
      z = z * (1 - moveCoeff) + moveCoeff * (height * 1.00 / Nz * (iz - Nz / 2 + 0.5) + offset * cos(frameCount * 0.1 + map(iy, 0, Ny, 0, 2*PI)));
    } else {
      x = x * (1 - moveCoeff) + moveCoeff * height * 1.00 / Nx * (ix - Nx / 2 + 0.5);
      y = y * (1 - moveCoeff) + moveCoeff * height * 1.00 / Ny * (iy - Ny / 2 + 0.5);
      z = z * (1 - moveCoeff) + moveCoeff * height * 1.00 / Nz * (iz - Nz / 2 + 0.5);
    }
    
    //propagatePositiveAverage();
    propagateAverage();
    //propagateMaximum();

    pushMatrix();
    translate(x, y, z);

    bx = 65;
    by = 16;
    bz = 8;

    int doAffectAngle = 0;

    cx = bx + x;
    cy = by + y;
    cz = bz + z;

    if (doAffectAngle > 0) {
      float anglez = size * noise(x, y, z);
      if (size <= 0) anglez = 0;
      rotateZ(anglez * frameCount / 180.0f * PI);

      float r = sqrt(bx * bx / 4 + by * by / 4);
      cx = r * cos(anglez) + x;
      cy = r * sin(anglez) + y;
      cz = bz / 2 + z;
    }

    int doAffectSize = 1;

    if (doAffectSize > 0) {
      float s = map(size, 0.0, 1.0, 1.0, 5.0);
      if (size < 0) s = 1;
      if (size > 1) s = 5;
      scale(1, s, s);

      cx = bx * 1 + x;
      cy = by * s + y;
      cz = bz * s + z;
    }

    int drawBox = 1;
    int drawBoxRandomly = 0;
    float drawBoxPercentage = 0.00;

    if (drawBox > 0) {
      stroke(0);
      strokeWeight(0);
      fill(255, 255); // box fader
      if (drawBoxRandomly <= 0 || noise(x * z, y + z * 0.1, frameCount * 0.09) < drawBoxPercentage)
        box(bx, by, bz);
    }

    int drawPerpLines = 0;
    if (drawPerpLines > 0) {
      strokeWeight(2);

      stroke(255, 0); // perpendicular line fader
      line(0, 0, 0, bx, 0, 0);
    }

    popMatrix();

    int drawConnectingLines = 1;
    if (drawConnectingLines > 0) {
      pushStyle();
      stroke(255, 0); // connecting line fader
      strokeWeight(2);

      float drawPercentage = 0.00;
      int neighbor = 1;
      if (neighbor > 0) {
        if (left != null) {
          if (noise(x * z, y + z * 0.1, frameCount * 0.09) < drawPercentage)
            line(left.cx, left.cy, left.cz, cx, cy, cz);
        }
        if (up != null) {
          if (noise(y * x, z + x * 0.1, frameCount * 0.09) < drawPercentage)
            line(up.cx, up.cy, up.cz, cx, cy, cz);
        }
        if (near != null) {
          if (noise(z * y, x + y * 0.1, frameCount * 0.09) < drawPercentage)
            line(near.cx, near.cy, near.cz, cx, cy, cz);
        }
      } else {
        if (noise(x * z, y + z * 0.1, frameCount * 0.09) < drawPercentage) {
          Agent a = agents[(int)random(Nz)][(int)random(Ny)][(int)random(Nx)];
          if (a != this)
            line(a.cx, a.cy, a.cz, cx, cy, cz);
        }
      }
      popStyle();
    }
  }
}

Agent[][][] agents = new Agent[64/8][64/8][64/8];
int Nx;
int Ny;
int Nz;

void setup() {
  size(1920, 1080, P3D);
  frameRate(60);

  minim = new Minim(this);

  in = minim.getLineIn();

  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this, 44444);
  //oscP5 = new OscP5(this, 7000);

  Nx = agents[0][0].length;
  Ny = agents[0].length;
  Nz = agents.length;

  for (int i = 0; i < Nz; i++) {
    for (int j = 0; j < Ny; j++) {
      for (int k = 0; k < Nx; k++) {
        float x = height / Nx * (k - Nx / 2 + 0.5);
        float y = height / Ny * (j - Ny / 2 + 0.5);
        float z = height / Nz * (i - Nz / 2 + 0.5);
        agents[i][j][k] = new Agent(k, j, i, x, y, z);
      }
    }
  }
}

void draw() {

  background(0);

  pointLight(200, 200, 220, width/2, height/2, 1000);
  pointLight(200, 200, 220, width/2, height/2, -1000);
  //noLights();

  stroke(255);
  strokeWeight(2);
  mult = 2.0;
  /*  for (int i = 0; i < in.bufferSize() - 1; i++)
   {
   line(i, 50 + in.left.get(i)*50*mult, i+1, 50 + in.left.get(i+1)*50*mult);
   line(i, 150 + in.right.get(i)*50*mult, i+1, 150 + in.right.get(i+1)*50*mult);
   }*/

  int triggerBoxOffsetX = 0;
  triggerBoxOffsetX *= 0.1;
  triggerBoxOffsetX += Nx / 2;
  if (triggerBoxOffsetX < 0) triggerBoxOffsetX = 0;
  if (triggerBoxOffsetX >= Nx) triggerBoxOffsetX = Nx - 1;
  int triggerBoxOffsetY = 0;
  triggerBoxOffsetY *= 0.1;
  triggerBoxOffsetY += Ny / 2;
  if (triggerBoxOffsetY < 0) triggerBoxOffsetY = 0;
  if (triggerBoxOffsetY >= Nx) triggerBoxOffsetY = Ny - 1;
  int triggerBoxOffsetZ = 0;
  triggerBoxOffsetZ *= 0.1;
  triggerBoxOffsetZ += Nz / 2;
  if (triggerBoxOffsetZ < 0) triggerBoxOffsetZ = 0;
  if (triggerBoxOffsetZ >= Nx) triggerBoxOffsetZ = Nx - 1;

  int doSoundAffectBox = 1;
  if (doSoundAffectBox > 0)
    agents[triggerBoxOffsetX][triggerBoxOffsetY][triggerBoxOffsetZ].size =
      agents[triggerBoxOffsetX][triggerBoxOffsetY][triggerBoxOffsetZ].size * 0.5 + in.left.get(0) * 50 * mult * 0.5;
  else
    agents[triggerBoxOffsetX][triggerBoxOffsetY][triggerBoxOffsetZ].size = -10;

  int doCameraShift = 0;
  if (doCameraShift > 0 && abs(in.left.get(0) * 50 * mult * 0.5) > 5) {
    camera(width/2.0, (height/2.0) / tan(PI*30.0 / 180.0), height/2.0, width/2.0, height/2.0, 0, 0, 0, 1);
  } else {
    camera(width/2.0, height/2.0, (height/2.0) / tan(PI*30.0 / 180.0), width/2.0, height/2.0, 0, 0, 1, 0);
  }

  translate(width/2, height/2, -400);

  int doRotate = 1;
  if (doRotate > 0) {
    int autoRotate = 1;

    if (autoRotate > 0) {
      rotateY(frameCount / 180.0f * PI * 0.5);
    } else {
      rotateZ(-z / 180.0f * PI);
      rotateX(y / 180.0f * PI);
      rotateY(-x / 180.0f * PI);
    }
  }

  stroke(255, 0); // simple box fader
  noFill();
  box(height);

  for (int i = 0; i < Nz; i++) {
    for (int j = 0; j < Ny; j++) {
      for (int k = 0; k < Nx; k++) {
        agents[i][j][k].draw();
      }
    }
  }
}


void keyPressed() {
  if (key == 'a') agents[0][0][0].size = map(mouseX, 0, width, 0, 100);
  if (key == 's') agents[0][0][0].size = -10;
  if (key == 'd') agents[Nx/2][Ny/2][Nz/2].size = map(mouseX, 0, width, 0, 100);
  if (key == 'p') saveFrame("line-######.png");
}


void oscEvent(OscMessage theOscMessage) {
  /* check if theOscMessage has the address pattern we are looking for. */

  if (theOscMessage.checkAddrPattern("/orientation")==true) {
    //if (theOscMessage.checkAddrPattern("/scenes/cube")==true) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("fff")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      x = theOscMessage.get(0).floatValue();
      y = theOscMessage.get(1).floatValue();
      z = theOscMessage.get(2).floatValue();
      return;
    }
  } 
  //println("### received an osc message. with address pattern "+theOscMessage.addrPattern());
}