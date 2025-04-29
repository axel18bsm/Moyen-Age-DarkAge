unit GameManager;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, raylib, raygui, init, TypInfo, UnitProcFunc,Math;

// Procédures pour gérer le GameManager
procedure InitializeGameManager;
procedure UpdateGameManager;
procedure DrawGameManager;
procedure CleanupGameManager;
procedure AffichageEcranGui(depart: TGameState);
procedure affichageBordEcran();
procedure DrawWallsTemporary;
procedure DrawRiverTemporary;
procedure CleanupUnits;
procedure DrawCastleTemporary;
procedure DrawUnits;
procedure DoNothing;
function DisplayHexAndUnitsInfo(hexID: Integer; var yPos: Integer): Integer;
procedure AddMessage(msg: string);
procedure HandleInitializationUpdate;
procedure HandleInitializationDraw;
procedure HandleSplashScreenUpdate;
procedure HandleSplashScreenDraw;
procedure HandleMainMenuUpdate;
procedure HandleMainMenuDraw;
procedure HandleNewGameMenuUpdate;
procedure HandleNewGameMenuDraw;
procedure HandleSetupAttackerUpdate;
procedure HandleSetupAttackerDraw;
procedure HandleSetupDefenderUpdate;
procedure HandleSetupDefenderDraw;
procedure HandleGameOverUpdate;
procedure HandleGameOverDraw;
procedure HandleNotImplementedDraw; // Pour les états non implémentés
procedure DrawMouseCoordinates;
function DrawGeneralInfo(var yPos: Integer): Integer;
procedure DrawHexAndUnitsInfo(var yPos: Integer);
procedure DrawButtons(depart: TGameState);
procedure DrawMessagePanel;
procedure HandleMoveOrders(numplayer: Integer); // Fonction commune
procedure HandleAttackerMoveOrdersUpdate;
procedure HandleAttackerMoveOrdersDraw;
procedure HandleDefenderMoveOrdersUpdate;
procedure HandleDefenderMoveOrdersDraw;
procedure HandleGameplayDraw;
procedure HandleAttackerMoveExecuteUpdate;
procedure HandleAttackerBattleOrdersUpdate;
procedure HandleCheckVictoryAttackerUpdate;
procedure HandleDefenderMoveExecuteUpdate;
procedure HandleDefenderBattleOrdersUpdate;
procedure HandleCheckVictoryDefenderUpdate;
//procedure HandlePlayerTurnUpdate;
procedure HandleCommonInput(numplayer: Integer; doMoveOrders: Boolean);
procedure HandleStateTransition(currentState: TGameState; nextState: TGameState; confirmMessage: string; nextPlayerIsAttacker: Boolean; successMessage: string; condition: Boolean);
function ExecuteUnitMovement(numplayer: Integer): Boolean;
procedure HandleBattleOrdersUpdate(numplayer: Integer);
procedure HandleBattlePhaseButtons(numplayer: Integer; var buttonY: Integer);



implementation

procedure HandleBattlePhaseButtons(numplayer: Integer; var buttonY: Integer);
const
  BUTTON_WIDTH = 230;
  BUTTON_HEIGHT = 30;
var
  dialogResult: Integer;
  buttonsEnabled: Boolean;
begin
  // Vérifier si les boutons "Combattre" et "Annuler" doivent être activés
  buttonsEnabled := (Length(Game.CombatOrders) > 0) and
                    (Length(Game.CombatOrders[0].AttackerIDs) > 0) and
                    (Game.CombatOrders[0].TargetHexID >= 1);

  // Bouton "Combattre"
  if not buttonsEnabled then
    GuiDisable();
  if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Combattre') = 1 then
  begin
    ExecuteMaterialCombat;
    AddMessage('Combat exécuté');
  end;
  if not buttonsEnabled then
    GuiEnable();
  Inc(buttonY, BUTTON_HEIGHT);

  // Bouton "Annuler"
  if not buttonsEnabled then
    GuiDisable();
  if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Annuler') = 1 then
  begin
    SetLength(Game.CombatOrders, 0);
    AddMessage('Ordres de combat annulés');
  end;
  if not buttonsEnabled then
    GuiEnable();
  Inc(buttonY, BUTTON_HEIGHT);

  // Bouton "Suivant"
  if not Game.ShowConfirmDialog then
  begin
    if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Suivant') = 1 then
      Game.ShowConfirmDialog := True;
    Inc(buttonY, BUTTON_HEIGHT);
  end
  else
  begin
    dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin des ordres de combat ?', 'Oui;Non');
    if dialogResult = 1 then
    begin
      Game.ShowConfirmDialog := False;
      if numplayer = 1 then
      begin
        Game.CurrentState := gsCheckVictoryAttacker;
        AddMessage('Vérification de victoire (Attaquant)');
      end
      else
      begin
        Game.CurrentState := gsCheckVictoryDefender;
        AddMessage('Vérification de victoire (Défenseur)');
      end;
    end
    else if dialogResult = 2 then
    begin
      Game.ShowConfirmDialog := False;
    end;
  end;
end;
procedure HandleBattleOrdersUpdate(numplayer: Integer);
var
  mousePos: TVector2;
  unitIndex, hexID, i: Integer;
  alreadyAttacker, isCatapult: Boolean;
  targetPlayer: Integer;
begin
  HandleCommonInput(numplayer, False);
  mousePos := GetScreenToWorld2D(GetMousePosition(), camera);

  // Déterminer le joueur cible (inversé par rapport à numplayer)
  targetPlayer := 3 - numplayer;

  // Clic droit : Sélectionner une cible (hexagone et unité si présente)
  if IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) then
  begin
    // Détecter l'hexagone cliqué
    hexID := GetHexagonAtPosition(mousePos.x, mousePos.y);
    if hexID < 1 then
      Exit;

    // Réinitialiser les ordres de combat
    if Length(Game.CombatOrders) = 0 then
      SetLength(Game.CombatOrders, 1);
    Game.CombatOrders[0].TargetHexID := hexID;
    Game.CombatOrders[0].TargetID := -1; // Par défaut, pas d'unité
    SetLength(Game.CombatOrders[0].AttackerIDs, 0); // Réinitialiser les attaquants

    // Vérifier si une unité ennemie est présente sur cet hexagone
    for unitIndex := 1 to MAX_UNITS do
    begin
      if not (Game.Units[unitIndex].visible and (Game.Units[unitIndex].HexagoneActuel = hexID)) then
        Continue;
      if not (Game.Units[unitIndex].numplayer = targetPlayer) or Game.Units[unitIndex].IsAttacked then
        Continue;

      Game.CombatOrders[0].TargetID := unitIndex;
      AddMessage('Unité cible ' + IntToStr(unitIndex) + ' sélectionnée sur hexagone ' + IntToStr(hexID));
      Exit;
    end;

    // Si aucune unité n'est présente, afficher un message pour l'hexagone
    if (Hexagons[hexID].IsCastle) or (Hexagons[hexID].Objet = 3000) then
      AddMessage('Hexagone cible ' + IntToStr(hexID) + ' sélectionné (mur/grille)')
    else
      AddMessage('Hexagone cible ' + IntToStr(hexID) + ' sélectionné');
    Exit;
  end;

  // Clic gauche : Ajouter une unité comme attaquant
  if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
  begin
    if (Length(Game.CombatOrders) = 0) or (Game.CombatOrders[0].TargetHexID < 1) then
    begin
      AddMessage('Sélectionnez une cible avant d''ajouter un attaquant.');
      Exit;
    end;

    for unitIndex := 1 to MAX_UNITS do
    begin
      if not (Game.Units[unitIndex].visible and (Game.Units[unitIndex].HexagoneActuel >= 1)) then
        Continue;
      if not CheckCollisionPointRec(mousePos, Game.Units[unitIndex].BtnPerim) then
        Continue;
      if not (Game.Units[unitIndex].numplayer = numplayer) or Game.Units[unitIndex].HasAttacked then
        Continue;

      // Vérifier si l'attaquant est déjà dans la liste
      alreadyAttacker := False;
      for i := 0 to High(Game.CombatOrders[0].AttackerIDs) do
        if Game.CombatOrders[0].AttackerIDs[i] = unitIndex then
        begin
          alreadyAttacker := True;
          Break;
        end;
      if alreadyAttacker then
        Continue;

      // Déterminer si l'unité est une catapulte (trébuchet : ID 6, 7, 15, 16)
      isCatapult := unitIndex in [6, 7, 15, 16];

      // Vérifier la portée
      if isCatapult then
      begin
        // Les trébuchets vérifient la portée par rapport à l'hexagone (mur/grille)
        if not IsInRangeBFS(Game.Units[unitIndex],
                            Game.CombatOrders[0].TargetHexID,
                            Vector2Create(Hexagons[Game.CombatOrders[0].TargetHexID].CenterX,
                                          Hexagons[Game.CombatOrders[0].TargetHexID].CenterY),
                            4) then
        begin
          AddMessage('Attaquant id ' + IntToStr(unitIndex) + ' hors de portée');
          Continue;
        end;
      end
      else
      begin
        // Les autres unités (cavalerie, archers, infanterie) vérifient la portée par rapport à l'unité cible
        if Game.CombatOrders[0].TargetID < 1 then
        begin
          AddMessage('Aucune unité ennemie à attaquer pour id ' + IntToStr(unitIndex));
          Continue;
        end;
        if not IsInRangeBFS(Game.Units[unitIndex],
                            Game.Units[Game.CombatOrders[0].TargetID].HexagoneActuel,
                            Vector2Create(Hexagons[Game.Units[Game.CombatOrders[0].TargetID].HexagoneActuel].CenterX,
                                          Hexagons[Game.Units[Game.CombatOrders[0].TargetID].HexagoneActuel].CenterY),
                            4) then
        begin
          AddMessage('Attaquant id ' + IntToStr(unitIndex) + ' hors de portée');
          Continue;
        end;
      end;

      // Vérifier la limite de 10 attaquants
      if Length(Game.CombatOrders[0].AttackerIDs) >= 10 then
      begin
        AddMessage('Limite de 10 attaquants atteinte');
        Exit;
      end;

      // Ajouter l'attaquant
      SetLength(Game.CombatOrders[0].AttackerIDs, Length(Game.CombatOrders[0].AttackerIDs) + 1);
      Game.CombatOrders[0].AttackerIDs[High(Game.CombatOrders[0].AttackerIDs)] := unitIndex;
      AddMessage('Unité attaquante ' + IntToStr(unitIndex) + ' ajoutée');
      Exit;
    end;
  end;
