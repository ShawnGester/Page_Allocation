#include "types.h"
#include "stat.h"
#include "user.h"

int
main(int argc, char **argv)
{
    // int* test1 = malloc(sizeof(int) * 5);
    // int* test2 = malloc(sizeof(int) * 5);
    //int* frames = malloc(sizeof(int) * 20);
    //int* pids = malloc(sizeof(int) * 20);
    
    int frames[20];
    int pids[20];
    // frames[0] = 15;
    // pids[0] = 15;
    int numframes = 20;
    /*for (int i = 0; i < 20; ++i) {
	frames[i] = 0;
	pids[i] = 0;
    }*/
    int parent = fork();
    if (parent) { //parent process
        dump_physmem(frames, pids, 20);
        for (int i = 0; i < numframes; ++i) {
	        printf(1, "frames[%d] = %d; pids[%d] = %d\n", i, *(frames+i), i, *(pids+i));
        }
        printf(1, "numframes: %d\n", numframes);
        wait();
    }
    else {
        // nothing
    }

    // free(test1);
    // free(test2);
    exit();
}
