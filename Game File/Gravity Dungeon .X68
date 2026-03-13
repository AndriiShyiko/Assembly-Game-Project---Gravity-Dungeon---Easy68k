*==========================================
*       ==== Andrii Shyiko====
*==== Goal: Text based game development====
*    ====Name: Gravity Dungeon ====
*==========================================

    ORG         $1000
DEATH           EQU             $0          ;COMPARISON TO HEALTH, IF TRUE GAME OVER

START:
    LEA         WELCOME_MSG,    A1          ; Load address of our message into A1
    MOVE.B      #14,            D0          ; Task 14: Display null-terminated string
    TRAP        #15                         ; Execute Task

INSTRUCTIONS:
    BSR         CLEAR_INPUT                 ; Clear garbage
    LEA         INPUT, A1                   ; Load address of buffer into A1
    MOVE.B      #2, D0                      ; Task 2: Read string from keyboard
    TRAP        #15                         ; Execute task
    
    ; Check if input is "YES"
    LEA         INPUT,          A0          ; A0 = User input
    LEA         YES,            A1          ; A1 = "YES" constant
    BSR         COMPARE_LOOP                ; Branch to string compare subroutine
    BEQ         YES_INSTRUCTIONS            ; If equal (Z-flag set), go to YES 

    ; Check if input is "NO"
    LEA         INPUT,          A0          ; Reset A0 to start of input
    LEA         NO,             A1          ; A1 = "NO" constant 
    BSR         COMPARE_LOOP
    BEQ         NO_INSTRUCTIONS             ; If equal, go to NO

    ; Check if input is "MAYBE"
    LEA         INPUT,          A0          ; Reset A0 to start of input
    LEA         MAYBE,          A1          ; A1 = "MAYBE" constant 
    BSR         COMPARE_LOOP
    BEQ         NOT_SURE                    ; If equal, go to NOT SURE
WRONG_CHOICE:
    LEA         WRONG,          A1          ; If the choice is wrong then display error      
    MOVE.B      #13,            D0          ; Task 13 
    TRAP        #15                         ; Execute Task
    
    BRA         INSTRUCTIONS 
*===========================================
*============MAIN GAME SPACE================
MAIN_GAME_LOOP: 
    
    ; 1. Check if player is still alive
    BSR         HEALTH_CHECK                ; Check if health is 0 or less
    BLE         NO_HEALTH_MSG               ; Branch if health is exactly 0 or less

    ; 2. If alive, continue game
    BSR         LOOKUP_STATUS               ; Display players data
    
    RTS
*===========================================
GAME_START:
    BSR         SPACE_FILL                  ; Add some space in between
    LEA         INSTRUCTION_MSG,    A1
    MOVE.B      #13,                D0
    TRAP        #15 
    
    BSR         DELAY_ROUTINE               ; Delay routine
    
    LEA         DROP_MSG, A1                ; Display drop message
    MOVE.B      #13, D0
    TRAP        #15
    BSR         DROP_SUPPLY                 ; Confirm drop opening
    
    LEA         NOTE_PICK, A1               ; Main game feature picked
    MOVE.B      #13, D0
    TRAP        #15
    BSR         DELAY_ROUTINE               ; Delay routine
    BSR         SPACE_FILL                  ; Fill space
    
    BRA         LOBBY                       ; Branch to Lobby level
*==============TECHNICAL SIDE================
NO_INSTRUCTIONS:
    ; Code for when input IS exactly "NO"
    LEA         WHY_NO,         A1            
    MOVE.B      #13,            D0          ; Task 13 
    TRAP        #15                         ; Execute Task
    
    BSR         SPACE_FILL                  ; Fill space
    
    BRA         INSTRUCTIONS

YES_INSTRUCTIONS:
    ; Code for when input IS exactly "YES"
    LEA         GOOD_CHOICE,        A1            
    MOVE.B      #13,                D0      ; Task 13 
    TRAP        #15                         ; Execute Task
    
    BSR         SPACE_FILL                  ; Fill space
    BSR         LOADING
    BSR         DELAY_ROUTINE               ; Delay routine
    BSR         SPACE_FILL                  ; Fill space
    BSR         LOADING
    BSR         DELAY_ROUTINE               ; Delay routine

    BRA         GAME_START                  ; Branch to the Start the game 
NOT_SURE:
    ; Code to execute if the input is exactly "MAYBE"
    LEA         WAIT_SOME,          A1            
    MOVE.B      #13,                D0      ; Task 13 
    TRAP        #15                         ; Execute Task
    
    BRA         INSTRUCTIONS
CLEAR_INPUT:
    LEA         INPUT, A0                   ; Point A0 to the start of the buffer
    MOVE.W      #81, D1                     ; Set counter 
CLEAR_LOOP:
    CLR.B       (A0)+                       ; Move 0 into the address and increment A0
    DBRA        D1, CLEAR_LOOP              ; Decrement D1 and loop until it hits -1
    RTS                                     ; Return
*===========================================
*============COMPARE LOOP=============
COMPARE_LOOP:
    MOVE.B      (A0)+, D2                   ; Get a character from input
    CMP.B       (A1)+, D2                   ; Compare to constant byte
    BNE         CMP_DONE                    ; Not equal? Exit subroutine (STOP if Strings are different)
    TST.B       D2                          ; Was it the null terminator (0)? (Check if the character taken is 0)
    BNE         COMPARE_LOOP                ; If it's NOT 0, loop back - Keep checking
    
CMP_DONE:
    RTS                                     ; Return to caller
; *******************************************************************************
; ROUTINE:  INVERTER_MALFUNCTION
; DESCRIPTION:  Simulates a random 40% chance of an Inverter Malfunction.
; 
; 1. Uses the system hardware clock Task 8 for randomness.
; 2. Performs a division by 10 via DIVU and SWAP to get a range of 0-9.
; 3. If the result is 0-3 -> Triggers Malfunction.
; 4. If the result is 4-9 -> No Malfunction (60% probability).
;
; NOTES:
; - Uses 1/100ths of a second.
; - Overflow protection: The AND.L #$FFFF, D1 prevents the 
;   division from crashing the CPU if the system time value is too large.
; - After DIVU, the remainder is stored in the upper 16 bits
;   of the register. SWAP D1 brings this remainder to the lower bits
;   for comparison and randomness. 
; *******************************************************************************
INVERTER_MALFUNCTION:                       ; Random event that might occur during gravity shifting
    CLR.L       D1                          ; Set all 32 bits of D1 to 0
    
    MOVE.B      #8, D0                      ; Task 8: Get system time
    TRAP        #15                         ; Let D1 have 1/100ths of a second
    AND.L       #$FFFF, D1                  ; Prevent overflow during division
    DIVU        #10, D1                     ; Divide by 10 (range from 0-9)
    SWAP        D1  

    CMPI.B      #3, D1
    BLE         ZERO_TO_THREE               ; SHORTCUT SHOCKED
    
    CMPI.B      #4, D1
    BHS         FOUR_TO_NINE                ; SAVED BY RANDOM, NO MALFUNCTION
