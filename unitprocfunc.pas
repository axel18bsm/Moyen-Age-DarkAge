unit UnitProcFunc;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,raylib, init,math;
procedure MoveCarte2DFleche;
procedure AffichageGuiBas;
procedure DragAndDropCarte2D;
procedure ZoomCarte2D;
function GetHexagonAtPosition(x, y: Single): Integer;
procedure UpdateUnitBtnPerim(unitID: Integer);
procedure CenterUnitOnHexagon(unitID, hexID: Integer);
function CenterUnitOnPositionActuelle(unitID: Integer): TVector2;
procedure FloodFillCastle(hexID: Integer);
procedure DetectWalls;
procedure MarkCastleHexagons;
procedure DetectRiverPairsAndSave;
procedure PositionAttackerUnitsAroundHex(hexID: Integer);
function SelectUnit(mouseX, mouseY: Single; playerNum: Integer): Integer;
procedure DrawUnitSelectionFrame;
procedure CalculateBresenhamPath(unitID, startHex, endHex: Integer);
function GetStateDisplayText(state: TGameState): string;
procedure AddBoat(playerNum: Integer; tour: Integer);
procedure HandleRavitaillement;
procedure OrderBoatReturn;





implementation
uses GameManager;
procedure AddBoat(playerNum: Integer; tour: Integer);
var
  hexID, unitID: Integer;
  hexCandidates: array[0..1] of Integer;
  freeHex: Integer;
  unitIndex, hexIndex, checkIndex: Integer;
begin
  if (playerNum = 2) and (tour >= 1) and (Game.Defender.BoatCount < 2) then
  begin
    // Défenseur : hexagones 96 ou 192
    hexCandidates[0] := 96;
    hexCandidates[1] := 192;
    unitID := -1;
    // Chercher une unité bateau disponible (68 si 67 est déjà placé)
    if Game.Units[68].HexagoneActuel = -1 then
      unitID := 68;
    if unitID = -1 then
    begin
      AddMessage('Échec ajout bateau défenseur : aucune unité disponible');
      Exit; // Pas d'unité disponible, attendre
    end;
  end
  else if (playerNum = 1) and (tour >= 3) and (Game.Attacker.BoatCount < 3) then
  begin
    // Attaquant : hexagones 319 ou 320
    hexCandidates[0] := 319;
    hexCandidates[1] := 320;
    unitID := -1;
    // Chercher une unité bateau disponible (38, 39, 40)
    for unitIndex := 38 to 40 do
    begin
      if Game.Units[unitIndex].HexagoneActuel = -1 then
      begin
        unitID := unitIndex;
        Break;
      end;
    end;
    if unitID = -1 then
    begin
      AddMessage('Échec ajout bateau attaquant : aucune unité disponible');
      Exit; // Pas d'unité disponible, attendre
    end;
  end
  else
  begin
    AddMessage('Échec ajout bateau : conditions non remplies (playerNum=' + IntToStr(playerNum) + ', tour=' + IntToStr(tour) + ')');
    Exit; // Conditions non remplies
  end;

  // Vérifier les hexagones candidats
  freeHex := -1;
  for hexIndex := 0 to 1 do
  begin
    hexID := hexCandidates[hexIndex];
    if (hexID >= 1) and (hexID <= HexagonCount) and (Hexagons[hexID].TerrainType = 'mer') then
    begin
      // Vérifier si l'hexagone est libre
      Game.IsOccupied := False;
      for checkIndex := 1 to MAX_UNITS do
      begin
        if Game.Units[checkIndex].HexagoneActuel = hexID then
        begin
          Game.IsOccupied := True;
          Break;
        end;
      end;
      if not Game.IsOccupied then
      begin
        freeHex := hexID;
        Break;
      end;
    end;
  end;

  // Si aucun hexagone libre, choisir aléatoirement
  if freeHex = -1 then
  begin
    freeHex := hexCandidates[Random(2)];
    AddMessage('Aucun hexagone libre, tentative aléatoire sur ' + IntToStr(freeHex));
  end;

  if freeHex >= 1 then
  begin
    CenterUnitOnHexagon(unitID, freeHex);
    if playerNum = 2 then
    begin
      Game.Units[unitID].HexagoneDepart := freeHex; // Définir l'hexagone de départ
      Game.Units[unitID].IsLoaded := True; // Bateau chargé
      Inc(Game.Defender.BoatCount);
      AddMessage('Nouveau bateau défenseur (unité ' + IntToStr(unitID) + ') arrivé sur hexagone ' + IntToStr(freeHex));
    end
    else
    begin
      Inc(Game.Attacker.BoatCount);
      AddMessage('Nouveau bateau attaquant (unité ' + IntToStr(unitID) + ') arrivé sur hexagone ' + IntToStr(freeHex));
    end;
  end
  else
    AddMessage('Échec ajout bateau : aucun hexagone valide');
end;

procedure HandleRavitaillement;
var
  i, j: Integer;
  consumption, ravitaillementContribution: Single;
  stock: Single;
  unitID: Integer;
  deliveryHexes: array[0..2] of Integer;
  isBlocked: Boolean;
