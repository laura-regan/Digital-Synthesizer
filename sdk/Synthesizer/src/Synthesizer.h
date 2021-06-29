/*
 * Synthesizer.h
 *
 *  Created on: 30 Dec 2020
 *      Author: Laura Isabel
 */

#ifndef SRC_SYNTHESIZER_H_
#define SRC_SYNTHESIZER_H_

enum MESSAGES
{
    MIDI,
    OSC_A_WAVE_TYPE,
    OSC_A_DETUNE,
    OSC_A_SQUARE_PW,
    OSC_A_MIX,
    OSC_B_WAVE_TYPE,
    OSC_B_DETUNE,
    OSC_B_SQUARE_PW,
    OSC_B_MIX,
	OSC_C_WAVE_TYPE,
	OSC_C_DETUNE,
	OSC_C_SQUARE_PW,
	OSC_C_MIX,
	LFO_A_WAVE_TYPE,
	LFO_A_RATE,
	LFO_A_AMOUNT,
	LFO_B_WAVE_TYPE,
	LFO_B_RATE,
	LFO_B_AMOUNT,
	LFO_C_WAVE_TYPE,
	LFO_C_RATE,
	LFO_C_AMOUNT,
    ADSR_ATTACK,
    ADSR_DECAY,
    ADSR_SUSTAIN,
    ADSR_RELEASE,
    FILTER_TYPE,
    FILTER_CUTOFF,
    FILTER_RESONANCE,
    FILTER_ENVELOPE,
    FILTER_ATTACK,
    FILTER_DECAY,
    FILTER_SUSTAIN,
    FILTER_RELEASE,
	SEQUENCER_RECORD,
	SEQUENCER_STOP,
	SEQUENCER_PLAY_PAUSE,
	SEQUENCER_TEMPO,
	SEQUENCER_TIME_DIV,
	SEQUENCER_GATE

};

#define NUM_CHANNELS				64

#define OSCILLATOR_ADDR				XPAR_OSCILLATOR_0_S_AXI_CTRL_BASEADDR
#define ADSR_ADDR 					XPAR_ADSR_0_S_AXI_CTRL_BASEADDR
#define FILTER_ADSR_ADDR 			XPAR_ADSR_1_S_AXI_CTRL_BASEADDR
#define FILTER_ADDR					XPAR_MOOG_LADDER_FILTER_0_S_AXI_CTRL_BASEADDR
#define LFO_A_ADDR					XPAR_LFO_0_S_AXI_CTRL_BASEADDR
#define LFO_B_ADDR					XPAR_LFO_1_S_AXI_CTRL_BASEADDR
#define LFO_C_ADDR					XPAR_LFO_2_S_AXI_CTRL_BASEADDR

// MIDI message types
#define NOTE_OFF                 0x80
#define NOTE_ON                  0x90
#define POLYPHONIC_PRESSURE  	 0xA0
#define CONTROL_CHANGE           0xB0
#define PROGRAM_CHANGE           0xC0
#define CHANNEL_PRESSURE         0xD0
#define PITCH_BEND               0xE0
#define SYSTEM					 0xF0

// Oscillator module registers
#define OSCILLATOR_FREQUENCY_REG		0
#define OSCILLATOR_WAVEFORM_REG			4
#define OSCILLATOR_PW_REG				8
#define OSCILLATOR_PWM_EN_REG   		12
#define OSCILLATOR_MODULATION_EN_REG	16
#define OSCILLATOR_DETUNE_REG			20
#define OSCILLATOR_MIX_REG				24

// ADSR module registers
#define ADSR_NOTE_ON_OFF_REG		0
#define ADSR_ATTACK_CW_REG			4
#define ADSR_DECAY_CW_REG			5
#define ADSR_SUSTAIN_LEVEL_REG		6
#define ADSR_RELEASE_CW_REG			7
#define ADSR_CHANNEL_FREE_REG		8

#define ADSR_MAX_VALUE				8388607		// Max 23 bit unsigned value
#define ADSR_MAX_TIME				10.0 		// Max time of 10 seconds
#define AUDIO_FREQ					96000.0		// Audio frequency of 96kHz

// Filter module registers
#define FILTER_CUTOFF_FREQUENCY_REG  0
#define FILTER_RESONANCE_REG         4
#define FILTER_ENVELOPE_AMOUNT_REG   8
#define FILTER_MODULATION_ENABLE_REG 12
#define FILTER_MODULATION_AMOUNT_REG 16
#define FILTER_TYPE_REG				 20
#define FILTER_ATTENUATION_REG		 24

// LFO module registers
#define LFO_CHANNEL_ON_OFF_REG		0
#define LFO_RATE_REG				4
#define LFO_AMOUNT_REG				8
#define LFO_WAVEFORM_REG			12


/* Standard message*/
typedef struct
{
    int16_t data;
} STD_MESSAGE;

