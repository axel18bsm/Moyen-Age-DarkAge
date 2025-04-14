unit GameManager;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, raylib, raygui, init, TypInfo, UnitProcFunc;

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
function DisplayHexAndUnitsInfo(hexID: Integer; startY: Integer): Integer;
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
procedure DrawGeneralInfo;
procedure DrawHexAndUnitsInfo;
procedure DrawButtons(depart: TGameState);
procedure DrawMessagePanel;
procedure HandleMoveOrders(numplayer: Integer); // Fonction commune
procedure HandleAttackerMoveOrdersUpdate;
procedure HandleAttackerMoveOrdersDraw;
procedure HandleDefenderMoveOrdersUpdate;
procedure HandleDefenderMoveOrdersDraw;
procedure HandleNewTurnUpdate;

implementation


// Nouvelle fonction pour gérer l'état gsNewTurn
procedure HandleNewTurnUpdate;
var
  unitID: Integer;
begin
  // Afficher un message pour indiquer le début du nouveau tour
  AddMessage('Tour ' + IntToStr(Game.CurrentPlayerTurn) + ' - Début du tour');

  // Réinitialiser les variables nécessaires pour toutes les unités
  for unitID := 1 to MAX_UNITS do
  begin
    if (Game.Units[unitID].numplayer = Game.CurrentPlayerTurn) and
       not (Game.Units[unitID].etatUnite = usDead) then
    begin
      // Réinitialiser vitesseActuelle pour toutes les unités vivantes
      Game.Units[unitID].vitesseActuelle := Game.Units[unitID].vitesseInitiale;
      Writeln('Unité ', Game.CurrentPlayerTurn, ' ', IntToStr(unitID), ' - vitesseActuelle réinitialisée à ', Game.Units[unitID].vitesseActuelle);

      // Réinitialiser tourMouvementTermine pour les unités avec HasMoveOrder
      if Game.Units[unitID].HasMoveOrder then
      begin
        Game.Units[unitID].tourMouvementTermine := False;
      end;
    end;
  end;

  // Passer à la phase suivante : gsAttackerMoveOrders
  Game.CurrentState := gsAttackerMoveOrders;
  AddMessage('Tour ' + IntToStr(Game.CurrentPlayerTurn) + ' - Ordres de mouvement (Attaquant)');
end;
 // Mise à jour pour gsAttackerMoveExecute
procedure HandleAttackerMoveExecuteUpdate;
begin
  // Exécuter les ordres de mouvement pour l'attaquant (numplayer = 1)
  ExecuteMoveOrders(1);

  // Appeler les fonctions de déplacement et d'affichage
  MoveCarte2DFleche;
  DragAndDropCarte2D;
  ZoomCarte2D;
  AffichageGuiBas;
end;

// Mise à jour pour gsDefenderMoveExecute
procedure HandleDefenderMoveExecuteUpdate;
begin
  // Exécuter les ordres de mouvement pour le défenseur (numplayer = 2)
  ExecuteMoveOrders(2);

  // Appeler les fonctions de déplacement et d'affichage
  MoveCarte2DFleche;
  DragAndDropCarte2D;
  ZoomCarte2D;
  AffichageGuiBas;
end;

// Dessin pour gsAttackerMoveExecute (identique à HandleAttackerMoveOrdersDraw)
procedure HandleAttackerMoveExecuteDraw;
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
  end;

  EndMode2D();

  // Dessiner les bordures
  affichageBordEcran();

  // Dessiner le GUI
  AffichageEcranGui(Game.CurrentState);
end;

// Dessin pour gsDefenderMoveExecute (identique à HandleDefenderMoveOrdersDraw)
procedure HandleDefenderMoveExecuteDraw;
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
  end;

  EndMode2D();

  // Dessiner les bordures
  affichageBordEcran();

  // Dessiner le GUI
  AffichageEcranGui(Game.CurrentState);
end;

