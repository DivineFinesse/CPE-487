LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY bat_n_ball IS
    PORT (
        v_sync : IN STD_LOGIC;
        pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        btnU : IN STD_LOGIC;
        btnD : IN STD_LOGIC;
        btnL : IN STD_LOGIC;
        btnR : IN STD_LOGIC;
        serve : IN STD_LOGIC;
        red : OUT STD_LOGIC;
        green : OUT STD_LOGIC;
        blue : OUT STD_LOGIC;
        display : OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
    );
END bat_n_ball;

ARCHITECTURE Behavioral OF bat_n_ball IS
    CONSTANT bsize : INTEGER := 8; 
    CONSTANT bat_w : INTEGER := 10; 
    CONSTANT bat_h : INTEGER := 10; 
    CONSTANT player_speed : INTEGER := 5;
    
    -- Target Object Size
    CONSTANT goal_sz : INTEGER := 10;
    
    -- STATE MACHINE
    TYPE state_type IS (MENU, PLAY_EASY, PLAY_HARD, GAME_OVER);
    SIGNAL game_state : state_type := MENU;
    SIGNAL menu_selection : STD_LOGIC := '0'; -- '0' for Easy, '1' for Hard
    
    -- EDGE DETECTION
    SIGNAL serve_prev : STD_LOGIC := '0';

    -- OBSTACLE DEFINITIONS
    CONSTANT wall_x_l : INTEGER := 375; CONSTANT wall_x_r : INTEGER := 425;
    CONSTANT wall_y_t : INTEGER := 200; CONSTANT wall_y_b : INTEGER := 400;
 
    -- Outer Walls
    CONSTANT wall1_x_l : INTEGER := 0;   CONSTANT wall1_x_r : INTEGER := 800;
    CONSTANT wall1_y_t : INTEGER := 0;   CONSTANT wall1_y_b : INTEGER := 50;
    CONSTANT wall2_x_l : INTEGER := 0;   CONSTANT wall2_x_r : INTEGER := 800;
    CONSTANT wall2_y_t : INTEGER := 550; CONSTANT wall2_y_b : INTEGER := 600;
    CONSTANT wall3_x_l : INTEGER := 0;   CONSTANT wall3_x_r : INTEGER := 50;
    CONSTANT wall3_y_t : INTEGER := 0;   CONSTANT wall3_y_b : INTEGER := 600;
    CONSTANT wall4_x_l : INTEGER := 750; CONSTANT wall4_x_r : INTEGER := 800;
    CONSTANT wall4_y_t : INTEGER := 0;   CONSTANT wall4_y_b : INTEGER := 600;

    -- Maze Additions
    CONSTANT wall5_x_l : INTEGER := 150; CONSTANT wall5_x_r : INTEGER := 300;
    CONSTANT wall5_y_t : INTEGER := 100; CONSTANT wall5_y_b : INTEGER := 120;
    CONSTANT wall6_x_l : INTEGER := 500; CONSTANT wall6_x_r : INTEGER := 650;
    CONSTANT wall6_y_t : INTEGER := 430; CONSTANT wall6_y_b : INTEGER := 450;
    CONSTANT wall7_x_l : INTEGER := 150; CONSTANT wall7_x_r : INTEGER := 170;
    CONSTANT wall7_y_t : INTEGER := 350; CONSTANT wall7_y_b : INTEGER := 450;
    CONSTANT wall8_x_l : INTEGER := 630; CONSTANT wall8_x_r : INTEGER := 650;
    CONSTANT wall8_y_t : INTEGER := 150; CONSTANT wall8_y_b : INTEGER := 250;

    SIGNAL hits : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0'); 
    
    SIGNAL ball_on : STD_LOGIC; 
    SIGNAL bat_on : STD_LOGIC; 
    SIGNAL wall_on : STD_LOGIC; 
    SIGNAL goal_on : STD_LOGIC; 
    
    -- Text Signals
    SIGNAL text_easy_on : STD_LOGIC; 
    SIGNAL text_hard_on : STD_LOGIC;
    SIGNAL text_game_over_on : STD_LOGIC; 
    SIGNAL score_on : STD_LOGIC; 
    
    SIGNAL ball_x : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(100, 11); 
    SIGNAL ball_y : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(100, 11);
    
    SIGNAL bat_x : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(400, 11);
    SIGNAL bat_y : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(500, 11);

    SIGNAL goal_x : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(700, 11);
    SIGNAL goal_y : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(100, 11);
    
    SIGNAL ball_x_motion, ball_y_motion : STD_LOGIC_VECTOR(10 DOWNTO 0);
    
