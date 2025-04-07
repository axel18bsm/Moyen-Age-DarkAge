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
function DisplayHexAndUnitsInfo(hexID: Integer; startY: Integer): Integer;




implementation
function DisplayHexAndUnitsInfo(hexID: Integer; startY: Integer): Integer;
var
  k, j: Integer;
  objText: string;
  unitsOnHex: array[1..2] of Integer; // Pour stocker les ID des unités (max 2 unités)
  unitCount: Integer;
  unitIndex: Integer;
  yPos: Integer;
  unitState: string;
begin
  yPos := startY;
  unitCount := 0;

  // Afficher les informations de l'hexagone
  if hexID > 0 then
  begin
    hexInfo := Format('Hexagone : %d', [hexID]);
    hexType := 'Terrain : ' + Hexagons[hexID].TerrainType;
    objText := 'Objet : Aucun';
    for k := 1 to 6 do
    begin
      if Hexagons[hexID].Objet = Objets[k].Points then
      begin
        objText := Format('Objet : %s', [Objets[k].Objet]);
        break;
      end;
    end;
    hexObject := objText;
    if Hexagons[hexID].IsCastle then
      hexcastle := 'Château : oui'
    else
      hexcastle := 'Château : non';

    if Hexagons[hexID].HasWall then
      hexwall := 'Mur : oui'
    else
      hexwall := 'Mur : non';

    if Hexagons[hexID].HasRiver then
      hexriver := 'Rivière : oui'
    else
      hexriver := 'Rivière : non';

    if Hexagons[hexID].Route then
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

  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(hexInfo));
  yPos := yPos + 20;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(hexType));
  yPos := yPos + 20;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(hexObject));
  yPos := yPos + 20;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(hexwall));
  yPos := yPos + 20;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(hexriver));
  yPos := yPos + 20;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(hexcastle));
  yPos := yPos + 20;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(hexroad));
  yPos := yPos + 20;

  // Trouver les unités sur l'hexagone (max 2 unités)
  unitCount := 0;
  for j := 1 to MAX_UNITS do
  begin
    if Game.Units[j].HexagoneActuel = hexID then
    begin
      Inc(unitCount);
      if unitCount <= 2 then
        unitsOnHex[unitCount] := j;
      if unitCount = 2 then
        break; // Maximum 2 unités par hexagone
    end;
  end;

  // Afficher les informations des unités
  if unitCount > 0 then
  begin
    yPos := yPos + 20; // Espacement
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), 'Unités sur l''hexagone :');
    yPos := yPos + 20;

    for unitIndex := 1 to unitCount do
    begin
      j := unitsOnHex[unitIndex];
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(Format('Unité %d : %s', [unitIndex, Game.Units[j].lenom])));
      yPos := yPos + 20;
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(Format('Force : %d', [Game.Units[j].Force])));
      yPos := yPos + 20;
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(Format('Vitesse : %d', [Game.Units[j].vitesseInitiale])));
      yPos := yPos + 20;
      if Game.Units[j].EtatUnite = 1 then
        unitState := 'Entière'
      else
        unitState := '1/2 Force';
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(Format('État : %s', [unitState])));
      yPos := yPos + 30; // Espacement entre les unités
    end;
  end
  else
  begin
    yPos := yPos + 20; // Espacement
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), 'Aucune unité sur cet hexagone');
    yPos := yPos + 20;
  end;

  Result := unitCount; // Retourner le nombre d'unités trouvées
