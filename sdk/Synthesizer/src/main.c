/**
 * 	Project: FPGA Synthesizer
 * 	Author: Laura Regan Williams
 * 	Date: 24/11/2020
 *
 */


/* Xilinx libraries*/
#include "xparameters.h"
#include "xplatform_info.h"
#include "xuartps.h"
#include <xgpio.h>
#include <xsysmon.h>
#include "xscugic.h"
#include "xscutimer.h"
#include "xil_exception.h"
#include "xil_printf.h"

#include "sleep.h"

/* Standard libraries*/
#include <math.h>

/*Custom IP includes*/
#include "Synthesizer.h"

#define DEBUG


#ifdef DEBUG
# define DEBUG_PRINT(x) xil_printf x
#else
# define DEBUG_PRINT(x) do {} while (0)
#endif



/************************** Constant Definitions **************************/
#define UART_DEVICE_ID		XPAR_XUARTPS_0_DEVICE_ID
#define MIDI_DEVICE_ID		XPAR_XUARTPS_1_DEVICE_ID
#define INTC_DEVICE_ID		XPAR_SCUGIC_SINGLE_DEVICE_ID
#define SYSMON_DEVICE_ID	XPAR_SYSMON_0_DEVICE_ID
#define TIMER_DEVICE_ID		XPAR_XSCUTIMER_0_DEVICE_ID

#define UART_INT_IRQ_ID		XPAR_XUARTPS_1_INTR
#define MIDI_INT_IRQ_ID		XPAR_XUARTPS_0_INTR
#define INTR_ID				61
#define TIMER_INT_IRQ_ID	XPAR_SCUTIMER_INTR

/* UART receive buffer size*/
#define UART_BUFFER_SIZE	100


/************************** Function Prototypes *****************************/

static int SetupUARTSystem(XUartPs *UartInstPtr);
static int SetupMIDISystem(XUartPs *MidiInstPtr);
static int SetupXADCSystem(XSysMon *SysMonInstPtr);
static int SetupTimerSystem(XScuTimer *TimerInstPtr);
static int SetupInterruptSystem(XScuGic *IntcInstancePtr,
		 	 	 	 	 	 	XSysMon *SysMonInstPtr,
								u16 XSysMonIntrId,
								XUartPs *UartInstPtr,
								u16 UartIntrId,
								XUartPs *MidiInstPtr,
								u16 MidiIntrId,
								XScuTimer *TimerInstPtr,
								u16 TimerIntrId);

static void UARTInterruptHandler(void *CallBackRef, u32 Event, unsigned int EventData);
static void MIDIInterruptHandler(void *CallBackRef, u32 Event, unsigned int EventData);
static void XAdcInterruptHandler(void *CallBackRef);
static void TimerInterruptHandler(void *CallBackRef);

void MessageReceived(uint8_t command, void *data, uint8_t size);
void readUart(XUartPs *instancePtr, u8 *buffer, int bytes);

/************************** Variable Definitions ***************************/

XUartPs UartInst;				/* Instance of the UART Device */
XUartPs MidiInst;				/* Instance of the MIDI Device */
XScuGic InterruptController;	/* Instance of the Interrupt Controller */
XSysMon SysMonInst;				/* Instance of the SysMon Device*/
XScuTimer TimerInst;
XGpio input, output;

static u8 RecvBuffer[UART_BUFFER_SIZE];	/* UART receive buffer */
static u8 MidiBuffer[UART_BUFFER_SIZE];	/* UART receive buffer */

int adcData[32];

