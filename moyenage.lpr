program moyenage;

{$mode objfpc}{$H+}

uses
  raylib, math, sysutils, init, gamemanager, unitprocfunc;

const
  SCREEN_WIDTH = 1280;
  SCREEN_HEIGHT = 720;
  MAX_UNITS = 68;
  MAX_HEXAGONS = 104;
  HEX_SIZE = 40;

var
  camera: TCamera2D;
  i: Integer;

begin
  InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, 'Moyen Âge');
  SetTargetFPS(60);

  // Initialisation des hexagones et des unités
  InitializeHexagons;
  InitializePlayerUnits;

  // Initialisation des variables de Game
  Game.CurrentState := gsSetupAttacker;
  Game.CurrentPlayerTurn := 1;
  Game.SelectedUnitID := -1;
  Game.LastClickedHexID := -1;
  Game.LastDestinationHexID := -1;
  Game.IsDragging := False;
  Game.DragStart := Vector2Create(0, 0);
  Game.LastClickTime := 0.0;
  SetLength(Game.Messages, 0);
  Game.Attacker.PlayerType := ptHuman;
  Game.Defender.PlayerType := ptHuman;

  camera.offset := Vector2Create(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2);
  camera.target := Vector2Create(0, 0);
  camera.rotation := 0;
  camera.zoom := 1.0;

  // Boucle principale
  while not WindowShouldClose() do
  begin
    // Mise à jour
    case Game.CurrentState of
      gsSetupAttacker: HandleSetupAttackerUpdate;
      gsSetupDefender: HandleSetupDefenderUpdate;
      gsAttackerMoveOrders: HandleAttackerMoveOrdersUpdate;
      gsAttackerMoveExecute: HandleAttackerMoveExecuteUpdate;
      gsAttackerBattleOrders: HandleAttackerBattleOrdersUpdate;
      gsDefenderMoveOrders: HandleDefenderMoveOrdersUpdate;
      gsDefenderMoveExecute: HandleDefenderMoveExecuteUpdate;
      gsDefenderBattleOrders: HandleDefenderBattleOrdersUpdate;
      gsBattleExecute: HandleBattleExecuteUpdate;
      gsGameOver: HandleGameOverUpdate;
      gsNewTurn: HandleNewTurnUpdate;
    end;

    // Rendu
    BeginDrawing();
    ClearBackground(RAYWHITE);
    BeginMode2D(camera);

    // Dessiner les hexagones
    for i := 1 to MAX_HEXAGONS do
    begin
      DrawPoly(Vector2Create(Hexagons[i].x, Hexagons[i].y), 6, HEX_SIZE, 0, Hexagons[i].color);
    end;

    // Dessiner les unités
    for i := 1 to MAX_UNITS do
    begin
      if (Game.Units[i].etatUnite = usFull) or (Game.Units[i].etatUnite = usDamaged) then
      begin
        if Game.Units[i].etatUnite = usFull then
          DrawTexture(Game.Units[i].latexture,
                      Game.Units[i].PositionActuelle.x - Game.Units[i].TextureHalfWidth,
                      Game.Units[i].PositionActuelle.y - Game.Units[i].TextureHalfHeight,
                      WHITE)
        else
          DrawTexture(Game.Units[i].latexture,
                      Game.Units[i].PositionActuelle.x - Game.Units[i].TextureHalfWidth,
                      Game.Units[i].PositionActuelle.y - Game.Units[i].TextureHalfHeight,
                      Fade(WHITE, 0.5));
      end
      else if Game.Units[i].etatUnite = usDead then
      begin
        DrawTexture(Game.Units[i].deathImage,
                    Game.Units[i].PositionActuelle.x - Game.Units[i].TextureHalfWidth,
                    Game.Units[i].PositionActuelle.y - Game.Units[i].TextureHalfHeight,
                    WHITE);
      end;
    end;

    // Dessiner les éléments GUI
    DrawText(PChar('État du jeu : ' + GameStateToString(Game.CurrentState)), 10, 10, 20, BLACK);
    DrawText(PChar('Tour du joueur : ' + IntToStr(Game.CurrentPlayerTurn)), 10, 40, 20, BLACK);
    DrawText(PChar('Zoom : ' + FormatFloat('0.##', camera.zoom)), 10, 70, 20, BLACK);

    // Afficher les messages du GUI bas
    for i := 0 to High(Game.Messages) do
    begin
      DrawText(PChar(Game.Messages[i]), 10, SCREEN_HEIGHT - 100 + i * 20, 20, BLACK);
    end;

    EndMode2D();
    EndDrawing();
  end;

  CloseWindow();
end.
