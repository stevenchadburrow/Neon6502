
; Neon6502-Program.asm

; To compile
; ./dev65/bin/as65 Neon6502-Program.asm

; To parse
; ./Neon6502-Parser.o Neon6502-Program.lst Neon6502-Program.bin 32768 0 32768 0

; To combine
; ./Neon6502-Combiner.o Neon6502-SyncSignals.bin Neon6502-Program.bin Neon6502-Flash128KB.bin

; To burn
; minipro -p "SST39SF010" -w Neon6502-Flash128KB.bin

; To simulate
; ./Neon6502-Simulator.o Neon6502-Program.bin

	.65C02

video .EQU $0800

piece_type .EQU $00
piece_rot .EQU $01
piece_x .EQU $02
piece_y .EQU $03
prev_rot .EQU $04
prev_x .EQU $05
prev_y .EQU $06
block_color .EQU $07
block_x .EQU $08
block_y .EQU $09
frame_counter .EQU $0A
piece_descend .EQU $0B
piece_color .EQU $0C
piece_next .EQU $0D
piece_speed .EQU $0E
random_value .EQU $0F
lines_low .EQU $10
lines_high .EQU $11
buttons_value .EQU $12
buttons_wait .EQU $13
buttons_delay .EQU $14
digit_value .EQU $15
digit_x .EQU $16
digit_y .EQU $17
draw_flag .EQU $18
wait_rot .EQU $19
bag_pos .EQU $1A

bag_array .EQU $0020 ; uses 7 bytes

get_func .EQU $0030
get_low .EQU $0031
get_high .EQU $0032
get_rts .EQU $0033

put_func .EQU $0034
put_low .EQU $0035
put_high .EQU $0036
put_rts .EQU $0037

seq_func .EQU $0038
seq_low .EQU $0039
seq_high .EQU $003A
seq_rts .EQU $003B

rand_func .EQU $0040 ; current = 5 * previous + 17, uses 12 bytes

grid_page .EQU $0200


	.ORG $8000
reset
	SEI
	CLD

	JSR setup
	JSR clear

	LDA #$00
	STA lines_low
	LDA #$00
	STA lines_high

	JSR draw_bag
	LDA bag_array
	STA piece_next
	INC bag_pos
		
	LDA #$3C ; $3C = 1 second, $1E = 0.5 seconds, $0F = 0.25 seconds
	STA piece_speed

	LDA #$FF
	STA wait_rot

	LDA #$01
	STA draw_flag

	JMP loop_new

loop
	JSR draw_next
	JSR draw_score
	JSR buttons
	LDA buttons_value
	AND #$0A
	BNE reset
	JSR draw_moves
	LDA piece_descend
	BEQ loop_wait
	LDA #$02
	STA piece_descend
	LDA piece_rot
	CMP prev_rot
	BEQ loop_prev
	STA wait_rot
	LDA prev_rot
	STA piece_rot
loop_prev
	LDA prev_x
	STA piece_x
	LDA prev_y
	STA piece_y
	INC piece_y
	JMP loop_draw
loop_wait
	LDA wait_rot
	CMP #$FF
	BEQ loop_draw
	LDA piece_rot
	STA prev_rot
	LDA wait_rot
	STA piece_rot
	LDA #$FF
	STA wait_rot
loop_draw
	JSR draw_walls
	JSR draw_piece
	LDA #$00
	STA piece_descend
	LDA piece_color
	CMP #$55
	BEQ loop_grid
	CMP #$AA
	BEQ loop_new
loop_inf
	JSR buttons
	LDA buttons_value
	AND #$0A
	BEQ loop_jump
	JMP reset
loop_jump
	JMP loop_inf

loop_grid
	JSR draw_grid
	JMP loop

loop_new
	LDA piece_next
	STA piece_type
	LDX bag_pos
	LDA bag_array,X
	STA piece_next
	INC bag_pos
	LDA bag_pos
	CMP #$07
	BNE loop_create
	JSR draw_bag
