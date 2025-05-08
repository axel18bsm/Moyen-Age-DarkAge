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
function GetUnitStatus(unitID: Integer): string;
function CalculateTotalForce(unitIDs: array of Integer): Single;
function IsInRangeBFS(unite: TUnit; hexCible: Integer; vecteurCible: TVector2; maxDistance: Integer): Boolean;
function IsInRangeEuclidean(unite: TUnit; hexCible: Integer; vecteurCible: TVector2; maxDistance: Integer):Boolean;
procedure SelectCombatTargetAndAttackers(numplayer: Integer);
function FindSecondHexagonForWall(targetHexID: Integer; catapultID: Integer): Integer;
procedure ExecuteMaterialCombat;
procedure ResetCombatFlags;
//ExecuteBelierCombat : Gère l’attaque du bélier sur une grille.
//ExecuteTrebuchetCombat : Gère l’attaque des trébuchets sur un mur, une grille, ou une unité ennemie.
//ExecuteCloseCombat : Gère le combat rapproché, calcule le rapport de force, et applique les résultats.
//ApplyAR, ApplyDR, ApplyDM, ApplyAM, ApplyAE, ApplyDE, ApplyEX : Appliquent les résultats spécifiques.
//DisplayCombatMessage : Centralise l’affichage des messages.
//DamageUnit : Endommage une unité (réduit la force, change l’image).
//DestroyUnit : Détruit une unité (met visible := False, BtnPerim à 0).
//MoveUnitToHex : Déplace une unité vers un hexagone.
//DestroyWallOrGate : Détruit un mur ou une grille.
//FindRetreatHex : Trouve un hexagone de recul.
//IsEnemyOnHex : Vérifie si un ennemi est sur un hexagone.
//IsHexNeighbor : Vérifie si deux hexagones sont voisins.
//SortAttackersByType et CompareUnitTypes : Trient les attaquants par type (infanterie → cavalerie → archer).
function ExecuteBelierCombat(hasBelier: Boolean; targetHexID: Integer; isGate: Boolean): Boolean;
function ExecuteTrebuchetCombat(numCatapults: Integer; targetHexID: Integer; isWall: Boolean; isGate: Boolean; hasInfantry: Boolean; belierEffectApplied: Boolean): Boolean;
procedure ExecuteCloseCombat(attackerIDs: array of Integer; targetID: Integer; wallOrGateAttacked: Boolean);
procedure ApplyAR(attackerIDs: array of Integer; attackerForce, defenderForce, row, diceRoll: Integer);
procedure ApplyDR(attackerIDs: array of Integer; targetID: Integer; attackerForce, defenderForce, row, diceRoll: Integer);
procedure ApplyDM(targetID: Integer; attackerForce, defenderForce, row, diceRoll: Integer);
procedure ApplyAM(attackerIDs: array of Integer; attackerForce, defenderForce, row, diceRoll: Integer);
procedure ApplyAE(attackerIDs: array of Integer; attackerForce, defenderForce, row, diceRoll: Integer);
procedure ApplyDE(targetID: Integer; attackerForce, defenderForce, row, diceRoll: Integer);
procedure ApplyEX(attackerIDs: array of Integer; targetID: Integer; attackerForce, defenderForce, row, diceRoll: Integer);
procedure DisplayCombatMessage(message: string);
procedure DamageUnit(unitIndex: Integer);
procedure DestroyUnit(unitIndex: Integer);
procedure MoveUnitToHex(unitIndex: Integer; hexID: Integer);
procedure DestroyWallOrGate(targetHexID: Integer);
function FindRetreatHex(unitIndex: Integer; playerNum: Integer): Integer;
function IsEnemyOnHex(hexID: Integer; playerNum: Integer): Boolean;
function IsHexNeighbor(hexID1: Integer; hexID2: Integer): Boolean;
procedure SortAttackersByType(var attackers: array of Integer);
function CompareUnitTypes(unit1: Integer; unit2: Integer): Integer;
function CheckVictory(playerNum: Integer): TTupleBooleanString;






implementation

uses GameManager;


function CheckVictory(playerNum: Integer): TTupleBooleanString;
var
  i, j: Integer;
  unitAlive: Boolean;
  victoryHexFound: Boolean;
begin
  Result.Success := False;
  Result.Message := '';


    // Vérifier la mort du duc attaquant (Type ID 4)
    WriteLn('DEBUG: Vérification victoire défenseur - Mort du duc attaquant (Type ID 4)');


        if not Game.Units[28].visible or (Game.Units[28].EtatUnite = -1) then
        begin
          Result.Success := True;
          Result.Message := 'Duc attaquant mort';
          WriteLn('DEBUG: Victoire détectée - ', Result.Message);
          Exit;
        end;




    // Vérifier le nombre de tours > 15
    WriteLn('DEBUG: Vérification victoire défenseur - Nombre de tours > 15');
    if Game.CurrentTurn > MAX_TOURS then
    begin
      Result.Success := True;
      Result.Message := 'Les mercenaires n''ont plus d''argent, les attaquants ont perdu';
      WriteLn('DEBUG: Victoire détectée - ', Result.Message);
      Exit;
    end
    else
    begin
      WriteLn('DEBUG: Nombre de tours actuel : ', Game.CurrentTurn);
    end;


    // Vérifier la mort du comte défenseur (Type ID 13)
    WriteLn('DEBUG: Vérification victoire attaquant - Mort du comte défenseur (Type ID 13)');

        if not Game.Units[13].visible or (Game.Units[59].EtatUnite = -1) then
        begin
          Result.Success := True;
          Result.Message := 'Comte défenseur mort';
          WriteLn('DEBUG: Victoire détectée - ', Result.Message);
          Exit;
        end;


    // Vérifier la mort de toutes les troupes du défenseur
    WriteLn('DEBUG: Vérification victoire attaquant - Mort de toutes les troupes du défenseur');
    unitAlive := False;
    for i := 41 to MAX_UNITS do // Unités défenseur : 41 à 68
    begin
      if (Game.Units[i].numplayer = 2) and Game.Units[i].visible and (Game.Units[i].EtatUnite >= 0) then
      begin
        unitAlive := True;
        WriteLn('DEBUG: Unité défenseur vivante trouvée (unité ', i, ')');
        Break;
      end;
    end;
    if not unitAlive then
    begin
      Result.Success := True;
      Result.Message := 'Toutes les troupes du défenseur mortes';
      WriteLn('DEBUG: Victoire détectée - ', Result.Message);
      Exit;
    end;

    // Vérifier une unité rouge sur une case de victoire pendant un tour complet
    WriteLn('DEBUG: Vérification victoire attaquant - Unité rouge sur case de victoire');
    victoryHexFound := False;
    for i := 1 to HexagonCount do
    begin
      if Hexagons[i].Objet = 10000 then // Objet Victoire
      begin
        for j := 1 to 40 do // Unités attaquant : 1 à 40
        begin
          if (Game.Units[j].HexagoneActuel = i) and (Game.Units[j].numplayer = 1) and Game.Units[j].visible then
          begin
            victoryHexFound := True;
            WriteLn('DEBUG: Unité rouge trouvée sur case de victoire (hexagone ', i, ', unité ', j, ')');
            if Game.VictoryHexOccupiedSince = Game.CurrentTurn - 1 then
            begin
              Result.Success := True;
              Result.Message := 'Unité rouge sur case de victoire pendant un tour complet';
              WriteLn('DEBUG: Victoire détectée - ', Result.Message);
              Exit;
            end;
            Game.VictoryHexOccupiedSince := Game.CurrentTurn;
            WriteLn('DEBUG: Mise à jour VictoryHexOccupiedSince : ', Game.VictoryHexOccupiedSince);
            Break;
          end;
        end;
      end;
    end;
    if not victoryHexFound then
    begin
      Game.VictoryHexOccupiedSince := -1;
      WriteLn('DEBUG: Aucune unité rouge sur une case de victoire, réinitialisation VictoryHexOccupiedSince');
    end;


  WriteLn('DEBUG: Aucune victoire détectée pour le joueur ', playerNum);
end;
function ExecuteBelierCombat(hasBelier: Boolean; targetHexID: Integer; isGate: Boolean): Boolean;
var
  diceRoll: Integer;
  wallDestroyed: Boolean;
begin
  Result := False;
  wallDestroyed := False;

  if not hasBelier then
    Exit;

  if isGate then
  begin
    // Jet de dé pour le bélier (même seuils que pour 1 catapulte)
    diceRoll := Random(6) + 1; // 1 à 6
    case diceRoll of
      1..4:
      begin
        DisplayCombatMessage('Combat : Aucun effet (bélier)');
      end;
      5..6:
      begin
        if Hexagons[targetHexID].IsDamaged then
        begin
          DisplayCombatMessage('Combat : Grille : détruite (bélier)');
          wallDestroyed := True;
        end
        else
        begin
          DisplayCombatMessage('Combat : Grille : endommagée (bélier)');
          Hexagons[targetHexID].IsDamaged := True;
        end;
      end;
    end;
  end
  else
  begin
    DisplayCombatMessage('Combat : Aucun effet (bélier, cible non-grille)');
  end;

  if wallDestroyed then
    DestroyWallOrGate(targetHexID);

  Result := wallDestroyed;
end;

function ExecuteTrebuchetCombat(numCatapults: Integer; targetHexID: Integer; isWall: Boolean; isGate: Boolean; hasInfantry: Boolean; belierEffectApplied: Boolean): Boolean;
var
  diceRoll: Integer;
  wallDestroyed: Boolean;