begin
  consumption := 0.0;
  ravitaillementContribution := 0.0;
  stock := Game.Defender.Ravitaillement;
  deliveryHexes[0] := 217;
  deliveryHexes[1] := 250;
  deliveryHexes[2] := 282;

  // Vérifier les blocages par les bateaux attaquants
  for i := 0 to 2 do
  begin
    isBlocked := False;
    for j := 38 to 40 do
    begin
      if Game.Units[j].HexagoneActuel = deliveryHexes[i] then
      begin
        isBlocked := True;
        Break;
      end;
    end;
    if isBlocked then
      AddMessage('Livraison bloquée sur hexagone ' + IntToStr(deliveryHexes[i]) + ' par un bateau attaquant');
  end;

  // Calculer la contribution des bateaux (unités 67 et 68)
  for i := 67 to 68 do
  begin
    if ((Game.Units[i].HexagoneActuel = 217) or
        (Game.Units[i].HexagoneActuel = 250) or
        (Game.Units[i].HexagoneActuel = 282)) and
       Game.Units[i].IsLoaded then
    begin
      if Game.Units[i].EtatUnite = 1 then
      begin
        ravitaillementContribution := ravitaillementContribution + 40.0;
        AddMessage('Bateau ' + IntToStr(i) + ' a livré + 40 points sur hexagone ' + IntToStr(Game.Units[i].HexagoneActuel));
      end
      else
      begin
        ravitaillementContribution := ravitaillementContribution + 20.0;
        AddMessage('Bateau ' + IntToStr(i) + ' a livré +20 points sur hexagone ' + IntToStr(Game.Units[i].HexagoneActuel));
      end;
      Game.Units[i].IsLoaded := False; // Décharger le bateau
      AddMessage('Bateau ' + IntToStr(i) + ' doit retourner à hexagone ' + IntToStr(Game.Units[i].HexagoneDepart) + ' pour recharger');
    end;
  end;

  // Calculer la consommation totale
  for i := 41 to 68 do
  begin
    if Game.Units[i].HexagoneActuel >= 1 then
    begin
      if Game.Units[i].EtatUnite = 1 then
        consumption := consumption + 1.0
      else
        consumption := consumption + 0.5;
    end;
  end;

  // Mettre à jour le stock
  stock := stock + ravitaillementContribution;
  stock := stock - consumption;
  AddMessage(Format('Bateaux défenseurs : +%.1f points, consommé %.1f points, stock restant : %.1f', [ravitaillementContribution, consumption, stock]));

  // Appliquer les pénalités si nécessaire
  if stock < 0 then
  begin
    stock := -stock; // Quantité manquante
    for unitID := 41 to 68 do
    begin
      if Game.Units[unitID].HexagoneActuel >= 1 then
      begin
        if Game.Units[unitID].EtatUnite = 1 then
        begin
          if stock >= 1.0 then
          begin
            stock := stock - 1.0;
            Game.Units[unitID].EtatUnite := 0;
            Game.Units[unitID].Force := Game.Units[unitID].TypeUnite.forceDem;
            UnloadTexture(Game.Units[unitID].latexture);
            Game.Units[unitID].limage := LoadImage(Game.Units[unitID].FileimageAbime);
            Game.Units[unitID].latexture := LoadTextureFromImage(Game.Units[unitID].limage);
            UpdateUnitBtnPerim(unitID);
            AddMessage('Unité ' + IntToStr(unitID) + ' (' + Game.Units[unitID].TypeUnite.lenom + ') abîmée');
          end;
        end
        else
        begin
          if stock >= 0.5 then
          begin
            stock := stock - 0.5;
            Game.Units[unitID].HexagoneActuel := -1;
            Game.Units[unitID].visible := False;
            if (unitID = 67) or (unitID = 68) then
            begin
              Dec(Game.Defender.BoatCount);
              AddMessage('Bateau ' + IntToStr(unitID) + ' coulé, nouveau bateau arrivera au tour suivant');
            end
            else
              AddMessage('Unité ' + IntToStr(unitID) + ' (' + Game.Units[unitID].TypeUnite.lenom + ') éliminée');
          end;
        end;
      end;
    end;
  end;

  Game.Defender.Ravitaillement := stock;
end;

procedure OrderBoatReturn;
var
  i, targetHex: Integer;
  deliveryHexes: array[0..2] of Integer;
  j,k: Integer;
  isBlocked: Boolean;
