
// Neo6502-Simulator.c

// To compile:  gcc -o Neo6502-Simulator.o Neo6502-Simulator.c -lglfw -lGL

// Simulates code for the Neo6502

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// uses OpenGL for graphics and keyboard
#include <GLFW/glfw3.h>
#include <GL/gl.h>

GLFWwindow* window;
int opengl_window_x = 640;
int opengl_window_y = 480;
int opengl_keyboard_state[512];


unsigned char cpu_memory[0x10000]; // 64KB of addressable space

unsigned long cpu_reg_a = 0x0000, cpu_reg_x = 0x0000, cpu_reg_y = 0x0000, cpu_reg_s = 0x00FD;
unsigned long cpu_flag_c = 0x0000, cpu_flag_z = 0x0000, cpu_flag_v = 0x0000, cpu_flag_n = 0x0000;
unsigned long cpu_flag_d = 0x0000, cpu_flag_b = 0x0000, cpu_flag_i = 0x0001; // needs to be 0x0001
unsigned long cpu_reg_pc = 0xFFFC;

unsigned long cpu_opcode = 0x0000, cpu_value = 0x0000, cpu_address = 0x0000; 
unsigned long cpu_result = 0x0000, cpu_cycles = 0x0000;

unsigned char cpu_read(unsigned long addr)
{
	return cpu_memory[addr];
}

void cpu_write(unsigned long addr, unsigned char val)
{
	if (addr < 0x8000)
	{
		cpu_memory[addr] = val;
	}
}

// cpu addressing modes
#define CPU_IMM { \
	cpu_value = (unsigned long)cpu_read(cpu_reg_pc++); }

#define CPU_ZPR { \
	cpu_value = (unsigned long)(cpu_memory[(unsigned long)cpu_read(cpu_reg_pc++)]&0x00FF); }

#define CPU_ZPW { \
	cpu_address = (unsigned long)cpu_read(cpu_reg_pc++); }

#define CPU_ZPM { \
	cpu_address = (unsigned long)cpu_read(cpu_reg_pc++); }

#define CPU_ZPXR { \
	cpu_value = (unsigned long)(cpu_memory[(((unsigned long)cpu_read(cpu_reg_pc++)+cpu_reg_x)&0x00FF)]&0x00FF); }

#define CPU_ZPXW { \
	cpu_address = (((unsigned long)cpu_read(cpu_reg_pc++)+cpu_reg_x)&0x00FF); }

#define CPU_ZPXM { \
	cpu_address = (((unsigned long)cpu_read(cpu_reg_pc++)+cpu_reg_x)&0x00FF); }

#define CPU_ZPYR { \
	cpu_value = (unsigned long)(cpu_memory[(((unsigned long)cpu_read(cpu_reg_pc++)+cpu_reg_y)&0x00FF)]&0x00FF); }

#define CPU_ZPYW { \
	cpu_address = (((unsigned long)cpu_read(cpu_reg_pc++)+cpu_reg_y)&0x00FF); }

#define CPU_ABSR { \
	cpu_address = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_address += ((unsigned long)cpu_read(cpu_reg_pc++)<<8); \
	cpu_value = (unsigned long)cpu_read(cpu_address); }

#define CPU_ABSW { \
	cpu_address = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_address += ((unsigned long)cpu_read(cpu_reg_pc++)<<8); }
	
#define CPU_ABSM { \
	cpu_address = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_address += ((unsigned long)cpu_read(cpu_reg_pc++)<<8); }

#define CPU_ABXR { \
	cpu_address = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_cycles += ((cpu_address+cpu_reg_x)>>8); \
	cpu_address += ((unsigned long)cpu_read(cpu_reg_pc++)<<8); \
	cpu_address += cpu_reg_x; \
	cpu_value = (unsigned long)cpu_read(cpu_address); }

#define CPU_ABXW { \
	cpu_address = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_cycles += ((cpu_address+cpu_reg_x)>>8); \
	cpu_address += ((unsigned long)cpu_read(cpu_reg_pc++)<<8); \
	cpu_address += cpu_reg_x; }
	
#define CPU_ABXM { \
	cpu_address = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_address += ((unsigned long)cpu_read(cpu_reg_pc++)<<8); \
	cpu_address += cpu_reg_x; }
	
#define CPU_ABYR { \
	cpu_address = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_cycles += ((cpu_address+cpu_reg_y)>>8); \
	cpu_address += ((unsigned long)cpu_read(cpu_reg_pc++)<<8); \
	cpu_address += cpu_reg_y; \
	cpu_value = (unsigned long)cpu_read(cpu_address); }

#define CPU_ABYW { \
	cpu_address = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_cycles += ((cpu_address+cpu_reg_y)>>8); \
	cpu_address += ((unsigned long)cpu_read(cpu_reg_pc++)<<8); \
	cpu_address += cpu_reg_y; }
	
#define CPU_INDXR { \
	cpu_value = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_address = (unsigned long)cpu_memory[((cpu_value+cpu_reg_x)&0x00FF)]+((unsigned long)cpu_memory[((cpu_value+cpu_reg_x+1)&0x00FF)]<<8); \
	cpu_value = (unsigned long)cpu_read(cpu_address); }

#define CPU_INDXW { \
	cpu_value = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_address = (unsigned long)cpu_memory[((cpu_value+cpu_reg_x)&0x00FF)]+((unsigned long)cpu_memory[((cpu_value+cpu_reg_x+1)&0x00FF)]<<8); }
	
#define CPU_INDYR { \
	cpu_value = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_address = (unsigned long)cpu_memory[cpu_value]+((unsigned long)cpu_memory[((cpu_value+1)&0x00FF)]<<8); \
	cpu_cycles += (((cpu_address&0x00FF)+cpu_reg_y)>>8); \
	cpu_address += cpu_reg_y; \
	cpu_value = (unsigned long)cpu_read(cpu_address); }

