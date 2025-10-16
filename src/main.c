#include <stdint.h>
#include <stdio.h>

// Simulate an LED toggle function (stub)
void toggle_led(void) {
    static int state = 0;
    state = !state;
    printf("LED is now %s\n", state ? "ON" : "OFF");
}

// Simulate delay (not suitable for real-time)
void delay(unsigned int count) {
    for (volatile unsigned int i = 0; i < count * 100000; ++i);
}

int main(void) {
    printf("Starting minimal firmware...\n");
    while (1) {
        toggle_led();
        delay(10);  // delay to simulate periodic action
    }
    return 0;  // Never reached
}