begin
  // Seulement pour IA ou mode automatique
  if (Game.Defender.PlayerType = ptAI) or (Game.Defender.SetupType = stRandom) then
  begin
    deliveryHexes[0] := 217;
    deliveryHexes[1] := 250;
    deliveryHexes[2] := 282;

    for i := 67 to 68 do
    begin
      if Game.Units[i].HexagoneActuel >= 1 then
      begin
        if Game.Units[i].IsLoaded then
        begin
          // Bateau chargé, chercher un hexagone de livraison libre
          targetHex := -1;
          for j := 0 to 2 do
          begin
            isBlocked := False;
            for k := 38 to 40 do
            begin
              if Game.Units[k].HexagoneActuel = deliveryHexes[j] then
              begin
                isBlocked := True;
                Break;
              end;
            end;
            if not isBlocked then
            begin
              targetHex := deliveryHexes[j];
              Break;
            end;
          end;
          if targetHex = -1 then
            Continue; // Tous les hexagones bloqués, attendre
        end
        else
        begin
          // Bateau déchargé, retourner à l'hexagone de départ
          targetHex := Game.Units[i].HexagoneDepart;
        end;

        // Donner un ordre de mouvement
        if (targetHex >= 1) and (Game.Units[i].HexagoneActuel <> targetHex) then
        begin
          Game.Units[i].PositionFinale := Vector2Create(Hexagons[targetHex].CenterX, Hexagons[targetHex].CenterY);
          Game.Units[i].HasMoveOrder := True;
          Game.Units[i].HexagoneCible := targetHex;
          CalculateBresenhamPath(i, Game.Units[i].HexagoneActuel, targetHex);
          Game.Units[i].CurrentPathIndex := 0;
          Game.Units[i].tourMouvementTermine := False;
          Game.Units[i].hasStopped := False;
          AddMessage('Bateau ' + IntToStr(i) + ' se dirige vers hexagone ' + IntToStr(targetHex));
        end;
      end;
    end;
  end;
end;

function GetStateDisplayText(state: TGameState): string;
begin
  case state of
    gsInitialization: Result := 'Initialisation';
    gsSplashScreen: Result := 'Écran de démarrage';
    gsMainMenu: Result := 'Menu principal';
    gsNewGameMenu: Result := 'Nouvelle partie';
    gsSetupAttacker: Result := 'Placement des troupes (Attaquant)';
    gsSetupDefender: Result := 'Placement des troupes (Défenseur)';
    gsAttackerMoveOrders: Result := 'Ordres de mouvement (Attaquant)';
    gsAttackerMoveExecute: Result := 'Exécution des mouvements (Attaquant)';
    gsAttackerBattleOrders: Result := 'Ordres de combat (Attaquant)';
    gsAttackerBattleExecute: Result := 'Exécution des combats (Attaquant)';
    gsCheckVictoryAttacker: Result := 'Vérification victoire (Attaquant)';
    gsDefenderMoveOrders: Result := 'Ordres de mouvement (Défenseur)';
    gsDefenderMoveExecute: Result := 'Exécution des mouvements (Défenseur)';
    gsDefenderBattleOrders: Result := 'Ordres de combat (Défenseur)';
    gsDefenderBattleExecute: Result := 'Exécution des combats (Défenseur)';
    gsCheckVictoryDefender: Result := 'Vérification victoire (Défenseur)';
    gsplayerturn: Result := 'Tour du joueur';
    gsGameOver: Result := 'Fin du jeu';
    else Result := 'État inconnu';
  end;
end;
procedure CalculateBresenhamPath(unitID, startHex, endHex: Integer);
var
  x0, y0, x1, y1: Integer;
  dx, dy, sx, sy, err, e2: Integer;
  x, y: Single;
  pointCount: Integer;
  hexNet: Integer;
  i, j, neighborID, modulo: Integer;
  prevHexNet, lastHexBrut: Integer;