loop_create
	LDA #$00
	STA piece_rot
	LDA #$00
	STA prev_rot
	LDA #$03
	STA piece_x
	LDA #$03
	STA prev_x
	LDA #$00
	STA piece_y
	LDA #$00
	STA prev_y
	LDA #$55
	STA piece_color
	LDA #$00
	STA piece_descend
	LDA #$00
	STA frame_counter
	JSR draw_grid
	JMP loop


setup
	LDA #$8D ; STAa
	STA put_func
	LDA #$00
	STA put_low
	LDA #$00
	STA put_high
	LDA #$60 ; RTS
	STA put_rts

	LDA #$AD ; LDAa
	STA get_func
	LDA #$00
	STA get_low
	LDA #$00
	STA get_high
	LDA #$60 ; RTS
	STA get_rts

	LDA #$BD ; LDAax
	STA seq_func
	LDA #$00
	STA seq_low
	LDA #$00
	STA seq_high
	LDA #$60 ; RTS
	STA seq_rts

	LDA #$A5 ; LDAz
	STA rand_func+0
	LDA #<random_value
	STA rand_func+1
	LDA #$0A ; ASL A
	STA rand_func+2
	LDA #$0A ; ASL A
	STA rand_func+3
	LDA #$18 ; CLC
	STA rand_func+4
	LDA #$65 ; ADCz
	STA rand_func+5
	LDA #<random_value
	STA rand_func+6
	LDA #$69 ; ADC#
	STA rand_func+7
	LDA #$11 ; 17
	STA rand_func+8
	LDA #$85 ; STAz
	STA rand_func+9
	LDA #<random_value
	STA rand_func+10
	LDA #$60 ; RTS
	STA rand_func+11

	RTS


clear
	LDA #<video
	STA put_low
	LDA #>video
	STA put_high
clear_sub_1
	LDA #$00
clear_sub_2
	JSR put_func
	INC put_low
	BNE clear_sub_2
	INC put_high
	LDA put_high
	CMP #$80
	BNE clear_sub_1
	LDX #$00
	LDA #$00
clear_sub_3
	STA grid_page,X
	INX
	BNE clear_sub_3
	RTS


buttons	
	LDA #$FF
	STA $8000
	LDX #$08
buttons_sub_1
	LSR A
	ORA #$80
	NOP
	NOP
	CLV
	NOP
	NOP
	NOP
	NOP
	BVC buttons_sub_2
	AND #$7F
buttons_sub_2
	STA $C000
	DEX
	BNE buttons_sub_1
	STA buttons_value
	RTS

	
draw_block
	TXA
	PHA
	TYA
	PHA

	LDX #$00
	LDA block_color
	BNE draw_block_sub_1
	LDA #<draw_block_data_0
	STA seq_low
	LDA #>draw_block_data_0
	STA seq_high
	JMP draw_block_sequence
draw_block_sub_1
	CMP #$55
	BNE draw_block_sub_2
	LDA #<draw_block_data_1
	STA seq_low
	LDA #>draw_block_data_1
	STA seq_high
	JMP draw_block_sequence
draw_block_sub_2
	CMP #$AA
	BNE draw_block_sub_3
	LDA #<draw_block_data_2
	STA seq_low
	LDA #>draw_block_data_2
	STA seq_high
	JMP draw_block_sequence
draw_block_sub_3
	CMP #$FF
	BNE draw_block_sub_4
	LDA #<draw_block_data_3
	STA seq_low
	LDA #>draw_block_data_3
	STA seq_high
	JMP draw_block_sequence
draw_block_sub_4
	PLA
	TAY
	PLA
	TAX
	RTS