int main(void)
{
	int Status;
	int enablePhysicalInterface = 0;

	// GPIO
	int ButtonData = 0;
	int SwitchData = 0;

	XGpio_Initialize(&input, XPAR_AXI_GPIO_1_DEVICE_ID);
	XGpio_Initialize(&output, XPAR_AXI_GPIO_0_DEVICE_ID);

	XGpio_SetDataDirection(&input, 1, 0xF);
	XGpio_SetDataDirection(&input, 2, 0xF);

	XGpio_SetDataDirection(&output, 1, 0x0);
	XGpio_SetDataDirection(&output, 2, 0x0);

	// UART
	SetupUARTSystem(&UartInst);
	SetupMIDISystem(&MidiInst);

	// System Monitor (XADC)
	SetupXADCSystem(&SysMonInst);

	// Timer
	SetupTimerSystem(&TimerInst);

	// Interrupt Controller
	Status = SetupInterruptSystem(&InterruptController, &SysMonInst, INTR_ID, &UartInst, UART_INT_IRQ_ID, &MidiInst, MIDI_INT_IRQ_ID, &TimerInst, TIMER_INT_IRQ_ID);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	XUartPs_Recv(&UartInst, RecvBuffer, UART_BUFFER_SIZE);

	// Oscillator initial values
	setOscillatorMix(OSCILLATOR_ADDR, 0, 1.0);
	setOscillatorMix(OSCILLATOR_ADDR, 1, 0.0);
	setOscillatorMix(OSCILLATOR_ADDR, 2, 0.0);

	setOscillatorWaveform(OSCILLATOR_ADDR, 0, 0);
	setOscillatorWaveform(OSCILLATOR_ADDR, 1, 0);
	setOscillatorWaveform(OSCILLATOR_ADDR, 2, 0);

	setOscillatorDetune(OSCILLATOR_ADDR, 0, 0);
	setOscillatorDetune(OSCILLATOR_ADDR, 1, 0);
	setOscillatorDetune(OSCILLATOR_ADDR, 2, 0);

	enableOscillatorPWM(OSCILLATOR_ADDR, 0, 1);
	enableOscillatorPWM(OSCILLATOR_ADDR, 1, 1);
	enableOscillatorPWM(OSCILLATOR_ADDR, 2, 1);

	// Amplitude ADSR initial values
	setAdsrAttack(ADSR_ADDR, 0.0);
	setAdsrDecay(ADSR_ADDR, 0.0);
	setAdsrSustain(ADSR_ADDR, 1.0);
	setAdsrRelease(ADSR_ADDR, 0.0);

	// Filter ADSR initial values
	setAdsrAttack(FILTER_ADSR_ADDR, 0.0);
	setAdsrDecay(FILTER_ADSR_ADDR, 0.0);
	setAdsrSustain(FILTER_ADSR_ADDR, 1.0);
	setAdsrRelease(FILTER_ADSR_ADDR, 0.0);

	// Filter initial values
	setFilterCutoffFrequency(FILTER_ADDR, 20000);	// cutoff 20kHz
	setFilterResonance(FILTER_ADDR, 0);				// resonance 0
	setFilterType(FILTER_ADDR, 0, 1);				// low pass, 12 dB/Oct
	setFilterEnvelopeAmount(FILTER_ADDR, 0.0);		// envelope amount 0
	setFilterModulationEnable(FILTER_ADDR, 1);		// enable cut-off frequency modulation
	setFilterModulationAmount(FILTER_ADDR, 1.0);	// set modulation amount to zero


	XScuTimer_LoadTimer(&TimerInst, 10000);
	XScuTimer_Start(&TimerInst);

	while(1)
	{
		SwitchData = XGpio_DiscreteRead(&input, 2);

		enablePhysicalInterface = SwitchData & 0x01;

		XGpio_DiscreteWrite(&output, 1, SwitchData);

		ButtonData = XGpio_DiscreteRead(&input, 1);

		switch(ButtonData)
		{
		case 0b00000:
			// do nothing
			break;
		case 0b00001:
			DEBUG_PRINT(("Button 0 pressed\n"));
			break;
		case 0b00010:
			DEBUG_PRINT(("Button 1 pressed\n"));
			break;
		case 0b00100:
			DEBUG_PRINT(("Button 2 pressed\n"));
			break;
		case 0b01000:
			DEBUG_PRINT(("Button 3 pressed\n"));
			break;
		case 0b10000:
			DEBUG_PRINT(("Button 4 pressed\n"));
			break;
		default:
			DEBUG_PRINT(("Multiple buttons pressed\n"));
			break;
		}

		if (enablePhysicalInterface)
		{
			int osc1Waveform = (4095 - adcData[30])/1024;
			setOscillatorWaveform(OSCILLATOR_ADDR, 0, osc1Waveform);

			int osc1Detune = 24.0*(2048.0 - adcData[31])/2048.0;
			//setOscillatorDetune(OSCILLATOR_ADDR, 0, osc1Detune);

			float osc1PulseWidth = (4095.0 - adcData[26])/4095.0;
			setOscillatorPulseWidth(OSCILLATOR_ADDR, 0, osc1PulseWidth);

			float osc1Mix = (4095.0 - adcData[8])/4095.0;
			setOscillatorMix(OSCILLATOR_ADDR, 0, osc1Mix);

			//int osc2Waveform = (4095 - adcData[5])/1024;
			//setOscillatorWaveform(OSCILLATOR_ADDR, 1, osc2Waveform);

			int osc2Detune = 24.0*(2048.0 - adcData[29])/2048.0;
			//setOscillatorDetune(OSCILLATOR_ADDR, 1, osc2Detune);

			float osc2PulseWidth = (4095.0 - adcData[7])/4095.0;
			setOscillatorPulseWidth(OSCILLATOR_ADDR, 1, osc2PulseWidth);

			float osc2Mix = (4095.0 - adcData[11])/4095.0;
			//setOscillatorMix(OSCILLATOR_ADDR, 1, osc2Mix);

			int osc3Waveform = (4095 - adcData[15])/1024;
			setOscillatorWaveform(OSCILLATOR_ADDR, 2, osc3Waveform);

			int osc3Detune = 24.0*(2048.0 - adcData[14])/2048.0;
			//setOscillatorDetune(OSCILLATOR_ADDR, 2, osc3Detune);

			float osc3PulseWidth = (4095.0 - adcData[13])/4095.0;
			setOscillatorPulseWidth(OSCILLATOR_ADDR, 2, osc3PulseWidth);

			float osc3Mix = (4095.0 - adcData[12])/4095.0;
			setOscillatorMix(OSCILLATOR_ADDR, 2, osc3Mix);

			int type = (4095.0 - adcData[9] + 4096.0/12)/4095.0*5.0;
			setFilterType(FILTER_ADDR, type >> 1, type & 0x01);

			float cutoff = 20000.0 * (4095.0 - adcData[5])/4095.0;
			setFilterCutoffFrequency(FILTER_ADDR, cutoff);

			float resonance = (4095.0 - adcData[22])/4095.0;
			setFilterResonance(FILTER_ADDR, resonance);

			float attack = 10.0 * (4095.0 - adcData[25])/4095.0;
			setAdsrAttack(ADSR_ADDR, attack);

			float decay = 10.0 * (4095.0 - adcData[27])/4095.0;
			setAdsrDecay(ADSR_ADDR, decay);

			float sustain = (4095.0 - adcData[23])/4095.0;
			setAdsrSustain(ADSR_ADDR, sustain);

			float release = 10.0 * (4095.0 - adcData[2])/4095.0; // faulty potentiometer
			setAdsrRelease(ADSR_ADDR, release);

			int lfo1Waveform = (4095 - adcData[24])/2048;

			int lfo1Rate = (4095 - adcData[21])/2048;

			int lfo1Amount = (4095 - adcData[16])/4095;

			int lfo2Waveform = (4095 - adcData[20])/2048;

			int lfo2Rate = (4095 - adcData[18])/2048;

			//int lfo2Amount = (4095 - adcData[])/4095;

			//int lfo3Waveform = (4095 - adcData[])/2048;

			int lfo3Rate = (4095 - adcData[1])/2048;

			int lfo3Amount = (4095 - adcData[0])/4095;

		}

		//usleep(2000);
	}
}

