# CPE 487 Final Project: The Stealth Game

## Project Description
**Objective:**
This project transforms the classic "Pong" lab into a top-down **Stealth Survival Game**. Instead of controlling a paddle to hit a ball, the user controls a "Spy" (cyan square) who must navigate a room and hide behind obstacles to avoid being caught by the patrolling "Guard" (red square).

**Core Gameplay Loop:**
1.  **Idle State:** The game begins with the Spy and Guard in neutral positions. The player can move freely to position themselves.
2.  **Active State:** Upon pressing the `Start` button, the Guard begins patrolling the room, bouncing off walls and the central pillar.
3.  **Survival:** The player must use the 4-directional buttons to evade the Guard. The central pillar provides cover—if the Guard hits the pillar, it bounces away, allowing the player to hide on the opposite side.
4.  **Game Over:** If the Guard touches the Spy, the game immediately resets (Capture).

**High-Level System Architecture:**
The system is built upon the `pong.vhd` top-level entity, which coordinates the VGA timing and game logic modules.

> *Figure 1: High-level block diagram showing the data flow between the Clock Divider, VGA Sync Generator, and the Game Logic (Bat_N_Ball) module.*



## Steps to Run the Project
To reproduce this project on a Nexys A7-100T FPGA board:

1.  **Create Project:** Open Vivado and create a new project targeting the `xc7a100tcsg324-1` part.
2.  **Add Sources:** Import the following VHDL files:
    * `pong.vhd` (Top Level)
    * `bat_n_ball.vhd` (Game Logic & Rendering)
    * `vga_sync.vhd` (VGA Timing)
    * `clk_wiz_0.vhd` / `clk_wiz_0_clk_wiz.vhd` (Clock Management)
    * `leddec16.vhd` (7-Segment Display Decoder)
3.  **Add Constraints:** Import the `pong.xdc` file. **Crucial:** Ensure the button mappings in the `.xdc` file (`btnU`, `btnD`, `btnL`, `btnR`) match the entity ports in `pong.vhd` exactly.
4.  **Generate Bitstream:** Run Synthesis, Implementation, and Generate Bitstream.
5.  **Program Device:** Connect the Nexys board via USB, open the Hardware Manager, and program the device with the generated `.bit` file.
6.  **Connect Hardware:** Connect a VGA monitor to the VGA port on the Nexys board.

## Inputs and Outputs
**Inputs (Controls):**
* `clk_in`: 100MHz System Clock.
* `btnU` (Up), `btnD` (Down), `btnL` (Left), `btnR` (Right): **[NEW]** Controls the Spy's movement in 2D space.
* `btn0` (Center): Serves/Starts the game (activates the Guard).

**Outputs (Visuals):**
* `VGA_red`, `VGA_green`, `VGA_blue`: RGB color signals driving the monitor.
* `VGA_hsync`, `VGA_vsync`: Synchronization signals for 60Hz display.
* `SEG7_anode`, `SEG7_seg`: Displays the debug information or "0000".

> *Figure 2: The physical setup showing the FPGA board and button layout.*

## Modifications
This project builds upon the foundational **Lab 6 (Pong)** but introduces substantial changes to the physics engine, rendering pipeline, and gameplay logic.

### 1. From 1D Paddle to 2D Player Controller
* **Original:** The bat was constrained to the bottom row (`bat_y` was a constant) and could only move Left/Right.
* **Modification:** We converted `bat_x` and `bat_y` into dynamic signals. A new process `move_player` was implemented to read four distinct button inputs and update the coordinates, effectively creating a top-down character controller.
* **Code Snippet:**
    ```vhdl
    -- move_player process allows 2D movement
    IF btnU = '1' AND bat_y > (bat_h + player_speed) THEN
        bat_y <= bat_y - player_speed;
    END IF;
    -- (Logic repeated for Down, Left, Right)
    ```

### 2. Static Environment & Collision (The Maze)
* **Original:** The game world was an empty void.
* **Modification:** We introduced a "Wall" object (Central Pillar). The rendering logic now checks for coordinates within the wall's bounding box to draw it black. Crucially, both the **Player Movement** and **Enemy Physics** processes were updated to check collisions against this wall, preventing the player from walking through it and causing the enemy to bounce off it.

> *Figure 3: The game screen. Note the Cyan Player (Spy), Red Enemy (Guard), and the Black Central Pillar (Wall).*

### 3. "Capture" Logic vs. "Miss" Logic
* **Original:** Game Over occurred when the ball passed the paddle (Y > 500).
* **Modification:** We inverted this logic. The "Guard" (ball) never disappears off the bottom; it bounces off the bottom wall like any other wall. The "Game Over" state is triggered solely by an **AABB (Axis-Aligned Bounding Box) Collision** between the Guard and the Spy.
* **Modification Credit:** Logic derived from standard AABB collision principles adapted for VHDL integers.

## Summary of the Process
* **Team Member 1:** Responsible for the initial `pong.vhd` cleanup and mapping the 4-button inputs in the constraints file.
* **Team Member 2:** Implemented the `move_player` logic in VHDL and the 2D coordinate system for the "Spy."
* **Team Member 3:** Designed the "Wall" logic, adding the obstacle rendering and the complex bounce physics for the "Guard" to recognize the wall.
* **Challenges:**
    * *Issue:* The player controls initially didn't work.
    * *Solution:* We realized there was a mismatch between the `.xdc` file (using Uppercase `btnU`) and the VHDL file (using lowercase `btnu`). Correcting the case sensitivity in the constraints file resolved the critical warnings.
    * *Issue:* The Guard would get stuck inside the wall.
    * *Solution:* We adjusted the collision bounds to check the *next* position rather than the current position, ensuring the bounce happens *before* overlap occurs.