end;
function ExecuteUnitMovement(numplayer: Integer): Boolean;
var
  i, j, startIndex, endIndex: Integer;
  foundMovableUnit: Boolean;
  newHexID, normalizedHexID, neighborID: Integer;
  terrainCost: TTerrainCost;
  isSpecialUnit, isPresentUnitSpecial: Boolean;
  blockingUnitIndex: Integer;
begin
  // Déterminer les limites de l'armée en fonction du joueur
  if numplayer = 1 then
  begin
    startIndex := 1;
    endIndex := 40; // Attaquants : unités 1 à 40
  end
  else
  begin
    startIndex := 41;
    endIndex := 68; // Défenseurs : unités 41 à 68
  end;

  // Parcourir les unités pour vérifier si au moins une peut bouger
  foundMovableUnit := False;
  for i := startIndex to endIndex do
  begin
    if Game.Units[i].HasMoveOrder and not Game.Units[i].tourMouvementTermine then
    begin
      foundMovableUnit := True;
      Break;
    end;
  end;

  // Si aucune unité ne peut bouger, sortir de la phase
  if not foundMovableUnit then
  begin
    Result := True;
    Exit;
  end;

  // Traiter le mouvement de toutes les unités qui peuvent bouger
  for i := startIndex to endIndex do
  begin
    if Game.Units[i].HasMoveOrder and not Game.Units[i].tourMouvementTermine then
    begin
      // Traiter jusqu'à vitesseInitiale points pour cette unité
      j := 0;
      while j < Game.Units[i].vitesseInitiale do
      begin
        // Vérifier si on a atteint la fin du chemin
        if Game.Units[i].CurrentPathIndex >= Length(Game.Units[i].chemin) then
        begin
          // Positionner l'unité sur HexagoneCible et terminer, en centrant l'unité
          Game.Units[i].PositionActuelle := Vector2Create(
            Hexagons[Game.Units[i].HexagoneCible].CenterX - Game.Units[i].TextureHalfWidth,
            Hexagons[Game.Units[i].HexagoneCible].CenterY - Game.Units[i].TextureHalfHeight
          );
          Game.Units[i].HexagoneActuel := Game.Units[i].HexagoneCible;
          Game.Units[i].HasMoveOrder := False;
          Game.Units[i].tourMouvementTermine := True;
          Game.Units[i].hasStopped := False;
          UpdateUnitBtnPerim(i);
          if (i in [67, 68]) and (Game.Units[i].HexagoneActuel = Game.Units[i].HexagoneDepart) then
          begin
            Game.Units[i].IsLoaded := True;
            AddMessage('Bateau ' + IntToStr(i) + ' a rechargé sur hexagone ' + IntToStr(Game.Units[i].HexagoneDepart));
          end;
          Break;
        end;

        // Mettre à jour la position actuelle, en centrant l'unité
        Game.Units[i].PositionActuelle := Vector2Create(
          Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.x - Game.Units[i].TextureHalfWidth,
          Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.y - Game.Units[i].TextureHalfHeight
        );

        // Mettre à jour BtnPerim après avoir changé la position
        UpdateUnitBtnPerim(i);

        // Vérifier si on change d'hexagone
        newHexID := Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].Hexbrut;
        if (Game.Units[i].CurrentPathIndex = 0) or
           (newHexID <> Game.Units[i].chemin[Game.Units[i].CurrentPathIndex - 1].Hexbrut) then
        begin
          // Normaliser newHexID pour obtenir l'hexagone réel (sans objet)
          normalizedHexID := newHexID;
          if newHexID > 832 then
            normalizedHexID := newHexID mod 1000; // Retirer l'objet (par exemple, 1832 -> 832)

          // 1. Vérification de Hexbrut
          if newHexID > 832 then
          begin
            // Revenir au point précédent si on n'est pas au début du chemin
            if Game.Units[i].CurrentPathIndex > 0 then
            begin
              Dec(Game.Units[i].CurrentPathIndex);
              Game.Units[i].PositionActuelle := Vector2Create(
                Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.x - Game.Units[i].TextureHalfWidth,
                Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.y - Game.Units[i].TextureHalfHeight
              );
              UpdateUnitBtnPerim(i);
            end;
            Game.Units[i].tourMouvementTermine := True;
            Break;
          end;

          // 2. Vérification du coût
          terrainCost := GetTerrainCost(Hexagons[normalizedHexID].TerrainType);
          if Game.Units[i].distanceMaxi <= terrainCost.MovementCost then
          begin
            // Revenir au point précédent si on n'est pas au début du chemin
            if Game.Units[i].CurrentPathIndex > 0 then
            begin
              Dec(Game.Units[i].CurrentPathIndex);
              Game.Units[i].PositionActuelle := Vector2Create(
                Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.x - Game.Units[i].TextureHalfWidth,
                Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.y - Game.Units[i].TextureHalfHeight
              );
              UpdateUnitBtnPerim(i);
            end;
            Game.Units[i].tourMouvementTermine := True;
            Break;
          end;

          // 3. Vérification du terrain
          if (Game.Units[i].TypeUnite.lenom = 'bateau') and (Hexagons[normalizedHexID].TerrainType <> 'mer') then
          begin
            // Revenir au point précédent si on n'est pas au début du chemin
            if Game.Units[i].CurrentPathIndex > 0 then
            begin
              Dec(Game.Units[i].CurrentPathIndex);
              Game.Units[i].PositionActuelle := Vector2Create(
                Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.x - Game.Units[i].TextureHalfWidth,
                Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.y - Game.Units[i].TextureHalfHeight
              );
              UpdateUnitBtnPerim(i);
            end;
            Game.Units[i].tourMouvementTermine := True;
            Break;
          end;
          if (Game.Units[i].TypeUnite.lenom <> 'bateau') and (Hexagons[normalizedHexID].TerrainType = 'mer') then
          begin
            // Revenir au point précédent si on n'est pas au début du chemin
            if Game.Units[i].CurrentPathIndex > 0 then
            begin
              Dec(Game.Units[i].CurrentPathIndex);
              Game.Units[i].PositionActuelle := Vector2Create(
                Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.x - Game.Units[i].TextureHalfWidth,
                Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.y - Game.Units[i].TextureHalfHeight
              );
              UpdateUnitBtnPerim(i);
            end;
            Game.Units[i].tourMouvementTermine := True;
            Break;
          end;

          // 4. Vérification de l'empilement
          blockingUnitIndex := -1;
          for j := startIndex to endIndex do
          begin
            if (j <> i) and (Game.Units[j].HexagoneActuel = normalizedHexID) then
            begin
              blockingUnitIndex := j;
              Break;
            end;
          end;
          if blockingUnitIndex <> -1 then
          begin
            // Vérifier si l'une des unités est spéciale
            isSpecialUnit := (Game.Units[i].TypeUnite.Id in [4, 5, 13, 14]); // Duc, Lieutenant, Comte, Chef Milicien
            isPresentUnitSpecial := (Game.Units[blockingUnitIndex].TypeUnite.Id in [4, 5, 13, 14]);
            if not (isSpecialUnit or isPresentUnitSpecial) then
            begin
              // Revenir au point précédent si on n'est pas au début du chemin
              if Game.Units[i].CurrentPathIndex > 0 then
              begin
                Dec(Game.Units[i].CurrentPathIndex);
                Game.Units[i].PositionActuelle := Vector2Create(
                  Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.x - Game.Units[i].TextureHalfWidth,
                  Game.Units[i].chemin[Game.Units[i].CurrentPathIndex].chemin.y - Game.Units[i].TextureHalfHeight
                );
                UpdateUnitBtnPerim(i);
              end;
              Game.Units[i].hasStopped := True;
              // Si l'unité bloquante a tmt = True, l'unité bloquée termine aussi son tour
              if Game.Units[blockingUnitIndex].tourMouvementTermine then
                Game.Units[i].tourMouvementTermine := True;
              Break;
            end;
          end;

          // 5. Vérification des unités adverses dans les voisins
          for j := 1 to MAX_UNITS do
          begin
            if (Game.Units[j].numplayer <> numplayer) and
               (Game.Units[j].HexagoneActuel <> -1) then
            begin
              // Normaliser les voisins pour comparer les hexagones réels
              neighborID := Hexagons[normalizedHexID].Neighbor1;
              if neighborID > 832 then neighborID := neighborID mod 1000;
              if Game.Units[j].HexagoneActuel = neighborID then
              begin
                Game.Units[i].HexagoneActuel := normalizedHexID;
                Game.Units[i].tourMouvementTermine := True;
                Break;
              end;
              neighborID := Hexagons[normalizedHexID].Neighbor2;
              if neighborID > 832 then neighborID := neighborID mod 1000;
              if Game.Units[j].HexagoneActuel = neighborID then
              begin
                Game.Units[i].HexagoneActuel := normalizedHexID;
                Game.Units[i].tourMouvementTermine := True;
                Break;
              end;
              neighborID := Hexagons[normalizedHexID].Neighbor3;
              if neighborID > 832 then neighborID := neighborID mod 1000;
              if Game.Units[j].HexagoneActuel = neighborID then
              begin
                Game.Units[i].HexagoneActuel := normalizedHexID;
                Game.Units[i].tourMouvementTermine := True;
                Break;
              end;
              neighborID := Hexagons[normalizedHexID].Neighbor4;
              if neighborID > 832 then neighborID := neighborID mod 1000;
              if Game.Units[j].HexagoneActuel = neighborID then
              begin
                Game.Units[i].HexagoneActuel := normalizedHexID;
                Game.Units[i].tourMouvementTermine := True;
                Break;
              end;
              neighborID := Hexagons[normalizedHexID].Neighbor5;
              if neighborID > 832 then neighborID := neighborID mod 1000;
              if Game.Units[j].HexagoneActuel = neighborID then
              begin
                Game.Units[i].HexagoneActuel := normalizedHexID;
                Game.Units[i].tourMouvementTermine := True;
                Break;
              end;
              neighborID := Hexagons[normalizedHexID].Neighbor6;
              if neighborID > 832 then neighborID := neighborID mod 1000;
              if Game.Units[j].HexagoneActuel = neighborID then
              begin
                Game.Units[i].HexagoneActuel := normalizedHexID;
                Game.Units[i].tourMouvementTermine := True;
                Break;
              end;
            end;
          end;

          // Si tout est OK, mettre à jour HexagoneActuel et déduire le coût
          if not Game.Units[i].tourMouvementTermine then
          begin
            Game.Units[i].HexagoneActuel := normalizedHexID;
            Game.Units[i].distanceMaxi := Game.Units[i].distanceMaxi - terrainCost.MovementCost;
          end;
        end;

        Inc(Game.Units[i].CurrentPathIndex);
        Inc(j);
      end;
    end;
  end;

  Result := False; // Continuer la phase tant qu'il reste des unités à bouger