begin
  // Réinitialiser le chemin
  SetLength(Game.Units[unitID].chemin, 0);
  pointCount := 0;

  // Coordonnées des centres des hexagones
  x0 := Hexagons[startHex].CenterX;
  y0 := Hexagons[startHex].CenterY;
  x1 := Hexagons[endHex].CenterX;
  y1 := Hexagons[endHex].CenterY;

  // Algorithme de Bresenham (première passe : vecteurs et Hexnet)
  dx := Abs(x1 - x0);
  dy := Abs(y1 - y0);
  sx := IfThen(x0 < x1, 1, -1);
  sy := IfThen(y0 < y1, 1, -1);
  err := dx - dy;

  x := x0;
  y := y0;

  while True do
  begin
    // Calculer Hexnet
    hexNet := GetHexagonAtPosition(x, y);

    // Stocker le point
    SetLength(Game.Units[unitID].chemin, pointCount + 1);
    Game.Units[unitID].chemin[pointCount].chemin := Vector2Create(x, y);
    Game.Units[unitID].chemin[pointCount].Hexnet := hexNet;
    Game.Units[unitID].chemin[pointCount].Hexbrut := 0; // Valeur temporaire
    pointCount := pointCount + 1;

    // Vérifier si on a atteint la destination
    if (x0 = x1) and (y0 = y1) then
      Break;

    // Mise à jour de Bresenham
    e2 := 2 * err;
    if e2 > -dy then
    begin
      err := err - dy;
      x0 := x0 + sx;
    end;
    if e2 < dx then
    begin
      err := err + dx;
      y0 := y0 + sy;
    end;
    x := x0;
    y := y0;
  end;

  // Seconde passe : calculer Hexbrut
  prevHexNet := -1;
  lastHexBrut := -1;
  for i := 0 to pointCount - 1 do
  begin
    hexNet := Game.Units[unitID].chemin[i].Hexnet;
    if (i = 0) or (hexNet <> prevHexNet) then
    begin
      // Nouveau Hexnet ou premier point : calculer Hexbrut
      lastHexBrut := hexNet; // Par défaut
      if prevHexNet > 0 then
      begin
        // Vérifier les voisins de prevHexNet
        for j := 1 to 6 do
        begin
          case j of
            1: neighborID := Hexagons[prevHexNet].Neighbor1;
            2: neighborID := Hexagons[prevHexNet].Neighbor2;
            3: neighborID := Hexagons[prevHexNet].Neighbor3;
            4: neighborID := Hexagons[prevHexNet].Neighbor4;
            5: neighborID := Hexagons[prevHexNet].Neighbor5;
            6: neighborID := Hexagons[prevHexNet].Neighbor6;
          end;
          if neighborID > 0 then
          begin
            modulo := neighborID mod 1000;
            if modulo = hexNet then
            begin
              lastHexBrut := neighborID;
              Break; // Prendre le premier trouvé
            end;
          end;
        end;
      end;
    end;
    // Stocker lastHexBrut pour ce point
    Game.Units[unitID].chemin[i].Hexbrut := lastHexBrut;
    prevHexNet := hexNet;
  end;

  // Afficher pour vérification
  for i := 0 to pointCount - 1 do
  begin
    WriteLn('Vecteur x: ', Game.Units[unitID].chemin[i].chemin.x:0:2,
            ', y: ', Game.Units[unitID].chemin[i].chemin.y:0:2,
            ' - Hexagone brut: ', Game.Units[unitID].chemin[i].Hexbrut,
            ' - Hexagone net: ', Game.Units[unitID].chemin[i].Hexnet);
  end;
end;

function SelectUnit(mouseX, mouseY: Single; playerNum: Integer): Integer;
var
  i: Integer;
  worldPos: TVector2;
  mouseRect: TRectangle;
begin
  Result := -1; // Par défaut, aucune unité sélectionnée

  // Convertir les coordonnées de la souris en coordonnées du monde
  worldPos := GetScreenToWorld2D(Vector2Create(mouseX, mouseY), camera);

  // Créer un petit rectangle autour de la position de la souris pour la détection
  mouseRect := RectangleCreate(worldPos.x - 2, worldPos.y - 2, 4, 4);

  // Parcourir toutes les unités pour vérifier si le clic est sur une unité
  for i := 1 to MAX_UNITS do
  begin
    if Game.Units[i].HexagoneActuel >= 0 then // Unité positionnée
    begin
      // Vérifier si l'unité appartient au joueur (playerNum)
      if Game.Units[i].numplayer = playerNum then
      begin
        // Vérifier si le clic est dans la zone de l'unité (BtnPerim)
        if CheckCollisionRecs(mouseRect, Game.Units[i].BtnPerim) then
        begin
          Result := i; // Retourner l'ID de l'unité sélectionnée
          Break;
        end;
      end;
    end;
  end;
end;

procedure DrawUnitSelectionFrame;
begin
  if Game.SelectedUnitID >= 1 then
  begin
    // Dessiner un cadre jaune autour de l'unité sélectionnée
    DrawRectangleLines(
      Round(Game.Units[Game.SelectedUnitID].BtnPerim.x),
      Round(Game.Units[Game.SelectedUnitID].BtnPerim.y),
      Round(Game.Units[Game.SelectedUnitID].BtnPerim.width),
      Round(Game.Units[Game.SelectedUnitID].BtnPerim.height),
      YELLOW
    );
  end;
end;
procedure PositionAttackerUnitsAroundHex(hexID: Integer);
var
  i, j, k, unitIndex: Integer;
  queue: array of Integer; // File pour la recherche en largeur
  queueStart, queueEnd: Integer; // Indices pour la file
  visited: array of Boolean; // Pour marquer les hexagones visités
  validHexes: array of Integer; // Liste des hexagones valides pour placer les unités
  occupiedHexes: array of Integer; // Liste des hexagones occupés
  unitPlaced: Boolean;
  neighborID: Integer;
