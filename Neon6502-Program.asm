
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
lines_low .EQU $0E
lines_high .EQU $0F
buttons_value .EQU $10
buttons_wait .EQU $11
buttons_delay .EQU $12
random_value .EQU $13


draw_func .EQU $0018
draw_x .EQU $0019
draw_y .EQU $001A
draw_rts .EQU $001B

grab_func .EQU $001C
grab_low .EQU $001D
grab_high .EQU $001E
grab_rts .EQU $001F

rand_func .EQU $0020 ; current = 5 * previous + 17, uses 12 bytes

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

	JMP loop_new

loop
	JSR buttons
	LDA buttons_value
	AND #$0A
	BNE reset
	JSR draw_moves
	LDA piece_descend
	BEQ loop_draw
	LDA #$02
	STA piece_descend
	LDA prev_rot
	STA piece_rot
	LDA prev_x
	STA piece_x
	LDA prev_y
	STA piece_y
	INC piece_y
loop_draw
	JSR draw_walls
	JSR draw_piece
	LDA #$00
	STA piece_descend
	LDA piece_color
	CMP #$AA
	BEQ loop_grid
	CMP #$55
	BEQ loop_new
loop_inf
	JSR buttons
	LDA buttons_value
	AND #$0A
	BNE reset
	JMP loop_inf

loop_grid
	JSR draw_grid
	JMP loop

loop_new
	LDA piece_next
	STA piece_type
loop_find
	JSR rand_func
	AND #$07
	BEQ loop_find
	STA piece_type
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
	LDA #$AA
	STA piece_color
	LDA #$00
	STA piece_descend
	LDA #$00
	STA frame_counter
	JSR draw_grid
	JMP loop


setup
	LDA #$8D ; STAa
	STA draw_func
	LDA #$00
	STA draw_x
	LDA #$00
	STA draw_y
	LDA #$60 ; RTS
	STA draw_rts
	LDA #$AD ; LDAa
	STA grab_func
	LDA #$00
	STA grab_low
	LDA #$00
	STA grab_high
	LDA #$60 ; RTS
	STA grab_rts

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
	STA draw_x
	LDA #>video
	STA draw_y
clear_sub_1
	LDA #$00
clear_sub_2
	JSR draw_func
	INC draw_x
	BNE clear_sub_2
	INC draw_y
	LDA draw_y
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
	LDA block_y
	ASL A
	ASL A
	CLC
	ADC #>video
	STA draw_y
	LDA block_x
	ASL A
	CLC
	ADC #<video
	STA draw_x
	LDA block_color
	JSR draw_func
	INC draw_x
	JSR draw_func
	LDA draw_x
	CLC
	ADC #$7F
	STA draw_x
	LDA block_color
	JSR draw_func
	INC draw_x
	JSR draw_func

	INC draw_y

	LDA draw_x
	CLC
	ADC #$7F
	STA draw_x
	LDA block_color
	JSR draw_func
	INC draw_x
	JSR draw_func
	LDA draw_x
	CLC
	ADC #$7F
	STA draw_x
	LDA block_color
	JSR draw_func
	INC draw_x
	JSR draw_func
	
	INC draw_y

	LDA draw_x
	CLC
	ADC #$7F
	STA draw_x
	LDA block_color
	JSR draw_func
	INC draw_x
	JSR draw_func
	LDA draw_x
	CLC
	ADC #$7F
	STA draw_x
	LDA block_color
	JSR draw_func
	INC draw_x
	JSR draw_func
	
	INC draw_y

	LDA draw_x
	CLC
	ADC #$7F
	STA draw_x
	LDA block_color
	JSR draw_func
	INC draw_x
	JSR draw_func
	LDA draw_x
	CLC
	ADC #$7F
	STA draw_x
	LDA block_color
	JSR draw_func
	INC draw_x
	JSR draw_func

	RTS


draw_moves
	LDA piece_color
	CMP #$AA
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
	LDA #$02
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
	LDA #$02
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
	CMP #$55
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
	STA grab_low
	LDA #>piece_data_i_0
	STA grab_high
	JMP draw_piece_collision
draw_piece_i_1
	LDA #<piece_data_i_1
	STA grab_low
	LDA #>piece_data_i_1
	STA grab_high
	JMP draw_piece_collision

draw_piece_o
	LDA #<piece_data_o_0
	STA grab_low
	LDA #>piece_data_o_0
	STA grab_high
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
	STA grab_low
	LDA #>piece_data_t_0
	STA grab_high
	JMP draw_piece_collision
draw_piece_t_1
	LDA #<piece_data_t_1
	STA grab_low
	LDA #>piece_data_t_1
	STA grab_high
	JMP draw_piece_collision