end;
procedure HandleStateTransition(currentState: TGameState; nextState: TGameState; confirmMessage: string; nextPlayerIsAttacker: Boolean; successMessage: string; condition: Boolean);
var
  dialogResult: Integer;
  suivantButtonY: Integer;
begin
  suivantButtonY := screenHeight - bottomBorderHeight - 70;
  if condition then
  begin
    if not Game.ShowConfirmDialog then
    begin
      if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
        Game.ShowConfirmDialog := True;
    end
    else
    begin
      dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', @confirmMessage, 'Oui;Non');
      if dialogResult = 1 then
      begin
        Game.ShowConfirmDialog := False;
        Game.CurrentState := nextState;
        if nextPlayerIsAttacker then
          Game.CurrentPlayer := Game.Attacker
        else
          Game.CurrentPlayer := Game.Defender;
        AddMessage(successMessage);
      end
      else if dialogResult = 2 then
        Game.ShowConfirmDialog := False;
    end;
  end;
end;
procedure HandleCommonInput(numplayer: Integer; doMoveOrders: Boolean);
var
  worldPosition: TVector2;
begin
  if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and not Game.IsDragging then
  begin
    worldPosition := GetScreenToWorld2D(GetMousePosition(), camera);
    if numplayer > 0 then
    begin
      Game.SelectedUnitID := SelectUnit(GetMousePosition().x, GetMousePosition().y, numplayer);
      if Game.SelectedUnitID >= 1 then
      begin
        if numplayer = 1 then
          AddMessage('Unité attaquante ' + IntToStr(Game.SelectedUnitID) + ' sélectionnée')
        else
          AddMessage('Unité défenseur ' + IntToStr(Game.SelectedUnitID) + ' sélectionnée');
      end;
    end;
    clickedHexID := GetHexagonAtPosition(worldPosition.x, worldPosition.y);
  end;
  MoveCarte2DFleche;
  DragAndDropCarte2D;
  ZoomCarte2D;
  AffichageGuiBas;
  if doMoveOrders then
    HandleMoveOrders(numplayer);
end;


procedure HandleCheckVictoryDefenderUpdate;
begin
  HandleCommonInput(0, False);

  // Vérifier si le tour maximum est atteint
  if Game.CurrentTurn = MAX_TOURS then
  begin
    Game.CurrentState := gsGameOver;
    AddMessage('Les mercenaires n''ont plus d''argent, les attaquants ont perdu');
  end;
end;

procedure HandleDefenderBattleOrdersUpdate;
begin
  HandleCommonInput(2, False);
  SelectCombatTargetAndAttackers(2); // Défenseur (joueur 2)
end;
procedure HandleDefenderMoveExecuteUpdate;
begin
  HandleCommonInput(2, False);

  // Exécuter le mouvement des unités défenseurs
  if ExecuteUnitMovement(2) then
  begin
    // Toutes les unités ont terminé leur mouvement, permettre la transition
    Game.ShowConfirmDialog := True;
  end;
end;
procedure HandleCheckVictoryAttackerUpdate;
begin
  HandleCommonInput(0, False);
end;

procedure HandleAttackerBattleOrdersUpdate;
begin
  HandleCommonInput(1, False);
  SelectCombatTargetAndAttackers(1); // Attaquant (joueur 1)
end;

procedure HandleAttackerMoveExecuteUpdate;
begin
  HandleCommonInput(1, False);

  // Exécuter le mouvement des unités attaquantes
  if ExecuteUnitMovement(1) then
  begin
    // Toutes les unités ont terminé leur mouvement, permettre la transition
    Game.ShowConfirmDialog := True;
  end;
end;
procedure HandleGameplayDraw;
begin
  BeginMode2D(camera);
  DrawTexture(texture, 0, 0, WHITE);
  DrawUnits;
  DrawUnitSelectionFrame;
  EndMode2D();
  affichageBordEcran();
  AffichageEcranGui(Game.CurrentState);
end;

// Fonction commune pour gérer les ordres de mouvement (attaquant ou défenseur)
procedure HandleMoveOrders(numplayer: Integer);
var
  worldPosition: TVector2;
  clickedHexID: Integer;
  i: Integer;
  doubleClick: Boolean;
  unit1, unit2: Integer; // Pour stocker les ID des unités sur l'hexagone
  armyText: string;
begin
  // Déterminer le texte pour les messages selon l'armée
  if numplayer = 1 then
    armyText := 'attaquante'
  else
    armyText := 'défenseur';

  // Étape 1 : Détecter le type de clic
  doubleClick := False;
  if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
  begin
    if GetTime() - Game.LastClickTime < 0.3 then // 300 ms pour un double-clic
      doubleClick := True;
    Game.LastClickTime := GetTime();
  end;

  // Étape 2 : Identifier l'hexagone cliqué (si clic gauche, double-clic ou clic droit)
  if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) or doubleClick or IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) then
  begin
    if not Game.IsDragging then // Ne pas sélectionner si on est en train de faire un glisser-déposer
    begin
      worldPosition := GetScreenToWorld2D(GetMousePosition(), camera);
      clickedHexID := GetHexagonAtPosition(worldPosition.x, worldPosition.y);
      Init.clickedHexID := clickedHexID; // Mettre à jour la variable globale clickedHexID
    end
    else
    begin
      clickedHexID := -1; // Pas d'hexagone cliqué si on est en train de glisser-déposer
      Init.clickedHexID := -1; // Mettre à jour la variable globale
    end;
  end
  else
  begin
    clickedHexID := -1; // Pas d'hexagone cliqué si aucun clic
  end;

  // Étape 3 : Gérer la sélection d'unités (clic gauche ou double-clic)
  if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) or doubleClick) and (clickedHexID > 0) then
  begin
    // Boucler sur les unités de l'armée spécifiée pour trouver celles sur cet hexagone
    unit1 := -1;
    unit2 := -1;
    for i := 1 to MAX_UNITS do
    begin
      if (Game.Units[i].HexagoneActuel = clickedHexID) and (Game.Units[i].numplayer = numplayer) then
      begin
        if unit1 = -1 then
          unit1 := i
        else if unit2 = -1 then
          unit2 := i;
      end;
    end;

    // Sélectionner une unité selon le type de clic
    if unit1 <> -1 then // Au moins une unité trouvée
    begin
      if doubleClick and (unit2 <> -1) then
      begin
        // Double-clic : sélectionner l'unité avec le plus petit ID
        if unit1 < unit2 then
          Game.SelectedUnitID := unit1
        else
          Game.SelectedUnitID := unit2;
      end
      else
      begin
        // Clic simple : sélectionner l'unité avec le plus grand ID
        if (unit2 <> -1) and (unit2 > unit1) then
          Game.SelectedUnitID := unit2
        else
          Game.SelectedUnitID := unit1;
      end;
      AddMessage('Unité ' + armyText + ' ' + IntToStr(Game.SelectedUnitID) + ' sélectionnée');
      // Mettre à jour l'hexagone cliqué pour l'affichage (hexagone de l'unité sélectionnée)
      Game.LastClickedHexID := Game.Units[Game.SelectedUnitID].HexagoneActuel;
      // Réinitialiser les informations de la destination lors de la sélection d'une nouvelle unité
      Game.LastDestinationHexID := -1;
    end
    else
    begin
      // Aucune unité sur cet hexagone, sélectionner l'hexagone
      Game.SelectedUnitID := -1; // Désélectionner toute unité
      Game.LastClickedHexID := clickedHexID; // Stocker l'hexagone cliqué pour l'affichage
      Game.LastDestinationHexID := -1; // Réinitialiser les informations de la destination
    end;
  end;

  // Étape 4 : Gérer l'ordre de mouvement (clic droit)
  if IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) and (Game.SelectedUnitID >= 1) and (clickedHexID > 0) then
  begin
    if Game.Units[Game.SelectedUnitID].numplayer = numplayer then
    begin
      Game.Units[Game.SelectedUnitID].PositionFinale := worldPosition;
      Game.Units[Game.SelectedUnitID].HasMoveOrder := True;
      Game.Units[Game.SelectedUnitID].HexagoneCible := clickedHexID;
      CalculateBresenhamPath(Game.SelectedUnitID, Game.Units[Game.SelectedUnitID].HexagoneActuel, clickedHexID);
      // Initialiser les champs liés au mouvement
      Game.Units[Game.SelectedUnitID].CurrentPathIndex := 0;
      Game.Units[Game.SelectedUnitID].tourMouvementTermine := False;
      Game.Units[Game.SelectedUnitID].hasStopped := False;
      Game.LastDestinationHexID := clickedHexID;
      AddMessage('L''unité ' + armyText + ' ' + IntToStr(Game.SelectedUnitID) + ' ' + Game.Units[Game.SelectedUnitID].TypeUnite.lenom +
                 ' va à la destination ' + IntToStr(Round(worldPosition.x)) + ', ' + IntToStr(Round(worldPosition.y)) +
                 ' hexagone ' + IntToStr(clickedHexID));
    end;
  end;
