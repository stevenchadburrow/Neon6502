
// Neo6502-SyncSignals.c

// Generates 64KB of sync signals for the Flash ROM

/*
VGA Signal 640 x 480 @ 60 Hz Industry standard timing

General timing
Screen refresh rate	60 Hz
Vertical refresh	31.46875 kHz
Pixel freq.	25.175 MHz
Horizontal timing (line)
Polarity of horizontal sync pulse is negative.

Scanline part	Pixels	Time [µs]
Visible area	640	25.422045680238
Front porch	16	0.63555114200596
Sync pulse	96	3.8133068520357
Back porch	48	1.9066534260179
Whole line	800	31.777557100298
Vertical timing (frame)
Polarity of vertical sync pulse is negative.

Frame part	Lines	Time [ms]
Visible area	480	15.253227408143
Front porch	10	0.31777557100298
Sync pulse	2	0.063555114200596
Back porch	33	1.0486593843098
Whole frame	525	16.683217477656
*/

// Signals:
// D0 = H-RESET (active low)
// D1 = !H-RESET (inverted)
// D2 = V-RESET (active low)
// D3 = H-SYNC (active low)
// D4 = V-SYNC (active low)
// D5 = VISIBLE (active high)
// D6 = !IRQ (active low)
// D7 = !NMI (active low)

#include <stdio.h>
#include <stdlib.h>

FILE *out_file;

// requires format 1010_0101
// starting from D7 -> D0
unsigned char out_byte(char *s)
{
	unsigned char val = 0x00;

	// D7
	if (s[0] == '0') val &= 0x7F;
	else if (s[0] == '1') val |= 0x80;

	// D6
	if (s[1] == '0') val &= 0xBF;
	else if (s[1] == '1') val |= 0x40;

	// D5
	if (s[2] == '0') val &= 0xDF;
	else if (s[2] == '1') val |= 0x20;

	// D4
	if (s[3] == '0') val &= 0xEF;
	else if (s[3] == '1') val |= 0x10;

	// skip s[4]

	// D3
	if (s[5] == '0') val &= 0xF7;
	else if (s[5] == '1') val |= 0x08;

	// D2
	if (s[6] == '0') val &= 0xFB;
	else if (s[6] == '1') val |= 0x04;

	// D1
	if (s[7] == '0') val &= 0xFD;
	else if (s[7] == '1') val |= 0x02;

	// D0
	if (s[8] == '0') val &= 0xFE;
	else if (s[8] == '1') val |= 0x01;
	
	return val;
}

int main()
{
	out_file = NULL;

	out_file = fopen("Neo6502-SyncSignals.bin", "wt");
	if (!out_file)
	{
		printf("Error!\n");
		return 0;
	}

	for (int y=0; y<16; y++) // vertical back porch
	{
		for (int x=0; x<80; x++) // visible region
		{
			fprintf(out_file, "%c", out_byte("1101_1101"));
		}

		for (int x=0; x<2; x++) // front porch
		{
			fprintf(out_file, "%c", out_byte("1001_1101")); // IRQ triggered here
		}
		
		for (int x=0; x<12; x++) // horizontal sync
		{
			fprintf(out_file, "%c", out_byte("1101_0101"));
		}
	
		for (int x=0; x<5; x++) // back porch
		{
			fprintf(out_file, "%c", out_byte("1101_1101"));
		}

		fprintf(out_file, "%c", out_byte("1101_1110")); // horizontal reset

		for (int x=0; x<28; x++) // filler
		{
			fprintf(out_file, "%c", out_byte("1101_1110")); // horizontal reset
		}
	}

	for (int y=0; y<240; y++) // vertical visible region
	{
		for (int x=0; x<80; x++) // visible region
		{
			fprintf(out_file, "%c", out_byte("1111_1101"));
		}

		for (int x=0; x<2; x++) // front porch
		{
			fprintf(out_file, "%c", out_byte("1001_1101")); // IRQ triggered here
		}
		
		for (int x=0; x<12; x++) // horizontal sync
		{
			fprintf(out_file, "%c", out_byte("1101_0101"));
		}
	
		for (int x=0; x<5; x++) // back porch
		{
			fprintf(out_file, "%c", out_byte("1101_1101"));
		}

		fprintf(out_file, "%c", out_byte("1101_1110")); // horizontal reset

		for (int x=0; x<28; x++) // filler
		{
			fprintf(out_file, "%c", out_byte("1101_1110")); // horizontal reset
		}
	}

	for (int y=0; y<5; y++) // vertical front porch
	{
		for (int x=0; x<80; x++) // visible region
		{
			fprintf(out_file, "%c", out_byte("1101_1101"));
		}

		for (int x=0; x<2; x++) // front porch
		{
			fprintf(out_file, "%c", out_byte("1001_1101")); // IRQ triggered here
		}
		
		for (int x=0; x<12; x++) // horizontal sync
		{
			fprintf(out_file, "%c", out_byte("1101_0101"));
		}
	
		for (int x=0; x<5; x++) // back porch
		{
			fprintf(out_file, "%c", out_byte("1101_1101"));
		}

		fprintf(out_file, "%c", out_byte("1101_1110")); // horizontal reset

		for (int x=0; x<28; x++) // filler
		{
			fprintf(out_file, "%c", out_byte("1101_1110")); // horizontal reset
		}
	}

	for (int y=0; y<1; y++) // vertical sync (NMI triggered here)
	{
		for (int x=0; x<80; x++) // visible region
		{
			fprintf(out_file, "%c", out_byte("0100_1101"));
		}

		for (int x=0; x<2; x++) // front porch
		{
			fprintf(out_file, "%c", out_byte("0000_1101")); // IRQ triggered here
		}
		
		for (int x=0; x<12; x++) // horizontal sync
		{
			fprintf(out_file, "%c", out_byte("0100_0101"));
		}
	
		for (int x=0; x<5; x++) // back porch
		{
			fprintf(out_file, "%c", out_byte("0100_1101"));
		}

		fprintf(out_file, "%c", out_byte("0100_1110")); // horizontal reset

		for (int x=0; x<28; x++) // filler
		{
			fprintf(out_file, "%c", out_byte("0100_1110")); // horizontal reset
		}
	}

	// usually each line is read twice, but this last line is only read once
	// because it has the vertical reset signal, the second read never happens

	for (int y=0; y<1; y++) // vertical back porch (and vertical reset)
	{
		for (int x=0; x<80; x++) // visible region
		{
			fprintf(out_file, "%c", out_byte("1101_1101"));
		}

		for (int x=0; x<2; x++) // front porch
		{
			fprintf(out_file, "%c", out_byte("1001_1101")); // IRQ triggered here
		}
		
		for (int x=0; x<12; x++) // horizontal sync
		{
			fprintf(out_file, "%c", out_byte("1101_0101"));
		}
	
		for (int x=0; x<5; x++) // back porch
		{
			fprintf(out_file, "%c", out_byte("1101_1101"));
		}

		fprintf(out_file, "%c", out_byte("1101_1010")); // horizontal reset (and vertical reset)

		for (int x=0; x<28; x++) // filler
		{
			fprintf(out_file, "%c", out_byte("1101_1010")); // horizontal reset (and vertical reset)
		}
	}

	for (int y=0; y<249; y++) // filler
	{
		for (int x=0; x<128; x++)
		{
			fprintf(out_file, "%c", out_byte("1101_1010")); // horizontal reset (and vertical reset)
		}
	}

	fclose(out_file);

	return 1;
}