#define CPU_INDYW { \
	cpu_value = (unsigned long)cpu_read(cpu_reg_pc++); \
	cpu_address = (unsigned long)cpu_memory[cpu_value]+((unsigned long)cpu_memory[((cpu_value+1)&0x00FF)]<<8); \
	cpu_address += cpu_reg_y; }
	
// instructions
#define CPU_ADC { \
	cpu_result = cpu_reg_a+cpu_value+cpu_flag_c; \
	cpu_flag_c = (cpu_result>0x00FF); \
	cpu_result = (cpu_result&0x00FF); \
	cpu_flag_z = (cpu_result==0x0000); \
	cpu_flag_v = !(((cpu_reg_a^cpu_result)&0x80)&&((cpu_reg_a^cpu_value)&0x80)); \
	cpu_flag_n = (cpu_result>>7); \
	cpu_reg_a = cpu_result; }
	
#define CPU_AND { \
	cpu_reg_a = (cpu_reg_a&cpu_value); \
	cpu_flag_z = (cpu_reg_a==0x0000); \
	cpu_flag_n = (cpu_reg_a>>7); }
	
#define CPU_ASL { \
	cpu_value = (unsigned long)cpu_read(cpu_address); \
	cpu_flag_c = (cpu_value>>7); \
	cpu_value = ((cpu_value<<1)&0x00FF); \
	cpu_write(cpu_address,(unsigned char)(cpu_value & 0x00FF)); \
	cpu_flag_z = (cpu_value==0x0000); \
	cpu_flag_n = (cpu_value>>7); }
	
#define CPU_BIT { \
	cpu_flag_v = ((cpu_value>>6)&0x01); \
	cpu_flag_n = (cpu_value>>7); \
	cpu_value = (cpu_reg_a&cpu_value); \
	cpu_flag_z = (cpu_value == 0x0000); }
	
#define CPU_CMP { \
	cpu_flag_c = (cpu_reg_a>=cpu_value); \
	cpu_flag_z = (cpu_reg_a==cpu_value); \
	cpu_value = ((cpu_reg_a-cpu_value)&0x00FF); \
	cpu_flag_n = (cpu_value>>7); }
	
#define CPU_CPX { \
	cpu_flag_c = (cpu_reg_x>=cpu_value); \
	cpu_flag_z = (cpu_reg_x==cpu_value); \
	cpu_value = ((cpu_reg_x-cpu_value)&0x00FF); \
	cpu_flag_n = (cpu_value>>7); }
	
#define CPU_CPY { \
	cpu_flag_c = (cpu_reg_y>=cpu_value); \
	cpu_flag_z = (cpu_reg_y==cpu_value); \
	cpu_value = ((cpu_reg_y-cpu_value)&0x00FF); \
	cpu_flag_n = (cpu_value>>7); }
	
#define CPU_DEC { \
	cpu_value = (unsigned long)cpu_read(cpu_address); \
	cpu_value = ((cpu_value-1)&0x00FF); \
	cpu_write(cpu_address,(unsigned char)(cpu_value&0x00FF)); \
	cpu_flag_z = (cpu_value==0x0000); \
	cpu_flag_n = (cpu_value>>7); }

#define CPU_EOR { \
	cpu_reg_a = (cpu_reg_a^cpu_value); \
	cpu_flag_z = (cpu_reg_a==0x0000); \
	cpu_flag_n = (cpu_reg_a>>7); }

#define CPU_INC { \
	cpu_value = (unsigned long)cpu_read(cpu_address); \
	cpu_value = ((cpu_value+1)&0x00FF); \
	cpu_write(cpu_address,(unsigned char)(cpu_value&0x00FF)); \
	cpu_flag_z = (cpu_value==0x0000); \
	cpu_flag_n = (cpu_value>>7); }

#define CPU_LDA { \
	cpu_reg_a = cpu_value; \
	cpu_flag_z = (cpu_reg_a==0x0000); \
	cpu_flag_n = (cpu_reg_a>>7); }

#define CPU_LDX { \
	cpu_reg_x = cpu_value; \
	cpu_flag_z = (cpu_reg_x==0x0000); \
	cpu_flag_n = (cpu_reg_x>>7); }

#define CPU_LDY { \
	cpu_reg_y = cpu_value; \
	cpu_flag_z = (cpu_reg_y==0x0000); \
	cpu_flag_n = (cpu_reg_y>>7); }

#define CPU_LSR { \
	cpu_value = (unsigned long)cpu_read(cpu_address); \
	cpu_flag_c = (cpu_value&0x01); \
	cpu_value = (cpu_value>>1); \
	cpu_write(cpu_address,(unsigned char)(cpu_value&0x00FF)); \
	cpu_flag_z = (cpu_value==0x0000); \
	cpu_flag_n = (cpu_value>>7); }

#define CPU_ORA { \
	cpu_reg_a = (cpu_reg_a|cpu_value); \
	cpu_flag_z = (cpu_reg_a==0x0000); \
	cpu_flag_n = (cpu_reg_a>>7); }

#define CPU_ROL { \
	cpu_value = (unsigned long)cpu_read(cpu_address); \
	cpu_value = (((cpu_value<<1)&0x01FF)|cpu_flag_c); \
	cpu_flag_c = (cpu_value>>8); \
	cpu_value = (cpu_value&0x00FF); \
	cpu_write(cpu_address,(unsigned char)(cpu_value&0x00FF)); \
	cpu_flag_z = (cpu_value==0x0000); \
	cpu_flag_n = (cpu_value>>7); }

#define CPU_ROR { \
	cpu_value = (unsigned long)cpu_read(cpu_address); \
	cpu_value = (cpu_value|(cpu_flag_c<<8)); \
	cpu_flag_c = (cpu_value&0x01); \
	cpu_value = (cpu_value>>1); \
	cpu_write(cpu_address,(unsigned char)(cpu_value&0x00FF)); \
	cpu_flag_z = (cpu_value==0x0000); \
	cpu_flag_n = (cpu_value>>7); }

