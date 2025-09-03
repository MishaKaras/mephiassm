#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "image.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#define STBI_ONLY_PNG

int main(int argc, char * argv[]) {
    FILE *f;
    long png = 0x0a1a0a0d474e5089;
    char buffer[8];
    unsigned char *src, *res;
    int width, height, channels;
    int mode;
    int times = 100;
    const char *src_path, *cres_path, *asmres_path;
    struct timespec t1, t2, delta_time;
    long total_sec = 0, total_nsec = 0, avg_sec, avg_nsec;
    if (argc != 5) {
		fprintf(stderr, "Usage: %s png_file c_result asm_result mode\n", argv[0]);
        fprintf(stderr, "  mode: 0 = Min, 1 = Max\n");
		return 1;
	}
    src_path = argv[1];
    cres_path = argv[2];
    asmres_path = argv[3];
    mode = atoi(argv[4]);
    if (mode != 0 && mode != 1) {
        fprintf(stderr, "%d - incorrect decomposition mode\n", mode);
		return 1;
    }

    if ((f = fopen(argv[1], "r")) == NULL){
		perror(argv[1]);
		return 1;
	}

    int stat = fread(buffer, 1, sizeof(long), f);
	fclose(f);
    if (stat == 0) {
        fprintf(stderr, "%s - signature read error\n", src_path);
		return 1;
    }

	if (*(long *)buffer != png){
		fprintf(stderr, "%s - not correct signature png_file\n", src_path);
		return 1;
	}

    src = stbi_load(src_path, &width, &height, &channels, 4);
    if (src == NULL) {
        fprintf(stderr, "%s - cannot load image\n", src_path);
		return 1;
    }

    printf("Input image: %d*%d pixels, %d channels\n", width, height, channels);
	if (channels < 3){
		fprintf(stderr, "Image is already monochrome\n");
		free(src);
		return 1;
	}
	if (channels == 3)
		printf("Image doesn't have alpha channel. Added\n");
	channels = 2;

    res = malloc(width * height * channels);
    if (res == NULL) {
        fprintf(stderr, "Memory allocation error\n");
        free(src);
		return 1;
    }

    // Таймирование функции на Си
    for (int i = 0; i < times; i++)
    {
        clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t1);
        decomposition_с(src, res, width, height, mode);
        clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t2);
        delta_time.tv_sec=t2.tv_sec-t1.tv_sec;
        if ((delta_time.tv_nsec=t2.tv_nsec-t1.tv_nsec)<0){
            delta_time.tv_sec--;
            delta_time.tv_nsec+=1000000000;
        }

        total_sec += delta_time.tv_sec;
        total_nsec += delta_time.tv_nsec;
    }
    
    total_sec += total_nsec / 1000000000;
    total_nsec = total_nsec % 1000000000;

    avg_sec = total_sec / times;
    avg_nsec = total_nsec / times;

    printf("C:   %ld.%09ld\n", avg_sec, avg_nsec);

    total_sec = 0;
    total_nsec = 0;

    // Запись результата на Си
    if (stbi_write_png(cres_path, width, height, channels, res, width*channels)==0)
		printf("C image write to file error\n");
    

    // Таймирование функции на ассме
    for (int i = 0; i < times; i++)
    {
        clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t1);
        decomposition_asm(src, res, width, height, mode);
        clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t2);
        delta_time.tv_sec=t2.tv_sec-t1.tv_sec;
        if ((delta_time.tv_nsec=t2.tv_nsec-t1.tv_nsec)<0){
            delta_time.tv_sec--;
            delta_time.tv_nsec+=1000000000;
        }

        total_sec += delta_time.tv_sec;
        total_nsec += delta_time.tv_nsec;
    }
    
    total_sec += total_nsec / 1000000000;
    total_nsec = total_nsec % 1000000000;

    avg_sec = total_sec / times;
    avg_nsec = total_nsec / times;

    printf("Asm: %ld.%09ld\n", avg_sec, avg_nsec);

    // Запись результата на ассме
    if (stbi_write_png(asmres_path, width, height, channels, res, width*channels)==0)
		printf("Asm image write to file error\n");
    
    free(src);
    free(res);
    return 0;
}