void MessageReceived(uint8_t command, void *data, uint8_t size)
{
	switch(command)
	{
		case MIDI:
		{
			MESSAGE_MIDI message;
			memcpy(&message, data, size);
			if (message.status == NOTE_ON)
			{
				SynthNoteOn(message.key);
			}
			else if (message.status == NOTE_OFF)
			{
				SynthNoteOff(message.key);
			}
			DEBUG_PRINT(("Received MIDI Message: %x %x %x\n", message.status, message.key, message.velocity));
		}
		break;
		case OSC_A_WAVE_TYPE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			setOscillatorWaveform(OSCILLATOR_ADDR, 0, message.data);
			DEBUG_PRINT(("Received Oscillator A Wave Type Message: %i\n", message.data));
		}
			break;
		case OSC_A_DETUNE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			setOscillatorDetune(OSCILLATOR_ADDR, 0, message.data);
			DEBUG_PRINT(("Received Oscillator A Detune Message: %i\n", message.data));
		}
			break;
		case OSC_A_SQUARE_PW:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float pw = message.data / 4095.0;
			setOscillatorPulseWidth(OSCILLATOR_ADDR, 0, pw);
			DEBUG_PRINT(("Received Oscillator A Pulse Width Message: %i\n", message.data));
		}
			break;
		case OSC_A_MIX:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float mix = message.data/4095.0;
			setOscillatorMix(OSCILLATOR_ADDR, 0, mix);
			DEBUG_PRINT(("Received Oscillator A Mix Message: %i\n", message.data));
		}
			break;
		case OSC_B_WAVE_TYPE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			setOscillatorWaveform(OSCILLATOR_ADDR, 1, message.data);
			DEBUG_PRINT(("Received Oscillator B Wave Type Message: %i\n", message.data));
		}
			break;
		case OSC_B_DETUNE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			setOscillatorDetune(OSCILLATOR_ADDR, 1, message.data);
			DEBUG_PRINT(("Received Oscillator B Detune Message: %i\n", message.data));
		}
			break;
		case OSC_B_SQUARE_PW:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float pw = message.data / 4095.0;
			setOscillatorPulseWidth(OSCILLATOR_ADDR, 1, pw);
			DEBUG_PRINT(("Received Oscillator B Pulse Width Message: %i\n", message.data));
		}
			break;
		case OSC_B_MIX:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float mix = message.data/4095.0;
			setOscillatorMix(OSCILLATOR_ADDR, 1, mix);
			DEBUG_PRINT(("Received Oscillator B Mix Message: %i\n", message.data));
		}
			break;
		case OSC_C_WAVE_TYPE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			setOscillatorWaveform(OSCILLATOR_ADDR, 2, message.data);
			DEBUG_PRINT(("Received Oscillator C Wave Type Message: %i\n", message.data));
		}
			break;
		case OSC_C_DETUNE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			setOscillatorDetune(OSCILLATOR_ADDR, 2, message.data);
			DEBUG_PRINT(("Received Oscillator C Detune Message: %i\n", message.data));
		}
			break;
		case OSC_C_SQUARE_PW:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float pw = message.data / 4095.0;
			setOscillatorPulseWidth(OSCILLATOR_ADDR, 2, pw);
			DEBUG_PRINT(("Received Oscillator C Pulse Width Message: %i\n", message.data));
		}
			break;
		case OSC_C_MIX:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float mix = message.data/4095.0;
			setOscillatorMix(OSCILLATOR_ADDR, 2, mix);
			DEBUG_PRINT(("Received Oscillator C Mix Message: %i\n", message.data));
		}
			break;
		case ADSR_ATTACK:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float time = message.data/4095.0*10.0;
			setAdsrAttack(ADSR_ADDR, time);
			DEBUG_PRINT(("Received ADSR Attack Type Message: %i\n", message.data));
		}
		break;
		case ADSR_DECAY:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float time = message.data/4095.0*10.0;
			setAdsrDecay(ADSR_ADDR, time);
			DEBUG_PRINT(("Received ADSR Decay Type Message: %i\n", message.data));
		}
		break;
		case ADSR_SUSTAIN:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float level = message.data/4095.0;
			setAdsrSustain(ADSR_ADDR, level);
			DEBUG_PRINT(("Received ADSR Sustain Type Message: %i\n", message.data));
		}
		break;
		case ADSR_RELEASE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float time = message.data/4095.0*10.0;
			setAdsrRelease(ADSR_ADDR, time);
			DEBUG_PRINT(("Received ADSR Release Type Message: %i\n", message.data));
		}
		break;
		case FILTER_TYPE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			u32 type = message.data >> 1;
			u32 attenuation = message.data & 0x01;
			setFilterType(FILTER_ADDR, type, attenuation);
			DEBUG_PRINT(("Received Filter Type Message: %i\n", message.data));
		}
			break;
		case FILTER_CUTOFF:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float frequency = message.data * 20000.0 / 4096.0;
			setFilterCutoffFrequency(FILTER_ADDR, frequency);
			DEBUG_PRINT(("Received Filter Cutoff Frequency Message: %i\n", message.data));
		}
			break;
		case FILTER_RESONANCE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float resonance = message.data / 4095.0;
			setFilterResonance(FILTER_ADDR, resonance);
			DEBUG_PRINT(("Received Filter Resonance Message: %i\n", message.data));
		}
			break;
		case FILTER_ENVELOPE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float amount = message.data/4095.0;
			setFilterEnvelopeAmount(FILTER_ADDR, amount);
			DEBUG_PRINT(("Received Filter Envelope Amount Message: %i\n", Xil_In32(FILTER_ADDR+FILTER_ENVELOPE_AMOUNT_REG)));
		}
			break;
		case FILTER_ATTACK:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float time = message.data/4095.0*10.0;
			setAdsrAttack(FILTER_ADSR_ADDR, time);
			DEBUG_PRINT(("Received Filter ADSR Attack Message: %i\n", message.data));
		}
		break;
		case FILTER_DECAY:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float time = message.data/4095.0*10.0;
			setAdsrDecay(FILTER_ADSR_ADDR, time);
			DEBUG_PRINT(("Received Filter ADSR Decay Message: %i\n", message.data));
		}
		break;
		case FILTER_SUSTAIN:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float level = message.data/4095.0;
			setAdsrSustain(FILTER_ADSR_ADDR, level);
			DEBUG_PRINT(("Received Filter ADSR Sustain Message: %i\n", message.data));
		}
		break;
		case FILTER_RELEASE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float time = message.data/4095.0*10.0;
			setAdsrRelease(FILTER_ADSR_ADDR, time);
			DEBUG_PRINT(("Received Filter ADSR Release Message: %i\n", message.data));
		}
		break;
		case LFO_A_WAVE_TYPE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			setLfoWaveform(LFO_A_ADDR, message.data);
			DEBUG_PRINT(("Received LFO A Wave Message: %i\n", message.data));
		}
		break;
		case LFO_A_RATE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float period = message.data/4095.0*30.0;
			setLfoRate(LFO_A_ADDR, period);
			DEBUG_PRINT(("Received LFO A Rate Message: %i\n", message.data));
		}
		break;
		case LFO_A_AMOUNT:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float amount = message.data/4095.0;
			setLfoAmount(LFO_A_ADDR, amount);
			DEBUG_PRINT(("Received LFO A Amount Message: %i\n", message.data));
		}
		break;
		case LFO_B_WAVE_TYPE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			setLfoWaveform(LFO_B_ADDR, message.data);
			DEBUG_PRINT(("Received LFO B Wave Type Message: %i\n", message.data));
		}
		break;
		case LFO_B_RATE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float period = message.data/4095.0*30.0;
			setLfoRate(LFO_B_ADDR, period);
			DEBUG_PRINT(("Received LFO B Rate Message: %i\n", message.data));
		}
		break;
		case LFO_B_AMOUNT:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float amount = message.data/4095.0;
			setLfoAmount(LFO_B_ADDR, amount);
			DEBUG_PRINT(("Received LFO B Amount Message: %i\n", message.data));
		}
		break;
		case LFO_C_WAVE_TYPE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			setLfoWaveform(LFO_C_ADDR, message.data);
			DEBUG_PRINT(("Received LFO C Wave Type Message: %i\n", message.data));
		}
		break;
		case LFO_C_RATE:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float period = message.data/4095.0*30.0;
			setLfoRate(LFO_C_ADDR, period);
			DEBUG_PRINT(("Received LFO C Rate Message: %i\n", message.data));
		}
		break;
		case LFO_C_AMOUNT:
		{
			STD_MESSAGE message;
			memcpy(&message, data, size);
			float amount = message.data/4095.0;
			setLfoAmount(LFO_C_ADDR, amount);
			DEBUG_PRINT(("Received LFO C Amount Message: %i\n\r", message.data));
		}
		break;
		default:
			DEBUG_PRINT(("Error: Unknown command\n\r"));
			break;
	}
}