#define CPU_SBC { \
	cpu_result = cpu_reg_a-cpu_value-(0x00001-cpu_flag_c); \
	cpu_flag_c = (0x0001-((cpu_result&0x8000)>>15)); \
	cpu_result = (cpu_result&0x00FF); \
	cpu_flag_z = (cpu_result==0x0000); \
	cpu_flag_v = (((cpu_reg_a^cpu_result)&0x80)&&((cpu_reg_a^cpu_value)&0x80)); \
	cpu_flag_n = (cpu_result>>7); \
	cpu_reg_a = cpu_result; }

#define CPU_STA { \
	cpu_write(cpu_address, (unsigned char)(cpu_reg_a&0x00FF)); }

#define CPU_STX { \
	cpu_write(cpu_address, (unsigned char)(cpu_reg_x&0x00FF)); }

#define CPU_STY { \
	cpu_write(cpu_address, (unsigned char)(cpu_reg_y&0x00FF)); }

// internal functions
#define CPU_BRA { \
	cpu_address = cpu_reg_pc; \
	if (cpu_value > 127) cpu_reg_pc = (unsigned long)((cpu_reg_pc + cpu_value - 256) & 0x0000FFFF); \
	else cpu_reg_pc = (unsigned long)((cpu_reg_pc + cpu_value) & 0x0000FFFF); \
	cpu_cycles += ((cpu_address&0xFF00)!=(cpu_reg_pc&0xFF00)); }

#define CPU_PUSH { \
	cpu_memory[0x0100+(cpu_reg_s&0x00FF)]=cpu_value; \
	cpu_reg_s=((cpu_reg_s-1)&0x00FF); }

#define CPU_PULL { \
	cpu_reg_s=((cpu_reg_s+1)&0x00FF); \
	cpu_value=cpu_memory[(0x0100+(cpu_reg_s&0x00FF))]; }


void cpu_irq()
{	
	if (cpu_flag_i == 0)
	{
		//printf("IRQ %04X\n", (unsigned int)cpu_reg_pc);

		cpu_flag_b = 0;
				
		cpu_value = ((cpu_reg_pc)>>8);
		CPU_PUSH;
		cpu_value = ((cpu_reg_pc)&0x00FF);
		CPU_PUSH;
		cpu_value = ((cpu_flag_n<<7)|(cpu_flag_v<<6)|(0x20)|(cpu_flag_b<<4)|
			(cpu_flag_d<<3)|(cpu_flag_i<<2)|(cpu_flag_z<<1)|cpu_flag_c);
		CPU_PUSH;
		cpu_reg_pc = (unsigned long)cpu_read(0xFFFE);
		cpu_reg_pc += ((unsigned long)cpu_read(0xFFFF)<<8);
		
		cpu_flag_i = 1;
	}
}

void cpu_nmi()
{	
	//printf("NMI %04X\n", (unsigned int)cpu_reg_pc);
	
	cpu_flag_b = 0;

	cpu_value = ((cpu_reg_pc)>>8);
	CPU_PUSH;
	cpu_value = ((cpu_reg_pc)&0x00FF);
	CPU_PUSH;
	cpu_value = ((cpu_flag_n<<7)|(cpu_flag_v<<6)|(0x20)|(cpu_flag_b<<4)|
		(cpu_flag_d<<3)|(cpu_flag_i<<2)|(cpu_flag_z<<1)|cpu_flag_c);
	CPU_PUSH;
	cpu_reg_pc = (unsigned long)cpu_read(0xFFFA);
	cpu_reg_pc += ((unsigned long)cpu_read(0xFFFB)<<8);
}

void cpu_brk()
{
	//printf("BRK %04X\n", (unsigned int)cpu_reg_pc);
	
	cpu_flag_b = 1;

	cpu_reg_pc += 1; // add one to PC
	cpu_value = ((cpu_reg_pc)>>8);
	CPU_PUSH;
	cpu_value = ((cpu_reg_pc)&0x00FF);
	CPU_PUSH;
	cpu_value = ((cpu_flag_n<<7)|(cpu_flag_v<<6)|(0x20)|(cpu_flag_b<<4)|
		(cpu_flag_d<<3)|(cpu_flag_i<<2)|(cpu_flag_z<<1)|cpu_flag_c);
	CPU_PUSH;
	cpu_reg_pc = (unsigned long)cpu_read(0xFFFE);
	cpu_reg_pc += ((unsigned long)cpu_read(0xFFFF)<<8);

	cpu_flag_i = 1;
}