// Fonction commune pour gérer les ordres de mouvement (attaquant ou défenseur)
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
        // Vérifier que l'unité est vivante (etatUnite = usFull ou usDamaged)
        if (Game.Units[i].etatUnite = usFull) or (Game.Units[i].etatUnite = usDamaged) then
        begin
          if unit1 = -1 then
            unit1 := i
          else if unit2 = -1 then
            unit2 := i;
        end;
      end;
    end;

    // Sélectionner une unité selon le type de clic
    if unit1 <> -1 then // Au moins une unité vivante trouvée
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
      // Aucune unité vivante sur cet hexagone, sélectionner l'hexagone
      Game.SelectedUnitID := -1; // Désélectionner toute unité
      Game.LastClickedHexID := clickedHexID; // Stocker l'hexagone cliqué pour l'affichage
      Game.LastDestinationHexID := -1; // Réinitialiser les informations de la destination
    end;
  end;

  // Étape 4 : Gérer l'ordre de mouvement (clic droit)
  if IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) and (Game.SelectedUnitID >= 1) and (clickedHexID > 0) then
  begin
    // Vérifier que l'unité sélectionnée appartient à l'armée spécifiée et est vivante
    if (Game.Units[Game.SelectedUnitID].numplayer = numplayer) and
       ((Game.Units[Game.SelectedUnitID].etatUnite = usFull) or (Game.Units[Game.SelectedUnitID].etatUnite = usDamaged)) then
    begin
      // Réinitialiser l'état de calcul de la trajectoire
      Game.Units[Game.SelectedUnitID].hasTrajectoryCalculated := False;
      // Stocker la destination dans l'unité
      Game.Units[Game.SelectedUnitID].PositionFinale := worldPosition;
      Game.Units[Game.SelectedUnitID].HasMoveOrder := True;

      // Calculer la trajectoire si elle n'a pas encore été calculée
      if not Game.Units[Game.SelectedUnitID].hasTrajectoryCalculated then
      begin
        CalculateTrajectory(Game.SelectedUnitID);
      end;

      // Ajouter un message dans le GUI bas
      AddMessage('L''unité ' + armyText + ' ' + IntToStr(Game.SelectedUnitID) + ' ' + Game.Units[Game.SelectedUnitID].TypeUnite.lenom +
                 ' va à la destination ' + IntToStr(Round(worldPosition.x)) + ', ' + IntToStr(Round(worldPosition.y)) +
                 ' hexagone ' + IntToStr(clickedHexID));

      // Stocker l'hexagone de destination pour l'affichage
      Game.LastDestinationHexID := clickedHexID;
    end;
  end;
end;

// Mise à jour de HandleAttackerMoveOrdersUpdate
procedure HandleAttackerMoveOrdersUpdate;
begin
  // Appeler la fonction commune pour l'attaquant (numplayer = 1)
  HandleMoveOrders(1);

  // Étape 5 : Appeler les fonctions de déplacement et d'affichage
  MoveCarte2DFleche;
  DragAndDropCarte2D;
  ZoomCarte2D;
  AffichageGuiBas;
end;

// Création de HandleDefenderMoveOrdersUpdate
procedure HandleDefenderMoveOrdersUpdate;
begin
  // Appeler la fonction commune pour le défenseur (numplayer = 2)
  HandleMoveOrders(2);

  // Étape 5 : Appeler les fonctions de déplacement et d'affichage
  MoveCarte2DFleche;
  DragAndDropCarte2D;
  ZoomCarte2D;
  AffichageGuiBas;
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
// Affiche les informations générales (titre, tour, joueur, état)
procedure DrawGeneralInfo;
var
  playerText: string;
  stateText: string;
  stateDisplayText: string;
  tourText: string;
begin
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
    gsAttackerMoveOrders: stateDisplayText := 'Ordres de mouvement (Attaquant)';
    gsAttackerMoveExecute: stateDisplayText := 'Exécution des mouvements (Attaquant)';
    gsAttackerBattleOrders: stateDisplayText := 'Ordres de bataille (Attaquant)';
    gsAttackerBattleExecute: stateDisplayText := 'Exécution des batailles (Attaquant)';
    gsDefenderMoveOrders: stateDisplayText := 'Ordres de mouvement (Défenseur)';
    gsDefenderMoveExecute: stateDisplayText := 'Exécution des mouvements (Défenseur)';
    gsDefenderBattleOrders: stateDisplayText := 'Ordres de bataille (Défenseur)';
    gsDefenderBattleExecute: stateDisplayText := 'Exécution des batailles (Défenseur)';
    gsCheckVictory:
      if Game.CurrentPlayer.IsAttacker then
        stateDisplayText := 'Vérification des conditions de victoire (Attaquant)'
      else
        stateDisplayText := 'Vérification des conditions de victoire (Défenseur)';
    gsPlayerturn: stateDisplayText := 'Tour du joueur';
    gsGameOver: stateDisplayText := 'Fin du jeu';
    else stateDisplayText := stateText; // Par défaut, utiliser le nom brut
  end;
  GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, 80, 230, 20), PChar('État : ' + stateDisplayText));
