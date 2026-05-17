#define STM32F411xE
#include "stm32f4xx.h"

#define LED_PIN 13

static void delay(volatile uint32_t count) {
    while (count--) __NOP();
}

int main(void) {
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOCEN;

    GPIOC->MODER &= ~(3 << (LED_PIN * 2));
    GPIOC->MODER |=  (1 << (LED_PIN * 2));

    GPIOC->OTYPER &= ~(1 << LED_PIN);

    GPIOC->OSPEEDR &= ~(3 << (LED_PIN * 2));
    GPIOC->OSPEEDR |=  (2 << (LED_PIN * 2));

    GPIOC->PUPDR  &= ~(3 << (LED_PIN * 2));

    for (;;) {
        GPIOC->BSRR = (1 << LED_PIN) << 16;
        delay(5000000);
        GPIOC->BSRR = (1 << LED_PIN);
        delay(5000000);
    }

    return 0;
}