draw_piece_t_2
	LDA #<piece_data_t_2
	STA grab_low
	LDA #>piece_data_t_2
	STA grab_high
	JMP draw_piece_collision
draw_piece_t_3
	LDA #<piece_data_t_3
	STA grab_low
	LDA #>piece_data_t_3
	STA grab_high
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
	STA grab_low
	LDA #>piece_data_j_0
	STA grab_high
	JMP draw_piece_collision
draw_piece_j_1
	LDA #<piece_data_j_1
	STA grab_low
	LDA #>piece_data_j_1
	STA grab_high
	JMP draw_piece_collision
draw_piece_j_2
	LDA #<piece_data_j_2
	STA grab_low
	LDA #>piece_data_j_2
	STA grab_high
	JMP draw_piece_collision
draw_piece_j_3
	LDA #<piece_data_j_3
	STA grab_low
	LDA #>piece_data_j_3
	STA grab_high
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
	STA grab_low
	LDA #>piece_data_l_0
	STA grab_high
	JMP draw_piece_collision
draw_piece_l_1
	LDA #<piece_data_l_1
	STA grab_low
	LDA #>piece_data_l_1
	STA grab_high
	JMP draw_piece_collision
draw_piece_l_2
	LDA #<piece_data_l_2
	STA grab_low
	LDA #>piece_data_l_2
	STA grab_high
	JMP draw_piece_collision
draw_piece_l_3
	LDA #<piece_data_l_3
	STA grab_low
	LDA #>piece_data_l_3
	STA grab_high
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
	STA grab_low
	LDA #>piece_data_s_0
	STA grab_high
	JMP draw_piece_collision
draw_piece_s_1
	LDA #<piece_data_s_1
	STA grab_low
	LDA #>piece_data_s_1
	STA grab_high
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
	STA grab_low
	LDA #>piece_data_z_0
	STA grab_high
	JMP draw_piece_collision
draw_piece_z_1
	LDA #<piece_data_z_1
	STA grab_low
	LDA #>piece_data_z_1
	STA grab_high
	JMP draw_piece_collision

draw_piece_collision
	TXA
	PHA
	LDA grab_high
	PHA
	LDA grab_low
	PHA
	LDA #$00
	PHA
	LDY #$00
draw_piece_collision_sub_1
	JSR grab_func
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
	INC grab_low
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
	BEQ draw_piece_collision_sub_4
	LDA #$55
	STA piece_color
draw_piece_collision_sub_3
	JMP draw_piece
draw_piece_collision_sub_4
	LDA #$00
	STA piece_color
	RTS

draw_piece_grid
	PLA
	STA grab_low
	PLA
	STA grab_high
	PLA
	TAX
	LDY #$00
draw_piece_grid_sub_1
	JSR grab_func
	BEQ draw_piece_grid_sub_2
	JSR grab_func
	AND piece_color
	STA grid_page,X
draw_piece_grid_sub_2
	INC grab_low
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
	CMP #$55
	BEQ draw_piece_grid_sub_3
	LDA #$AA
	STA piece_color
	RTS
draw_piece_grid_sub_3
	RTS


draw_grid
	LDX #$00
	LDY #$00
	LDA #$00
	STA block_x
	LDA #$00
	STA block_y
	LDA #$00
	PHA
draw_grid_sub_1
	LDA grid_page,X
	STA block_color
	CMP #$55
	BNE draw_grid_sub_2
	PLA
	CLC
	ADC #$01
	PHA
	LDA #$55
draw_grid_sub_2
	JSR draw_block
	INC block_x
	INY
	CPY #$0C
	BNE draw_grid_sub_3
	LDY #$00
	LDA #$00
	STA block_x
	PLA
	CMP #$0A
	BEQ draw_line
	LDA #$00
	PHA
	INC block_y
draw_grid_sub_3
	INX
	CPX #$FC
	BNE draw_grid_sub_1
	PLA
	RTS

draw_line
	INC lines_low
	LDA lines_low
	BNE draw_line_sub_1
	INC lines_high
draw_line_sub_1
	LDX block_y
	LDA #$00
draw_line_sub_2
	CLC
	ADC #$0C
	DEX
	BNE draw_line_sub_2
	CLC
	ADC #$0C
	TAX
	SEC
	SBC #$0C
	TAY
draw_line_sub_3
	LDA grid_page,Y
	STA grid_page,X
	DEX
	DEY
	BNE draw_line_sub_3
	JMP draw_grid
	

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






nmi
	PHA
	INC frame_counter
	LDA frame_counter
	CMP #$1E ; $1E = 30 frames at 60 Hz = 0.5 seconds
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


