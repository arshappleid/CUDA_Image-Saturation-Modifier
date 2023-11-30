
#include <iostream>

// Imported Functions
extern void adjustSaturation(char *image, float saturation);

int main() {
    char* imageName = "./farmImg.webp";
    float saturationFactor = 1.0f; // Example saturation factor

	adjustSaturation(imageName, saturationFactor);
	printf("Adjustment complete.\n");
	return 0;
}
