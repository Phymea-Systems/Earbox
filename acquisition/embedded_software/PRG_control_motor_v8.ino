//////////////////////////////////////////////////////////////////
//©2022 PHYMEA_systems 
//12/10/19 modif interrupt et remplacement par analog
//01/03/22 modif vitesse pour video de démo
//By V. OURY & T. LEROUX
/////////////////////////////////////////////////////////////////
#define ING_PIN 5
#define ROT_PIN 6
#define DIR_PIN 9
#define STEP_PIN 10
#define LED_DOOR 8
#define LED_MOTOR A2 // ou 16 c pareil

#define DIR2_PIN A0
#define STEP2_PIN A1
#define G_CTRL_PIN 7
#define DOOR_STATE_PIN 4
#define ENABLE_ROLLER A3
#define ENABLE_DOOR A4
#define ADC_DOOR A5

#define BOUNCE_DELAY 10
const byte interupt_pin = 2;
volatile unsigned long last_change;
volatile bool btn_pressed  = false;

volatile byte state = LOW;

bool door_state = false;
int ADC_Value = 1024;  //initialise ADC_value en position haute (porte fermée)

float low_speed = 0.3;//0.20;
float high_speed =0.6;//0.3;

void setup() { 
  Serial.begin(9600);
  pinMode(DIR_PIN, OUTPUT); 
  pinMode(STEP_PIN, OUTPUT); 
  pinMode(DIR2_PIN, OUTPUT); 
  pinMode(STEP2_PIN, OUTPUT); 
  pinMode(LED_DOOR, OUTPUT); 
   pinMode(LED_MOTOR, OUTPUT); 
   
  pinMode(ING_PIN, INPUT); 
  pinMode(ROT_PIN, INPUT); 
  pinMode(G_CTRL_PIN, INPUT); 
  pinMode(DOOR_STATE_PIN, OUTPUT); 
  pinMode(ENABLE_ROLLER, OUTPUT); 
  pinMode(ENABLE_DOOR, OUTPUT);

  //attachInterrupt(digitalPinToInterrupt(interupt_pin),ISR_function, CHANGE);    
  //Check si la porte est déjà ouverte en position MAX
  //boolean btn_state_temp = digitalRead(interupt_pin);
  //Serial.println(btn_state_temp);
  ADC_Value = analogRead(ADC_DOOR);
  Serial.println(ADC_Value);
  /*
  if (btn_state_temp==LOW) { 
      btn_pressed = true;
      Serial.println(F("Button : pressed"));
    }
  else if (btn_state_temp==HIGH){
      btn_pressed = false;
      Serial.println(F("Button : released"));
    }
    */
  //////Définition de la fin de course de la porte (=ouverte en position MAX) 
  door_end();
  delay(10);                      
  /// intitialisation des Rouleaux 
  digitalWrite(ENABLE_ROLLER, LOW); //Active le driver                     
  rotateDeg(-360, 0.06);//0.03
  delay(10);
  rotateDeg(-360, 0.08);//0.06
  delay(10);
  rotateDeg(-360, 0.09);//0.08
  digitalWrite(ENABLE_ROLLER, HIGH); //Désactive le driver
  door_down();
} 

void loop(){
  //ADC_Value = analogRead(ADC_DOOR);
  //Serial.println(ADC_Value);
  float spd = 0.09;// définit la vitesse de rotation 1-0.01 
  int rot = -144 ;
  int rep = 0;  
  if (digitalRead(G_CTRL_PIN) == 1){
    //delay(20);
    door_ctrl();
  }
  int ING_state = digitalRead(ING_PIN);   //lit le pin pour un démarrage d'acquisition
  if (ING_state == 1){                 //SI l'état de capture est HIGH démarre la séquence de rotation
     Serial.println("Capture start");
     digitalWrite(ENABLE_ROLLER, LOW); //Active le driver
     int ROT_state = 0; //met l'état de rotation sur LOW
     while (rep <5){    
       digitalWrite(LED_MOTOR, HIGH);
       delay(300);
       digitalWrite(LED_MOTOR, LOW);
       delay(150);
       rep ++;
     }
   //Photo1
     Serial.println("Photo 1");
     while(ROT_state == 0){            // TANT que l'état de rotation est LOW :
       ROT_state = digitalRead(ROT_PIN); // lit le Pin d'ordre de ROTATION
       delay(20); }                      // attend 20ms
      //rotate a specific number of degrees 
     rotateDeg(rot, spd);                 // execute une rotation
     ROT_state = 0;                    //met l'état de rotation sur LOW
   //Photo2
     Serial.println("Photo 2");
     while(ROT_state == 0){       
       ROT_state = digitalRead((ROT_PIN));
       delay(20); }
     rotateDeg(rot, spd); 
     ROT_state = 0;
   //Photo3
     Serial.println("Photo 3");
     while(ROT_state == 0){
       ROT_state = digitalRead((ROT_PIN));
       delay(20); }
     rotateDeg(rot, spd);
     ROT_state = 0;    
   //Photo4
     Serial.println("Photo 4");
     while(ROT_state == 0){
       ROT_state = digitalRead((ROT_PIN));
       delay(20); }
     rotateDeg(rot, spd);
     ROT_state = 0;  
   //Photo5
   Serial.println("Photo 5");
   while(ROT_state == 0){
     ROT_state = digitalRead((ROT_PIN));
     delay(20); }
   rotateDeg(rot, spd);
   ROT_state = 0; 
   ING_state = 0;  
   //Photo6
   Serial.println("Photo 6");
  door_state = false;
  while (digitalRead(G_CTRL_PIN) == 0){ delay(10);}
  door_ctrl();
  digitalWrite(ENABLE_ROLLER, HIGH); //Désactive le driver   
    
  }
                        //met l'état de capture sur LOW
  delay(10);                              //attend 10ms   


}

