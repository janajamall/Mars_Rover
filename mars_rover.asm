
_ATD_init:

;mars_rover.c,12 :: 		void ATD_init(void) {
;mars_rover.c,13 :: 		ADCON0 = 0x41; // ADC ON, Channel 0 (AN0), Fosc/16
	MOVLW      65
	MOVWF      ADCON0+0
;mars_rover.c,14 :: 		ADCON1 = 0xCE; // RA0 analog, rest digital, Right justified
	MOVLW      206
	MOVWF      ADCON1+0
;mars_rover.c,15 :: 		}
L_end_ATD_init:
	RETURN
; end of _ATD_init

_ATD_read:

;mars_rover.c,17 :: 		void ATD_read(void) {
;mars_rover.c,18 :: 		ADCON0 |= 0x04;           // Start conversion
	BSF        ADCON0+0, 2
;mars_rover.c,19 :: 		while (ADCON0 & 0x04);    // Wait for conversion to complete
L_ATD_read0:
	BTFSS      ADCON0+0, 2
	GOTO       L_ATD_read1
	GOTO       L_ATD_read0
L_ATD_read1:
;mars_rover.c,20 :: 		temp_raw = ((ADRESH << 8) | ADRESL); // Combine high and low results
	MOVF       ADRESH+0, 0
	MOVWF      R0+1
	CLRF       R0+0
	MOVF       ADRESL+0, 0
	IORWF      R0+0, 1
	MOVLW      0
	IORWF      R0+1, 1
	MOVF       R0+0, 0
	MOVWF      _temp_raw+0
	MOVF       R0+1, 0
	MOVWF      _temp_raw+1
;mars_rover.c,21 :: 		temp_celsius = (temp_raw * 488) / 1000;    // Convert to °C (10mV per °C)
	MOVLW      232
	MOVWF      R4+0
	MOVLW      1
	MOVWF      R4+1
	CALL       _Mul_16X16_U+0
	MOVLW      232
	MOVWF      R4+0
	MOVLW      3
	MOVWF      R4+1
	CALL       _Div_16X16_U+0
	MOVF       R0+0, 0
	MOVWF      _temp_celsius+0
	MOVF       R0+1, 0
	MOVWF      _temp_celsius+1
;mars_rover.c,22 :: 		if (temp_celsius > 10) {
	MOVLW      128
	MOVWF      R2+0
	MOVLW      128
	XORWF      R0+1, 0
	SUBWF      R2+0, 0
	BTFSS      STATUS+0, 2
	GOTO       L__ATD_read39
	MOVF       R0+0, 0
	SUBLW      10
L__ATD_read39:
	BTFSC      STATUS+0, 0
	GOTO       L_ATD_read2
;mars_rover.c,23 :: 		PORTB |= 0x04; // Turn on LEDs or fan if temp > 10°C
	BSF        PORTB+0, 2
;mars_rover.c,24 :: 		} else {
	GOTO       L_ATD_read3
L_ATD_read2:
;mars_rover.c,25 :: 		PORTB &= ~0x04; // Turn off
	BCF        PORTB+0, 2
;mars_rover.c,26 :: 		}
L_ATD_read3:
;mars_rover.c,27 :: 		}
L_end_ATD_read:
	RETURN
; end of _ATD_read

_interrupt:
	MOVWF      R15+0
	SWAPF      STATUS+0, 0
	CLRF       STATUS+0
	MOVWF      ___saveSTATUS+0
	MOVF       PCLATH+0, 0
	MOVWF      ___savePCLATH+0
	CLRF       PCLATH+0

