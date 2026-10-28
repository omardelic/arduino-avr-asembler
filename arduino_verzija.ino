// Arduino verzija programa iz poglavlja 3
const int LED = 13;      // PB5
const int TASTER = 2;    // PD2
int prethodno = HIGH;    // taster je na pocetku otpusten

void setup() {
  pinMode(LED, OUTPUT);
  pinMode(TASTER, INPUT_PULLUP);
  Serial.begin(9600);
  Serial.println(F("Sistem spreman. Pritisnite taster."));
}

void loop() {
  int stanje = digitalRead(TASTER);
  if (stanje != prethodno) {
    delay(20);                                // debouncing
    if (digitalRead(TASTER) == stanje) {
      prethodno = stanje;
      if (stanje == LOW) {
        digitalWrite(LED, HIGH);
        Serial.println(F("Taster pritisnut - LED ukljucena"));
      } else {
        digitalWrite(LED, LOW);
        Serial.println(F("Taster otpusten - LED iskljucena"));
      }
    }
  }
}
