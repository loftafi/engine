#define SDL_MAIN_USE_CALLBACKS

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include <jni.h>

//extern JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved);
extern JNIEXPORT jint JNICALL OnLoad(JavaVM* vm, void* reserved);


JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved) {
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
                 "On_Load ####");

    JNIEnv* env;
    if ((*vm)->GetEnv(vm, (void**)&env, JNI_VERSION_1_6) != JNI_OK) {
        return JNI_ERR; // JNI version not supported
    }
    OnLoad(vm, reserved);
    return JNI_VERSION_1_6; // Return the JNI version
}
#if 0

extern uint AppInitC(int argc, char *argv[]);
extern void AppQuitC(SDL_AppResult result);
extern uint AppEventC(SDL_Event *event);
extern uint AppIterateC(void *appstate);

SDL_AppResult SDL_AppIterate(void *appstate) {
    // Call the shared library to handle events.
   return AppIterateC(appstate);
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event) {
    // Call the shared library to handle events.
    return AppEventC(event);
}

SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[]) {
    // Call the shared library to handle setup.
    return AppInitC(argc, argv);
}

void SDL_AppQuit(void *appstate, SDL_AppResult result) {
    // Call the shared library to hande cleanup.
    AppQuitC(result);
}
#endif