;mars_rover.c,28 :: 		void interrupt(void){
;mars_rover.c,30 :: 		if(PIR1 & 0x04){                                           // CCP1 interrupt
	BTFSS      PIR1+0, 2
	GOTO       L_interrupt4
;mars_rover.c,31 :: 		if(HL){                                // high
	MOVF       _HL+0, 0
	BTFSC      STATUS+0, 2
	GOTO       L_interrupt5
;mars_rover.c,32 :: 		CCPR1H = angle >> 8;
	MOVF       _angle+1, 0
	MOVWF      R0+0
	CLRF       R0+1
	MOVF       R0+0, 0
	MOVWF      CCPR1H+0
;mars_rover.c,33 :: 		CCPR1L = angle;
	MOVF       _angle+0, 0
	MOVWF      CCPR1L+0
;mars_rover.c,34 :: 		HL = 0;                      // next time low
	CLRF       _HL+0
;mars_rover.c,35 :: 		CCP1CON = 0x09;              // compare mode, clear output on match
	MOVLW      9
	MOVWF      CCP1CON+0
;mars_rover.c,36 :: 		TMR1H = 0;
	CLRF       TMR1H+0
;mars_rover.c,37 :: 		TMR1L = 0;
	CLRF       TMR1L+0
;mars_rover.c,38 :: 		}
	GOTO       L_interrupt6
L_interrupt5:
;mars_rover.c,40 :: 		CCPR1H = (40000 - angle) >> 8;       // 40000 counts correspond to 20ms
	MOVF       _angle+0, 0
	SUBLW      64
	MOVWF      R3+0
	MOVF       _angle+1, 0
	BTFSS      STATUS+0, 0
	ADDLW      1
	SUBLW      156
	MOVWF      R3+1
	MOVF       R3+1, 0
	MOVWF      R0+0
	CLRF       R0+1
	MOVF       R0+0, 0
	MOVWF      CCPR1H+0
;mars_rover.c,41 :: 		CCPR1L = (40000 - angle);
	MOVF       R3+0, 0
	MOVWF      CCPR1L+0
;mars_rover.c,42 :: 		CCP1CON = 0x08;             // compare mode, set output on match
	MOVLW      8
	MOVWF      CCP1CON+0
;mars_rover.c,43 :: 		HL = 1;                     //next time High
	MOVLW      1
	MOVWF      _HL+0
;mars_rover.c,44 :: 		TMR1H = 0;
	CLRF       TMR1H+0
;mars_rover.c,45 :: 		TMR1L = 0;
	CLRF       TMR1L+0
;mars_rover.c,46 :: 		}
L_interrupt6:
;mars_rover.c,48 :: 		PIR1 = PIR1&0xFB;
	MOVLW      251
	ANDWF      PIR1+0, 1
;mars_rover.c,50 :: 		}
L_interrupt4:
;mars_rover.c,51 :: 		if (INTCON & 0x02) {  // Check INTF
	BTFSS      INTCON+0, 1
	GOTO       L_interrupt7
;mars_rover.c,52 :: 		if (!(PORTB & 0x01)) { // If RB0 is LOW
	BTFSC      PORTB+0, 0
	GOTO       L_interrupt8
;mars_rover.c,53 :: 		PORTD |= 0x01;  // Turn on light at PORTB2
	BSF        PORTD+0, 0
;mars_rover.c,54 :: 		}
L_interrupt8:
;mars_rover.c,55 :: 		INTCON &= ~0x02;  // Clear INTF
	BCF        INTCON+0, 1
;mars_rover.c,56 :: 		}
L_interrupt7:
;mars_rover.c,57 :: 		if (INTCON & 0x04) {  // Check INTF
	BTFSS      INTCON+0, 2
	GOTO       L_interrupt9
;mars_rover.c,58 :: 		ATD_read();
	CALL       _ATD_read+0
;mars_rover.c,59 :: 		INTCON &= ~0x04;  // Clear INTF
	BCF        INTCON+0, 2
;mars_rover.c,60 :: 		}
L_interrupt9:
;mars_rover.c,61 :: 		}
L_end_interrupt:
L__interrupt41:
	MOVF       ___savePCLATH+0, 0
	MOVWF      PCLATH+0
	SWAPF      ___saveSTATUS+0, 0
	MOVWF      STATUS+0
	SWAPF      R15+0, 1
	SWAPF      R15+0, 0
	RETFIE
; end of _interrupt

_calculate_distance:

