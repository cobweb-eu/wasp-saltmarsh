
#include <WaspSensorSW.h>

#include <Wasp3G.h>
#include <WaspFrame.h>

char ps1[]="POST /waspData HTTP/1.0\r\nContent-Length: \0";
char ps2[]="\r\nContent-Type: application/x-www-form-urlencoded\r\n\r\n\0";

char apn[] = "wlanp.com";
char login[] = "situ";
char password[] = "situ";


char IP[] = "137.43.130.184";
uint16_t port = 80;
char id='2';
char PIN[]="0000";
 
int8_t answer;


#define NUM 4
#define NCHR 20
#define NDEC 10

char soilTempVal[NUM][NCHR];
char condVal[NUM][NCHR];
char temI[NUM][NCHR];
char convVal[NUM][NCHR];

int mdVal;

// Value 1 used to calibrate the sensor
#define point1_cond 10500
// Value 2 used to calibrate the sensor
#define point2_cond 40000

// Point 1 of the calibration 
#define point1_cal 197.00
// Point 2 of the calibration 
#define point2_cal 150.00

conductivityClass ConductivitySensor;


pt1000Class temperatureSensor;




void setup() {
  float value;
 
    // Turn on the USB and print a start message
  USB.ON();
  USB.println(F("start"));
  delay(100);

  // Turn on the sensor board
  SensorSW.ON();  

  ConductivitySensor.setCalibrationPoints(point1_cond, point1_cal, point2_cond, point2_cal);
  delay(2000);
  
  // Turn on the RTC
  RTC.ON();
  
  mdVal=0;
  
   USB.println(F("**************************"));
   // 1. sets operator parameters
   _3G.set_APN(apn, login, password);
   // And shows them
   _3G.show_APN();
   USB.println(F("**************************"));
  
}



void loop() {
  RTC.ON(); 
  SensorSW.ON();
 USB.println(RTC.getTime());
 int len;
 float value;
 char number[20];

  
 if(mdVal==0){
       
  
    int i;
    char output[8+4*NUM*(NCHR+8)];
    output[0]='\0';
    char cma[]={',','\0'};
    char ida[]={id,'\0'};
    
    strcat(output,ida);
     for(i=0;i<NUM;i++){
      
       strcat(output,cma);
       strcat(output,soilTempVal[i]);
       
       strcat(output,cma);
       strcat(output,condVal[i]);
       
       strcat(output,cma);
       strcat(output,temI[i]);
       
       strcat(output,cma);
       strcat(output,convVal[i]);
        
     }
     
   
   for(len=0;output[len]!='\0';len++);  
   
   Utils.long2array(len, number); 
   
   for(i=0;number[i]!='\0';i++);
   
   char postS[102+i+len];
   postS[0]='\0';
   strcat(postS,ps1);
   strcat(postS,number);
   strcat(postS,ps2);
   strcat(postS,output);
   
    USB.println(postS);
      // 2. activates the 3G module:
    answer = _3G.ON();
    if ((answer == 1) || (answer == -3))
    {
        USB.println(F("3G module ready..."));

        // 3. sets pin code:
        USB.println(F("Setting PIN code..."));
        // **** must be substituted by the SIM code
        if (_3G.setPIN(PIN) == 1) 
        {
            USB.println(F("PIN code accepted"));
        }
        else
        {
            USB.println(F("PIN code incorrect"));
        }

        // 4. waits for connection to the network
        answer = _3G.check(180);    
        if (answer == 1)
        { 
            USB.println(F("3G module connected to the network..."));

            // 5. configures TCP connection
            USB.print(F("Setting connection..."));
            answer = _3G.configureTCP_UDP();
            if (answer == 1)
            {
                USB.println(F("Done"));

                USB.print(F("Opening TCP socket..."));
                // 6. opens a TCP socket
                answer = _3G.createSocket(TCP_CLIENT, IP, port);
                if (answer == 1)
                {
                    USB.println(F("Conected"));
                    if(_3G.getIP() == 1)
                    {
                        // if configuration is success shows the IP address
                        USB.print(F("IP address: ")); 
                        USB.println(_3G.buffer_3G);
                    }


                    //************************************************
                    //             Send a string of text
                    //************************************************

                    USB.println(F("Sending data..."));
                   
                    // 7. sends 'post_string'
                    answer = _3G.sendData(postS);
                    
                   
                    if (answer == 1) 
                    {
                        USB.println(F("Done"));
                    }
                    else if (answer == 0)
                    {
                        USB.println(F("Fail"));
                    }
                    else 
                    {
                        USB.print(F("Fail. Error code: "));
                        USB.println(answer, DEC);
                        USB.print(F("CME or IP error code: "));
                        USB.println(_3G.CME_CMS_code, DEC);
                    }


                    USB.print(F("Closing TCP socket..."));  
                    // 9. closes socket
                    if (_3G.closeSocket() == 1)
                    {
                        USB.println(F("Done"));
                    }
                    else
                    {
                        USB.println(F("Fail"));
                    }
                }
                else if (answer <= -4)
                {
                    USB.print(F("Connection failed. Error code: "));
                    USB.println(answer, DEC);
                    USB.print(F("CME error code: "));
                    USB.println(_3G.CME_CMS_code, DEC);
                }
                else 
                {
                    USB.print(F("Connection failed. Error code: "));
                    USB.println(answer, DEC);
                }           
            }
            else if (answer <= -10)
            {
                USB.print(F("Configuration failed. Error code: "));
                USB.println(answer, DEC);
                USB.print(F("CME error code: "));
                USB.println(_3G.CME_CMS_code, DEC);
            }
            else 
            {
                USB.print(F("Configuration failed. Error code: "));
                USB.println(answer, DEC);
            }
        }
        else
        {
            USB.println(F("3G module cannot connect to the network..."));
        }
    }
    else
    {
        // Problem with the communication with the 3G module
        USB.println(F("3G module not started"));
    }

    // 10. Powers off the 3G module
    _3G.OFF();
     
     
  }
  
  
  
  
  // Read the sensor 
  value = temperatureSensor.readTemperature();
  //USB.println(value);
  Utils.float2String(value, soilTempVal[mdVal], NDEC);
  //USB.println(soilTempVal[mdVal]);
  
  
  
  
  // Read the conductivity sensor 
  value = ConductivitySensor.readConductivity();
   //USB.println(value);
  Utils.float2String(value, condVal[mdVal], NDEC);
  // USB.println(condVal[mdVal]);
  
  value = ConductivitySensor.conductivityConversion(value);
  //USB.println(value);
  Utils.float2String(value, convVal[mdVal], NDEC);
 // USB.println(convVal[mdVal]);
  
  

  value = Utils.readTemperature();
 // USB.println(value);
  Utils.float2String(value, temI[mdVal], NDEC);
  // USB.println(temI[mdVal]);
  
  mdVal++;
  mdVal%=NUM;

  if(mdVal==1){
    PWR.deepSleep("00:00:14:16", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  }else{
    PWR.deepSleep("00:00:15:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  }
  
 
 

}

