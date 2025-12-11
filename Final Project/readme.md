# CPE 487 Final Project: The Stealth Game

## Project Description
**Objective:**
This project transforms the classic "Pong" lab into a top-down **Stealth Survival Game**. Instead of controlling a paddle to hit a ball, the user controls a "Spy" (cyan square) who must navigate a complex, maze-like arena and hide behind obstacles to avoid being caught by the patrolling "Guard" (red square).

**Core Gameplay Loop:**
1.  **The Arena:** The game takes place inside a fortified compound filled with 9 distinct collision objects. This "Maze" forces the player to navigate through narrow choke points while breaking the enemy's line of sight.
2.  **Survival:** The player must use the 4-directional buttons to evade the Guard. The obstacles provide cover—if the Guard hits a wall, it bounces away, allowing the player to hide on the opposite side.
3.  **The Hunter AI:** The Guard features an active tracking algorithm. Every 20 frames (approx. 0.33 seconds), it re-evaluates the player's position and adjusts its trajectory to intercept them.
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
This project builds upon the foundational **Lab 6 (Pong)** but introduces substantial changes to satisfy the "Modifications" requirement.

### 1. From 1D Paddle to 2D Player Controller
* **Original:** The bat was constrained to the bottom row (`bat_y` was a constant) and could only move Left/Right.
* **Modification:** We converted `bat_x` and `bat_y` into dynamic signals controlled by a custom process `move_player`.
* **Tuning:** The player speed was increased to **5 pixels/frame** (up from 4) to balance the difficulty against the aggressive new AI.

### 2. The Complex Maze Architecture
* **Original:** The game world was an empty void with simple edge boundaries.
* **Modification:** We implemented a "Map System" defining **9 distinct collision objects** using AABB (Axis-Aligned Bounding Box) logic:
    * **Outer Shell:** Four thick border walls enclosing the play area (Walls 1-4).
    * **Central Hub:** A large rectangular pillar in the center (Safe zone).
    * **Tactical Obstacles:** Four floating walls added to create dead ends and cover:
        * **Wall 5 (Top-Left) & Wall 6 (Bottom-Right):** Horizontal bars that force vertical movement.
        * **Wall 7 (Bottom-Left) & Wall 8 (Top-Right):** Vertical pillars that force lateral movement.
* **Rendering:** A priority encoding system determines pixel color: `Obstacle (Black) > Enemy (Red) > Player (Cyan) > Background (White)`.

> *Figure 3: The game screen showing the complex arena. Note the Cyan Player hiding behind one of the new vertical pillars (Wall 7).*

### 3. Aggressive AI Tracking Implementation
* **Original:** The ball moved in a straight line and only changed direction when hitting a wall.
* **Modification:** We implemented a "Hunter" algorithm using a frame timer.
    * **Logic:** `IF timer < 20 THEN increment ELSE update_direction`.
    * **Behavior:** Every **20 frames** (approx. 0.33s), the enemy reads the player's coordinate signals and alters its velocity vectors to move directly toward the player.
    * **Difficulty:** This is significantly faster than standard "lazy" tracking (usually 60 frames), creating a high-tension chase experience.

## Summary of the Process
* **Team Member 1:** Responsible for the initial `pong.vhd` cleanup and mapping the 4-button inputs in the constraints file.
* **Team Member 2:** Implemented the `move_player` logic and tuned the player speed to `5` to ensure the game was winnable.
* **Team Member 3:** Designed the complex level layout, defining the coordinate constants for all 9 obstacles and implementing the priority collision logic that ensures the AI respects walls even while hunting the player.
* **Challenges:**
    * *Issue:* The aggressive AI would sometimes clip through corners.
    * *Solution:* We strictly prioritized the Wall Collision logic *after* the AI movement update in the VHDL process. This ensures that even if the AI tries to force a move through a wall, the physics engine overrides it and forces a bounce.
