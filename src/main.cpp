#include <whb/proc.h>

#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>

#include <string.h>

#define SCREEN_W 1280
#define SCREEN_H 720

#define BUTTON_A 0
#define BUTTON_B 1
#define BUTTON_X 2
#define BUTTON_Y 3
#define BUTTON_STICKL 4
#define BUTTON_STICKR 5
#define BUTTON_L 6
#define BUTTON_R 7
#define BUTTON_ZL 8
#define BUTTON_ZR 9
#define BUTTON_PLUS 10
#define BUTTON_MINUS 11
#define BUTTON_LEFT 12
#define BUTTON_UP 13
#define BUTTON_RIGHT 14
#define BUTTON_DOWN 15
#define BUTTON_COUNT 16

#define RED 0xFFFF0000
#define GREEN 0xFF00FF00
#define BLUE 0xFF0000FF
#define BLACK 0xFF000000
#define WHITE 0xFFFFFFFF

void initStuff() {
    WHBProcInit();

    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER);

    SDL_InitSubSystem(SDL_INIT_JOYSTICK);
    SDL_JoystickEventState(SDL_ENABLE);
    SDL_JoystickOpen(0);
}

void exitStuff() {
    SDL_Quit();
    WHBProcShutdown();
}

int checkButtonPressed(SDL_Event event, int button) {
    return event.type == SDL_JOYBUTTONDOWN && event.jbutton.button == button;
}

int checkButtonReleased(SDL_Event event, int button) {
    return event.type == SDL_JOYBUTTONUP && event.jbutton.button == button;
}

void fillColor(int* buf, int col, int size) {
    for (int i = 0; i < size; i++) {
        buf[i] = col;
    }
}

int main(int argc, char** argv) {
    initStuff();

    SDL_Window* window = SDL_CreateWindow("DrawUSDL", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_W, SCREEN_H, SDL_WINDOW_SHOWN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);

    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, SCREEN_W, SCREEN_H);

    int size = 20;

    bool exitRequested = false;
    SDL_Event event;

    bool buttons[16];
    memset(buttons, 0, 16);

    SDL_Rect rect = {0, 0, SCREEN_W, SCREEN_H};

    while (!exitRequested && WHBProcIsRunning()) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                exitRequested = true;
                goto stop;
            }

            if (checkButtonPressed(event, BUTTON_PLUS)) {
                exitRequested = true;
                goto stop;
            }
            
            if (checkButtonPressed(event, BUTTON_MINUS)) {
                SDL_DestroyTexture(texture);
                texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, SCREEN_W, SCREEN_H);
            }

            for (int i = 0; i < 16; i++) {
                if (checkButtonPressed(event, i))
                    buttons[i] = true;
                
                if (checkButtonReleased(event, i))
                    buttons[i] = false;
            }

            if (event.type == SDL_FINGERMOTION) {
                int x = (int)(event.tfinger.x * (float)SCREEN_W);
                int y = (int)(event.tfinger.y * (float)SCREEN_H);

                int col = 0;
                
                if (buttons[BUTTON_A])
                    col |= RED;

                if (buttons[BUTTON_X])
                    col |= GREEN;

                if (buttons[BUTTON_Y])
                    col |= BLUE;
                
                if (col == 0)
                    col = WHITE;

                if (buttons[BUTTON_B]) {
                    int dat[size * size];
                    SDL_Rect r = {x - size / 2, y - size / 2, size, size};
                    fillColor(dat, col, size * size);
                    SDL_UpdateTexture(texture, &r, dat, size * 4);
                }
                else {
                    SDL_Rect r = {x, y, 1, 1};
                    SDL_UpdateTexture(texture, &r, &col, 4);
                }
            }
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0xFF);
        SDL_RenderClear(renderer);

        SDL_RenderCopy(renderer, texture, NULL, &rect);

        SDL_RenderPresent(renderer);
    }

stop:
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);

    exitStuff();

    return 0;
}