end;

// Mise à jour de HandleAttackerMoveOrdersUpdate
procedure HandleAttackerMoveOrdersUpdate;
var
  unitIndex: Integer;
begin
  if not Game.PlayerTurnProcessed then
  begin
    AddMessage('Début tour ' + IntToStr(Game.CurrentTurn) + ', BoatCount défenseur=' + IntToStr(Game.Defender.BoatCount) + ', attaquant=' + IntToStr(Game.Attacker.BoatCount));

    if Game.CurrentTurn >= 1 then
      AddBoat(2, Game.CurrentTurn);
    if Game.CurrentTurn >= 3 then
      AddBoat(1, Game.CurrentTurn);

    HandleRavitaillement;
    OrderBoatReturn;

    for unitIndex := 1 to MAX_UNITS do
    begin
      Game.Units[unitIndex].distanceMaxi := Game.Units[unitIndex].vitesseInitiale;
      Game.Units[unitIndex].tourMouvementTermine := False;
      Game.Units[unitIndex].hasStopped := False;
    end;
    ResetCombatFlags; // Appeler la nouvelle fonction pour réinitialiser les flags

    SetLength(Game.CombatOrders, 0);

    Game.PlayerTurnProcessed := True;
    AddMessage('Traitements de début de tour effectués pour l''attaquant au tour ' + IntToStr(Game.CurrentTurn));
  end;

  HandleCommonInput(1, True);
end;

// Création de HandleDefenderMoveOrdersUpdate
procedure HandleDefenderMoveOrdersUpdate;
var
  unitIndex: Integer;
begin
  if not Game.PlayerTurnProcessed then
  begin
    AddMessage('Début tour ' + IntToStr(Game.CurrentTurn) + ', BoatCount défenseur=' + IntToStr(Game.Defender.BoatCount) + ', attaquant=' + IntToStr(Game.Attacker.BoatCount));

    if Game.CurrentTurn >= 1 then
      AddBoat(2, Game.CurrentTurn);
    if Game.CurrentTurn >= 3 then
      AddBoat(1, Game.CurrentTurn);

    HandleRavitaillement;
    OrderBoatReturn;

    for unitIndex := 1 to MAX_UNITS do
    begin
      Game.Units[unitIndex].distanceMaxi := Game.Units[unitIndex].vitesseInitiale;
      Game.Units[unitIndex].tourMouvementTermine := False;
      Game.Units[unitIndex].hasStopped := False;
    end;
    ResetCombatFlags; // Appeler la nouvelle fonction pour réinitialiser les flags

    SetLength(Game.CombatOrders, 0);

    Game.PlayerTurnProcessed := True;
    AddMessage('Traitements de début de tour effectués pour le défenseur au tour ' + IntToStr(Game.CurrentTurn));
  end;

  HandleCommonInput(2, True);
end;

// Création de HandleDefenderMoveOrdersDraw (identique à HandleAttackerMoveOrdersDraw)
procedure HandleDefenderMoveOrdersDraw;

begin
  BeginMode2D(camera);

  // Dessiner la carte
  DrawTexture(texture, 0, 0, WHITE);

  // Dessiner les unités
  DrawUnits;

  // Dessiner un cadre jaune autour de l'unité sélectionnée
  if Game.SelectedUnitID >= 1 then
  begin
    DrawRectangleLines(Round(Game.Units[Game.SelectedUnitID].PositionActuelle.x - Game.Units[Game.SelectedUnitID].TextureHalfWidth),
                       Round(Game.Units[Game.SelectedUnitID].PositionActuelle.y - Game.Units[Game.SelectedUnitID].TextureHalfHeight),
                       Game.Units[Game.SelectedUnitID].latexture.width,
                       Game.Units[Game.SelectedUnitID].latexture.height,
                       YELLOW);

    // Dessiner un rond blanc sur la destination de l'unité sélectionnée
    if Game.Units[Game.SelectedUnitID].HasMoveOrder then
    begin
      DrawCircle(Round(Game.Units[Game.SelectedUnitID].PositionFinale.x),
                 Round(Game.Units[Game.SelectedUnitID].PositionFinale.y),
                 5, WHITE);
    end;
  end;

  EndMode2D();

  // Dessiner les bordures
  affichageBordEcran();

  // Dessiner le GUI
  AffichageEcranGui(Game.CurrentState);
end;


procedure HandleAttackerMoveOrdersDraw;

begin
  BeginMode2D(camera);

  // Dessiner la carte
  DrawTexture(texture, 0, 0, WHITE);

  // Ne pas dessiner les murs, rivières, château (suppression des appels)
  // DrawWallsTemporary;
  // DrawRiverTemporary;
  // DrawCastleTemporary;

  // Dessiner les unités
  DrawUnits;

  // Dessiner un cadre jaune autour de l'unité sélectionnée
  if Game.SelectedUnitID >= 1 then
  begin
    DrawRectangleLines(Round(Game.Units[Game.SelectedUnitID].PositionActuelle.x - Game.Units[Game.SelectedUnitID].TextureHalfWidth),
                       Round(Game.Units[Game.SelectedUnitID].PositionActuelle.y - Game.Units[Game.SelectedUnitID].TextureHalfHeight),
                       Game.Units[Game.SelectedUnitID].latexture.width,
                       Game.Units[Game.SelectedUnitID].latexture.height,
                       YELLOW);

    // Dessiner un rond blanc sur la destination de l'unité sélectionnée
    if Game.Units[Game.SelectedUnitID].HasMoveOrder then
    begin
      DrawCircle(Round(Game.Units[Game.SelectedUnitID].positionfinale.x),
                 Round(Game.Units[Game.SelectedUnitID].positionfinale.y),
                 5, WHITE);
    end;
  end;

  EndMode2D();

  // Dessiner les bordures
  affichageBordEcran();

  // Dessiner le GUI
  AffichageEcranGui(Game.CurrentState);
end;

// Affiche les coordonnées de la souris en bas à gauche
procedure DrawMouseCoordinates;
begin
  if clickedHexID > 0 then
  begin
    // writeln(clickedHexID);
  end
  else
    DrawText('Aucun hexagone cliqué', leftBorderWidth, screenHeight-90, 20, RED);
  DrawText(Pchartxt, leftBorderWidth, screenHeight-60, 20, RED);
  DrawText(Pchartxt2, leftBorderWidth, screenHeight-30, 20, RED);
end;

// Affiche les informations générales (titre, tour, joueur, état)
function DrawGeneralInfo(var yPos: Integer): Integer;
var
  i: Integer;
  unitID: Integer;
  modifiedForce: Single;
  hasWallOrGate, hasSpecialUnit: Boolean;
  specialUnitID: Integer;
  forceText: string;
  playerText: string;
  attackForce: Single;
begin
  Result := yPos;

  // Afficher les informations générales
  GuiGroupBox(RectangleCreate(screenWidth - rightBorderWidth + 5, yPos, 230, 450), 'Info générales');

  Inc(yPos, 20);
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 210, 20), PChar('Tour : ' + IntToStr(Game.CurrentTurn) + ' / 15'));
  Inc(yPos, 20);

  // Afficher le joueur (remplacement demandé)
  if Game.CurrentPlayer.IsAttacker then
  begin
    playerText := 'Attaquant';
    if Game.AttackerType = 1 then
      playerText := playerText + ' - AI'
    else
      playerText := playerText + ' - Humain';
  end
  else
  begin
    playerText := 'Défenseur';
    if Game.DefenderType = 1 then
      playerText := playerText + ' - AI'
    else
      playerText := playerText + ' - Humain';
  end;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 210, 20), PChar('Joueur : ' + playerText));
  yPos := yPos + 20;

  // Afficher la phase
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 210, 20), PChar('Phase : ' + GetStateDisplayText(Game.CurrentState)));
  Inc(yPos, 20);

  // Afficher le ravitaillement si pertinent

    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 210, 20), PChar('Ravitaillement : ' + FloatToStr(Game.CurrentPlayer.Ravitaillement)));
    Inc(yPos, 20);

  // Afficher les informations sur la cible
  if (Length(Game.CombatOrders) > 0) then
  begin
    // Si une unité est ciblée
    if Game.CombatOrders[0].TargetID >= 1 then
    begin
      unitID := Game.CombatOrders[0].TargetID;
      modifiedForce := Game.Units[unitID].Force;

      // Vérifier si l'hexagone a un mur ou une grille
      hasWallOrGate := (Hexagons[Game.CombatOrders[0].TargetHexID].HasWall) or (Hexagons[Game.CombatOrders[0].TargetHexID].Objet = 3000);

      // Vérifier si une unité spéciale est présente sur cet hexagone
      hasSpecialUnit := False;
      specialUnitID := -1;
      for i := 1 to MAX_UNITS do
      begin
        if (Game.Units[i].HexagoneActuel = Game.CombatOrders[0].TargetHexID) and
           (Game.Units[i].numplayer = Game.Units[unitID].numplayer) and
           (Game.Units[i].TypeUnite.Id in [4, 5, 13, 14]) then // duc, lieutenant, comte, chef milicien
        begin
          hasSpecialUnit := True;
          specialUnitID := i;
          Break;
        end;
      end;

      // Calculer la force modifiée (force de défense)
      if hasSpecialUnit then
      begin
        modifiedForce := Game.Units[unitID].Force * 3;
        forceText := 'Force : ' + FloatToStr(modifiedForce) + ' (base ' + FloatToStr(Game.Units[unitID].Force) + ', x3)';
      end
      else if hasWallOrGate then
      begin
        modifiedForce := Game.Units[unitID].Force * 2;
        forceText := 'Force : ' + FloatToStr(modifiedForce) + ' (base ' + FloatToStr(Game.Units[unitID].Force) + ', x2)';
      end
      else
      begin
        forceText := 'Force : ' + FloatToStr(modifiedForce);
      end;

      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 20, yPos, 210, 20), PChar('Cible : ID : ' + IntToStr(unitID) + ' - ' + Game.Units[unitID].TypeUnite.lenom));
      Inc(yPos, 20);
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 20, yPos, 210, 20), PChar('Force défense : ' + forceText));
      Inc(yPos, 20);
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 20, yPos, 210, 20), PChar('Hexagone : ' + IntToStr(Game.Units[unitID].HexagoneActuel)));
      Inc(yPos, 20);
      if hasSpecialUnit then
      begin
        GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 20, yPos, 210, 20), PChar('Unité spéciale présente : ID ' + IntToStr(specialUnitID)));
        Inc(yPos, 20);
      end;
    end
    // Si seul un hexagone est ciblé (mur ou grille)
    else if Game.CombatOrders[0].TargetHexID >= 1 then
    begin
      if Hexagons[Game.CombatOrders[0].TargetHexID].Objet = 3000 then
        GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 20, yPos, 210, 20), PChar('Cible : Grille'))
      else if Hexagons[Game.CombatOrders[0].TargetHexID].HasWall then
        GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 20, yPos, 210, 20), PChar('Cible : Mur'))
      else
        GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 20, yPos, 210, 20), PChar('Cible : Hexagone ' + IntToStr(Game.CombatOrders[0].TargetHexID)));
      Inc(yPos, 20);
    end
    else
    begin
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 20, yPos, 210, 20), PChar('Aucune cible sélectionnée'));
      Inc(yPos, 20);
    end;

    // Calculer et afficher la force d'attaque (total des attaquants)
    if Length(Game.CombatOrders[0].AttackerIDs) > 0 then
    begin
      attackForce := CalculateTotalForce(Game.CombatOrders[0].AttackerIDs);
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 20, yPos, 210, 20), PChar('Force attaque : ' + FloatToStr(attackForce)));
      Inc(yPos, 20);
    end;

    // Afficher les attaquants
    for i := 0 to Min(9, High(Game.CombatOrders[0].AttackerIDs)) do
    begin
      unitID := Game.CombatOrders[0].AttackerIDs[i];
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 20, yPos, 210, 20), PChar('Attaquant : ID : ' + IntToStr(unitID) + ' - ' + Game.Units[unitID].TypeUnite.lenom));
      Inc(yPos, 20);
    end;
  end
  else
  begin
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 20, yPos, 210, 20), PChar('Aucune cible sélectionnée'));
    Inc(yPos, 20);
  end;

  Result := yPos;