;mars_rover.c,63 :: 		unsigned int calculate_distance(){
;mars_rover.c,64 :: 		unsigned int time = 0, distance;
;mars_rover.c,65 :: 		unsigned char triggerPin = 0, echoPin = 0; // Initialize to prevent undefined behavior
	CLRF       calculate_distance_triggerPin_L0+0
	CLRF       calculate_distance_echoPin_L0+0
;mars_rover.c,66 :: 		triggerPin = 0x20;
	MOVLW      32
	MOVWF      calculate_distance_triggerPin_L0+0
;mars_rover.c,67 :: 		echoPin = 0x10;
	MOVLW      16
	MOVWF      calculate_distance_echoPin_L0+0
;mars_rover.c,70 :: 		PORTC =PORTC |triggerPin; // Set trigger pin HIGH
	BSF        PORTC+0, 5
;mars_rover.c,71 :: 		Delay_us(10);        // Wait for 10 microseconds
	MOVLW      6
	MOVWF      R13+0
L_calculate_distance10:
	DECFSZ     R13+0, 1
	GOTO       L_calculate_distance10
	NOP
;mars_rover.c,72 :: 		PORTC = PORTC & ~triggerPin; // Set trigger pin LOW
	COMF       calculate_distance_triggerPin_L0+0, 0
	MOVWF      R0+0
	MOVF       R0+0, 0
	ANDWF      PORTC+0, 1
;mars_rover.c,76 :: 		while (!(PORTC & echoPin)); // Wait until echo pin goes HIGH
L_calculate_distance11:
	MOVF       calculate_distance_echoPin_L0+0, 0
	ANDWF      PORTC+0, 0
	MOVWF      R0+0
	BTFSS      STATUS+0, 2
	GOTO       L_calculate_distance12
	GOTO       L_calculate_distance11
L_calculate_distance12:
;mars_rover.c,80 :: 		TMR1H = 0;
	CLRF       TMR1H+0
;mars_rover.c,81 :: 		TMR1L = 0;
	CLRF       TMR1L+0
;mars_rover.c,85 :: 		T1CON = 0x01;
	MOVLW      1
	MOVWF      T1CON+0
;mars_rover.c,89 :: 		while (PORTC & echoPin); // Wait until echo pin goes LOW
L_calculate_distance13:
	MOVF       calculate_distance_echoPin_L0+0, 0
	ANDWF      PORTC+0, 0
	MOVWF      R0+0
	BTFSC      STATUS+0, 2
	GOTO       L_calculate_distance14
	GOTO       L_calculate_distance13
L_calculate_distance14:
;mars_rover.c,93 :: 		T1CON = 0x00;
	CLRF       T1CON+0
;mars_rover.c,97 :: 		time = (TMR1H << 8) | TMR1L;
	MOVF       TMR1H+0, 0
	MOVWF      R0+1
	CLRF       R0+0
	MOVF       TMR1L+0, 0
	IORWF      R0+0, 1
	MOVLW      0
	IORWF      R0+1, 1
;mars_rover.c,101 :: 		distance = (time * 0.0343) /2; // Distance in cm
	CALL       _word2double+0
	MOVLW      40
	MOVWF      R4+0
	MOVLW      126
	MOVWF      R4+1
	MOVLW      12
	MOVWF      R4+2
	MOVLW      122
	MOVWF      R4+3
	CALL       _Mul_32x32_FP+0
	MOVLW      0
	MOVWF      R4+0
	MOVLW      0
	MOVWF      R4+1
	MOVLW      0
	MOVWF      R4+2
	MOVLW      128
	MOVWF      R4+3
	CALL       _Div_32x32_FP+0
	CALL       _double2word+0
;mars_rover.c,104 :: 		return distance; // Return Distance
;mars_rover.c,105 :: 		}
L_end_calculate_distance:
	RETURN
; end of _calculate_distance

_read_light:

