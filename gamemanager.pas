unit GameManager;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, raylib, raygui, init,TypInfo,UnitProcFunc;

// Procédures pour gérer le GameManager
procedure InitializeGameManager;
procedure UpdateGameManager;
procedure DrawGameManager;
procedure CleanupGameManager;
procedure AffichageEcranGui(depart:TGameState);
procedure affichageBordEcran();
procedure DrawWallsTemporary;
procedure DrawRiverTemporary;
procedure CleanupUnits;
procedure DrawCastleTemporary;
procedure DrawUnits;
procedure DoNothing;




implementation
procedure DoNothing;
begin
  // Procédure vide pour désactiver les commandes
end;

procedure DrawUnits;
var
  j: Integer;

begin
  for j := 1 to MAX_UNITS do
  begin
    if Game.Units[j].HexagoneActuel >= 0 then
    begin
      // Centrer l'image de l'unité par rapport à PositionActuelle
      drawPos := CenterUnitOnPositionActuelle(j);
      DrawTexture(Game.Units[j].latexture, Round(drawPos.x), Round(drawPos.y), WHITE);
    end;
  end;
end;
procedure DrawCastleTemporary;
var
  i: Integer;
begin
  // Parcourir tous les hexagones
  for i := 1 to HexagonCount do
  begin
    if Hexagons[i].IsCastle then
    begin
      DrawCircle(Hexagons[i].CenterX, Hexagons[i].CenterY, 5, BLACK); // Point noir
    end;
  end;
end;
procedure CleanupUnits;
var
  i: Integer;
begin
  for i := 1 to MAX_UNITS do
  begin
    UnloadTexture(Game.Units[i].latexture);
    UnloadImage(Game.Units[i].limage);
  end;
end;
procedure DrawRiverTemporary;
var
  i, j: Integer;
  hexID, neighborID: Integer;
  startPos, endPos: TVector2;
begin
  // Parcourir tous les hexagones
  for i := 1 to HexagonCount do
  begin
    hexID := Hexagons[i].ID;
    startPos := Vector2Create(Hexagons[i].CenterX, Hexagons[i].CenterY);

    // Vérifier les 6 voisins
    for j := 1 to 6 do
    begin
      case j of
        1: neighborID := Hexagons[i].Neighbor1;
        2: neighborID := Hexagons[i].Neighbor2;
        3: neighborID := Hexagons[i].Neighbor3;
        4: neighborID := Hexagons[i].Neighbor4;
        5: neighborID := Hexagons[i].Neighbor5;
        6: neighborID := Hexagons[i].Neighbor6;
      end;

      // Si le voisin a un ID entre 4000 et 4999, il y a une rivière
      if (neighborID >= 4000) and (neighborID <= 4999) then
      begin
        neighborID := neighborID - 4000; // Récupérer l'ID réel du voisin
        if (neighborID > 0) and (neighborID <= HexagonCount) and (hexID < neighborID) then
        begin
          endPos := Vector2Create(Hexagons[neighborID].CenterX, Hexagons[neighborID].CenterY);
          // Dessiner une ligne verte entre les deux centres
          DrawLineEx(startPos, endPos, 2, GREEN);
        end;
      end;
    end;
  end;
end;
procedure DrawWallsTemporary;
var
  i: Integer;
  vertices: array[0..5] of TVector2;
begin
  // Parcourir tous les hexagones
  for i := 1 to HexagonCount do
  begin
    if Hexagons[i].HasWall then
    begin
      DrawCircle(Hexagons[i].CenterX,Hexagons[i].CenterY,10,BLUE);
    end;
  end;
end;
 procedure affichageBordEcran();
  begin
      DrawRectangle(0, 0, leftBorderWidth, screenHeight, BLACK); // Bordure gauche
      DrawRectangle(0, 0, screenWidth, topBorderHeight, BLACK); // Bordure haute
      DrawRectangle(0, screenHeight - bottomBorderHeight, screenWidth, bottomBorderHeight, BLACK); // Bordure basse
      DrawRectangle(screenWidth - rightBorderWidth, 0, rightBorderWidth, screenHeight, BLACK); // Bordure droite
  end;

 procedure AffichageEcranGui(depart: TGameState);
