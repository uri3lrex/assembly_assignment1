# 💡 ARM Cortex-M0+ LED Control with Button Interrupts  

This project is an **ARM Cortex-M0+ assembly implementation** for the Raspberry Pi Pico (RP2040).  
It demonstrates the use of **GPIO, timers, and interrupts** to control the onboard LED using three buttons.  

---

## ⚙️ Features
- **Timer-based LED flashing**
  - Default flashing rate controlled by an alarm interrupt.
- **Button controls (GPIO 20, 21, 22)**
  - **Down (GP20):** Halve the LED flashing rate.  
  - **Up (GP22):** Double the LED flashing rate.  
  - **Enter (GP21):** Start/stop LED flashing.  
- **Interrupt Service Routines (ISRs)**
  - Alarm ISR: toggles LED state and prints messages.  
  - GPIO ISR: handles button presses and updates state.  
- **Console messages** via `printf` to indicate events (start, pause, reset, alarm triggered, etc.).  

---

## 📂 File Structure
- `main_asm`: Entry point, sets up interrupts and main loop.  
- `initialize_leds`: Configures the onboard LED (GPIO 25).  
- `initialize_buttons`: Sets up buttons with input + IRQ.  
- `initialize_alarm`: Configures timer alarm interrupts.  
- `alrm_isr`: Handles alarm events (LED toggle).  
- `gpio_isr`: Handles button events (rate changes, start/stop).  
- `.data`: Stores LED state and current timer duration.  

---

## 🛠️ Requirements
- **Board:** Raspberry Pi Pico (RP2040, Cortex-M0+).  
- **Toolchain:** ARM GNU assembler + Pico SDK.  
- **Connections:**
  - GP20 → Button (Down)  
  - GP21 → Button (Enter)  
  - GP22 → Button (Up)  
  - GP25 → Onboard LED  

---

## ▶️ Usage
1. Assemble and link with the Pico SDK toolchain.  
2. Flash the `.uf2` binary onto the Raspberry Pi Pico.  
3. Open a serial terminal to observe runtime messages.  
4. Use the buttons to control LED flashing rate and state.  

---

## 📌 Notes
- Default alarm timeout: **1,000,000 cycles**.  
- Default LED state: **Start flashing**.  
- Messages are printed to the terminal for debugging and clarity.  