FOUR_TO_NINE:    
    RTS
ZERO_TO_THREE:
    LEA         MALFUNCTION, A1
    MOVE.B      #13, D0          
    TRAP        #15   
    
    BSR         SHORTCUT_DMG                ; Shortcut damage
    RTS      
SHORTCUT_DMG:
    MOVE.L      PLAYER_HEALTH, D0
    SUB.L       #5, D0
    MOVE.L      D0, PLAYER_HEALTH
    
    RTS
; *******************************************************************************
; ROUTINE:  DELAY_ROUTINE
; DESCRIPTION: Delay Control
;
; NOTES:
; - Creates a pause to allow the player to read messages, slows gameplay.
; *******************************************************************************
DELAY_ROUTINE:
    MOVE.L      #200, D1                    ; 2 second delay
    MOVE        #23, D0                     ; Task 23: Delay    
    TRAP        #15                         ; Execute the pause
    
    RTS
*===END OF DELAY====
FALLING_EFFECT:
    LEA         FALLING, A1
    MOVE.B      #13, D0
    TRAP        #15
    RTS
; *******************************************************************************
; ROUTINE: COORDINATES
; DESCRIPTION: Displays the Player's X and Y coordinates to the EASy68K console.
; 
; NOTE:
; - CLR.L D1 is used before MOVE.B to ensure the upper 24 bits 
;   of the register are zeroed. Since TRAP task #3 prints the full 32-bit longword, 
;   failing to clear the register would result in "garbage" data being displayed.
; *******************************************************************************
COORDINATES:
                                            ; === Display X Label ===
    LEA         X_MSG,  A1
    MOVE.B      #14,     D0
    TRAP        #15
                                            ; === Display X Value ===
    CLR.L       D1                          ;Clears all 32 bits of D1
    MOVE.B      PLAYERS_X, D1
    MOVE.B      #3, D0
    TRAP        #15
    BSR         SPACE_FILL                  ; Add visual padding
                                            ; === Display Y Label ===
    LEA         Y_MSG, A1
    MOVE.B      #14, D0
    TRAP        #15
                                            ; === Display Y Value ===
    CLR.L       D1                          ;Clears all 32 bits of D1
    MOVE.B      PLAYERS_Y, D1               
    MOVE.B      #3, D0
    TRAP        #15
    BSR         SPACE_FILL                  ; Add visual padding
    RTS
; *******************************************************************************
; ROUTINE:  LOOKUP_STATUS
; DESCRIPTION: Displays status of player
;
; NOTES:
; - Displays Health, X/Y, Location.
; - Uses BSR for clean logic.
; - Uses SPACE_FILL to separate game logs from UI.
; *******************************************************************************
LOOKUP_STATUS:                              ; Look up\display players info
    BSR         STATUS_BAR
    BSR         COORDINATES
    BSR         POSITION_RESOLUTION
    BSR         SPACE_FILL                  ; Add visual padding
    
    RTS
DROP_SUPPLY:
    LEA         OPENDROP, A1                ; Display Yes\No to open supply crate
    MOVE.B      #13, D0
    TRAP        #15
    
    BSR         CLEAR_INPUT                 ; Clear garbage
    LEA         INPUT, A1                   ; Load address of buffer into A1
    MOVE.B      #2, D0                      ; Task 2: Read string from keyboard
    TRAP        #15                         ; Execute task
    
    LEA         INPUT, A0                   ; A0 = User input
    LEA         YES, A1                     ; A1 = "YES" constant
    BSR         COMPARE_LOOP
    BNE         DROP_SUPPLY                 ; If input something else than 
    
    LEA         OPENING,    A1              ; Loading message
    MOVE.B      #13, D0
    TRAP        #15 
    BSR         SPACE_FILL                  ; Fill space | make a gap
    BSR         DELAY_ROUTINE               ; Delay Routine
    RTS       
HEALTH_CHECK:                               ; Check player health
    MOVE.L      PLAYER_HEALTH, D0
    CMPI.L      #DEATH, D0
    
    RTS 
; *******************************************************************************
; ROUTINE:  CONFIRM_MOVE
; DESCRIPTION: Stops program waiting for confirmation (Input Instruction)
;
; NOTE:
; - Forces user to type "YES" to proceed.
; - Ensures execution until match.
; *******************************************************************************   
CONFIRM_MOVE:                               ; Confirm routine for smooth gameplay
    LEA         PROCEED    , A1
    MOVE.B      #13, D0
    TRAP        #15
    
    BSR         CLEAR_INPUT                 ; Clear garbage
    LEA         INPUT, A1                   ; Load address of buffer into A1
    MOVE.B      #2, D0                      ; Task 2: Read string from keyboard
    TRAP        #15                         ; Execute task
    
    LEA         INPUT, A0                   ; A0 = User input
    LEA         YES, A1                     ; A1 = "YES" constant
    BSR         COMPARE_LOOP
    BNE         CONFIRM_MOVE
    BSR         SPACE_FILL                  ; Fill Space
       
    RTS
LOADING:
    LEA         LOADING_MSG,        A1            
    MOVE.B      #13,                D0      ; Task 13 
    TRAP        #15                         ; Execute Task
    
    RTS
SPACE_FILL:
    LEA         SPACE,              A1            
    MOVE.B      #13,                D0      ; Task 13 
    TRAP        #15                         ; Execute Task

    RTS
NO_HEALTH_MSG:
    LEA         NO_HEALTH,  A1
    MOVE.B      #13,        D0              ; Task 13
    TRAP        #15                         ; Execute Task

    BRA         GAME_END
