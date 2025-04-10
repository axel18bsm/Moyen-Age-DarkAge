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
procedure AddMessage(msg: string);




implementation
 procedure AddMessage(msg: string);
 begin
   Inc(Game.MessageCount);
   SetLength(Game.Messages, Game.MessageCount);
   Game.Messages[Game.MessageCount - 1] := msg;
 end;

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
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(Format('Unité %d : %s', [Game.Units[j].id, Game.Units[j].lenom])));
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
  dialogResult: Integer;
  // Variables pour le panneau défilant
  panelBounds: TRectangle;
  contentBounds: TRectangle;
  scroll: TVector2;
  view: TRectangle; // Ajout du rectangle pour la zone visible
  contentHeight: Integer;
  firstVisibleMessage: Integer;
  lastVisibleMessage: Integer;
  i: Integer;
  yMsgPos: Integer;
  scrollResult: Integer; // Pour le retour de GuiScrollPanel
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
  begin
    playerText := 'Attaquant';
    if Game.Attacker.PlayerType = ptAI then
      playerText := playerText + ' - AI'
    else
      playerText := playerText + ' - Humain';
  end
  else
  begin
    playerText := 'Défenseur';
    if Game.Defender.PlayerType = ptAI then
      playerText := playerText + ' - AI'
    else
      playerText := playerText + ' - Humain';
  end;
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
  if Game.CurrentState in [gsSetupAttacker, gsSetupDefender, gsAttackerMoveOrders, gsAttackerMoveExecute,
                          gsAttackerBattleOrders, gsAttackerBattleExecute, gsDefenderMoveOrders,
                          gsDefenderMoveExecute, gsDefenderBattleOrders, gsDefenderBattleExecute, gsCheckVictory] then
  begin
    // Vérifier si le bouton "Suivant" doit être affiché
    if (Game.CurrentState = gsSetupAttacker) then
    begin
      if Game.AttackerUnitsPlaced then
      begin
        if not Game.ShowConfirmDialog then
        begin
          if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 30), 'Suivant') = 1 then
          begin
            Game.ShowConfirmDialog := True; // Afficher la boîte de dialogue
          end;
        end
        else
        begin
          // Afficher la boîte de dialogue de confirmation
          dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin du placement ?', 'Oui;Non');
          if dialogResult = 1 then // Oui
          begin
            Game.ShowConfirmDialog := False;
            Game.CurrentState := gsSetupDefender;
          end
          else if dialogResult = 2 then // Non
          begin
            Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
          end;
        end;
        yPos := yPos + 40;
      end
      else
      begin
        yPos := yPos + 40; // Espace pour le bouton "Suivant" (non affiché)
      end;
    end
    else if (Game.CurrentState = gsSetupDefender) then
    begin
      if Game.DefenderUnitsPlaced then
      begin
        if not Game.ShowConfirmDialog then
        begin
          if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 30), 'Suivant') = 1 then
          begin
            Game.ShowConfirmDialog := True; // Afficher la boîte de dialogue
          end;
        end
        else
        begin
          // Afficher la boîte de dialogue de confirmation
          dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin du placement ?', 'Oui;Non');
          if dialogResult = 1 then // Oui
          begin
            Game.ShowConfirmDialog := False;
            Game.CurrentState := gsAttackerMoveOrders;
          end
          else if dialogResult = 2 then // Non
          begin
            Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
          end;
        end;
        yPos := yPos + 40;
      end
      else
      begin
        yPos := yPos + 40; // Espace pour le bouton "Suivant" (non affiché)
      end;
    end
    else
    begin
      yPos := yPos + 40; // Espace pour le bouton "Suivant" (non affiché)
    end;
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
      if (Game.Attacker.PlayerType = ptAI) and (Game.Attacker.SetupType = stManual) then
        message := 'IA-manuel : Cliquez avec le bouton droit pour positionner les unités attaquantes'
      else
        message := 'Cliquez avec le bouton droit sur la carte pour positionner les unités attaquantes';
    end
    else
    begin
      if (Game.Attacker.PlayerType = ptAI) and (Game.Attacker.SetupType = stManual) then
        message := 'IA-manuel : Unités attaquantes positionnées'
      else if Game.Attacker.SetupType = stManual then
        message := 'Unités attaquantes positionnées'
      else
        message := 'Unités attaquantes positionnées automatiquement. Cliquez sur Suivant pour continuer';
      if Game.Attacker.SetupType = stManual then
        message := message + '. Vous pouvez les déplacer';
    end;
    AddMessage(message);

    // Afficher le message d'erreur (si présent)
    if Game.ErrorMessage <> '' then
      AddMessage(Game.ErrorMessage);
  end
  else if Game.CurrentState = gsSetupDefender then
  begin
    if not Game.DefenderUnitsPlaced then
    begin
      message := 'Positionnement automatique des unités défenseurs en cours...';
    end
    else
    begin
      if (Game.Defender.PlayerType = ptAI) and (Game.Defender.SetupType = stManual) then
        message := 'IA-manuel : Unités défenseurs positionnées'
      else if Game.Defender.SetupType = stManual then
        message := 'Unités défenseurs positionnées'
      else
        message := 'Unités défenseurs positionnées automatiquement. Cliquez sur Suivant pour continuer';
      if Game.Defender.SetupType = stManual then
        message := message + '. Vous pouvez les déplacer';
    end;
    AddMessage(message);

    // Afficher le message d'erreur (si présent)
    if Game.ErrorMessage <> '' then
      AddMessage(Game.ErrorMessage);
  end;

  // Panneau défilant pour l'historique des messages
  if Game.MessageCount > 0 then
  begin
    // Définir le rectangle du panneau en bas de l'écran
    panelBounds := RectangleCreate(leftBorderWidth, screenHeight - bottomBorderHeight, screenWidth - leftBorderWidth - rightBorderWidth, bottomBorderHeight);

    // Calculer la hauteur totale de l'historique des messages (20 pixels par message)
    contentHeight := Game.MessageCount * 20;
    contentBounds := RectangleCreate(0, 0, panelBounds.width - 20, contentHeight); // -20 pour laisser de la place au slider

    // Initialiser le défilement
    scroll := Vector2Create(0, 0);

    // Créer le panneau défilant
    scrollResult := GuiScrollPanel(panelBounds, 'Historique', contentBounds, @scroll, @view);
    if scrollResult <> 0 then
    begin
      // Le panneau a été interactif (par exemple, l'utilisateur a fait défiler)
      // Pas d'action spécifique pour l'instant, mais on peut ajouter une logique si nécessaire
    end;

    // Ajuster le défilement pour afficher les derniers messages par défaut
    if scroll.y = 0 then
    begin
      scroll.y := -(contentHeight - panelBounds.height); // Positionner le slider en bas
      if scroll.y > 0 then scroll.y := 0; // Ne pas dépasser le début de la liste
    end;

    // Calculer les messages visibles
   firstVisibleMessage := Trunc(Abs(scroll.y)) div 20; // Conversion de Single en Integer avec Trunc
    lastVisibleMessage := firstVisibleMessage + (Trunc(panelBounds.height) div 20); // Conversion de Single en Integer avec Trunc   if lastVisibleMessage >= Game.MessageCount then
      lastVisibleMessage := Game.MessageCount - 1;

    // Afficher les messages visibles
    BeginScissorMode(Round(view.x), Round(view.y), Round(view.width), Round(view.height));
    for i := firstVisibleMessage to lastVisibleMessage do
    begin
      if (i >= 0) and (i < Game.MessageCount) then
      begin
        yMsgPos := trunc(panelBounds.y) + (i * 20) + trunc(scroll.y);
        if (yMsgPos >= panelBounds.y) and (yMsgPos < panelBounds.y + panelBounds.height) then
        begin
          GuiLabel(RectangleCreate(panelBounds.x + 10, yMsgPos, panelBounds.width - 30, 20), PChar(Game.Messages[i]));
        end;
      end;
    end;
    EndScissorMode();
  end;
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
      DrawUnits; // Afficher toutes les unités (y compris celles déjà positionnées)
      DrawUnitSelectionFrame; // Dessiner le cadre jaune autour de l'unité sélectionnée
      EndMode2D();
      affichageBordEcran(); // Dessine les bordures noires
      AffichageEcranGui(Game.CurrentState); // Affiche le GUI
    end;

    gsSetupDefender:
    begin
      BeginMode2D(camera);
      DrawTexture(texture, 0, 0, WHITE); // Dessiner l'image à la position (0, 0)
      DrawUnits; // Afficher toutes les unités (y compris celles déjà positionnées)
      DrawUnitSelectionFrame; // Dessiner le cadre jaune autour de l'unité sélectionnée
      EndMode2D();
      affichageBordEcran(); // Dessine les bordures noires
      AffichageEcranGui(Game.CurrentState); // Affiche le GUI
    end;

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
  Game.DefenderUnitsPlaced := False;

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

  // Initialiser ShowConfirmDialog
  Game.ShowConfirmDialog := False;

  // Initialiser l'historique des messages
  SetLength(Game.Messages, 0);
  Game.MessageCount := 0;

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
      AddMessage('Jeu initialisé, passage à l''écran de démarrage');
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
          AddMessage('Musique arrêtée');
        end
        else
        begin
          PlayMusicStream(Game.Music);
          Game.MusicPlaying := True;
          AddMessage('Musique reprise');
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
          AddMessage('Musique arrêtée à la fin de l''écran de démarrage');
        end;
        AddMessage('Passage au menu principal');
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
          AddMessage('Musique arrêtée');
        end
        else
        begin
          PlayMusicStream(Game.Music);
          Game.MusicPlaying := True;
          AddMessage('Musique reprise');
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
          AddMessage('Musique arrêtée');
        end
        else
        begin
          PlayMusicStream(Game.Music);
          Game.MusicPlaying := True;
          AddMessage('Musique reprise');
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
        Game.DefenderUnitsPlaced := False;

        // Passer au placement des troupes de l'attaquant
        Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
        Game.CurrentState := gsSetupAttacker;
        AddMessage('Nouvelle partie commencée, passage au placement des attaquants');
      end;
    end;

    gsSetupAttacker:
    begin
      // Mettre à jour clickedHexID à chaque clic gauche, même avant le positionnement
      if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and not Game.IsDragging then
      begin
        worldPosition := GetScreenToWorld2D(GetMousePosition(), camera);
        clickedHexID := GetHexagonAtPosition(worldPosition.x, worldPosition.y);
      end;

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
            AddMessage('Unités attaquantes positionnées autour de l''hexagone ' + IntToStr(clickedHexID));
            // Si mode manuel (humain ou IA), attendre l’action de l’utilisateur
            // Sinon, passer à l’état suivant
            if not (Game.Attacker.SetupType = stManual) then
            begin
              Game.CurrentState := gsSetupDefender;
              AddMessage('Passage au placement des défenseurs (mode non manuel)');
            end;
          end;
        end;
      end
      else if Game.Attacker.SetupType = stManual then // Mode manuel (humain ou IA)
      begin
        // Mode manuel : permettre le déplacement des unités
        if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and not Game.IsDragging then
        begin
          worldPosition := GetScreenToWorld2D(GetMousePosition(), camera);

          // Essayer de sélectionner une unité
          Game.SelectedUnitID := SelectUnit(GetMousePosition().x, GetMousePosition().y, 1); // 1 = attaquant
          if Game.SelectedUnitID >= 1 then
            AddMessage('Unité attaquante ' + IntToStr(Game.SelectedUnitID) + ' sélectionnée');
          // Toujours mettre à jour clickedHexID, même si une unité est sélectionnée
          clickedHexID := GetHexagonAtPosition(worldPosition.x, worldPosition.y);
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
                AddMessage('Unité attaquante ' + IntToStr(Game.SelectedUnitID) + ' déplacée sur l''hexagone ' + IntToStr(clickedHexID));
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

    gsSetupDefender:
    begin
      // Mettre à jour clickedHexID à chaque clic gauche, même avant le positionnement
      if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and not Game.IsDragging then
      begin
        worldPosition := GetScreenToWorld2D(GetMousePosition(), camera);
        clickedHexID := GetHexagonAtPosition(worldPosition.x, worldPosition.y);
      end;

      // Positionnement automatique des unités défenseurs (tous les modes)
      if not Game.DefenderUnitsPlaced then
      begin
        // Placer les unités défenseurs selon les positions fixes
        CenterUnitOnHexagon(41, 269); // infanterie
        CenterUnitOnHexagon(42, 363); // infanterie
        CenterUnitOnHexagon(43, 249); // infanterie
        CenterUnitOnHexagon(44, 395); // infanterie
        CenterUnitOnHexagon(45, 459); // infanterie
        CenterUnitOnHexagon(46, 332); // infanterie
        CenterUnitOnHexagon(47, 270); // infanterie
        CenterUnitOnHexagon(48, 427); // infanterie
        CenterUnitOnHexagon(49, 492); // infanterie
        CenterUnitOnHexagon(50, 300); // archer
        CenterUnitOnHexagon(51, 331); // archer
        CenterUnitOnHexagon(52, 493); // archer
        CenterUnitOnHexagon(53, 558); // archer
        CenterUnitOnHexagon(54, 309); // cav
        CenterUnitOnHexagon(55, 400); // cav
        CenterUnitOnHexagon(56, 529); // cav
        CenterUnitOnHexagon(57, 271); // cav
        CenterUnitOnHexagon(58, 340); // cav
        CenterUnitOnHexagon(59, 308); // comte
        CenterUnitOnHexagon(60, 431); // chef
        CenterUnitOnHexagon(61, 301); // trebuchet
        CenterUnitOnHexagon(62, 494); // trebuchet
        CenterUnitOnHexagon(63, 366); // milicien
        CenterUnitOnHexagon(64, 398); // milicien
        CenterUnitOnHexagon(65, 462); // milicien
        CenterUnitOnHexagon(66, 496); // milicien
        CenterUnitOnHexagon(67, 96);  // bateau

        Game.DefenderUnitsPlaced := True;
        AddMessage('Unités défenseurs positionnées automatiquement');
      end
      else if Game.Defender.SetupType = stManual then // Mode manuel (humain ou IA)
      begin
        // Mode manuel : permettre le déplacement des unités
        if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and not Game.IsDragging then
        begin
          worldPosition := GetScreenToWorld2D(GetMousePosition(), camera);

          // Essayer de sélectionner une unité
          Game.SelectedUnitID := SelectUnit(GetMousePosition().x, GetMousePosition().y, 2); // 2 = défenseur
          if Game.SelectedUnitID >= 1 then
            AddMessage('Unité défenseur ' + IntToStr(Game.SelectedUnitID) + ' sélectionnée');
          // Toujours mettre à jour clickedHexID, même si une unité est sélectionnée
          clickedHexID := GetHexagonAtPosition(worldPosition.x, worldPosition.y);
        end;

        // Déplacer l'unité sélectionnée avec clic droit
        if (Game.SelectedUnitID >= 1) and IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) then
        begin
          worldPosition := GetScreenToWorld2D(GetMousePosition(), camera);
          clickedHexID := GetHexagonAtPosition(worldPosition.x, worldPosition.y);
          if clickedHexID > 0 then
          begin
            // Vérifier les règles de déplacement
            if Game.Units[Game.SelectedUnitID].TypeUnite.lenom = 'bateau' then
            begin
              if Hexagons[clickedHexID].TerrainType <> 'mer' then
              begin
                Game.ErrorMessage := 'Déplacement interdit : les bateaux doivent être sur la mer';
                Game.SelectedUnitID := -1; // Désélectionner l'unité
              end;
            end
            else if not Hexagons[clickedHexID].IsCastle then
            begin
              Game.ErrorMessage := 'Déplacement interdit : les unités doivent rester dans le château';
              Game.SelectedUnitID := -1; // Désélectionner l'unité
            end
            else
            begin
              // Vérifier si l'hexagone est occupé par une autre unité
              Game.IsOccupied := False;
              for k := 1 to MAX_UNITS do
              begin
                if Game.Units[k].HexagoneActuel = clickedHexID then
                begin
                  Game.IsOccupied := True;
                  Break;
                end;
              end;

              // Vérifier si l'unité est le Comte ou le Chef milicien
              Game.IsSpecialUnit := (Game.Units[Game.SelectedUnitID].TypeUnite.lenom = 'comte') or
                                   (Game.Units[Game.SelectedUnitID].TypeUnite.lenom = 'chef_milicien');

              if Game.IsOccupied and not Game.IsSpecialUnit then
              begin
                Game.ErrorMessage := 'Déplacement interdit : hexagone occupé';
                Game.SelectedUnitID := -1; // Désélectionner l'unité
              end
              else
              begin
                // Déplacer l'unité
                CenterUnitOnHexagon(Game.SelectedUnitID, clickedHexID);
                AddMessage('Unité défenseur ' + IntToStr(Game.SelectedUnitID) + ' déplacée sur l''hexagone ' + IntToStr(clickedHexID));
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
        AddMessage('Fin du jeu, retour au menu principal');
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