BEGIN
    -- VISUALS
    red <= '1' WHEN text_game_over_on = '1' ELSE
           NOT wall_on AND NOT bat_on AND NOT goal_on AND NOT score_on AND 
           NOT (text_easy_on AND NOT menu_selection) AND 
           NOT (text_hard_on AND menu_selection);        

    green <= '0' WHEN text_game_over_on = '1' ELSE
             NOT wall_on AND NOT ball_on AND NOT score_on AND
             NOT (text_easy_on AND menu_selection) AND     
             NOT (text_hard_on AND NOT menu_selection);    

    blue <= '0' WHEN text_game_over_on = '1' ELSE
            NOT wall_on AND NOT ball_on AND NOT goal_on AND NOT score_on AND 
            NOT text_easy_on AND NOT text_hard_on; 
    
    display <= hits; 

    -- PROCESS: DRAW WALLS
    walldraw : PROCESS (pixel_row, pixel_col)
    BEGIN
        IF ((pixel_col >= wall_x_l AND pixel_col <= wall_x_r) AND (pixel_row >= wall_y_t AND pixel_row <= wall_y_b)) or 
           ((pixel_col >= wall1_x_l AND pixel_col <= wall1_x_r) AND (pixel_row >= wall1_y_t AND pixel_row <= wall1_y_b)) or 
           ((pixel_col >= wall2_x_l AND pixel_col <= wall2_x_r) AND (pixel_row >= wall2_y_t AND pixel_row <= wall2_y_b)) or 
           ((pixel_col >= wall3_x_l AND pixel_col <= wall3_x_r) AND (pixel_row >= wall3_y_t AND pixel_row <= wall3_y_b)) or 
           ((pixel_col >= wall4_x_l AND pixel_col <= wall4_x_r) AND (pixel_row >= wall4_y_t AND pixel_row <= wall4_y_b)) or
           ((pixel_col >= wall5_x_l AND pixel_col <= wall5_x_r) AND (pixel_row >= wall5_y_t AND pixel_row <= wall5_y_b)) or 
           ((pixel_col >= wall6_x_l AND pixel_col <= wall6_x_r) AND (pixel_row >= wall6_y_t AND pixel_row <= wall6_y_b)) or 
           ((pixel_col >= wall7_x_l AND pixel_col <= wall7_x_r) AND (pixel_row >= wall7_y_t AND pixel_row <= wall7_y_b)) or 
           ((pixel_col >= wall8_x_l AND pixel_col <= wall8_x_r) AND (pixel_row >= wall8_y_t AND pixel_row <= wall8_y_b)) THEN
            wall_on <= '1';
        ELSE
            wall_on <= '0';
        END IF;
    END PROCESS;

    -- PROCESS: DRAW TEXT
    textdraw : PROCESS (pixel_row, pixel_col, game_state)
    BEGIN
        text_easy_on <= '0'; text_hard_on <= '0'; text_game_over_on <= '0';
        
        IF game_state = MENU THEN
            -- [MENU TEXT DRAWING LOGIC]
            IF (pixel_col >= 140 AND pixel_col <= 150 AND pixel_row >= 250 AND pixel_row <= 350) OR -- E
               (pixel_col >= 140 AND pixel_col <= 180 AND pixel_row >= 250 AND pixel_row <= 260) OR 
               (pixel_col >= 140 AND pixel_col <= 180 AND pixel_row >= 295 AND pixel_row <= 305) OR 
               (pixel_col >= 140 AND pixel_col <= 180 AND pixel_row >= 340 AND pixel_row <= 350) OR 
               (pixel_col >= 190 AND pixel_col <= 200 AND pixel_row >= 250 AND pixel_row <= 350) OR -- A
               (pixel_col >= 220 AND pixel_col <= 230 AND pixel_row >= 250 AND pixel_row <= 350) OR 
               (pixel_col >= 190 AND pixel_col <= 230 AND pixel_row >= 250 AND pixel_row <= 260) OR 
               (pixel_col >= 190 AND pixel_col <= 230 AND pixel_row >= 295 AND pixel_row <= 305) OR 
               (pixel_col >= 240 AND pixel_col <= 280 AND pixel_row >= 250 AND pixel_row <= 260) OR -- S
               (pixel_col >= 240 AND pixel_col <= 280 AND pixel_row >= 295 AND pixel_row <= 305) OR 
               (pixel_col >= 240 AND pixel_col <= 280 AND pixel_row >= 340 AND pixel_row <= 350) OR 
               (pixel_col >= 240 AND pixel_col <= 250 AND pixel_row >= 250 AND pixel_row <= 305) OR 
               (pixel_col >= 270 AND pixel_col <= 280 AND pixel_row >= 305 AND pixel_row <= 350) OR 
               (pixel_col >= 290 AND pixel_col <= 300 AND pixel_row >= 250 AND pixel_row <= 300) OR -- Y
               (pixel_col >= 320 AND pixel_col <= 330 AND pixel_row >= 250 AND pixel_row <= 300) OR 
               (pixel_col >= 290 AND pixel_col <= 330 AND pixel_row >= 300 AND pixel_row <= 310) OR 
               (pixel_col >= 305 AND pixel_col <= 315 AND pixel_row >= 310 AND pixel_row <= 350) THEN 
               text_easy_on <= '1'; 
            
            ELSIF (pixel_col >= 500 AND pixel_col <= 510 AND pixel_row >= 250 AND pixel_row <= 350) OR -- H
                  (pixel_col >= 530 AND pixel_col <= 540 AND pixel_row >= 250 AND pixel_row <= 350) OR 
                  (pixel_col >= 500 AND pixel_col <= 540 AND pixel_row >= 295 AND pixel_row <= 305) OR 
                  (pixel_col >= 550 AND pixel_col <= 560 AND pixel_row >= 250 AND pixel_row <= 350) OR -- A
                  (pixel_col >= 580 AND pixel_col <= 590 AND pixel_row >= 250 AND pixel_row <= 350) OR 
                  (pixel_col >= 550 AND pixel_col <= 590 AND pixel_row >= 250 AND pixel_row <= 260) OR 
                  (pixel_col >= 550 AND pixel_col <= 590 AND pixel_row >= 295 AND pixel_row <= 305) OR 
                  (pixel_col >= 600 AND pixel_col <= 610 AND pixel_row >= 250 AND pixel_row <= 350) OR -- R
                  (pixel_col >= 600 AND pixel_col <= 640 AND pixel_row >= 250 AND pixel_row <= 260) OR 
                  (pixel_col >= 600 AND pixel_col <= 640 AND pixel_row >= 295 AND pixel_row <= 305) OR 
                  (pixel_col >= 630 AND pixel_col <= 640 AND pixel_row >= 250 AND pixel_row <= 305) OR 
                  (pixel_col >= 630 AND pixel_col <= 640 AND pixel_row >= 305 AND pixel_row <= 350) OR 
                  (pixel_col >= 650 AND pixel_col <= 660 AND pixel_row >= 250 AND pixel_row <= 350) OR -- D
                  (pixel_col >= 650 AND pixel_col <= 680 AND pixel_row >= 250 AND pixel_row <= 260) OR 
                  (pixel_col >= 650 AND pixel_col <= 680 AND pixel_row >= 340 AND pixel_row <= 350) OR 
                  (pixel_col >= 680 AND pixel_col <= 690 AND pixel_row >= 260 AND pixel_row <= 340) THEN 
                  text_hard_on <= '1';
            END IF;
            
        ELSIF game_state = GAME_OVER THEN
            -- G 
            IF (pixel_col >= 275 AND pixel_col <= 315 AND pixel_row >= 140 AND pixel_row <= 150) OR -- Top
               (pixel_col >= 275 AND pixel_col <= 315 AND pixel_row >= 180 AND pixel_row <= 190) OR -- Bot
               (pixel_col >= 275 AND pixel_col <= 285 AND pixel_row >= 140 AND pixel_row <= 190) OR -- Left
               (pixel_col >= 305 AND pixel_col <= 315 AND pixel_row >= 165 AND pixel_row <= 190) OR -- Right Low
               (pixel_col >= 295 AND pixel_col <= 315 AND pixel_row >= 165 AND pixel_row <= 175) THEN -- Hook
               text_game_over_on <= '1';
            -- A 
            ELSIF (pixel_col >= 335 AND pixel_col <= 345 AND pixel_row >= 140 AND pixel_row <= 190) OR -- Left
                  (pixel_col >= 365 AND pixel_col <= 375 AND pixel_row >= 140 AND pixel_row <= 190) OR -- Right
                  (pixel_col >= 335 AND pixel_col <= 375 AND pixel_row >= 140 AND pixel_row <= 150) OR -- Top
                  (pixel_col >= 335 AND pixel_col <= 375 AND pixel_row >= 165 AND pixel_row <= 175) THEN -- Mid
               text_game_over_on <= '1';
            -- M 
            ELSIF (pixel_col >= 395 AND pixel_col <= 405 AND pixel_row >= 140 AND pixel_row <= 190) OR -- Left
                  (pixel_col >= 425 AND pixel_col <= 435 AND pixel_row >= 140 AND pixel_row <= 190) OR -- Right
                  (pixel_col >= 405 AND pixel_col <= 415 AND pixel_row >= 140 AND pixel_row <= 165) OR -- V Left
                  (pixel_col >= 415 AND pixel_col <= 425 AND pixel_row >= 140 AND pixel_row <= 165) THEN -- V Right
               text_game_over_on <= '1';
            -- E 
            ELSIF (pixel_col >= 455 AND pixel_col <= 465 AND pixel_row >= 140 AND pixel_row <= 190) OR -- Vert
                  (pixel_col >= 455 AND pixel_col <= 495 AND pixel_row >= 140 AND pixel_row <= 150) OR -- Top
                  (pixel_col >= 455 AND pixel_col <= 495 AND pixel_row >= 160 AND pixel_row <= 170) OR -- Mid
                  (pixel_col >= 455 AND pixel_col <= 495 AND pixel_row >= 180 AND pixel_row <= 190) THEN -- Bot
               text_game_over_on <= '1';
               
            -- O 
            ELSIF (pixel_col >= 275 AND pixel_col <= 315 AND pixel_row >= 410 AND pixel_row <= 420) OR -- Top
                  (pixel_col >= 275 AND pixel_col <= 315 AND pixel_row >= 450 AND pixel_row <= 460) OR -- Bot
                  (pixel_col >= 275 AND pixel_col <= 285 AND pixel_row >= 410 AND pixel_row <= 460) OR -- Left
                  (pixel_col >= 305 AND pixel_col <= 315 AND pixel_row >= 410 AND pixel_row <= 460) THEN -- Right
               text_game_over_on <= '1';
            -- V 
            ELSIF (pixel_col >= 335 AND pixel_col <= 345 AND pixel_row >= 410 AND pixel_row <= 445) OR -- Left Top
                  (pixel_col >= 365 AND pixel_col <= 375 AND pixel_row >= 410 AND pixel_row <= 445) OR -- Right Top
                  (pixel_col >= 350 AND pixel_col <= 360 AND pixel_row >= 445 AND pixel_row <= 460) THEN -- Bot
               text_game_over_on <= '1';
            -- E 
            ELSIF (pixel_col >= 395 AND pixel_col <= 405 AND pixel_row >= 410 AND pixel_row <= 460) OR 
                  (pixel_col >= 395 AND pixel_col <= 435 AND pixel_row >= 410 AND pixel_row <= 420) OR 
                  (pixel_col >= 395 AND pixel_col <= 435 AND pixel_row >= 430 AND pixel_row <= 440) OR 
                  (pixel_col >= 395 AND pixel_col <= 435 AND pixel_row >= 450 AND pixel_row <= 460) THEN 
               text_game_over_on <= '1';
            -- R 
            ELSIF (pixel_col >= 455 AND pixel_col <= 465 AND pixel_row >= 410 AND pixel_row <= 460) OR -- Left
                  (pixel_col >= 455 AND pixel_col <= 495 AND pixel_row >= 410 AND pixel_row <= 420) OR -- Top
                  (pixel_col >= 455 AND pixel_col <= 495 AND pixel_row >= 430 AND pixel_row <= 440) OR -- Mid
                  (pixel_col >= 485 AND pixel_col <= 495 AND pixel_row >= 410 AND pixel_row <= 435) OR -- Top Right
                  (pixel_col >= 485 AND pixel_col <= 495 AND pixel_row >= 435 AND pixel_row <= 460) THEN -- Leg
               text_game_over_on <= '1';
            END IF;
        END IF;
    END PROCESS;

    -- PROCESS: DRAW SCORE
    scoredraw : PROCESS (pixel_row, pixel_col, hits)
        VARIABLE digit : INTEGER;
        CONSTANT sx : INTEGER := 400; CONSTANT sy : INTEGER := 60; CONSTANT sw : INTEGER := 30; CONSTANT sh : INTEGER := 50; CONSTANT th : INTEGER := 4; 
    BEGIN
        digit := CONV_INTEGER(hits(3 DOWNTO 0)); 
        IF game_state /= MENU AND pixel_col >= sx AND pixel_col <= sx + sw AND pixel_row >= sy AND pixel_row <= sy + sh THEN
            IF (digit=0 OR digit=2 OR digit=3 OR digit=5 OR digit=6 OR digit=7 OR digit=8 OR digit=9) AND (pixel_row <= sy + th) THEN score_on <= '1';
            ELSIF (digit=0 OR digit=1 OR digit=2 OR digit=3 OR digit=4 OR digit=7 OR digit=8 OR digit=9) AND (pixel_col >= sx + sw - th AND pixel_row <= sy + sh/2) THEN score_on <= '1';
            ELSIF (digit=0 OR digit=1 OR digit=3 OR digit=4 OR digit=5 OR digit=6 OR digit=7 OR digit=8 OR digit=9) AND (pixel_col >= sx + sw - th AND pixel_row >= sy + sh/2) THEN score_on <= '1';
            ELSIF (digit=0 OR digit=2 OR digit=3 OR digit=5 OR digit=6 OR digit=8 OR digit=9) AND (pixel_row >= sy + sh - th) THEN score_on <= '1';
            ELSIF (digit=0 OR digit=2 OR digit=6 OR digit=8) AND (pixel_col <= sx + th AND pixel_row >= sy + sh/2) THEN score_on <= '1';
            ELSIF (digit=0 OR digit=4 OR digit=5 OR digit=6 OR digit=8 OR digit=9) AND (pixel_col <= sx + th AND pixel_row <= sy + sh/2) THEN score_on <= '1';
            ELSIF (digit=2 OR digit=3 OR digit=4 OR digit=5 OR digit=6 OR digit=8 OR digit=9) AND (pixel_row >= sy + sh/2 - th/2 AND pixel_row <= sy + sh/2 + th/2) THEN score_on <= '1';
            ELSE score_on <= '0';
            END IF;
        ELSE score_on <= '0';
        END IF;
    END PROCESS;

    -- PROCESS: DRAW GOAL
    goaldraw : PROCESS (goal_x, goal_y, pixel_row, pixel_col)
    BEGIN
        IF (pixel_col >= goal_x - goal_sz) AND (pixel_col <= goal_x + goal_sz) AND
           (pixel_row >= goal_y - goal_sz) AND (pixel_row <= goal_y + goal_sz) THEN
            goal_on <= '1';
        ELSE
            goal_on <= '0';
        END IF;
    END PROCESS;

    -- PROCESS: DRAW BALL
    balldraw : PROCESS (ball_x, ball_y, pixel_row, pixel_col, game_state) IS
        VARIABLE vx, vy : STD_LOGIC_VECTOR (10 DOWNTO 0); 
    BEGIN
        IF game_state = GAME_OVER THEN 
            ball_on <= '0';
        ELSE
            IF pixel_col <= ball_x THEN vx := ball_x - pixel_col; ELSE vx := pixel_col - ball_x; END IF;
            IF pixel_row <= ball_y THEN vy := ball_y - pixel_row; ELSE vy := pixel_row - ball_y; END IF;
            IF ((vx * vx) + (vy * vy)) < (bsize * bsize) THEN ball_on <= '1'; ELSE ball_on <= '0'; END IF;
        END IF;
    END PROCESS;
    
    -- PROCESS: DRAW BAT
    batdraw : PROCESS (bat_x, bat_y, pixel_row, pixel_col, game_state) IS
    BEGIN
        IF game_state = GAME_OVER THEN 
            bat_on <= '0';
        ELSE
            IF pixel_col >= (bat_x - bat_w) AND pixel_col <= (bat_x + bat_w) AND
               pixel_row >= (bat_y - bat_h) AND pixel_row <= (bat_y + bat_h) THEN
                    bat_on <= '1';
            ELSE
                bat_on <= '0';
            END IF;
        END IF;
    END PROCESS;

   -- PROCESS: GAME LOGIC
    move_player : PROCESS
        VARIABLE temp : STD_LOGIC_VECTOR (11 DOWNTO 0);
        VARIABLE speed_vec : STD_LOGIC_VECTOR(10 DOWNTO 0);
        VARIABLE neg_speed_vec : STD_LOGIC_VECTOR(10 DOWNTO 0);
        
        -- DYNAMIC AI VARIABLES
        VARIABLE current_speed : INTEGER;
        VARIABLE ai_reaction_delay : INTEGER;
        
        -- ai timer counter
        VARIABLE ai_timer : INTEGER RANGE 0 TO 100 := 0;
    BEGIN
        WAIT UNTIL rising_edge(v_sync);
        
        -- EDGE DETECTION UPDATE
        serve_prev <= serve;

        -- MENU INPUT LOGIC
        IF game_state = MENU THEN
            IF btnL = '1' THEN menu_selection <= '0'; END IF; 
            IF btnR = '1' THEN menu_selection <= '1'; END IF; 
            
            -- RESET POSITIONS
            bat_x <= CONV_STD_LOGIC_VECTOR(400, 11);
            bat_y <= CONV_STD_LOGIC_VECTOR(500, 11);
            ball_x <= CONV_STD_LOGIC_VECTOR(100, 11); 
            ball_y <= CONV_STD_LOGIC_VECTOR(100, 11);
            hits <= (OTHERS => '0');

            -- START GAME LOGIC (EDGE DETECTED)
            IF serve = '1' AND serve_prev = '0' THEN
                IF menu_selection = '0' THEN 
                    game_state <= PLAY_EASY;
                    ball_x_motion <= CONV_STD_LOGIC_VECTOR(3, 11);
                    ball_y_motion <= CONV_STD_LOGIC_VECTOR(3, 11);
                ELSE 
                    game_state <= PLAY_HARD; 
                    ball_x_motion <= CONV_STD_LOGIC_VECTOR(6, 11);
                    ball_y_motion <= CONV_STD_LOGIC_VECTOR(6, 11);
                END IF;
                ai_timer := 0; 
            END IF;

        -- GAME OVER LOGIC
        ELSIF game_state = GAME_OVER THEN
            -- Wait for restart (EDGE DETECTED)
            IF serve = '1' AND serve_prev = '0' THEN
                game_state <= MENU;
            END IF;
        
        ELSE -- GAMEPLAY
            
            -- SETUP VARIABLES BASED ON MODE
            IF game_state = PLAY_EASY THEN current_speed := 3; ai_reaction_delay := 60;
            ELSE current_speed := 6; ai_reaction_delay := 20; END IF;
            
            speed_vec := CONV_STD_LOGIC_VECTOR(current_speed, 11);
            neg_speed_vec := (NOT speed_vec) + 1;
            
            -- GOAL HIT
            IF (bat_x + bat_w >= goal_x - goal_sz) AND (bat_x - bat_w <= goal_x + goal_sz) AND
               (bat_y + bat_h >= goal_y - goal_sz) AND (bat_y - bat_h <= goal_y + goal_sz) THEN
                hits <= hits + '1'; 
                IF hits(1 downto 0) = "00" THEN goal_x <= CONV_STD_LOGIC_VECTOR(100, 11); goal_y <= CONV_STD_LOGIC_VECTOR(500, 11);
                ELSIF hits(1 downto 0) = "01" THEN goal_x <= CONV_STD_LOGIC_VECTOR(400, 11); goal_y <= CONV_STD_LOGIC_VECTOR(500, 11);
                ELSIF hits(1 downto 0) = "10" THEN goal_x <= CONV_STD_LOGIC_VECTOR(700, 11); goal_y <= CONV_STD_LOGIC_VECTOR(500, 11);
                ELSE goal_x <= CONV_STD_LOGIC_VECTOR(100, 11); goal_y <= CONV_STD_LOGIC_VECTOR(100, 11);
                END IF;
            END IF;

            -- PLAYER MOVEMENT 
            IF btnU = '1' AND bat_y > (bat_h + player_speed) THEN
                IF (NOT ((bat_x + bat_w > wall_x_l) AND (bat_x - bat_w < wall_x_r) AND (bat_y - player_speed - bat_h < wall_y_b) AND (bat_y - player_speed + bat_h > wall_y_t)) AND
                    NOT (bat_y - player_speed - bat_h < wall1_y_b) AND
                    NOT ((bat_x + bat_w > wall2_x_l) AND (bat_x - bat_w < wall2_x_r) AND (bat_y - player_speed - bat_h < wall2_y_b) AND (bat_y - player_speed + bat_h > wall2_y_t)) AND
                    NOT ((bat_x + bat_w > wall3_x_l) AND (bat_x - bat_w < wall3_x_r) AND (bat_y - player_speed - bat_h < wall3_y_b) AND (bat_y - player_speed + bat_h > wall3_y_t)) AND
                    NOT ((bat_x + bat_w > wall4_x_l) AND (bat_x - bat_w < wall4_x_r) AND (bat_y - player_speed - bat_h < wall4_y_b) AND (bat_y - player_speed + bat_h > wall4_y_t)) AND
                    NOT ((bat_x + bat_w > wall5_x_l) AND (bat_x - bat_w < wall5_x_r) AND (bat_y - player_speed - bat_h < wall5_y_b) AND (bat_y - player_speed + bat_h > wall5_y_t)) AND
                    NOT ((bat_x + bat_w > wall6_x_l) AND (bat_x - bat_w < wall6_x_r) AND (bat_y - player_speed - bat_h < wall6_y_b) AND (bat_y - player_speed + bat_h > wall6_y_t)) AND
                    NOT ((bat_x + bat_w > wall7_x_l) AND (bat_x - bat_w < wall7_x_r) AND (bat_y - player_speed - bat_h < wall7_y_b) AND (bat_y - player_speed + bat_h > wall7_y_t)) AND
                    NOT ((bat_x + bat_w > wall8_x_l) AND (bat_x - bat_w < wall8_x_r) AND (bat_y - player_speed - bat_h < wall8_y_b) AND (bat_y - player_speed + bat_h > wall8_y_t))
                    ) THEN bat_y <= bat_y - player_speed;
                END IF;
            END IF;
            IF btnD = '1' AND bat_y < (600 - bat_h - player_speed) THEN
                IF (NOT ((bat_x + bat_w > wall_x_l) AND (bat_x - bat_w < wall_x_r) AND (bat_y + player_speed - bat_h < wall_y_b) AND (bat_y + player_speed + bat_h > wall_y_t)) AND
                    NOT (bat_y + player_speed + bat_h > wall2_y_t) AND
                    NOT ((bat_x + bat_w > wall1_x_l) AND (bat_x - bat_w < wall1_x_r) AND (bat_y + player_speed - bat_h < wall1_y_b) AND (bat_y + player_speed + bat_h > wall1_y_t)) AND
                    NOT ((bat_x + bat_w > wall3_x_l) AND (bat_x - bat_w < wall3_x_r) AND (bat_y + player_speed - bat_h < wall3_y_b) AND (bat_y + player_speed + bat_h > wall3_y_t)) AND
                    NOT ((bat_x + bat_w > wall4_x_l) AND (bat_x - bat_w < wall4_x_r) AND (bat_y + player_speed - bat_h < wall4_y_b) AND (bat_y + player_speed + bat_h > wall4_y_t)) AND
                    NOT ((bat_x + bat_w > wall5_x_l) AND (bat_x - bat_w < wall5_x_r) AND (bat_y + player_speed - bat_h < wall5_y_b) AND (bat_y + player_speed + bat_h > wall5_y_t)) AND
                    NOT ((bat_x + bat_w > wall6_x_l) AND (bat_x - bat_w < wall6_x_r) AND (bat_y + player_speed - bat_h < wall6_y_b) AND (bat_y + player_speed + bat_h > wall6_y_t)) AND
                    NOT ((bat_x + bat_w > wall7_x_l) AND (bat_x - bat_w < wall7_x_r) AND (bat_y + player_speed - bat_h < wall7_y_b) AND (bat_y + player_speed + bat_h > wall7_y_t)) AND
                    NOT ((bat_x + bat_w > wall8_x_l) AND (bat_x - bat_w < wall8_x_r) AND (bat_y + player_speed - bat_h < wall8_y_b) AND (bat_y + player_speed + bat_h > wall8_y_t))
                    ) THEN bat_y <= bat_y + player_speed;
                END IF;
            END IF;
            IF btnL = '1' AND bat_x > (bat_w + player_speed) THEN
                IF (NOT ((bat_x - player_speed + bat_w > wall_x_l) AND (bat_x - player_speed - bat_w < wall_x_r) AND (bat_y - bat_h < wall_y_b) AND (bat_y + bat_h > wall_y_t)) AND
                    NOT (bat_x - player_speed - bat_w < wall3_x_r) AND
                    NOT ((bat_x - player_speed + bat_w > wall1_x_l) AND (bat_x - player_speed - bat_w < wall1_x_r) AND (bat_y - bat_h < wall1_y_b) AND (bat_y + bat_h > wall1_y_t)) AND
                    NOT ((bat_x - player_speed + bat_w > wall2_x_l) AND (bat_x - player_speed - bat_w < wall2_x_r) AND (bat_y - bat_h < wall2_y_b) AND (bat_y + bat_h > wall2_y_t)) AND
                    NOT ((bat_x - player_speed + bat_w > wall4_x_l) AND (bat_x - player_speed - bat_w < wall4_x_r) AND (bat_y - bat_h < wall4_y_b) AND (bat_y + bat_h > wall4_y_t)) AND
                    NOT ((bat_x - player_speed + bat_w > wall5_x_l) AND (bat_x - player_speed - bat_w < wall5_x_r) AND (bat_y - bat_h < wall5_y_b) AND (bat_y + bat_h > wall5_y_t)) AND
                    NOT ((bat_x - player_speed + bat_w > wall6_x_l) AND (bat_x - player_speed - bat_w < wall6_x_r) AND (bat_y - bat_h < wall6_y_b) AND (bat_y + bat_h > wall6_y_t)) AND
                    NOT ((bat_x - player_speed + bat_w > wall7_x_l) AND (bat_x - player_speed - bat_w < wall7_x_r) AND (bat_y - bat_h < wall7_y_b) AND (bat_y + bat_h > wall7_y_t)) AND
                    NOT ((bat_x - player_speed + bat_w > wall8_x_l) AND (bat_x - player_speed - bat_w < wall8_x_r) AND (bat_y - bat_h < wall8_y_b) AND (bat_y + bat_h > wall8_y_t))
                    ) THEN bat_x <= bat_x - player_speed;
                END IF;
            END IF;
            IF btnR = '1' AND bat_x < (800 - bat_w - player_speed) THEN
                IF (NOT ((bat_x + player_speed + bat_w > wall_x_l) AND (bat_x + player_speed - bat_w < wall_x_r) AND (bat_y - bat_h < wall_y_b) AND (bat_y + bat_h > wall_y_t)) AND
                    NOT (bat_x + player_speed + bat_w > wall4_x_l) AND
                    NOT ((bat_x + player_speed + bat_w > wall1_x_l) AND (bat_x + player_speed - bat_w < wall1_x_r) AND (bat_y - bat_h < wall1_y_b) AND (bat_y + bat_h > wall1_y_t)) AND
                    NOT ((bat_x + player_speed + bat_w > wall2_x_l) AND (bat_x + player_speed - bat_w < wall2_x_r) AND (bat_y - bat_h < wall2_y_b) AND (bat_y + bat_h > wall2_y_t)) AND
                    NOT ((bat_x + player_speed + bat_w > wall3_x_l) AND (bat_x + player_speed - bat_w < wall3_x_r) AND (bat_y - bat_h < wall3_y_b) AND (bat_y + bat_h > wall3_y_t)) AND
                    NOT ((bat_x + player_speed + bat_w > wall5_x_l) AND (bat_x + player_speed - bat_w < wall5_x_r) AND (bat_y - bat_h < wall5_y_b) AND (bat_y + bat_h > wall5_y_t)) AND
                    NOT ((bat_x + player_speed + bat_w > wall6_x_l) AND (bat_x + player_speed - bat_w < wall6_x_r) AND (bat_y - bat_h < wall6_y_b) AND (bat_y + bat_h > wall6_y_t)) AND
                    NOT ((bat_x + player_speed + bat_w > wall7_x_l) AND (bat_x + player_speed - bat_w < wall7_x_r) AND (bat_y - bat_h < wall7_y_b) AND (bat_y + bat_h > wall7_y_t)) AND
                    NOT ((bat_x + player_speed + bat_w > wall8_x_l) AND (bat_x + player_speed - bat_w < wall8_x_r) AND (bat_y - bat_h < wall8_y_b) AND (bat_y + bat_h > wall8_y_t))
                    ) THEN bat_x <= bat_x + player_speed;
                END IF;
            END IF;

            -- AI BALL MOVEMENT & COLLISION
            IF ai_timer < ai_reaction_delay THEN
                ai_timer := ai_timer + 1;
            ELSE
                ai_timer := 0;
                IF bat_x > ball_x THEN ball_x_motion <= speed_vec; ELSE ball_x_motion <= neg_speed_vec; END IF;
                IF bat_y > ball_y THEN ball_y_motion <= speed_vec; ELSE ball_y_motion <= neg_speed_vec; END IF;
            END IF;

            -- WALL COLLISIONS - UPDATED with "Overlap Logic"
            -- Y DIRECTION
            IF ball_y <= bsize THEN ball_y_motion <= speed_vec;
            ELSIF ball_y + bsize >= 600 THEN ball_y_motion <= neg_speed_vec;
            ELSIF (ball_y + bsize >= wall_y_t) AND (ball_y - bsize < wall_y_t) AND (ball_x + bsize >= wall_x_l) AND (ball_x - bsize <= wall_x_r) AND (ball_y_motion(10) = '0') THEN ball_y_motion <= neg_speed_vec;
            ELSIF (ball_y - bsize <= wall_y_b) AND (ball_y + bsize > wall_y_b) AND (ball_x + bsize >= wall_x_l) AND (ball_x - bsize <= wall_x_r) AND (ball_y_motion(10) = '1') THEN ball_y_motion <= speed_vec;
            ELSIF (ball_y + bsize >= wall1_y_t) AND (ball_y - bsize < wall1_y_t) AND (ball_x + bsize >= wall1_x_l) AND (ball_x - bsize <= wall1_x_r) AND (ball_y_motion(10) = '0') THEN ball_y_motion <= neg_speed_vec;
            ELSIF (ball_y - bsize <= wall1_y_b) AND (ball_y + bsize > wall1_y_b) AND (ball_x + bsize >= wall1_x_l) AND (ball_x - bsize <= wall1_x_r) AND (ball_y_motion(10) = '1') THEN ball_y_motion <= speed_vec;
            ELSIF (ball_y + bsize >= wall2_y_t) AND (ball_y - bsize < wall2_y_t) AND (ball_x + bsize >= wall2_x_l) AND (ball_x - bsize <= wall2_x_r) AND (ball_y_motion(10) = '0') THEN ball_y_motion <= neg_speed_vec;
            ELSIF (ball_y - bsize <= wall2_y_b) AND (ball_y + bsize > wall2_y_b) AND (ball_x + bsize >= wall2_x_l) AND (ball_x - bsize <= wall2_x_r) AND (ball_y_motion(10) = '1') THEN ball_y_motion <= speed_vec;
            ELSIF (ball_y + bsize >= wall3_y_t) AND (ball_y - bsize < wall3_y_t) AND (ball_x + bsize >= wall3_x_l) AND (ball_x - bsize <= wall3_x_r) AND (ball_y_motion(10) = '0') THEN ball_y_motion <= neg_speed_vec;
            ELSIF (ball_y - bsize <= wall3_y_b) AND (ball_y + bsize > wall3_y_b) AND (ball_x + bsize >= wall3_x_l) AND (ball_x - bsize <= wall3_x_r) AND (ball_y_motion(10) = '1') THEN ball_y_motion <= speed_vec;
            ELSIF (ball_y + bsize >= wall4_y_t) AND (ball_y - bsize < wall4_y_t) AND (ball_x + bsize >= wall4_x_l) AND (ball_x - bsize <= wall4_x_r) AND (ball_y_motion(10) = '0') THEN ball_y_motion <= neg_speed_vec;
            ELSIF (ball_y - bsize <= wall4_y_b) AND (ball_y + bsize > wall4_y_b) AND (ball_x + bsize >= wall4_x_l) AND (ball_x - bsize <= wall4_x_r) AND (ball_y_motion(10) = '1') THEN ball_y_motion <= speed_vec;
            ELSIF (ball_y + bsize >= wall5_y_t) AND (ball_y - bsize < wall5_y_t) AND (ball_x + bsize >= wall5_x_l) AND (ball_x - bsize <= wall5_x_r) AND (ball_y_motion(10) = '0') THEN ball_y_motion <= neg_speed_vec;
            ELSIF (ball_y + bsize >= wall6_y_t) AND (ball_y - bsize < wall6_y_t) AND (ball_x + bsize >= wall6_x_l) AND (ball_x - bsize <= wall6_x_r) AND (ball_y_motion(10) = '0') THEN ball_y_motion <= neg_speed_vec;
            ELSIF (ball_y + bsize >= wall7_y_t) AND (ball_y - bsize < wall7_y_t) AND (ball_x + bsize >= wall7_x_l) AND (ball_x - bsize <= wall7_x_r) AND (ball_y_motion(10) = '0') THEN ball_y_motion <= neg_speed_vec;
            ELSIF (ball_y + bsize >= wall8_y_t) AND (ball_y - bsize < wall8_y_t) AND (ball_x + bsize >= wall8_x_l) AND (ball_x - bsize <= wall8_x_r) AND (ball_y_motion(10) = '0') THEN ball_y_motion <= neg_speed_vec;
            ELSIF (ball_y - bsize <= wall5_y_b) AND (ball_y + bsize > wall5_y_b) AND (ball_x + bsize >= wall5_x_l) AND (ball_x - bsize <= wall5_x_r) AND (ball_y_motion(10) = '1') THEN ball_y_motion <= speed_vec;        
            ELSIF (ball_y - bsize <= wall6_y_b) AND (ball_y + bsize > wall6_y_b) AND (ball_x + bsize >= wall6_x_l) AND (ball_x - bsize <= wall6_x_r) AND (ball_y_motion(10) = '1') THEN ball_y_motion <= speed_vec;
            ELSIF (ball_y - bsize <= wall7_y_b) AND (ball_y + bsize > wall7_y_b) AND (ball_x + bsize >= wall7_x_l) AND (ball_x - bsize <= wall7_x_r) AND (ball_y_motion(10) = '1') THEN ball_y_motion <= speed_vec;
            ELSIF (ball_y - bsize <= wall8_y_b) AND (ball_y + bsize > wall8_y_b) AND (ball_x + bsize >= wall8_x_l) AND (ball_x - bsize <= wall8_x_r) AND (ball_y_motion(10) = '1') THEN ball_y_motion <= speed_vec;
            END IF;
            
            -- X DIRECTION
            IF ball_x + bsize >= 800 THEN ball_x_motion <= neg_speed_vec; 
            ELSIF ball_x <= bsize THEN ball_x_motion <= speed_vec;
            ELSIF (ball_x + bsize >= wall_x_l) AND (ball_x - bsize < wall_x_l) AND (ball_y + bsize >= wall_y_t) AND (ball_y - bsize <= wall_y_b) AND (ball_x_motion(10) = '0') THEN ball_x_motion <= neg_speed_vec;
            ELSIF (ball_x - bsize <= wall_x_r) AND (ball_x + bsize > wall_x_r) AND (ball_y + bsize >= wall_y_t) AND (ball_y - bsize <= wall_y_b) AND (ball_x_motion(10) = '1') THEN ball_x_motion <= speed_vec; 
            ELSIF (ball_x + bsize >= wall1_x_l) AND (ball_x - bsize < wall1_x_l) AND (ball_y + bsize >= wall1_y_t) AND (ball_y - bsize <= wall1_y_b) AND (ball_x_motion(10) = '0') THEN ball_x_motion <= neg_speed_vec;
            ELSIF (ball_x - bsize <= wall1_x_r) AND (ball_x + bsize > wall1_x_r) AND (ball_y + bsize >= wall1_y_t) AND (ball_y - bsize <= wall1_y_b) AND (ball_x_motion(10) = '1') THEN ball_x_motion <= speed_vec; 
            ELSIF (ball_x + bsize >= wall2_x_l) AND (ball_x - bsize < wall2_x_l) AND (ball_y + bsize >= wall2_y_t) AND (ball_y - bsize <= wall2_y_b) AND (ball_x_motion(10) = '0') THEN ball_x_motion <= neg_speed_vec;
            ELSIF (ball_x - bsize <= wall2_x_r) AND (ball_x + bsize > wall2_x_r) AND (ball_y + bsize >= wall2_y_t) AND (ball_y - bsize <= wall2_y_b) AND (ball_x_motion(10) = '1') THEN ball_x_motion <= speed_vec; 
            ELSIF (ball_x + bsize >= wall3_x_l) AND (ball_x - bsize < wall3_x_l) AND (ball_y + bsize >= wall3_y_t) AND (ball_y - bsize <= wall3_y_b) AND (ball_x_motion(10) = '0') THEN ball_x_motion <= neg_speed_vec;
            ELSIF (ball_x - bsize <= wall3_x_r) AND (ball_x + bsize > wall3_x_r) AND (ball_y + bsize >= wall3_y_t) AND (ball_y - bsize <= wall3_y_b) AND (ball_x_motion(10) = '1') THEN ball_x_motion <= speed_vec; 
            ELSIF (ball_x + bsize >= wall4_x_l) AND (ball_x - bsize < wall4_x_l) AND (ball_y + bsize >= wall4_y_t) AND (ball_y - bsize <= wall4_y_b) AND (ball_x_motion(10) = '0') THEN ball_x_motion <= neg_speed_vec;
            ELSIF (ball_x - bsize <= wall4_x_r) AND (ball_x + bsize > wall4_x_r) AND (ball_y + bsize >= wall4_y_t) AND (ball_y - bsize <= wall4_y_b) AND (ball_x_motion(10) = '1') THEN ball_x_motion <= speed_vec; 
            ELSIF (ball_x + bsize >= wall5_x_l) AND (ball_x - bsize < wall5_x_l) AND (ball_y + bsize >= wall5_y_t) AND (ball_y - bsize <= wall5_y_b) AND (ball_x_motion(10) = '0') THEN ball_x_motion <= neg_speed_vec;
            ELSIF (ball_x + bsize >= wall6_x_l) AND (ball_x - bsize < wall6_x_l) AND (ball_y + bsize >= wall6_y_t) AND (ball_y - bsize <= wall6_y_b) AND (ball_x_motion(10) = '0') THEN ball_x_motion <= neg_speed_vec;
            ELSIF (ball_x + bsize >= wall7_x_l) AND (ball_x - bsize < wall7_x_l) AND (ball_y + bsize >= wall7_y_t) AND (ball_y - bsize <= wall7_y_b) AND (ball_x_motion(10) = '0') THEN ball_x_motion <= neg_speed_vec;
            ELSIF (ball_x + bsize >= wall8_x_l) AND (ball_x - bsize < wall8_x_l) AND (ball_y + bsize >= wall8_y_t) AND (ball_y - bsize <= wall8_y_b) AND (ball_x_motion(10) = '0') THEN ball_x_motion <= neg_speed_vec;
            ELSIF (ball_x - bsize <= wall5_x_r) AND (ball_x + bsize > wall5_x_r) AND (ball_y + bsize >= wall5_y_t) AND (ball_y - bsize <= wall5_y_b) AND (ball_x_motion(10) = '1') THEN ball_x_motion <= speed_vec; 
            ELSIF (ball_x - bsize <= wall6_x_r) AND (ball_x + bsize > wall6_x_r) AND (ball_y + bsize >= wall6_y_t) AND (ball_y - bsize <= wall6_y_b) AND (ball_x_motion(10) = '1') THEN ball_x_motion <= speed_vec;
            ELSIF (ball_x - bsize <= wall7_x_r) AND (ball_x + bsize > wall7_x_r) AND (ball_y + bsize >= wall7_y_t) AND (ball_y - bsize <= wall7_y_b) AND (ball_x_motion(10) = '1') THEN ball_x_motion <= speed_vec;
            ELSIF (ball_x - bsize <= wall8_x_r) AND (ball_x + bsize > wall8_x_r) AND (ball_y + bsize >= wall8_y_t) AND (ball_y - bsize <= wall8_y_b) AND (ball_x_motion(10) = '1') THEN ball_x_motion <= speed_vec;
            END IF;

            -- PLAYER CAUGHT LOGIC
            IF (ball_x + bsize/2) >= (bat_x - bat_w) AND (ball_x - bsize/2) <= (bat_x + bat_w) AND
               (ball_y + bsize/2) >= (bat_y - bat_h) AND (ball_y - bsize/2) <= (bat_y + bat_h) THEN
                 game_state <= GAME_OVER; -- Go to Death Screen
            END IF;
            
            -- UPDATE POSITION
            temp := ('0' & ball_y) + (ball_y_motion(10) & ball_y_motion);
            IF temp(11) = '1' THEN ball_y <= (OTHERS => '0'); ELSE ball_y <= temp(10 DOWNTO 0); END IF;
            
            temp := ('0' & ball_x) + (ball_x_motion(10) & ball_x_motion);
            IF temp(11) = '1' THEN ball_x <= (OTHERS => '0'); ELSE ball_x <= temp(10 DOWNTO 0); END IF;
        END IF;
    END PROCESS;
END Behavioral;