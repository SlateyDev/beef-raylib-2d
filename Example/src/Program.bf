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

        static List<CardDefinition> cardDefinitions = new List<CardDefinition>() ~ delete _;

        static int CARD_WIDTH = 278;
        static int CARD_HEIGHT = 378;

        public static void ImageRenderCenteredText(Image *dst, Font font, String text, Vector2 pos, float font_size, Color fore_color) {
            var textSize = Raylib.MeasureTextEx(font, text, font_size, 2);
            Raylib.ImageDrawTextEx(dst, font, text, .(pos.x - textSize.x / 2, pos.y - textSize.y / 2), font_size, 2, fore_color);
        }

        public static void ImageRenderTextBoxed(Image *dst, Font font, String text, Rectangle rec, float fontSize, float spacing, bool wordWrap, Color tint, float leading = 0.0f) {
            int32 length = int32(text.Length);

            float textOffsetY = 0.0f;          // Offset between lines (on line break '\n')
            float textOffsetX = 0.0f;       // Offset X to next character to draw

            float scaleFactor = fontSize / float(font.baseSize);

            // Word/character wrapping mechanism variables
            bool state = !wordWrap;

            int32 startLine = -1;         // Index where to begin drawing (where a line begins)
            int32 endLine = -1;           // Index where to stop drawing (where a line ends)
            int32 lastk = -1;             // Holds last value of the character position

            int32 i = 0;
            int32 k = 0;
            while (i < length) {
                // Get next codepoint from byte string and glyph index in font
                int32 codepointByteCount = 0;
                var codepoint = Raylib.GetCodepoint(&text[i], &codepointByteCount);
                var index = Raylib.GetGlyphIndex(font, codepoint);

                // NOTE: Normally we exit the decoding sequence as soon as a bad byte is found (and return 0x3f)
                // but we need to draw all of the bad bytes using the '?' symbol moving one byte
                if (codepoint == 0x3f) codepointByteCount = 1;
                i += codepointByteCount - 1;

                float glyphWidth = 0.0f;
                if (codepoint != (int)'\n') {
                    glyphWidth = (font.glyphs[index].advanceX == 0) ? font.recs[index].width*scaleFactor : float(font.glyphs[index].advanceX) * scaleFactor;

                    if (i + 1 < length) glyphWidth = glyphWidth + spacing;
                }

                // NOTE: When wordWrap is ON we first measure how much of the text we can draw before going outside of the rec container
                // We store this info in startLine and endLine, then we change states, draw the text between those two variables
                // and change states again and again recursively until the end of the text (or until we get outside of the container).
                // When wordWrap is OFF we don't need the measure state so we go to the drawing state immediately
                // and begin drawing on the next line before we can get outside the container.
                if (state == false) {
                    // TODO: There are multiple types of spaces in UNICODE, maybe it's a good idea to add support for more
                    // Ref: http://jkorpela.fi/chars/spaces.html
                    if (codepoint == (int)' ' || codepoint == (int)'\t' || codepoint == (int)'\n') endLine = i;

                    if (textOffsetX + glyphWidth > rec.width) {
                        endLine = (endLine < 1) ? i : endLine;
                        if (i == endLine) endLine -= codepointByteCount;
                        if (startLine + codepointByteCount == endLine) endLine = i - codepointByteCount;

                        state = !state;
                    } else if (i + 1 == length) {
                        endLine = i;
                        state = !state;
                    } else if (codepoint == (int)'\n') {
                        state = !state;
                    }

                    if (state == true) {
                        textOffsetX = 0;
                        i = startLine;
                        glyphWidth = 0;

                        // Save character position when we switch states
                        var tmp = lastk;
                        lastk = k - 1;
                        k = tmp;
                    }
                } else {
                    if (codepoint == (int)'\n') {
                        if (!wordWrap) {
                            textOffsetY += float(font.baseSize + font.baseSize / 2) * scaleFactor + leading;
                            textOffsetX = 0;
                        }
                    } else {
                        if (!wordWrap && ((textOffsetX + glyphWidth) > rec.width)) {
                            textOffsetY += float(font.baseSize + font.baseSize / 2) * scaleFactor + leading;
                            textOffsetX = 0;
                        }

                        // When text overflows rectangle height limit, just stop drawing
                        if ((textOffsetY + float(font.baseSize)*scaleFactor + leading) > rec.height) break;

                        // Draw current character glyph
                        if ((codepoint != (int)' ') && (codepoint != (int)'\t')) {
                            Raylib.ImageDrawTextEx(dst, font, scope $"{text.Substring(i, codepointByteCount)}", .(rec.x + textOffsetX, rec.y + textOffsetY), fontSize, 0, tint);
                        }
                    }

                    if (wordWrap && (i == endLine)) {
                        textOffsetY += float(font.baseSize + font.baseSize / 2) * scaleFactor + leading;
                        textOffsetX = 0;
                        startLine = endLine;
                        endLine = -1;
                        glyphWidth = 0;
                        k = lastk;

                        state = !state;
                    }
                }

                if (textOffsetX != 0 || codepoint != (int)' ') textOffsetX += glyphWidth;  // avoid leading spaces

                i += 1;
                k += 1;
            }
        }

        public static int Main(String[] args)
        {
            Raylib.InitWindow(1920, 1080, "Testing");
            defer Raylib.CloseWindow();

            // Load texture
            texture = Raylib.LoadTexture("assets/textures/sample.png");
            defer Raylib.UnloadTexture(texture);

            cardDefinitions.Add(CardDefinition {
                name = "Strike",
                flavourText = "Deal 6 damage.",
                cost = 1,
                kind = CardKind.Attack,
                proc = scope () => { Console.WriteLine("Strike card played!"); }
            });
            cardDefinitions.Add(CardDefinition {
                name = "Defend",
                flavourText = "Gain 5 block.",
                cost = 1,
                kind = CardKind.Skill,
                proc = scope () => { Console.WriteLine("Defend card played!"); }
            });
            cardDefinitions.Add(CardDefinition {
                name = "Rage",
                flavourText = "Gain 2 strength.",
                cost = 2,
                kind = CardKind.Power,
                proc = scope () => { Console.WriteLine("Rage card played!"); }
            });
            cardDefinitions.Add(CardDefinition {
                name = "Bash",
                flavourText = "Deal 8 damage and apply 2 Vulnerable.",
                cost = 2,
                kind = CardKind.Attack,
                proc = scope () => { Console.WriteLine("Bash card played!"); }
            });

            var cardLayout = Raylib.LoadImage("assets/textures/card_layout.png");
            defer Raylib.UnloadImage(cardLayout);
            var cardFont = Raylib.LoadFont("assets/OLDSH___.TTF");
            defer Raylib.UnloadFont(cardFont);
            Raylib.GenTextureMipmaps(&cardFont.texture);
            Raylib.SetTextureFilter(cardFont.texture, TextureFilter.TEXTURE_FILTER_TRILINEAR);

            for (var cardDefinition in ref cardDefinitions) {
                var newCardArt = Raylib.ImageCopy(cardLayout);
                //defer Raylib.UnloadImage(cardLayout);

                ImageRenderCenteredText(&newCardArt, cardFont, cardDefinition.name, .(CARD_WIDTH / 2, 273), 12, Raylib.WHITE);
                ImageRenderTextBoxed(&newCardArt, cardFont, cardDefinition.flavourText, .(83, 315, 112, 22), 12, 1, true, Raylib.BLACK, -10);
                Raylib.ImageDrawCircle(&newCardArt, 38, 44, 20, Raylib.BLACK);
                ImageRenderCenteredText(&newCardArt, cardFont, scope $"{cardDefinition.cost}", .(38, 44), 24, Raylib.GREEN);

                cardDefinition.artwork = Raylib.LoadTextureFromImage(newCardArt);
                Raylib.GenTextureMipmaps(&cardDefinition.artwork);
                Raylib.SetTextureFilter(cardDefinition.artwork, TextureFilter.TEXTURE_FILTER_TRILINEAR);
            }

            for (var cardDefinition in cardDefinitions) {
                for (int i = 0; i < 5; i++) {
                    Card card = .{
                        definition = cardDefinition,
                        selected = false,
                        position = .(0, 0),
                        rotation = 0.0f,
                    };
                    deck.AddCard(card);
                }
            }

            // Create and shuffle deck
            deck.Shuffle();

            // Draw initial hand
            // Deal 5 cards
            //for (int i = 0; i < 5; i++)
            //{
            //    playerHand.Add(deck.DrawCard());
            //}

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
                Vector2 origin = .(texture.width / 2, texture.height / 2);
                
                // Draw card texture with rotation
                //Raylib.DrawTextureEx(texture, position, rotation, 1.0f, Raylib.WHITE);
                rotation = 0;
                Color cardColor = Raylib.WHITE;
                Rectangle cardRect = .(position.x, position.y, CARD_WIDTH, CARD_HEIGHT);
                if (Raylib.CheckCollisionPointRec(mousePos, cardRect)) {
                    cardColor = Raylib.YELLOW;
                }
                Raylib.DrawTextureEx(playerHand[i].definition.artwork, position, rotation, 1.0f, cardColor);
            }

            // Example: Draw a card when space is pressed
            if (Raylib.IsKeyPressed(.KEY_SPACE) && playerHand.Count < 10)
            {
                Card drawnCard = deck.DrawCard();
                playerHand.Add(drawnCard);
                delete drawnCardText;
                drawnCardText = new $"Drew {drawnCard.definition.name}";
            }

            Raylib.DrawText(drawnCardText, 400, 300, 20, Raylib.BLACK);
        }
    }
}