draw_block_sequence
	LDA block_y
	ASL A
	ASL A
	CLC
	ADC #>video
	CLC
	ADC #$10 ; vertical shift
	STA put_high
	LDA block_x
	ASL A
	CLC
	ADC #<video
	CLC
	ADC #$14 ; horizontal shift
	STA put_low
	JSR seq_func
	INX
	JSR put_func
	INC put_low
	JSR seq_func
	INX
	JSR put_func
	LDA put_low
	CLC
	ADC #$7F
	STA put_low
	JSR seq_func
	INX
	JSR put_func
	INC put_low
	JSR seq_func
	INX
	JSR put_func

	INC put_high

	LDA put_low
	CLC
	ADC #$7F
	STA put_low
	JSR seq_func
	INX
	JSR put_func
	INC put_low
	JSR seq_func
	INX
	JSR put_func
	LDA put_low
	CLC
	ADC #$7F
	STA put_low
	JSR seq_func
	INX
	JSR put_func
	INC put_low
	JSR seq_func
	INX
	JSR put_func
	
	INC put_high

	LDA put_low
	CLC
	ADC #$7F
	STA put_low
	JSR seq_func
	INX
	JSR put_func
	INC put_low
	JSR seq_func
	INX
	JSR put_func
	LDA put_low
	CLC
	ADC #$7F
	STA put_low
	JSR seq_func
	INX
	JSR put_func
	INC put_low
	JSR seq_func
	INX
	JSR put_func
	
	INC put_high

	LDA put_low
	CLC
	ADC #$7F
	STA put_low
	JSR seq_func
	INX
	JSR put_func
	INC put_low
	JSR seq_func
	INX
	JSR put_func
	LDA put_low
	CLC
	ADC #$7F
	STA put_low
	JSR seq_func
	INX
	JSR put_func
	INC put_low
	JSR seq_func
	INX
	JSR put_func

	PLA
	TAY
	PLA
	TAX
	RTS


draw_moves
	LDA piece_color
	CMP #$55
	BEQ draw_moves_sub_1
	RTS
draw_moves_sub_1
	LDA piece_rot
	STA prev_rot
	LDA piece_x
	STA prev_x
	LDA piece_y
	STA prev_y
	LDA buttons_value
	AND #$10 ; right
	BEQ draw_moves_sub_2
	LDA buttons_delay
	BNE draw_moves_sub_2
	LDA piece_x
	CMP #$09
	BCS draw_moves_sub_2
	CLC
	ADC #$01
	STA piece_x
	LDA #$01 ; horizontal speed
	STA buttons_delay
	JSR rand_func ; to help randomize
draw_moves_sub_2
	LDA buttons_value
	AND #$20 ; left
	BEQ draw_moves_sub_3
	LDA buttons_delay
	BNE draw_moves_sub_3
	LDA piece_x
	CMP #$01
	BCC draw_moves_sub_3
	SEC
	SBC #$01
	STA piece_x
	LDA #$01 ; horizontal speed
	STA buttons_delay
	JSR rand_func ; to help randomize
draw_moves_sub_3
	LDA buttons_value
	AND #$01 ; A
	BEQ draw_moves_sub_4
	LDA buttons_wait
	BNE draw_moves_sub_4
	LDA #$FF
	STA buttons_wait
	LDA piece_rot
	CLC
	ADC #$01
	AND #$03
	STA piece_rot
	JSR rand_func ; to help randomize
draw_moves_sub_4
	LDA buttons_value
	AND #$04 ; B
	BEQ draw_moves_sub_5
	LDA buttons_wait
	BNE draw_moves_sub_5
	LDA #$FF
	STA buttons_wait
	LDA piece_rot
	SEC
	SBC #$01
	AND #$03
	STA piece_rot
	JSR rand_func ; to help randomize
draw_moves_sub_5
	LDA buttons_value
	AND #$40 ; down
	BEQ draw_moves_sub_6
	LDA #$01
	STA piece_descend
	LDA #$00
	STA frame_counter
	JSR rand_func ; to help randomize
draw_moves_sub_6
	LDA buttons_value
	AND #$05 ; A and B
	BNE draw_moves_sub_7
	LDA #$00
	STA buttons_wait
draw_moves_sub_7
	LDA buttons_value
	AND #$30 ; left and right
	BNE draw_moves_sub_8
	LDA #$00
	STA buttons_delay
