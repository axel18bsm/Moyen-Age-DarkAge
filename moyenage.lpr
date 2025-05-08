program moyenage;

{$mode objfpc}{$H+}

uses
  raylib, strings, init, UnitProcFunc, GameManager;




begin
  // Charger l'image principale (newlacarte.png)
  Pchartxt := 'resources/newlacarte.png';
  InitWindow(screenWidth, screenHeight, Pchartxt);
  SetTargetFPS(60);
  image := LoadImage(Pchartxt);
  texture := LoadTextureFromImage(image);
  UnloadImage(image); // L'image originale peut être déchargée après la conversion

  // Charger l'image calque (newlecalque.png) en mémoire, sans l'afficher
  calqueImage := LoadImage('resources/newlecalque.png');

  // Initialisation des ressources
  writeln('ok, j ai la main!');
  // chargeressource(); // Désactivé : maintenant géré dans UpdateGameManager après "Commencer la partie"
  // initialisezCamera2D(); // Désactivé : maintenant géré dans UpdateGameManager après chargeressource()

  // Initialiser le GameManager
  InitializeGameManager();

  while not WindowShouldClose() do
  begin
    // Mettre à jour le GameManager
    UpdateGameManager();

    BeginDrawing();
       ClearBackground(BLACK);
    // Dessiner en fonction de l'état du jeu
       DrawGameManager();

    EndDrawing();

    if Game.Aquitter then Break;
  end;

  // Libération des ressources
  CleanupGameManager();
  UnloadTexture(texture);
  UnloadImage(calqueImage); // Libérer l'image calque
  CloseWindow();
end.