begin
  Result := False;
  wallDestroyed := False;

  if numCatapults = 0 then
    Exit;

  // Effectuer le jet de dé des trébuchets uniquement si la cible est un mur ou une grille
  if (isWall or isGate) or (belierEffectApplied and (isWall or isGate)) then
  begin
    diceRoll := Random(6) + 1; // 1 à 6
    case numCatapults of
      1:
      begin
        case diceRoll of
          1..4:
          begin
            DisplayCombatMessage('Combat : Aucun effet (trébuchets)');
          end;
          5..6:
          begin
            if Hexagons[targetHexID].IsDamaged then
            begin
              if isGate then
                DisplayCombatMessage('Combat : Grille : détruite (trébuchets)')
              else
                DisplayCombatMessage('Combat : Mur détruit (trébuchets)');
              wallDestroyed := True;
            end
            else
            begin
              if isGate then
                DisplayCombatMessage('Combat : Grille : endommagée (trébuchets)')
              else
                DisplayCombatMessage('Combat : Mur endommagé (trébuchets)');
              Hexagons[targetHexID].IsDamaged := True;
            end;
          end;
        end;
      end;
      2:
      begin
        case diceRoll of
          1..3:
          begin
            DisplayCombatMessage('Combat : Aucun effet (trébuchets)');
          end;
          4..5:
          begin
            if Hexagons[targetHexID].IsDamaged then
            begin
              if isGate then
                DisplayCombatMessage('Combat : Grille : détruite (trébuchets)')
              else
                DisplayCombatMessage('Combat : Mur détruit (trébuchets)');
              wallDestroyed := True;
            end
            else
            begin
              if isGate then
                DisplayCombatMessage('Combat : Grille : endommagée (trébuchets)')
              else
                DisplayCombatMessage('Combat : Mur endommagé (trébuchets)');
              Hexagons[targetHexID].IsDamaged := True;
            end;
          end;
          6:
          begin
            if isGate then
              DisplayCombatMessage('Combat : Grille : détruite (trébuchets)')
            else
              DisplayCombatMessage('Combat : Mur détruit (trébuchets)');
            wallDestroyed := True;
          end;
        end;
      end;
      3:
      begin
        case diceRoll of
          1..2:
          begin
            DisplayCombatMessage('Combat : Aucun effet (trébuchets)');
          end;
          3..4:
          begin
            if Hexagons[targetHexID].IsDamaged then
            begin
              if isGate then
                DisplayCombatMessage('Combat : Grille : détruite (trébuchets)')
              else
                DisplayCombatMessage('Combat : Mur détruit (trébuchets)');
              wallDestroyed := True;
            end
            else
            begin
              if isGate then
                DisplayCombatMessage('Combat : Grille : endommagée (trébuchets)')
              else
                DisplayCombatMessage('Combat : Mur endommagé (trébuchets)');
              Hexagons[targetHexID].IsDamaged := True;
            end;
          end;
          5..6:
          begin
            if isGate then
              DisplayCombatMessage('Combat : Grille : détruite (trébuchets)')
            else
              DisplayCombatMessage('Combat : Mur détruit (trébuchets)');
            wallDestroyed := True;
          end;
        end;
      end;
    end;
  end;

  if wallDestroyed then
    DestroyWallOrGate(targetHexID);

  Result := wallDestroyed;
end;

procedure ExecuteCloseCombat(attackerIDs: array of Integer; targetID: Integer; wallOrGateAttacked: Boolean);
var
  i, j: Integer;
  attackerForce, defenderForce: Integer;
  ratio: Single;
  intRatio: Integer;
  diceRoll: Integer;
  row: Integer;
  validAttackers: array of Integer;
  hasSpecialUnit: Boolean;
  specialUnitID: Integer;
  hasWallOrGate: Boolean;
  isInCastle: Boolean;
  hasComteOrDuc: Boolean;
  hasLieutenantOrChef: Boolean;
  attackerHex: Integer;
  neighborHex: Integer;
  humanUnitCount: Integer;
  specialUnitForce: Integer;
  wallOrGateText: string;
  hasWallOrGateText: string;
  isInCastleText: string;
  humanUnitTypes: set of Byte;