begin
  // Vérifier si l'ID de l'hexagone est valide
  if (hexID < 1) or (hexID > HexagonCount) then
  begin
    WriteLn('Erreur : ID d''hexagone invalide dans PositionAttackerUnitsAroundHex');
    Exit;
  end;

  // Initialiser la file pour la recherche en largeur
  SetLength(queue, HexagonCount);
  queueStart := 0;
  queueEnd := 0;
  queue[queueEnd] := hexID;
  Inc(queueEnd);

  // Initialiser le tableau des hexagones visités
  SetLength(visited, HexagonCount + 1);
  for i := 0 to HexagonCount do
    visited[i] := False;
  visited[hexID] := True;

  // Initialiser la liste des hexagones valides
  SetLength(validHexes, 0);

  // Recherche en largeur pour trouver tous les hexagones valides
  while queueStart < queueEnd do
  begin
    // Récupérer l'hexagone courant
    i := queue[queueStart];
    Inc(queueStart);

    // Vérifier si cet hexagone est valide (pas de forêt, mer, ou château)
    if (Hexagons[i].TerrainType <> 'foret') and
       (Hexagons[i].TerrainType <> 'mer') and
       (not Hexagons[i].IsCastle) then
    begin
      SetLength(validHexes, Length(validHexes) + 1);
      validHexes[High(validHexes)] := i;
    end;

    // Ajouter les voisins non visités à la file
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

      // Vérifier si le voisin est valide et non visité
      if (neighborID > 0) and (neighborID <= HexagonCount) and not visited[neighborID] then
      begin
        visited[neighborID] := True;
        queue[queueEnd] := neighborID;
        Inc(queueEnd);
      end;
    end;
  end;

  // Créer une liste des hexagones déjà occupés
  SetLength(occupiedHexes, 0);
  for j := 1 to MAX_UNITS do
  begin
    if Game.Units[j].HexagoneActuel > 0 then
    begin
      SetLength(occupiedHexes, Length(occupiedHexes) + 1);
      occupiedHexes[High(occupiedHexes)] := Game.Units[j].HexagoneActuel;
    end;
  end;

  // Positionner les unités attaquantes (sauf les bateaux)
  unitIndex := 0;
  for i := 1 to MAX_UNITS do
  begin
    if (Game.Units[i].numplayer = 1) and (Game.Units[i].HexagoneActuel = -1) then // Unité attaquante non positionnée
    begin
      // Exclure les bateaux (type "bateau")
      if Game.Units[i].TypeUnite.lenom = 'bateau' then
        Continue; // Passer à l'unité suivante

      // Vérifier si c'est un Lieutenant ou un Duc
      Game.IsSpecialUnit := (Game.Units[i].TypeUnite.lenom = 'lieutenant') or (Game.Units[i].TypeUnite.lenom = 'duc');

      unitPlaced := False;
      while (unitIndex < Length(validHexes)) and not unitPlaced do
      begin
        // Vérifier si l'hexagone est occupé
        Game.IsOccupied := False;
        Game.HexOccupiedByAttacker := False;
        for k := 1 to MAX_UNITS do
        begin
          if Game.Units[k].HexagoneActuel = validHexes[unitIndex] then
          begin
            Game.IsOccupied := True;
            if Game.Units[k].numplayer = 1 then // Occupé par une unité attaquante
              Game.HexOccupiedByAttacker := True;
            Break;
          end;
        end;

        // Autoriser l'empilement uniquement pour le Lieutenant ou le Duc si l'hexagone est occupé par une unité attaquante
        if (not Game.IsOccupied) or (Game.IsSpecialUnit and Game.HexOccupiedByAttacker) then
        begin
          // Positionner l'unité sur cet hexagone
          CenterUnitOnHexagon(i, validHexes[unitIndex]);
          if not Game.IsSpecialUnit then
          begin
            // Ajouter l'hexagone à la liste des occupés seulement si l'unité n'est pas spéciale
            SetLength(occupiedHexes, Length(occupiedHexes) + 1);
            occupiedHexes[High(occupiedHexes)] := validHexes[unitIndex];
          end;
          unitPlaced := True;
        end;
        unitIndex := unitIndex + 1;
      end;

      if not unitPlaced then
      begin
        WriteLn('Erreur : Pas assez d''hexagones valides pour positionner toutes les unités attaquantes');
        Exit;
      end;
    end;
  end;

  WriteLn('Unités attaquantes positionnées autour de l''hexagone ', hexID);
end;
procedure DetectRiverPairsAndSave;
var
  i, j, pairCount: Integer;
  hexID, neighborID: Integer;
  startX, startY, endX, endY: Integer;
  dx, dy, steps, step: Integer;
  x, y, xInc, yInc: Single;
  pixelColor: TColor;
  riverFile: TextFile;