static int SetupUARTSystem(XUartPs *UartInstPtr)
{
	XUartPs_Config *Config;
	int Status;
	u32 IntrMask;

	Config = XUartPs_LookupConfig(UART_DEVICE_ID);
	if (NULL == Config)
	{
		return XST_FAILURE;
	}

	Status = XUartPs_CfgInitialize(UartInstPtr, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	/* Check hardware build */
	Status = XUartPs_SelfTest(UartInstPtr);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	XUartPs_SetHandler(UartInstPtr, (XUartPs_Handler)UARTInterruptHandler, UartInstPtr);

	IntrMask =	XUARTPS_IXR_TOUT | XUARTPS_IXR_PARITY | XUARTPS_IXR_FRAMING |
				XUARTPS_IXR_OVER | XUARTPS_IXR_TXEMPTY | XUARTPS_IXR_RXFULL |
				XUARTPS_IXR_RXOVR;

	XUartPs_SetInterruptMask(UartInstPtr, IntrMask);

	XUartPs_SetOperMode(UartInstPtr, XUARTPS_OPER_MODE_NORMAL);

	/* Set baudrate to 38400 */
	XUartPs_SetBaudRate(UartInstPtr, 38400);

	/* Set time out to 32 (8x4) bit periods */
	XUartPs_SetRecvTimeout(UartInstPtr, 8);

	return XST_SUCCESS;
}

static int SetupMIDISystem(XUartPs *MidiInstPtr)
{
	XUartPs_Config *Config;
	int Status;
	u32 IntrMask;

	Config = XUartPs_LookupConfig(MIDI_DEVICE_ID);
	if (NULL == Config)
	{
		return XST_FAILURE;
	}

	Status = XUartPs_CfgInitialize(MidiInstPtr, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	/* Check hardware build */
	Status = XUartPs_SelfTest(MidiInstPtr);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	XUartPs_SetHandler(MidiInstPtr, (XUartPs_Handler)MIDIInterruptHandler, MidiInstPtr);

	IntrMask =	XUARTPS_IXR_RXOVR;


	XUartPs_SetInterruptMask(MidiInstPtr, IntrMask);

	XUartPs_SetOperMode(MidiInstPtr, XUARTPS_OPER_MODE_NORMAL);

	/* Set baudrate to 31250 */
	XUartPs_SetBaudRate(MidiInstPtr, 31250);

	/* Set time out to 32 (8x4) bit periods */
	XUartPs_SetRecvTimeout(MidiInstPtr, 0);
	XUartPs_SetFifoThreshold(MidiInstPtr, 3);

	return XST_SUCCESS;
}

static int SetupTimerSystem(XScuTimer *TimerInstPtr)
{
	XScuTimer_Config *ConfigPtr;
	int Status;

	ConfigPtr = XScuTimer_LookupConfig(TIMER_DEVICE_ID);
	if (ConfigPtr == NULL)
	{
		return XST_FAILURE;
	}

	Status = XScuTimer_CfgInitialize(TimerInstPtr, ConfigPtr, ConfigPtr->BaseAddr);
	if (Status != XST_SUCCESS)
	{
		xil_printf("TIMER INIT FAILURE\n\r");
		return XST_FAILURE;
	}

	Status = XScuTimer_SelfTest(TimerInstPtr);
	if (Status != XST_SUCCESS)
	{
		xil_printf("TIMER SELF TEST FAILURE\n\r");
		return XST_FAILURE;
	}

	XScuTimer_LoadTimer(TimerInstPtr, 10000);


	return XST_SUCCESS;
}

static int SetupXADCSystem(XSysMon * SysMonInstPtr)
{
	XSysMon_Config *ConfigPtr;
	int Status;

	ConfigPtr = XSysMon_LookupConfig(SYSMON_DEVICE_ID);
	if (ConfigPtr == NULL)
	{
		return XST_FAILURE;
	}

	Status = XSysMon_CfgInitialize(SysMonInstPtr, ConfigPtr, ConfigPtr->BaseAddress);
	if (Status != XST_SUCCESS)
	{
		xil_printf("SYSMON INIT FAILURE\n\r");
		return XST_FAILURE;
	}

	Status = XSysMon_SelfTest(SysMonInstPtr);
	if (Status != XST_SUCCESS)
	{
		xil_printf("SYSMON SELF TEST FAILURE\n\r");
		return XST_FAILURE;
	}

	/* Set sequencer to safe mode before changing configuration */
	XSysMon_SetSequencerMode(SysMonInstPtr, XSM_SEQ_MODE_SAFE);

	/* Disable alarms */
	XSysMon_SetAlarmEnables(SysMonInstPtr, 0x0);

	/* Enable channels AUX00 to AUX15 in sequencer */
	XSysMon_SetSeqChEnables(SysMonInstPtr, 0xFFFFFFFF);

	/* Enable Event Mode */
	XSysMon_SetSequencerEvent(SysMonInstPtr, FALSE);

	/* Set clock divider to 40 */
	XSysMon_SetAdcClkDivisor(SysMonInstPtr, 100);

	/* Connect VP/VN to external multiplexer */
	XSysMon_SetExtenalMux(SysMonInstPtr, XSM_CH_VPVN);

	/* All unipolar */
	XSysMon_SetSeqInputMode(SysMonInstPtr, 0x0);

	/* Extend acquisition time for channels 0 to 15 */
	XSysMon_SetSeqAcqTime(SysMonInstPtr, 0xFFFFFFFF);

	/* Average 16 samples */
	XSysMon_SetAvg(SysMonInstPtr, XSM_AVG_16_SAMPLES);

	/* Single channel - No Sequencing */
	XSysMon_SetSequencerMode(SysMonInstPtr, XSM_SEQ_MODE_SINGCHAN);

	return XST_SUCCESS;
}

static int SetupInterruptSystem(XScuGic *IntcInstancePtr,
		 	 	 	 	 	 	XSysMon *SysMonInstPtr,
								u16 XSysMonIntrId,
								XUartPs *UartInstPtr,
								u16 UartIntrId,
								XUartPs *MidiInstPtr,
								u16 MidiIntrId,
								XScuTimer *TimerInstPtr,
								u16 TimerIntrId)
{
	XScuGic_Config *IntcConfig; /* Config for interrupt controller */
	int Status;

	/* Initialize the interrupt controller driver */
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig)
	{
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig, IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}


	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
				(Xil_ExceptionHandler) XScuGic_InterruptHandler,
				IntcInstancePtr);

	/* UART interrupt */
	Status = XScuGic_Connect(IntcInstancePtr, UartIntrId,
				  (Xil_ExceptionHandler) XUartPs_InterruptHandler,
				  (void *) UartInstPtr);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	/* Enable the interrupt for the device */
	XScuGic_Enable(IntcInstancePtr, UartIntrId);

	/* MIDI interrupt */
	Status = XScuGic_Connect(IntcInstancePtr, MidiIntrId,
					  (Xil_ExceptionHandler) XUartPs_InterruptHandler,
					  (void *) MidiInstPtr);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	/* Enable the interrupt for the device */
	XScuGic_Enable(IntcInstancePtr, MidiIntrId);

	/* XADC interrupt */
	Status = XScuGic_Connect(IntcInstancePtr, XSysMonIntrId, (Xil_InterruptHandler)XAdcInterruptHandler, (void *) SysMonInstPtr);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	XScuGic_Enable(IntcInstancePtr, XSysMonIntrId);

	/* Timer interrupt*/
	Status = XScuGic_Connect(IntcInstancePtr, TimerIntrId,
						  (Xil_ExceptionHandler) TimerInterruptHandler,
						  (void *) TimerInstPtr);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	XScuGic_Enable(IntcInstancePtr, TimerIntrId);

	XScuTimer_EnableInterrupt(TimerInstPtr);

	/* Enable interrupts */
	Xil_ExceptionEnable();

	XScuGic_SetPriorityTriggerType(IntcInstancePtr, XSysMonIntrId, 0xa0 , 3);

	return XST_SUCCESS;
}