end;

// Affiche les informations de l'hexagone sélectionné et des unités
procedure DrawHexAndUnitsInfo(var yPos: Integer);
var
  unitCount: Integer;
begin
  unitCount := DisplayHexAndUnitsInfo(clickedHexID, yPos);
  // Mettre à jour Game.LastYPos si nécessaire
  Game.LastYPos := yPos;
end;

// Affiche les boutons (Suivant, Passer le tour, Menu) et gère la boîte de dialogue

procedure DrawButtons(depart: TGameState);
const
  BUTTON_HEIGHT = 30; // Hauteur des boutons
  BUTTON_WIDTH = 230; // Largeur des boutons
var
  dialogResult: Integer;
  baseY, buttonY: Integer;
begin
  // Calculer la position de base (bouton le plus bas à 10 pixels du bas)
  baseY := screenHeight - 10 - BUTTON_HEIGHT;

  // Ne pas modifier les phases du menu général
  if Game.CurrentState in [gsSplashScreen, gsMainMenu, gsNewGameMenu] then
  begin
    case Game.CurrentState of
      gsSplashScreen:
      begin
        // Aucun bouton dans cette phase
      end;

      gsMainMenu:
      begin
        // Boutons du menu principal (positions inchangées)
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 200, 230, 30), 'Nouvelle partie') = 1 then
          Game.CurrentState := gsNewGameMenu;
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 240, 230, 30), 'Charger partie') = 1 then
          AddMessage('Charger partie - Non implémenté');
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 280, 230, 30), 'Quitter') = 1 then
          Game.Aquitter := True;
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 320, 230, 30), 'Retour') = 1 then
          Game.CurrentState := Game.PreviousState;
      end;

      gsNewGameMenu:
      begin
        // Boutons du menu de nouvelle partie (positions inchangées)
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 200, 230, 30), 'Attaquant : Humain') = 1 then
          Game.AttackerType := 0;
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 240, 230, 30), 'Attaquant : IA') = 1 then
          Game.AttackerType := 1;
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 280, 230, 30), 'Défenseur : Humain') = 1 then
          Game.DefenderType := 0;
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 320, 230, 30), 'Défenseur : IA') = 1 then
          Game.DefenderType := 1;
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 360, 230, 30), 'Setup Attaquant : Random') = 1 then
          Game.AttackerSetup := 0;
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 400, 230, 30), 'Setup Attaquant : Manuel') = 1 then
          Game.AttackerSetup := 1;
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 440, 230, 30), 'Setup Défenseur : Random') = 1 then
          Game.DefenderSetup := 0;
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 480, 230, 30), 'Setup Défenseur : Manuel') = 1 then
          Game.DefenderSetup := 1;
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, 520, 230, 30), 'Retour') = 1 then
          Game.CurrentState := Game.PreviousState;
      end;
    end;
    Exit;
  end;

  // Positionner les boutons en partant du bas
  buttonY := baseY; // Position du bouton "Menu"

  case Game.CurrentState of
    gsSetupAttacker:
    begin
      buttonY := baseY - BUTTON_HEIGHT; // Position avant "Menu"
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Suivant') = 1 then
          Game.ShowConfirmDialog := True;
      end
      else
      begin
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous le placement des unités attaquantes ?', 'Oui;Non');
        if dialogResult = 1 then
        begin
          Game.ShowConfirmDialog := False;
          Game.AttackerUnitsPlaced := True;
          Game.CurrentState := gsSetupDefender;
          Game.CurrentPlayer := Game.Defender;
          AddMessage('Placement des unités défenseurs');
        end
        else if dialogResult = 2 then
        begin
          Game.ShowConfirmDialog := False;
        end;
      end;
    end;

    gsSetupDefender:
    begin
      buttonY := baseY - BUTTON_HEIGHT;
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Suivant') = 1 then
          Game.ShowConfirmDialog := True;
      end
      else
      begin
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous le placement des unités défenseurs ?', 'Oui;Non');
        if dialogResult = 1 then
        begin
          Game.ShowConfirmDialog := False;
          Game.DefenderUnitsPlaced := True;
          Game.CurrentState := gsAttackerMoveOrders;
          Game.CurrentPlayer := Game.Attacker;
          AddMessage('Déplacements des unités attaquantes');
        end
        else if dialogResult = 2 then
        begin
          Game.ShowConfirmDialog := False;
        end;
      end;
    end;

    gsAttackerMoveOrders:
    begin
      buttonY := baseY - BUTTON_HEIGHT;
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Suivant') = 1 then
          Game.ShowConfirmDialog := True;
      end
      else
      begin
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin des ordres de déplacement ?', 'Oui;Non');
        if dialogResult = 1 then
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsAttackerMoveExecute;
          AddMessage('Exécution des déplacements (Attaquant)');
        end
        else if dialogResult = 2 then
        begin
          Game.ShowConfirmDialog := False;
        end;
      end;
    end;

    gsDefenderMoveOrders:
    begin
      buttonY := baseY - BUTTON_HEIGHT;
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Suivant') = 1 then
          Game.ShowConfirmDialog := True;
      end
      else
      begin
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin des ordres de déplacement ?', 'Oui;Non');
        if dialogResult = 1 then
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsDefenderMoveExecute;
          AddMessage('Exécution des déplacements (Défenseur)');
        end
        else if dialogResult = 2 then
        begin
          Game.ShowConfirmDialog := False;
        end;
      end;
    end;

    gsAttackerMoveExecute:
    begin
      buttonY := baseY - BUTTON_HEIGHT;
      if Game.ShowConfirmDialog then
      begin
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin des déplacements ?', 'Oui;Non');
        if dialogResult = 1 then
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsAttackerBattleOrders;
          AddMessage('Passage aux ordres de combat (Attaquant)');
        end
        else if dialogResult = 2 then
        begin
          Game.ShowConfirmDialog := False;
        end;
      end
      else
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Suivant') = 1 then
          Game.ShowConfirmDialog := True;
      end;
    end;

    gsDefenderMoveExecute:
    begin
      buttonY := baseY - BUTTON_HEIGHT;
      if Game.ShowConfirmDialog then
      begin
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin des déplacements ?', 'Oui;Non');
        if dialogResult = 1 then
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsDefenderBattleOrders;
          AddMessage('Passage aux ordres de combat (Défenseur)');
        end
        else if dialogResult = 2 then
        begin
          Game.ShowConfirmDialog := False;
        end;
      end
      else
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Suivant') = 1 then
          Game.ShowConfirmDialog := True;
      end;
    end;

    gsAttackerBattleOrders:
    begin
      buttonY := baseY - 3 * BUTTON_HEIGHT; // "Combattre", "Annuler", "Suivant" avant "Menu"
      HandleBattlePhaseButtons(1, buttonY);
    end;

    gsDefenderBattleOrders:
    begin
      buttonY := baseY - 3 * BUTTON_HEIGHT;
      HandleBattlePhaseButtons(2, buttonY);
    end;

    gsCheckVictoryAttacker:
    begin
      buttonY := baseY - BUTTON_HEIGHT;
      if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Suivant') = 1 then
      begin
        Game.CurrentState := gsDefenderMoveOrders;
        Game.CurrentPlayer := Game.Defender;
        Game.PlayerTurnProcessed := False; // Réinitialiser pour le prochain tour
        AddMessage('Déplacements des unités défenseurs');
      end;
    end;

    gsCheckVictoryDefender:
    begin
      buttonY := baseY - BUTTON_HEIGHT;
      if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Suivant') = 1 then
      begin
        Game.CurrentState := gsAttackerMoveOrders;
        Game.CurrentPlayer := Game.Attacker;
        Game.PlayerTurnProcessed := False; // Réinitialiser pour le prochain tour
        AddMessage('Déplacements des unités attaquantes');
        Inc(Game.CurrentTurn);
      end;
    end;

    gsGameOver:
    begin
      buttonY := baseY - BUTTON_HEIGHT;
      if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, buttonY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Retour au menu') = 1 then
      begin
        Game.CurrentState := gsMainMenu;
        AddMessage('Retour au menu principal');
      end;
    end;
  end;

  // Bouton "Menu" (toujours le plus bas)
  if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, baseY, BUTTON_WIDTH, BUTTON_HEIGHT), 'Menu') = 1 then
  begin
    Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
    Game.CurrentState := gsMainMenu;
    SetLength(Game.CombatOrders, 0); // Réinitialiser les ordres de combat
    AddMessage('Retour au menu principal');
  end;