; *******************************************************************************
; SUBROUTINE: STATUS_BAR
; DESCRIPTION: Renders the player's health status to the simulator console.
; 
;   - PLAYER_HEALTH: A longword variable containing health value.
;   - Register: CLR.L D1 - TRAP task #3 reads the 
;     entire 32-bit register. If D1 is not cleared, data in the upper
;     bits will corrupt the numerical output on screen.
; *******************************************************************************
STATUS_BAR:
    BSR         CLEAR_INPUT
    LEA         STATUS,     A1
    MOVE.B      #14,         D0
    TRAP        #15
    
    CLR.L       D1                          ; Clear all 32 bits of D1
    MOVE.L      PLAYER_HEALTH, D1           ; Load the ACTUAL VALUE into D1
    MOVE.B      #3, D0                      ; Display number from D1
    TRAP        #15                         ; Execute simulator task
    BSR         SPACE_FILL                  ; Space fill
    
    RTS
; *******************************************************************************
; ROUTINE: POSITION_RESOLUTION
; DESCRIPTION: Translates numerical X/Y coordinates into string output.
;
;   (X=0, Y=0) -> "FLOOR"
;   (X=0, Y=1) -> "RIGHT_WALL"
;   (X=1, Y=0) -> "LEFT_WALL"
;   (X=1, Y=1) -> "CEILING"
;
; NOTE:
; - Uses Nested Comparisons structure to resolve the state.
; *******************************************************************************
POSITION_RESOLUTION:
    CMP.B       #1, PLAYERS_X
    BEQ         X1
    
    CMP.B       #0, PLAYERS_X
    BEQ         X0
    
X0:
    CMP.B       #0, PLAYERS_Y
    BEQ         X0Y0
    
    CMP.B       #1, PLAYERS_Y
    BEQ         X0Y1

X1:
    CMP.B       #0, PLAYERS_Y
    BEQ         X1Y0
    
    CMP.B       #1, PLAYERS_Y
    BEQ         X1Y1

X0Y0:
    LEA         FLOOR,      A1
    MOVE.B      #13,        D0
    TRAP        #15
    
    RTS
X0Y1:
    LEA         RIGHT_WALL, A1
    MOVE.B      #13,        D0
    TRAP        #15
    
    RTS
X1Y0:
    LEA         LEFT_WALL,  A1
    MOVE.B      #13,        D0
    TRAP        #15
    
    RTS
X1Y1:
    LEA         CEILING,    A1
    MOVE.B      #13,        D0
    TRAP        #15
    
    RTS
* === END OF POSTITIONING ===
WRONG_SHIFT:
    LEA         WRONG,          A1          ; If the GRAVITY choice is wrong then display error      
    MOVE.B      #13,            D0          ; Task 13 
    TRAP        #15

    BRA         LOBBY_GRAV_INPUT            
; *******************************************************************************
; ROUTINE: SHIFT_CHECK
; PURPOSE: Manages player movement between four planes (Up, Down, Left, Right).
;
; 1. Compares user input string against direction constants.
; 2. Checks if the player is already at the target coordinate.
; 3. Updates PLAYERS_X/Y and triggers falling effect.
; 4. Applies 20-point health deduction if gravity shift is long.
;
; - The "SOLID_CHECK" routines re-verify the input string.
;   Since the direction is already known it saves CPU cycles.
; *******************************************************************************
SHIFT_CHECK:
    
    LEA         UP, A1                      ; CEILING CHECK
    LEA         INPUT, A0
    BSR         COMPARE_LOOP
    BEQ         UP_CHECK                    ; IF USER WANTS TO CHANGE GRAVITY TO CEILING
                                            ; THEN --> CHECK CURRENT COORDINATES   
    LEA         DOWN, A1                    ; FLOOR CHECK
    LEA         INPUT, A0
    BSR         COMPARE_LOOP
    BEQ         DOWN_CHECK

    LEA         RIGHT, A1                   ; RIGHT WALL CHECK
    LEA         INPUT, A0
    BSR         COMPARE_LOOP
    BEQ         RIGHT_CHECK
    
    LEA         LEFT, A1                    ; LEFT WALL CHECK
    LEA         INPUT, A0
    BSR         COMPARE_LOOP
    BEQ         LEFT_CHECK
     
    BRA         WRONG_SHIFT                 ; Wrong input handler
                                            ;FINAL GRAVITY SETTERS   
SET_UP:
    MOVE.B      #1, D0                      ; CHANGE COORDINATES TO CEILING 
    MOVE.B      #1, D1
    MOVE.B      D0, PLAYERS_X
    MOVE.B      D1, PLAYERS_Y

    RTS 
SET_DOWN:
    MOVE.B      #0, D0                      ; CHANGE COORDINATES TO FLOOR
    MOVE.B      #0, D1
    MOVE.B      D0, PLAYERS_X
    MOVE.B      D1, PLAYERS_Y
    
    RTS 
SET_RIGHT:
    MOVE.B      #0, D0                      ; CHANGE COORDINATES TO RIGHT WALL
    MOVE.B      #1, D1
    MOVE.B      D0, PLAYERS_X
    MOVE.B      D1, PLAYERS_Y
    
    RTS 
SET_LEFT:
    MOVE.B      #1, D0                      ; CHANGE COORDINATES TO LEFT WALL
    MOVE.B      #0, D1
    MOVE.B      D0, PLAYERS_X
    MOVE.B      D1, PLAYERS_Y
    
    RTS 
                                            ; COORDINATES CHECKERS
UP_CHECK:
    MOVE.B      PLAYERS_X, D0
    CMPI.B      #0, D0         
    BNE         SOLID_UP_CHECK    
    
    MOVE.B      PLAYERS_Y, D0
    CMPI.B      #0, D0
    BEQ         UP_CONFIRMED                ; IF CURRENT COORDINATES ARE THE CEILING THEN 
                                            ; TAKE NO DAMAGE AND DISPLAY USER IS ALREADY THERE THEN RETURN
    BRA         SOLID_UP_CHECK              
DOWN_CHECK:
    MOVE.B      PLAYERS_X, D0
    CMPI.B      #1, D0
    BNE         SOLID_DOWN_CHECK    
    
    MOVE.B      PLAYERS_Y, D0
    CMPI.B      #1, D0
    BEQ         DOWN_CONFIRMED
                                            ; IF CURRENT COORDINATES ARE THE CEILING THEN 
    BRA         SOLID_DOWN_CHECK            ; TAKE NO DAMAGE AND DISPLAY USER IS ALREADY THERE THEN RETURN