;mars_rover.c,108 :: 		void read_light() {
;mars_rover.c,109 :: 		if ((PORTC & 0b00000001)) {      // If RC0 is high
	BTFSS      PORTC+0, 0
	GOTO       L_read_light15
;mars_rover.c,110 :: 		PORTD |= 0b00000001;       // Set RD0 high (LED ON)
	BSF        PORTD+0, 0
;mars_rover.c,111 :: 		} else {
	GOTO       L_read_light16
L_read_light15:
;mars_rover.c,112 :: 		PORTD &= ~0b00000001;      // Clear RD0 (LED OFF)
	BCF        PORTD+0, 0
;mars_rover.c,113 :: 		}
L_read_light16:
;mars_rover.c,114 :: 		}
L_end_read_light:
	RETURN
; end of _read_light

_pwm_init_dc:

;mars_rover.c,116 :: 		void pwm_init_dc() {
;mars_rover.c,117 :: 		TRISC.F1 = 0;            // Set RC2 as output
	BCF        TRISC+0, 1
;mars_rover.c,118 :: 		CCP2CON = 0x0C;       // PWM mode for CCP2
	MOVLW      12
	MOVWF      CCP2CON+0
;mars_rover.c,120 :: 		PR2 = 255;
	MOVLW      255
	MOVWF      PR2+0
;mars_rover.c,121 :: 		T2CON = 0b00000111;      // Timer2 ON, prescaler 1:1
	MOVLW      7
	MOVWF      T2CON+0
;mars_rover.c,122 :: 		}
L_end_pwm_init_dc:
	RETURN
; end of _pwm_init_dc

_set_dc_motor_speed:

;mars_rover.c,126 :: 		void set_dc_motor_speed(int speed_percent) {
;mars_rover.c,127 :: 		if (speed_percent > 0) {
	MOVLW      128
	MOVWF      R0+0
	MOVLW      128
	XORWF      FARG_set_dc_motor_speed_speed_percent+1, 0
	SUBWF      R0+0, 0
	BTFSS      STATUS+0, 2
	GOTO       L__set_dc_motor_speed46
	MOVF       FARG_set_dc_motor_speed_speed_percent+0, 0
	SUBLW      0
L__set_dc_motor_speed46:
	BTFSC      STATUS+0, 0
	GOTO       L_set_dc_motor_speed17
;mars_rover.c,129 :: 		PORTB |= (1 << 7) | (1 << 5);     // Set F7 and F5
	MOVLW      160
	IORWF      PORTB+0, 1
;mars_rover.c,130 :: 		PORTB &= ~((1 << 6) | (1 << 4));  // Clear F6 and F4
	MOVLW      175
	ANDWF      PORTB+0, 1
;mars_rover.c,131 :: 		} else if (speed_percent < 0) {
	GOTO       L_set_dc_motor_speed18
L_set_dc_motor_speed17:
	MOVLW      128
	XORWF      FARG_set_dc_motor_speed_speed_percent+1, 0
	MOVWF      R0+0
	MOVLW      128
	SUBWF      R0+0, 0
	BTFSS      STATUS+0, 2
	GOTO       L__set_dc_motor_speed47
	MOVLW      0
	SUBWF      FARG_set_dc_motor_speed_speed_percent+0, 0
L__set_dc_motor_speed47:
	BTFSC      STATUS+0, 0
	GOTO       L_set_dc_motor_speed19
;mars_rover.c,133 :: 		PORTB |= (1 << 6) | (1 << 4);     // Set F6 and F4
	MOVLW      80
	IORWF      PORTB+0, 1
;mars_rover.c,134 :: 		PORTB &= ~((1 << 7) | (1 << 5));  // Clear F7 and F5
	MOVLW      95
	ANDWF      PORTB+0, 1
;mars_rover.c,135 :: 		} else {
	GOTO       L_set_dc_motor_speed20
L_set_dc_motor_speed19:
;mars_rover.c,137 :: 		PORTB &= ~((1 << 7) | (1 << 6) | (1 << 5) | (1 << 4));
	MOVLW      15
	ANDWF      PORTB+0, 1
;mars_rover.c,138 :: 		}
L_set_dc_motor_speed20:
L_set_dc_motor_speed18:
;mars_rover.c,141 :: 		if (speed_percent < 0) speed_percent = -speed_percent;
	MOVLW      128
	XORWF      FARG_set_dc_motor_speed_speed_percent+1, 0
	MOVWF      R0+0
	MOVLW      128
	SUBWF      R0+0, 0
	BTFSS      STATUS+0, 2
	GOTO       L__set_dc_motor_speed48
	MOVLW      0
	SUBWF      FARG_set_dc_motor_speed_speed_percent+0, 0
L__set_dc_motor_speed48:
	BTFSC      STATUS+0, 0
	GOTO       L_set_dc_motor_speed21
	MOVF       FARG_set_dc_motor_speed_speed_percent+0, 0
	SUBLW      0
	MOVWF      FARG_set_dc_motor_speed_speed_percent+0
	MOVF       FARG_set_dc_motor_speed_speed_percent+1, 0
	BTFSS      STATUS+0, 0
	ADDLW      1
	CLRF       FARG_set_dc_motor_speed_speed_percent+1
	SUBWF      FARG_set_dc_motor_speed_speed_percent+1, 1
L_set_dc_motor_speed21:
;mars_rover.c,142 :: 		if (speed_percent > 100) speed_percent = 100;
	MOVLW      128
	MOVWF      R0+0
	MOVLW      128
	XORWF      FARG_set_dc_motor_speed_speed_percent+1, 0
	SUBWF      R0+0, 0
	BTFSS      STATUS+0, 2
	GOTO       L__set_dc_motor_speed49
	MOVF       FARG_set_dc_motor_speed_speed_percent+0, 0
	SUBLW      100
L__set_dc_motor_speed49:
	BTFSC      STATUS+0, 0
	GOTO       L_set_dc_motor_speed22
	MOVLW      100
	MOVWF      FARG_set_dc_motor_speed_speed_percent+0
	MOVLW      0
	MOVWF      FARG_set_dc_motor_speed_speed_percent+1
L_set_dc_motor_speed22:
;mars_rover.c,144 :: 		CCPR2L=75;
	MOVLW      75
	MOVWF      CCPR2L+0
;mars_rover.c,145 :: 		}
L_end_set_dc_motor_speed:
	RETURN