begin
  pairCount := 0;
  SetLength(RiverPairs, 0); // Initialiser le tableau dynamique

  // Parcourir tous les hexagones
  for i := 1 to HexagonCount do
  begin
    hexID := Hexagons[i].ID;
    startX := Hexagons[i].CenterX;
    startY := Hexagons[i].CenterY;

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

      // Si le voisin existe (ID > 0) et est supérieur à hexID (pour éviter les doublons)
      if (neighborID > 0) and (neighborID <= HexagonCount) and (hexID < neighborID) then
      begin
        endX := Hexagons[neighborID].CenterX;
        endY := Hexagons[neighborID].CenterY;

        // Algorithme de Bresenham pour tracer un trait entre les deux centres
        dx := Abs(endX - startX);
        dy := Abs(endY - startY);
        if dx > dy then
          steps := dx
        else
          steps := dy;

        if steps = 0 then Continue; // Éviter une division par zéro

        xInc := (endX - startX) / steps;
        yInc := (endY - startY) / steps;

        x := startX;
        y := startY;

        // Vérifier chaque pixel du trait
        for step := 0 to steps do
        begin
          pixelColor := getimagecolor(calqueImage, Round(x), Round(y));
          // Vérifier si la couleur est celle d'une rivière (RGB 0, 162, 232)
          if (pixelColor.r = 0) and (pixelColor.g = 162) and (pixelColor.b = 232) then
          begin
            // Ajouter la paire à RiverPairs
            Inc(pairCount);
            SetLength(RiverPairs, pairCount);
            RiverPairs[pairCount - 1].Id := pairCount;
            RiverPairs[pairCount - 1].Hex1 := hexID;
            RiverPairs[pairCount - 1].Hex2 := neighborID;
            Break; // Une rivière est détectée, pas besoin de vérifier les autres pixels
          end;
          x := x + xInc;
          y := y + yInc;
        end;
      end;
    end;
  end;

  // Sauvegarder les paires dans rivers.csv
  AssignFile(riverFile, 'resources/rivers.csv');
  Rewrite(riverFile);
  WriteLn(riverFile, 'ID,Hex1,Hex2'); // En-tête
  for i := 0 to pairCount - 1 do
  begin
    WriteLn(riverFile, Format('%d,%d,%d', [RiverPairs[i].Id, RiverPairs[i].Hex1, RiverPairs[i].Hex2]));
  end;
  CloseFile(riverFile);

  WriteLn('Détecté et sauvegardé ', pairCount, ' paires d''hexagones séparés par une rivière dans rivers.csv');
end;
procedure MarkCastleHexagons;
var
  i: Integer;
  startHexID: Integer;
begin
  // Trouver un hexagone village comme point de départ
  startHexID := -1;
  for i := 1 to HexagonCount do
  begin
    if Hexagons[i].TerrainType = 'village' then
    begin
      startHexID := Hexagons[i].ID;
      Break;
    end;
  end;

  if startHexID = -1 then
  begin
    WriteLn('Erreur : Aucun hexagone village trouvé pour déterminer le château');
    Exit;
  end;

  // Marquer les hexagones du château à partir du point de départ
  FloodFillCastle(startHexID);

  // Inclure les tours et les cases victoire dans le château
  for i := 1 to HexagonCount do
  begin
    if (Hexagons[i].Objet = 5000) or (Hexagons[i].Objet = 10000) or (Hexagons[i].Objet = 3000)then
    begin
      Hexagons[i].IsCastle := True;
    end;
  end;

  WriteLn('Surface du château déterminée à partir de l''hexagone ', startHexID);
end;
procedure DetectWalls;
var
  i, j: Integer;
  neighborID: Integer;
  wallCount: Integer;
begin
  wallCount := 0;

  // Parcourir tous les hexagones
  for i := 1 to HexagonCount do
  begin
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

      // Si le voisin existe (ID > 0) et a un mur (Objet entre 3000 et 4000)
        if (neighborID > 1000) and (neighborID< 2000) then
        begin
          Hexagons[i].HasWall := True;
          wallCount := wallCount + 1;
          Break; // On peut arrêter dès qu'on trouve un mur
        end;

      end;
    end;


  WriteLn('Détecté ', wallCount, ' hexagones avec un mur adjacent');
end;

procedure FloodFillCastle(hexID: Integer);
var
  j: Integer;
  neighborID: Integer;
begin
  // Si l'hexagone n'existe pas, est déjà marqué, ou est un mur, arrêter
  if (hexID < 1) or (hexID > HexagonCount) then Exit;
  if Hexagons[hexID].IsCastle then Exit;
  if Hexagons[hexID].HasWall then Exit;
  if Hexagons[hexID].Objet=3000 then Exit;

  // Marquer l'hexagone comme faisant partie du château
  Hexagons[hexID].IsCastle := True;

  // Explorer les 6 voisins
  for j := 1 to 6 do
  begin
    case j of
      1: neighborID := Hexagons[hexID].Neighbor1;
      2: neighborID := Hexagons[hexID].Neighbor2;
      3: neighborID := Hexagons[hexID].Neighbor3;
      4: neighborID := Hexagons[hexID].Neighbor4;
      5: neighborID := Hexagons[hexID].Neighbor5;
      6: neighborID := Hexagons[hexID].Neighbor6;
    end;
    FloodFillCastle(neighborID);
  end;
end;
function CenterUnitOnPositionActuelle(unitID: Integer): TVector2;
var
  drawPos: TVector2;
begin
  if (unitID < 1) or (unitID > MAX_UNITS) then
  begin
    WriteLn('Erreur : ID d''unité invalide dans CenterUnitOnPositionActuelle');
    Result := Vector2Create(0, 0);
    Exit;
  end;

  // Calculer la position de dessin pour centrer l'image par rapport à PositionActuelle
  drawPos.x := Game.Units[unitID].PositionActuelle.x - Game.Units[unitID].TextureHalfWidth;
  drawPos.y := Game.Units[unitID].PositionActuelle.y - Game.Units[unitID].TextureHalfHeight;
  Result := drawPos;
end;

