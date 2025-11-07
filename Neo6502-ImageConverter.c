
// Neo6502-ImageConverter.c

// Converts a 320x240 BMP image that uses white, red, cyan, and black, into hex code essentially.

#include <stdio.h>
#include <stdlib.h>

unsigned long pixel[320*240];

int main(const int argc, const char **argv)
{
	if (argc < 3)
	{
		printf("Arguments: <input.bmp> <output.hex>\n");
	
		return 0;
	}

	FILE *input = NULL, *output = NULL;

	input = fopen(argv[1], "rb");
	if (!input)
	{
		printf("Error!\n");
		return 0;
	}

	output = fopen(argv[2], "wt");
	if (!output)
	{
		printf("Error!\n");
		return 0;
	}

	unsigned long pos = 0;

	int bytes = 1;
	unsigned char buffer;
	unsigned char red, green, blue;

	for (int i=0; i<54; i++) bytes = fscanf(input, "%c", &buffer); // header

	while (bytes > 0)
	{
		bytes = fscanf(input, "%c%c%c", &blue, &green, &red);
		
		if (bytes > 0)
		{
			if (red >= 0xC0 && green >= 0xC0 && blue >= 0xC0) // white
			{
				pixel[pos] = 0xC0;
			}
			else if (red >= 0xC0 && green < 0xC0 && blue < 0xC0) // red
			{
				pixel[pos] = 0x80;
			}
			else if (red < 0xC0 && (green >= 0xC0 && blue >= 0xC0)) // cyan
			{
				pixel[pos] = 0x40;
			}
			else
			{
				pixel[pos] = 0x00;
			}

			pos++;

			if (pos >= 320 * 240) break;
		}
	}

	for (int y=239; y>=0; y--) // upside down
	{
		for (int x=0; x<80; x++)
		{
			buffer = ((pixel[y * 320 + x * 4 + 0]) | 
				(pixel[y * 320 + x * 4 + 1] >> 2) |
				(pixel[y * 320 + x * 4 + 2] >> 4) |
				(pixel[y * 320 + x * 4 + 3] >> 6));

			fprintf(output, "0x%02X, ", buffer);

			if (x % 16 == 15) fprintf(output, "\n");
		}

		// extra black off screen
		//for (int x=80; x<128; x++)
		//{
		//	fprintf(output, "0x00, ");
		//
		//	if (x % 16 == 15) fprintf(output, "\n");
		//}
	
		fprintf(output, "\n");
	}
	
	fclose(input);

	fclose(output);

	return 1;
}