; end of _set_dc_motor_speed

_main:

;mars_rover.c,146 :: 		void main(void) {
;mars_rover.c,147 :: 		ATD_init();
	CALL       _ATD_init+0
;mars_rover.c,148 :: 		pwm_init_dc();
	CALL       _pwm_init_dc+0
;mars_rover.c,151 :: 		OPTION_REG.INTEDG = 0;         // Interrupt on falling edge (1 ? 0) for RB0
	BCF        OPTION_REG+0, 6
;mars_rover.c,152 :: 		INTCON |= 0b11110000;          // Enable Global (GIE), Peripheral (PEIE), and External (INTE) interrupts
	MOVLW      240
	IORWF      INTCON+0, 1
;mars_rover.c,155 :: 		TRISA = 0x01;                  // RA0 input (for analog), rest output
	MOVLW      1
	MOVWF      TRISA+0
;mars_rover.c,156 :: 		TRISB = 0b00000001;            // RB0 as input (INT), others as output
	MOVLW      1
	MOVWF      TRISB+0
;mars_rover.c,157 :: 		TRISC = 0b00010001;            // RC0 and RC4 as input, others output
	MOVLW      17
	MOVWF      TRISC+0
;mars_rover.c,158 :: 		TRISD = 0x00;                  // PORTD as output
	CLRF       TRISD+0
;mars_rover.c,161 :: 		T1CON = 0x01;                  // Enable Timer1
	MOVLW      1
	MOVWF      T1CON+0
;mars_rover.c,162 :: 		PORTB = 0x00;                  // Clear PORTB
	CLRF       PORTB+0
;mars_rover.c,163 :: 		PORTC = 0x00;                  // Clear PORTC
	CLRF       PORTC+0
;mars_rover.c,164 :: 		PORTD = 0x00;                  // Clear PORTD
	CLRF       PORTD+0
;mars_rover.c,167 :: 		OPTION_REG = 0b00000011;       // PSA=0, Prescaler 1:64, T0CS=0 (internal clock)
	MOVLW      3
	MOVWF      OPTION_REG+0
;mars_rover.c,170 :: 		TMR1H = 0;
	CLRF       TMR1H+0
;mars_rover.c,171 :: 		TMR1L = 0;
	CLRF       TMR1L+0
;mars_rover.c,172 :: 		HL = 1;                        // Start with High
	MOVLW      1
	MOVWF      _HL+0
;mars_rover.c,173 :: 		CCP1CON = 0x08;                // Compare mode, set output on match
	MOVLW      8
	MOVWF      CCP1CON+0
;mars_rover.c,174 :: 		PIE1 |= 0x04;                  // Enable CCP1 interrupt
	BSF        PIE1+0, 2
;mars_rover.c,175 :: 		CCPR1H = 2000 >> 8;
	MOVLW      7
	MOVWF      CCPR1H+0
;mars_rover.c,176 :: 		CCPR1L = 2000;
	MOVLW      208
	MOVWF      CCPR1L+0
;mars_rover.c,179 :: 		x = 0;
	CLRF       _x+0
;mars_rover.c,180 :: 		tmr0=0;
	CLRF       TMR0+0
;mars_rover.c,182 :: 		while (1) {
L_main23:
;mars_rover.c,183 :: 		set_dc_motor_speed(5);  // Forward
	MOVLW      5
	MOVWF      FARG_set_dc_motor_speed_speed_percent+0
	MOVLW      0
	MOVWF      FARG_set_dc_motor_speed_speed_percent+1
	CALL       _set_dc_motor_speed+0
;mars_rover.c,184 :: 		Delay_ms(1000);         // Wait 1 second
	MOVLW      11
	MOVWF      R11+0
	MOVLW      38
	MOVWF      R12+0
	MOVLW      93
	MOVWF      R13+0
L_main25:
	DECFSZ     R13+0, 1
	GOTO       L_main25
	DECFSZ     R12+0, 1
	GOTO       L_main25
	DECFSZ     R11+0, 1
	GOTO       L_main25
	NOP
	NOP
;mars_rover.c,185 :: 		set_dc_motor_speed(0);  // Stop
	CLRF       FARG_set_dc_motor_speed_speed_percent+0
	CLRF       FARG_set_dc_motor_speed_speed_percent+1
	CALL       _set_dc_motor_speed+0
;mars_rover.c,186 :: 		Delay_ms(1000);
	MOVLW      11
	MOVWF      R11+0
	MOVLW      38
	MOVWF      R12+0
	MOVLW      93
	MOVWF      R13+0
L_main26:
	DECFSZ     R13+0, 1
	GOTO       L_main26
	DECFSZ     R12+0, 1
	GOTO       L_main26
	DECFSZ     R11+0, 1
	GOTO       L_main26
	NOP
	NOP
;mars_rover.c,190 :: 		if (calculate_distance() < 10) {
	CALL       _calculate_distance+0
	MOVLW      0
	SUBWF      R0+1, 0
	BTFSS      STATUS+0, 2
	GOTO       L__main51
	MOVLW      10
	SUBWF      R0+0, 0
L__main51:
	BTFSC      STATUS+0, 0
	GOTO       L_main27
;mars_rover.c,191 :: 		PORTC.F6 = 1;
	BSF        PORTC+0, 6
;mars_rover.c,193 :: 		} else {
	GOTO       L_main28
L_main27:
;mars_rover.c,194 :: 		PORTC.F6 = 0;
	BCF        PORTC+0, 6
;mars_rover.c,196 :: 		}
L_main28:
;mars_rover.c,198 :: 		DELAY_MS(1000);
	MOVLW      11
	MOVWF      R11+0
	MOVLW      38
	MOVWF      R12+0
	MOVLW      93
	MOVWF      R13+0
L_main29:
	DECFSZ     R13+0, 1
	GOTO       L_main29
	DECFSZ     R12+0, 1
	GOTO       L_main29
	DECFSZ     R11+0, 1
	GOTO       L_main29
	NOP
	NOP
;mars_rover.c,200 :: 		PIE1 &= ~0x04;           // Disable CCP1 interrupt
	BCF        PIE1+0, 2
;mars_rover.c,201 :: 		T1CON = 0x00;            // Disable Timer1
	CLRF       T1CON+0
;mars_rover.c,202 :: 		Delay_ms(10);            // Small delay for safety
	MOVLW      26
	MOVWF      R12+0
	MOVLW      248
	MOVWF      R13+0
L_main30:
	DECFSZ     R13+0, 1
	GOTO       L_main30
	DECFSZ     R12+0, 1
	GOTO       L_main30
	NOP
;mars_rover.c,204 :: 		distance = calculate_distance();
	CALL       _calculate_distance+0
	MOVF       R0+0, 0
	MOVWF      _distance+0
	MOVF       R0+1, 0
	MOVWF      _distance+1
;mars_rover.c,205 :: 		if (distance < 10) {
	MOVLW      0
	SUBWF      R0+1, 0
	BTFSS      STATUS+0, 2
	GOTO       L__main52
	MOVLW      10
	SUBWF      R0+0, 0
L__main52:
	BTFSC      STATUS+0, 0
	GOTO       L_main31
;mars_rover.c,206 :: 		PORTC.F6 = 1; // Close object
	BSF        PORTC+0, 6
;mars_rover.c,207 :: 		} else {
	GOTO       L_main32
L_main31:
;mars_rover.c,208 :: 		PORTC.F6 = 0;
	BCF        PORTC+0, 6
;mars_rover.c,209 :: 		}
L_main32:
;mars_rover.c,211 :: 		Delay_ms(100);           // Let things settle
	MOVLW      2
	MOVWF      R11+0
	MOVLW      4
	MOVWF      R12+0
	MOVLW      186
	MOVWF      R13+0
L_main33:
	DECFSZ     R13+0, 1
	GOTO       L_main33
	DECFSZ     R12+0, 1
	GOTO       L_main33
	DECFSZ     R11+0, 1
	GOTO       L_main33
	NOP
;mars_rover.c,215 :: 		TMR1H = 0;
	CLRF       TMR1H+0
;mars_rover.c,216 :: 		TMR1L = 0;
	CLRF       TMR1L+0
;mars_rover.c,217 :: 		PIE1 |= 0x04;            // Re-enable CCP1 interrupt
	BSF        PIE1+0, 2
;mars_rover.c,218 :: 		T1CON = 0x01;            // Restart Timer1
	MOVLW      1
	MOVWF      T1CON+0
;mars_rover.c,221 :: 		if (!x)
	MOVF       _x+0, 0
	BTFSS      STATUS+0, 2
	GOTO       L_main34
;mars_rover.c,222 :: 		angle = 3500;
	MOVLW      172
	MOVWF      _angle+0
	MOVLW      13
	MOVWF      _angle+1
	GOTO       L_main35
L_main34:
;mars_rover.c,224 :: 		angle = 1500;
	MOVLW      220
	MOVWF      _angle+0
	MOVLW      5
	MOVWF      _angle+1
L_main35:
;mars_rover.c,225 :: 		x = !x;
	MOVF       _x+0, 0
	MOVLW      1
	BTFSS      STATUS+0, 2
	MOVLW      0
	MOVWF      _x+0
;mars_rover.c,227 :: 		Delay_ms(1000); // Wait before next cycle
	MOVLW      11
	MOVWF      R11+0
	MOVLW      38
	MOVWF      R12+0
	MOVLW      93
	MOVWF      R13+0
L_main36:
	DECFSZ     R13+0, 1
	GOTO       L_main36
	DECFSZ     R12+0, 1
	GOTO       L_main36
	DECFSZ     R11+0, 1
	GOTO       L_main36
	NOP
	NOP
;mars_rover.c,228 :: 		}
	GOTO       L_main23
;mars_rover.c,229 :: 		}
L_end_main:
	GOTO       $+0
; end of _main