draw_moves_sub_8
	LDA buttons_delay
	BEQ draw_moves_sub_9
	DEC buttons_delay
draw_moves_sub_9
	RTS


draw_walls
	LDX #$00
	LDY #$00
draw_walls_sub_1
	LDA grid_page,X
	CMP #$AA
	BEQ draw_walls_sub_2
	LDA draw_walls_data,Y
	STA grid_page,X
draw_walls_sub_2
	INY
	CPY #$0C
	BNE draw_walls_sub_3
	LDY #$00
draw_walls_sub_3
	INX
	BNE draw_walls_sub_1
	LDX #$F0
	LDA #$FF
draw_walls_sub_4
	STA grid_page,X
	INX
	BNE draw_walls_sub_4
	RTS


draw_piece
	LDX piece_y
	LDA #$00
draw_piece_sub_1
	CLC
	ADC #$0C
	DEX
	BNE draw_piece_sub_1
	CLC
	ADC piece_x
	TAX
	LDA piece_type
	CMP #$01
	BNE draw_piece_sub_2
	JMP draw_piece_i
draw_piece_sub_2
	CMP #$02
	BNE draw_piece_sub_3
	JMP draw_piece_o
draw_piece_sub_3
	CMP #$03
	BNE draw_piece_sub_4
	JMP draw_piece_t
draw_piece_sub_4
	CMP #$04
	BNE draw_piece_sub_5
	JMP draw_piece_j
draw_piece_sub_5
	CMP #$05
	BNE draw_piece_sub_6
	JMP draw_piece_l
draw_piece_sub_6
	CMP #$06
	BNE draw_piece_sub_7
	JMP draw_piece_s
draw_piece_sub_7
	CMP #$07
	BNE draw_piece_sub_8
	JMP draw_piece_z
draw_piece_sub_8
	RTS

draw_piece_i
	LDA piece_rot
	CMP #$00
	BEQ draw_piece_i_0
	CMP #$01
	BEQ draw_piece_i_1
	CMP #$02
	BEQ draw_piece_i_0
	CMP #$03
	BEQ draw_piece_i_1
	RTS
draw_piece_i_0
	LDA #<piece_data_i_0
	STA get_low
	LDA #>piece_data_i_0
	STA get_high
	JMP draw_piece_collision
draw_piece_i_1
	LDA #<piece_data_i_1
	STA get_low
	LDA #>piece_data_i_1
	STA get_high
	JMP draw_piece_collision

draw_piece_o
	LDA #<piece_data_o_0
	STA get_low
	LDA #>piece_data_o_0
	STA get_high
	JMP draw_piece_collision

draw_piece_t
	LDA piece_rot
	CMP #$00
	BEQ draw_piece_t_0
	CMP #$01
	BEQ draw_piece_t_1
	CMP #$02
	BEQ draw_piece_t_2
	CMP #$03
	BEQ draw_piece_t_3
	RTS
draw_piece_t_0
	LDA #<piece_data_t_0
	STA get_low
	LDA #>piece_data_t_0
	STA get_high
	JMP draw_piece_collision
draw_piece_t_1
	LDA #<piece_data_t_1
	STA get_low
	LDA #>piece_data_t_1
	STA get_high
	JMP draw_piece_collision
draw_piece_t_2
	LDA #<piece_data_t_2
	STA get_low
	LDA #>piece_data_t_2
	STA get_high
	JMP draw_piece_collision
draw_piece_t_3
	LDA #<piece_data_t_3
	STA get_low
	LDA #>piece_data_t_3
	STA get_high
	JMP draw_piece_collision

draw_piece_j
	LDA piece_rot
	CMP #$00
	BEQ draw_piece_j_0
	CMP #$01
	BEQ draw_piece_j_1
	CMP #$02
	BEQ draw_piece_j_2
	CMP #$03
	BEQ draw_piece_j_3
	RTS