/* MIDI message*/
typedef struct
{
    uint8_t status;
    uint8_t key;
    uint8_t velocity;
} MESSAGE_MIDI;


static int8_t assignedChannels[NUM_CHANNELS];

void ADSRNoteOn(u32 BaseAddress, u32 channel);
void ADSRNoteOff(u32 BaseAddress, u32 channel);
void ADSRCheckFreeChannels();

void OscillatorSetFrequency(uint32_t channel, float freq);

void SynthNoteOn(uint32_t note);
void SynthNoteOff(uint32_t note);

void SequencerRecord();
void SequencerStop();
void SequencerPlay();
void SequencerPause();
void SequencerStep(int8_t note);

static uint32_t freeChannels[4];

// Oscillator module functions

void setOscillatorFrequency(u32 address, uint32_t channel, float freq)
{
	float fcw = freq*1048576.0/96000.0;
	u32 config = (channel << 25) + (u32)fcw;
	Xil_Out32(address+OSCILLATOR_FREQUENCY_REG, config);
}

void setOscillatorDetune(u32 address, uint32_t oscillator, int semitones)
{
	float detune = powf(2.0, (semitones)/12.0);
	u32 msg = powf(2.0, 14.0) * detune;
	msg = msg + (oscillator << 25);
	Xil_Out32(address+OSCILLATOR_DETUNE_REG, (u32)msg);
}

void setOscillatorWaveform(u32 address, int oscillator, int waveform)
{
	u32 config = waveform + (oscillator << 25);
	Xil_Out32(address+OSCILLATOR_WAVEFORM_REG, config);
}

void setOscillatorPulseWidth(u32 address, int oscillator, float pw)
{
	u32 msg = (oscillator << 25) + (u32)(8388607.0 * pw);
	Xil_Out32(address+OSCILLATOR_PW_REG, msg);
}

void setOscillatorMix(u32 address, uint32_t oscillator, float mix)
{
	u32 value = (u32)(mix * 131071) + (oscillator << 25);
	Xil_Out32(address+OSCILLATOR_MIX_REG, (u32)value);
}

void enableOscillatorPWM(u32 address, uint32_t oscillator, unsigned enable)
{
	u32 msg = enable + (oscillator << 25);
	Xil_Out32(address+OSCILLATOR_PWM_EN_REG, (u32)msg);
}

void enableOscillatorModulation(u32 address, unsigned channel, unsigned enable)
{
	u32 value = (channel << 25) + enable;
	Xil_Out32(address+OSCILLATOR_MODULATION_EN_REG, value);
}

// ADSR envelope generator module functions

void setAdsrAttack(u32 adsrAddress, float time)
{
	u32 attackCW = time == 0 ? ADSR_MAX_VALUE : ADSR_MAX_VALUE / (time * AUDIO_FREQ);
	Xil_Out32(adsrAddress+ADSR_ATTACK_CW_REG*4, (u32)attackCW);
}

void setAdsrSustain(u32 adsrAddress, float level)
{
	u32 sustainLevel = ADSR_MAX_VALUE * level;
	Xil_Out32(adsrAddress+ADSR_SUSTAIN_LEVEL_REG*4, (u32)sustainLevel);
}

void setAdsrDecay(u32 adsrAddress, float time)
{
	u32 sustainLevel = Xil_In32(adsrAddress+ADSR_SUSTAIN_LEVEL_REG*4);
	u32 decayCW = (time == 0) ? (ADSR_MAX_VALUE - sustainLevel) : (ADSR_MAX_VALUE - sustainLevel) / (time * AUDIO_FREQ);
	Xil_Out32(adsrAddress+ADSR_DECAY_CW_REG*4, (u32)decayCW);
}

void setAdsrRelease(u32 adsrAddress, float time)
{
	u32 sustainLevel = Xil_In32(adsrAddress+ADSR_SUSTAIN_LEVEL_REG*4);
	u32 releaseCW = (time == 0) ? sustainLevel : sustainLevel / (time * AUDIO_FREQ);
	Xil_Out32(adsrAddress+ADSR_RELEASE_CW_REG*4, (u32)releaseCW);
}

void setAdsrNoteOn(u32 BaseAddress, u32 channel)
{
	u32 on_off_notes = Xil_In32(BaseAddress+ADSR_NOTE_ON_OFF_REG*4);
	on_off_notes |= (0x1 << channel);
	Xil_Out32(BaseAddress+ADSR_NOTE_ON_OFF_REG*4, on_off_notes);
}

void setAdsrNoteOff(u32 BaseAddress, u32 channel)
{
	u32 on_off_notes = Xil_In32(BaseAddress+ADSR_NOTE_ON_OFF_REG*4);
	on_off_notes &= ~(0x1 << channel);
	Xil_Out32(BaseAddress+ADSR_NOTE_ON_OFF_REG*4, on_off_notes);
}