procedure CenterUnitOnHexagon(unitID, hexID: Integer);
begin
  if (unitID < 1) or (unitID > MAX_UNITS) or (hexID < 1) or (hexID > HexagonCount) then
  begin
    WriteLn('Erreur : ID d''unité ou d''hexagone invalide dans CenterUnitOnHexagon');
    Exit;
  end;

  // Affecter l'hexagone actuel à l'unité
  Game.Units[unitID].HexagoneActuel := hexID;

  // Positionner l'unité au centre de l'hexagone
  Game.Units[unitID].PositionActuelle := Vector2Create(Hexagons[hexID].CenterX, Hexagons[hexID].CenterY);

  // Si c'est la première position, initialiser positionInitiale
  if Game.Units[unitID].HexagonePrevious = -1 then
  begin
    Game.Units[unitID].positionInitiale := Game.Units[unitID].PositionActuelle;
  end;

  // Mettre à jour BtnPerim
  UpdateUnitBtnPerim(unitID);
end;
procedure UpdateUnitBtnPerim(unitID: Integer);
begin
  if (unitID < 1) or (unitID > MAX_UNITS) then
  begin
    WriteLn('Erreur : ID d''unité invalide dans UpdateUnitBtnPerim');
    Exit;
  end;

  // Mettre à jour le rectangle BtnPerim pour centrer autour de PositionActuelle
  Game.Units[unitID].BtnPerim := RectangleCreate(
    Game.Units[unitID].PositionActuelle.x - Game.Units[unitID].TextureHalfWidth,
    Game.Units[unitID].PositionActuelle.y - Game.Units[unitID].TextureHalfHeight,
    Game.Units[unitID].latexture.width,
    Game.Units[unitID].latexture.height
  );
end;

function GetHexagonAtPosition(x, y: Single): Integer;
var
  i: Integer;
  minDistance, distance: Single;
  closestHex: Integer;
  mouseScreenPos: TVector2;
begin
  Result := 0; // Retourne 0 par défaut (clic hors de la carte ou aucun hexagone trouvé)

  // Récupérer les coordonnées brutes de la souris (espace de l'écran)
  mouseScreenPos := GetMousePosition();

  // Vérifier si le clic est dans la zone visible (hors des bordures noires)
  if (mouseScreenPos.x < leftBorderWidth) or
     (mouseScreenPos.x > screenWidth - rightBorderWidth) or
     (mouseScreenPos.y < topBorderHeight) or
     (mouseScreenPos.y > screenHeight - bottomBorderHeight) then
  begin
    WriteLn('Clic hors de la zone visible - mouseScreenPos: x=', mouseScreenPos.x, ', y=', mouseScreenPos.y);
    Exit; // Retourne 0 si le clic est dans les bordures noires
  end;

  // Si le clic est dans la zone visible, chercher l'hexagone le plus proche
  minDistance := 10000; // Distance initiale très grande
  closestHex := -1;

  // Parcourir tous les hexagones
  for i := 1 to HexagonCount do
  begin
    distance := Sqrt(Sqr(x - Hexagons[i].CenterX) + Sqr(y - Hexagons[i].CenterY));
    if distance < minDistance then
    begin
      minDistance := distance;
      closestHex := Hexagons[i].ID;
    end;
  end;

  if closestHex >= 0 then
    Result := closestHex
  else
    WriteLn('Aucun hexagone trouvé - x=', x, ', y=', y);
end;

procedure MoveCarte2DFleche;
begin
    // Déplacement de la caméra avec les touches fléchées
    deltaX := 0;
    deltaY := 0;
    if IsKeyDown(KEY_RIGHT) then deltaX := 5;
    if IsKeyDown(KEY_LEFT) then deltaX := -5;
    if IsKeyDown(KEY_DOWN) then deltaY := 5;
    if IsKeyDown(KEY_UP) then deltaY := -5;

    // Appliquer les limites au mouvement
    camera.target.x := camera.target.x + deltaX;
    camera.target.y := camera.target.y + deltaY;

    if camera.target.x < leftLimit then camera.target.x := leftLimit;
    if camera.target.x > rightLimit then camera.target.x := rightLimit;

    if camera.target.y < topLimit then camera.target.y := topLimit;
    if camera.target.y > bottomLimit then camera.target.y := bottomLimit;
end;

procedure AffichageGuiBas;
begin
   // Générer le texte des coordonnées acrobatie Pascal sur les chaines caracteres
    // conversion d un nombre en text et ensuite d'un string classique en old string Pascal et C.
      //Str(trunc(mousepos.x),untext);  // souris en x single en pascal valeur entiere ou non donc trunc pour conversion str
      //Str(trunc(mousepos.y),untext2);  // souris en y
      //phrasetext:='position clic souris fenetre principale x : ' + untext +' y : '+untext2;
      //Pchartxt :=pchar(phrasetext);
      //
      //Str(trunc(worldPosition.x),untext);  // souris en x
      //Str(trunc(worldPosition.y),untext2);
     // phrase2text:='position clic souris Carte x : ' + untext +' y : '+untext2;
      //Pchartxt2 :=pchar(phrase2text);
