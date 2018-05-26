#ifndef INDEX_H
#define INDEX_H


#ifdef __cplusplus
#define INDEX_EXTERN_C extern "C"
#else
#define INDEX_EXTERN_C
#endif

#if defined(_WIN32)
#define INDEX_EXPORT INDEX_EXTERN_C __declspec(dllimport)
#else
#define INDEX_EXPORT INDEX_EXTERN_C __attribute__((visibility ("default")))
#endif


#endif
