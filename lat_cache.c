/* Microbenchmark de latencia de cache por pointer-chasing.
   Mede o tempo medio por acesso (ns) variando o tamanho do conjunto de trabalho.
   Os patamares revelam L1, L2, L3 e RAM. */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static double now_ns(void){
    struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec*1e9 + ts.tv_nsec;
}

int main(void){
    size_t sizes[] = {
        4*1024UL, 8*1024UL, 16*1024UL, 24*1024UL, 32*1024UL, 48*1024UL, 64*1024UL,
        128*1024UL, 256*1024UL, 512*1024UL, 768*1024UL,
        1024*1024UL, 2*1024*1024UL, 3*1024*1024UL, 4*1024*1024UL, 6*1024*1024UL,
        8*1024*1024UL, 12*1024*1024UL, 16*1024*1024UL, 24*1024*1024UL,
        32*1024*1024UL, 64*1024*1024UL, 128*1024*1024UL, 256*1024*1024UL
    };
    int n = (int)(sizeof(sizes)/sizeof(sizes[0]));
    const size_t ITERS = 20000000UL;
    srand(42);
    printf("size_KB,latency_ns\n");
    for(int s=0; s<n; s++){
        size_t bytes = sizes[s];
        size_t ne = bytes / sizeof(size_t);
        size_t *perm = malloc(ne*sizeof(size_t));
        size_t *next = malloc(ne*sizeof(size_t));
        if(!perm || !next){ free(perm); free(next); continue; }
        for(size_t i=0;i<ne;i++) perm[i]=i;
        for(size_t i=ne-1;i>0;i--){           /* embaralha (Fisher-Yates) */
            size_t j = ((size_t)rand()*(size_t)rand()) % (i+1);
            size_t t=perm[i]; perm[i]=perm[j]; perm[j]=t;
        }
        for(size_t i=0;i<ne;i++) next[perm[i]] = perm[(i+1)%ne]; /* ciclo unico */
        free(perm);
        volatile size_t idx=0;
        for(size_t i=0;i<ne;i++) idx = next[idx];   /* aquecimento */
        double t0 = now_ns();
        for(size_t i=0;i<ITERS;i++) idx = next[idx];
        double t1 = now_ns();
        if(idx==0xdeadbeef) printf("x");            /* evita otimizacao */
        printf("%zu,%.2f\n", bytes/1024, (t1-t0)/(double)ITERS);
        fflush(stdout);
        free(next);
    }
    return 0;
}