end;

// Affiche les informations de l'hexagone sélectionné et des unités
procedure DrawHexAndUnitsInfo;
var
  yPos: Integer;
  unitCount: Integer;
begin
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

  // Stocker yPos dans une variable globale ou un champ de GameManager si nécessaire
  Game.LastYPos := yPos; // Ajouter un champ LastYPos à TGameManager si besoin
end;

// Affiche les boutons (Suivant, Passer le tour, Menu) et gère la boîte de dialogue
// Affiche les boutons (Suivant, Menu) et gère la boîte de dialogue
procedure DrawButtons(depart: TGameState);
var
  dialogResult: Integer;
  suivantButtonY: Integer;
  playerText: string;
begin
  // Calculer la position Y fixe pour le bouton "Suivant" (30 pixels au-dessus du bouton "Menu")
  suivantButtonY := screenHeight - bottomBorderHeight - 40 - 30;

  // Boutons dans la bordure droite
  case Game.CurrentState of
    gsSetupAttacker:
    begin
      if Game.AttackerUnitsPlaced then
      begin
        if not Game.ShowConfirmDialog then
        begin
          if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
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
            Game.CurrentPlayer := Game.Defender; // Mettre à jour le joueur actif
            // Ajouter le message pour le nouvel état
            if Game.Defender.PlayerType = ptAI then
              playerText := 'IA'
            else
              playerText := 'Humain';
            AddMessage(playerText + ' - Placement des troupes (Défenseur)');
            WriteLn('Message ajouté : ' + playerText + ' - Placement des troupes (Défenseur)'); // Message de débogage
          end
          else if dialogResult = 2 then // Non
          begin
            Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
          end;
        end;
      end;
    end;

    gsSetupDefender:
    begin
      if Game.DefenderUnitsPlaced then
      begin
        if not Game.ShowConfirmDialog then
        begin
          if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
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
            Game.CurrentState := gsAttackerMoveOrders; // Passer à gsAttackerMoveOrders (ordre normal)
            Game.CurrentPlayer := Game.Attacker; // Mettre à jour le joueur actif
            // Ajouter le message pour le nouvel état
            if Game.Attacker.PlayerType = ptAI then
              playerText := 'IA'
            else
              playerText := 'Humain';
            AddMessage(playerText + ' - Ordres de mouvement (Attaquant)');
            WriteLn('Message ajouté : ' + playerText + ' - Ordres de mouvement (Attaquant)'); // Message de débogage
          end
          else if dialogResult = 2 then // Non
          begin
            Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
          end;
        end;
      end;
    end;

    gsAttackerMoveOrders:
    begin
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
        begin
          Game.ShowConfirmDialog := True; // Afficher la boîte de dialogue
        end;
      end
      else
      begin
        // Afficher la boîte de dialogue de confirmation
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin des ordres de mouvement ?', 'Oui;Non');
        if dialogResult = 1 then // Oui
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsAttackerMoveExecute; // Passer à gsAttackerMoveExecute
          Game.CurrentPlayer := Game.Attacker; // S'assurer que le joueur actif est l'attaquant
          // Ajouter le message pour le nouvel état
          if Game.Attacker.PlayerType = ptAI then
            playerText := 'IA'
          else
            playerText := 'Humain';
          AddMessage(playerText + ' - Exécution des mouvements (Attaquant)');
          WriteLn('Message ajouté : ' + playerText + ' - Exécution des mouvements (Attaquant)'); // Message de débogage
        end
        else if dialogResult = 2 then // Non
        begin
          Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
        end;
      end;
    end;

    gsAttackerMoveExecute:
    begin
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
        begin
          Game.ShowConfirmDialog := True; // Afficher la boîte de dialogue
        end;
      end
      else
      begin
        // Afficher la boîte de dialogue de confirmation
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin de l''exécution des mouvements ?', 'Oui;Non');
        if dialogResult = 1 then // Oui
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsAttackerBattleOrders; // Passer à gsAttackerBattleOrders
          Game.CurrentPlayer := Game.Attacker; // S'assurer que le joueur actif est l'attaquant
          // Ajouter le message pour le nouvel état
          if Game.Attacker.PlayerType = ptAI then
            playerText := 'IA'
          else
            playerText := 'Humain';
          AddMessage(playerText + ' - Ordres de bataille (Attaquant)');
          WriteLn('Message ajouté : ' + playerText + ' - Ordres de bataille (Attaquant)'); // Message de débogage
        end
        else if dialogResult = 2 then // Non
        begin
          Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
        end;
      end;
    end;

    gsAttackerBattleOrders:
    begin
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
        begin
          Game.ShowConfirmDialog := True; // Afficher la boîte de dialogue
        end;
      end
      else
      begin
        // Afficher la boîte de dialogue de confirmation
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin des ordres de bataille ?', 'Oui;Non');
        if dialogResult = 1 then // Oui
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsAttackerBattleExecute; // Passer à gsAttackerBattleExecute
          Game.CurrentPlayer := Game.Attacker; // S'assurer que le joueur actif est l'attaquant
          // Ajouter le message pour le nouvel état
          if Game.Attacker.PlayerType = ptAI then
            playerText := 'IA'
          else
            playerText := 'Humain';
          AddMessage(playerText + ' - Exécution des batailles (Attaquant)');
          WriteLn('Message ajouté : ' + playerText + ' - Exécution des batailles (Attaquant)'); // Message de débogage
        end
        else if dialogResult = 2 then // Non
        begin
          Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
        end;
      end;
    end;

    gsAttackerBattleExecute:
    begin
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
        begin
          Game.ShowConfirmDialog := True; // Afficher la boîte de dialogue
        end;
      end
      else
      begin
        // Afficher la boîte de dialogue de confirmation
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin de l''exécution des batailles ?', 'Oui;Non');
        if dialogResult = 1 then // Oui
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsCheckVictory; // Passer à gsCheckVictory
          Game.CurrentPlayer := Game.Attacker; // S'assurer que le joueur actif est l'attaquant
          AddMessage('Vérification des conditions de zealotement (Attaquant)');
          WriteLn('Message ajouté : Vérification des conditions de victoire (Attaquant)'); // Message de débogage
        end
        else if dialogResult = 2 then // Non
        begin
          Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
        end;
      end;
    end;

    gsCheckVictory:
    begin
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
        begin
          Game.ShowConfirmDialog := True; // Afficher la boîte de dialogue
        end;
      end
      else
      begin
        // Afficher la boîte de dialogue de confirmation
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin de la vérification ?', 'Oui;Non');
        if dialogResult = 1 then // Oui
        begin
          Game.ShowConfirmDialog := False;
          // Déterminer l'état suivant en fonction du joueur actif
          if Game.CurrentPlayer.IsAttacker then
          begin
            Game.CurrentState := gsDefenderMoveOrders; // Passer à gsDefenderMoveOrders
            Game.CurrentPlayer := Game.Defender; // Mettre à jour le joueur actif
            // Ajouter le message pour le nouvel état
            if Game.Defender.PlayerType = ptAI then
              playerText := 'IA'
            else
              playerText := 'Humain';
            AddMessage(playerText + ' - Ordres de mouvement (Défenseur)');
            WriteLn('Message ajouté : ' + playerText + ' - Ordres de mouvement (Défenseur)'); // Message de débogage
          end
          else
          begin
            // Après le tour du défenseur, passer au tour suivant
            Inc(Game.CurrentTurn);
            Game.CurrentState := gsAttackerMoveOrders; // Revenir à gsAttackerMoveOrders
            Game.CurrentPlayer := Game.Attacker; // Mettre à jour le joueur actif
            // Ajouter le message pour le nouvel état
            if Game.Attacker.PlayerType = ptAI then
              playerText := 'IA'
            else
              playerText := 'Humain';
            AddMessage(playerText + ' - Ordres de mouvement (Attaquant, tour ' + IntToStr(Game.CurrentTurn) + ')');
            WriteLn('Message ajouté : ' + playerText + ' - Ordres de mouvement (Attaquant, tour ' + IntToStr(Game.CurrentTurn) + ')'); // Message de débogage
          end;
        end
        else if dialogResult = 2 then // Non
        begin
          Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
        end;
      end;
    end;

    gsDefenderMoveOrders:
    begin
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
        begin
          Game.ShowConfirmDialog := True; // Afficher la boîte de dialogue
        end;
      end
      else
      begin
        // Afficher la boîte de dialogue de confirmation
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin des ordres de mouvement ?', 'Oui;Non');
        if dialogResult = 1 then // Oui
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsDefenderMoveExecute; // Passer à gsDefenderMoveExecute
          Game.CurrentPlayer := Game.Defender; // S'assurer que le joueur actif est le défenseur
          // Ajouter le message pour le nouvel état
          if Game.Defender.PlayerType = ptAI then
            playerText := 'IA'
          else
            playerText := 'Humain';
          AddMessage(playerText + ' - Exécution des mouvements (Défenseur)');
          WriteLn('Message ajouté : ' + playerText + ' - Exécution des mouvements (Défenseur)'); // Message de débogage
        end
        else if dialogResult = 2 then // Non
        begin
          Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
        end;
      end;
    end;

    gsDefenderMoveExecute:
    begin
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
        begin
          Game.ShowConfirmDialog := True; // Afficher la boîte de dialogue
        end;
      end
      else
      begin
        // Afficher la boîte de dialogue de confirmation
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin de l''exécution des mouvements ?', 'Oui;Non');
        if dialogResult = 1 then // Oui
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsDefenderBattleOrders; // Passer à gsDefenderBattleOrders
          Game.CurrentPlayer := Game.Defender; // S'assurer que le joueur actif est le défenseur
          // Ajouter le message pour le nouvel état
          if Game.Defender.PlayerType = ptAI then
            playerText := 'IA'
          else
            playerText := 'Humain';
          AddMessage(playerText + ' - Ordres de bataille (Défenseur)');
          WriteLn('Message ajouté : ' + playerText + ' - Ordres de bataille (Défenseur)'); // Message de débogage
        end
        else if dialogResult = 2 then // Non
        begin
          Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
        end;
      end;
    end;

    gsDefenderBattleOrders:
    begin
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
        begin
          Game.ShowConfirmDialog := True; // Afficher la boîte de dialogue
        end;
      end
      else
      begin
        // Afficher la boîte de dialogue de confirmation
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin des ordres de bataille ?', 'Oui;Non');
        if dialogResult = 1 then // Oui
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsDefenderBattleExecute; // Passer à gsDefenderBattleExecute
          Game.CurrentPlayer := Game.Defender; // S'assurer que le joueur actif est le défenseur
          // Ajouter le message pour le nouvel état
          if Game.Defender.PlayerType = ptAI then
            playerText := 'IA'
          else
            playerText := 'Humain';
          AddMessage(playerText + ' - Exécution des batailles (Défenseur)');
          WriteLn('Message ajouté : ' + playerText + ' - Exécution des batailles (Défenseur)'); // Message de débogage
        end
        else if dialogResult = 2 then // Non
        begin
          Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
        end;
      end;
    end;

    gsDefenderBattleExecute:
    begin
      if not Game.ShowConfirmDialog then
      begin
        if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, suivantButtonY, 230, 30), 'Suivant') = 1 then
        begin
          Game.ShowConfirmDialog := True; // Afficher la boîte de dialogue
        end;
      end
      else
      begin
        // Afficher la boîte de dialogue de confirmation
        dialogResult := GuiMessageBox(RectangleCreate(screenWidth div 2 - 150, screenHeight div 2 - 75, 300, 150), 'Confirmation', 'Confirmez-vous la fin de l''exécution des batailles ?', 'Oui;Non');
        if dialogResult = 1 then // Oui
        begin
          Game.ShowConfirmDialog := False;
          Game.CurrentState := gsCheckVictory; // Passer à gsCheckVictory
          Game.CurrentPlayer := Game.Defender; // S'assurer que le joueur actif est le défenseur
          AddMessage('Vérification des conditions de victoire (Défenseur)');
          WriteLn('Message ajouté : Vérification des conditions de victoire (Défenseur)'); // Message de débogage
        end
        else if dialogResult = 2 then // Non
        begin
          Game.ShowConfirmDialog := False; // Fermer la boîte de dialogue
        end;
      end;
    end;

    gsGameOver:
    begin
      // Pas de bouton "Suivant" pour cet état
    end;
  end;

  // Bouton "Menu" en bas à droite
  if GuiButton(RectangleCreate(screenWidth - rightBorderWidth + 10, screenHeight - bottomBorderHeight - 40, 230, 30), 'Menu') <> 0 then
  begin
    Game.PreviousState := Game.CurrentState; // Sauvegarder l'état actuel
    Game.CurrentState := gsMainMenu; // Passer à l'état du menu général
    AddMessage('Menu principal : Sélectionnez une option');
    WriteLn('Message ajouté : Menu principal : Sélectionnez une option'); // Message de débogage
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
begin
  DrawMouseCoordinates; // Afficher les coordonnées de la souris
  DrawGeneralInfo; // Afficher les informations générales (titre, tour, joueur, état)
  DrawHexAndUnitsInfo; // Afficher les informations de l'hexagone et des unités
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
begin
  // Ajouter un message d'état à l'entrée de l'état
  if Game.LastStateMessage <> 'Menu principal : Sélectionnez une option' then
    AddMessage('Menu principal : Sélectionnez une option');

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
  end;

  EndMode2D();

  // Dessiner les bordures
  affichageBordEcran();

  // Dessiner le GUI (bas et droit)
  AffichageEcranGui(Game.CurrentState);
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
    if Game.Units[Game.SelectedUnitID].EtatUnite = usFull then
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
      GuiLabel(RectangleCreate(screenWidth - rightBorderWidth + 10, yPos, 230, 20), 'Château: Oui')
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
      if Game.Units[j].etatUnite = usDead then
        DrawTexture(Game.Units[j].deathImage, Round(drawPos.x), Round(drawPos.y), WHITE)
      else
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
    UnloadTexture(Game.Units[i].deathImage); // Libérer l'image de décès
    UnloadImage(Game.Units[i].limage);
    // Le tableau trajet est automatiquement libéré par Free Pascal (types simples)
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
  Game.LastStateMessage := '';

  // Initialiser LastYPos
  Game.LastYPos := 0;

  // Initialiser LastClickTime, LastClickedHexID et LastDestinationHexID
  Game.LastClickTime := 0.0;
  Game.LastClickedHexID := -1;
  Game.LastDestinationHexID := -1;

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
    gsInitialization: HandleInitializationUpdate;
    gsSplashScreen: HandleSplashScreenUpdate;
    gsMainMenu: HandleMainMenuUpdate;
    gsNewGameMenu: HandleNewGameMenuUpdate;
    gsSetupAttacker: HandleSetupAttackerUpdate;
    gsSetupDefender: HandleSetupDefenderUpdate;
    gsAttackerMoveOrders: HandleAttackerMoveOrdersUpdate;
    gsDefenderMoveOrders: HandleDefenderMoveOrdersUpdate;
    gsAttackerMoveExecute: HandleAttackerMoveExecuteUpdate;
    gsDefenderMoveExecute: HandleDefenderMoveExecuteUpdate;
    gsAttackerBattleOrders,
    gsAttackerBattleExecute,
    gsDefenderBattleOrders,
    gsDefenderBattleExecute,
    gsCheckVictory,
    gsPlayerturn: DoNothing; // États non implémentés
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
    gsDefenderMoveOrders: HandleDefenderMoveOrdersDraw;
    gsAttackerMoveExecute: HandleAttackerMoveExecuteDraw;
    gsDefenderMoveExecute: HandleDefenderMoveExecuteDraw;
    gsAttackerBattleOrders,
    gsAttackerBattleExecute,
    gsDefenderBattleOrders,
    gsDefenderBattleExecute,
    gsCheckVictory,
    gsPlayerturn: HandleNotImplementedDraw; // États non implémentés
    gsGameOver: HandleGameOverDraw;
  end;
end;

 procedure CleanupGameManager;
 begin
   // Libérer les ressources des unités
   CleanupUnits;

   // Libérer les autres ressources
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