begin
  // Débogage sans IfThen
  if wallOrGateAttacked then
    wallOrGateText := 'True'
  else
    wallOrGateText := 'False';
  WriteLn('DEBUG: ExecuteCloseCombat appelé - TargetID: ', targetID, ', WallOrGateAttacked: ', wallOrGateText);

  SetLength(validAttackers, 0);
  for i := 0 to High(attackerIDs) do
  begin
    if (attackerIDs[i] >= 1) and (attackerIDs[i] <= MAX_UNITS) then
    begin
      // Exclure les unités ayant déjà attaqué
      if Game.Units[attackerIDs[i]].HasAttacked then
      begin
        WriteLn('DEBUG: Unité attaquante ', attackerIDs[i], ' a déjà attaqué, ignorée');
        Continue;
      end;
      // Exclure les trébuchets et béliers si un mur ou une grille a été attaqué
      if wallOrGateAttacked and
         ((Game.Units[attackerIDs[i]].TypeUnite.lenom = 'trebuchet') or (Game.Units[attackerIDs[i]].TypeUnite.lenom = 'belier')) then
      begin
        WriteLn('DEBUG: Unité attaquante ', attackerIDs[i], ' est un trébuchet/bélier et mur/grille attaqué, ignorée');
        Continue;
      end;
      SetLength(validAttackers, Length(validAttackers) + 1);
      validAttackers[High(validAttackers)] := attackerIDs[i];
      WriteLn('DEBUG: Unité attaquante ajoutée à validAttackers - ID: ', attackerIDs[i], ', Type: ', Game.Units[attackerIDs[i]].TypeUnite.lenom);
    end;
  end;

  if Length(validAttackers) = 0 then
  begin
    WriteLn('DEBUG: Aucun attaquant valide, sortie');
    DisplayCombatMessage('Combat rapproché : Aucun attaquant valide');
    Exit;
  end;

  // Calculer la force des attaquants avec bonus des comtes, ducs, lieutenants et chefs miliciens
  attackerForce := 0;
  for i := 0 to High(validAttackers) do
  begin
    hasComteOrDuc := False;
    hasLieutenantOrChef := False;
    specialUnitForce := 0;
    attackerHex := Game.Units[validAttackers[i]].HexagoneActuel;
    WriteLn('DEBUG: Calcul force attaquant - ID: ', validAttackers[i], ', Type: ', Game.Units[validAttackers[i]].TypeUnite.lenom, ', Hexagone: ', attackerHex);

    // Déterminer les types d'unités humaines en fonction du joueur
    if Game.Units[validAttackers[i]].numplayer = 1 then
      humanUnitTypes := [1, 2, 3] // Attaquant: Infanterie, Cavalerie, Archer
    else
      humanUnitTypes := [10, 11, 12]; // Défenseur: Infanterie, Cavalerie, Archer

    // Compter le nombre d'unités humaines sur la même case pour le bonus du lieutenant/chef milicien
    humanUnitCount := 0;
    for j := 1 to MAX_UNITS do
    begin
      if (Game.Units[j].visible) and
         (Game.Units[j].HexagoneActuel = attackerHex) and
         (Game.Units[j].numplayer = Game.Units[validAttackers[i]].numplayer) and
         (Game.Units[j].TypeUnite.Id in humanUnitTypes) then
      begin
        Inc(humanUnitCount);
      end;
    end;
    WriteLn('DEBUG: Nombre d''unités humaines sur hexagone ', attackerHex, ': ', humanUnitCount);

    // Vérifier la présence d'un comte ou duc sur la même case ou les cases voisines
    for j := 1 to MAX_UNITS do
    begin
      if (Game.Units[j].visible) and
         (Game.Units[j].numplayer = Game.Units[validAttackers[i]].numplayer) and
         (Game.Units[j].TypeUnite.Id in [4, 5]) then // Comte ou Duc
      begin
        // Même case
        if Game.Units[j].HexagoneActuel = attackerHex then
        begin
          hasComteOrDuc := True;
          specialUnitForce := specialUnitForce + Game.Units[j].Force;
          WriteLn('DEBUG: Comte/Duc trouvé sur la même case - ID: ', j, ', Force ajoutée: ', Game.Units[j].Force);
        end
        // Cases voisines
        else if IsHexNeighbor(Game.Units[j].HexagoneActuel, attackerHex) then
        begin
          hasComteOrDuc := True;
          specialUnitForce := specialUnitForce + Game.Units[j].Force;
          WriteLn('DEBUG: Comte/Duc trouvé sur case voisine - ID: ', j, ', Hexagone: ', Game.Units[j].HexagoneActuel, ', Force ajoutée: ', Game.Units[j].Force);
        end;
      end;
    end;

    // Vérifier la présence d'un lieutenant ou chef milicien sur la même case
    for j := 1 to MAX_UNITS do
    begin
      if (Game.Units[j].visible) and
         (Game.Units[j].numplayer = Game.Units[validAttackers[i]].numplayer) and
         (Game.Units[j].TypeUnite.Id in [13, 14]) and // Lieutenant ou Chef milicien
         (Game.Units[j].HexagoneActuel = attackerHex) and
         (humanUnitCount = 1) then // Une seule unité humaine sur la case
      begin
        hasLieutenantOrChef := True;
        specialUnitForce := specialUnitForce + Game.Units[j].Force;
        WriteLn('DEBUG: Lieutenant/Chef milicien trouvé - ID: ', j, ', Force ajoutée: ', Game.Units[j].Force);
      end;
    end;

    // Appliquer le bonus le plus élevé pour les attaquants
    if (Game.Units[validAttackers[i]].TypeUnite.Id in humanUnitTypes) and (hasComteOrDuc or hasLieutenantOrChef) then
    begin
      attackerForce := attackerForce + (Game.Units[validAttackers[i]].Force * 2) + specialUnitForce;
      WriteLn('DEBUG: Bonus appliqué à attaquant ', validAttackers[i], ' (unité humaine) - Force de base: ', Game.Units[validAttackers[i]].Force, ', Force après bonus: ', (Game.Units[validAttackers[i]].Force * 2), ', SpecialUnitForce: ', specialUnitForce);
    end
    else
    begin
      attackerForce := attackerForce + Game.Units[validAttackers[i]].Force;
      WriteLn('DEBUG: Pas de bonus pour attaquant ', validAttackers[i], ' - Force: ', Game.Units[validAttackers[i]].Force);
    end;
  end;
  WriteLn('DEBUG: Force totale des attaquants: ', attackerForce);

  // Calculer la force du défenseur avec bonus
  defenderForce := Game.Units[targetID].Force;
  hasSpecialUnit := False;
  specialUnitID := -1;
  specialUnitForce := 0;
  attackerHex := Game.Units[targetID].HexagoneActuel;
  WriteLn('DEBUG: Calcul force défenseur - ID: ', targetID, ', Type: ', Game.Units[targetID].TypeUnite.lenom, ', Hexagone: ', attackerHex, ', Force de base: ', defenderForce);

  // Déterminer les types d'unités humaines pour le défenseur
  if Game.Units[targetID].numplayer = 1 then
    humanUnitTypes := [1, 2, 3] // Attaquant: Infanterie, Cavalerie, Archer
  else
    humanUnitTypes := [10, 11, 12]; // Défenseur: Infanterie, Cavalerie, Archer

  // Compter le nombre d'unités humaines sur la même case pour le bonus du lieutenant/chef milicien
  humanUnitCount := 0;
  for j := 1 to MAX_UNITS do
  begin
    if (Game.Units[j].visible) and
       (Game.Units[j].HexagoneActuel = attackerHex) and
       (Game.Units[j].numplayer = Game.Units[targetID].numplayer) and
       (Game.Units[j].TypeUnite.Id in humanUnitTypes) then
    begin
      Inc(humanUnitCount);
    end;
  end;
  WriteLn('DEBUG: Nombre d''unités humaines sur hexagone ', attackerHex, ': ', humanUnitCount);

  // Vérifier la présence d'un comte ou duc sur la même case ou les cases voisines
  hasComteOrDuc := False;
  for j := 1 to MAX_UNITS do
  begin
    if (Game.Units[j].visible) and
       (Game.Units[j].numplayer = Game.Units[targetID].numplayer) and
       (Game.Units[j].TypeUnite.Id in [4, 5]) then // Comte ou Duc
    begin
      // Même case
      if Game.Units[j].HexagoneActuel = attackerHex then
      begin
        hasComteOrDuc := True;
        specialUnitForce := specialUnitForce + Game.Units[j].Force;
        WriteLn('DEBUG: Comte/Duc trouvé pour défenseur sur la même case - ID: ', j, ', Force ajoutée: ', Game.Units[j].Force);
      end
      // Cases voisines
      else if IsHexNeighbor(Game.Units[j].HexagoneActuel, attackerHex) then
      begin
        hasComteOrDuc := True;
        specialUnitForce := specialUnitForce + Game.Units[j].Force;
        WriteLn('DEBUG: Comte/Duc trouvé pour défenseur sur case voisine - ID: ', j, ', Hexagone: ', Game.Units[j].HexagoneActuel, ', Force ajoutée: ', Game.Units[j].Force);
      end;
    end;
  end;

  // Vérifier la présence d'un lieutenant ou chef milicien sur la même case
  hasLieutenantOrChef := False;
  for j := 1 to MAX_UNITS do
  begin
    if (Game.Units[j].visible) and
       (Game.Units[j].numplayer = Game.Units[targetID].numplayer) and
       (Game.Units[j].TypeUnite.Id in [13, 14]) and // Lieutenant ou Chef milicien
       (Game.Units[j].HexagoneActuel = attackerHex) and
       (humanUnitCount = 1) then // Une seule unité humaine sur la case
    begin
      hasLieutenantOrChef := True;
      specialUnitForce := specialUnitForce + Game.Units[j].Force;
      WriteLn('DEBUG: Lieutenant/Chef milicien trouvé pour défenseur - ID: ', j, ', Force ajoutée: ', Game.Units[j].Force);
    end;
  end;

  // Vérifier la présence d'un mur et si l'hexagone est un château
  hasWallOrGate := (Hexagons[Game.CombatOrders[0].TargetHexID].HasWall) or (Hexagons[Game.CombatOrders[0].TargetHexID].Objet = 3000);
  isInCastle := Hexagons[Game.CombatOrders[0].TargetHexID].IsCastle;
  if hasWallOrGate then
    hasWallOrGateText := 'True'
  else
    hasWallOrGateText := 'False';
  if isInCastle then
    isInCastleText := 'True'
  else
    isInCastleText := 'False';
  WriteLn('DEBUG: Défenseur - HasWallOrGate: ', hasWallOrGateText, ', IsInCastle: ', isInCastleText);

  // Appliquer les bonus pour le défenseur (uniquement si unité humaine)
  if Game.Units[targetID].TypeUnite.Id in humanUnitTypes then
  begin
    // Cas 3 : Mur/grille + unité spéciale + château → triplement
    if hasWallOrGate and isInCastle and (hasComteOrDuc or hasLieutenantOrChef) then
    begin
      defenderForce := Game.Units[targetID].Force * 3;
      defenderForce := defenderForce + specialUnitForce;
      WriteLn('DEBUG: Bonus Cas 3 appliqué à défenseur (unité humaine) - Force de base: ', Game.Units[targetID].Force, ', Force après triplement: ', defenderForce);
    end
    // Cas 1 : Pas de mur/grille, mais unité spéciale présente → doublage
    else if (hasComteOrDuc or hasLieutenantOrChef) and not (hasWallOrGate and isInCastle) then
    begin
      defenderForce := Game.Units[targetID].Force * 2;
      defenderForce := defenderForce + specialUnitForce;
      WriteLn('DEBUG: Bonus Cas 1 appliqué à défenseur (unité humaine) - Force de base: ', Game.Units[targetID].Force, ', Force après doublage: ', defenderForce);
    end
    // Cas 2 : Mur/grille + château, pas d'unité spéciale → doublage
    else if hasWallOrGate and isInCastle and not (hasComteOrDuc or hasLieutenantOrChef) then
    begin
      defenderForce := Game.Units[targetID].Force * 2;
      WriteLn('DEBUG: Bonus Cas 2 appliqué à défenseur (unité humaine) - Force de base: ', Game.Units[targetID].Force, ', Force après doublage: ', defenderForce);
    end;
  end
  else
  begin
    WriteLn('DEBUG: Défenseur ', targetID, ' n''est pas une unité humaine, pas de bonus - Force: ', defenderForce);
  end;
  WriteLn('DEBUG: Force totale du défenseur: ', defenderForce);

  // Calculer le rapport et déterminer le résultat
  ratio := attackerForce / defenderForce;
  WriteLn('DEBUG: Rapport de force (attackerForce / defenderForce): ', ratio:0:3);

  if ratio >= 1 then
  begin
    intRatio := Trunc(ratio);
    if intRatio <= 1 then
      row := 4
    else if intRatio <= 2 then
      row := 5
    else if intRatio <= 3 then
      row := 6
    else if intRatio <= 4 then
      row := 7
    else if intRatio <= 5 then
      row := 8
    else if intRatio <= 6 then
      row := 9
    else
      row := 9; // Pour les rapports > 6
  end
  else
  begin
    if ratio <= 0.25 then
      row := 1
    else if ratio <= 0.333 then
      row := 2
    else if ratio <= 0.5 then
      row := 3
    else
      row := 4; // Rapport <= 1
  end;
  WriteLn('DEBUG: Ligne déterminée pour table des résultats: ', row);

  diceRoll := Random(6) + 1;
  WriteLn('DEBUG: Jet de dé: ', diceRoll);

  case row of
    1: // Rapport ≤ 1/4
    begin
      case diceRoll of
        1..2: ApplyAR(validAttackers, attackerForce, defenderForce, row, diceRoll);
        3..4: ApplyAM(validAttackers, attackerForce, defenderForce, row, diceRoll);
        5..6: ApplyAE(validAttackers, attackerForce, defenderForce, row, diceRoll);
      end;
    end;
    2: // Rapport ≤ 1/3
    begin
      case diceRoll of
        1: ApplyDR(validAttackers, targetID, attackerForce, defenderForce, row, diceRoll);
        2..4: ApplyAR(validAttackers, attackerForce, defenderForce, row, diceRoll);
        5..6: ApplyAM(validAttackers, attackerForce, defenderForce, row, diceRoll);
      end;
    end;
    3: // Rapport ≤ 1/2
    begin
      case diceRoll of
        1..2: ApplyDR(validAttackers, targetID, attackerForce, defenderForce, row, diceRoll);
        3..6: ApplyAR(validAttackers, attackerForce, defenderForce, row, diceRoll);
      end;
    end;
    4: // Rapport ≤ 1/1
    begin
      case diceRoll of
        1..3: ApplyDR(validAttackers, targetID, attackerForce, defenderForce, row, diceRoll);
        4..6: ApplyAR(validAttackers, attackerForce, defenderForce, row, diceRoll);
      end;
    end;
    5: // Rapport ≤ 2/1
    begin
      case diceRoll of
        1: ApplyDM(targetID, attackerForce, defenderForce, row, diceRoll);
        2..4: ApplyDR(validAttackers, targetID, attackerForce, defenderForce, row, diceRoll);
        5..6: ApplyAR(validAttackers, attackerForce, defenderForce, row, diceRoll);
      end;
    end;
    6: // Rapport ≤ 3/1
    begin
      case diceRoll of
        1..2: ApplyDM(targetID, attackerForce, defenderForce, row, diceRoll);
        3..4: ApplyDR(validAttackers, targetID, attackerForce, defenderForce, row, diceRoll);
        5..6: ApplyAR(validAttackers, attackerForce, defenderForce, row, diceRoll);
      end;
    end;
    7: // Rapport ≤ 4/1
    begin
      case diceRoll of
        1..3: ApplyDM(targetID, attackerForce, defenderForce, row, diceRoll);
        4..5: ApplyDR(validAttackers, targetID, attackerForce, defenderForce, row, diceRoll);
        6: ApplyAR(validAttackers, attackerForce, defenderForce, row, diceRoll);
      end;
    end;
    8: // Rapport ≤ 5/1
    begin
      case diceRoll of
        1: ApplyDE(targetID, attackerForce, defenderForce, row, diceRoll);
        2..4: ApplyDM(targetID, attackerForce, defenderForce, row, diceRoll);
        5: ApplyDR(validAttackers, targetID, attackerForce, defenderForce, row, diceRoll);
        6: ApplyEX(validAttackers, targetID, attackerForce, defenderForce, row, diceRoll);
      end;
    end;
    9: // Rapport ≤ 6/1
    begin
      case diceRoll of
        1..2: ApplyDE(targetID, attackerForce, defenderForce, row, diceRoll);
        3..4: ApplyDM(targetID, attackerForce, defenderForce, row, diceRoll);
        5..6: ApplyEX(validAttackers, targetID, attackerForce, defenderForce, row, diceRoll);
      end;
    end;
  end;
  WriteLn('DEBUG: Résultat du combat appliqué');

  DisplayCombatMessage('Combat terminé');
