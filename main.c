#define STM32F411xE
#include "stm32f4xx.h"
#include "delay.h"
#include "uart.h"

#define LED_PIN 13

int main(void) {
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOCEN;

    GPIOC->MODER   &= ~(3 << (LED_PIN * 2));
    GPIOC->MODER   |=  (1 << (LED_PIN * 2));
    GPIOC->OTYPER  &= ~(1 << LED_PIN);
    GPIOC->OSPEEDR &= ~(3 << (LED_PIN * 2));
    GPIOC->OSPEEDR |=  (2 << (LED_PIN * 2));
    GPIOC->PUPDR   &= ~(3 << (LED_PIN * 2));

    for (int i = 0; i < 5; i++) {
        GPIOC->BSRR = (1 << LED_PIN) << 16;
        delay_ms(80);
        GPIOC->BSRR = (1 << LED_PIN);
        delay_ms(80);
    }

    uart_init();
    uart_puts("hello world\n");

    for (;;) {
        GPIOC->BSRR = (1 << LED_PIN) << 16;
        delay_ms(500);
        GPIOC->BSRR = (1 << LED_PIN);
        delay_ms(500);
    }

    return 0;
}
