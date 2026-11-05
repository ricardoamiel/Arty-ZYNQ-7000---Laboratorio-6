#include "xparameters.h"
#include "xaxis_switch.h"
#include "xaxidma.h"

#include "sleep.h"
#include <stdint.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define MEM_BASE_ADDR		0x10000000

#define TX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00100000)
#define RX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00300000)
#define POLL_TIMEOUT_COUNTER    1000000U

#define XFTT_LOG2            11

XAxis_Switch AxisSwitch_0;	/**< Slave to Master MUX */
XAxiDma AxiDma; /**< AXI DMA Instance */

void axi_switches_cnfg(XAxis_Switch AxisSwitch, u8 MiIndex, u8 SiIndex);
void axi_switches_stop(XAxis_Switch AxisSwitch, u8 MiIndex, u8 SiIndex);
uint16_t scale_cascades(uint16_t log2nFFT);

void init_tx_buffer_chirp(u8 *TxBufferPtr, int Nlen);



typedef union {
    struct {
        uint32_t log2nFFT : 4; // [3:0]     log2nFFT
        uint32_t rsvd0 : 4;    // [3:0]     Reserved
        uint32_t dir : 1;      // [1]       Direction: 1 - Forward, 0 - Inverse
        uint32_t scaling : 12; // [11:0]    Scaling factor
        uint32_t rsvd1 : 11;   //           reserved
    } bits;  // Bitfield access
    uint32_t reg;  // Full 32-bit register access
} xfft_config_t;

xfft_config_t *xfft_config;


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

	Status = XAxisScr_CfgInitialize(&AxisSwitch_0, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		xil_printf("[ERROR] Axi Switch 0 AXI4-Stream initialization failed.\r\n");
		return XST_FAILURE;
	}

    xil_printf("[INFO] AXI DMA Configuration \r\n");

    u8 *TxBufferPtr;
	u8 *RxBufferPtr;
	int TimeOut = POLL_TIMEOUT_COUNTER;

	TxBufferPtr = (u8 *)TX_BUFFER_BASE ;
	RxBufferPtr = (u8 *)RX_BUFFER_BASE;
    
    
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

    xil_printf("\n[INFO] xFFT configuration for FORWARD \r\n");

    xfft_config->bits.dir = 1;
    xfft_config->bits.log2nFFT = XFTT_LOG2; // 2 ** xfft_config.bits.log2nFFT points
    xfft_config->bits.scaling = scale_cascades((uint16_t)XFTT_LOG2);
    Xil_DCacheFlushRange((UINTPTR)xfft_config, 4);

    axi_switches_cnfg(AxisSwitch_0, 1, 0);

    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) xfft_config, 4, XAXIDMA_DMA_TO_DEVICE);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    TimeOut = POLL_TIMEOUT_COUNTER;
    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA) && XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) {
        if (TimeOut == 0) {
            xil_printf("\n\n[WARNING] AXIDMA TIMEOUT \r\n\n");
            break;
        }
        TimeOut--;
        usleep(1U);
    }
    TimeOut = POLL_TIMEOUT_COUNTER;
    xil_printf("[INFO] xFFT configuration for FORWARD Done \r\n");

    xil_printf("[INFO] xFFT Forward Start \r\n");
    init_tx_buffer_chirp(TxBufferPtr, ((int)1 << XFTT_LOG2));

    Xil_DCacheFlushRange((UINTPTR)TxBufferPtr, 4*((int)1 << XFTT_LOG2));
	Xil_DCacheFlushRange((UINTPTR)RxBufferPtr, 4*((int)1 << XFTT_LOG2));

    axi_switches_cnfg(AxisSwitch_0, 0, 0);


    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) RxBufferPtr,	4*((int)1 << XFTT_LOG2), XAXIDMA_DEVICE_TO_DMA);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) TxBufferPtr, 4*((int)1 << XFTT_LOG2), XAXIDMA_DMA_TO_DEVICE);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA) && XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) {
        if (TimeOut == 0) {
            xil_printf("\n\n[WARNING] AXIDMA TIMEOUT \r\n\n");
            break;
        }
        TimeOut--;
        usleep(1U);
    }

    xil_printf("[INFO] xFFT Forward Done \r\n");

   xil_printf("\n[INFO] xFFT configuration for Inverse FFT \r\n");

    xfft_config->bits.dir = 0;
    xfft_config->bits.log2nFFT = XFTT_LOG2; // 2 ** xfft_config.bits.log2nFFT points
    xfft_config->bits.scaling = 0;
    Xil_DCacheFlushRange((UINTPTR)xfft_config, 4);

    axi_switches_cnfg(AxisSwitch_0, 1, 0);

    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) xfft_config, 4, XAXIDMA_DMA_TO_DEVICE);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    TimeOut = POLL_TIMEOUT_COUNTER;
    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA) && XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) {
        if (TimeOut == 0) {
            xil_printf("\n\n[WARNING] AXIDMA TIMEOUT \r\n\n");
            break;
        }
        TimeOut--;
        usleep(1U);
    }
    TimeOut = POLL_TIMEOUT_COUNTER;
    xil_printf("[INFO] xFFT configuration for Inverse Done \r\n");

    xil_printf("[INFO] xFFT Inverse Start \r\n");
    //TODO: change initialization
    init_tx_buffer_chirp(TxBufferPtr, ((int)1 << XFTT_LOG2));

    Xil_DCacheFlushRange((UINTPTR)TxBufferPtr, 4*((int)1 << XFTT_LOG2));
	Xil_DCacheFlushRange((UINTPTR)RxBufferPtr, 4*((int)1 << XFTT_LOG2));

    axi_switches_cnfg(AxisSwitch_0, 0, 0);

    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) TxBufferPtr,	4*((int)1 << XFTT_LOG2), XAXIDMA_DEVICE_TO_DMA);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    /* RxBufferPtr is used as Transmit Buffer since it consists of Forward FFT output */
    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR) RxBufferPtr, 4*((int)1 << XFTT_LOG2), XAXIDMA_DMA_TO_DEVICE);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA) && XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) {
        if (TimeOut == 0) {
            xil_printf("\n\n[WARNING] AXIDMA TIMEOUT \r\n\n");
            break;
        }
        TimeOut--;
        usleep(1U);
    }

    xil_printf("[INFO] xFFT Inverse Done \r\n");

    axi_switches_stop(AxisSwitch_0, 0, 0);

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


