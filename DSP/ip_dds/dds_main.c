#include "xparameters.h"
#include "xaxis_switch.h"
#include "xaxidma.h"

#include "sleep.h"
#include <stdint.h>

#define MEM_BASE_ADDR		0x10000000

#define TX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00100000)
#define RX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00300000)
#define POLL_TIMEOUT_COUNTER    1000000U

#define NUM_SAMPLES         2048

XAxis_Switch AxisSwitch_0;	/**< Slave to Master MUX */
XAxis_Switch AxisSwitch_1;	/**< Master to Slave MUX */
XAxiDma AxiDma; /**< AXI DMA Instance */

void axi_switches_cnfg(XAxis_Switch AxisSwitch, u8 MiIndex, u8 SiIndex);
void axi_switches_stop(XAxis_Switch AxisSwitch, u8 MiIndex, u8 SiIndex);

void init_tx_buffer_lut  (u8 *TxBufferPtr, int Nlen);
void init_tx_buffer_phase(u8 *TxBufferPtr, int Nlen);


int main()
{
    xil_printf("[INFO] Start Application\r\n");

    xil_printf("[INFO] AXI Switchers Configuration \r\n");


    XAxis_Switch_Config *Config;
	int Status;
    xil_printf("[INFO] Configuration of the Axi Switch 0 \r\n");
    Config = XAxisScr_LookupConfig(XPAR_AXIS_SWITCH_0_BASEADDR);
    if (NULL == Config) {
        xil_printf("[ERROR] XAxisScr_LookupConfig Axi Switch 0 Error\r\n");
		return XST_FAILURE;
	}

	Status = XAxisScr_CfgInitialize(&AxisSwitch_0, Config,
						Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		xil_printf("[ERROR] Axi Switch 0 AXI4-Stream initialization failed.\r\n");
		return XST_FAILURE;
	}

    xil_printf("[INFO] Configuration of the Axi Switch 1 \r\n");
    Config = XAxisScr_LookupConfig(XPAR_AXIS_SWITCH_1_BASEADDR);
    if (NULL == Config) {
        xil_printf("[ERROR] XAxisScr_LookupConfig Axi Switch 1 Error\r\n");
		return XST_FAILURE;
	}

	Status = XAxisScr_CfgInitialize(&AxisSwitch_1, Config,
						Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		xil_printf("[ERROR] Axi Switch 1 AXI4-Stream initialization failed.\r\n");
		return XST_FAILURE;
	}

    xil_printf("[INFO] AXI DMA Configuration \r\n");

    u8 *TxBufferPtr;
	u8 *RxBufferPtr;
	int TimeOut = POLL_TIMEOUT_COUNTER;

	TxBufferPtr = (u8 *)TX_BUFFER_BASE ;
	RxBufferPtr = (u8 *)RX_BUFFER_BASE;
    xil_printf("[INFO] TX buffer for Chirp Signal \r\n");
    init_tx_buffer_phase(TxBufferPtr, NUM_SAMPLES + 32);

    Xil_DCacheFlushRange((UINTPTR)TxBufferPtr, 2*(NUM_SAMPLES + 32));
	Xil_DCacheFlushRange((UINTPTR)RxBufferPtr, 4*NUM_SAMPLES);
    
    XAxiDma_Config *CfgPtr;

    CfgPtr = XAxiDma_LookupConfig(XPAR_XAXIDMA_0_BASEADDR);
	if (!CfgPtr) {
		xil_printf("No config found for %d\r\n", XPAR_XAXIDMA_0_BASEADDR);
		return XST_FAILURE;
	}

	Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Initialization failed %d\r\n", Status);
		return XST_FAILURE;
	}

	if (XAxiDma_HasSg(&AxiDma)) {
		xil_printf("Device configured as SG mode \r\n");
		return XST_FAILURE;
	}

	/* Disable interrupts, we use polling mode
	 */
	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,  XAXIDMA_DEVICE_TO_DMA);
	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,  XAXIDMA_DMA_TO_DEVICE);

    xil_printf("\n[INFO] DDS compiler Phase Generator Start \r\n");

    axi_switches_cnfg(AxisSwitch_0, 0, 0); // DDS Input
    axi_switches_cnfg(AxisSwitch_1, 0, 0); // DDS Output


    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) RxBufferPtr,	4*NUM_SAMPLES, XAXIDMA_DEVICE_TO_DMA);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) TxBufferPtr, 2*(NUM_SAMPLES + 32), XAXIDMA_DMA_TO_DEVICE);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /*Wait till tranfer is done or 1usec * 10^6 iterations of timeout occurs*/
    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA) && XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) {
        if (TimeOut == 0) {
            xil_printf("\n\n[WARNING] AXIDMA TIMEOUT \r\n\n");
            break;
        }
        TimeOut--;
        usleep(1U);
    }
    TimeOut = POLL_TIMEOUT_COUNTER;
    xil_printf("[INFO] DDS compiler Phase Generator Done \r\n");
    xil_printf("\n[INFO] DDS compiler LUT start\r\n");

    init_tx_buffer_lut(TxBufferPtr, NUM_SAMPLES + 32);

    Xil_DCacheFlushRange((UINTPTR)TxBufferPtr, 2*(NUM_SAMPLES + 32));
	Xil_DCacheFlushRange((UINTPTR)RxBufferPtr, 4*NUM_SAMPLES);

    axi_switches_cnfg(AxisSwitch_0, 1, 0); // DDS Input
    axi_switches_cnfg(AxisSwitch_1, 0, 1); // DDS Output


    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) RxBufferPtr,	4*NUM_SAMPLES, XAXIDMA_DEVICE_TO_DMA);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) TxBufferPtr, 2*(NUM_SAMPLES + 32), XAXIDMA_DMA_TO_DEVICE);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /*Wait till tranfer is done or 1usec * 10^6 iterations of timeout occurs*/
    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA) && XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) {
        if (TimeOut == 0) {
            xil_printf("\n\n[WARNING] AXIDMA TIMEOUT \r\n\n");
            break;
        }
        TimeOut--;
        usleep(1U);
    }

    xil_printf("[INFO] DDS compiler LUT  Done \r\n");

    axi_switches_stop(AxisSwitch_0, 1, 0);
    axi_switches_stop(AxisSwitch_1, 0, 1);

    xil_printf("[INFO] End Application\r\n");

	return XST_SUCCESS;
}