end;

// Affiche le panneau défilant pour l'historique des messages
// Affiche un panneau statique pour les 4 derniers messages de l'historique
procedure DrawMessagePanel;
var
  panelBounds: TRectangle;
  startIndex: Integer;
  i: Integer;
  yMsgPos: Integer;
  messagesToShow: Integer;
begin
  if Game.MessageCount > 0 then
  begin
    // Définir le rectangle du panneau en bas de l'écran
    panelBounds := RectangleCreate(leftBorderWidth, screenHeight - bottomBorderHeight, screenWidth - leftBorderWidth - rightBorderWidth, bottomBorderHeight);

    // Afficher un panneau statique avec le titre "Messages"
    GuiPanel(panelBounds, 'Messages');
    panelBounds.y:=panelBounds.y+10;

    // Calculer le nombre de messages à afficher (maximum 4)
    messagesToShow := Game.MessageCount;
    if messagesToShow > 4 then
      messagesToShow := 4;

    // Calculer l'index du premier message à afficher (le plus ancien parmi les 4 derniers)
    startIndex := Game.MessageCount - messagesToShow;

    // Afficher les messages (du plus récent en bas au plus ancien en haut)
    for i := 0 to messagesToShow - 1 do
    begin
      // Calculer la position Y pour que le message le plus récent soit en bas
      yMsgPos := trunc(panelBounds.y) + (messagesToShow - 1 - i) * 20 + 10; // +10 pour l'espacement du titre
      GuiLabel(RectangleCreate(panelBounds.x + 10, yMsgPos, panelBounds.width - 20, 20), PChar(Game.Messages[startIndex + i]));
    end;
  end;
end;

// Nouvelle version simplifiée de AffichageEcranGui
procedure AffichageEcranGui(depart: TGameState);
var
  yPos: Integer;
begin
  // Position de départ pour l'affichage
  yPos := 20;

  DrawMouseCoordinates; // Afficher les coordonnées de la souris

  // Afficher les informations générales (titre, tour, joueur, état, combats)
  yPos := DrawGeneralInfo(yPos);

  // Afficher les informations de l'hexagone et des unités
  DrawHexAndUnitsInfo(yPos);

  DrawButtons(depart); // Afficher les boutons et gérer la boîte de dialogue
  DrawMessagePanel; // Afficher le panneau défilant
end;

procedure HandleInitializationUpdate;
begin
  // Après l'initialisation, passer directement au splash screen
  Game.CurrentState := gsSplashScreen;
  AddMessage('Jeu initialisé, passage à l''écran de démarrage');
end;

// Gère le rendu pour l'état gsInitialization
procedure HandleInitializationDraw;
begin
  ClearBackground(BLACK);
  DrawText('Initialisation...', screenWidth div 2 - 100, screenHeight div 2, 20, WHITE);
end;
procedure HandleSplashScreenUpdate;
begin
  // Ajouter un message d'état à l'entrée de l'état
  if Game.LastStateMessage <> 'Écran de démarrage : Appuyez sur Espace pour continuer' then
    AddMessage('Écran de démarrage : Appuyez sur Espace pour continuer');

  // Mettre à jour la musique si elle est en train de jouer
  if Game.MusicPlaying then
    UpdateMusicStream(Game.Music);

  // Vérifier si la touche S est pressée pour arrêter/reprendre la musique
  if IsKeyPressed(KEY_S) then
  begin
    if Game.MusicPlaying then
    begin
      PauseMusicStream(Game.Music); // Mettre en pause au lieu d'arrêter
      Game.MusicPlaying := False;
      AddMessage('Musique mise en pause');
    end
    else
    begin
      ResumeMusicStream(Game.Music);
      PlayMusicStream(Game.Music);
      Game.MusicPlaying := True;
      AddMessage('Musique reprise');
    end;
  end;

  // Passer à l'état suivant si la touche Espace est pressée ou après 50 secondes
  if IsKeyPressed(KEY_SPACE) or (Game.SplashScreenTimer >= 50) then
  begin
    Game.CurrentState := gsMainMenu;
    Game.SplashScreenTimer := 0.0;
    AddMessage('Passage au menu principal');
  end;
end;

// Gère le rendu pour l'état gsSplashScreen
procedure HandleSplashScreenDraw;
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
// Gère la logique de mise à jour pour l'état gsMainMenu
procedure HandleMainMenuUpdate;
var
  buttonY: Integer;
  buttonWidth: Integer;
  buttonHeight: Integer;
begin
  buttonY := 10;
  buttonWidth := 150;
  buttonHeight := 40;

  if GuiButton(RectangleCreate(10, buttonY, buttonWidth, buttonHeight), 'Tutoriel') = 1 then
  begin
    AddMessage('Tutoriel : À implémenter');
  end;

  buttonY := buttonY + buttonHeight + 10;
  if GuiButton(RectangleCreate(10, buttonY, buttonWidth, buttonHeight), 'Nouvelle partie') = 1 then
  begin
    Game.CurrentState := gsNewGameMenu;
    AddMessage('Menu nouvelle partie');
  end;

  buttonY := buttonY + buttonHeight + 10;
  if GuiButton(RectangleCreate(10, buttonY, buttonWidth, buttonHeight), 'Sauvegarde') = 1 then
  begin
    AddMessage('Sauvegarde : À implémenter');
  end;

  buttonY := buttonY + buttonHeight + 10;
  if GuiButton(RectangleCreate(10, buttonY, buttonWidth, buttonHeight), 'Chargement') = 1 then
  begin
    AddMessage('Chargement : À implémenter');
  end;

  buttonY := buttonY + buttonHeight + 10;
  if GuiButton(RectangleCreate(10, buttonY, buttonWidth, buttonHeight), 'À propos') = 1 then
  begin
    AddMessage('À propos : À implémenter');
  end;

  buttonY := buttonY + buttonHeight + 10;
  if GuiButton(RectangleCreate(10, buttonY, buttonWidth, buttonHeight), 'Quitter') = 1 then
  begin
    Game.Aquitter := True;
    AddMessage('Quitter le jeu');
  end;

 buttonY := buttonY + buttonHeight + 10;
  // Bouton pour gérer la musique
  if Game.MusicPlaying then
      musicButtonText := 'Couper la musique'
    else
      musicButtonText := 'Reprendre la musique';
    if GuiButton(RectangleCreate(10, buttonY, buttonWidth, buttonHeight), PChar(musicButtonText)) > 0 then  begin
    if Game.MusicPlaying then
    begin
      PauseMusicStream(Game.Music);
      Game.MusicPlaying := False;
      AddMessage('Musique mise en pause');
    end
    else
    begin
      ResumeMusicStream(Game.Music);
      PlayMusicStream(Game.Music);
      Game.MusicPlaying := True;
      AddMessage('Musique reprise');
    end;
  end;


  buttonY := buttonY + buttonHeight + 10;

      if (Game.PreviousState in [gsAttackerMoveOrders, gsAttackerMoveExecute, gsAttackerBattleOrders, gsCheckVictoryAttacker]) then
        Game.CurrentPlayer := Game.Attacker
      else
        Game.CurrentPlayer := Game.Defender;
 end;


// Gère le rendu pour l'état gsMainMenu
procedure HandleMainMenuDraw;
var
  musicButtonText: string;
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



  // Bouton pour couper/reprendre la musique dans le menu
  if Game.MusicPlaying then
    musicButtonText := 'Couper la musique'
  else
    musicButtonText := 'Reprendre la musique';
  if GuiButton(RectangleCreate(10, 230, 180, 30), PChar(musicButtonText)) > 0 then
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

   if GuiButton(RectangleCreate(10, 270, 180, 30), 'Quitter') <> 0 then
  begin
    Game.Aquitter := True;
  end;

  // Bouton "Retour" : Afficher uniquement si on ne vient pas de gsSplashScreen ou gsInitialization
 if not (Game.PreviousState in [gsSplashScreen, gsInitialization, gsMainMenu, gsNewGameMenu]) then
begin
  if GuiButton(RectangleCreate(10, screenHeight - 40, 180, 30), 'Retour') > 0 then
  begin
    Game.CurrentState := Game.PreviousState; // Restaurer l'état précédent
    if (Game.PreviousState in [gsAttackerMoveOrders, gsAttackerMoveExecute, gsAttackerBattleOrders, gsCheckVictoryAttacker]) then
      Game.CurrentPlayer := Game.Attacker
    else
      Game.CurrentPlayer := Game.Defender;
    AddMessage('Retour à l''état : ' + GetStateDisplayText(Game.CurrentState));
  end;
end;
 end;

