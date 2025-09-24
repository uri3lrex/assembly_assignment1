#include "hardware/regs/addressmap.h"   //include reigster address defs
#include "hardware/regs/io_bank0.h"     //include gpio bank regs
#include "hardware/regs/timer.h"        //include time regs
#include "hardware/regs/m0plus.h"       //include cortexm0+ specs

.syntax unified
.cpu    cortex-m0plus
.thumb
.global main_asm
.align    4

//define constants for LED flashing states
.equ    DFLT_STATE_STRT, 1              // Specify the value to start flashing
.equ    DFLT_STATE_STOP, 0              // Specify the value to stop flashing
.equ    DFLT_ALARM_TIME, 1000000        // Specify the default alarm timeout
//define gpio button masks fro detecetign falling-edge events
.equ    GPIO_BTN_DN_MSK, 0x00040000     // Bit-18 for falling-edge event on GP20
.equ    GPIO_BTN_EN_MSK, 0x00400000     // Bit-22 for falling-edge event on GP21
.equ    GPIO_BTN_UP_MSK, 0x04000000     // Bit-26 for falling-edge event on GP22
//define gpio pin numbers fro buttons and LEDs
.equ    GPIO_BTN_DN,  20                // Specify pin for the "down" button
.equ    GPIO_BTN_EN,  21                // Specify pin for the "enter" button
.equ    GPIO_BTN_UP,  22                // Specify pin for the "up" button
.equ    GPIO_LED_PIN, 25                // Specify pin for the built-in LED
//define gpio direction values
.equ    GPIO_DIR_IN,   0                // Specify input direction for a GPIO pin
.equ    GPIO_DIR_OUT,  1                // Specify output direction for a GPIO pin
//define LED on or off
.equ    LED_VAL_ON,    1                // Specify value that turns the LED "on"
.equ    LED_VAL_OFF,   0                // Specify value that turns the LED "off"
//define interrupt vector offsets
.equ    GPIO_ISR_OFFSET, 0x74           // GPIO is int #13 (vector-table entry 29)
.equ    ALRM_ISR_OFFSET, 0x40           // ALARM0 is int #0 (vector-table entry 16)

main_asm:
    ldr     r0, =msg            // Load message "Hello, this is assign01!\n" into r0                    
    bl      printf              // Print message
    bl      setup_alarm_isr    // Installing alarm interrupt handler
    bl      ins_gpio_isr_handler    // Installing GPIO interrupt handler
    bl      initialize_leds           // Initializing LED GPIO
    bl      initialize_buttons        // Initializing the button GPIOs
    bl      initialize_alarm           // Initializing the alarm settings

main_loop:
    bl      set_alarm           // Function to call for the next alarm
    wfi                         // Waiting for interrupt to save power
    b       main_loop           // Loop forever

// Initialize LED GPIO
.thumb_func
initialize_leds:
    push    {lr}                    // Save link register (return address) on the stack
    movs    r0, #GPIO_LED_PIN       // Load LED pin number -> register r0
    bl      asm_gpio_init           // Call function to initialize the GPIO for the LED
    movs    r0, #GPIO_LED_PIN       // Load LED pin number again -> register r0
    movs    r1, #GPIO_DIR_OUT       // Load value for output direction -> register r1
    bl      asm_gpio_set_dir        // Call function to set LED pin -> output
    pop     {pc}                    // Return

// Initialize buttons
.thumb_func
initialize_buttons:
    push    {lr}                    // Save link register (return address) on the stack

    ldr     r0, =GPIO_BTN_DN        // Loading address of "DOWN" button
    bl      asm_gpio_set_irq        // Call function to enable interrupt for "DOWN" button
    ldr     r0, =GPIO_BTN_DN        // Loading address of "DOWN" button 
    movs    r1, #GPIO_DIR_IN        // Set button direction -> input
    bl      asm_gpio_set_dir        // Call function for direction

    ldr     r0, =GPIO_BTN_EN        // Load address of "ENTER" button pin
    bl      asm_gpio_set_irq        // Enable interrupt for "ENTER" button
    ldr     r0, =GPIO_BTN_EN        // Load address of "ENTER" button pin again
    movs    r1, #GPIO_DIR_IN        // Set button direction ->  input
    bl      asm_gpio_set_dir        // Call function for direction

    ldr     r0, =GPIO_BTN_UP        // Load address of "UP" button pin
    bl      asm_gpio_set_irq        // Call function to interrupt for "UP" button
    ldr     r0, =GPIO_BTN_UP        // Loading address of "UP" button pin again
    movs    r1, #GPIO_DIR_IN        // Set button direction ->  input
    bl      asm_gpio_set_dir        // Call function for the direction

    pop     {pc}                    //Return

// Initialize alarm system
.thumb_func
initialize_alarm:
    ldr     r0, =TIMER_BASE             //Loading base address of the timer
    ldr     r1, =TIMER_INTE_OFFSET      //Loading offset for the timer interrupt enable reg
    add     r0, r0, r1                  //Computing address of the interrupt enable register
    ldr     r2, =1                      //Load value 1 (to enable alarm interrupt)  
    str     r2, [r0]                    //Store 1 -> interrupt enable register to activate the alarm interrupt
    bx      lr                          //Return

