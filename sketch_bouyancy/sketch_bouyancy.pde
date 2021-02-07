/**
**********************************************************************************************************************
* @file       Maze.pde
* @author     Elie Hymowitz, Steve Ding, Colin Gallacher
* @version    V4.0.0
* @date       08-January-2021
* @brief      Maze game example using 2-D physics engine
**********************************************************************************************************************
* @attention
*
*
**********************************************************************************************************************
*/



/* library imports *****************************************************************************************************/ 
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
/* end library imports *************************************************************************************************/  



/* scheduler definition ************************************************************************************************/ 
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/ 



/* device block definitions ********************************************************************************************/
Board             haplyBoard;
Device            widgetOne;
Mechanisms        pantograph;

byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           renderingForce                     = false;
/* end device block definition *****************************************************************************************/



/* framerate definition ************************************************************************************************/
long              baseFrameRate                       = 120;
/* end framerate definition ********************************************************************************************/ 



/* elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerCentimeter                 = 40.0;

/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0); 

/* World boundaries */
FWorld            world;
float             worldWidth                          = 25.0;  
float             worldHeight                         = 10.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;

float             gravityAcceleration                 = 980; //cm/s2
/* Initialization of virtual tool */
HVirtualCoupling  s;

/* define blocks and paramters*/
float             liquidHeight                        = 4;
float             liquidDensity                       = 50;
boolean           useThreeLiuquids                    = false;
FBox              l1;
FBox              l2;
FBox              l3;

/* define start and stop button */
FCircle           c1;
FCircle           c2;

/* define game ball and paramters */
float             objectDensity                       = 200;
FCircle           g2;
FBox              g1;

/* define game start */
boolean           gameStart                           = false;

/* text font */
PFont             f;

/* end elements definition *********************************************************************************************/  



/* setup section *******************************************************************************************************/
void setup(){
		/* put setup code here, run once: */
  
		/* screen size definition */
		size(1000, 400);
  
		/* set font type and size */
		f                   = createFont("Arial", 16, true);

  
		/* device setup */
  
		/**  
		 * The board declaration needs to be changed depending on which USB serial port the Haply board is connected.
		 * In the base example, a connection is setup to the first detected serial device, this parameter can be changed
		 * to explicitly state the serial port will look like the following for different OS:
		 *
		 *      windows:      haplyBoard = new Board(this, "COM10", 0);
		 *      linux:        haplyBoard = new Board(this, "/dev/ttyUSB0", 0);
		 *      mac:          haplyBoard = new Board(this, "/dev/cu.usbmodem1411", 0);
		 */
		haplyBoard          = new Board(this, Serial.list()[0], 0);
		widgetOne           = new Device(widgetOneID, haplyBoard);
		pantograph          = new Pantograph();
  
		widgetOne.set_mechanism(pantograph);

		widgetOne.add_actuator(1, CCW, 2);
		widgetOne.add_actuator(2, CW, 1);
 
		widgetOne.add_encoder(1, CCW, 241, 10752, 2);
		widgetOne.add_encoder(2, CW, -61, 10752, 1);
  
  
		widgetOne.device_set_parameters();
  
  
		/* 2D physics scaling and world creation */
		hAPI_Fisica.init(this); 
		hAPI_Fisica.setScale(pixelsPerCentimeter); 
		world               = new FWorld();

		/* Set viscous layer */
		if (useThreeLiuquids)
		{
				l1                  = new FBox(24.5/3, liquidHeight);
				l1.setPosition(24.5/6, 8);
		}
		else
		{
				l1                  = new FBox(24.5, liquidHeight);
				l1.setPosition(24.5/2, 8);
		}
		l1.setFill(170,170,255,80);
		l1.setDensity(liquidDensity);
		l1.setSensor(true);
		l1.setNoStroke();
		l1.setStatic(true);
		l1.setName("Water");
		world.add(l1);

		if (useThreeLiuquids)
		{
				l2                  = new FBox(24.5/3, liquidHeight);
				l2.setPosition(24.5 / 2, 8);
				l2.setFill(170,155,255,80);
				l2.setDensity(liquidDensity * 2);
				l2.setSensor(true);
				l2.setNoStroke();
				l2.setStatic(true);
				l2.setName("Water");
				world.add(l2);

				l3                  = new FBox(24.5/3, liquidHeight);
				l3.setPosition(24.5 * 5/6, 8);
				l3.setFill(170,120,255,80);
				l3.setDensity(liquidDensity * 3);
				l3.setSensor(true);
				l3.setNoStroke();
				l3.setStatic(true);
				l3.setName("Water");
				world.add(l3);
		}
  
		/* Start Button */
		c1                  = new FCircle(2.0); // diameter is 2
		c1.setPosition(edgeTopLeftX+2.5, edgeTopLeftY+worldHeight/2.0-3);
		c1.setFill(0, 255, 0);
		c1.setStaticBody(true);
		world.add(c1);
  
		/* Finish Button */
		c2                  = new FCircle(2.0);
		c2.setPosition(worldWidth-2.5, edgeTopLeftY+worldHeight/2.0);
		c2.setFill(200,0,0);
		c2.setStaticBody(true);
		c2.setSensor(true);
		world.add(c2);
  
		/* Game Box */
		g1                  = new FBox(1, 1);
		g1.setPosition(2, 4);
		g1.setDensity(objectDensity);
		g1.setFill(random(255),random(255),random(255));
		g1.setName("Widget");
		world.add(g1);
  
		/* Game Ball */
		g2                  = new FCircle(1);
		g2.setPosition(3, 4);
		g2.setDensity(objectDensity);
		g2.setFill(random(255),random(255),random(255));
		g2.setName("Widget");
		world.add(g2);
  
		/* Setup the Virtual Coupling Contact Rendering Technique */
		s                   = new HVirtualCoupling((0.75)); 
		s.h_avatar.setDensity(4); 
		s.h_avatar.setFill(255,0,0); 
		s.h_avatar.setSensor(true);

		s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2); 
  
		/* World conditions setup */
		world.setGravity((0.0), gravityAcceleration); //1000 cm/(s^2)
		world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY)); 
		world.setEdgesRestitution(.4);
		world.setEdgesFriction(0.5);
 
		world.draw();  
  
		/* setup framerate speed */
		frameRate(baseFrameRate);
    
		/* setup simulation thread to run at 1kHz */
		SimulationThread st = new SimulationThread();
		scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}