var
  playerText: string;
  stateText: string;
  tourText: string;
  objText: string;
  k: Integer;
begin
  // Afficher l'ID de l'hexagone cliqué
  if clickedHexID > 0 then
  begin
    // writeln(clickedHexID);
  end
  else
    DrawText('Aucun hexagone cliqué', leftBorderWidth, screenHeight-90, 20, RED);
  DrawText(Pchartxt, leftBorderWidth, screenHeight-60, 20, RED);
  DrawText(Pchartxt2, leftBorderWidth, screenHeight-30, 20, RED);

  // Dessiner le GUI dans la bordure droite
  GuiPanel(RectangleCreate(screenWidth - rightBorderWidth, 0, rightBorderWidth, screenHeight), 'Informations');

  // Titre centré "Moyen Age"
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + (rightBorderWidth - 100) div 2, 20, 100, 20), 'Moyen Age');

  // Nombre de tours
  tourText := Format('N° Tour : %d/%d', [Game.CurrentTurn, MAX_TOURS]);
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 40, 230, 20), PChar(tourText));

  // Informations sur le joueur et l'état
  if Game.CurrentPlayer.IsAttacker then
    playerText := 'Attaquant'
  else
    playerText := 'Défenseur';
  stateText := GetEnumName(TypeInfo(TGameState), Ord(Game.CurrentState));
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 60, 230, 20), PChar(Format('Joueur : %s ', [playerText])));
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 75, 230, 20), PChar(Format('Etat : %s ', [stateText])));


  // Afficher les informations de l'hexagone cliqué
  if clickedHexID > 0 then
  begin
    hexInfo := Format('Hexagone : %d', [clickedHexID]);
    hexType := 'Terrain : ' + Hexagons[clickedHexID].TerrainType;
    objText := 'Objet : Aucun';
    for k := 1 to 6 do
    begin
      if Hexagons[clickedHexID].Objet = Objets[k].Points then
      begin
        objText := Format('Objet : %s', [Objets[k].Objet]);
        break;
      end;
    end;
    hexObject := objText;
    if Hexagons[clickedHexID].IsCastle then
      hexcastle := 'Château : oui'
    else
      hexcastle := 'Château : non';

    if Hexagons[clickedHexID].HasWall then
      hexwall := 'Mur : oui'
    else
      hexwall := 'Mur : non';

    if Hexagons[clickedHexID].HasRiver then
      hexriver := 'Rivière : oui'
    else
      hexriver := 'Rivière : non';

    if Hexagons[clickedHexID].Route then
      hexroad := 'Route : oui'
    else
      hexroad := 'Route : non';
  end
  else
  begin
    hexInfo := 'Hexagone : Aucun';
    hexType := 'Terrain : -';
    hexObject := 'Objet : -';
    hexwall := 'Mur : -';
    hexriver := 'Rivière : -';
    hexcastle := 'Château : -';
    hexroad := 'Route : -';
  end;

  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 90, 230, 20), PChar(hexInfo));
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 110, 230, 20), PChar(hexType));
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 130, 230, 20), PChar(hexObject));
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 150, 230, 20), PChar(hexwall));
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 170, 230, 20), PChar(hexriver));
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 190, 230, 20), PChar(hexcastle));
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 210, 230, 20), PChar(hexroad));

  // Afficher les informations des unités sélectionnées
  if SelectedUnit1 >= 0 then
  begin
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 230, 230, 20), PChar(Format('Unité 1 : %s', [Game.Units[SelectedUnit1].TypeUnite.lenom])));
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 250, 230, 20), PChar(Format('Force : %d', [Game.Units[SelectedUnit1].Force])));
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 270, 230, 20), PChar(Format('Hexagone : %d', [Game.Units[SelectedUnit1].HexagoneActuel])));
  end
  else
  begin
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 270, 230, 20), 'Unité 1 : Aucune');
  end;

  if SelectedUnit2 >= 0 then
  begin
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 290, 230, 20), PChar(Format('Unité 2 : %s', [Game.Units[SelectedUnit2].TypeUnite.lenom])));
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 310, 230, 20), PChar(Format('Force : %d', [Game.Units[SelectedUnit2].Force])));
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 330, 230, 20), PChar(Format('Hexagone : %d', [Game.Units[SelectedUnit2].HexagoneActuel])));
  end
  else
  begin
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 350, 230, 20), 'Unité 2 : Aucune');
  end;

  // Boutons dans la bordure droite (désactivés)
  if (Game.CurrentState in [gsSetupAttacker, gsSetupDefender, gsAttackerMoveOrders, gsAttackerMoveExecute,
                            gsAttackerBattleOrders, gsAttackerBattleExecute, gsDefenderMoveOrders,
                            gsDefenderMoveExecute, gsDefenderBattleOrders, gsDefenderBattleExecute, gsCheckVictory]) then
  begin
    if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 600, 230, 30), 'Suivant') <> 0 then
    begin
      DoNothing; // Désactiver le bouton "Suivant"
    end;
  end
  else if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 600, 230, 30), 'Passer le tour') <> 0 then
  begin
    DoNothing; // Désactiver le bouton "Passer le tour"
  end;

  // Bouton "Menu" en bas à droite
  if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, screenHeight - bottomBorderHeight - 40, 230, 30), 'Menu') <> 0 then
  begin
    Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
    Game.CurrentState := gsMainMenu; // Passer à l'état du menu général
  end;

  // Message dans la bordure basse
  GuiLabel(RectangleCreate(10, screenHeight - bottomBorderHeight + 10, 230, 20), 'Tour du joueur 1');
