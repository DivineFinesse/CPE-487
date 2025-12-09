# CPE 487 Final Project: The Stealth Game

## Project Description
**Objective:**
This project transforms the classic "Pong" lab into a top-down **Stealth Survival Game**. Instead of controlling a paddle to hit a ball, the user controls a "Spy" (cyan square) who must navigate a constrained arena and hide behind obstacles to avoid being caught by the patrolling "Guard" (red square).

**Core Gameplay Loop:**
1.  **The Arena:** The game takes place inside a walled compound. There are thick borders on all four sides and a central pillar (obstacle) in the middle of the room.
2.  **Survival:** The player must use the 4-directional buttons to evade the Guard. The central pillar provides cover—if the Guard hits the pillar, it bounces away, allowing the player to hide on the opposite side.
3.  **The Enemy AI:** The Guard is not just a bouncing ball. It features a "Lazy Tracking" algorithm. Every second (approx. 60 frames), it re-evaluates the player's position and adjusts its trajectory to intercept them.
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
* `btnU` (Up), `btnD` (Down), `btnL` (Left), `btnR` (Right): Controls the Spy's movement in 2D space.
* `btn0` (Center): Serves/Starts the game (activates the Guard).

**Outputs (Visuals):**
* `VGA_red`, `VGA_green`, `VGA_blue`: RGB color signals driving the monitor.
* `VGA_hsync`, `VGA_vsync`: Synchronization signals for 60Hz display.
* `SEG7_anode`, `SEG7_seg`: Displays debug information or "0000".

> *Figure 2: The physical setup showing the FPGA board and button layout.*

## Modifications
This project builds upon the foundational **Lab 6 (Pong)** but introduces substantial changes to the physics engine, rendering pipeline, and gameplay logic.

### 1. From 1D Paddle to 2D Player Controller
* **Original:** The bat was constrained to the bottom row (`bat_y` was a constant) and could only move Left/Right.
* **Modification:** We converted `bat_x` and `bat_y` into dynamic signals. A new process `move_player` was implemented to read four distinct button inputs and update the coordinates, effectively creating a top-down character controller.

### 2. Static Environment (The Maze)
* **Original:** The game world was an empty void with boundaries only at the very edges of the screen (0 and 800/600).
* **Modification:** We implemented a custom map definition using constant integers.
    * **Central Pillar:** A rectangular obstacle in the middle of the screen (X: 375-425, Y: 200-400).
    * **Border Walls:** Four thick walls enclosing the play area, effectively shrinking the playable space and creating "corners" for the player to get trapped in.
* **Rendering:** A priority encoding system determines pixel color: `Wall (Black) > Ball (Red) > Player (Cyan) > Background (White)`.

> *Figure 3: The game screen. Note the Cyan Player (Spy), Red Enemy (Guard), the Black Central Pillar, and the thick border walls.*

### 3. AI Tracking Implementation
* **Original:** The ball moved in a straight line and only changed direction when hitting a wall.
* **Modification:** We implemented a "Lazy Tracking" algorithm.
    * A timer counts up to 60 frames (1 second).
    * When the timer triggers, the ball compares its `ball_x/y` to the player's `bat_x/y`.
    * The ball alters its velocity vectors (`ball_x_motion`, `ball_y_motion`) to move toward the player.
    * **Result:** The enemy actively hunts the player rather than bouncing randomly.

## Summary of the Process
* **Team Member 1:** Responsible for the initial `pong.vhd` cleanup and mapping the 4-button inputs in the constraints file.
* **Team Member 2:** Implemented the `move_player` logic in VHDL and the 2D coordinate system for the "Spy."
* **Team Member 3:** Designed the "Wall" logic and the AI tracking algorithm.
* **Challenges:**
    * *Issue:* The Guard would get stuck inside the new border walls.
    * *Solution:* We adjusted the collision bounds to check the *next* position rather than the current position, ensuring the bounce happens *before* overlap occurs.
    * *Issue:* The AI was too difficult to beat.
    * *Solution:* We added the "Lazy" timer so the AI only updates its path once per second, giving the player time to dodge.