end;
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
  stateDisplayText: string;
  tourText: string;
  yPos: Integer;
  unitCount: Integer;
  message: string;
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

  // Informations sur le joueur
  if Game.CurrentPlayer.IsAttacker then
    playerText := 'Attaquant'
  else
    playerText := 'Défenseur';
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 60, 230, 20), PChar('Joueur : ' + playerText));

  // Informations sur l'état (GameState)
  stateText := GetEnumName(TypeInfo(TGameState), Ord(Game.CurrentState));
  case Game.CurrentState of
    gsSetupAttacker: stateDisplayText := 'Placement des troupes (Attaquant)';
    gsSetupDefender: stateDisplayText := 'Placement des troupes (Défenseur)';
    gsPlayerturn: stateDisplayText := 'Tour du joueur';
    gsCheckVictory: stateDisplayText := 'Vérification de la victoire';
    gsGameOver: stateDisplayText := 'Fin du jeu';
    else stateDisplayText := stateText; // Par défaut, utiliser le nom brut
  end;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 80, 230, 20), PChar('État : ' + stateDisplayText));

  // Log pour vérifier clickedHexID avant l'affichage
  WriteLn('AffichageEcranGui - clickedHexID : ', clickedHexID);

  // Afficher les informations de l'hexagone et des unités
  yPos := 110; // Position Y de départ pour les informations de l'hexagone
  unitCount := DisplayHexAndUnitsInfo(clickedHexID, yPos);

  // Ajuster yPos après l'affichage des informations
  yPos := yPos + 160; // 7 lignes (hexagone) + 20 (espacement)
  if unitCount > 0 then
  begin
    yPos := yPos + 20; // Espacement initial
    yPos := yPos + unitCount * 110; // 4 lignes par unité + 30 (espacement entre unités)
  end
  else
  begin
    yPos := yPos + 40; // Espacement pour "Aucune unité"
  end;

  // Boutons dans la bordure droite
  if (Game.CurrentState in [gsSetupAttacker, gsSetupDefender, gsAttackerMoveOrders, gsAttackerMoveExecute,
                          gsAttackerBattleOrders, gsAttackerBattleExecute, gsDefenderMoveOrders,
                          gsDefenderMoveExecute, gsDefenderBattleOrders, gsDefenderBattleExecute, gsCheckVictory]) then
  begin
    if (Game.Attacker.PlayerType = ptHuman) and (Game.Attacker.SetupType = stManual) and Game.AttackerUnitsPlaced then
    begin
      if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 30), 'Suivant') <> 0 then
      begin
        // Afficher un message de confirmation avec RayGUI
        if GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin du placement ?', 'Oui;Non') = 1 then
        begin
          Game.CurrentState := gsSetupDefender;
        end;
      end;
      yPos := yPos + 40;
    end
    else if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 30), 'Suivant') <> 0 then
    begin
      DoNothing; // Désactiver le bouton "Suivant" dans les autres cas
    end;
    yPos := yPos + 40;
  end
  else if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 30), 'Passer le tour') <> 0 then
  begin
    DoNothing; // Désactiver le bouton "Passer le tour"
  end;
  yPos := yPos + 40;

  // Bouton "Menu" en bas à droite
  if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, screenHeight - bottomBorderHeight - 40, 230, 30), 'Menu') <> 0 then
  begin
    Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
    Game.CurrentState := gsMainMenu; // Passer à l'état du menu général
  end;

  // Afficher le message de positionnement des unités attaquantes
  if Game.CurrentState = gsSetupAttacker then
  begin
    if not Game.AttackerUnitsPlaced then
    begin
      message := 'Cliquez avec le bouton droit sur la carte pour positionner les unités attaquantes';
    end
    else
    begin
      message := 'Unités attaquantes positionnées';
      if (Game.Attacker.PlayerType = ptHuman) and (Game.Attacker.SetupType = stManual) then
        message := message + '. Vous pouvez les déplacer';
    end;
    GuiLabel(RectangleCreate(10, screenHeight - bottomBorderHeight + 30, 230, 20), PChar(message));

    // Afficher le message d'erreur (si présent)
    if Game.ErrorMessage <> '' then
      GuiLabel(RectangleCreate(10, screenHeight - bottomBorderHeight + 50, 230, 20), PChar(Game.ErrorMessage));
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

  // Dessiner le cadre jaune autour de l'unité sélectionnée
  DrawUnitSelectionFrame;

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
   Game.Attacker.SetupType := stManual; // Par défaut : mode manuel
   Game.Attacker.IsAttacker := True;
   Game.Defender.PlayerType := ptHuman; // Par défaut
   Game.Defender.SetupType := stRandom; // Par défaut
   Game.Defender.IsAttacker := False;

   // Initialiser les variables des sliders
   Game.AttackerType := 0;  // 0 = Humain
   Game.AttackerSetup := 1; // 1 = Manuel
   Game.DefenderType := 0;  // 0 = Humain
   Game.DefenderSetup := 0; // 0 = Random

   // Initialiser le tour
   Game.CurrentTurn := 0;

   // Initialiser le drapeau de positionnement
   Game.AttackerUnitsPlaced := False;

   // Initialiser l'unité sélectionnée
   Game.SelectedUnitID := -1; // Aucune unité sélectionnée par défaut

   // Initialiser le message d'erreur
   Game.ErrorMessage := '';

   // Initialiser les variables globales pour le positionnement
   Game.IsOccupied := False;
   Game.HexOccupiedByAttacker := False;
   Game.IsSpecialUnit := False;

   // Initialiser MouseInitialized
   Game.MouseInitialized := False;

   // Initialiser IsDragging
   Game.IsDragging := False;

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
 var
   worldPosition: TVector2;
   k: Integer; // Déclaration de k
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

         // Réinitialiser le drapeau de positionnement
         Game.AttackerUnitsPlaced := False;

         // Log pour vérifier les valeurs
         WriteLn('Après Commencer la partie :');
         WriteLn('  Game.Attacker.PlayerType : ', GetEnumName(TypeInfo(TPlayerType), Ord(Game.Attacker.PlayerType)));
         WriteLn('  Game.Attacker.SetupType : ', GetEnumName(TypeInfo(TSetupType), Ord(Game.Attacker.SetupType)));

         // Passer au placement des troupes de l'attaquant
         Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
         Game.CurrentState := gsSetupAttacker;
       end;
     end;

     gsSetupAttacker:
     begin
       // Positionnement des unités attaquantes avec clic droit
       if not Game.AttackerUnitsPlaced then
       begin
         if IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) then
         begin
           worldPosition := GetScreenToWorld2D(GetMousePosition(), camera);
           clickedHexID := GetHexagonAtPosition(worldPosition.x, worldPosition.y);
           if clickedHexID > 0 then
           begin
             PositionAttackerUnitsAroundHex(clickedHexID);
             Game.AttackerUnitsPlaced := True;
             // Si humain et positionnement manuel, attendre l’action de l’utilisateur
             // Sinon, passer à l’état suivant
             if not ((Game.Attacker.PlayerType = ptHuman) and (Game.Attacker.SetupType = stManual)) then
             begin
               Game.CurrentState := gsSetupDefender;
             end;
           end;
         end;
       end
       else if (Game.Attacker.PlayerType = ptHuman) and (Game.Attacker.SetupType = stManual) then
       begin
         // Mode manuel : permettre le déplacement des unités
         if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and not Game.IsDragging then
         begin
           worldPosition := GetScreenToWorld2D(GetMousePosition(), camera);

           // Essayer de sélectionner une unité
           Game.SelectedUnitID := SelectUnit(GetMousePosition().x, GetMousePosition().y, 1); // 1 = attaquant
           if Game.SelectedUnitID = -1 then
           begin
             // Si aucune unité n'est sélectionnée, mettre à jour clickedHexID
             clickedHexID := GetHexagonAtPosition(worldPosition.x, worldPosition.y);
             // Log pour diagnostiquer
             WriteLn('Clic gauche - clickedHexID : ', clickedHexID);
           end;
         end;

         // Déplacer l'unité sélectionnée avec clic droit
         if (Game.SelectedUnitID >= 1) and IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) then
         begin
           worldPosition := GetScreenToWorld2D(GetMousePosition(), camera);
           clickedHexID := GetHexagonAtPosition(worldPosition.x, worldPosition.y);
           if clickedHexID > 0 then
           begin
             // Vérifier les règles de déplacement
             if (Hexagons[clickedHexID].TerrainType = 'mer') or (Hexagons[clickedHexID].TerrainType = 'foret') then
             begin
               Game.ErrorMessage := 'Déplacement interdit : terrain ' + Hexagons[clickedHexID].TerrainType;
               Game.SelectedUnitID := -1; // Désélectionner l'unité
             end
             else if Hexagons[clickedHexID].IsCastle then
             begin
               Game.ErrorMessage := 'Déplacement interdit : château';
               Game.SelectedUnitID := -1; // Désélectionner l'unité
             end
             else
             begin
               // Vérifier si l'hexagone est occupé par une autre unité attaquante
               Game.IsOccupied := False;
               Game.HexOccupiedByAttacker := False;
               for k := 1 to MAX_UNITS do
               begin
                 if Game.Units[k].HexagoneActuel = clickedHexID then
                 begin
                   Game.IsOccupied := True;
                   if Game.Units[k].numplayer = 1 then // Occupé par une unité attaquante
                     Game.HexOccupiedByAttacker := True;
                   Break;
                 end;
               end;

               // Vérifier si l'unité est un Lieutenant ou un Duc
               Game.IsSpecialUnit := (Game.Units[Game.SelectedUnitID].TypeUnite.lenom = 'lieutenant') or
                                    (Game.Units[Game.SelectedUnitID].TypeUnite.lenom = 'duc');

               if Game.IsOccupied and Game.HexOccupiedByAttacker and not Game.IsSpecialUnit then
               begin
                 Game.ErrorMessage := 'Déplacement interdit : hexagone occupé';
                 Game.SelectedUnitID := -1; // Désélectionner l'unité
               end
               else
               begin
                 // Déplacer l'unité
                 CenterUnitOnHexagon(Game.SelectedUnitID, clickedHexID);
                 Game.ErrorMessage := '';
                 Game.SelectedUnitID := -1; // Désélectionner après déplacement
               end;
             end;
           end
           else
           begin
             Game.ErrorMessage := 'Déplacement annulé : clic hors de la carte';
             Game.SelectedUnitID := -1; // Désélectionner l'unité
           end;
         end;
       end;

       MoveCarte2DFleche;
       DragAndDropCarte2D; // Utilise le clic gauche, mais ne devrait plus causer de recentrage
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
