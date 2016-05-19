
#include <WaspSensorSmart_v20.h>

#include <Wasp3G.h>
#include <WaspFrame.h>

char ps1[]="POST /waspData HTTP/1.0\r\nContent-Length: \0";
char ps2[]="\r\nContent-Type: application/x-www-form-urlencoded\r\n\r\n\0";


char apn[] = "wlanp.com";
char login[] = "situ";
char password[] = "situ";


char IP[] = "137.43.130.184";
uint16_t port = 80;
char id='1';
char PIN[]="0000";
 
int8_t answer;


#define NUM 4
#define NCHR 20

char lumVal[NUM][NCHR];
char sonVal[NUM][NCHR];


int mdVal;

#define NDEC 10


void setup() {
  float value;
    // Turn on the USB and print a start message
  USB.ON();
  USB.println(F("start"));
  delay(100);

  // Turn on the sensor board
  SensorSmartv20.ON();
  
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
   SensorSmartv20.ON();
 USB.println(RTC.getTime());
  int len;
 float value;
 char number[20];
  
 if(mdVal==0){
       
  
    int i;
    char output[8+2*NUM*(NCHR+8)];
    output[0]='\0';
    char cma[]={',','\0'};
    char ida[]={id,'\0'};
    
    strcat(output,ida);
    for(i=0;i<NUM;i++){
      
       strcat(output,cma);
       strcat(output,lumVal[i]);
       
       strcat(output,cma);
       strcat(output,sonVal[i]);

        
    }
     
    //USB.println(output);
     
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
            USB.println(F("PIN code incorrect"));
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
  
  
  // Sonar Sensor reading
  // Turn on the sensor and wait for stabilization and response time
  SensorSmartv20.setSensorMode(SENS_ON, SENS_SMART_US_5V);
  delay(2000);
  
  // Read the ultrasound sensor 
  value = SensorSmartv20.readValue(SENS_SMART_US_5V, SENS_US_WRA1);
  Utils.float2String(value, sonVal[mdVal],NDEC);
  
  USB.println(sonVal[mdVal]);
  // Turn off the sensor
  SensorSmartv20.setSensorMode(SENS_OFF, SENS_SMART_US_5V);
  
  
  
  // Luminosity Sensor reading
  // Turn on the sensor and wait for stabilization and response time
  SensorSmartv20.setSensorMode(SENS_ON, SENS_SMART_LDR);
  delay(10);
  
  // Read the LDR sensor 
 
  value = SensorSmartv20.readValue(SENS_SMART_LDR);
  //USB.println(value);
  Utils.float2String(value, lumVal[mdVal], NDEC);
   USB.println(lumVal[mdVal]);
  //USB.println(lumVal[mdVal]);
  
  // Turn off the sensor
  SensorSmartv20.setSensorMode(SENS_OFF, SENS_SMART_LDR);
 
  
  
  mdVal++;
  mdVal%=NUM;
  
  if(mdVal==1){
    PWR.deepSleep("00:00:14:14", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  }else{
    PWR.deepSleep("00:00:14:58", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  }
 
 

}

