#define STM32F411xE
#include "stm32f4xx.h"
#include "uart.h"

void uart_init(void) {
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOBEN;
    RCC->APB2ENR |= RCC_APB2ENR_USART1EN;

    GPIOB->MODER   &= ~(0x3 << 12 | 0x3 << 14);
    GPIOB->MODER   |=  (0x2 << 12 | 0x2 << 14);
    GPIOB->AFR[0]  &= ~(0xF << 24 | 0xF << 28);
    GPIOB->AFR[0]  |=  (0x7 << 24 | 0x7 << 28);
    GPIOB->OSPEEDR |=  (0x3 << 12 | 0x3 << 14);
    GPIOB->PUPDR   &= ~(0x3 << 12 | 0x3 << 14);

    USART1->BRR = 868;

    USART1->CR1 = USART_CR1_UE | USART_CR1_TE | USART_CR1_RE;
}

void uart_putc(char c) {
    while (!(USART1->SR & USART_SR_TXE));
    USART1->DR = (uint8_t)c;
    if (c == '\n') {
        while (!(USART1->SR & USART_SR_TXE));
        USART1->DR = (uint8_t)'\r';
    }
}

void uart_puts(const char *s) {
    while (*s) uart_putc(*s++);
}

void uart_write(const char *buf, uint32_t len) {
    for (uint32_t i = 0; i < len; i++) uart_putc(buf[i]);
}

int uart_getc(void) {
    uint32_t sr = USART1->SR;
    if (!(sr & USART_SR_RXNE)) return -1;
    if (sr & (USART_SR_ORE | USART_SR_FE)) {
        (void)USART1->DR;
        return -1;
    }
    return (uint8_t)USART1->DR;
}