RIGHT_CHECK:
    MOVE.B      PLAYERS_X, D0
    CMPI.B      #1, D0
    BNE         SOLID_RIGHT_CHECK     
    
    MOVE.B      PLAYERS_Y, D0
    CMPI.B      #0, D0
    BEQ         RIGHT_CONFIRMED
                                            ; IF CURRENT COORDINATES ARE THE CEILING THEN 
    BRA         SOLID_RIGHT_CHECK           ; TAKE NO DAMAGE AND DISPLAY USER IS ALREADY THERE THEN RETURN
LEFT_CHECK:
    MOVE.B      PLAYERS_X, D0
    CMPI.B      #0, D0
    BNE         SOLID_LEFT_CHECK          
    
    MOVE.B      PLAYERS_Y, D0
    CMPI.B      #1, D0
    BEQ         LEFT_CONFIRMED
                                            ; IF CURRENT COORDINATES ARE THE CEILING THEN
    BRA         SOLID_LEFT_CHECK            ; TAKE NO DAMAGE AND DISPLAY USER IS ALREADY THERE THEN RETURN
                                            ;======SOLID CHECKERS======
SOLID_LEFT_CHECK:
    LEA         LEFT, A1                    ; LEFT WALL CHECK
    LEA         INPUT, A0
    BSR         COMPARE_LOOP 
    BEQ         SET_LEFT

    RTS
SOLID_RIGHT_CHECK:
    LEA         RIGHT, A1                   ; RIGHT WALL CHECK
    LEA         INPUT, A0
    BSR         COMPARE_LOOP 
    BEQ         SET_RIGHT

    RTS
SOLID_DOWN_CHECK:
    LEA         DOWN, A1                    ; FLOOR CHECK
    LEA         INPUT, A0
    BSR         COMPARE_LOOP 
    BEQ         SET_DOWN

    RTS
SOLID_UP_CHECK:
    LEA         UP, A1                      ; CEILING CHECK
    LEA         INPUT, A0
    BSR         COMPARE_LOOP 
    BEQ         SET_UP

    RTS
                                            ;IF FALL IS MORE THAN HALF OF THE ROOM, TAKE DAMAGE ROUTINES
DOWN_CONFIRMED:
    BSR         SET_DOWN
    BSR         FALLING_EFFECT
    BSR         DELAY_ROUTINE
    
    BSR         FALL_DMG 
    
    RTS
RIGHT_CONFIRMED:
    BSR         SET_RIGHT
    BSR         FALLING_EFFECT
    BSR         DELAY_ROUTINE
    
    BSR         FALL_DMG 
    
    RTS
LEFT_CONFIRMED:
    BSR         SET_LEFT
    BSR         FALLING_EFFECT
    BSR         DELAY_ROUTINE
    
    BSR         FALL_DMG 
    
    RTS
UP_CONFIRMED:
    BSR         SET_UP
    BSR         FALLING_EFFECT
    BSR         DELAY_ROUTINE
    
    BSR         FALL_DMG 
    
    RTS
FALL_DMG:                                   ; TAKE FALL DAMAGE ROUTINE 
    MOVE.L      PLAYER_HEALTH, D0
    SUB.L       #20, D0
    MOVE.L      D0, PLAYER_HEALTH
    
    BSR         SPACE_FILL
    LEA         DMG_MSG, A1
    MOVE.B      #13, D0
    TRAP        #15
                                            
    BSR         HEALTH_CHECK                ; Check if player is still alive    
    BLE         NO_HEALTH_MSG               ; Branch if health is exactly 0
    
    RTS
*==============================Level Memory==============================
LOBBY_MEMORY:
    LEA         L_MEMORY, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    RTS
SH_MEMORY:
    LEA         L_MEMORY, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    RTS

FH_SDW_MEMORY:
    LEA         FH_MMR_SDWTRK, A1
    MOVE.B      #13, D0
    TRAP        #15
    BSR         DELAY_ROUTINE
    BSR         DELAY_ROUTINE
    
    RTS
CHEST_MEMORY:
    LEA         CHEST_M_MSG, A1
    MOVE.B      #13, D0
    TRAP        #15
    BSR         DELAY_ROUTINE
    BSR         DELAY_ROUTINE
    
    RTS
CHEST_T_MSG:
    LEA         CHEST_MSG, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    RTS
THINKING:
    LEA         THINKING_MSG, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    RTS
*================Start Levels=================
*====================LOBBY======================
LOBBY:
    BSR         MAIN_GAME_LOOP              ; Go to main game loop
    
    BSR         SPACE_FILL
    LEA         MOVING_MSG, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    BSR         DELAY_ROUTINE
    BSR         DELAY_ROUTINE
    BSR         SPACE_FILL

    LEA         OBSERVATION, A1
    MOVE.B      #13, D0
    TRAP        #15
 
    BSR         DELAY_ROUTINE
    BSR         DELAY_ROUTINE
    BSR         SPACE_FILL
LOBBY_GRAV_INPUT:
    LEA         GRAVITY_CHANGE, A1
    MOVE.B      #13, D0
    TRAP        #15

    BSR         CLEAR_INPUT                 ; Clear garbage
    LEA         INPUT, A1                   ; Load address of buffer into A1
    MOVE.B      #2, D0                      ; Task 2: Read string from keyboard
    TRAP        #15                         ; Execute task
    BSR         SPACE_FILL
    BSR         SHIFT_CHECK                 ; Take damage if shift gives long free fall
    BSR         INVERTER_MALFUNCTION
    
    LEA         INPUT, A0                   ; Reset A0 to start of input
    LEA         UP, A1                      ; A1 = "UP" constant 
    BSR         COMPARE_LOOP
    BEQ         FIRST_HALLWAY               ; Branch to the first lvel
    
    BSR         SPACE_FILL                  ; Display if lobby level is not completed
    BSR         LOBBY_MEMORY
    BSR         DELAY_ROUTINE
    BSR         DELAY_ROUTINE
    
    BRA         LOBBY
*=========================FIRST HALLWAY===========================
FIRST_HALLWAY:
    BSR         SPACE_FILL
    BSR         MAIN_GAME_LOOP              ; Go to main game loop
    LEA         HALLWAY_1, A1               ; Load First Hallway message
    MOVE.B      #13, D0
    TRAP        #15
    
FH_OPTION_INPUT:
    MOVE.B      #4,D0                       ; Take input from the player
    TRAP        #15          
    MOVE.B      D1,INPUT     
    
    CMPI.B      #1, INPUT
    BEQ         F_H_OPTION1 
    
    CMPI.B      #2, INPUT
    BEQ         F_H_OPTION2
    
    CMPI.B      #3, INPUT
    BEQ         F_H_OPTION3
    
    BSR         INVALID_OPTION              ; Display Invalid Option message
    BRA         FH_OPTION_INPUT     
