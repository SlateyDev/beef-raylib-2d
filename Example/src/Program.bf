using System;
using System.Collections;
using RaylibBeef;

namespace Example
{
    class Program
    {
#if BF_PLATFORM_WASM
        private function void em_callback_func();

        [CLink, CallingConvention(.Stdcall)]
        private static extern void emscripten_set_main_loop(em_callback_func func, int32 fps, int32 simulateInfinteLoop);

        [CLink, CallingConvention(.Stdcall)]
        private static extern int32 emscripten_set_main_loop_timing(int32 mode, int32 value);

        [CLink, CallingConvention(.Stdcall)]
        private static extern double emscripten_get_now();

        private static void EmscriptenMainLoop()
        {
        	Update();
        }
#endif

        static Camera2D camera = .{
            target = .(0, 0),
            zoom   = 1,
        };

        static Deck deck = new Deck() ~ delete(deck);
        static List<Card> playerHand = new List<Card>() ~ delete(playerHand);
        static String drawnCardText = new $"Space to draw a card" ~ delete(drawnCardText);
        static Texture texture = .{};

        public static int Main(String[] args)
        {
            Raylib.InitWindow(1920, 1080, "Testing");
            defer Raylib.CloseWindow();

            // Load texture
            texture = Raylib.LoadTexture("assets/textures/sample.png");
            defer Raylib.UnloadTexture(texture);

            // Create and shuffle deck
            deck.Shuffle();

            // Draw initial hand
            // Deal 5 cards
            for (int i = 0; i < 5; i++)
            {
                playerHand.Add(deck.DrawCard());
            }

#if BF_PLATFORM_WASM
            emscripten_set_main_loop(=> EmscriptenMainLoop, 0, 1);
#else
            while (!Raylib.WindowShouldClose())
            {
            	Update();
            }
#endif

            return 0;
        }

        private static void Update() {
            var mousePos = Raylib.GetMousePosition();

            Raylib.BeginDrawing();
            defer Raylib.EndDrawing();
            Raylib.BeginMode2D(camera);
            defer Raylib.EndMode2D();

            var currentScreenWidth = Raylib.GetScreenWidth();
            var currentScreenHeight = Raylib.GetScreenHeight();

            Raylib.ClearBackground(Raylib.BEIGE);

            // Draw cards in an arc
            for (int i = 0; i < playerHand.Count; i++)
            {
                // Calculate position in arc
                float arcRadius = 800; // Increased radius for a wider arc
                float cardSpacing = 20; // Reduced spacing between cards
                float startAngle = 135; // Start from bottom left
                float angleRange = 90; // Total angle range for the arc
                float angle = startAngle - (angleRange * i / (playerHand.Count - 1));
                
                // Convert polar coordinates to cartesian
                float x = currentScreenWidth/2 - arcRadius * Math.Cos(angle * Math.PI_f / 180);
                float y = currentScreenHeight - arcRadius * Math.Sin(angle * Math.PI_f / 180);
                
                // Calculate rotation angle for each card
                float rotation = angle;
                
                // Create Vector2 for position and origin
                Vector2 position = .(x, y);
                Vector2 origin = .(texture.width/2, texture.height/2);
                
                // Draw card texture with rotation
                Raylib.DrawTextureEx(texture, position, rotation, 1.0f, Raylib.WHITE);
            }

            // Example: Draw a card when space is pressed
            if (Raylib.IsKeyPressed(.KEY_SPACE) && playerHand.Count < 10)
            {
                Card drawnCard = deck.DrawCard();
                playerHand.Add(drawnCard);
                delete drawnCardText;
                drawnCardText = new $"Drew {drawnCard.rank} of {drawnCard.suit}";
            }

            Raylib.DrawText(drawnCardText, 400, 300, 20, Raylib.BLACK);
        }
    }
}