// Set an alarm
.thumb_func
set_alarm:
    ldr     r4, =lstate                     // Load address of LED state
    ldr     r5, [r4]                        // Load CURRENT LED state value
    cmp     r5, #DFLT_STATE_STOP            // Check if LED flashing has stopped
    beq     end                             // If stopped, end
    ldr     r0, =TIMER_BASE                 // Load base address of the timer
    ldr     r1, =TIMER_TIMELR_OFFSET        // Load offset for the current timer value
    add     r0, r0, r1                      // Compute the address of the current timer register
    ldr     r2, [r0]                        // Load current time from the timer register        
    ldr     r3, =ltimer                     // Load address of the timer duration variable
    ldr     r4, [r3]                        // Load the timer duration value
    add     r2, r2, r4                      // Add duration to the current time to set alarm time      
    ldr     r0, =TIMER_BASE                 // Load base address of the timer
    ldr     r1, =TIMER_ALARM0_OFFSET        // Load offset for the alarm register
    add     r0, r0, r1                      // Compute the address of the alarm register
    str     r2, [r0]                        // Store the computed alarm time in the alarm register
end:
    bx      lr                              //Return

.thumb_func
setup_alarm_isr:
    ldr     r2,=(PPB_BASE + M0PLUS_VTOR_OFFSET)              // Load vector-table base address
    ldr     r1, [r2]                                         // Get current vector-table address
    movs    r2, #ALRM_ISR_OFFSET                             // Load alarm ISR offset
    add     r2, r1                                           // Calculate ISR address
    ldr     r0, =alrm_isr                                    // Load address of alarm ISR funtion
    str     r0, [r2]                                         // Store ISR address in vector-table
    ldr     r2,=(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)         // Load NVIC interrupt clear register   
    ldr     r0, =1                                           // Set bit for alarm interrupt
    str     r0, [r2]                                         // Clear pending interrupt
    ldr     r2,=(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)         // Load NVIC interrupt enable register
    ldr     r0, =1                                           // Enable alarm interrupt
    str     r0, [r2]
    bx      lr                                               // Return

.thumb_func
alrm_isr:
    push    {lr}                                            // Save return address
    ldr     r0, =alarm                                      // Load alarm message "Timer alarm triggered!!\n"
    bl      printf                                          // Print message
    ldr     r2, =(TIMER_BASE + TIMER_INTR_OFFSET)           // Load timer interrupt status reg address
    ldr     r1, =1                                          // Load interrupt clear bit value
    str     r1, [r2]                                        // Clear timer interrupt
    movs    r0, #GPIO_LED_PIN                               // Load LED pin number
    bl      asm_gpio_get                                    // LED state
    cmp     r0, #LED_VAL_OFF                                // Check if LED is off
    beq     led_set_on                                      // Branch to turn LED on if it's off
led_set_off:
    movs    r1, #LED_VAL_OFF                                // Set LED off value
    b       led_set_state                                   // Jump to set LED state
led_set_on:
    movs    r1, #LED_VAL_ON                                 // Set LED on value
led_set_state:
    movs    r0, #GPIO_LED_PIN                               // Load LED pin number
    bl      asm_gpio_put                                    // Set LED state
    pop     {pc}                                            // Restore return address and return

.thumb_func
ins_gpio_isr_handler:

    ldr     r2,=(PPB_BASE + M0PLUS_VTOR_OFFSET)             // Load vector-table base address
    ldr     r1, [r2]                                        // Get vector-table address
    ldr     r2, =GPIO_ISR_OFFSET                            // Load GPIO ISR offset
    add     r2, r1                                          // Calculate ISR address
    ldr     r0, =gpio_isr                                   // Load address of GPIO ISR
    str     r0, [r2]                                        // Store ISR address
    ldr     r0, =0x1                                     
    lsls    r0, #13                                         // Shifting left to match GPIO interrupt bit
    ldr     r1,=(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)        // Load NVIC interrupt register enable
    str     r0, [r1]                                        // Clear pending GPIO interrupt
    ldr     r1,=(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)        // Load NVIC interrupt enable register
    str     r0, [r1]                                        // Enable GPIO interrupt
    bx      lr                                              //Return

.thumb_func
gpio_isr:
    push    {lr}                                                    // Save the link register (return address) on the stack
    ldr     r2, =(IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET)      // Load address of GPIO interrupt status register
    ldr     r1, [r2]                                                // Load interrupt status
    ldr     r3, =GPIO_BTN_DN_MSK                                    // Load mask for button - down
    ands    r1, r3                                                  // Apply mask to check if button down was pressed
    cmp     r1, r3                                                  // Compare result with mask value
    bne     not_down                                                // If button down not pressed, branch to "not_down"
    ldr     r4, =lstate                                             // Load address of lstate 
    ldr     r5, [r4]                                                // Load current state value
    cmp     r5, #1                                                  // Cjeck if state is 1, meaning flashing
    beq     no_pause_down                                               // If flashing then branch to "no_pause_down"
    ldr     r4, =ltimer                                             // Load address of ltimer
    ldr     r5, =DFLT_ALARM_TIME                                    // Loaad defualt alarm time value
    str     r5, [r4]                                                // Store default alarm time in ltimer
    ldr     r0, =reset                                              // Load address of reset msg - "Flashing rate successfully resetted!\n"
    bl      printf                                                  // Print the message
    b       finish                                                  // Branch to finish (exit ISR)

