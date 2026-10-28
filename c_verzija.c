// C verzija programa iz poglavlja 3 (direktan pristup registrima, avr-libc)
#define F_CPU 16000000UL
#include <avr/io.h>
#include <avr/pgmspace.h>
#include <util/delay.h>

#define UBRR_VR 103

static void usart_init(void) {
    UBRR0H = (uint8_t)(UBRR_VR >> 8);
    UBRR0L = (uint8_t)UBRR_VR;
    UCSR0B = (1 << TXEN0);
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}
static void posalji_znak(char c) {
    while (!(UCSR0A & (1 << UDRE0)));
    UDR0 = c;
}
static void posalji_tekst(const char *s) {
    char c;
    while ((c = pgm_read_byte(s++)) != 0) posalji_znak(c);
}
int main(void) {
    DDRB |= (1 << PB5);  PORTB &= ~(1 << PB5);
    DDRD &= ~(1 << PD2); PORTD |= (1 << PD2);
    usart_init();
    posalji_tekst(PSTR("Sistem spreman. Pritisnite taster.\r\n"));
    uint8_t prethodno = 1;
    for (;;) {
        uint8_t stanje = (PIND & (1 << PD2)) ? 1 : 0;
        if (stanje != prethodno) {
            _delay_ms(20);
            if (((PIND & (1 << PD2)) ? 1 : 0) == stanje) {
                prethodno = stanje;
                if (stanje == 0) {
                    PORTB |= (1 << PB5);
                    posalji_tekst(PSTR("Taster pritisnut - LED ukljucena\r\n"));
                } else {
                    PORTB &= ~(1 << PB5);
                    posalji_tekst(PSTR("Taster otpusten - LED iskljucena\r\n"));
                }
            }
        }
    }
}
