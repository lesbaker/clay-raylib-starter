#include "raylib.h"
#include "stdio.h"
#define CLAY_IMPLEMENTATION
#include "clay.h"
#include "clay_renderer_raylib.c"

Clay_LayoutConfig layoutElement = (Clay_LayoutConfig) { .padding = {5} };

void HandleClayErrors(Clay_ErrorData errorData) {
    printf("%s", errorData.errorText.chars);
}

int main(void) {
    Clay_Raylib_Initialize(1000, 500, "asdf", FLAG_WINDOW_RESIZABLE | FLAG_WINDOW_HIGHDPI | FLAG_MSAA_4X_HINT);

    uint64_t totalMemorySize = Clay_MinMemorySize();
    Clay_Arena clayMemory = Clay_CreateArenaWithCapacityAndMemory(totalMemorySize, (char *)malloc(totalMemorySize));
    Font fonts[1];
    fonts[0] = LoadFontEx("resources/Roboto-Regular.ttf", 48, 0, 400);

    Clay_Initialize(clayMemory, (Clay_Dimensions) {1024,768}, (Clay_ErrorHandler) { HandleClayErrors });
    Clay_SetMeasureTextFunction(Raylib_MeasureText, fonts);


    while (!WindowShouldClose()) {
        Clay_BeginLayout();
        CLAY(CLAY_ID("outer"), {
            .layout = {
                 .sizing = {CLAY_SIZING_GROW(0), CLAY_SIZING_GROW(0)},
                 .padding = CLAY_PADDING_ALL(16),
                 .childGap = 16
             },
            .backgroundColor = {40, 80, 60, 255}
        }) {
            CLAY_TEXT(CLAY_STRING("Raylib version: " RAYLIB_VERSION), {
                      .fontId = 0,
                      .fontSize = 24,
                      .textColor = {255, 255, 255, 255}
            });
        }
        Clay_RenderCommandArray rca = Clay_EndLayout(0);
        BeginDrawing();
        Clay_Raylib_Render(rca, fonts);
        EndDrawing();
    }

    return 0;
}