no_pause_down:
    ldr     r1, =ltimer     //Load address of ltimer
    ldr     r3,[r1]         //Load current timer value
    lsls    r3, #1          //Left shift, double the value
    str     r3, [r1]        //Store updated timer value
    ldr     r0, =dn         //Load address of dn msg - "The flashing rate of the LED has now halved!\n"
    bl      printf          //Print
    b       finish          //Branch to finish

not_down:
    ldr     r2, =(IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET)      // Load address of GPIO interrupt status register
    ldr     r1, [r2]                                                // Load interrupt status
    ldr     r3, =GPIO_BTN_EN_MSK                                    // Load mask for button - enter
    ands    r1, r3                                                  // Apply mask to check if button enter was pressed
    cmp     r1, r3                                                  // Compare result with mask value
    bne     not_enter                                               // If button enter not pressed, branch to "not_enter"
    ldr     r2, =lstate                                             // Load address of lstate
    ldr     r3, [r2]                                                // Load current state value
    cmp     r3, #1                                                  // Check if state is 1 (flashing)
    bne     start_timer                                             // If not in flashing state, branch to "start_timer"
    ldr     r1, =DFLT_STATE_STOP                                    // Load default stop state value
    ldr     r2, =lstate                                             // Load address of lstate
    str     r1, [r2]                                                // Store stop state value
    ldr     r0, =pause                                              // Load address of pause msg - "Paused said LED flashing rate!\n"
    bl      printf                                                  // Print pause message
    b       finish                                                  // Branch to finish (exit ISR)

start_timer:
    ldr     r1, =DFLT_STATE_STRT    //Load default start state value
    ldr     r2, =lstate             //Load address of lstate
    str     r1, [r2]                //Store start state value
    ldr     r0, =start              //Load address of start msg - "LED flashing started\n"
    bl      printf                  //Print
    b       finish                  //Bracnh to finish

not_enter:
    ldr     r2, =(IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET)      // Load address of GPIO interrupt status register
    ldr     r1, [r2]                                                // Load interrupt status
    ldr     r3, =GPIO_BTN_UP_MSK                                    // Load mask for button - up
    ands    r1, r3                                                  // Apply mask to check if button up was pressed
    cmp     r1, r3                                                  // Compare result with mask value
    bne     finish                                                  // If button up not pressed, branch to "finish"
    ldr     r4, =lstate                                             // Load address of lstate
    ldr     r5, [r4]                                                // Load current state value
    cmp     r5, #1                                                  // Check if state is 1 (flashing) 
    beq     no_pause_up                                             // If in flashing state, branch to "no_pause_up"
    ldr     r4, =ltimer                                             // Load address of ltimer
    ldr     r5, =DFLT_ALARM_TIME                                    // Load default alarm time value
    str     r5, [r4]                                                // Store default alarm time in ltimer 
    ldr     r0, =reset                                              // Load address of reset msg - "Flashing rate successfully resetted!\n"
    bl      printf                                                  // Print
    b       finish                                                  // Branch to finihs

no_pause_up:
    ldr     r1, =ltimer     //Load address of ltimer
    ldr     r3,[r1]         //Load current timer value
    asrs    r3, #1          //Shift right, divide timer value /2
    str     r3, [r1]        //Store updated timer value 
    ldr     r0, =up         //Load address of up msg - "The flashing rate of the LED has now doubled!\n"
    bl      printf          //Print
    b       finish          //Branch to finish
//Clear the interrupt in GPIO
finish:
    ldr     r0, =IO_BANK0_BASE              // Load base address of IO_BANK0
    ldr     r1, =IO_BANK0_INTR2_OFFSET      // Load offset for interrupt clear register
    add     r0, r0, r1                      // Compute address for PROC0_INTR2
    ldr     r2, [r0]                        // Load current interrupt pin state
    str     r2, [r0]                        // Write back to clear the interrupt
    pop     {pc}                            // Restore return address and exit ISR

.align 4
msg: 	   .asciz "Currently running Assignment 01 on terminal!\n"
up:        .asciz "The flashing rate of the LED has now doubled!\n"
dn:        .asciz "The flashing rate of the LED has now halved!\n"
reset:     .asciz "Flashing rate successfully resetted!\n"
pause:     .asciz "Paused said LED flashing rate!\n"
start:     .asciz "LED had started to flash!!\n"
alarm:     .asciz "Timer alarm triggered!!\n"

.data
lstate: .word    DFLT_STATE_STRT    
ltimer: .word    DFLT_ALARM_TIME   