// Gère la logique de mise à jour pour l'état gsNewGameMenu
procedure HandleNewGameMenuUpdate;
begin
  // Ajouter un message d'état à l'entrée de l'état
  if Game.LastStateMessage <> 'Nouvelle partie : Configurez les options et cliquez sur Commencer' then
    AddMessage('Nouvelle partie : Configurez les options et cliquez sur Commencer');

  // Mettre à jour la musique si elle est en train de jouer
  if Game.MusicPlaying then
    UpdateMusicStream(Game.Music);

  // Vérifier si la touche S est pressée pour arrêter/reprendre la musique
  if IsKeyPressed(KEY_S) then
  begin
    if Game.MusicPlaying then
    begin
      PauseMusicStream(Game.Music);
      Game.MusicPlaying := False;
      AddMessage('Musique mise en pause');
    end
    else
    begin
      ResumeMusicStream(Game.Music);
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

    // Réinitialiser le drapeau de positionnement
    Game.AttackerUnitsPlaced := False;
    Game.DefenderUnitsPlaced := False;

    // Passer au placement des troupes de l'attaquant
    Game.PreviousState := Game.CurrentState;
    Game.CurrentState := gsSetupAttacker;
    AddMessage('Nouvelle partie commencée, passage au placement des attaquants');
  end;
end;

// Gère le rendu pour l'état gsNewGameMenu
procedure HandleNewGameMenuDraw;
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

// Gère la logique de mise à jour pour l'état gsSetupAttacker
procedure HandleSetupAttackerUpdate;
var
  worldPosition: TVector2;
  k: Integer;
begin
  // S'assurer que le joueur actif est l'attaquant
  Game.CurrentPlayer := Game.Attacker;

  // Ajouter un message d'état avant le positionnement
  if not Game.AttackerUnitsPlaced then
  begin
    if (Game.Attacker.PlayerType = ptAI) and (Game.Attacker.SetupType = stManual) then
    begin
      if Game.LastStateMessage <> 'IA-manuel : Cliquez avec le bouton droit pour positionner les unités attaquantes' then
        AddMessage('IA-manuel : Cliquez avec le bouton droit pour positionner les unités attaquantes');
    end
    else
    begin
      if Game.LastStateMessage <> 'Cliquez avec le bouton droit sur la carte pour positionner les unités attaquantes' then
        AddMessage('Cliquez avec le bouton droit sur la carte pour positionner les unités attaquantes');
    end;
  end;

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
        if (Game.Attacker.PlayerType = ptAI) and (Game.Attacker.SetupType = stManual) then
          AddMessage('IA-manuel : Unités attaquantes positionnées')
        else if Game.Attacker.SetupType = stManual then
          AddMessage('Unités attaquantes positionnées. Vous pouvez les déplacer')
        else
          AddMessage('Unités attaquantes positionnées automatiquement. Cliquez sur Suivant pour continuer');
        // Si mode manuel (humain ou IA), attendre l’action de l’utilisateur
        // Sinon, passer à l’état suivant
        if not (Game.Attacker.SetupType = stManual) then
        begin
          Game.CurrentState := gsSetupDefender;
          Game.CurrentPlayer := Game.Defender; // Mettre à jour le joueur actif
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

// Gère le rendu pour l'état gsSetupAttacker
procedure HandleSetupAttackerDraw;
begin
  BeginMode2D(camera);
  DrawTexture(texture, 0, 0, WHITE); // Dessiner l'image à la position (0, 0)
  DrawUnits; // Afficher toutes les unités (y compris celles déjà positionnées)
  DrawUnitSelectionFrame; // Dessiner le cadre jaune autour de l'unité sélectionnée
  EndMode2D();
  affichageBordEcran(); // Dessine les bordures noires
  AffichageEcranGui(Game.CurrentState); // Affiche le GUI
end;

// Gère la logique de mise à jour pour l'état gsSetupDefender
procedure HandleSetupDefenderUpdate;
var
  worldPosition: TVector2;
  k: Integer;
begin
  // Ajouter un message d'état avant le positionnement
  if not Game.DefenderUnitsPlaced then
  begin
    if Game.LastStateMessage <> 'Positionnement automatique des unités défenseurs en cours...' then
      AddMessage('Positionnement automatique des unités défenseurs en cours...');
  end;

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
    Game.Units[67].HexagoneDepart := 96; // Définir l'hexagone de départ
    Game.Units[67].IsLoaded := True; // Bateau chargé au départ
    Game.DefenderUnitsPlaced := True;

    Game.DefenderUnitsPlaced := True;
    AddMessage('Unités défenseurs positionnées automatiquement');
    if (Game.Defender.PlayerType = ptAI) and (Game.Defender.SetupType = stManual) then
      AddMessage('IA-manuel : Unités défenseurs positionnées')
    else if Game.Defender.SetupType = stManual then
      AddMessage('Unités défenseurs positionnées. Vous pouvez les déplacer')
    else
      AddMessage('Unités défenseurs positionnées automatiquement. Cliquez sur Suivant pour continuer');
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

// Gère le rendu pour l'état gsSetupDefender
procedure HandleSetupDefenderDraw;
begin
  BeginMode2D(camera);
  DrawTexture(texture, 0, 0, WHITE); // Dessiner l'image à la position (0, 0)
  DrawUnits; // Afficher toutes les unités (y compris celles déjà positionnées)
  DrawUnitSelectionFrame; // Dessiner le cadre jaune autour de l'unité sélectionnée
  EndMode2D();
  affichageBordEcran(); // Dessine les bordures noires
  AffichageEcranGui(Game.CurrentState); // Affiche le GUI
end;

// Gère la logique de mise à jour pour l'état gsGameOver
procedure HandleGameOverUpdate;
begin
  // Ajouter un message d'état à l'entrée de l'état
  if Game.LastStateMessage <> 'Fin du jeu : Appuyez sur Espace pour retourner au menu' then
    AddMessage('Fin du jeu : Appuyez sur Espace pour retourner au menu');

  // À implémenter : fin du jeu
  if IsKeyPressed(KEY_SPACE) then
  begin
    Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
    Game.CurrentState := gsMainMenu; // Retour au menu principal
    AddMessage('Fin du jeu, retour au menu principal');
  end;
end;

// Gère le rendu pour l'état gsGameOver
procedure HandleGameOverDraw;
begin
  ClearBackground(BLACK);
  DrawText('Fin du jeu', screenWidth div 2 - 50, screenHeight div 2, 20, WHITE);
  DrawText('Appuyez sur Espace pour retourner au menu', screenWidth div 2 - 150, screenHeight div 2 + 30, 20, WHITE);
end;

// Gère le rendu pour les états non implémentés
procedure HandleNotImplementedDraw;
begin
  ClearBackground(BLACK);
  DrawText('Mode désactivé', screenWidth div 2 - 50, screenHeight div 2, 20, WHITE);
end;
// Ajoute un message à l'historique
procedure AddMessage(msg: string);
begin
  // Ajouter le message s'il est différent du dernier message d'état
  // ou s'il s'agit d'un message d'action (contenant "déplacée" ou "sélectionnée")
  // ou s'il s'agit d'un message de changement d'état (contenant "Passage à l’état")
  if (msg <> Game.LastStateMessage) or (Pos('déplacée', msg) > 0) or (Pos('sélectionnée', msg) > 0) or (Pos('Passage à l’état', msg) > 0) then
  begin
    Inc(Game.MessageCount);
    SetLength(Game.Messages, Game.MessageCount);
    Game.Messages[Game.MessageCount - 1] := msg;
    // Mettre à jour LastStateMessage uniquement pour les messages d'état
    if (Pos('déplacée', msg) = 0) and (Pos('sélectionnée', msg) = 0) then
      Game.LastStateMessage := msg;
  end;
end;

// Remplacer la fonction DisplayHexAndUnitsInfo par :
function DisplayHexAndUnitsInfo(hexID: Integer; var yPos: Integer): Integer;
var
  k, j: Integer;
  objText: string;
  unitCount: Integer;
  unitState: string;
  hexgate: string; // Nouvelle variable pour les grilles
begin
  unitCount := 0;

  // Afficher les informations de l'hexagone cliqué
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

    // Afficher l'état du mur
    if Hexagons[hexID].HasWall then
    begin
      if Hexagons[hexID].IsDamaged then
        hexwall := 'Mur : endommagé'
      else
        hexwall := 'Mur : oui';
    end
    else
      hexwall := 'Mur : non';

    // Afficher l'état de la grille
    if Hexagons[hexID].Objet = 3000 then
    begin
      if Hexagons[hexID].IsDamaged then
        hexgate := 'Grille : endommagée'
      else
        hexgate := 'Grille : oui';
    end
    else
      hexgate := 'Grille : non';

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
    hexgate := 'Grille : -';
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
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(hexgate)); // Nouvelle ligne pour les grilles
  yPos := yPos + 20;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(hexriver));
  yPos := yPos + 20;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(hexcastle));
  yPos := yPos + 20;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(hexroad));
  yPos := yPos + 20;

  // Afficher les informations de l'unité sélectionnée
  if Game.SelectedUnitID >= 1 then
  begin
    yPos := yPos + 20; // Espacement
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(Format('Unité %d : %s', [Game.Units[Game.SelectedUnitID].Id, Game.Units[Game.SelectedUnitID].lenom])));
    yPos := yPos + 20;
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(Format('Force : %d', [Game.Units[Game.SelectedUnitID].Force])));
    yPos := yPos + 20;
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(Format('Vitesse : %d', [Game.Units[Game.SelectedUnitID].vitesseInitiale])));
    yPos := yPos + 20;
    if Game.Units[Game.SelectedUnitID].EtatUnite = 1 then
      unitState := 'Entière'
    else
      unitState := '1/2 Force';
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(Format('État : %s', [unitState])));
    yPos := yPos + 20;
    unitCount := unitCount + 1;
  end;

  // Afficher les informations de l'hexagone de destination (si un ordre de mouvement a été donné)
  if (Game.SelectedUnitID >= 1) and (Game.LastDestinationHexID > 0) then
  begin
    yPos := yPos + 20; // Espacement
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), 'Destination:');
    yPos := yPos + 20;
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar('Hexagone ID: ' + IntToStr(Game.LastDestinationHexID)));
    yPos := yPos + 20;
    GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar('Type: ' + Hexagons[Game.LastDestinationHexID].TerrainType));
    yPos := yPos + 20;
    if Hexagons[Game.LastDestinationHexID].IsCastle then
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), 'Château: nimble: Oui')
    else
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), 'Château: Non');
    yPos := yPos + 20;

    // Afficher les unités présentes sur l'hexagone de destination
    for j := 1 to MAX_UNITS do
    begin
      if Game.Units[j].HexagoneActuel = Game.LastDestinationHexID then
      begin
        yPos := yPos + 20; // Espacement
        GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(Format('Unité %d : %s', [Game.Units[j].Id, Game.Units[j].lenom])));
        yPos := yPos + 20;
        GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), PChar(Format('Joueur: %d', [Game.Units[j].numplayer])));
        yPos := yPos + 20;
        unitCount := unitCount + 1;
      end;
    end;
  end;

  // Ajouter un espace après les informations de l'hexagone
  yPos := yPos + 10;

  Result := unitCount; // Retourner le nombre d'unités trouvées