/* end setup section ***************************************************************************************************/



/* draw section ********************************************************************************************************/
void draw(){
		/* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
		if(renderingForce == false){
				background(255);
				textFont(f, 22);
 
				if(gameStart){
						fill(0, 0, 0);
						textAlign(CENTER);
						text("Push the ball or square to the red circle", width/2, 60);
						textAlign(CENTER);
						text("Touch the green circle to reset", width/2, 90);    
				}
				else{
						fill(128, 128, 128);
						textAlign(CENTER);
						text("Touch the green circle to start the maze", width/2, 60);
				}
  
				world.draw();
		}
}
/* end draw section ****************************************************************************************************/



/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable{
  
		public void run(){
				/* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    
				renderingForce = true;
    
				if(haplyBoard.data_available()){
						/* GET END-EFFECTOR STATE (TASK SPACE) */
						widgetOne.device_read_data();
    
						angles.set(widgetOne.get_device_angles()); 
						posEE.set(widgetOne.get_device_position(angles.array()));
						posEE.set(posEE.copy().mult(200));  
				}
    
				s.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7); 
				s.updateCouplingForce();
 
 
				fEE.set(-s.getVirtualCouplingForceX(), s.getVirtualCouplingForceY());
				fEE.div(100000); //dynes to newtons
    
				torques.set(widgetOne.set_device_torques(fEE.array()));
				widgetOne.device_write_torques();
    
				if (s.h_avatar.isTouchingBody(c1)){
						gameStart = true;
						g1.setPosition(2,8);
						g2.setPosition(3,8);
						s.h_avatar.setSensor(false);
				}
  
				if(g1.isTouchingBody(c2) || g2.isTouchingBody(c2)){
						gameStart = false;
						s.h_avatar.setSensor(true);
				}
  
  
  
				/* Viscous layer codes */
				if (s.h_avatar.isTouchingBody(l1)){
						s.h_avatar.setDamping(700);
				}
				else{
						s.h_avatar.setDamping(10); 
				}
  
				if(gameStart && g1.isTouchingBody(l1)){
						g1.setDamping(20);
				}
  
				if(gameStart && g2.isTouchingBody(l1)){
						g2.setDamping(20);
				}
  
  
				/* Bouyancy of fluid on avatar and gameball section */
				/* if (g1.isTouchingBody(l1)){ */
				/*   float b_s; */
				/*   float bm_d = g1.getY()-l1.getY()+l1.getHeight()/2; // vertical distance between middle of ball and top of water */
    
				/*   if (bm_d + g1.getWidth()/2 >= g1.getWidth()) { //if whole ball or more is submerged */
				/*     b_s = g1.getWidth(); // amount of ball submerged is ball size */
				/*   } */
				/*   else { //if ball is partially submerged */
				/*     b_s = bm_d + g1.getWidth()/2; // amount of ball submerged is vertical distance between middle of ball and top of water + half of ball size */
				/*   } */
  
				/*   g1.addForce(0,l1.getDensity()*sq(b_s)*gravityAcceleration*-1); // 300 is gravity force */
   
				/* } */
  
				/* if (g2.isTouchingBody(l1)){ */
				/*   float b_s; */
				/*   float bm_d = g2.getY()-l1.getY()+l1.getHeight()/2; // vertical distance between middle of ball and top of water */
    
				/*   if (bm_d + g2.getSize()/2 >= g2.getSize()) { //if whole ball or more is submerged */
				/*     b_s = g2.getSize(); // amount of ball submerged is ball size */
				/*   } */
				/*   else { //if ball is partially submerged */
				/*     b_s = bm_d + g2.getSize()/2; // amount of ball submerged is vertical distance between middle of ball and top of water + half of ball size */
				/*   } */
  
				/*   g2.addForce(0,l1.getDensity()*sq(b_s)*gravityAcceleration*-1); // 300 is gravity force */
     
				/* } */
				/* End Bouyancy of fluid on avatar and gameball section */
  
  
				world.step(1.0f/1000.0f);
  
				renderingForce = false;
		}
}
/* end simulation section **********************************************************************************************/