F_H_OPTION1:                                ;SHADOW DOOR
    BSR         DELAY_ROUTINE
    BSR         SHADOW_DMG
    BSR         MAIN_GAME_LOOP
    BSR         DELAY_ROUTINE
    BSR         DELAY_ROUTINE
    BSR         FH_SDW_MEMORY
    BSR         DELAY_ROUTINE
SDW_INPUT:
    MOVE.B      #4,D0                       ; Take input from the player
    TRAP        #15          
    MOVE.B      D1,INPUT
    
    CMPI.B      #2, INPUT
    BEQ         F_H_OPTION2
    
    CMPI.B      #3, INPUT
    BEQ         SDW_F_H_OPTION3
    
    BSR         INVALID_OPTION
    BRA         SDW_INPUT
SDW_F_H_OPTION3:
    BSR         CHEST_TRAP
    BSR         CHEST_T_MSG
    BSR         DELAY_ROUTINE
    BSR         MAIN_GAME_LOOP
    BSR         DELAY_ROUTINE
    
    LEA         UNLUCKY_GUESS, A1
    MOVE.B      #13, D0
    TRAP        #15

    BSR         CONFIRM_MOVE
    BRA         F_H_OPTION2
    
F_H_OPTION2:                                ; BUSH OF NATURE
    LEA         NATURE_BUSH, A1
    MOVE.B      #13,D0
    TRAP        #15
    
    BSR         LUCKY_GUESS
    BSR         DELAY_ROUTINE
    BSR         DELAY_ROUTINE
    
    BRA         COMPLETE_FH
F_H_OPTION3:                                ; TRAP CHEST TO THE LEFT
    BSR         CHEST_TRAP
    BSR         CHEST_T_MSG
    BSR         DELAY_ROUTINE
    BSR         MAIN_GAME_LOOP
    BSR         DELAY_ROUTINE
    
    BSR         CHEST_MEMORY
F_H_OPTION3_INPUT:
    MOVE.B      #4,D0                       ; Take input from the player
    TRAP        #15          
    MOVE.B      D1,INPUT
    
    CMPI.B      #1, INPUT
    BEQ         CHEST_F_H_OPTION1
    
    CMPI.B      #2, INPUT
    BEQ         F_H_OPTION2
    
    BSR         INVALID_OPTION
    BRA         F_H_OPTION3_INPUT
CHEST_F_H_OPTION1:
    BSR         DELAY_ROUTINE
    BSR         SHADOW_DMG
    BSR         DELAY_ROUTINE
    BSR         MAIN_GAME_LOOP
    
    LEA         UNLUCKY_GUESS, A1
    MOVE.B      #13, D0
    TRAP        #15

    BSR         CONFIRM_MOVE
    BRA         F_H_OPTION2    
INVALID_OPTION:
    LEA         WRONG,             A1            
    MOVE.B      #13,               D0      
    TRAP        #15
    
    RTS
SHADOW_DMG:
    LEA         SHADOWS_TRICK, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    MOVE.L      PLAYER_HEALTH, D0
    SUB.L       #20, D0
    MOVE.L      D0, PLAYER_HEALTH
    
    RTS
CHEST_TRAP:
    MOVE.L      PLAYER_HEALTH, D0
    SUB.L       #20, D0
    MOVE.L      D0, PLAYER_HEALTH
    
    RTS
LUCKY_GUESS:
    MOVE.L      PLAYER_HEALTH, D0
    CMPI.L      #80, D0
    BGE         FULL_HEALTH
    
    ADD.L       #20, D0
    MOVE.L      D0, PLAYER_HEALTH
    BSR         DELAY_ROUTINE
    
    RTS
FULL_HEALTH:
    MOVE.L      #100, D3
    MOVE.L      D3, PLAYER_HEALTH
    BSR         DELAY_ROUTINE
    
    RTS
COMPLETE_FH:
    BRA         SECOND_HALLWAY
*=========================SECOND HALLWAY=============================
SECOND_HALLWAY:
    BSR         SET_DOWN                    ;MYSTERIOUS CHANGE OF GRAVITY ON ENTRANCE TO THE SH
    BSR         MAIN_GAME_LOOP
    BSR         DELAY_ROUTINE
    LEA         HALLWAY_2, A1               ;DISPLAY MSG OF SH
    MOVE.B      #13, D0
    TRAP        #15
    BSR         DELAY_ROUTINE
    BSR         DELAY_ROUTINE
    BSR         SPACE_FILL
SH_INPUT:
    BSR         CLEAR_INPUT                 ; Clear garbage
    LEA         INPUT, A1                   ; Load address of buffer into A1
    MOVE.B      #2, D0                      ; Task 2: Read string from keyboard
    TRAP        #15                         ; Execute task
                       
    LEA         INPUT, A0           
    LEA         GO, A1               
    BSR         COMPARE_LOOP                ; Check if input is exactly "GO"
    BEQ         ABYSS_WALKER
    
    LEA         INPUT, A0           
    LEA         SHIFT, A1           
    BSR         COMPARE_LOOP                ; Check if input is exactly "SHIFT"
    BEQ         SH_SHIFT
    
    BSR         INVALID_OPTION
    BRA         SH_INPUT                    ; IF INPUT IS WRONG, GO TO INPUT AGAIN
ABYSS_WALKER:
    LEA         ABYSS_ACHVMT, A1            ; ACHIVEMENT IF PLAYER GOES HERE
    MOVE.B      #13, D0
    TRAP        #15

    LEA         STEP_INTO_ABYSS, A1         ; UNFORTUNATE ENDING MESSAGE
    MOVE.B      #13, D0
    TRAP        #15
        
    BRA         GAME_END                    ; GAME OVER ROUTINE
SH_SHIFT:
    LEA         GRAVITY_CHANGE, A1
    MOVE.B      #13, D0
    TRAP        #15

    BSR         CLEAR_INPUT                 ; Clear garbage
    LEA         INPUT, A1                   ; Load address of buffer into A1
    MOVE.B      #2, D0                      ; Task 2: Read string from keyboard
    TRAP        #15                         ; Execute task
    BSR         SPACE_FILL
    BSR         SHIFT_CHECK
    BSR         INVERTER_MALFUNCTION
    
    LEA         INPUT, A0                   ; Reset A0 to start of input
    LEA         LEFT, A1              
    BSR         COMPARE_LOOP
    BEQ         SH_LEFT_WALL
    
    BSR         SH_MEMORY
    BRA         SH_SHIFT
