unit UnitProcFunc;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,raylib, init;
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




implementation
uses GameManager;

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
  minZoom: Single = 0.8;   // Zoom minimal (50% de la taille originale)
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