void init_tx_buffer_chirp(u8 *TxBufferPtr, int Nlen) {
    double Ts = 10e-9;            // Sample period: 10 ns.
    double amplitude = 16000.0;     // Adjust amplitude as needed.
    // Define chirp parameters:
    double Fstart = 8.0e6;          // Starting frequency
    double Fend   = 0.0e6;          // Ending frequency
    double T_total = (Nlen - 1) * Ts; // Total duration of the chirp.
    
    int idx;
    int16_t re, im;
    double t, phase;
    
    for (idx = 0; idx < Nlen; idx++) {
        t = idx * Ts;
        // Compute phase: phase = 2pi*Fstart*t + pi*(Fend - Fstart)*t^2/T_total
        phase = 2.0 * M_PI * Fstart * t + M_PI * (Fend - Fstart) * t * t / T_total;
        im = (int16_t)(amplitude * sin(phase));
        re = (int16_t)(amplitude * cos(phase));
        // Write the 16-bit sample in big-endian order:
        TxBufferPtr[4 * idx + 0]    =  (u8)(re & 0xFF);
        TxBufferPtr[4 * idx + 1]    =  (u8)((re >> 8) & 0xFF);
        TxBufferPtr[4 * idx + 2]    =  (u8)(im & 0xFF);
        TxBufferPtr[4 * idx + 3]    =  (u8)((im >> 8) & 0xFF);
    }
}

uint16_t scale_cascades(uint16_t log2nFFT)
{
	uint16_t sch = 0;
	switch (log2nFFT)  {
	    case 4:
	    	sch  = 0x0000000A;
	        break;
	    case 5:
	    	sch  = 0x0000001A;
	        break;
	    case 6:
	    	sch  = 0x0000002A;
	        break;
	    case 7:
	    	sch  = 0x0000006A;
	        break;
	    case 8:
	    	sch  = 0x000000AA;
	        break;
	    case 9:
	    	sch  = 0x000001AA;
	        break;
	    case 10:
	    	sch  = 0x000002AA;
	        break;
	    case 11:
	    	sch  = 0x000006AA;
	        break;
	    case 12:
	    	sch  = 0x00000AAA;
	        break;
	    case 13:
	    	sch  = 0x00000AAA;
	        break;
	    default: // up to 2**3 points
	    	sch = 6;
	}

	return sch;
}