SH_LEFT_WALL:
    BSR         SH_AHEAD
    
    BRA         MYSTERY_ROOM_THIRD
SH_AHEAD:   
    LEA         SH_GO_AHEAD, A1
    MOVE.B      #13, D0
    TRAP        #15      
    BSR         CONFIRM_MOVE
    
    RTS
*=========================MYSTERY HALLWAY=============================
MYSTERY_ROOM_THIRD:
    LEA         SH_MYSTERY, A1
    MOVE.B      #13, D0
    TRAP        #15

    BSR         CONFIRM_MOVE

    LEA         VOICE_FROM, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    BSR         CONFIRM_MOVE
    
    LEA         THE_MIRROR_DOOR, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    BSR         CONFIRM_MOVE
    
    LEA         THE_IRON_GRATE, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    BSR         CONFIRM_MOVE
    
    LEA         THE_EMPTY_PDSTL, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    BSR         CONFIRM_MOVE
    
    LEA         SCRATCHED_HINT, A1          ; Output a hint
    MOVE.B      #13, D0
    TRAP        #15
FINAL_STAND_INPUT:
    LEA         CHOICES, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    BSR         CLEAR_INPUT                 ; Clear garbage
    LEA         INPUT, A1                   ; Load address of buffer into A1
    MOVE.B      #2, D0                      ; Task 2: Read string from keyboard
    TRAP        #15                         ; Execute task
    
* CHOICE RESOLUTION (REFLECTION, TRANSPARENCY, PROJECTION)
    LEA         INPUT, A0                   ; Reset A0 to start of input
    LEA         REFLECTION, A1              ; A1 - constant 
    BSR         COMPARE_LOOP
    BEQ         MIRROR_DOOR
    
    LEA         INPUT, A0                   ; Reset A0 to start of input
    LEA         TRANSPARENCY, A1            ; A1 - constant 
    BSR         COMPARE_LOOP
    BEQ         DUNGEON_EXIT
    
    LEA         INPUT, A0                   ; Reset A0 to start of input
    LEA         PROJECTION, A1              ; A1 - constant 
    BSR         COMPARE_LOOP
    BEQ         PROJECTION_WINDOW
    
    BSR         SPACE_FILL
    BSR         THINKING
    BSR         SPACE_FILL
    BRA         FINAL_STAND_INPUT           ;control branching
PROJECTION_WINDOW:
    BSR         SPACE_FILL         
    LEA         PROJECTION_MSG, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    BSR         DELAY_ROUTINE               ; Delay 
    BSR         DELAY_ROUTINE
    BSR         DELAY_ROUTINE               
    BSR         DELAY_ROUTINE
    
    
    BRA         GAME_END
MIRROR_DOOR:
    BSR         SPACE_FILL
    LEA         MIRROR_MSG, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    BSR         DELAY_ROUTINE               ; Delay 
    BSR         DELAY_ROUTINE
    BSR         DELAY_ROUTINE               
    BSR         DELAY_ROUTINE
    
    BRA         GAME_END
DUNGEON_EXIT:
    BSR         SPACE_FILL
    LEA         EXIT_MSG, A1
    MOVE.B      #13, D0
    TRAP        #15
    
    BSR         DELAY_ROUTINE               ; Delay 
    BSR         DELAY_ROUTINE
    BSR         DELAY_ROUTINE               
    BSR         DELAY_ROUTINE
    
    BRA         WIN
*==========ENDING SCRIPT==========
GAME_END:
    LEA         GAME_END_MSG,       A1            
    MOVE.B      #13,                D0      ; Task 13 
    TRAP        #15  
WIN:
    SIMHALT                                 ; halt simulator

            *===============*
            *== CONSTANTS ==*
            *== ======== ===*
PLAYERS_X       DC.B    0
PLAYERS_Y       DC.B    0
PLAYER_HEALTH   DC.L    $64
COUNTER         DC.L    200
            *==============*
            *== MESSAGES ==*
            *== ======== ==*
MOVING_MSG      DC.B    '*you move forward to the dead end and get confused for a minute*',0
DMG_MSG         DC.B    'FALLING DAMAGE TAKEN, BE CAREFULL!',0
NO_HEALTH       DC.B    'You run out of HP points!',0  
GO              DC.B    'GO',0
SHIFT           DC.B    'SHIFT',0
UP              DC.B    'UP',0      
DOWN            DC.B    'DOWN',0 
RIGHT           DC.B    'RIGHT',0 
LEFT            DC.B    'LEFT',0 
PROCEED         DC.B    'TYPE YES TO CONTINUE!',0
OPENDROP        DC.B    'TYPE YES TO OPEN!',0
GRAVITY_CHANGE  DC.B    'DIRECTION TO SHIFT? (UP/DOWN/LEFT/RIGHT)',0   
RIGHT_WALL      DC.B    'YOUR GRAVITY SHIFTED TO THE RIGHT WALL',0
LEFT_WALL       DC.B    'YOUR GRAVITY SHIFTED TO THE LEFT WALL',0
CEILING         DC.B    'YOU ARE ON THE CEILING',0
OPENING         DC.B    '======....OPENING....======',0
FLOOR           DC.B    'NORMAL GRAVITY',0
FALLING         DC.B    '===== FALLING... =====',0
GAME_END_MSG    DC.B    'NICE GAME ADVENTURER, THE GAME IS OVER!',0
WELCOME_MSG     DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    'WELCOME ADVENTURER!'
                DC.B    $0D,$0A
                DC.B    'YOU GOT STUCK IN A GRAVITY DUNGEON!'
                DC.B    $0D,$0A
                DC.B    'WOULD YOU LIKE TO KNOW WHAT TO DO NEXT?(YES/NO)'
                DC.B    $0D,$0A
                DC.B    '************************************************************'
                DC.B    $0D,$0A,0

INSTRUCTION_MSG DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    'YOU HAVE TO GET OUT OF THE GRAVITY DUNGEON!'
                DC.B    $0D,$0A
                DC.B    '************************************************************'
                DC.B    $0D,$0A,0
                