void UARTInterruptHandler(void *CallBackRef, u32 Event, unsigned int EventData)
{
	XUartPs *UartInstPtr = (XUartPs *) CallBackRef;

	/* All of the data has been sent */
	if (Event == XUARTPS_EVENT_SENT_DATA)
	{

	}

	/* All of the data has been received */
	if (Event == XUARTPS_EVENT_RECV_DATA)
	{

	}

	/*
	 * Data was received, but not the expected number of bytes, a
	 * timeout just indicates the data stopped for 8 character times
	 */
	if (Event == XUARTPS_EVENT_RECV_TOUT && EventData != 0)
	{
		XUartPs_Recv(UartInstPtr, RecvBuffer, 0);

		uint8_t command = RecvBuffer[0];
		void * data = RecvBuffer + 1;
		uint8_t size = EventData - 1;
		MessageReceived(command, data, size);

		XUartPs_Recv(UartInstPtr, RecvBuffer, UART_BUFFER_SIZE);
	}

	/*
	 * Data was received with an error, keep the data but determine
	 * what kind of errors occurred
	 */
	if (Event == XUARTPS_EVENT_RECV_ERROR)
	{

	}

	/*
	 * Data was received with an parity or frame or break error, keep the data
	 * but determine what kind of errors occurred. Specific to Zynq Ultrascale+
	 * MP.
	 */
	if (Event == XUARTPS_EVENT_PARE_FRAME_BRKE)
	{

	}

	/*
	 * Data was received with an overrun error, keep the data but determine
	 * what kind of errors occurred. Specific to Zynq Ultrascale+ MP.
	 */
	if (Event == XUARTPS_EVENT_RECV_ORERR)
	{

	}
}