end;

procedure ApplyAR(attackerIDs: array of Integer; attackerForce, defenderForce, row, diceRoll: Integer);
var
  i: Integer;
begin
  DisplayCombatMessage(Format('Combat : Attaquant recule (%d/%d, ligne %d, jet de dé %d)', [attackerForce, defenderForce, row, diceRoll]));
  for i := 0 to High(attackerIDs) do
  begin
      MoveUnitToHex(attackerIDs[i], FindRetreatHex(attackerIDs[i], Game.Units[attackerIDs[i]].numplayer));
  end;
end;

procedure ApplyDR(attackerIDs: array of Integer; targetID: Integer; attackerForce, defenderForce, row, diceRoll: Integer);
var
  retreatHex: Integer;
  i: Integer;
  infantryUnits: array of Integer;
  infantryCount: Integer;
  selectedInfantry: Integer;
  randomIndex: Integer;
begin
  DisplayCombatMessage(Format('Combat : Défenseur recule (%d/%d, ligne %d, jet de dé %d)', [attackerForce, defenderForce, row, diceRoll]));
  retreatHex := FindRetreatHex(targetID, Game.Units[targetID].numplayer);
  MoveUnitToHex(targetID, retreatHex);

  // Identifier les unités d'infanterie attaquantes en contact avec l'hexagone cible
  SetLength(infantryUnits, 0);
  infantryCount := 0;
  for i := 0 to High(attackerIDs) do
  begin
    if (attackerIDs[i] >= 1) and (attackerIDs[i] <= MAX_UNITS) then
    begin
      if (Game.Units[attackerIDs[i]].TypeUnite.Id = 1) and // Infanterie uniquement
         IsHexNeighbor(Game.Units[attackerIDs[i]].HexagoneActuel, Game.CombatOrders[0].TargetHexID) then
      begin
        SetLength(infantryUnits, infantryCount + 1);
        infantryUnits[infantryCount] := attackerIDs[i];
        Inc(infantryCount);
      end;
    end;
  end;

  // Si au moins une unité d'infanterie est disponible, en choisir une au hasard
  if infantryCount > 0 then
  begin
    randomIndex := Random(infantryCount); // Génère un indice aléatoire entre 0 et infantryCount-1
    selectedInfantry := infantryUnits[randomIndex];
    MoveUnitToHex(selectedInfantry, Game.CombatOrders[0].TargetHexID);
    DisplayCombatMessage('Unité attaquante ' + IntToStr(selectedInfantry) + ' (infanterie) avance sur hexagone ' + IntToStr(Game.CombatOrders[0].TargetHexID));
  end;
end;

procedure ApplyDM(targetID: Integer; attackerForce, defenderForce, row, diceRoll: Integer);
begin
  DisplayCombatMessage(Format('Combat : Défenseur endommagé (%d/%d, ligne %d, jet de dé %d)', [attackerForce, defenderForce, row, diceRoll]));
  DamageUnit(targetID);
end;

procedure ApplyAM(attackerIDs: array of Integer; attackerForce, defenderForce, row, diceRoll: Integer);
var
  i: Integer;
begin
  DisplayCombatMessage(Format('Combat : Attaquant endommagé (%d/%d, ligne %d, jet de dé %d)', [attackerForce, defenderForce, row, diceRoll]));
  for i := 0 to High(attackerIDs) do
  begin
    if (attackerIDs[i] >= 1) and (attackerIDs[i] <= MAX_UNITS) then
      DamageUnit(attackerIDs[i]);
  end;
end;

procedure ApplyAE(attackerIDs: array of Integer; attackerForce, defenderForce, row, diceRoll: Integer);
var
  i: Integer;
begin
  DisplayCombatMessage(Format('Combat : Attaquant éliminé (%d/%d, ligne %d, jet de dé %d)', [attackerForce, defenderForce, row, diceRoll]));
  for i := 0 to High(attackerIDs) do
  begin
    if (attackerIDs[i] >= 1) and (attackerIDs[i] <= MAX_UNITS) then
      DestroyUnit(attackerIDs[i]);
  end;
end;

procedure ApplyDE(targetID: Integer; attackerForce, defenderForce, row, diceRoll: Integer);
begin
  DisplayCombatMessage(Format('Combat : Défenseur éliminé (%d/%d, ligne %d, jet de dé %d)', [attackerForce, defenderForce, row, diceRoll]));
  DestroyUnit(targetID);
end;

procedure ApplyEX(attackerIDs: array of Integer; targetID: Integer; attackerForce, defenderForce, row, diceRoll: Integer);
var
  i: Integer;
  remainingForce: Integer;
  validAttackers: array of Integer;
begin
  DisplayCombatMessage(Format('Combat : Exceptionnel - Défenseur éliminé (%d/%d, ligne %d, jet de dé %d)', [attackerForce, defenderForce, row, diceRoll]));
  DestroyUnit(targetID);
  remainingForce := Game.Units[targetID].Force;
  SetLength(validAttackers, 0);
  for i := 0 to High(attackerIDs) do
  begin
    if (attackerIDs[i] >= 1) and (attackerIDs[i] <= MAX_UNITS) then
    begin
      if (Game.Units[attackerIDs[i]].TypeUnite.lenom = 'trebuchet') or (Game.Units[attackerIDs[i]].TypeUnite.lenom = 'belier') then
        Continue;
      SetLength(validAttackers, Length(validAttackers) + 1);
      validAttackers[High(validAttackers)] := attackerIDs[i];
    end;
  end;
  SortAttackersByType(validAttackers);
  for i := 0 to High(validAttackers) do
  begin
    if remainingForce <= 0 then
      Break;
    if Game.Units[validAttackers[i]].visible then
    begin
      if Game.Units[validAttackers[i]].Force <= remainingForce then
      begin
        remainingForce := remainingForce - Game.Units[validAttackers[i]].Force;
        DestroyUnit(validAttackers[i]);
        DisplayCombatMessage('Unité attaquante ' + IntToStr(validAttackers[i]) + ' éliminée (EX)');
      end
      else
      begin
        Game.Units[validAttackers[i]].Force := Game.Units[validAttackers[i]].Force - remainingForce;
        DamageUnit(validAttackers[i]);
        DisplayCombatMessage('Unité attaquante ' + IntToStr(validAttackers[i]) + ' endommagée (EX)');
        remainingForce := 0;
      end;
    end;
  end;
end;

procedure DisplayCombatMessage(message: string);
begin
  WriteLn(message); // Afficher dans le terminal
  // Ne plus appeler AddMessage ici
  // AddMessage(message);
end;

procedure DamageUnit(unitIndex: Integer);
var
  newImage: TImage;
  newTexture: TTexture2D;
