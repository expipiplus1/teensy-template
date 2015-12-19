#include <core_pins.h>

const int led_pin = 13;

int main(){
  pinMode(led_pin, OUTPUT);
  while(1){
    digitalWrite(led_pin, HIGH);
    delay(1000);
    digitalWrite(led_pin, LOW);
    delay(1000);
  }
}
