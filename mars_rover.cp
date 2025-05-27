#line 1 "C:/Users/20210371/Documents/mars_rover.c"
unsigned int temp_raw = 0;
unsigned int distance, time;
unsigned char triggerPin = 0, echoPin = 0;
int temperature = 0;
int blue=0;
int temp_celsius = 0;

unsigned int angle;
unsigned char HL;
unsigned char x;

void ATD_init(void) {
 ADCON0 = 0x41;
 ADCON1 = 0xCE;
}

void ATD_read(void) {
 ADCON0 |= 0x04;
 while (ADCON0 & 0x04);
 temp_raw = ((ADRESH << 8) | ADRESL);
 temp_celsius = (temp_raw * 488) / 1000;
 if (temp_celsius > 10) {
 PORTB |= 0x04;
 } else {
 PORTB &= ~0x04;
 }
}
void interrupt(void){

 if(PIR1 & 0x04){
 if(HL){
 CCPR1H = angle >> 8;
 CCPR1L = angle;
 HL = 0;
 CCP1CON = 0x09;
 TMR1H = 0;
 TMR1L = 0;
 }
 else{
 CCPR1H = (40000 - angle) >> 8;
 CCPR1L = (40000 - angle);
 CCP1CON = 0x08;
 HL = 1;
 TMR1H = 0;
 TMR1L = 0;
 }

 PIR1 = PIR1&0xFB;

 }
 if (INTCON & 0x02) {
 if (!(PORTB & 0x01)) {
 PORTD |= 0x01;
 }
 INTCON &= ~0x02;
 }
 if (INTCON & 0x04) {
 ATD_read();
 INTCON &= ~0x04;
 }
}

unsigned int calculate_distance(){
 unsigned int time = 0, distance;
 unsigned char triggerPin = 0, echoPin = 0;
 triggerPin = 0x20;
 echoPin = 0x10;


 PORTC =PORTC |triggerPin;
 Delay_us(10);
 PORTC = PORTC & ~triggerPin;



 while (!(PORTC & echoPin));



 TMR1H = 0;
 TMR1L = 0;



 T1CON = 0x01;



 while (PORTC & echoPin);



 T1CON = 0x00;



 time = (TMR1H << 8) | TMR1L;



 distance = (time * 0.0343) /2;


 return distance;
}


void read_light() {
 if ((PORTC & 0b00000001)) {
 PORTD |= 0b00000001;
 } else {
 PORTD &= ~0b00000001;
 }
}

void pwm_init_dc() {
 TRISC.F1 = 0;
 CCP2CON = 0x0C;

 PR2 = 255;
 T2CON = 0b00000111;
}



void set_dc_motor_speed(int speed_percent) {
if (speed_percent > 0) {

 PORTB |= (1 << 7) | (1 << 5);
 PORTB &= ~((1 << 6) | (1 << 4));
 } else if (speed_percent < 0) {

 PORTB |= (1 << 6) | (1 << 4);
 PORTB &= ~((1 << 7) | (1 << 5));
 } else {

 PORTB &= ~((1 << 7) | (1 << 6) | (1 << 5) | (1 << 4));
 }


 if (speed_percent < 0) speed_percent = -speed_percent;
 if (speed_percent > 100) speed_percent = 100;

 CCPR2L=75;
}
void main(void) {
 ATD_init();
 pwm_init_dc();


 OPTION_REG.INTEDG = 0;
 INTCON |= 0b11110000;


 TRISA = 0x01;
 TRISB = 0b00000001;
 TRISC = 0b00010001;
 TRISD = 0x00;


 T1CON = 0x01;
 PORTB = 0x00;
 PORTC = 0x00;
 PORTD = 0x00;


 OPTION_REG = 0b00000011;


 TMR1H = 0;
 TMR1L = 0;
 HL = 1;
 CCP1CON = 0x08;
 PIE1 |= 0x04;
 CCPR1H = 2000 >> 8;
 CCPR1L = 2000;


 x = 0;
 tmr0=0;

 while (1) {
 set_dc_motor_speed(5);
 Delay_ms(1000);
 set_dc_motor_speed(0);
 Delay_ms(1000);



 if (calculate_distance() < 10) {
 PORTC.F6 = 1;

 } else {
 PORTC.F6 = 0;

 }

 DELAY_MS(1000);

 PIE1 &= ~0x04;
 T1CON = 0x00;
 Delay_ms(10);

 distance = calculate_distance();
 if (distance < 10) {
 PORTC.F6 = 1;
 } else {
 PORTC.F6 = 0;
 }

 Delay_ms(100);



 TMR1H = 0;
 TMR1L = 0;
 PIE1 |= 0x04;
 T1CON = 0x01;


 if (!x)
 angle = 3500;
 else
 angle = 1500;
 x = !x;

 Delay_ms(1000);
 }
}