void axi_switches_cnfg(XAxis_Switch AxisSwitch, u8 MiIndex, u8 SiIndex)
{
    /* Disable register update */
	XAxisScr_RegUpdateDisable(&AxisSwitch);

	/* Disable all MI ports */
	XAxisScr_MiPortDisableAll(&AxisSwitch);
    /* Source SI[SiIndex] to MI[MiIndex] */
	XAxisScr_MiPortEnable(&AxisSwitch, MiIndex, SiIndex);

	/* Enable register update */
	XAxisScr_RegUpdateEnable(&AxisSwitch);

	/* Check for MI port enable */
	int Status = XAxisScr_IsMiPortEnabled(&AxisSwitch, MiIndex, SiIndex);
	if (Status) {
		xil_printf("[INFO] MI[%d] is sourced from SI[%d].\r\n", MiIndex, SiIndex);
	}

}


void axi_switches_stop(XAxis_Switch AxisSwitch, u8 MiIndex, u8 SiIndex)
{

    /* Disable MI[MiIndex] */
	XAxisScr_MiPortDisable(&AxisSwitch, MiIndex);

	/* Check for MI port enable */
	int Status = XAxisScr_IsMiPortEnabled(&AxisSwitch, MiIndex, SiIndex);
	if (!Status) {
		xil_printf("[INFO] MI[%d] is not sourced from SI[%d].\r\n", MiIndex, SiIndex);
	}
}

void init_tx_buffer_phase(  u8 *TxBufferPtr, int Nlen)
{
    double Freq_start = 1.0e6;
    double Freq_end = 0.0e6;
    for (uint16_t idx = 0; idx < Nlen; idx++) {
       double f_inst = Freq_start + (Freq_end - Freq_start) * idx / (Nlen - 1);
       uint16_t delta = (uint16_t)(f_inst * 0.00065536);
       TxBufferPtr[2 * idx + 1]     = (u8)((delta >> 8) & 0xFF);
       TxBufferPtr[2 * idx + 0] = (u8)(delta & 0xFF);
    }
}

void init_tx_buffer_lut(  u8 *TxBufferPtr, int Nlen)
{
    double Freq_start = 1.0e6;
    double Freq_end = 0.0e6;
    uint16_t phase = 0;
    for (uint16_t idx = 0; idx < Nlen; idx++) {
       double f_inst = Freq_start + (Freq_end - Freq_start) * idx / (Nlen - 1);
       uint16_t delta = (uint16_t)(f_inst * 0.00065536);
       phase += delta;
       TxBufferPtr[2 * idx + 1]     = (u8)((phase >> 8) & 0xFF);
       TxBufferPtr[2 * idx + 0] = (u8)(phase & 0xFF);
    }
}