end;

 procedure DrawGameManager;
 begin
   case Game.CurrentState of
     gsInitialization:
     begin
       ClearBackground(BLACK);
       DrawText('Initialisation...', screenWidth div 2 - 100, screenHeight div 2, 20, WHITE);
     end;

     gsSplashScreen:
     begin
       ClearBackground(BLACK);
       // Afficher l'image du splash screen centrée
       DrawTexture(Game.SplashScreenImage,
         (screenWidth - Game.SplashScreenImage.width) div 2,
         (screenHeight - Game.SplashScreenImage.height) div 2,
         WHITE);
       // Afficher un message pour indiquer comment passer
       DrawText('Appuyez sur Espace pour continuer (S pour couper la musique)',
         screenWidth div 2 - 200, screenHeight - 50, 20, WHITE);
     end;

     gsMainMenu:
     begin
       // Écran noir pour cacher la carte
       ClearBackground(BLACK);

       // Panneau à gauche
       GuiPanel(RectangleCreate(0, 0, 200, screenHeight), 'Menu Général');

       // Boutons du menu
       if GuiButton(RectangleCreate(10, 30, 180, 30), 'Tutoriel') <> 0 then
       begin
         WriteLn('Bouton Tutoriel cliqué');
         DoNothing; // Désactiver pour l'instant
       end;

       if GuiButton(RectangleCreate(10, 70, 180, 30), 'Nouvelle partie') <> 0 then
       begin
         Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
         Game.CurrentState := gsNewGameMenu; // Passer au menu de nouvelle partie
       end;

       if GuiButton(RectangleCreate(10, 110, 180, 30), 'Sauvegarde') <> 0 then
       begin
         WriteLn('Bouton Sauvegarde cliqué');
         DoNothing; // Désactiver pour l'instant
       end;

       if GuiButton(RectangleCreate(10, 150, 180, 30), 'Chargement') <> 0 then
       begin
         WriteLn('Bouton Chargement cliqué');
         DoNothing; // Désactiver pour l'instant
       end;

       if GuiButton(RectangleCreate(10, 190, 180, 30), 'À propos') <> 0 then
       begin
         WriteLn('Bouton À propos cliqué');
         DoNothing; // Désactiver pour l'instant
       end;

       if GuiButton(RectangleCreate(10, 230, 180, 30), 'Quitter') <> 0 then
       begin
         Game.Aquitter := True;
       end;

       // Bouton pour couper/reprendre la musique dans le menu
       if Game.MusicPlaying then
         musicButtonText := 'Couper la musique'
       else
         musicButtonText := 'Reprendre la musique';
       if GuiButton(RectangleCreate(10, 270, 180, 30), PChar(musicButtonText)) > 0 then
       begin
         if Game.MusicPlaying then
         begin
           StopMusicStream(Game.Music);
           Game.MusicPlaying := False;
         end
         else
         begin
           PlayMusicStream(Game.Music);
           Game.MusicPlaying := True;
         end;
       end;

       // Bouton "Retour" : Afficher uniquement si on ne vient pas de gsSplashScreen ou gsInitialization
       if not (Game.PreviousState in [gsSplashScreen, gsInitialization]) then
       begin
         if GuiButton(RectangleCreate(10, screenHeight - 40, 180, 30), 'Retour') > 0 then
         begin
           Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
           Game.CurrentState := Game.GamePlayState; // Retourner à l'état de jeu actif
         end;
       end;
     end;

     gsNewGameMenu:
     begin
       // Écran noir pour cacher la carte
       ClearBackground(BLACK);

       // Panneau centré pour la création d'une nouvelle partie
       GuiPanel(RectangleCreate(screenWidth div 2 - 200, screenHeight div 2 - 200, 400, 400), 'Nouvelle Partie');

       // Ajuster le style des sliders
       GuiSetStyle(SLIDER, SLIDER_PADDING, 2);

       // Choix du type de joueur pour l'attaquant
       GuiLabel(RectangleCreate(screenWidth div 2 - 180, screenHeight div 2 - 160, 180, 20), 'Attaquant :');

       if GuiToggleSlider(RectangleCreate(screenWidth div 2 - 180, screenHeight div 2 - 140, 180, 30), 'Humain;IA', @Game.AttackerType) > 0 then
       begin
         if Game.AttackerType = 1 then
           Game.Attacker.PlayerType := ptAI
         else
           Game.Attacker.PlayerType := ptHuman;
       end;
       // Choix du placement des troupes pour l'attaquant
       GuiLabel(RectangleCreate(screenWidth div 2 - 180, screenHeight div 2 - 100, 180, 20), 'Placement Attaquant :');
       GuiToggleSlider(RectangleCreate(screenWidth div 2 - 180, screenHeight div 2 - 80, 180, 30), 'Random;Manuel', @Game.AttackerSetup);
       if Game.AttackerSetup = 1 then
         Game.Attacker.SetupType := stManual
       else
         Game.Attacker.SetupType := stRandom;

       // Choix du type de joueur pour le défenseur
       GuiLabel(RectangleCreate(screenWidth div 2 + 10, screenHeight div 2 - 160, 180, 20), 'Défenseur :');
       GuiToggleSlider(RectangleCreate(screenWidth div 2 + 10, screenHeight div 2 - 140, 180, 30), 'Humain;IA', @Game.DefenderType);
       if Game.DefenderType = 1 then
         Game.Defender.PlayerType := ptAI
       else
         Game.Defender.PlayerType := ptHuman;

       // Choix du placement des troupes pour le défenseur
       GuiLabel(RectangleCreate(screenWidth div 2 + 10, screenHeight div 2 - 100, 180, 20), 'Placement Défenseur :');
       GuiToggleSlider(RectangleCreate(screenWidth div 2 + 10, screenHeight div 2 - 80, 180, 30), 'Random;Manuel', @Game.DefenderSetup);
       if Game.DefenderSetup = 1 then
         Game.Defender.SetupType := stManual
       else
         Game.Defender.SetupType := stRandom;

       // Bouton pour commencer la partie
       if GuiButton(RectangleCreate(screenWidth div 2 - 180, screenHeight div 2 + 20, 360, 30), 'Commencer la partie') <> 0 then
       begin
         // L'action est gérée dans UpdateGameManager
       end;

       // Bouton pour retourner au menu principal
       if GuiButton(RectangleCreate(screenWidth div 2 - 180, screenHeight div 2 + 60, 360, 30), 'Retour') > 0 then
       begin
         Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
         Game.CurrentState := gsMainMenu; // Revenir au menu principal
       end;
     end;

     gsSetupAttacker:
     begin
       BeginMode2D(camera);
       DrawTexture(texture, 0, 0, WHITE); // Dessiner l'image à la position (0, 0)

       // Afficher toutes les unités (y compris le Comte)
       DrawUnits;

       EndMode2D();
       affichageBordEcran(); // Dessine les bordures noires
       AffichageEcranGui(Game.CurrentState); // Affiche le GUI
     end;

     gsSetupDefender,
     gsAttackerMoveOrders,
     gsAttackerMoveExecute,
     gsAttackerBattleOrders,
     gsAttackerBattleExecute,
     gsDefenderMoveOrders,
     gsDefenderMoveExecute,
     gsDefenderBattleOrders,
     gsDefenderBattleExecute,
     gsCheckVictory,
     gsPlayerturn:
     begin
       // Ne rien afficher dans ces modes pour l'instant
       ClearBackground(BLACK);
       DrawText('Mode désactivé', screenWidth div 2 - 50, screenHeight div 2, 20, WHITE);
     end;

     gsGameOver:
     begin
       ClearBackground(BLACK);
       DrawText('Fin du jeu', screenWidth div 2 - 50, screenHeight div 2, 20, WHITE);
       DrawText('Appuyez sur Espace pour retourner au menu', screenWidth div 2 - 150, screenHeight div 2 + 30, 20, WHITE);
     end;
   end;
 end;
 procedure InitializeGameManager;