L_MEMORY        DC.B    '*****************************************************************'
                DC.B    $0D,$0A
                DC.B    'The gravity may have changed, but you are still in the same place'
                DC.B    $0D,$0A
                DC.B    'So you start to remember what happened before...'
                DC.B    $0D,$0A
                DC.B    '*****************************************************************'
                DC.B    $0D,$0A,0
GRAV_EXCEPTION  DC.B    'THIS GRAVITY IS ALREADY SET, CONTINUE',0
INPUT           DS.B    82
SPACE           DC.B    '',0
X_MSG           DC.B    'COORDINATE X: ',0
Y_MSG           DC.B    'COORDINATE Y: ',0
WRONG           DC.B    'THAT OPTION WAS NOT GIVEN BUDDY!',0
WAIT_SOME       DC.B    'WELL THATS UP TO YOU TO GET GOING OR SIT STILL!',0
YES             DC.B    'YES',0
NO              DC.B    'NO',0
MAYBE           DC.B    'MAYBE',0
WHY_NO          DC.B    'THATS NOT AN OPTION ADVENTURER, UNLESS YOU WANT TO BE STUCK HERE FOREVER!',0
GOOD_CHOICE     DC.B    'GOOD CHOICE SOLDIER! NOW, LETS START!',0
NOTE_PICK       DC.B    'You have picked up a Gravity Inverter! NOW YOU CAN CONTROL GRAVITY!',0
OBSERVATION     DC.B    'DEAD END HAS A WAY OUT! YOU SEE A DOOR IN THE CEILING!',0 
STATUS          DC.B    'HEALTH STATUS BAR: ',0
LOADING_MSG     DC.B    '============ LOADING.... ============',0
DROP_MSG        DC.B    'YOU HAVE A SUPPLY DROP NEARBY!',0
MALFUNCTION     DC.B    'OOPS, INVERTER MALFUNCTION - Electrical shortcut! You have been shocked -5HP!',0
*================================HALLWAYS======================================
START_PATH      DC.B    'YOU HAVE SPAWNED IN A SMALL HALLWAY ARC THAT GOES INTO A DEAD END',0

*=======HALLWAY 1=========
HALLWAY_1       DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    'NOW THAT YOU HAVE REACHED THE FIRST HALLWAY, YOU GO FURTHER AND SEE...'
                DC.B    $0D,$0A
                DC.B    '1. A DOOR COVERED IN SHADOWS UP AHEAD,'
                DC.B    $0D,$0A
                DC.B    '2. A BIG BUSH TO YOUR RIGHT (A SECRET WAY OUT.. OR NATURES WILL?),'
                DC.B    $0D,$0A
                DC.B    '3. A CHEST TO YOUR LEFT(COULD THERE BE TREASURES INSIDE.. OR TRAPS?)'
                DC.B    $0D,$0A
                DC.B    '************************************************************'
                DC.B    $0D,$0A,0

NATURE_BUSH     DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    'NATURES BUSH IT WAS!'
                DC.B    $0D,$0A
                DC.B    '*you start going through the bush and feel something on the ground*'
                DC.B    $0D,$0A
                DC.B    '*you pick up something similiar to a spiral glass bottle*'
                DC.B    $0D,$0A
                DC.B    'Thats a heal potion! +20 to hp! And this is a way out, is it luck?!'
                DC.B    $0D,$0A
                DC.B    '************************************************************'
                DC.B    $0D,$0A,0

SHADOWS_TRICK   DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    'As you approaching the door, shadows grow sicker..'
                DC.B    $0D,$0A
                DC.B    'You start to lose control of yourself and lose conscious!'
                DC.B    $0D,$0A
                DC.B    'A headache woke you up, losing 20 hp to the shadows, door has disappeared!'
                DC.B    $0D,$0A
                DC.B    '************************************************************'
                DC.B    $0D,$0A,0
FH_MMR_SDWTRK   DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    'Memory of what happend returns, you realize there are only 2 choices left'
                DC.B    $0D,$0A
                DC.B    '2. A BIG BUSH TO YOUR RIGHT (A SECRET WAY OUT.. OR NATURES WILL?),'
                DC.B    $0D,$0A
                DC.B    '3. A CHEST TO YOUR LEFT(COULD THERE BE TREASURES INSIDE.. OR TRAPS?)'
                DC.B    $0D,$0A
                DC.B    '************************************************************'
                DC.B    $0D,$0A,0
CHEST_M_MSG     DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    'Memory of what happend returns, you realize there are only 2 choices left'
                DC.B    $0D,$0A
                DC.B    '1. A DOOR COVERED IN SHADOWS UP AHEAD,'
                DC.B    $0D,$0A
                DC.B    '2. A BIG BUSH TO YOUR RIGHT (A SECRET WAY OUT.. OR NATURES WILL?),'
                DC.B    $0D,$0A
                DC.B    '************************************************************'
                DC.B    $0D,$0A,0
UNLUCKY_GUESS   DC.B    'Those are unlucky choices, but its over now! Shall you continue? ',0
CHEST_MSG       DC.B    'You thought that there will be treasures inside but instead...'
                DC.B    $0D,$0A
                DC.B    'As chest slowly opens, you see big sharp teeth of a chest pointed at you!'
                DC.B    $0D,$0A
                DC.B    'It was a mimic after all! It bit you and you lost 20 hp!'
                DC.B    $0D,$0A,0
ABYSS_ACHVMT    DC.B    'NEW ACHIVEMENT - Abyss Walker!',0

*======HALLWAY 1 END========
STEP_INTO_ABYSS DC.B    'You stepped into the Tartarus abyss, from where nobody returned..'
                DC.B    $0D,$0A
                DC.B    'Curiosity killed the rabbit! You have not came back, unfotrunate ending!'
                DC.B    $0D,$0A,0

*=======HALLWAY 2=========

HALLWAY_2       DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    'As you move through the bush, on the exit new puzzle takes place!'
                DC.B    $0D,$0A
                DC.B    'Gravity mysteriously changed to floor as soon as you walked through the bush'
                DC.B    $0D,$0A
                DC.B    'No falling damage was taken with the side effect of healing potion used before!'
                DC.B    $0D,$0A
                DC.B    'You see no floor ahead, a pit marked by a small label...'
                DC.B    $0D,$0A
                DC.B    '#A pit to Tartarus, no return beyond this point#'
                DC.B    $0D,$0A
                DC.B    'A door is high up on the left wall...'
                DC.B    $0D,$0A
                DC.B    'What are you going to do? (go forward - GO, shift gravity - SHIFT)'
                DC.B    $0D,$0A,0    