unsigned long cpu_run()
{	
	cpu_opcode = (unsigned long)cpu_read(cpu_reg_pc++);

	switch (cpu_opcode)
	{
		// ADC
		case 0x69: { cpu_cycles = 2; CPU_IMM; CPU_ADC; break; }
		case 0x65: { cpu_cycles = 3; CPU_ZPR; CPU_ADC; break; }
		case 0x75: { cpu_cycles = 4; CPU_ZPXR; CPU_ADC; break; }
		case 0x6D: { cpu_cycles = 4; CPU_ABSR; CPU_ADC; break; }
		case 0x7D: { cpu_cycles = 4; CPU_ABXR; CPU_ADC; break; }
		case 0x79: { cpu_cycles = 4; CPU_ABYR; CPU_ADC; break; }
		case 0x61: { cpu_cycles = 6; CPU_INDXR; CPU_ADC; break; }
		case 0x71: { cpu_cycles = 5; CPU_INDYR; CPU_ADC; break; }
		
		// AND
		case 0x29: { cpu_cycles = 2; CPU_IMM; CPU_AND; break; }
		case 0x25: { cpu_cycles = 3; CPU_ZPR; CPU_AND; break; }
		case 0x35: { cpu_cycles = 4; CPU_ZPXR; CPU_AND; break; }
		case 0x2D: { cpu_cycles = 4; CPU_ABSR; CPU_AND; break; }
		case 0x3D: { cpu_cycles = 4; CPU_ABXR; CPU_AND; break; }
		case 0x39: { cpu_cycles = 4; CPU_ABYR; CPU_AND; break; }
		case 0x21: { cpu_cycles = 6; CPU_INDXR; CPU_AND; break; }
		case 0x31: { cpu_cycles = 5; CPU_INDYR; CPU_AND; break; }
		
		// ASL
		case 0x0A:
		{
			cpu_cycles = 0x0002;
			cpu_flag_c = (cpu_reg_a>>7);
			cpu_reg_a = ((cpu_reg_a<<1)&0x00FF);
			cpu_flag_z = (cpu_reg_a==0x0000);
			cpu_flag_n = (cpu_reg_a>>7);
			break;
		}
		case 0x06: { cpu_cycles = 5; CPU_ZPM; CPU_ASL; break; }
		case 0x16: { cpu_cycles = 6; CPU_ZPXM; CPU_ASL; break; }
		case 0x0E: { cpu_cycles = 6; CPU_ABSM; CPU_ASL; break; }
		case 0x1E: { cpu_cycles = 7; CPU_ABXM; CPU_ASL; break; }
		
		// BCC
		case 0x90: { cpu_cycles = 2; CPU_IMM; 
			if (cpu_flag_c == 0x0000) { cpu_cycles = 3; CPU_BRA; } break; }
		// BCS
		case 0xB0: { cpu_cycles = 2; CPU_IMM; 
			if (cpu_flag_c != 0x0000) { cpu_cycles = 3; CPU_BRA; } break; }
		// BEQ
		case 0xF0: { cpu_cycles = 2; CPU_IMM; 
			if (cpu_flag_z != 0x0000) { cpu_cycles = 3; CPU_BRA; } break; }
		
		// BIT
		case 0x24: { cpu_cycles = 3; CPU_ZPR; CPU_BIT; break; }
		case 0x2C: { cpu_cycles = 4; CPU_ABSR; CPU_BIT; break; }
	
		// BMI
		case 0x30: { cpu_cycles = 2; CPU_IMM; 
			if (cpu_flag_n != 0x0000) { cpu_cycles = 3; CPU_BRA; } break; }
		// BNE
		case 0xD0: { cpu_cycles = 2; CPU_IMM; 
			if (cpu_flag_z == 0x0000) { cpu_cycles = 3; CPU_BRA; } break; }
		// BPL
		case 0x10: { cpu_cycles = 2; CPU_IMM; 
			if (cpu_flag_n == 0x0000) { cpu_cycles = 3; CPU_BRA; } break; }
		
		// BRK
		case 0x00:
		{
			cpu_cycles = 0x0007;
			cpu_brk();
			break;
		}
		
		// BVC
		case 0x50:
		{
			cpu_cycles = 0x0002;
			cpu_value = (unsigned long)cpu_read(cpu_reg_pc++);
			if (cpu_flag_v == 0x0000) { cpu_cycles = 3; CPU_BRA; }
			break;
		}
		
		// BVS
		case 0x70:
		{
			cpu_cycles = 0x0002;
			cpu_value = (unsigned long)cpu_read(cpu_reg_pc++);
			if (cpu_flag_v != 0x0000) { cpu_cycles = 3; CPU_BRA; }
			break;
		}
		
		// CLC
		case 0x18:
		{
			cpu_cycles = 0x0002;
			cpu_flag_c = 0x0000;
			break;
		}
		
		// CLD
		case 0xD8:
		{
			cpu_cycles = 0x0002;
			cpu_flag_d = 0x0000;
			break;
		}
		
		// CLI
		case 0x58:
		{
			cpu_cycles = 0x0002;
			cpu_flag_i = 0x0000;
			break;
		}
		
		// CLV
		case 0xB8:
		{
			cpu_cycles = 0x0002;
			cpu_flag_v = 0x0000;
			break;
		}
		
		// CMP
		case 0xC9: { cpu_cycles = 2; CPU_IMM; CPU_CMP; break; }
		case 0xC5: { cpu_cycles = 3; CPU_ZPR; CPU_CMP; break; }
		case 0xD5: { cpu_cycles = 4; CPU_ZPXR; CPU_CMP; break; }
		case 0xCD: { cpu_cycles = 4; CPU_ABSR; CPU_CMP; break; }
		case 0xDD: { cpu_cycles = 4; CPU_ABXR; CPU_CMP; break; }
		case 0xD9: { cpu_cycles = 4; CPU_ABYR; CPU_CMP; break; }
		case 0xC1: { cpu_cycles = 6; CPU_INDXR; CPU_CMP; break; }
		case 0xD1: { cpu_cycles = 5; CPU_INDYR; CPU_CMP; break; }
		
		// CPX
		case 0xE0: { cpu_cycles = 2; CPU_IMM; CPU_CPX; break; }
		case 0xE4: { cpu_cycles = 3; CPU_ZPR; CPU_CPX; break; }
		case 0xEC: { cpu_cycles = 4; CPU_ABSR; CPU_CPX; break; }
		
		// CPY
		case 0xC0: { cpu_cycles = 2; CPU_IMM; CPU_CPY; break; }
		case 0xC4: { cpu_cycles = 3; CPU_ZPR; CPU_CPY; break; }
		case 0xCC: { cpu_cycles = 4; CPU_ABSR; CPU_CPY; break; }
		
		// DEC
		case 0xC6: { cpu_cycles = 5; CPU_ZPM; CPU_DEC; break; }
		case 0xD6: { cpu_cycles = 6; CPU_ZPXM; CPU_DEC; break; }
		case 0xCE: { cpu_cycles = 6; CPU_ABSM; CPU_DEC; break; }
		case 0xDE: { cpu_cycles = 7; CPU_ABXM; CPU_DEC; break; }
		
		// DEX
		case 0xCA:
		{
			cpu_cycles = 0x0002;
			cpu_reg_x = ((cpu_reg_x-1) & 0x00FF);
			cpu_flag_z = (cpu_reg_x == 0x0000);
			cpu_flag_n = (cpu_reg_x >> 7);
			break;
		}
		
		// DEY
		case 0x88:
		{
			cpu_cycles = 0x0002;
			cpu_reg_y = ((cpu_reg_y-1) & 0x00FF);
			cpu_flag_z = (cpu_reg_y == 0x0000);
			cpu_flag_n = (cpu_reg_y >> 7);
			break;
		}
		
		// EOR
		case 0x49: { cpu_cycles = 2; CPU_IMM; CPU_EOR; break; }
		case 0x45: { cpu_cycles = 3; CPU_ZPR; CPU_EOR; break; }
		case 0x55: { cpu_cycles = 4; CPU_ZPXR; CPU_EOR; break; }
		case 0x4D: { cpu_cycles = 4; CPU_ABSR; CPU_EOR; break; }
		case 0x5D: { cpu_cycles = 4; CPU_ABXR; CPU_EOR; break; }
		case 0x59: { cpu_cycles = 4; CPU_ABYR; CPU_EOR; break; }
		case 0x41: { cpu_cycles = 6; CPU_INDXR; CPU_EOR; break; }
		case 0x51: { cpu_cycles = 5; CPU_INDYR; CPU_EOR; break; }
		
		// INC
		case 0xE6: { cpu_cycles = 5; CPU_ZPM; CPU_INC; break; }
		case 0xF6: { cpu_cycles = 6; CPU_ZPXM; CPU_INC; break; }
		case 0xEE: { cpu_cycles = 6; CPU_ABSM; CPU_INC; break; }
		case 0xFE: { cpu_cycles = 7; CPU_ABXM; CPU_INC; break; }
		
		// INX
		case 0xE8:
		{
			cpu_cycles = 0x0002;
			cpu_reg_x = ((cpu_reg_x+1) & 0x00FF);
			cpu_flag_z = (cpu_reg_x == 0x0000);
			cpu_flag_n = (cpu_reg_x >> 7);
			break;
		}
		
		// INY
		case 0xC8:
		{
			cpu_cycles = 0x0002;
			cpu_reg_y = ((cpu_reg_y+1) & 0x00FF);
			cpu_flag_z = (cpu_reg_y == 0x0000);
			cpu_flag_n = (cpu_reg_y >> 7);
			break;
		}
		
		// JMP
		case 0x4C:
		{
			cpu_cycles = 0x0003;
			cpu_address = (unsigned long)cpu_read(cpu_reg_pc++);
			cpu_address += ((unsigned long)cpu_read(cpu_reg_pc++)<<8);
			cpu_reg_pc = cpu_address;
			break;
		}
		case 0x6C:
		{
			cpu_cycles = 0x0005;
			cpu_address = (unsigned long)cpu_read(cpu_reg_pc++);
			cpu_address += ((unsigned long)cpu_read(cpu_reg_pc++)<<8);
			cpu_value = (unsigned long)cpu_read(cpu_address);
			cpu_value += (unsigned long)(cpu_read((cpu_address&0xFF00)|(((cpu_address&0x00FF)+1)&0x00FF))<<8);
			cpu_reg_pc = cpu_value;
			break;
		}
		
		// JSR
		case 0x20:
		{
			cpu_cycles = 0x0006;
			cpu_value = ((cpu_reg_pc+1)>>8);
			CPU_PUSH;
			cpu_value = ((cpu_reg_pc+1)&0x00FF);
			CPU_PUSH;
			cpu_address = (unsigned long)cpu_read(cpu_reg_pc++);
			cpu_address += ((unsigned long)cpu_read(cpu_reg_pc)<<8);
			cpu_reg_pc = cpu_address;
			break;
		}
		
		// LDA
		case 0xA9: { cpu_cycles = 2; CPU_IMM; CPU_LDA; break; }
		case 0xA5: { cpu_cycles = 3; CPU_ZPR; CPU_LDA; break; }
		case 0xB5: { cpu_cycles = 4; CPU_ZPXR; CPU_LDA; break; }
		case 0xAD: { cpu_cycles = 4; CPU_ABSR; CPU_LDA; break; }
		case 0xBD: { cpu_cycles = 4; CPU_ABXR; CPU_LDA; break; }
		case 0xB9: { cpu_cycles = 4; CPU_ABYR; CPU_LDA; break; }
		case 0xA1: { cpu_cycles = 6; CPU_INDXR; CPU_LDA; break; }
		case 0xB1: { cpu_cycles = 5; CPU_INDYR; CPU_LDA; break; }
		
		// LDX
		case 0xA2: { cpu_cycles = 2; CPU_IMM; CPU_LDX; break; }
		case 0xA6: { cpu_cycles = 3; CPU_ZPR; CPU_LDX; break; }
		case 0xB6: { cpu_cycles = 4; CPU_ZPYR; CPU_LDX; break; }
		case 0xAE: { cpu_cycles = 4; CPU_ABSR; CPU_LDX; break; }
		case 0xBE: { cpu_cycles = 4; CPU_ABYR; CPU_LDX; break; }
		
		// LDY
		case 0xA0: { cpu_cycles = 2; CPU_IMM; CPU_LDY; break; }
		case 0xA4: { cpu_cycles = 3; CPU_ZPR; CPU_LDY; break; }
		case 0xB4: { cpu_cycles = 4; CPU_ZPXR; CPU_LDY; break; }
		case 0xAC: { cpu_cycles = 4; CPU_ABSR; CPU_LDY; break; }
		case 0xBC: { cpu_cycles = 4; CPU_ABXR; CPU_LDY; break; }
		
		// LSR
		case 0x4A:
		{
			cpu_cycles = 0x0002;
			cpu_flag_c = (cpu_reg_a&0x01);
			cpu_reg_a = (cpu_reg_a>>1);
			cpu_flag_z = (cpu_reg_a==0x0000);
			cpu_flag_n = (cpu_reg_a>>7);
			break;
		}
		case 0x46: { cpu_cycles = 5; CPU_ZPM; CPU_LSR; break; }
		case 0x56: { cpu_cycles = 6; CPU_ZPXM; CPU_LSR; break; }
		case 0x4E: { cpu_cycles = 6; CPU_ABSM; CPU_LSR; break; }
		case 0x5E: { cpu_cycles = 7; CPU_ABXM; CPU_LSR; break; }
		
		// NOP
		case 0xEA:
		{
			cpu_cycles = 0x0002;
			break;
		}
		
		// ORA
		case 0x09: { cpu_cycles = 2; CPU_IMM; CPU_ORA; break; }
		case 0x05: { cpu_cycles = 3; CPU_ZPR; CPU_ORA; break; }
		case 0x15: { cpu_cycles = 4; CPU_ZPXR; CPU_ORA; break; }
		case 0x0D: { cpu_cycles = 4; CPU_ABSR; CPU_ORA; break; }
		case 0x1D: { cpu_cycles = 4; CPU_ABXR; CPU_ORA; break; }
		case 0x19: { cpu_cycles = 4; CPU_ABYR; CPU_ORA; break; }
		case 0x01: { cpu_cycles = 6; CPU_INDXR; CPU_ORA; break; }
		case 0x11: { cpu_cycles = 5; CPU_INDYR; CPU_ORA; break; }
		
		// PHA
		case 0x48:
		{
			cpu_cycles = 0x0003;
			cpu_value = cpu_reg_a;
			CPU_PUSH;
			break;
		}
		
		// PHP
		case 0x08:
		{
			cpu_cycles = 0x0003;
			cpu_flag_b = 1;
			cpu_value = ((cpu_flag_n<<7)|(cpu_flag_v<<6)|(0x20)|(cpu_flag_b<<4)|
				(cpu_flag_d<<3)|(cpu_flag_i<<2)|(cpu_flag_z<<1)|cpu_flag_c);
			CPU_PUSH;
			break;
		}
		
		// PLA
		case 0x68:
		{
			cpu_cycles = 0x0004;
			CPU_PULL;
			cpu_reg_a = cpu_value;
			cpu_flag_z = (cpu_reg_a==0);
			cpu_flag_n = (cpu_reg_a>>7);
			break;
		}
		
		// PLP
		case 0x28:
		{
			cpu_cycles = 0x0004;
			CPU_PULL;
			cpu_flag_n = (cpu_value>>7);
			cpu_flag_v = ((cpu_value>>6)&0x01);
			cpu_flag_d = ((cpu_value>>3)&0x01);
			cpu_flag_i = ((cpu_value>>2)&0x01);
			cpu_flag_z = ((cpu_value>>1)&0x01);
			cpu_flag_c = (cpu_value&0x01);
			break;
		}
		
		// ROL
		case 0x2A:
		{
			cpu_cycles = 0x0002;
			cpu_reg_a = (((cpu_reg_a<<1)&0x01FF)|cpu_flag_c);
			cpu_flag_c = (cpu_reg_a>>8);
			cpu_reg_a = (cpu_reg_a&0x00FF);
			cpu_flag_z = (cpu_reg_a==0x0000);
			cpu_flag_n = (cpu_reg_a>>7);
			break;
		}
		case 0x26: { cpu_cycles = 5; CPU_ZPM; CPU_ROL; break; }
		case 0x36: { cpu_cycles = 6; CPU_ZPXM; CPU_ROL; break; }
		case 0x2E: { cpu_cycles = 6; CPU_ABSM; CPU_ROL; break; }
		case 0x3E: { cpu_cycles = 7; CPU_ABXM; CPU_ROL; break; }

		// ROR
		case 0x6A:
		{
			cpu_cycles = 0x0002;
			cpu_reg_a = (cpu_reg_a|(cpu_flag_c<<8));
			cpu_flag_c = (cpu_reg_a&0x01);
			cpu_reg_a = (cpu_reg_a>>1);
			cpu_flag_z = (cpu_reg_a==0x0000);
			cpu_flag_n = (cpu_reg_a>>7);
			break;
		}
		case 0x66: { cpu_cycles = 5; CPU_ZPM; CPU_ROR; break; }
		case 0x76: { cpu_cycles = 6; CPU_ZPXM; CPU_ROR; break; }
		case 0x6E: { cpu_cycles = 6; CPU_ABSM; CPU_ROR; break; }
		case 0x7E: { cpu_cycles = 7; CPU_ABXM; CPU_ROR; break; }	
		
		// RTI
		case 0x40:
		{
			cpu_cycles = 0x0006;
			CPU_PULL;
			cpu_flag_n = ((cpu_value>>7)&0x01);
			cpu_flag_v = ((cpu_value>>6)&0x01);
			cpu_flag_d = ((cpu_value>>3)&0x01);
			cpu_flag_i = ((cpu_value>>2)&0x01);
			cpu_flag_z = ((cpu_value>>1)&0x01);
			cpu_flag_c = (cpu_value&0x01);
			CPU_PULL;
			cpu_reg_pc = cpu_value;
			CPU_PULL;
			cpu_reg_pc += (cpu_value<<8);	
			
			break;
		}
		
		// RTS
		case 0x60:
		{
			cpu_cycles = 0x0006;
			CPU_PULL;
			cpu_reg_pc = cpu_value;
			CPU_PULL;
			cpu_reg_pc += (cpu_value<<8)+1;
			break;
		}
		
		// SBC
		case 0xE9: { cpu_cycles = 2; CPU_IMM; CPU_SBC; break; }
		case 0xE5: { cpu_cycles = 3; CPU_ZPR; CPU_SBC; break; }
		case 0xF5: { cpu_cycles = 4; CPU_ZPXR; CPU_SBC; break; }
		case 0xED: { cpu_cycles = 4; CPU_ABSR; CPU_SBC; break; }
		case 0xFD: { cpu_cycles = 4; CPU_ABXR; CPU_SBC; break; }
		case 0xF9: { cpu_cycles = 4; CPU_ABYR; CPU_SBC; break; }
		case 0xE1: { cpu_cycles = 6; CPU_INDXR; CPU_SBC; break; }
		case 0xF1: { cpu_cycles = 5; CPU_INDYR; CPU_SBC; break; }
		
		// SEC
		case 0x38:
		{
			cpu_cycles = 0x0002;
			cpu_flag_c = 0x0001;
			break;
		}
		
		// SED
		case 0xF8:
		{
			cpu_cycles = 0x0002;
			cpu_flag_d = 0x0001;
			break;
		}
		
		// SEI
		case 0x78:
		{
			cpu_cycles = 0x0002;
			cpu_flag_i = 0x0001;
			break;
		}
		
		// STA
		case 0x85: { CPU_ZPW; CPU_STA; cpu_cycles = 3; break; }
		case 0x95: { CPU_ZPXW; CPU_STA; cpu_cycles = 4; break; }
		case 0x8D: { CPU_ABSW; CPU_STA; cpu_cycles = 4; break; }
		case 0x9D: { CPU_ABXW; CPU_STA; cpu_cycles = 5; break; }
		case 0x99: { CPU_ABYW; CPU_STA; cpu_cycles = 5; break; }
		case 0x81: { CPU_INDXW; CPU_STA; cpu_cycles = 6; break; }
		case 0x91: { CPU_INDYW; CPU_STA; cpu_cycles = 6; break; }
		
		// STX
		case 0x86: { CPU_ZPW; CPU_STX; cpu_cycles = 3; break; }
		case 0x96: { CPU_ZPYW; CPU_STX; cpu_cycles = 4; break; }
		case 0x8E: { CPU_ABSW; CPU_STX; cpu_cycles = 4; break; }
		
		// STY
		case 0x84: { CPU_ZPW; CPU_STY; cpu_cycles = 3; break; }
		case 0x94: { CPU_ZPXW; CPU_STY; cpu_cycles = 4; break; }
		case 0x8C: { CPU_ABSW; CPU_STY; cpu_cycles = 4; break; }
		
		// TAX
		case 0xAA:
		{
			cpu_cycles = 0x0002;
			cpu_reg_x = cpu_reg_a;
			cpu_flag_z = (cpu_reg_x==0);
			cpu_flag_n = (cpu_reg_x>>7);
			break;
		}
		
		// TAY
		case 0xA8:
		{
			cpu_cycles = 0x0002;
			cpu_reg_y = cpu_reg_a;
			cpu_flag_z = (cpu_reg_y==0);
			cpu_flag_n = (cpu_reg_y>>7);
			break;
		}
		
		// TSX
		case 0xBA:
		{
			cpu_cycles = 0x0002;
			cpu_reg_x = cpu_reg_s;
			cpu_flag_z = (cpu_reg_x==0);
			cpu_flag_n = (cpu_reg_x>>7);
			break;
		}
		
		// TXA
		case 0x8A:
		{
			cpu_cycles = 0x0002;
			cpu_reg_a = cpu_reg_x;
			cpu_flag_z = (cpu_reg_a==0);
			cpu_flag_n = (cpu_reg_a>>7);
			break;
		}
		
		// TXS
		case 0x9A:
		{
			cpu_cycles = 0x0002;
			cpu_reg_s = cpu_reg_x;
			cpu_flag_z = (cpu_reg_s==0);
			cpu_flag_n = (cpu_reg_s>>7);
			break;
		}
		
		// TYA
		case 0x98:
		{
			cpu_cycles = 0x0002;
			cpu_reg_a = cpu_reg_y;
			cpu_flag_z = (cpu_reg_a==0);
			cpu_flag_n = (cpu_reg_a>>7);
			break;
		}
		
		default:
		{
			cpu_cycles = 0x0000;
		}
	}
	
	return cpu_cycles;
}