draw_piece_j_0
	LDA #<piece_data_j_0
	STA get_low
	LDA #>piece_data_j_0
	STA get_high
	JMP draw_piece_collision
draw_piece_j_1
	LDA #<piece_data_j_1
	STA get_low
	LDA #>piece_data_j_1
	STA get_high
	JMP draw_piece_collision
draw_piece_j_2
	LDA #<piece_data_j_2
	STA get_low
	LDA #>piece_data_j_2
	STA get_high
	JMP draw_piece_collision
draw_piece_j_3
	LDA #<piece_data_j_3
	STA get_low
	LDA #>piece_data_j_3
	STA get_high
	JMP draw_piece_collision

draw_piece_l
	LDA piece_rot
	CMP #$00
	BEQ draw_piece_l_0
	CMP #$01
	BEQ draw_piece_l_1
	CMP #$02
	BEQ draw_piece_l_2
	CMP #$03
	BEQ draw_piece_l_3
	RTS
draw_piece_l_0
	LDA #<piece_data_l_0
	STA get_low
	LDA #>piece_data_l_0
	STA get_high
	JMP draw_piece_collision
draw_piece_l_1
	LDA #<piece_data_l_1
	STA get_low
	LDA #>piece_data_l_1
	STA get_high
	JMP draw_piece_collision
draw_piece_l_2
	LDA #<piece_data_l_2
	STA get_low
	LDA #>piece_data_l_2
	STA get_high
	JMP draw_piece_collision
draw_piece_l_3
	LDA #<piece_data_l_3
	STA get_low
	LDA #>piece_data_l_3
	STA get_high
	JMP draw_piece_collision

draw_piece_s
	LDA piece_rot
	CMP #$00
	BEQ draw_piece_s_0
	CMP #$01
	BEQ draw_piece_s_1
	CMP #$02
	BEQ draw_piece_s_0
	CMP #$03
	BEQ draw_piece_s_1
	RTS
draw_piece_s_0
	LDA #<piece_data_s_0
	STA get_low
	LDA #>piece_data_s_0
	STA get_high
	JMP draw_piece_collision
draw_piece_s_1
	LDA #<piece_data_s_1
	STA get_low
	LDA #>piece_data_s_1
	STA get_high
	JMP draw_piece_collision

draw_piece_z
	LDA piece_rot
	CMP #$00
	BEQ draw_piece_z_0
	CMP #$01
	BEQ draw_piece_z_1
	CMP #$02
	BEQ draw_piece_z_0
	CMP #$03
	BEQ draw_piece_z_1
	RTS
draw_piece_z_0
	LDA #<piece_data_z_0
	STA get_low
	LDA #>piece_data_z_0
	STA get_high
	JMP draw_piece_collision
draw_piece_z_1
	LDA #<piece_data_z_1
	STA get_low
	LDA #>piece_data_z_1
	STA get_high
	JMP draw_piece_collision

draw_piece_collision
	TXA
	PHA
	LDA get_high
	PHA
	LDA get_low
	PHA
	LDA #$00
	PHA
	LDY #$00
draw_piece_collision_sub_1
	JSR get_func
	BEQ draw_piece_collision_sub_2
	LDA grid_page,X
	BEQ draw_piece_collision_sub_2
	LDA prev_rot
	STA piece_rot	
	LDA prev_x
	STA piece_x
	LDA prev_y
	STA piece_y
	PLA
	CLC
	ADC #$01
	PHA
draw_piece_collision_sub_2
	INC get_low
	INX
	INY
	TYA
	AND #$03
	BNE draw_piece_collision_sub_1
	TXA
	CLC
	ADC #$08
	TAX
	CPY #$10
	BNE draw_piece_collision_sub_1
	PLA
	CMP #$00
	BEQ draw_piece_grid
	PLA
	PLA
	PLA
	LDA piece_descend
	BEQ draw_piece_collision_sub_3
	CMP #$01
	BEQ draw_piece_collision_sub_3
	LDA prev_y
	BEQ draw_piece_collision_sub_5
	LDA #$AA
	STA piece_color