end;
procedure DragAndDropCarte2D;
var
  deltaX, deltaY: Single;
  currentMousePos: TVector2;
  inVisibleArea: Boolean;
begin
  // Vérifier si la souris est dans la zone visible
  currentMousePos := GetMousePosition();
  inVisibleArea := (currentMousePos.x >= leftBorderWidth) and
                   (currentMousePos.x <= screenWidth - rightBorderWidth) and
                   (currentMousePos.y >= topBorderHeight) and
                   (currentMousePos.y <= screenHeight - bottomBorderHeight);

  // Ajouter des messages de log pour déboguer


  // Initialiser mousePos la première fois
  if not Game.MouseInitialized then
  begin
    mousePos := GetMousePosition();
    Game.MouseInitialized := True;
  end;

  if IsMouseButtonDown(MOUSE_BUTTON_LEFT) then
  begin
    // Si le bouton gauche vient d'être enfoncé, initialiser mousePos et marquer le début du glisser-déposer
    if not Game.IsDragging then
    begin
      mousePos := GetMousePosition();
      Game.IsDragging := True;
    end;

    // Vérifier si la souris est dans la zone visible pour permettre le déplacement
    if inVisibleArea then
    begin
      currentMousePos := GetMousePosition();

      // Vérifier si la souris a bougé (pour différencier un clic simple d’un glisser-déposer)
      if (GetMouseDelta.x <> 0.0) or (GetMouseDelta.y <> 0.0) then
      begin
        deltaX := mousePos.x - currentMousePos.x;
        deltaY := mousePos.y - currentMousePos.y;

        camera.target.x := camera.target.x + deltaX;
        camera.target.y := camera.target.y + deltaY;

        // Utiliser les limites dynamiques
        if camera.target.x < leftLimit then
          camera.target.x := leftLimit;
        if camera.target.x > rightLimit then
          camera.target.x := rightLimit;
        if camera.target.y < topLimit then
          camera.target.y := topLimit;
        if camera.target.y > bottomLimit then
          camera.target.y := bottomLimit;

        mousePos := currentMousePos;
     end;
    end
    else
    begin
    end;
  end
  else
  begin
    // Si le bouton gauche est relâché, terminer le glisser-déposer
    if Game.IsDragging then
    Game.IsDragging := False;
  end;
end;




procedure ZoomCarte2D;
var
  wheelMove: Single;
  mouseWorldPosBefore, mouseWorldPosAfter: TVector2;
  zoomFactor: Single = 0.1; // Sensibilité du zoom
  minZoom: Single = 0.5;   // Zoom minimal (50% de la taille originale)
  maxZoom: Single = 2.0;   // Zoom maximal (200% de la taille originale)
  mousePos: TVector2;
begin
  // Vérifier si la souris est dans la zone visible
  mousePos := GetMousePosition();
  if not ((mousePos.x >= leftBorderWidth) and
          (mousePos.x <= screenWidth - rightBorderWidth) and
          (mousePos.y >= topBorderHeight) and
          (mousePos.y <= screenHeight - bottomBorderHeight)) then
  begin
    Exit; // Sortir si la souris est en dehors de la zone visible
  end;

  // Récupérer le mouvement de la molette
  wheelMove := GetMouseWheelMove();

  if wheelMove <> 0 then
  begin
    // Récupérer la position de la souris dans le monde avant le zoom
    mouseWorldPosBefore := GetScreenToWorld2D(GetMousePosition(), camera);

    // Ajuster le zoom
    camera.zoom := camera.zoom + wheelMove * zoomFactor;

    // Limiter le zoom entre minZoom et maxZoom
    if camera.zoom < minZoom then
      camera.zoom := minZoom;
    if camera.zoom > maxZoom then
      camera.zoom := maxZoom;

    // Recalculer la position de la souris dans le monde après le zoom
    mouseWorldPosAfter := GetScreenToWorld2D(GetMousePosition(), camera);

    // Ajuster la position de la caméra pour que le point sous la souris reste le même
    camera.target.x := camera.target.x + (mouseWorldPosBefore.x - mouseWorldPosAfter.x);
    camera.target.y := camera.target.y + (mouseWorldPosBefore.y - mouseWorldPosAfter.y);

    // Recalculer les limites en fonction du zoom
    leftLimit := (screenWidth - rightBorderWidth - leftBorderWidth) / 2 / camera.zoom;
    topLimit := (screenHeight - bottomBorderHeight - topBorderHeight) / 2 / camera.zoom;
    rightLimit := texture.width - (screenWidth - rightBorderWidth - leftBorderWidth) / 2 / camera.zoom;
    bottomLimit := texture.height - (screenHeight - bottomBorderHeight - topBorderHeight) / 2 / camera.zoom;

    // Assurer que la caméra respecte les nouvelles limites
    if camera.target.x < leftLimit then
      camera.target.x := leftLimit;
    if camera.target.x > rightLimit then
      camera.target.x := rightLimit;
    if camera.target.y < topLimit then
      camera.target.y := topLimit;
    if camera.target.y > bottomLimit then
      camera.target.y := bottomLimit;
  end;
end;
end.