/* helper functions section, place helper functions here ***************************************************************/

/* Alternate bouyancy of fluid on avatar and gameball helper functions, comment out
 * "Bouyancy of fluid on avatar and gameball section" in simulation and uncomment 
 * the helper functions below to test
 */
 

void contactPersisted(FContact contact){
		float size;
		float b_s;
		float bm_d;
		float drag_coeff;
		FBody object;
		FBody liquid;
  
		if(contact.contains("Water", "Widget")){
				object = contact.getBody2();
				liquid = contact.getBody1();

				size = 2 * sqrt(object.getMass() / object.getDensity() / 3.1415);
				if (object instanceof FCircle)
				{
						size = ((FCircle)object).getSize();
						drag_coeff = 0.5;
				}
				else
				{
						size = ((FBox)object).getHeight();
						drag_coeff = 1;
				}
				
				bm_d = object.getY() - liquid.getY() + liquidHeight / 2;

				if(bm_d >= size/2){ //  if fully submerged
						if (object instanceof FCircle)
								b_s = 3.1415 * sq(size/2);
						else
								b_s = sq(size);
				}
				else{ // if partially submerged
						b_s = size * (bm_d + size/2); // For the sake of simplicity assuming the submerged area is the same for bothh circle and box
				}

				/* object.addForce(0.5 * liquid.getDensity() * sq(object.getVelocityX()) * drag_coeff * b_s, 0); //for simplicity using same b_s as area */
				/* object.addForce(0, 0.5 * liquid.getDensity() * sq(object.getVelocityY()) * drag_coeff * b_s); //for simplicity using same b_s as area */
				object.addForce(0, liquid.getDensity() * b_s * gravityAcceleration*-1);
				object.setDamping(20);
		}
  
}


void contactEnded(FContact contact){
		if(contact.contains("Water", "Widget")){
				contact.getBody2().setDamping(0);
		}
}

/* End Alternate Bouyancy of fluid on avatar and gameball helper functions */


void justAFunction()
{
		
}
/* end helper functions section ****************************************************************************************/
