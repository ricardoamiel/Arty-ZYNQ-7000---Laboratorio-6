/* Parte PS: el procesador ARM Cortex A9 controla LD0 y LD1 por AXI GPIO. */
#include "xparameters.h"
#include "xgpio.h"
#include "sleep.h"
#include "xil_printf.h"

#ifdef SDT
#define GPIO_ID XPAR_XGPIO_0_BASEADDR
#else
#define GPIO_ID XPAR_GPIO_0_DEVICE_ID
#endif

int main(void)
{
    XGpio leds;
    if (XGpio_Initialize(&leds, GPIO_ID) != XST_SUCCESS) {
        xil_printf("Error al iniciar AXI GPIO\r\n");
        return -1;
    }
    XGpio_SetDataDirection(&leds, 1, 0x0);   /* canal 1, todo salida */

    xil_printf("Hola mundo desde el ARM Cortex A9 de la Arty Z7-20\r\n");
    xil_printf("LD0 y LD1 controlados por el procesador\r\n");
    u32 n = 0;
    while (1) {
        /* LD0 se enciende y apaga cada 500 ms; LD1 cambia cada 2 ciclos */
        u32 patron = (n & 1) | (((n >> 1) & 1) << 1);
        XGpio_DiscreteWrite(&leds, 1, patron);
        xil_printf("ciclo %d  LD1 LD0 = %d%d\r\n", n, (patron >> 1) & 1, patron & 1);
        n++;
        usleep(500000);
    }
    return 0;
}