void MIDIInterruptHandler(void *CallBackRef, u32 Event, unsigned int EventData)
{
	XUartPs *MidiInstPtr = (XUartPs *) CallBackRef;
	int count;

	do
	{
		count = XUartPs_Recv(MidiInstPtr, MidiBuffer, 1);
		if (count != 0)
		{
			char command = (MidiBuffer[0] & 0xF0);
			//char channel;
			char note;
			switch (command)
			{
			case NOTE_OFF:
				//channel = (MidiBuffer[0] & 0x0F);
				readUart(MidiInstPtr, MidiBuffer, 2);
				note = MidiBuffer[0];
				SynthNoteOff(note);
				break;
			case NOTE_ON:
				readUart(MidiInstPtr, MidiBuffer, 2);
				note = MidiBuffer[0];
				SynthNoteOn(note);
				break;
			case POLYPHONIC_PRESSURE:
				readUart(MidiInstPtr, MidiBuffer, 2);
				break;
			case CONTROL_CHANGE:
				readUart(MidiInstPtr, MidiBuffer, 2);
				break;
			case PROGRAM_CHANGE:
				readUart(MidiInstPtr, MidiBuffer, 1);
				break;
			case CHANNEL_PRESSURE:
				readUart(MidiInstPtr, MidiBuffer, 1);
				break;
			case PITCH_BEND:
				readUart(MidiInstPtr, MidiBuffer, 2);
				break;
			case SYSTEM:

				break;
			default:
				// unknown command
				break;
			}
		}
	} while (XUartPs_IsReceiveData(XPAR_XUARTPS_1_BASEADDR));
}