begin


  // Réduire la force de l'unité et mettre à jour son état
  Game.Units[unitIndex].Force := Game.Units[unitIndex].Forcedmg;
  Game.Units[unitIndex].EtatUnite := 0;
  WriteLn('DEBUG: DamageUnit - Unité ', unitIndex, ' endommagée, nouvelle force=', Game.Units[unitIndex].Force);

  // Décharger l'ancienne texture
  if Game.Units[unitIndex].latexture.id <> 0 then
  begin
    UnloadTexture(Game.Units[unitIndex].latexture);
    WriteLn('DEBUG: DamageUnit - Ancienne texture déchargée pour unité ', unitIndex);
  end;

  // Charger l'image abîmée
  WriteLn('DEBUG: DamageUnit - Tentative de chargement de l''image abîmée : ', Game.Units[unitIndex].FileimageAbimeStr);
  newImage := LoadImage(PChar(Game.Units[unitIndex].FileimageAbimeStr));
  if newImage.data = nil then
  begin
    WriteLn('ERREUR: DamageUnit - Impossible de charger l''image abîmée ', Game.Units[unitIndex].FileimageAbimeStr, ' pour unité ', unitIndex);
    // Charger l'image normale comme secours
    newImage := LoadImage(Game.Units[unitIndex].Fileimage);
    if newImage.data = nil then
    begin
      WriteLn('ERREUR: DamageUnit - Impossible de charger l''image normale ', Game.Units[unitIndex].Fileimage, ' pour unité ', unitIndex);
      Exit;
    end;
  end;

  // Charger la nouvelle texture
  newTexture := LoadTextureFromImage(newImage);
  if newTexture.id = 0 then
  begin
    WriteLn('ERREUR: DamageUnit - Impossible de charger la texture pour unité ', unitIndex);
    UnloadImage(newImage);
    Exit;
  end;

  // Mettre à jour limage et latexture
  Game.Units[unitIndex].limage := newImage;
  Game.Units[unitIndex].latexture := newTexture;
  WriteLn('DEBUG: DamageUnit - Nouvelle texture chargée pour unité ', unitIndex);

  // Mettre à jour les dimensions de la texture
  Game.Units[unitIndex].TextureHalfWidth := Game.Units[unitIndex].latexture.width div 2;
  Game.Units[unitIndex].TextureHalfHeight := Game.Units[unitIndex].latexture.height div 2;

  // Mettre à jour BtnPerim
  UpdateUnitBtnPerim(unitIndex);
  WriteLn('DEBUG: DamageUnit - BtnPerim mis à jour pour unité ', unitIndex);
end;

procedure DestroyUnit(unitIndex: Integer);
begin
  if not Game.Units[unitIndex].visible then
    Exit;

  Game.Units[unitIndex].visible := False;
  Game.Units[unitIndex].EtatUnite := -1; // detruit
  Game.Units[unitIndex].BtnPerim := RectangleCreate(0, 0, 0, 0); // Désactiver le rectangle de collision
  Game.Units[unitIndex].PositionActuelle.x:=-1;
  Game.Units[unitIndex].PositionActuelle.y:=-1;    //hors du champ de bataille
end;

procedure MoveUnitToHex(unitIndex: Integer; hexID: Integer);
begin
  if not Game.Units[unitIndex].visible then
    Exit;

  if hexID < 1 then
  begin
    DestroyUnit(unitIndex);
    Exit;
  end;

  Game.Units[unitIndex].HexagoneActuel := hexID;
  Game.Units[unitIndex].PositionActuelle := Vector2Create(Hexagons[hexID].CenterX, Hexagons[hexID].CenterY);
  Game.Units[unitIndex].BtnPerim := RectangleCreate(
    Hexagons[hexID].CenterX - Game.Units[unitIndex].TextureHalfWidth,
    Hexagons[hexID].CenterY - Game.Units[unitIndex].TextureHalfHeight,
    Game.Units[unitIndex].latexture.width,
    Game.Units[unitIndex].latexture.height
  );
end;

procedure DestroyWallOrGate(targetHexID: Integer);
var
  i, j: Integer;
  secondHexID: Integer;
  attackerID: Integer;
  targetHexIDAdjusted: Integer;
begin
  // Mettre à jour l'hexagone cible
  Hexagons[targetHexID].HasWall := False;
  if Hexagons[targetHexID].Objet = 3000 then
    Hexagons[targetHexID].Objet := 0;
  Hexagons[targetHexID].IsDamaged := False;

  // Mettre à jour les voisins de l'hexagone cible
  for i := 1 to 6 do
  begin
    case i of
      1: Hexagons[targetHexID].Neighbor1 := Hexagons[targetHexID].Neighbor1 mod 1000;
      2: Hexagons[targetHexID].Neighbor2 := Hexagons[targetHexID].Neighbor2 mod 1000;
      3: Hexagons[targetHexID].Neighbor3 := Hexagons[targetHexID].Neighbor3 mod 1000;
      4: Hexagons[targetHexID].Neighbor4 := Hexagons[targetHexID].Neighbor4 mod 1000;
      5: Hexagons[targetHexID].Neighbor5 := Hexagons[targetHexID].Neighbor5 mod 1000;
      6: Hexagons[targetHexID].Neighbor6 := Hexagons[targetHexID].Neighbor6 mod 1000;
    end;
  end;

  // Parcourir chaque attaquant pour trouver l'hexagone voisin (secondHexID) et mettre à jour son état
  for i := 0 to High(Game.CombatOrders[0].AttackerIDs) do
  begin
    attackerID := Game.CombatOrders[0].AttackerIDs[i];
    if (attackerID < 1) or (attackerID > MAX_UNITS) then
      Continue;

    // Trouver le second hexagone pour le mur
    secondHexID := FindSecondHexagonForWall(targetHexID, attackerID);
    if (secondHexID < 1) or (secondHexID > HexagonCount) then
      Continue;

    // Mettre à jour l'état de l'hexagone voisin
    Hexagons[secondHexID].HasWall := False;
    if Hexagons[secondHexID].Objet = 3000 then
      Hexagons[secondHexID].Objet := 0;
    Hexagons[secondHexID].IsDamaged := False;

    // Mettre à jour les voisins de l'hexagone voisin
    for j := 1 to 6 do
    begin
      // Ajuster le voisin pour qu'il soit comparable (modulo 1000)
      case j of
        1: targetHexIDAdjusted := Hexagons[secondHexID].Neighbor1 mod 1000;
        2: targetHexIDAdjusted := Hexagons[secondHexID].Neighbor2 mod 1000;
        3: targetHexIDAdjusted := Hexagons[secondHexID].Neighbor3 mod 1000;
        4: targetHexIDAdjusted := Hexagons[secondHexID].Neighbor4 mod 1000;
        5: targetHexIDAdjusted := Hexagons[secondHexID].Neighbor5 mod 1000;
        6: targetHexIDAdjusted := Hexagons[secondHexID].Neighbor6 mod 1000;
        else targetHexIDAdjusted := -1;
      end;

      // Si le voisin correspond à l'hexagone cible, appliquer modulo 1000
      if targetHexIDAdjusted = targetHexID then
      begin
        case j of
          1: Hexagons[secondHexID].Neighbor1 := Hexagons[secondHexID].Neighbor1 mod 1000;
          2: Hexagons[secondHexID].Neighbor2 := Hexagons[secondHexID].Neighbor2 mod 1000;
          3: Hexagons[secondHexID].Neighbor3 := Hexagons[secondHexID].Neighbor3 mod 1000;
          4: Hexagons[secondHexID].Neighbor4 := Hexagons[secondHexID].Neighbor4 mod 1000;
          5: Hexagons[secondHexID].Neighbor5 := Hexagons[secondHexID].Neighbor5 mod 1000;
          6: Hexagons[secondHexID].Neighbor6 := Hexagons[secondHexID].Neighbor6 mod 1000;
        end;
      end;
    end;
  end;

  // Redétecter les murs pour les hexagones voisins
  DetectWalls();
end;

function FindRetreatHex(unitIndex: Integer; playerNum: Integer): Integer;
var
  i, j: Integer;
  currentHex: Integer;
  neighborID: Integer;
  isFree: Boolean;
  isSafe: Boolean;
  friendlyUnit: Integer;