draw_piece_collision_sub_3
	JSR buttons ; prevents lockup
	LDA buttons_value
	AND #$0A
	BEQ draw_piece_collision_sub_4
	JMP reset
draw_piece_collision_sub_4
	JMP draw_piece
draw_piece_collision_sub_5
	LDA #$00
	STA piece_color
	RTS

draw_piece_grid
	PLA
	STA get_low
	PLA
	STA get_high
	PLA
	TAX
	LDY #$00
draw_piece_grid_sub_1
	JSR get_func
	BEQ draw_piece_grid_sub_2
	JSR get_func
	AND piece_color
	STA grid_page,X
draw_piece_grid_sub_2
	INC get_low
	INX
	INY
	TYA
	AND #$03
	BNE draw_piece_grid_sub_1
	TXA
	CLC
	ADC #$08
	TAX
	CPY #$10
	BNE draw_piece_grid_sub_1
	LDA piece_color
	CMP #$AA
	BEQ draw_piece_grid_sub_3
	LDA #$55
	STA piece_color
	RTS
draw_piece_grid_sub_3
	RTS


draw_grid
	LDA draw_flag
	BNE draw_grid_sub_1
	RTS
draw_grid_sub_1
	LDA #$00
	STA draw_flag
	LDX #$00
	LDY #$00
	LDA #$00
	STA block_x
	LDA #$00
	STA block_y
	LDA #$00
	PHA
draw_grid_sub_2
	LDA grid_page,X
	STA block_color
	CMP #$AA
	BNE draw_grid_sub_3
	PLA
	CLC
	ADC #$01
	PHA
	LDA #$AA
draw_grid_sub_3
	JSR draw_block
	INC block_x
	INY
	CPY #$0C
	BNE draw_grid_sub_4
	LDY #$00
	LDA #$00
	STA block_x
	PLA
	CMP #$0A
	BEQ draw_line
	LDA #$00
	PHA
	INC block_y
draw_grid_sub_4
	INX
	CPX #$FC
	BNE draw_grid_sub_2
	PLA
	JSR draw_top
	RTS

draw_line
	INC lines_low
	LDA lines_low
	AND #$03
	BNE draw_line_sub_1
	DEC piece_speed
	LDA piece_speed
	CMP #$0F
	BCS draw_line_sub_1
	LDA #$0F
	STA piece_speed
draw_line_sub_1
	LDA lines_low
	CMP #$64 ; 100 in decimal
	BNE draw_line_sub_2
	LDA #$00
	STA lines_low
	INC lines_high
draw_line_sub_2
	LDX block_y
	LDA #$00
draw_line_sub_3
	CLC
	ADC #$0C
	DEX
	BNE draw_line_sub_3
	CLC
	ADC #$0C
	TAX
	SEC
	SBC #$0C
	TAY
draw_line_sub_4
	LDA grid_page,Y
	STA grid_page,X
	DEX
	DEY
	BNE draw_line_sub_4
	JMP draw_grid

draw_top
	LDX #$14
draw_top_sub_1
	LDA #$44
	STA $1600,X
	INX
	TXA
	CMP #$2C
	BNE draw_top_sub_1
	LDX #$94
draw_top_sub_2
	LDA #$11
	STA $1600,X
	INX
	TXA
	CMP #$AC
	BNE draw_top_sub_2
	LDX #$14
draw_top_sub_3
	LDA #$44
	STA $1700,X
	INX
	TXA
	CMP #$2C
	BNE draw_top_sub_3
	LDX #$94
draw_top_sub_4
	LDA #$11
	STA $1700,X
	INX
	TXA
	CMP #$AC
	BNE draw_top_sub_4
	RTS
	

draw_score
	LDA lines_low
	PHA
	LDA lines_high
	PHA
	LDY #$02
	LDA #$28
	STA digit_x
	LDA #$10
	STA digit_y
draw_score_sub_1
	PLA
	LDX #$00
