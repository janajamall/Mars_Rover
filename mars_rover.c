unsigned int temp_raw = 0; 
unsigned int distance, time;
unsigned char triggerPin = 0, echoPin = 0; // ultrasonic vars
int temperature = 0;
int temp_celsius = 0;
unsigned int angle;     // for servo
unsigned char HL;  // high/low var for ccp mod   
unsigned char x;   // Testing 

void Delay_us(unsigned int us) {
    while (us--) {
        asm("NOP");
        asm("NOP");
        asm("NOP");
    }
}

void Delay_ms(unsigned int ms) {
    while (ms--) {
        Delay_us(1000);  // 1000 µs = 1 ms
    }
}


void ATD_init(void) {
    ADCON0 = 0x41; // Enable ADC Module and select bit 0 -- ADC Control Register
    ADCON1 = 0xCE; // only sets ra0 as digital the rest of ra pins are analog -- ADC Config register
}

void ATD_read(void) {
    ADCON0 |= 0x04;           // set bit 2 to 1 tos start conversion
    while (ADCON0 & 0x04);    // wait for conversion to complete
    temp_raw = ((ADRESH << 8) | ADRESL); // ADC is 10 bits so result is split with two 8 bit register, this is where we combine them
    temp_celsius = (temp_raw * 488) / 1000;    // Convert to Celsius (10mV per degree)
    if (temp_celsius > 10) {
        PORTB |= 0x04; // Turn on LEDs or fan if temp > 10C
    } else {
        PORTB &= ~0x04; // Turn off otherwise
    }
}
void interrupt(void){

       if(PIR1 & 0x04){          
             if(HL){                                // high
                    CCPR1H = angle >> 8;
                    CCPR1L = angle;
                    HL = 0;                      // next time low
                    CCP1CON = 0x09;              // compare mode, clear output on match
                    TMR1H = 0;
                    TMR1L = 0;
             }
             else{                                          //low
                    CCPR1H = (40000 - angle) >> 8;       // 40000 counts correspond to 20ms
                    CCPR1L = (40000 - angle);
                    CCP1CON = 0x08;             // compare mode, set output on match
                    HL = 1;                     //next time High
                    TMR1H = 0;
                    TMR1L = 0;
             }

             PIR1 = PIR1&0xFB;

       }
       if (INTCON & 0x02) {  
        if (!(PORTB & 0x01)) { // If rb0 is low
            PORTD |= 0x01;  // Turn on light 
        }
        INTCON &= ~0x02;  // Clear INTF
    }
     if (INTCON & 0x04) {  // Check INTF
        ATD_read(); // led stays on
        INTCON &= ~0x04;  // Clear INTF
    }
}

unsigned int calculate_distance(){
    unsigned int time = 0, distance;
    unsigned char triggerPin = 0, echoPin = 0; // Initialize vars
    triggerPin = 0x20;
    echoPin = 0x10;

    PORTC =PORTC |triggerPin; // Set trigger pin HIGH so send pulse
    Delay_us(10);        
    PORTC = PORTC & ~triggerPin; // Set trigger pin LOW so stop sending pulse

    while (!(PORTC & echoPin)); // Wait for Echo Start
    
    TMR1H = 0; 
    TMR1L = 0;
    T1CON = 0x01;  

    while (PORTC & echoPin);  // Wait for Echo End

    T1CON = 0x00; // Stop Timer

    time = (TMR1H << 8) | TMR1L; // Read Timer Value

    // Convert Time to Distance assuming speed of sound = 343 m/s
    distance = (time * 0.0343) /2; // this gives is the distance in cm

    return distance; 
}


void read_light() {
    if ((PORTC & 0b00000001)) {      // If RC0 is high
        PORTD |= 0b00000001;       // Set RD0 high (LED ON)
    } else {
        PORTD &= ~0b00000001;      // Clear RD0 (LED OFF)
    }
}

void pwm_init_dc() {
     TRISC.F1 = 0;            // Set RC2 as output
    CCP2CON = 0x0C;       // PWM mode for CCP2

   PR2 = 255;
 T2CON = 0b00000111;      // Timer2 ON, prescaler 1:1
}



void set_dc_motor_speed(int speed_percent) {
if (speed_percent > 0) {
        // Forward: IN1=1, IN2=0, IN3=1, IN4=0
        PORTB |= (1 << 7) | (1 << 5);     // Set F7 and F5
        PORTB &= ~((1 << 6) | (1 << 4));  // Clear F6 and F4
    } else if (speed_percent < 0) {
        // Reverse: IN1=0, IN2=1, IN3=0, IN4=1
        PORTB |= (1 << 6) | (1 << 4);     // Set F6 and F4
        PORTB &= ~((1 << 7) | (1 << 5));  // Clear F7 and F5
    } else {
        // Stop all
        PORTB &= ~((1 << 7) | (1 << 6) | (1 << 5) | (1 << 4));
    }


    if (speed_percent < 0) speed_percent = -speed_percent;
    if (speed_percent > 100) speed_percent = 100;

  CCPR2L=75;
}
void main(void) {
    ATD_init();
    pwm_init_dc();

    OPTION_REG.INTEDG = 0;         // Interrupt on falling edge 
    INTCON |= 0b11110000;          // Enable Global, Peripheral , and External interrupts

    TRISA = 0x01;                  // ra0 input - temp sensor
    TRISB = 0b00000001;            // rb0 input
    TRISC = 0b00010001;            // rc0 and rc4 as input
    TRISD = 0x00;                  // portd as output

    T1CON = 0x01;                  // Enable Timer1
    PORTB = 0x00;                  // Clear ports
    PORTC = 0x00;                  
    PORTD = 0x00;                  

    OPTION_REG = 0b00000011;      

    TMR1H = 0;
    TMR1L = 0;
    HL = 1;                        // Start with High
    CCP1CON = 0x08;                // Compare mode, set output on match
    PIE1 |= 0x04;                  // Enable CCP1 interrupt
    CCPR1H = 2000 >> 8;
    CCPR1L = 2000;

    x = 0;
    tmr0=0;

    while (1) {
        set_dc_motor_speed(5);  // Forward
        Delay_ms(1000);         // Wait 1 second
        set_dc_motor_speed(0);  // Stop
        Delay_ms(1000);


        if (calculate_distance() < 1) {
            PORTC |= 0b01000000;

        } else {
            PORTC &= ~0b01000000;;

        }

        DELAY_MS(1000);

        // Change angle every cycle to open/close arm
        if (!x)
            angle = 3500;
        else
            angle = 1500;
        x = !x;

        Delay_ms(1000); 
    }
}
