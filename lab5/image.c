#include "image.h"

unsigned int max3(unsigned int a, unsigned int b, unsigned int c) {
    a = (a >= b) ? a : b;
    return (a >= c) ? a : c;
}

unsigned int min3(unsigned int a, unsigned int b, unsigned int c) {
    a = (a <= b) ? a : b;
    return (a <= c) ? a : c;
}

void decomposition_с(unsigned char *from, unsigned char *to, int width, int height, int mode) {
    if (width <= 0 || height <= 0)
        return ;
    unsigned int r, g, b, gray;
    for (int i = 0; i < width * height; ++i) {
        r = from[i * 4];
        g = from[i * 4 + 1];
        b = from[i * 4 + 2];
        gray = (mode == 0) ? min3(r, g, b) : max3(r, g, b);
        to[i * 2] = gray;
        to[i * 2 + 1] = from[i * 4 + 3];
    }
}