void getAdsrFreeChannels(u32 adsrAddress)
{
	freeChannels[0] = Xil_In32(adsrAddress+ADSR_CHANNEL_FREE_REG*4);
	freeChannels[1] = Xil_In32(adsrAddress+ADSR_CHANNEL_FREE_REG*4+4);
	freeChannels[2] = Xil_In32(adsrAddress+ADSR_CHANNEL_FREE_REG*4+8);
	freeChannels[3] = Xil_In32(adsrAddress+ADSR_CHANNEL_FREE_REG*4+16);
}

// Filter module functions

void setFilterCutoffFrequency(u32 address, float frequency)
{
	u32 freq = frequency*32768/96000.0*2*3.14159;
	Xil_Out32(address+FILTER_CUTOFF_FREQUENCY_REG, (u32)freq);
}

void setFilterType(u32 address, int type, int attenuation)
{
	Xil_Out32(address+FILTER_TYPE_REG, (u32)type);
	Xil_Out32(address+FILTER_ATTENUATION_REG, (u32)attenuation);
}

void setFilterResonance(u32 address, float resonance)
{
	u32 res = resonance * 32767;
	Xil_Out32(address+FILTER_RESONANCE_REG, (u32)res);
}

void setFilterEnvelopeAmount(u32 address, float amount)
{
	u32 am = amount*20000.0/96000.0*2*3.14159*32767;
	Xil_Out32(address+FILTER_ENVELOPE_AMOUNT_REG, (u32)am);
}

void setFilterModulationEnable(u32 address, unsigned value)
{
	Xil_Out32(address+FILTER_MODULATION_ENABLE_REG, (u32)value);
}

void setFilterModulationAmount(u32 address, float amount)
{
	u32 value = amount * 42893;
	Xil_Out32(address+FILTER_MODULATION_AMOUNT_REG, (u32)value);
}

// LFO module functions

void setLfoChannelOn(u32 BaseAddress, u32 channel)
{
	u32 value = channel + (0x1 << 7) + (0x1 << 8);
	Xil_Out32(BaseAddress+LFO_CHANNEL_ON_OFF_REG, value);
}

void setLfoChannelOff(u32 BaseAddress, u32 channel)
{
	u32 value = channel + (0x1 << 8);
	Xil_Out32(BaseAddress+LFO_CHANNEL_ON_OFF_REG, value);
}

void setLfoWaveform(u32 BaseAddress, u32 waveform)
{
	Xil_Out32(BaseAddress+LFO_WAVEFORM_REG, waveform);
}


void setLfoRate(u32 BaseAddress, float period)
{
	u32 fcw = 16777216.0/96000.0/period;
	Xil_Out32(BaseAddress+LFO_RATE_REG, fcw);
}

void setLfoAmount(u32 BaseAddress, float amount)
{
	u32 value = 32767 * amount;
	Xil_Out32(BaseAddress+LFO_AMOUNT_REG, value);
}


// Synthesizer functions

void SynthNoteOn(uint32_t note)
{
	getAdsrFreeChannels(ADSR_ADDR);
	uint32_t temp;
	int i = 0;
	while( ((temp = (freeChannels[i/32] & (1 << i))) == 0) && (i < NUM_CHANNELS) )
	{
		i++;
	}

	if (i < NUM_CHANNELS) // channel available
	{
		float freq = 8.18*powf(2.0, note/12.0);
		// set oscillator channel frequency
		setOscillatorFrequency(OSCILLATOR_ADDR, i, freq);
		// turn on ADSR channel
		setAdsrNoteOn(ADSR_ADDR, i);
		setAdsrNoteOn(FILTER_ADSR_ADDR, i);
		// turn on LFO channel
		enableOscillatorModulation(OSCILLATOR_ADDR,i, 1);
		setLfoChannelOn(LFO_A_ADDR, i);
		setLfoChannelOn(LFO_B_ADDR, i);
		setLfoChannelOn(LFO_C_ADDR, i);
		// assign key to channel
		assignedChannels[i] = note;
	}

}

void SynthNoteOff(uint32_t note)
{
	int i = 0;
	while ((assignedChannels[i] != note) && (i < NUM_CHANNELS))
	{
		i++;
	}

	if (i < NUM_CHANNELS)
	{
		// channels had been assigned
		setAdsrNoteOff(ADSR_ADDR, i);
		setAdsrNoteOff(FILTER_ADSR_ADDR, i);
		// turn off LFO channel
		setLfoChannelOff(LFO_A_ADDR, i);
		setLfoChannelOff(LFO_B_ADDR, i);
		setLfoChannelOff(LFO_C_ADDR, i);
		assignedChannels[i] = -1;
	}

}


#endif /* SRC_SYNTHESIZER_H_ */