SH_GO_AHEAD     DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    'You are moving closer to the door high up on the left wall...'
                DC.B    $0D,$0A
                DC.B    'Door opens and you walk inside a strange room, compared to the dungeon...'
                DC.B    $0D,$0A
                DC.B    'A sign that says like you are #One door away from the surface!#...'
                DC.B    $0D,$0A
                DC.B    'Its not that you trust something that looks like a joke!'
                DC.B    $0D,$0A
                DC.B    '************************************************************'
                DC.B    $0D,$0A,0
    
*=======HALLWAY 2 END=========
*=======MYSTERY HALLWAY=======
SH_MYSTERY      DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    'The damp replaced instantly by the scent of ozone and ancient parchment.'
                DC.B    $0D,$0A
                DC.B    'You step into a room that shouldnt exist: a perfect cube of white marble,'
                DC.B    $0D,$0A
                DC.B    'humming with a low, vibrational frequency that you feel in your teeth.'
                DC.B    $0D,$0A
                DC.B    'The center of the room holds three pedestals, '
                DC.B    $0D,$0A
                DC.B    'each supporting a different method of departure.'
                DC.B    $0D,$0A,0
VOICE_FROM      DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    'A voice echoes from the walls:'
                DC.B    $0D,$0A
                DC.B    'The path to the sun is not bought with gold, but with the weight '
                DC.B    $0D,$0A
                DC.B    'of your own perspective. Choose the door that leads home; choose poorly,'
                DC.B    $0D,$0A
                DC.B    'and become the floor you stand upon.'
                DC.B    $0D,$0A,0
THE_MIRROR_DOOR DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    '1. The Mirror Door (The Reflection)'
                DC.B    $0D,$0A
                DC.B    'To your left stands a door frame made of silver.'
                DC.B    $0D,$0A
                DC.B    'There is no wood or stone — only a shimmering vertical pool of liquid mercury.'
                DC.B    $0D,$0A
                DC.B    'When you look into it, you dont see the marble room.'
                DC.B    $0D,$0A
                DC.B    'You see yourself exactly as you were before you entered this dungeon:'
                DC.B    $0D,$0A
                DC.B    'clean, rested, and oblivious.'
                DC.B    $0D,$0A,0
THE_IRON_GRATE  DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    '2. The Iron Grate (The Transparency)'
                DC.B    $0D,$0A
                DC.B    'In the center, a heavy iron grate is set into the floor, looking down '
                DC.B    $0D,$0A
                DC.B    'into a terrifyingly bright abyss of pure white light.'
                DC.B    $0D,$0A
                DC.B    'Beside it lies a key made of thin, fragile glass.'
                DC.B    $0D,$0A
                DC.B    'To open the grate, you must turn the key with enough force to engage'
                DC.B    $0D,$0A
                DC.B    'the heavy iron mechanism, but not so much that the glass shatters.'
                DC.B    $0D,$0A,0
THE_EMPTY_PDSTL DC.B    '************************************************************'
                DC.B    $0D,$0A
                DC.B    '3. The Empty Pedestal (The Projection)'
                DC.B    $0D,$0A
                DC.B    'To the right is a stone pedestal with nothing on it.'
                DC.B    $0D,$0A
                DC.B    'However, when you stand before it, a small window opens in the wall above.'
                DC.B    $0D,$0A
                DC.B    'It shows a view of a mundane, muddy field outside the dungeon'
                DC.B    $0D,$0A
                DC.B    'the very definition of "the surface".'
                DC.B    $0D,$0A
                DC.B    'There is no door, no key, and no way to reach the window.'
                DC.B    $0D,$0A                
                DC.B    '************************************************************'
                DC.B    $0D,$0A,0
SCRATCHED_HINT  DC.B    'If you look closely at the floor, you notice inscriptions in ancient script:'
                DC.B    $0D,$0A
                DC.B    '"The coward seeks the man he used to be."'
                DC.B    $0D,$0A
                DC.B    '"The fool follows his eyes into a frame."'
                DC.B    $0D,$0A
                DC.B    '"The hero knows that to reach the sky, one must first survive the break."'
                DC.B    $0D,$0A,0
MIRROR_MSG      DC.B    'You step through and find yourself back home, but you are a ghost.'
                DC.B    $0D,$0A
                DC.B    'You have "returned" to your old life by erasing everything'
                DC.B    $0D,$0A
                DC.B    'you did in the dungeon — including your physical body.'
                DC.B    $0D,$0A
                DC.B    'You are safe, but you have lost your soul to the mirror.'
                DC.B    $0D,$0A
                DC.B    'You remain in the room as a reflection for the next traveler to see.'
                DC.B    $0D,$0A,0
PROJECTION_MSG  DC.B    'The window is not a window - it is a painting.'
                DC.B    $0D,$0A
                DC.B    'The more you stare at the "surface," the more your body'
                DC.B    $0D,$0A
                DC.B    'begins to turn into the same white marble as the room.'
                DC.B    $0D,$0A
                DC.B    'By choosing to watch a world you cannot reach instead of taking a risk,'
                DC.B    $0D,$0A
                DC.B    'you become a permanent fixture of the room'
                DC.B    $0D,$0A
                DC.B    '— a statue of a traveler looking at a fake sky.'
                DC.B    $0D,$0A,0

THINKING_MSG    DC.B    'Take your time you are not in a rush, choose wisely...',0
CHOICES         DC.B    'What choice do you want to make? (REFLECTION, TRANSPARENCY, PROJECTION)',0
REFLECTION      DC.B    'REFLECTION',0
TRANSPARENCY    DC.B    'TRANSPARENCY',0
PROJECTION      DC.B    'PROJECTION',0
*==========END OF THE MYSTERY HALLWAY===========
*==========EXIT DOOR, GAME FINISHED=============
EXIT_MSG        DC.B    'The key shatters as the lock clicks. The iron grate dissolves'
                DC.B    $0D,$0A
                DC.B    'into liquid light, and you plummet into the abyss.'
                DC.B    $0D,$0A
                DC.B    'Instead of hitting the floor, you gasp as you break the surface of a forest pond,'
                DC.B    $0D,$0A
                DC.B    'the real sun finally stinging your eyes.'
                DC.B    $0D,$0A
                DC.B    'You are free.'
                DC.B    $0D,$0A,0
      *==========END OF EXIT==========
    END    START







*~Font name~Courier New~
*~Font size~14~
*~Tab type~1~
*~Tab size~4~
