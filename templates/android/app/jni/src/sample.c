#define SDL_MAIN_USE_CALLBACKS

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

extern uint AppInitC(int argc, char *argv[]);
extern void AppQuitC(SDL_AppResult result);
extern uint AppEventC(SDL_Event *event);
extern uint AppIterateC(void *appstate);

SDL_AppResult SDL_AppIterate(void *appstate)
{
    // Call the shared library to handle events.
    return AppIterateC(appstate);
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event)
{
    // Call the shared library to handle events.
    return AppEventC(event);
}

SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[])
{
    // Call the shared library to handle setup.
    return AppInitC(argc, argv);
}

void SDL_AppQuit(void *appstate, SDL_AppResult result)
{
    // Call the shared library to hande cleanup.
    AppQuitC(result);
}