static void XAdcInterruptHandler(void *CallBackRef)
{
	int idx;
	static int mux = 0;

	for (idx = 0; idx < 16; idx++)
	{
		adcData[idx+mux*16] = (XSysMon_GetAdcData(&SysMonInst, XSM_CH_AUX_MIN + idx) >> 4);
		//DEBUG_PRINT(("CH%i: %u. ", idx+mux*16, adcData[idx+mux*16]));
	}
	//DEBUG_PRINT(("\n\r"));

	mux = (mux+1)%2;
	XGpio_DiscreteWrite(&output, 2, mux);

	XScuTimer_LoadTimer(&TimerInst, 10000);
	XScuTimer_Start(&TimerInst);
}


static void TimerInterruptHandler(void *CallBackRef)
{
	XScuTimer *TimerInstancePtr = (XScuTimer *) CallBackRef;

	XScuTimer_ClearInterruptStatus(TimerInstancePtr);

	XSysMon_SetSequencerMode(&SysMonInst, XSM_SEQ_MODE_SINGCHAN);
	XSysMon_SetSequencerMode(&SysMonInst, XSM_SEQ_MODE_ONEPASS);
}

void readUart(XUartPs *instancePtr, u8 *buffer, int bytes)
{
	int count = 0;
	int receivedTotal = 0;
	while (receivedTotal < bytes)
	{
		count = XUartPs_Recv(instancePtr, buffer+receivedTotal, bytes-receivedTotal);
		receivedTotal += count;
	}
}