begin
  // Initialiser l'état du jeu
  Game.CurrentState := gsInitialization;
  Game.PreviousState := gsInitialization; // État précédent initial
  Game.GamePlayState := gsSetupAttacker; // État de jeu actif initial (sera mis à jour plus tard)

  // Initialiser le timer du splash screen
  Game.SplashScreenTimer := 0.0;

  // Initialiser les joueurs
  Game.Attacker.PlayerType := ptHuman; // Par défaut
  Game.Attacker.SetupType := stRandom; // Par défaut
  Game.Attacker.IsAttacker := True;
  Game.Defender.PlayerType := ptHuman; // Par défaut
  Game.Defender.SetupType := stRandom; // Par défaut
  Game.Defender.IsAttacker := False;

  // Initialiser les variables des sliders
  Game.AttackerType := 0;  // 0 = Humain
  Game.AttackerSetup := 0; // 0 = Random
  Game.DefenderType := 0;  // 0 = Humain
  Game.DefenderSetup := 0; // 0 = Random

  // Initialiser le tour
  Game.CurrentTurn := 0;

  // Charger l'image du splash screen
  Game.SplashScreenImage := LoadTexture('resources/image/intromoyenage.png');
  if Game.SplashScreenImage.id = 0 then
  begin
    WriteLn('Erreur : Impossible de charger l''image resources/image/intromoyenage.png');
  end;

  // Initialiser l'audio et charger la musique
  InitAudioDevice();
  Game.Music := LoadMusicStream('resources/music/HeroicAge.mp3');
  if Game.Music.ctxData = nil then
  begin
    WriteLn('Erreur : Impossible de charger la musique resources/music/HeroicAge.mp3');
  end;
  Game.MusicPlaying := True; // La musique commence à jouer par défaut
  PlayMusicStream(Game.Music);

  // Charger le style Raygui "Amber"
  GuiLoadStyle(PChar(GetApplicationDirectory + 'gui_styles/style_amber.rgs'));