// OpenGL function
void InitializeOpenGLSettings()
{
	// set up the init settings
	glViewport(0, 0, opengl_window_x, opengl_window_y);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glClearColor(0.1f, 0.1f, 0.1f, 0.5f);   

	return;
};

// OpenGL function
void handleKeys(GLFWwindow *window, int key, int scancode, int action, int mods)
{
	if (action == GLFW_PRESS)
	{
		opengl_keyboard_state[key] = 1;

		switch (key)
		{
			case GLFW_KEY_ESCAPE:
			{
				glfwSetWindowShouldClose(window, GLFW_TRUE);
			
				break;
			}
	
			case GLFW_KEY_F1:
			{
				const GLFWvidmode* mode = glfwGetVideoMode(glfwGetPrimaryMonitor());

				glfwSetWindowMonitor(window, glfwGetPrimaryMonitor(), 0, 0, mode->width, mode->height, mode->refreshRate);

				opengl_window_x = mode->width;
				opengl_window_y = mode->height;

				break;
			}

			case GLFW_KEY_F2:
			{
				const GLFWvidmode* mode = glfwGetVideoMode(glfwGetPrimaryMonitor());

				glfwSetWindowMonitor(window, NULL, 0, 0, 640, 480, mode->refreshRate);

				opengl_window_x = 640;
				opengl_window_y = 480;

				break;
			}

			default: {}
		}
	}
	else if (action == GLFW_RELEASE)
	{
		opengl_keyboard_state[key] = 0;
	}

	return;
};