end;
procedure DoNothing;
begin
  // Procédure vide pour désactiver les commandes
end;

// Remplacer la procédure DrawUnits par :
procedure DrawUnits;
var
  unitIndex, i: Integer;
  unitRectangle: TRectangle;
  secondHexID: Integer;
begin
  for unitIndex := 1 to MAX_UNITS do
  begin
    if Game.Units[unitIndex].visible and (Game.Units[unitIndex].HexagoneActuel >= 1) then
    begin
      // Rendu de l'unité avec centrage
      DrawTextureV(Game.Units[unitIndex].latexture,
        Vector2Create(
          Game.Units[unitIndex].PositionActuelle.x - Game.Units[unitIndex].TextureHalfWidth,
          Game.Units[unitIndex].PositionActuelle.y - Game.Units[unitIndex].TextureHalfHeight),
        WHITE);

      // Cadres visuels pour les phases de combat
      if (Game.CurrentState in [gsAttackerBattleOrders, gsDefenderBattleOrders]) and
         (Length(Game.CombatOrders) > 0) then
      begin
        // Cadre pour la cible (orange)
        if Game.Units[unitIndex].Id = Game.CombatOrders[0].TargetID then
        begin
          unitRectangle := RectangleCreate(
            Game.Units[unitIndex].PositionActuelle.x - Game.Units[unitIndex].TextureHalfWidth,
            Game.Units[unitIndex].PositionActuelle.y - Game.Units[unitIndex].TextureHalfHeight,
            Game.Units[unitIndex].latexture.width,
            Game.Units[unitIndex].latexture.height
          );
          DrawRectangleLinesEx(unitRectangle, 2, ORANGE);
        end;

        // Cadres pour les attaquants (jaune)
        for i := 0 to High(Game.CombatOrders[0].AttackerIDs) do
        begin
          if Game.Units[unitIndex].Id = Game.CombatOrders[0].AttackerIDs[i] then
          begin
            unitRectangle := RectangleCreate(
              Game.Units[unitIndex].PositionActuelle.x - Game.Units[unitIndex].TextureHalfWidth,
              Game.Units[unitIndex].PositionActuelle.y - Game.Units[unitIndex].TextureHalfHeight,
              Game.Units[unitIndex].latexture.width,
              Game.Units[unitIndex].latexture.height
            );
            DrawRectangleLinesEx(unitRectangle, 2, YELLOW);

            // Dessiner un cercle orange au centre de l'hexagone cible
            DrawCircle(Hexagons[Game.CombatOrders[0].TargetHexID].CenterX,
                       Hexagons[Game.CombatOrders[0].TargetHexID].CenterY,
                       15, ORANGE);

            // Trouver le second hexagone pour le mur
            secondHexID := FindSecondHexagonForWall(Game.CombatOrders[0].TargetHexID, Game.Units[unitIndex].Id);

            // Dessiner un cercle vert au centre du second hexagone, si valide
            if (secondHexID >= 1) and (secondHexID <= HexagonCount) then
              DrawCircle(Hexagons[secondHexID].CenterX,
                         Hexagons[secondHexID].CenterY,
                         15, GREEN);
          end;
        end;
      end;
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


 procedure InitializeGameManager;
 var
   i: Integer;
 begin
   // Initialiser l'état du jeu
   Game.CurrentState := gsInitialization;
   Game.PreviousState := gsInitialization; // État précédent initial

   // Initialiser le timer du splash screen
   Game.SplashScreenTimer := 0.0;

   // Initialiser les joueurs
   Game.Attacker.PlayerType := ptHuman; // Par défaut
   Game.Attacker.SetupType := stManual; // Par défaut : mode manuel
   Game.Attacker.IsAttacker := True;
   Game.Attacker.Ravitaillement := 0.0; // Pas de ravitaillement pour l'attaquant
   Game.Attacker.BoatCount := 0; // Aucun bateau initial

  Game.Defender.PlayerType := ptHuman; // Par défaut
   Game.Defender.SetupType := stRandom; // Par défaut
   Game.Defender.IsAttacker := False;
   Game.Defender.Ravitaillement := 100.0; // 100 points pour le défenseur
  Game.Defender.BoatCount := 1; // Bateau initial (unité 67)

   // Initialiser les variables des sliders
   Game.AttackerType := 0;  // 0 = Humain
   Game.AttackerSetup := 1; // 1 = Manuel
   Game.DefenderType := 0;  // 0 = Humain
   Game.DefenderSetup := 0; // 0 = Random

   // Initialiser le tour
   Game.CurrentTurn := 0;
   Game.PlayerTurnProcessed := False; // Initialiser le drapeau pour frame
   SetLength(Game.CombatOrders, 0); // Initialiser les ordres de combat

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
   Game.LastStateMessage := '';

   // Initialiser LastYPos
   Game.LastYPos := 0;

   // Initialiser LastClickTime, LastClickedHexID et LastDestinationHexID
   Game.LastClickTime := 0.0;
   Game.LastClickedHexID := -1;
   Game.LastDestinationHexID := -1;

   // Initialiser les nouveaux champs des unités
   for i := 1 to MAX_UNITS do
   begin
     Game.Units[i].CurrentPathIndex := 0;
     Game.Units[i].tourMouvementTermine := False;
   end;

   // Initialiser CurrentUnitIndex
   Game.CurrentUnitIndex := 1;

   // Charger l'image du splash screen
   Game.SplashScreenImage := LoadTexture('resources/image/intromoyenage.png');
   if Game.SplashScreenImage.id = 0 then
   begin
     WriteLn('Erreur : Impossible de charger l''image resources/image/intromoyenage.png');
   end;

   // Initialiser l'audio et charger la musique
   InitAudioDevice();
   Game.Music := LoadMusicStream('resources/music/LAssautdesOmbres.mp3');
   if Game.Music.ctxData = nil then
   begin
     WriteLn('Erreur : Impossible de charger la musique resources/music/LAssautdesOmbres.mp3');
   end;
   Game.MusicPlaying := True; // La musique commence à jouer par défaut
   PlayMusicStream(Game.Music);

   // Charger le style Raygui "Amber"
   GuiLoadStyle(PChar(GetApplicationDirectory + 'gui_styles/style_amber.rgs'));
 end;

 procedure UpdateGameManager;
begin
  // Mettre à jour la musique pour toutes les phases sauf gsInitialization
  if Game.CurrentState <> gsInitialization then
  begin
    if Game.MusicPlaying then
      UpdateMusicStream(Game.Music);
  end;
  case Game.CurrentState of
  gsInitialization: HandleInitializationUpdate;
  gsSplashScreen: HandleSplashScreenUpdate;
  gsMainMenu: HandleMainMenuUpdate;
  gsNewGameMenu: HandleNewGameMenuUpdate;
  gsSetupAttacker: HandleSetupAttackerUpdate;
  gsSetupDefender: HandleSetupDefenderUpdate;
  gsAttackerMoveOrders: HandleAttackerMoveOrdersUpdate;
  gsAttackerMoveExecute: HandleAttackerMoveExecuteUpdate;
  gsAttackerBattleOrders: HandleAttackerBattleOrdersUpdate;
  gsCheckVictoryAttacker: HandleCheckVictoryAttackerUpdate;
  gsDefenderMoveOrders: HandleDefenderMoveOrdersUpdate;
  gsDefenderMoveExecute: HandleDefenderMoveExecuteUpdate;
  gsDefenderBattleOrders: HandleDefenderBattleOrdersUpdate;
  gsCheckVictoryDefender: HandleCheckVictoryDefenderUpdate;
  gsGameOver: HandleGameOverUpdate;
end;
end;

 procedure DrawGameManager;
begin
  case Game.CurrentState of
  gsInitialization: HandleInitializationDraw;
  gsSplashScreen: HandleSplashScreenDraw;
  gsMainMenu: HandleMainMenuDraw;
  gsNewGameMenu: HandleNewGameMenuDraw;
  gsSetupAttacker: HandleSetupAttackerDraw;
  gsSetupDefender: HandleSetupDefenderDraw;
  gsAttackerMoveOrders: HandleAttackerMoveOrdersDraw;
  gsAttackerMoveExecute: HandleGameplayDraw;
  gsAttackerBattleOrders: HandleGameplayDraw;
  gsCheckVictoryAttacker: HandleGameplayDraw;
  gsDefenderMoveOrders: HandleDefenderMoveOrdersDraw;
  gsDefenderMoveExecute: HandleGameplayDraw;
  gsDefenderBattleOrders: HandleGameplayDraw;
  gsCheckVictoryDefender: HandleGameplayDraw;
  gsGameOver: HandleGameOverDraw;
end;
end;

procedure CleanupGameManager;
begin
  // Libérer les ressources
  UnloadTexture(Game.SplashScreenImage);
  if Game.Music.ctxData <> nil then
  begin
    StopMusicStream(Game.Music);
    UnloadMusicStream(Game.Music);
  end;
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