end;

 procedure UpdateGameManager;
begin
  case Game.CurrentState of
    gsInitialization:
    begin
      // Après l'initialisation, passer directement au splash screen
      Game.CurrentState := gsSplashScreen;
    end;

    gsSplashScreen:
    begin
      // Mettre à jour la musique si elle est en train de jouer
      if Game.MusicPlaying then
        UpdateMusicStream(Game.Music);

      // Vérifier si la touche S est pressée pour arrêter/reprendre la musique
      if IsKeyPressed(KEY_S) then
      begin
        if Game.MusicPlaying then
        begin
          StopMusicStream(Game.Music);
          Game.MusicPlaying := False;
        end
        else
        begin
          PlayMusicStream(Game.Music);
          Game.MusicPlaying := True;
        end;
      end;

      // Mettre à jour le timer du splash screen
      Game.SplashScreenTimer := Game.SplashScreenTimer + GetFrameTime();

      // Passer à l'état suivant si la touche Espace est pressée ou après 10 secondes
      if IsKeyPressed(KEY_SPACE) or (Game.SplashScreenTimer >= 10.0) then
      begin
        Game.CurrentState := gsMainMenu; // Passer au menu principal
        Game.SplashScreenTimer := 0.0; // Réinitialiser le timer
        if Game.MusicPlaying then
        begin
          StopMusicStream(Game.Music); // Arrêter la musique à la fin du splash screen
          Game.MusicPlaying := False;
        end;
      end;
    end;

    gsMainMenu:
    begin
      // Mettre à jour la musique si elle est en train de jouer
      if Game.MusicPlaying then
        UpdateMusicStream(Game.Music);

      // Vérifier si la touche S est pressée pour arrêter/reprendre la musique
      if IsKeyPressed(KEY_S) then
      begin
        if Game.MusicPlaying then
        begin
          StopMusicStream(Game.Music);
          Game.MusicPlaying := False;
        end
        else
        begin
          PlayMusicStream(Game.Music);
          Game.MusicPlaying := True;
        end;
      end;
    end;

    gsNewGameMenu:
    begin
      // Mettre à jour la musique si elle est en train de jouer
      if Game.MusicPlaying then
        UpdateMusicStream(Game.Music);

      // Vérifier si la touche S est pressée pour arrêter/reprendre la musique
      if IsKeyPressed(KEY_S) then
      begin
        if Game.MusicPlaying then
        begin
          StopMusicStream(Game.Music);
          Game.MusicPlaying := False;
        end
        else
        begin
          PlayMusicStream(Game.Music);
          Game.MusicPlaying := True;
        end;
      end;

      // Charger les ressources et passer à gsSetupAttacker après "Commencer la partie"
      if GuiButton(RectangleCreate(screenWidth div 2 - 180, screenHeight div 2 + 20, 360, 30), 'Commencer la partie') <> 0 then
      begin
        // Charger toutes les ressources
        chargeressource();
        initialisezCamera2D(); // Initialiser la caméra après le chargement de la carte

        // Initialiser le tour à 1
        Game.CurrentTurn := 1;

        // Définir le joueur actif (attaquant)
        Game.CurrentPlayer := Game.Attacker;

        // Mettre à jour l'état de jeu actif
        Game.GamePlayState := gsSetupAttacker;

        // Passer au placement des troupes de l'attaquant
        Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
        Game.CurrentState := gsSetupAttacker;
      end;
    end;

    gsSetupAttacker:
    begin
      // À implémenter : placement des troupes de l'attaquant
      // Pour l'instant, on reste dans cet état pour permettre un affichage jouable
      if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
      begin
        mousePos := GetMousePosition();
        worldPosition := GetScreenToWorld2D(mousePos, camera);
        clickedHexID := GetHexagonAtPosition(worldPosition.x, worldPosition.y);
        writeln(clickedHexID);
      end;

      MoveCarte2DFleche;
      DragAndDropCarte2D;
      ZoomCarte2D;
      AffichageGuiBas;
    end;

    gsSetupDefender,
    gsAttackerMoveOrders,
    gsAttackerMoveExecute,
    gsAttackerBattleOrders,
    gsAttackerBattleExecute,
    gsDefenderMoveOrders,
    gsDefenderMoveExecute,
    gsDefenderBattleOrders,
    gsDefenderBattleExecute,
    gsCheckVictory,
    gsPlayerturn:
    begin
      DoNothing; // Désactiver ces modes pour l'instant
    end;

    gsGameOver:
    begin
      // À implémenter : fin du jeu
      if IsKeyPressed(KEY_SPACE) then
      begin
        Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
        Game.CurrentState := gsMainMenu; // Retour au menu principal
      end;
    end;
  end;
end;

procedure CleanupGameManager;
begin
  // Libérer les ressources
  UnloadTexture(Game.SplashScreenImage);
  UnloadMusicStream(Game.Music);
  CloseAudioDevice();
end;
 begin
  // Libérer les ressources des unités
  CleanupUnits;

  // Libérer les autres ressources
  UnloadTexture(Game.SplashScreenImage);
  UnloadMusicStream(Game.Music);
  CloseAudioDevice();
end.