draw_score_sub_2
	INX	
	SEC
	SBC #$0A
	BCS draw_score_sub_2
	CLC
	ADC #$0A
	PHA
	DEX
	TXA
	STA digit_value
	JSR draw_digit
	INC digit_x
	PLA
	STA digit_value
	JSR draw_digit
	INC digit_x
	DEY
	BNE draw_score_sub_1
	RTS


draw_digit
	LDA digit_x
	STA put_low
	LDA digit_y
	STA put_high
	LDA #<draw_digit_data
	STA get_low
	LDA #>draw_digit_data
	STA get_high
	LDA digit_value
	ASL A
	ASL A
	ASL A
	CLC
	ADC get_low
	STA get_low
	LDX #$06
draw_digit_sub_1
	JSR get_func
	JSR put_func
	INC get_low
	LDA put_low
	CLC
	ADC #$80
	STA put_low
	BCC draw_digit_sub_2
	INC put_high
draw_digit_sub_2
	DEX
	BNE draw_digit_sub_1
	RTS


draw_next
	LDA #$14
	STA put_low
	LDA #$10
	STA put_high
	LDA #<draw_next_data
	STA get_low
	LDA #>draw_next_data
	STA get_high
	LDA piece_next
	ASL A
	ASL A
	ASL A	
	CLC
	ADC get_low
	STA get_low
	LDX #$06
draw_next_sub_1
	JSR get_func
	JSR put_func
	INC get_low
	LDA put_low
	CLC
	ADC #$80
	STA put_low
	BCC draw_next_sub_2
	INC put_high
draw_next_sub_2
	DEX
	BNE draw_next_sub_1
	RTS

draw_bag
	LDY #$01
	LDA #$FF
	STA bag_array
	STA bag_array+1
	STA bag_array+2
	STA bag_array+3
	STA bag_array+4
	STA bag_array+5
	STA bag_array+6
draw_bag_sub_1
	JSR rand_func
	AND #$07
	BEQ draw_bag_sub_1
	TAX
	DEX
	LDA bag_array,X
	CMP #$FF
	BNE draw_bag_sub_1
	TYA
	STA bag_array,X
	INY
	CPY #$08
	BNE draw_bag_sub_1
	LDA #$00
	STA bag_pos
	RTS


	.ORG $C000

piece_data_i_0
	.BYTE $00,$00,$00,$00
	.BYTE $FF,$FF,$FF,$FF
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_i_1
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$FF,$00,$00

piece_data_o_0
	.BYTE $00,$00,$00,$00
	.BYTE $00,$FF,$FF,$00
	.BYTE $00,$FF,$FF,$00
	.BYTE $00,$00,$00,$00

piece_data_t_0
	.BYTE $00,$00,$00,$00
	.BYTE $FF,$FF,$FF,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_t_1
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$FF,$FF,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_t_2
	.BYTE $00,$FF,$00,$00
	.BYTE $FF,$FF,$FF,$00
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_t_3
	.BYTE $00,$FF,$00,$00
	.BYTE $FF,$FF,$00,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_j_0
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $FF,$FF,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_j_1
	.BYTE $00,$00,$00,$00
	.BYTE $FF,$FF,$FF,$00
	.BYTE $00,$00,$FF,$00
	.BYTE $00,$00,$00,$00

piece_data_j_2
	.BYTE $00,$FF,$FF,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_j_3
	.BYTE $FF,$00,$00,$00
	.BYTE $FF,$FF,$FF,$00
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_l_0
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$FF,$FF,$00
	.BYTE $00,$00,$00,$00

piece_data_l_1
	.BYTE $00,$00,$FF,$00
	.BYTE $FF,$FF,$FF,$00
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_l_2
	.BYTE $FF,$FF,$00,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_l_3
	.BYTE $00,$00,$00,$00
	.BYTE $FF,$FF,$FF,$00
	.BYTE $FF,$00,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_s_0
	.BYTE $00,$00,$00,$00
	.BYTE $00,$FF,$FF,$00
	.BYTE $FF,$FF,$00,$00
	.BYTE $00,$00,$00,$00