// OpenGL function
void handleResize(GLFWwindow *window, int width, int height)
{
	glfwGetWindowSize(window, &width, &height);	

	opengl_window_x = width;
	opengl_window_y = height;
	
	glViewport(0, 0, width, height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	InitializeOpenGLSettings();

	return;
};

// expects 32KB ROM file
int main(const int argc, const char **argv)
{
	if (argc < 2)
	{
		printf("Arguments: <program.bin>\n");
		return 0;
	}

	// randomize memory
	for (unsigned long i=0; i<0x10000; i++)
	{
		cpu_memory[i] = (rand() % 256);
	}

	// load ROM
	FILE *input = NULL;

	input = fopen(argv[1], "rb");
	if (!input)
	{
		printf("Error!\n");
		return 0;
	}

	int bytes = 1;
	unsigned char buffer = 0;
	unsigned long addr = 0x8000;
	
	while (bytes > 0)
	{
		bytes = fscanf(input, "%c", &buffer);

		if (bytes > 0)
		{
			cpu_memory[addr] = buffer;
			addr++;

			if (addr >= 0x10000)
			{
				break;
			}
		}
	}

	fclose(input);

	// reset vector
	cpu_reg_pc = (unsigned char)cpu_memory[0xFFFC] + ((unsigned char)cpu_memory[0xFFFD] << 8);

	// OpenGL initialization
	if (!glfwInit()) return 0;
	window = glfwCreateWindow(opengl_window_x, opengl_window_y, "Neo6502", NULL, NULL);
	if (!window) { glfwTerminate(); return 0; }
	glfwMakeContextCurrent(window);
	InitializeOpenGLSettings();
	for (int i=0; i<512; i++) opengl_keyboard_state[i] = 0;
	glfwSetInputMode(window, GLFW_STICKY_KEYS, GLFW_TRUE);
	glfwSetKeyCallback(window, handleKeys);
	glfwSetWindowSizeCallback(window, handleResize);

	unsigned long previous_clock = 0;

	unsigned long temp_cycles = 0;
	unsigned long scanline_cycles = 0;
	unsigned long frame_cycles = 0;

	unsigned char color_byte = 0;

	unsigned char running, loop;

	running = 1;

	while (running > 0)
	{
		loop = 1;

		while (loop > 0)
		{
			temp_cycles = cpu_run();

			scanline_cycles += temp_cycles;

			if (scanline_cycles >= 100) // for 3.14 MHz
			{
				scanline_cycles -= 100;
	
				cpu_irq(); // once every scanline

				if (cpu_flag_i == 0) frame_cycles += 7;
			}

			frame_cycles += temp_cycles;

			if (frame_cycles >= 52448) // for 3.14 MHz
			{
				frame_cycles -= 52448;
		
				cpu_nmi(); // once every frame
				
				frame_cycles += 7;

				loop = 0;
			}

			if (opengl_keyboard_state[GLFW_KEY_W] == 1) { }
			if (opengl_keyboard_state[GLFW_KEY_S] == 1) { }
			if (opengl_keyboard_state[GLFW_KEY_A] == 1) { }
			if (opengl_keyboard_state[GLFW_KEY_D] == 1) { }

			if (opengl_keyboard_state[GLFW_KEY_I] == 1) { }
			if (opengl_keyboard_state[GLFW_KEY_K] == 1) { }
			if (opengl_keyboard_state[GLFW_KEY_J] == 1) { }
			if (opengl_keyboard_state[GLFW_KEY_L] == 1) { }
		}

		if (glfwWindowShouldClose(window)) running = 0; // makes ESCAPE exit program

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glLoadIdentity();

		glBegin(GL_QUADS);

		for (unsigned long j=0; j<240; j++)
		{
			for (unsigned long i=0; i<80; i++)
			{
				color_byte = cpu_memory[j*128 + i + 0x0800];

				for (unsigned long k=0; k<4; k++)
				{
					if ((color_byte & 0xC0) == 0xC0) // white
					{
						glColor3f(1.0f, 1.0f, 1.0f); // white
					}
					else if ((color_byte & 0xC0) == 0x80) // red/orange
					{
						//glColor3f(1.0f, 0.0f, 0.0f); // red
						glColor3f(618.0f/700.0f, 308.0f/700.0f, 0.0f); // orange
					}
					else if ((color_byte & 0xC0) == 0x40) // cyan/blue
					{
						//glColor3f(0.0f, 1.0f, 1.0f); // cyan
						glColor3f(0.0f, 308.0f/700.0f, 618.0f/700.0f); // blue
					}
					else if ((color_byte & 0xC0) == 0x00) // black
					{
						glColor3f(0.0f, 0.0f, 0.0f);
					}

					color_byte = color_byte << 2;

					glVertex2f(-1.0f + 1.0f * (float)(i*8+0+2*k) / 256.0f, 1.0f - 1.0f * (float)(j*2+0) / 240.0f);
					glVertex2f(-1.0f + 1.0f * (float)(i*8+0+2*k) / 256.0f, 1.0f - 1.0f * (float)(j*2+2) / 240.0f);
					glVertex2f(-1.0f + 1.0f * (float)(i*8+2+2*k) / 256.0f, 1.0f - 1.0f * (float)(j*2+2) / 240.0f);
					glVertex2f(-1.0f + 1.0f * (float)(i*8+2+2*k) / 256.0f, 1.0f - 1.0f * (float)(j*2+0) / 240.0f);
				}
			}
		}

		glEnd();

		glfwSwapInterval(0); // turn off v-sync
		glfwSwapBuffers(window);
		glfwPollEvents();

		while (clock() < previous_clock + 16667) { } // for 60 Hz
		previous_clock = clock();	
	}

	return 1;
}

