; ============================================================
;  program.S - Upravljanje hardverom pomocu AVR asemblera
;  Platforma: Arduino Uno (ATmega328P, 16 MHz)
;  LED dioda: PB5 (digitalni pin 13)
;  Taster:    PD2 (digitalni pin 2), interni pull-up otpornik
;  USART0:    9600 bit/s, 8 bita podataka, bez pariteta, 1 stop bit
; ============================================================

#define __SFR_OFFSET 0   /* registri se adresiraju kao I/O adrese */
#include <avr/io.h>

#define LED_PIN   5   /* PB5 */
#define TAST_PIN  2   /* PD2 */
#define UBRR_VR   103   /* 16 000 000 / (16 * 9600) - 1 = 103 */

        .global main

; ------------------------------------------------------------
;  Tekstualne poruke u flash memoriji (zavrsavaju nulom)
; ------------------------------------------------------------
        .section .progmem.data
poruka_start:
        .asciz  "Sistem spreman. Pritisnite taster.\r\n"
poruka_pritisnut:
        .asciz  "Taster pritisnut - LED ukljucena\r\n"
poruka_otpusten:
        .asciz  "Taster otpusten - LED iskljucena\r\n"

        .text
; ------------------------------------------------------------
;  Glavni program
; ------------------------------------------------------------
main:
        ; --- Konfiguracija pinova ---
        sbi     DDRB, LED_PIN       ; PB5 je izlaz (LED)
        cbi     PORTB, LED_PIN      ; LED je na pocetku iskljucena
        cbi     DDRD, TAST_PIN      ; PD2 je ulaz (taster)
        sbi     PORTD, TAST_PIN     ; ukljucen interni pull-up na PD2

        ; --- Konfiguracija USART0 ---
        rcall   usart_init

        ; --- Pocetna poruka ---
        ldi     ZL, lo8(poruka_start)
        ldi     ZH, hi8(poruka_start)
        rcall   posalji_tekst

        ldi     r20, 1              ; r20 = prethodno stanje (1 = otpusten)

glavna_petlja:
        in      r16, PIND           ; procitaj stanje porta D
        andi    r16, (1 << TAST_PIN); izdvoji bit PD2
        breq    taster_dolje        ; bit = 0 -> taster je pritisnut

taster_gore:                        ; taster je otpusten
        cpi     r20, 0              ; da li je prije bio pritisnut?
        brne    glavna_petlja       ; nije - nema promjene stanja
        rcall   pauza_20ms          ; debouncing
        sbic    PIND, TAST_PIN      ; ako je i dalje otpusten...
        rjmp    potvrdi_otpustanje  ; ...potvrdi promjenu
        rjmp    glavna_petlja
potvrdi_otpustanje:
        cbi     PORTB, LED_PIN      ; iskljuci LED
        ldi     r20, 1
        ldi     ZL, lo8(poruka_otpusten)
        ldi     ZH, hi8(poruka_otpusten)
        rcall   posalji_tekst
        rjmp    glavna_petlja

taster_dolje:                       ; taster je pritisnut
        cpi     r20, 1              ; da li je prije bio otpusten?
        brne    glavna_petlja       ; nije - nema promjene stanja
        rcall   pauza_20ms          ; debouncing
        sbis    PIND, TAST_PIN      ; ako je i dalje pritisnut...
        rjmp    potvrdi_pritisak    ; ...potvrdi promjenu
        rjmp    glavna_petlja
potvrdi_pritisak:
        sbi     PORTB, LED_PIN      ; ukljuci LED
        ldi     r20, 0
        ldi     ZL, lo8(poruka_pritisnut)
        ldi     ZH, hi8(poruka_pritisnut)
        rcall   posalji_tekst
        rjmp    glavna_petlja

; ------------------------------------------------------------
;  usart_init - 9600 bit/s, format 8N1, ukljucen predajnik
; ------------------------------------------------------------
usart_init:
        ldi     r16, hi8(UBRR_VR)
        sts     UBRR0H, r16
        ldi     r16, lo8(UBRR_VR)
        sts     UBRR0L, r16
        ldi     r16, (1 << TXEN0)               ; ukljuci predajnik
        sts     UCSR0B, r16
        ldi     r16, (1 << UCSZ01) | (1 << UCSZ00) ; 8 bita podataka
        sts     UCSR0C, r16
        ret

; ------------------------------------------------------------
;  posalji_znak - salje znak iz r16 preko USART0
; ------------------------------------------------------------
posalji_znak:
        lds     r17, UCSR0A
        sbrs    r17, UDRE0          ; cekaj prazan registar podataka
        rjmp    posalji_znak
        sts     UDR0, r16           ; upisi znak -> pocinje slanje
        ret

; ------------------------------------------------------------
;  posalji_tekst - salje niz iz flash memorije na koji
;  pokazuje Z, sve do nultog bajta
; ------------------------------------------------------------
posalji_tekst:
        lpm     r16, Z+             ; procitaj bajt iz flasha, Z = Z + 1
        cpi     r16, 0              ; kraj niza?
        breq    kraj_teksta
        rcall   posalji_znak
        rjmp    posalji_tekst
kraj_teksta:
        ret

; ------------------------------------------------------------
;  pauza_20ms - softverska pauza od priblizno 20 ms pri 16 MHz
;  (unutrasnja petlja: 4 takta x 4000 = 16 000 taktova = 1 ms)
; ------------------------------------------------------------
pauza_20ms:
        ldi     r18, 20             ; 20 x 1 ms
pauza_ms:
        ldi     r24, lo8(4000)
        ldi     r25, hi8(4000)
pauza_petlja:
        sbiw    r24, 1              ; 2 takta
        brne    pauza_petlja        ; 2 takta (kad skace)
        dec     r18
        brne    pauza_ms
        ret