//////////////////////////////////////////////////////////////////////
/////////FUNCTIONS
void door_ctrl(){
  if (door_state== false){door_open();}
  if (door_state==true){door_close();}
  door_state= !door_state;
}

void rotate(int steps, float speed){ 
  //rotate a specific number of microsteps (8 microsteps per step) - (negitive for reverse movement)
  //speed is any number from .01 -> 1 with 1 being fastest - Slower is stronger
  int dir = (steps > 0)? HIGH:LOW;
  steps = abs(steps);

  digitalWrite(DIR_PIN,dir); 
   
  float usDelay = (1/speed) * 70;
  digitalWrite(LED_MOTOR, HIGH); 
  for(int i=0; i < steps; i++){ 
    digitalWrite(STEP_PIN, HIGH); 
    delayMicroseconds(usDelay); 

    digitalWrite(STEP_PIN, LOW); 
    delayMicroseconds(usDelay); 
  }
  digitalWrite(LED_MOTOR, LOW); 
} 

void rotateDeg(float deg, float speed){ 
  //rotate a specific number of degrees (negitive for reverse movement)
  //speed is any number from .01 -> 1 with 1 being fastest - Slower is stronger
  int dir = (deg > 0)? HIGH:LOW;
  digitalWrite(DIR_PIN,dir); 

  int steps = abs(deg)*(1/0.225);
  float usDelay = (1/speed) * 70;
  digitalWrite(LED_MOTOR, HIGH); 
  for(int i=0; i < steps; i++){ 
    digitalWrite(STEP_PIN, HIGH); 
    delayMicroseconds(usDelay); 

    digitalWrite(STEP_PIN, LOW); 
    delayMicroseconds(usDelay); 
  } 
  digitalWrite(LED_MOTOR, LOW); 
}


void rotateDoor(float deg, float speed){ 
  //rotate a specific number of degrees (negitive for reverse movement)
  //speed is any number from .01 -> 1 with 1 being fastest - Slower is stronger
  int dir = (deg > 0)? HIGH:LOW;
  digitalWrite(DIR2_PIN,dir); 

  int steps = abs(deg)*(1/0.225);
  float usDelay = (1/speed) * 70;
  digitalWrite(LED_MOTOR, HIGH); 
  for(int i=0; i < steps; i++){ 
    digitalWrite(STEP2_PIN, HIGH); 
    delayMicroseconds(usDelay); 

    digitalWrite(STEP2_PIN, LOW); 
    delayMicroseconds(usDelay); 
  }
  digitalWrite(LED_MOTOR, LOW); 
}

void door_end(){
      digitalWrite(ENABLE_DOOR, LOW); //Active le driver
      digitalWrite(LED_MOTOR, HIGH);
      //while (btn_pressed == false){ rotateDoor(2, 0.35); }
      while (analogRead(ADC_DOOR) > 10){ rotateDoor(1, 0.35); }
      digitalWrite(LED_MOTOR, LOW); 
      digitalWrite(ENABLE_DOOR, HIGH); //Désactive le driver  
      digitalWrite(LED_DOOR, HIGH);
}

void door_down(){
   digitalWrite(ENABLE_DOOR, LOW); //Active le driver
   rotateDoor(-360*4, high_speed); //
   rotateDoor(-360*2.25, low_speed); //1.14 sur proto
   digitalWrite(DOOR_STATE_PIN, LOW);
   digitalWrite(ENABLE_DOOR, HIGH); //Désactive le driver
   digitalWrite(LED_DOOR, LOW);
}

void door_open(){
   digitalWrite(ENABLE_DOOR, LOW); //Active le driver
   rotateDoor(360*5.75, high_speed); //.6
   rotateDoor(360*0.25, low_speed); //.4
   digitalWrite(DOOR_STATE_PIN, HIGH);
   digitalWrite(ENABLE_DOOR, HIGH); //Désactive le driver
   digitalWrite(LED_DOOR, HIGH);
}

void door_close(){
   digitalWrite(ENABLE_DOOR, LOW); //Active le driver
   rotateDoor(-360*5.5, high_speed); //.6
   rotateDoor(-360*0.5, low_speed); //.4
   digitalWrite(DOOR_STATE_PIN, LOW);
   digitalWrite(ENABLE_DOOR, HIGH); //Désactive le driver
   digitalWrite(LED_DOOR, LOW);
}
/*
void ISR_function(){
  if (millis()-last_change > BOUNCE_DELAY) {
  boolean btn_state = digitalRead(interupt_pin);
    if (btn_state==LOW) { 
      btn_pressed = true;
      Serial.println(F("ISR_Button : pressed"));
    }
    else if (btn_state==HIGH){
      btn_pressed = false;
      Serial.println(F("ISR_Button : released"));
    }
  }
  last_change = millis(); // Warning : millis() is not updated inside interrupts !!
}
*/