begin
  Result := -1;
  currentHex := Game.Units[unitIndex].HexagoneActuel;

  // Parcourir les voisins de l'hexagone actuel
  for i := 1 to 6 do
  begin
    case i of
      1: neighborID := Hexagons[currentHex].Neighbor1;
      2: neighborID := Hexagons[currentHex].Neighbor2;
      3: neighborID := Hexagons[currentHex].Neighbor3;
      4: neighborID := Hexagons[currentHex].Neighbor4;
      5: neighborID := Hexagons[currentHex].Neighbor5;
      6: neighborID := Hexagons[currentHex].Neighbor6;
      else neighborID := -1;
    end;

    if (neighborID < 1) or (neighborID > HexagonCount) then
      Continue;

    // Vérifier si la case est libre
    isFree := True;
    for j := 1 to MAX_UNITS do
    begin
      if (Game.Units[j].visible) and (Game.Units[j].HexagoneActuel = neighborID) then
      begin
        isFree := False;
        // Si la case est occupée par une unité amie, on peut la repousser
        if Game.Units[j].numplayer = playerNum then
        begin
          friendlyUnit := j;
          Break;
        end;
      end;
    end;

    // Vérifier si la case est sûre (non voisine d'un ennemi)
    isSafe := True;
    for j := 1 to 6 do
    begin
      case j of
        1: if (Hexagons[neighborID].Neighbor1 >= 1) and (Hexagons[neighborID].Neighbor1 <= HexagonCount) then
            if IsEnemyOnHex(Hexagons[neighborID].Neighbor1, playerNum) then
              isSafe := False;
        2: if (Hexagons[neighborID].Neighbor2 >= 1) and (Hexagons[neighborID].Neighbor2 <= HexagonCount) then
            if IsEnemyOnHex(Hexagons[neighborID].Neighbor2, playerNum) then
              isSafe := False;
        3: if (Hexagons[neighborID].Neighbor3 >= 1) and (Hexagons[neighborID].Neighbor3 <= HexagonCount) then
            if IsEnemyOnHex(Hexagons[neighborID].Neighbor3, playerNum) then
              isSafe := False;
        4: if (Hexagons[neighborID].Neighbor4 >= 1) and (Hexagons[neighborID].Neighbor4 <= HexagonCount) then
            if IsEnemyOnHex(Hexagons[neighborID].Neighbor4, playerNum) then
              isSafe := False;
        5: if (Hexagons[neighborID].Neighbor5 >= 1) and (Hexagons[neighborID].Neighbor5 <= HexagonCount) then
            if IsEnemyOnHex(Hexagons[neighborID].Neighbor5, playerNum) then
              isSafe := False;
        6: if (Hexagons[neighborID].Neighbor6 >= 1) and (Hexagons[neighborID].Neighbor6 <= HexagonCount) then
            if IsEnemyOnHex(Hexagons[neighborID].Neighbor6, playerNum) then
              isSafe := False;
      end;
    end;

    if isFree and isSafe then
    begin
      Result := neighborID;
      Exit;
    end;

    // Si la case est occupée par une unité amie, repousser cette unité
    if not isFree and (friendlyUnit >= 1) and isSafe then
    begin
      MoveUnitToHex(friendlyUnit, FindRetreatHex(friendlyUnit, playerNum));
      if Game.Units[friendlyUnit].visible then // Si l'unité amie a pu reculer
      begin
        Result := neighborID;
        Exit;
      end;
    end;
  end;

  // Si aucune case n'est disponible, retourner -1 (l'unité sera éliminée)
  Result := -1;
end;

