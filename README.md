Modular Receiver 0-30 Mhz
=========================
![Modular receiver](./modular%20receiver.png)

This receiver was built around an AD831 mixer, a Raspberry Pi Pico (RP2040), and an SI5351.
The goal was to compare reception with the PICO-RX SDR receiver.

![Modular receiver](./schematic%20modular%20receiver.svg)

The software was written in Free Pascal and allows control of the local oscillator (SI5351) and the display (SSD1306).
A 20 dB attenuator at the SI5351 output makes it possible to match the level to the AD831 input.
The audio amplifier allows operation either with a loudspeaker or with headphones.
The CW transmit section is currently under construction (with a 5‑watt output power).