piece_data_s_1
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$FF,$FF,$00
	.BYTE $00,$00,$FF,$00
	.BYTE $00,$00,$00,$00

piece_data_z_0
	.BYTE $00,$00,$00,$00
	.BYTE $FF,$FF,$00,$00
	.BYTE $00,$FF,$FF,$00
	.BYTE $00,$00,$00,$00

piece_data_z_1
	.BYTE $00,$00,$FF,$00
	.BYTE $00,$FF,$FF,$00
	.BYTE $00,$FF,$00,$00
	.BYTE $00,$00,$00,$00

draw_walls_data
	.BYTE $FF,$00,$00,$00
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$FF
	.BYTE $00,$00,$00,$00

draw_digit_data
	.BYTE $3F,$33,$33,$33,$3F,$00,$00,$00
	.BYTE $03,$03,$03,$03,$03,$00,$00,$00
	.BYTE $3F,$03,$3F,$30,$3F,$00,$00,$00
	.BYTE $3F,$03,$3F,$03,$3F,$00,$00,$00
	.BYTE $33,$33,$3F,$03,$03,$00,$00,$00
	.BYTE $3F,$30,$3F,$03,$3F,$00,$00,$00
	.BYTE $3F,$30,$3F,$33,$3F,$00,$00,$00
	.BYTE $3F,$03,$03,$03,$03,$00,$00,$00
	.BYTE $3F,$33,$3F,$33,$3F,$00,$00,$00
	.BYTE $3F,$33,$3F,$03,$3F,$00,$00,$00
	.BYTE $00,$00,$00,$00,$00,$00,$00,$00
	.BYTE $00,$00,$00,$00,$00,$00,$00,$00

draw_next_data
	.BYTE $00,$00,$00,$00,$00,$00,$00,$00
	.BYTE $3F,$0C,$0C,$0C,$3F,$00,$00,$00
	.BYTE $3F,$33,$33,$33,$3F,$00,$00,$00
	.BYTE $3F,$0C,$0C,$0C,$0C,$00,$00,$00
	.BYTE $03,$03,$03,$03,$3F,$00,$00,$00
	.BYTE $30,$30,$30,$30,$3F,$00,$00,$00
	.BYTE $3F,$30,$3F,$03,$3F,$00,$00,$00
	.BYTE $3F,$03,$3F,$30,$3F,$00,$00,$00

draw_block_data_0
	.BYTE $00,$00
	.BYTE $00,$00
	.BYTE $00,$00
	.BYTE $00,$00
	.BYTE $00,$00
	.BYTE $00,$00
	.BYTE $00,$00
	.BYTE $00,$00

draw_block_data_1
	.BYTE $FF,$FF
	.BYTE $C0,$00
	.BYTE $C5,$55
	.BYTE $C5,$55
	.BYTE $C5,$55
	.BYTE $C5,$55
	.BYTE $C5,$55
	.BYTE $C5,$55

draw_block_data_2
	.BYTE $FF,$FF
	.BYTE $C0,$00
	.BYTE $CA,$AA
	.BYTE $CA,$AA
	.BYTE $CA,$AA
	.BYTE $CA,$AA
	.BYTE $CA,$AA
	.BYTE $CA,$AA

draw_block_data_3
	.BYTE $FF,$FF
	.BYTE $FF,$FF
	.BYTE $FF,$FF
	.BYTE $FF,$FF
	.BYTE $FF,$FF
	.BYTE $FF,$FF
	.BYTE $FF,$FF
	.BYTE $FF,$FF	



nmi
	PHA
	INC draw_flag
	INC frame_counter
	LDA frame_counter
	CMP piece_speed
	BNE nmi_skip
	LDA #$00
	STA frame_counter
	LDA #$01
	STA piece_descend
nmi_skip
	PLA
	RTI
	
irq
	RTI

; vectors
	.ORG $FFFA
	.WORD nmi
	.WORD reset
	.WORD irq