function IsEnemyOnHex(hexID: Integer; playerNum: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to MAX_UNITS do
  begin
    if (Game.Units[i].visible) and (Game.Units[i].HexagoneActuel = hexID) and (Game.Units[i].numplayer <> playerNum) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function IsHexNeighbor(hexID1: Integer; hexID2: Integer): Boolean;
var
  i: Integer;
  neighborID: Integer;
begin
  Result := False;
  for i := 1 to 6 do
  begin
    case i of
      1: neighborID := Hexagons[hexID1].Neighbor1;
      2: neighborID := Hexagons[hexID1].Neighbor2;
      3: neighborID := Hexagons[hexID1].Neighbor3;
      4: neighborID := Hexagons[hexID1].Neighbor4;
      5: neighborID := Hexagons[hexID1].Neighbor5;
      6: neighborID := Hexagons[hexID1].Neighbor6;
      else neighborID := -1;
    end;
    if neighborID = hexID2 then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure SortAttackersByType(var attackers: array of Integer);
var
  i, j: Integer;
  temp: Integer;
begin
  // Trier par type : infanterie → cavalerie → archer
  for i := 0 to High(attackers) - 1 do
  begin
    for j := i + 1 to High(attackers) do
    begin
      if CompareUnitTypes(attackers[i], attackers[j]) > 0 then
      begin
        temp := attackers[i];
        attackers[i] := attackers[j];
        attackers[j] := temp;
      end;
    end;
  end;
end;

function CompareUnitTypes(unit1: Integer; unit2: Integer): Integer;
var
  type1, type2: string;
begin
  type1 := Game.Units[unit1].TypeUnite.lenom;
  type2 := Game.Units[unit2].TypeUnite.lenom;

  if (type1 = type2) or (type1 = 'trebuchet') or (type1 = 'belier') or (type2 = 'trebuchet') or (type2 = 'belier') then
    Result := 0
  else if (type1 = 'infanterie') then
    Result := -1
  else if (type2 = 'infanterie') then
    Result := 1
  else if (type1 = 'cavalerie') then
    Result := -1
  else if (type2 = 'cavalerie') then
    Result := 1
  else
    Result := 0; // Archers ou autres types
end;
function FindSecondHexagonForWall(targetHexID: Integer; catapultID: Integer): Integer;
var
  i, neighborID, adjustedNeighborID: Integer;
  centerX, centerY, catapultX, catapultY: Single;
  angle, minAngle: Single;
  closestNeighbor: Integer;
begin
  Result := -1;
  if (targetHexID < 1) or (targetHexID > HexagonCount) or (catapultID < 1) or (catapultID > MAX_UNITS) then
    Exit;

  // Coordonnées du centre de l'hexagone cible
  centerX := Hexagons[targetHexID].CenterX;
  centerY := Hexagons[targetHexID].CenterY;

  // Coordonnées de la catapulte
  catapultX := Game.Units[catapultID].PositionActuelle.x;
  catapultY := Game.Units[catapultID].PositionActuelle.y;

  // Trouver le voisin le plus aligné avec la direction de la catapulte
  minAngle := 360; // Une grande valeur pour trouver le minimum
  closestNeighbor := -1;

  for i := 1 to 6 do
  begin
    case i of
      1: neighborID := Hexagons[targetHexID].Neighbor1;
      2: neighborID := Hexagons[targetHexID].Neighbor2;
      3: neighborID := Hexagons[targetHexID].Neighbor3;
      4: neighborID := Hexagons[targetHexID].Neighbor4;
      5: neighborID := Hexagons[targetHexID].Neighbor5;
      6: neighborID := Hexagons[targetHexID].Neighbor6;
    end;

    // Ajuster l'ID si nécessaire (pour les rivières ou murs)
    adjustedNeighborID := neighborID;
    if neighborID > 832 then
      adjustedNeighborID := neighborID mod 1000;

    // Vérifier si le voisin est valide
    if (adjustedNeighborID >= 1) and (adjustedNeighborID <= HexagonCount) then
    begin
      // Calculer l'angle entre la catapulte et ce voisin
      angle := ArcTan2(Hexagons[adjustedNeighborID].CenterY - centerY, Hexagons[adjustedNeighborID].CenterX - centerX) -
               ArcTan2(catapultY - centerY, catapultX - centerX);
      angle := Abs(angle * 180 / Pi); // Convertir en degrés et prendre la valeur absolue
      if angle > 180 then
        angle := 360 - angle;

      // Trouver le voisin avec l'angle le plus petit
      if angle < minAngle then
      begin
        minAngle := angle;
        closestNeighbor := adjustedNeighborID;
      end;
    end;
  end;

  Result := closestNeighbor;
end;


procedure ExecuteMaterialCombat;
var
  i: Integer;
  attackerID: Integer;
  numCatapults: Integer;
  isWall, isGate: Boolean;
  hasBelier: Boolean;
  belierEffectApplied: Boolean;
  hasInfantry: Boolean;
  enemyOnHex: Boolean;
  targetPlayer: Integer;
  enemyUnits: array of Integer;
  wallOrGateAttacked: Boolean;
begin
  if (Length(Game.CombatOrders) = 0) or (Length(Game.CombatOrders[0].AttackerIDs) = 0) then
    Exit;

  // Initialiser les variables
  belierEffectApplied := False;
  hasBelier := False;
  hasInfantry := Game.CombatOrders[0].TargetID >= 1;
  enemyOnHex := False;
  wallOrGateAttacked := False;
  SetLength(enemyUnits, 0);

  // Déterminer si la cible est un mur ou une grille
  isWall := Hexagons[Game.CombatOrders[0].TargetHexID].HasWall;
  isGate := Hexagons[Game.CombatOrders[0].TargetHexID].Objet = 3000;

  // Déterminer le joueur cible (inversé par rapport aux attaquants)
  targetPlayer := 3 - Game.Units[Game.CombatOrders[0].AttackerIDs[0]].numplayer;

  // Vérifier si des unités ennemies sont présentes sur l'hexagone cible
  for i := 1 to MAX_UNITS do
  begin
    if (Game.Units[i].visible) and                                              // verifie si l uniré et est valide
       (Game.Units[i].HexagoneActuel = Game.CombatOrders[0].TargetHexID) and
       (Game.Units[i].numplayer = targetPlayer) and
       (not Game.Units[i].IsAttacked) then
    begin
      enemyOnHex := True;
      SetLength(enemyUnits, Length(enemyUnits) + 1);
      enemyUnits[High(enemyUnits)] := i;
      WriteLn('DEBUG: Unité ennemie détectée - ID: ', i, ', Hexagone: ', Game.Units[i].HexagoneActuel);
    end;
  end;

  if not enemyOnHex then
    WriteLn('DEBUG: Aucune unité ennemie détectée sur l''hexagone cible ', Game.CombatOrders[0].TargetHexID);

  // Compter le nombre de trébuchets et vérifier la présence d'un bélier
  numCatapults := 0;
  for i := 0 to High(Game.CombatOrders[0].AttackerIDs) do
  begin
    attackerID := Game.CombatOrders[0].AttackerIDs[i];
    if (attackerID >= 1) and (attackerID <= MAX_UNITS) then
    begin
      if Game.Units[attackerID].TypeUnite.lenom = 'trebuchet' then
        Inc(numCatapults)
      else if Game.Units[attackerID].TypeUnite.lenom = 'belier' then
        hasBelier := True;
    end;
  end;

  // Gérer l'attaque du bélier
  if hasBelier then
  begin
    belierEffectApplied := ExecuteBelierCombat(hasBelier, Game.CombatOrders[0].TargetHexID, isGate);
    if belierEffectApplied then
      wallOrGateAttacked := True;
    // Marquer les béliers comme ayant attaqué
    for i := 0 to High(Game.CombatOrders[0].AttackerIDs) do
    begin
      attackerID := Game.CombatOrders[0].AttackerIDs[i];
      if (attackerID >= 1) and (attackerID <= MAX_UNITS) and (Game.Units[attackerID].TypeUnite.lenom = 'belier') then
        Game.Units[attackerID].HasAttacked := True;
    end;
  end;

  // Gérer l'attaque des trébuchets
  if numCatapults > 0 then
  begin
    if ExecuteTrebuchetCombat(numCatapults, Game.CombatOrders[0].TargetHexID, isWall, isGate, hasInfantry, belierEffectApplied) then
      wallOrGateAttacked := True;
    // Marquer les trébuchets comme ayant attaqué
    for i := 0 to High(Game.CombatOrders[0].AttackerIDs) do
    begin
      attackerID := Game.CombatOrders[0].AttackerIDs[i];
      if (attackerID >= 1) and (attackerID <= MAX_UNITS) and (Game.Units[attackerID].TypeUnite.lenom = 'trebuchet') then
        Game.Units[attackerID].HasAttacked := True;
    end;
  end;

  // Gérer le combat rapproché si une unité ennemie est ciblée ou présente sur l'hexagone
  if hasInfantry then
  begin
    WriteLn('DEBUG: ExecuteCloseCombat appelé (hasInfantry = True)');
    ExecuteCloseCombat(Game.CombatOrders[0].AttackerIDs, Game.CombatOrders[0].TargetID, wallOrGateAttacked);
  end
  else if enemyOnHex then
  begin
    WriteLn('DEBUG: ExecuteCloseCombat appelé (enemyOnHex = True)');
    for i := 0 to High(enemyUnits) do
    begin
      if not Game.Units[enemyUnits[i]].IsAttacked then
      begin
        Game.CombatOrders[0].TargetID := enemyUnits[i];
        ExecuteCloseCombat(Game.CombatOrders[0].AttackerIDs, Game.CombatOrders[0].TargetID, wallOrGateAttacked);
        Break;
      end;
    end;
  end
  else
  begin
    WriteLn('DEBUG: ExecuteCloseCombat non appelé (ni hasInfantry ni enemyOnHex)');
  end;

  // Mettre à jour les flags des unités attaquantes (déjà fait pour les trébuchets et béliers)
  for i := 0 to High(Game.CombatOrders[0].AttackerIDs) do
  begin
    attackerID := Game.CombatOrders[0].AttackerIDs[i];
    if (attackerID >= 1) and (attackerID <= MAX_UNITS) and not Game.Units[attackerID].HasAttacked then
      Game.Units[attackerID].HasAttacked := True;
  end;

  // Marquer la cible et l'hexagone comme attaqués
  if Game.CombatOrders[0].TargetID >= 1 then
    Game.Units[Game.CombatOrders[0].TargetID].IsAttacked := True;
  Hexagons[Game.CombatOrders[0].TargetHexID].IsAttacked := True;

  // Réinitialiser les ordres de combat
  SetLength(Game.CombatOrders, 0);
end;

procedure SelectCombatTargetAndAttackers(numplayer: Integer);
var
  mousePos: TVector2;
  unitIndex, hexID, i: Integer;
  alreadyAttacker, isCatapult: Boolean;
  targetPlayer: Integer;
  distance: Integer;
  isCatapultText: string;
  numTrebuchets: Integer;  // Déclaration de numTrebuchets
  numBeliers: Integer;     // Déclaration de numBeliers
begin
  HandleCommonInput(numplayer, False);
  mousePos := GetScreenToWorld2D(GetMousePosition(), camera);
  //WriteLn('DEBUG: SelectCombatTargetAndAttackers - Numplayer: ', numplayer, ', MousePos: (', mousePos.x:0:2, ', ', mousePos.y:0:2, ')');

  // Déterminer le joueur cible (inversé par rapport à numplayer)
  targetPlayer := 3 - numplayer;
  //WriteLn('DEBUG: Joueur cible: ', targetPlayer);

  // Clic droit : Sélectionner une cible (hexagone et unité si présente)
  if IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) then
  begin
    // Détecter l'hexagone cliqué
    hexID := GetHexagonAtPosition(mousePos.x, mousePos.y);
    //WriteLn('DEBUG: Clic droit - Hexagone détecté: ', hexID);
    if hexID < 1 then
    begin
      WriteLn('DEBUG: Hexagone invalide, sortie');
      Exit;
    end;

    // Réinitialiser les ordres de combat
    if Length(Game.CombatOrders) = 0 then
      SetLength(Game.CombatOrders, 1);
    Game.CombatOrders[0].TargetHexID := hexID;
    Game.CombatOrders[0].TargetID := -1; // Par défaut, pas d'unité
    SetLength(Game.CombatOrders[0].AttackerIDs, 0); // Réinitialiser les attaquants
    WriteLn('DEBUG: Ordres de combat réinitialisés - TargetHexID: ', Game.CombatOrders[0].TargetHexID);

    // Vérifier si une unité ennemie est présente sur cet hexagone
    for unitIndex := 1 to MAX_UNITS do
    begin
      if not (Game.Units[unitIndex].visible and (Game.Units[unitIndex].HexagoneActuel = hexID)) then
        Continue;
      if not (Game.Units[unitIndex].numplayer = targetPlayer) or Game.Units[unitIndex].IsAttacked then
        Continue;

      Game.CombatOrders[0].TargetID := unitIndex;
      WriteLn('DEBUG: Unité cible trouvée - ID: ', unitIndex, ', Type: ', Game.Units[unitIndex].TypeUnite.lenom, ', Hexagone: ', hexID);
      AddMessage('Unité cible ' + IntToStr(unitIndex) + ' sélectionnée sur hexagone ' + IntToStr(hexID));
      Exit;
    end;

    // Si aucune unité n'est présente, afficher un message pour l'hexagone
    if (Hexagons[hexID].IsCastle) or (Hexagons[hexID].Objet = 3000) then
    begin
      WriteLn('DEBUG: Hexagone cible avec mur/grille - ID: ', hexID);
      AddMessage('Hexagone cible ' + IntToStr(hexID) + ' sélectionné (mur/grille)');
    end
    else
    begin
      WriteLn('DEBUG: Hexagone cible sélectionné - ID: ', hexID);
      AddMessage('Hexagone cible ' + IntToStr(hexID) + ' sélectionné');
    end;
    Exit;
  end;

  // Clic gauche : Ajouter une unité comme attaquant
  if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
  begin
    if (Length(Game.CombatOrders) = 0) or (Game.CombatOrders[0].TargetHexID < 1) then
    begin
      WriteLn('DEBUG: Clic gauche - Aucune cible sélectionnée, sortie');
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

      WriteLn('DEBUG: Clic gauche - Unité potentielle attaquante trouvée - ID: ', unitIndex, ', Type: ', Game.Units[unitIndex].TypeUnite.lenom, ', Hexagone: ', Game.Units[unitIndex].HexagoneActuel);

      // Vérifier si l'attaquant est déjà dans la liste
      alreadyAttacker := False;
      for i := 0 to High(Game.CombatOrders[0].AttackerIDs) do
        if Game.CombatOrders[0].AttackerIDs[i] = unitIndex then
        begin
          alreadyAttacker := True;
          WriteLn('DEBUG: Unité ', unitIndex, ' déjà dans la liste des attaquants');
          Break;
        end;
      if alreadyAttacker then
        Continue;

      // Déterminer si l'unité est une catapulte (trébuchet : ID 6 ou 15)
      isCatapult := (Game.Units[unitIndex].TypeUnite.Id in [6, 15]);
      if isCatapult then
        isCatapultText := 'Oui'
      else
        isCatapultText := 'Non';
      WriteLn('DEBUG: Unité ', unitIndex, ' - Est une catapulte: ', isCatapultText);

      // Vérifier la portée
      if Game.CombatOrders[0].TargetID >= 1 then
      begin
        // Si une unité est ciblée, vérifier la portée par rapport à l'hexagone de l'unité cible
        if not IsInRangeBFS(Game.Units[unitIndex],
                            Game.Units[Game.CombatOrders[0].TargetID].HexagoneActuel,
                            Vector2Create(Hexagons[Game.Units[Game.CombatOrders[0].TargetID].HexagoneActuel].CenterX,
                                          Hexagons[Game.Units[Game.CombatOrders[0].TargetID].HexagoneActuel].CenterY),
                            Game.Units[unitIndex].DistCombatMax) then
        begin
          WriteLn('DEBUG: Unité ', unitIndex, ' hors de portée de l''unité cible ', Game.CombatOrders[0].TargetID);
          AddMessage('Attaquant id ' + IntToStr(unitIndex) + ' hors de portée');
          Continue;
        end;
        WriteLn('DEBUG: Unité ', unitIndex, ' à portée de l''unité cible ', Game.CombatOrders[0].TargetID);
      end
      else
      begin
        // Sinon, vérifier la portée par rapport à l'hexagone cible (mur/grille)
        if not IsInRangeBFS(Game.Units[unitIndex],
                            Game.CombatOrders[0].TargetHexID,
                            Vector2Create(Hexagons[Game.CombatOrders[0].TargetHexID].CenterX,
                                          Hexagons[Game.CombatOrders[0].TargetHexID].CenterY),
                            Game.Units[unitIndex].DistCombatMax) then
        begin
          WriteLn('DEBUG: Unité ', unitIndex, ' hors de portée de l''hexagone cible ', Game.CombatOrders[0].TargetHexID);
          AddMessage('Attaquant id ' + IntToStr(unitIndex) + ' hors de portée');
          Continue;
        end;
        WriteLn('DEBUG: Unité ', unitIndex, ' à portée de l''hexagone cible ', Game.CombatOrders[0].TargetHexID);
      end;

      // Vérifier la limite de 10 attaquants
      if Length(Game.CombatOrders[0].AttackerIDs) >= 10 then
      begin
        WriteLn('DEBUG: Limite de 10 attaquants atteinte');
        AddMessage('Limite de 10 attaquants atteinte');
        Exit;
      end;

      // Vérifier si l'unité est un bélier et si la cible est une grille
      if (Game.Units[unitIndex].TypeUnite.lenom = 'belier') and (Hexagons[Game.CombatOrders[0].TargetHexID].Objet <> 3000) then
      begin
        WriteLn('DEBUG: Unité ', unitIndex, ' est un bélier, mais cible non-grille, ignorée');
        Continue;
      end;

      // Compter les trébuchets et béliers déjà sélectionnés
      numTrebuchets := 0;
      numBeliers := 0;
      for i := 0 to High(Game.CombatOrders[0].AttackerIDs) do
      begin
        if Game.Units[Game.CombatOrders[0].AttackerIDs[i]].TypeUnite.lenom = 'trebuchet' then
          Inc(numTrebuchets)
        else if Game.Units[Game.CombatOrders[0].AttackerIDs[i]].TypeUnite.lenom = 'belier' then
          Inc(numBeliers);
      end;
      WriteLn('DEBUG: Nombre de trébuchets déjà sélectionnés: ', numTrebuchets, ', Nombre de béliers: ', numBeliers);

      // Vérifier les limites spécifiques
      if (Game.Units[unitIndex].TypeUnite.lenom = 'trebuchet') and (numTrebuchets >= 3) then
      begin
        WriteLn('DEBUG: Limite de 3 trébuchets atteinte, unité ', unitIndex, ' ignorée');
        Continue;
      end;
      if (Game.Units[unitIndex].TypeUnite.lenom = 'belier') and (numBeliers >= 1) then
      begin
        WriteLn('DEBUG: Limite de 1 bélier atteinte, unité ', unitIndex, ' ignorée');
        Continue;
      end;

      // Ajouter l'attaquant
      SetLength(Game.CombatOrders[0].AttackerIDs, Length(Game.CombatOrders[0].AttackerIDs) + 1);
      Game.CombatOrders[0].AttackerIDs[High(Game.CombatOrders[0].AttackerIDs)] := unitIndex;
      WriteLn('DEBUG: Unité attaquante ajoutée - ID: ', unitIndex, ', Type: ', Game.Units[unitIndex].TypeUnite.lenom);
      AddMessage('Unité attaquante ' + IntToStr(unitIndex) + ' ajoutée');
      Exit;
    end;
  end;
end;

procedure ResetCombatFlags;
var
  unitIndex: Integer;
begin
  for unitIndex := 1 to MAX_UNITS do
  begin
    Game.Units[unitIndex].IsAttacked := False;
    Game.Units[unitIndex].HasAttacked := False;
  end;
end;

function IsInRangeBFS(unite: TUnit; hexCible: Integer; vecteurCible: TVector2; maxDistance: Integer): Boolean;
type
  TQueueEntry = record
    HexID: Integer;
    Distance: Integer;
  end;
var
  queue: array of TQueueEntry;
  queueStart, queueEnd: Integer;
  visited: array of Boolean;
  i, neighborID, adjustedNeighborID: Integer;
  currentEntry: TQueueEntry;
  hexStart: Integer;
  distanceFound: Integer;
begin
  Result := False;

  hexStart := unite.HexagoneActuel;

  // Cas particulier : même hexagone
  if hexStart = hexCible then
  begin
    distanceFound := 0;
    Result := (distanceFound >= unite.DistCombatMin) and (distanceFound <= unite.DistCombatMax);
    Exit;
  end;

  // Initialiser la file pour BFS
  SetLength(queue, HexagonCount);
  queueStart := 0;
  queueEnd := 0;
  queue[queueEnd].HexID := hexStart;
  queue[queueEnd].Distance := 0;
  Inc(queueEnd);

  // Initialiser le tableau des hexagones visités
  SetLength(visited, HexagonCount + 1);
  for i := 0 to HexagonCount do
    visited[i] := False;
  visited[hexStart] := True;

  // Parcourir la grille avec BFS
  while queueStart < queueEnd do
  begin
    // Récupérer l'hexagone courant
    currentEntry := queue[queueStart];
    Inc(queueStart);

    // Vérifier si on a atteint la cible
    if currentEntry.HexID = hexCible then
    begin
      distanceFound := currentEntry.Distance;
      Result := (distanceFound >= unite.DistCombatMin) and (distanceFound <= unite.DistCombatMax);
      Exit;
    end;

    // Vérifier si la distance dépasse maxDistance
    if currentEntry.Distance >= maxDistance then
      Continue;

    // Explorer les voisins
    for i := 1 to 6 do
    begin
      case i of
        1: neighborID := Hexagons[currentEntry.HexID].Neighbor1;
        2: neighborID := Hexagons[currentEntry.HexID].Neighbor2;
        3: neighborID := Hexagons[currentEntry.HexID].Neighbor3;
        4: neighborID := Hexagons[currentEntry.HexID].Neighbor4;
        5: neighborID := Hexagons[currentEntry.HexID].Neighbor5;
        6: neighborID := Hexagons[currentEntry.HexID].Neighbor6;
      end;

      // Appliquer la règle : si l'ID est supérieur à 832, utiliser modulo 1000
      adjustedNeighborID := neighborID;
      if neighborID > 832 then
        adjustedNeighborID := neighborID mod 1000;

      // Ignorer les voisins invalides (ID = 0)
      if adjustedNeighborID = 0 then
        Continue;

      if not visited[adjustedNeighborID] then
      begin
        // Ajouter le voisin à la file
        visited[adjustedNeighborID] := True;
        queue[queueEnd].HexID := adjustedNeighborID;
        queue[queueEnd].Distance := currentEntry.Distance + 1;
        Inc(queueEnd);
      end;
    end;
  end;

  // Si la cible n'est pas atteinte
  Result := False;
end;

// Fonction : IsInRangeEuclidean (Approximation euclidienne)
function IsInRangeEuclidean(unite: TUnit; hexCible: Integer; vecteurCible: TVector2; maxDistance: Integer): Boolean;
const
  HEX_SIZE = 50; // À ajuster selon la taille réelle des hexagones (distance entre deux centres voisins)
var
  x1, y1, x2, y2: Single;
  distanceEuclidean: Single;
  distanceHexagons: Integer;
  hexStart: Integer;
begin
  Result := False;

  hexStart := unite.HexagoneActuel;

  // Cas particulier : même hexagone
  if hexStart = hexCible then
  begin
    distanceHexagons := 0;
    Result := (distanceHexagons >= unite.DistCombatMin) and (distanceHexagons <= unite.DistCombatMax);
    Exit;
  end;

  // Récupérer les coordonnées centrales
  x1 := Hexagons[hexStart].CenterX;
  y1 := Hexagons[hexStart].CenterY;
  x2 := vecteurCible.x;
  y2 := vecteurCible.y;

  // Calculer la distance euclidienne
  distanceEuclidean := Sqrt(Sqr(x2 - x1) + Sqr(y2 - y1));

  // Convertir en nombre d'hexagones (approximation)
  distanceHexagons := Round(distanceEuclidean / HEX_SIZE);

  // Vérifier si la distance dépasse maxDistance
  if distanceHexagons > maxDistance then
  begin
    Result := False;
    Exit;
  end;

  // Vérifier la portée
  Result := (distanceHexagons >= unite.DistCombatMin) and (distanceHexagons <= unite.DistCombatMax);
end;


function CalculateTotalForce(unitIDs: array of Integer): Single;
var
  i: Integer;
  totalForce: Single;
begin
  totalForce := 0.0;
  for i := 0 to High(unitIDs) do
    if unitIDs[i] >= 1 then
      totalForce := totalForce + Game.Units[unitIDs[i]].Force;
  Result := totalForce;
end;

function GetUnitStatus(unitID: Integer): string;
begin
  if Game.Units[unitID].EtatUnite = 1 then
    Result := 'Entier'
  else
    Result := 'Abimé';
end;
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
            UnloadImage(Game.Units[unitid].limage);
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
    gsSetupAttacker: Result := 'Plact des troupes (Attaquant)';
    gsSetupDefender: Result := 'Plact des troupes (Défenseur)';
    gsAttackerMoveOrders: Result := 'Ordres de mvt (Attaquant)';
    gsAttackerMoveExecute: Result := 'Exéc. des mvts (Attaquant)';
    gsAttackerBattleOrders: Result := 'Ordres de combat (Attaquant)';
    gsCheckVictoryAttacker: Result := 'Vérif. victoire (Attaquant)';
    gsDefenderMoveOrders: Result := 'Ordres de mvt (Défenseur)';
    gsDefenderMoveExecute: Result := 'Exéc. des mvts (Défenseur)';
    gsDefenderBattleOrders: Result := 'Ordres de combat (Défenseur)';
    gsCheckVictoryDefender: Result := 'Vérif. victoire (Défenseur)';
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

