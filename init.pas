unit Init;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, raylib;

const
  MAX_HEXAGONS = 832; // Nombre total d'hexagones dans le CSV
  MAX_TOURS=15;
  MAX_UNITS = 68; // Nombre total d'unités (40 pour l'attaquant + 28 pour le défenseur)
  CHEMIN_SOLDAT1='resources/soldat/player1/';
  CHEMIN_SOLDAT2='resources/soldat/player2/';
type
  TTupleBooleanString = record
    Success: Boolean;
    Message: String;
  end;
type
  TCombatOrder = record
    TargetID: Integer;      // ID de l'unité cible
    TargetHexID: Integer;   // ID de l'hexagone cible (nouveau champ pour les murs/grilles)
    AttackerIDs: array of Integer; // Liste des attaquants
  end;
type
  TPlayerType = (ptHuman, ptAI); // Type de joueur : Humain ou IA
  TSetupType = (stRandom, stManual); // Type de placement des troupes : Random ou Manuel

  TChemin = record
  chemin: TVector2;   // Coordonnées (x, y) du point
  Hexnet: Integer;    // Hexagone net calculé
  Hexbrut: Integer;   // Hexagone  calculé
end;
  TRiverPair = record
    Id: Integer;      // Identifiant unique de la paire
    Hex1: Integer;    // ID du premier hexagone
    Hex2: Integer;    // ID du deuxième hexagone
  end;
  TObjet = record
    Id: Integer;      // Identifiant unique de l'objet
    Points: Integer;  // Points associés à l'objet
    Objet: PChar;     // Nom de l'objet
  end;

  TArmeeEntry = record
    Id: Integer;         // Numéro d'identification
    NumArmee: Integer;   // Numéro de l'armée (1 = attaquant, 2 = défenseur)
    UniteId: Integer;    // ID du type d'unité (TtpUnite)
    Nombre: Integer;     // Nombre d'unités de ce type
    Nom: string;         // Nom du type d'unité
    FichierE:string;     //nomdufichier entier
    FichierD:string;    //nomdufichier demi
  end;

  TtpUnite = record
    Id: Integer;             // Numéro unique unité
    lenom: PChar;            // Nom de l'unité
    armee: Integer;          // Appartenance (1 = attaquant, 2 = défenseur)
    forceInitiale: Integer;  // Force initiale
    forceDem: Integer;       // Force diminuée (moitié)
    forcedefensive: Integer; // Force défensive
    vitesse: Integer;        // Vitesse de déplacement
    distanceCombatMini:Integer;  // distance minimum combat
    distanceCombatMaxi:Integer;  // distance maximum combat.
  end;
  TUnit = record
    Id: Integer;             // Numéro unique unité
    lenom: PChar;            // Nom de l’unité
    BtnPerim: TRectangle;    // Surface de l’unité
    PositionActuelle: TVector2;// Position
    positionInitiale: TVector2;// Stocker la position initiale
    positionFinale: TVector2; // Destination à atteindre
    vitesseInitiale: Integer; // Vitesse autorisée max
    distanceMaxi: single; // distance maxi corrigée
    numplayer:integer; // 1 pour attaquant, 2 pour défenseur
    Fileimagestr:string;      // facilite la vie !!
    Fileimage: PChar;        // Chemin de mon dessin normal
    FileimageAbime: PChar;   // Chemin de mon dessin abimé
    FileimageAbimeStr: string; // Nouveau champ pour stocker le chemin abîmé
    latexture: TTexture2D;   // Le dessin est stocké
    limage: TImage;          // Nom du fichier normal
    Force: Integer;          // Force de combat
    Forcedmg: Integer;       // force dmg
    DistCombatMax: Integer;     // Distance en hexagone au combat max
    DistCombatMin: Integer;     // Distance en hexagone au combat mini
    EtatUnite: Integer;      // Entière 1/2 force ou kill
    TypeUnite: TtpUnite;     // Type d'unité
    visible: Boolean;        // Suis-je caché
    HexagoneActuel: Integer; // Sur quel terrain, je suis
    HexagonePrevious: Integer; // Hexagone précédent
    HexagoneCible:Integer; // hexagone destination
    selected: Boolean;    // Suis-je cliqué
    hasStopped: Boolean;     // Indicateur d'arrêt
    hasMoved: Boolean;       // Indicateur de mouvement (au moins 1 déplacement)
    MustMove: Boolean;       // Permet de savoir s’il doit démarrer ou pas
    TextureHalfWidth: Integer;  // Moitié de la largeur de la texture (pour centrage)
    TextureHalfHeight: Integer; // Moitié de la hauteur de la texture (pour centrage)
    chemin: array of TChemin; // Tableau dynamique de points
    HasMoveOrder: Boolean;
    CurrentPathIndex: Integer;  // Index actuel dans le tableau chemin
    tourMouvementTermine: Boolean; // Indique si l'unité a terminé son mouvement pour le tour
    HexagoneDepart: Integer; // Hexagone de départ pour les bateaux (96 ou 192)
    IsLoaded: Boolean; // Indique si le bateau est chargé
    IsAttacked: Boolean; // Indique si l'unité a été attaquée ce tour
    HasAttacked: Boolean; // Indique si l'unité a attaqué ce tour
  end;
  TPlayer = record
    PlayerType: TPlayerType; // Humain ou IA
    SetupType: TSetupType;   // Random ou Manuel
    IsAttacker: Boolean;     // True si c'est l'attaquant
    Ravitaillement: Single; // Stock de ravitaillement
    BoatCount: Integer; // Nombre de bateaux actifs sur la mer
  end;


  TGameState = (
  gsInitialization,
  gsSplashScreen,
  gsMainMenu,
  gsNewGameMenu,
  gsSetupAttacker,
  gsSetupDefender,
  gsAttackerMoveOrders,
  gsAttackerMoveExecute,
  gsAttackerBattleOrders,
  gsCheckVictoryAttacker,
  gsDefenderMoveOrders,
  gsDefenderMoveExecute,
  gsDefenderBattleOrders,
  gsCheckVictoryDefender,
  gsGameOver
);

  TTerrainColor = record
    R: Integer;
    G: Integer;
    B: Integer;
  end;

  TTerrainCost = record
    Name: string;            // Nom du terrain (plaine, riviere, etc.)
    MovementCost: Single;    // Coût de mouvement (en points)
    DefenseMultiplier: Single; // Multiplicateur de défense
    IsPassable: Boolean;     // Indique si le terrain est franchissable
    TColor: TTerrainColor;   // Couleur du terrain sur l'image invisible
  end;





  TGameManager = record
    CurrentState: TGameState;  // État actuel du jeu
    PreviousState: TGameState; // État précédent (pour le bouton "Retour")
    SplashScreenImage: TTexture2D;  // Image du splash screen
    SplashScreenTimer: Single;  // Temps écoulé pour le splash screen
    Music: TMusic;              // Musique du splash screen
    MusicPlaying: Boolean;      // État de la musique (joue ou arrêtée)
    Aquitter: Boolean;          // Sortie du jeu
    Attacker: TPlayer;          // Joueur attaquant
    Defender: TPlayer;          // Joueur défenseur
    CurrentTurn: Integer;       // Tour actuel (1 à 15)
    CurrentPlayer: TPlayer;     // Joueur actif (pointe vers Attacker ou Defender)
    AttackerType: LongInt;      // 0 = Humain, 1 = IA
    AttackerSetup: LongInt;     // 0 = Random, 1 = Manuel
    DefenderType: LongInt;      // 0 = Humain, 1 = IA
    DefenderSetup: LongInt;     // 0 = Random, 1 = Manuel
    AttackerUnitsPlaced: Boolean; // Indique si les unités attaquantes ont été positionnées
    DefenderUnitsPlaced: Boolean; // Indique si les unités défenseurs ont été positionnées
    SelectedUnitID: Integer; // ID de l'unité sélectionnée (-1 si aucune unité sélectionnée)
    ErrorMessage: string; // Message d'erreur temporaire pour le GUI bas
    Units: array[1..MAX_UNITS] of TUnit; // Toutes les unités des deux armées
    IsOccupied: Boolean; // Indique si un hexagone est occupé
    HexOccupiedByAttacker: Boolean; // Indique si un hexagone est occupé par une unité attaquante
    IsSpecialUnit: Boolean; // Indique si l'unité est un Lieutenant ou un Duc
    MouseInitialized: Boolean; // Indique si mousePos a été initialisé pour DragAndDropCarte2D
    IsDragging: Boolean; // Indique si un glisser-déposer est en cours
    ShowConfirmDialog: Boolean; // Indique si la boîte de dialogue de confirmation doit être affichée
    Messages: array of string; // Liste des messages pour l'historique
    MessageCount: Integer; // Nombre de messages dans l'historique
    LastStateMessage: string; // Dernier message d'état ajouté (pour éviter les répétitions)
    LastYPos: Integer; // Dernière position Y après l'affichage des informations de l'hexagone et des unités
    LastClickTime: Double; // Temps du dernier clic pour détecter un double-clic
    LastClickedHexID: Integer; // Dernier hexagone cliqué (pour l'affichage dans le GUI droit)
    LastDestinationHexID: Integer; // Hexagone de destination (pour l'affichage dans le GUI droit)
    CurrentUnitIndex: Integer; // Index de l'unité actuellement en cours de traitement dans le cycle
    PlayerTurnProcessed: Boolean; // Indique si les traitements du tour ont été effectués
    CombatOrders: array of TCombatOrder; // Ordres de combat en cours
    VictoryMessage: String;           // Message de victoire
    VictoryHexOccupiedSince: Integer; // Tour où une unité rouge est arrivée sur une case de victoire


  end;

  // Type pour représenter un hexagone
  THexagon = record
    ID: Integer;          // Identifiant unique
    CenterX: Integer;     // Coordonnée X du centre
    CenterY: Integer;     // Coordonnée Y du centre
    ColorR: Integer;      // Couleur R de l'hexagone
    ColorG: Integer;      // Couleur G de l'hexagone
    ColorB: Integer;      // Couleur B de l'hexagone
    ColorPtR: Integer;    // Couleur R du point central (pour type de terrain)
    ColorPtG: Integer;    // Couleur G du point central
    ColorPtB: Integer;    // Couleur B du point central
    BSelected: Boolean;   // Hexagone sélectionné ?
    Colonne: Integer;     // Numéro de colonne
    Ligne: Integer;       // Numéro de ligne
    Emplacement: string;  // Position sur la carte (CoinHG, BordH, etc.)
    PairImpairLigne: Boolean; // Pour calculer les voisins
    Vertex1X, Vertex1Y: Integer; // Sommet 1
    Vertex2X, Vertex2Y: Integer; // Sommet 2
    Vertex3X, Vertex3Y: Integer; // Sommet 3
    Vertex4X, Vertex4Y: Integer; // Sommet 4
    Vertex5X, Vertex5Y: Integer; // Sommet 5
    Vertex6X, Vertex6Y: Integer; // Sommet 6
    Neighbor1: Integer;   // Voisin nord
    Neighbor2: Integer;   // Voisin nord-est
    Neighbor3: Integer;   // Voisin sud-est
    Neighbor4: Integer;   // Voisin sud
    Neighbor5: Integer;   // Voisin sud-ouest
    Neighbor6: Integer;   // Voisin nord-ouest
    Route: Boolean;       // Présence d'une route (oui/non)
    TerrainType: string;  // Type de terrain (plaine, foret, mer, etc.)
    Objet: Integer;       // Objet spécial (5000 = tour, 10000 = case victoire, 0 = rien)
    HasWall: Boolean;     // Présence d'un mur adjacent (basé sur Objet entre 3000 et 4000)
    HasRiver:boolean;     //
    IsCastle: Boolean;    // est ce une case de type chateau
    IsDamaged: Boolean; // mur ou grille
    IsAttacked: Boolean;
  end;


var
  // Taille de la fenêtre
  screenWidth: Integer = 1280;
  screenHeight: Integer = 800;
  // Dimensions des bordures
  leftBorderWidth: Integer = 0;
  topBorderHeight: Integer = 0;
  bottomBorderHeight: Integer = 100;
  rightBorderWidth: Integer = 250;
  camera: TCamera2D;
  image: TImage;
  texture: TTexture2D;
  textureCalque: TTexture2D; // Texture pour newlecalque.png (non visible)
  mousePos, mousePositionmvt: TVector2;
  worldPosition: TVector2;
  calqueImage: TImage; // Image pour newlecalque.png (non visible)
  deltaX, deltaY: Single;
  leftLimit, topLimit, rightLimit, bottomLimit: Single;
  Pchartxt: PChar = 'resources/Carte1870.png'; // Carte principale
  Pchartxt2: PChar;
  // Tableau pour stocker les hexagones
  Hexagons: array[1..MAX_HEXAGONS] of THexagon;
  HexagonCount: Integer; // Nombre d'hexagones chargés
  clickedHexID,i: Integer;
  Game: TGameManager;
  toggleSliderActive: Integer;
  hexInfo: string;
  hexType: string;
  hexObject: string;
  hexwall:string;
  hexriver:string;
  hexcastle:String;
  hexroad:string;
  musicButtonText: string;
  SelectedUnit1: Integer =-1; // ID de la première unité sélectionnée (-1 si aucune)
  SelectedUnit2: Integer =-1; // ID de la deuxième unité sélectionnée (-1 si aucune)
  TerrainCosts: array[1..8] of TTerrainCost; // Tableau fixe pour les 8 types de terrain
  UnitTypes: array[1..17] of TtpUnite; // Tableau fixe pour les 16 types d'unités
  Objets: array[1..6] of TObjet; // Tableau fixe pour les 6 objets
  ArmeeEntries: array[1..17] of TArmeeEntry; // Tableau des entrées du fichier armee.csv
  RiverPairs: array of TRiverPair; // Tableau temporaire pour stocker les paires d'hexagones séparés par une rivière
  drawPos: TVector2;


procedure chargeressource;
procedure initialisezCamera2D;
procedure LoadHexagonsFromCSV(const FileName: string);
procedure InitializeTerrainCosts;
procedure InitializeUnitTypes;
procedure InitializeObjets;
procedure LoadArmeeFromCSV(const FileName: string);
procedure InitializePlayerUnits;
procedure LoadRiverPairsFromCSV;
procedure UpdateHexagonsForRivers;
function GetTerrainCost(terrainType: string): TTerrainCost;

implementation

uses UnitProcFunc;
function GetTerrainCost(terrainType: string): TTerrainCost;
var
  i: Integer;
begin
  Result.MovementCost := 0.0;
  Result.DefenseMultiplier := 1.0;
  Result.IsPassable := False;

  for i := 1 to 8 do
  begin
    if LowerCase(terrainType) = TerrainCosts[i].Name then
    begin
      Result := TerrainCosts[i];
      Exit;
    end;
  end;
end;


procedure UpdateHexagonsForRivers;
var
  i, j: Integer;
  hex1, hex2: Integer;
  neighborID: Integer;
  found: Boolean;
begin
  // Parcourir toutes les paires dans RiverPairs
  for i := 0 to High(RiverPairs) do
  begin
    hex1 := RiverPairs[i].Hex1;
    hex2 := RiverPairs[i].Hex2;

    // Mettre HasRiver à True pour hex1 et mettre à jour ses voisins
    Hexagons[hex1].HasRiver := True;
    found := False;
    for j := 1 to 6 do
    begin
      case j of
        1: neighborID := Hexagons[hex1].Neighbor1;
        2: neighborID := Hexagons[hex1].Neighbor2;
        3: neighborID := Hexagons[hex1].Neighbor3;
        4: neighborID := Hexagons[hex1].Neighbor4;
        5: neighborID := Hexagons[hex1].Neighbor5;
        6: neighborID := Hexagons[hex1].Neighbor6;
      end;

      if neighborID = hex2 then
      begin
        // Ajouter 4000 à l'ID du voisin
        case j of
          1: Hexagons[hex1].Neighbor1 := neighborID + 4000;
          2: Hexagons[hex1].Neighbor2 := neighborID + 4000;
          3: Hexagons[hex1].Neighbor3 := neighborID + 4000;
          4: Hexagons[hex1].Neighbor4 := neighborID + 4000;
          5: Hexagons[hex1].Neighbor5 := neighborID + 4000;
          6: Hexagons[hex1].Neighbor6 := neighborID + 4000;
        end;
        found := True;
        Break;
      end;
    end;
    if not found then
      WriteLn('Erreur : Hexagone ', hex2, ' non trouvé dans les voisins de ', hex1);

    // Mettre HasRiver à True pour hex2 et mettre à jour ses voisins
    Hexagons[hex2].HasRiver := True;
    found := False;
    for j := 1 to 6 do
    begin
      case j of
        1: neighborID := Hexagons[hex2].Neighbor1;
        2: neighborID := Hexagons[hex2].Neighbor2;
        3: neighborID := Hexagons[hex2].Neighbor3;
        4: neighborID := Hexagons[hex2].Neighbor4;
        5: neighborID := Hexagons[hex2].Neighbor5;
        6: neighborID := Hexagons[hex2].Neighbor6;
      end;

      if neighborID = hex1 then
      begin
        // Ajouter 4000 à l'ID du voisin
        case j of
          1: Hexagons[hex2].Neighbor1 := neighborID + 4000;
          2: Hexagons[hex2].Neighbor2 := neighborID + 4000;
          3: Hexagons[hex2].Neighbor3 := neighborID + 4000;
          4: Hexagons[hex2].Neighbor4 := neighborID + 4000;
          5: Hexagons[hex2].Neighbor5 := neighborID + 4000;
          6: Hexagons[hex2].Neighbor6 := neighborID + 4000;
        end;
        found := True;
        Break;
      end;
    end;
    if not found then
      WriteLn('Erreur : Hexagone ', hex1, ' non trouvé dans les voisins de ', hex2);
  end;

  WriteLn('Mise à jour des hexagones pour les rivières terminée');
end;

procedure LoadRiverPairsFromCSV;
var
  fileText: TStringList;
  i: Integer;
  line: string;
  values: TStringArray;
begin
  fileText := TStringList.Create;
  try
    fileText.LoadFromFile('resources/rivers.csv');
    SetLength(RiverPairs, fileText.Count - 1); // Exclure l'en-tête

    for i := 1 to fileText.Count - 1 do
    begin
      line := fileText[i];
      values := line.Split(',');
      if Length(values) >= 3 then // Vérifier que la ligne a assez de colonnes
      begin
        RiverPairs[i - 1].Id := StrToIntDef(values[0], 0);
        RiverPairs[i - 1].Hex1 := StrToIntDef(values[1], 0);
        RiverPairs[i - 1].Hex2 := StrToIntDef(values[2], 0);
      end;
    end;
  finally
    fileText.Free;
  end;
  WriteLn('Chargé ', Length(RiverPairs), ' paires d''hexagones séparés par une rivière depuis rivers.csv');
end;


 procedure InitializePlayerUnits;
var
  i, k, unitCount: Integer;
  filePathAbime: string;
  defaultImage: TImage;
begin
  unitCount := 0;

  // Charger une image par défaut
  defaultImage := LoadImage('resources/soldat/default.png'); // À remplacer par un fichier réel
  if defaultImage.data = nil then
    WriteLn('ERREUR: InitializePlayerUnits - Impossible de charger l''image par défaut');

  // Initialiser toutes les unités dans l'ordre (attaquant puis défenseur)
  for i := 1 to 17 do // 17 entrées dans ArmeeEntries
  begin
    // Vérifier FichierD pour débogage
    WriteLn('DEBUG: InitializePlayerUnits - Type unité ', i, ', FichierD=', ArmeeEntries[i].FichierD);

    // Créer le nombre d'unités spécifié
    for k := 1 to ArmeeEntries[i].Nombre do
    begin
      unitCount := unitCount + 1;
      Game.Units[unitCount].Id := unitCount;
      Game.Units[unitCount].TypeUnite := UnitTypes[i];
      Game.Units[unitCount].lenom := unitTypes[i].lenom;
      Game.Units[unitCount].numplayer := ArmeeEntries[i].NumArmee; // 1 pour attaquant, 2 pour défenseur
      Game.Units[unitCount].Force := UnitTypes[i].forceInitiale;
      Game.Units[unitCount].Forcedmg := UnitTypes[i].forceDem;
      Game.Units[unitCount].DistCombatMax := UnitTypes[i].distanceCombatMaxi;
      Game.Units[unitCount].DistCombatMin := UnitTypes[i].distanceCombatMini;
      Game.Units[unitCount].EtatUnite := 1; // Entière
      Game.Units[unitCount].vitesseInitiale := UnitTypes[i].vitesse;
      Game.Units[unitCount].distanceMaxi := Game.Units[unitCount].vitesseInitiale;
      Game.Units[unitCount].visible := True;
      Game.Units[unitCount].HexagoneActuel := -1; // Pas encore positionné
      Game.Units[unitCount].HexagonePrevious := -1;
      Game.Units[unitCount].HexagoneCible := -1;
      Game.Units[unitCount].selected := False;
      Game.Units[unitCount].hasStopped := False;
      Game.Units[unitCount].hasMoved := False;
      Game.Units[unitCount].MustMove := False;
      Game.Units[unitCount].BtnPerim := RectangleCreate(0, 0, 0, 0);
      Game.Units[unitCount].PositionActuelle := Vector2Create(0, 0);
      Game.Units[unitCount].positionInitiale := Vector2Create(0, 0);
      Game.Units[unitCount].positionFinale := Vector2Create(0, 0);
      Game.Units[unitCount].IsAttacked := False;
      Game.Units[unitCount].HasAttacked := False;

      if unitCount in [67, 68] then
      begin
        Game.Units[unitCount].HexagoneDepart := -1; // Sera défini lors du placement
        Game.Units[unitCount].IsLoaded := True; // Chargé par défaut
      end;

      // Charger les images
      if Game.Units[unitCount].numplayer = 1 then
      begin
        Game.Units[unitCount].Fileimagestr := CHEMIN_SOLDAT1;
      end
      else
      begin
        Game.Units[unitCount].Fileimagestr := CHEMIN_SOLDAT2;
      end;
      Game.Units[unitCount].Fileimagestr := Game.Units[unitCount].Fileimagestr + ArmeeEntries[i].FichierE; // Chemin de l'image normale
      Game.Units[unitCount].Fileimage := PChar(Game.Units[unitCount].Fileimagestr);
      WriteLn('DEBUG: InitializePlayerUnits - Unité ', unitCount, ', Image normale : ', Game.Units[unitCount].Fileimage);

      // Construire le chemin complet pour l'image abîmée
      if Game.Units[unitCount].numplayer = 1 then
      begin
        filePathAbime := CHEMIN_SOLDAT1 + ArmeeEntries[i].FichierD;
      end
      else
      begin
        filePathAbime := CHEMIN_SOLDAT2 + ArmeeEntries[i].FichierD;
      end;
      Game.Units[unitCount].FileimageAbimeStr := filePathAbime; // Stocker une copie
      Game.Units[unitCount].FileimageAbime := PChar(Game.Units[unitCount].FileimageAbimeStr);
      WriteLn('DEBUG: InitializePlayerUnits - Unité ', unitCount, ', Image abîmée : ', Game.Units[unitCount].FileimageAbimeStr);



      // Charger l'image et la texture
      Game.Units[unitCount].limage := LoadImage(Game.Units[unitCount].Fileimage);
      if Game.Units[unitCount].limage.data = nil then
      begin
        WriteLn('Erreur : Impossible de charger l''image ', Game.Units[unitCount].Fileimage, ' pour l''unité ', unitCount);
        Game.Units[unitCount].limage := defaultImage;
      end;

      Game.Units[unitCount].latexture := LoadTextureFromImage(Game.Units[unitCount].limage);
      if Game.Units[unitCount].latexture.id = 0 then
      begin
        WriteLn('Erreur : Impossible de charger la texture pour l''unité ', unitCount);
        Game.Units[unitCount].latexture := LoadTextureFromImage(defaultImage);
      end;

      // Calculer la moitié de la largeur et de la hauteur de la texture
      Game.Units[unitCount].TextureHalfWidth := Game.Units[unitCount].latexture.width div 2;
      Game.Units[unitCount].TextureHalfHeight := Game.Units[unitCount].latexture.height div 2;

      // Mettre à jour BtnPerim (initialement à (0, 0))
      UpdateUnitBtnPerim(unitCount);

      SetLength(Game.Units[unitCount].chemin, 0);
    end;
  end;

  // Décharger l'image par défaut
  if defaultImage.data <> nil then
    UnloadImage(defaultImage);
end;



procedure LoadArmeeFromCSV(const FileName: string);
var
  fileText: TStringList;
  i: Integer;
  line: string;
  values: TStringArray;
begin
  fileText := TStringList.Create;
  try
    fileText.LoadFromFile(FileName);
    for i := 1 to fileText.Count - 1 do
    begin
      line := fileText[i];
      values := line.Split(',');
      if Length(values) >= 7 then // Vérifier que la ligne a assez de colonnes
      begin
        ArmeeEntries[i].Id := StrToIntDef(values[0], 0);
        ArmeeEntries[i].NumArmee := StrToIntDef(values[1], 0);
        ArmeeEntries[i].UniteId := StrToIntDef(values[2], 0);
        ArmeeEntries[i].Nombre := StrToIntDef(values[3], 0);
        ArmeeEntries[i].Nom := values[4];
        ArmeeEntries[i].FichierE := values[5];
        ArmeeEntries[i].FichierD := values[6];
      end;
    end;
  finally
    fileText.Free;
  end;
  WriteLn('Chargé  entrées d''armée');
end;
procedure InitializeObjets;
begin
  // Tour
  Objets[1].Id := 1;
  Objets[1].Points := 5000;
  Objets[1].Objet := 'tour';

  // Mur
  Objets[2].Id := 2;
  Objets[2].Points := 1000;
  Objets[2].Objet := 'mur';

  // Victoire
  Objets[3].Id := 3;
  Objets[3].Points := 10000;
  Objets[3].Objet := 'Victoire';

  // Pont
  Objets[4].Id := 4;
  Objets[4].Points := 2000;
  Objets[4].Objet := 'pont';

  // Grille
  Objets[5].Id := 5;
  Objets[5].Points := 3000;
  Objets[5].Objet := 'grille';

  // Rivière
  Objets[6].Id := 6;
  Objets[6].Points := 4000;
  Objets[6].Objet := 'riviere';
end;

procedure InitializeUnitTypes;
begin
  // Attaquant (armee = 1)
  UnitTypes[1].Id := 1;
  UnitTypes[1].lenom := 'infanterie';
  UnitTypes[1].armee := 1;
  UnitTypes[1].forceInitiale := 6;
  UnitTypes[1].forceDem := 3;
  UnitTypes[1].forcedefensive := 0;
  UnitTypes[1].vitesse := 5;
  UnitTypes[1].distanceCombatMaxi := 1;
  UnitTypes[1].distanceCombatMini := 1;

  UnitTypes[2].Id := 2;
  UnitTypes[2].lenom := 'archer';
  UnitTypes[2].armee := 1;
  UnitTypes[2].forceInitiale := 4;
  UnitTypes[2].forceDem := 2;
  UnitTypes[2].forcedefensive := 0;
  UnitTypes[2].vitesse := 5;
  UnitTypes[2].distanceCombatMaxi := 2;
  UnitTypes[2].distanceCombatMini := 1;

  UnitTypes[3].Id := 3;
  UnitTypes[3].lenom := 'cavalier';
  UnitTypes[3].armee := 1;
  UnitTypes[3].forceInitiale := 6;
  UnitTypes[3].forceDem := 3;
  UnitTypes[3].forcedefensive := 0;
  UnitTypes[3].vitesse := 8;
  UnitTypes[3].distanceCombatMaxi := 1;
  UnitTypes[3].distanceCombatMini := 1;

  UnitTypes[4].Id := 4;
  UnitTypes[4].lenom := 'duc';
  UnitTypes[4].armee := 1;
  UnitTypes[4].forceInitiale := 1;
  UnitTypes[4].forceDem := 1;
  UnitTypes[4].forcedefensive := 0;
  UnitTypes[4].vitesse := 8;
  UnitTypes[4].distanceCombatMaxi := 1;
  UnitTypes[4].distanceCombatMini := 1;

  UnitTypes[5].Id := 5;
  UnitTypes[5].lenom := 'lieutenant';
  UnitTypes[5].armee := 1;
  UnitTypes[5].forceInitiale := 1;
  UnitTypes[5].forceDem := 1;
  UnitTypes[5].forcedefensive := 0;
  UnitTypes[5].vitesse := 6;
  UnitTypes[5].distanceCombatMaxi := 1;
  UnitTypes[5].distanceCombatMini := 1;

  UnitTypes[6].Id := 6;
  UnitTypes[6].lenom := 'trebuchet';
  UnitTypes[6].armee := 1;
  UnitTypes[6].forceInitiale := 3;
  UnitTypes[6].forceDem := 2;
  UnitTypes[6].forcedefensive := 0;
  UnitTypes[6].vitesse := 3;
  UnitTypes[6].distanceCombatMaxi := 4;
  UnitTypes[6].distanceCombatMini := 2;

  UnitTypes[7].Id := 7;
  UnitTypes[7].lenom := 'belier';
  UnitTypes[7].armee := 1;
  UnitTypes[7].forceInitiale := 2;
  UnitTypes[7].forceDem := 1;
  UnitTypes[7].forcedefensive := 0;
  UnitTypes[7].vitesse := 3;
  UnitTypes[7].distanceCombatMaxi := 1;
  UnitTypes[7].distanceCombatMini := 1;

  UnitTypes[8].Id := 8;
  UnitTypes[8].lenom := 'beffroi';
  UnitTypes[8].armee := 1;
  UnitTypes[8].forceInitiale := 0;
  UnitTypes[8].forceDem := 0;
  UnitTypes[8].forcedefensive := 0;
  UnitTypes[8].vitesse := 2;
  UnitTypes[8].distanceCombatMaxi := 0;
  UnitTypes[8].distanceCombatMini := 0;

  UnitTypes[9].Id := 9;
  UnitTypes[9].lenom := 'bateau';
  UnitTypes[9].armee := 1;
  UnitTypes[9].forceInitiale := 4;
  UnitTypes[9].forceDem := 2;
  UnitTypes[9].forcedefensive := 0;
  UnitTypes[9].vitesse := 5;
  UnitTypes[9].distanceCombatMaxi := 1;
  UnitTypes[9].distanceCombatMini := 1;

  // Défenseur (armee = 2)
  UnitTypes[10].Id := 10;
  UnitTypes[10].lenom := 'infanterie';
  UnitTypes[10].armee := 2;
  UnitTypes[10].forceInitiale := 6;
  UnitTypes[10].forceDem := 3;
  UnitTypes[10].forcedefensive := 0;
  UnitTypes[10].vitesse := 5;
  UnitTypes[10].distanceCombatMaxi := 1;
  UnitTypes[10].distanceCombatMini := 1;

  UnitTypes[11].Id := 11;
  UnitTypes[11].lenom := 'archer';
  UnitTypes[11].armee := 2;
  UnitTypes[11].forceInitiale := 4;
  UnitTypes[11].forceDem := 2;
  UnitTypes[11].forcedefensive := 0;
  UnitTypes[11].vitesse := 5;
  UnitTypes[11].distanceCombatMaxi := 2;
  UnitTypes[11].distanceCombatMini := 1;

  UnitTypes[12].Id := 12;
  UnitTypes[12].lenom := 'cavalier';
  UnitTypes[12].armee := 2;
  UnitTypes[12].forceInitiale := 6;
  UnitTypes[12].forceDem := 3;
  UnitTypes[12].forcedefensive := 0;
  UnitTypes[12].vitesse := 8;
  UnitTypes[12].distanceCombatMaxi := 1;
  UnitTypes[12].distanceCombatMini := 1;

  UnitTypes[13].Id := 13;
  UnitTypes[13].lenom := 'comte';
  UnitTypes[13].armee := 2;
  UnitTypes[13].forceInitiale := 1;
  UnitTypes[13].forceDem := 1;
  UnitTypes[13].forcedefensive := 0;
  UnitTypes[13].vitesse := 8;
  UnitTypes[13].distanceCombatMaxi := 1;
  UnitTypes[13].distanceCombatMini := 1;

  UnitTypes[14].Id := 14;
  UnitTypes[14].lenom := 'Chef Milicien';
  UnitTypes[14].armee := 2;
  UnitTypes[14].forceInitiale := 1;
  UnitTypes[14].forceDem := 1;
  UnitTypes[14].forcedefensive := 0;
  UnitTypes[14].vitesse := 6;
  UnitTypes[14].distanceCombatMaxi := 1;
  UnitTypes[14].distanceCombatMini := 1;

  UnitTypes[15].Id := 15;
  UnitTypes[15].lenom := 'trebuchet';
  UnitTypes[15].armee := 2;
  UnitTypes[15].forceInitiale := 3;
  UnitTypes[15].forceDem := 2;
  UnitTypes[15].forcedefensive := 0;
  UnitTypes[15].vitesse := 3;
  UnitTypes[15].distanceCombatMaxi := 4;
  UnitTypes[15].distanceCombatMini := 2;

  UnitTypes[16].Id := 16;
  UnitTypes[16].lenom := 'milicien';
  UnitTypes[16].armee := 2;
  UnitTypes[16].forceInitiale := 5;
  UnitTypes[16].forceDem := 2;
  UnitTypes[16].forcedefensive := 0;
  UnitTypes[16].vitesse := 5;
  UnitTypes[16].distanceCombatMaxi := 1;
  UnitTypes[16].distanceCombatMini := 1;

  UnitTypes[17].Id := 17;
  UnitTypes[17].lenom := 'bateau';
  UnitTypes[17].armee := 2;
  UnitTypes[17].forceInitiale := 4;
  UnitTypes[17].forceDem := 2;
  UnitTypes[17].forcedefensive := 0;
  UnitTypes[17].vitesse := 5;
  UnitTypes[17].distanceCombatMaxi := 1;
  UnitTypes[17].distanceCombatMini := 1;
end;

procedure InitializeTerrainCosts;
begin
  // Plaine
  TerrainCosts[1].Name := 'plaine';
  TerrainCosts[1].MovementCost := 1.0;
  TerrainCosts[1].DefenseMultiplier := 1.0;
  TerrainCosts[1].IsPassable := True;
  TerrainCosts[1].TColor.R := 255;
  TerrainCosts[1].TColor.G := 255;
  TerrainCosts[1].TColor.B := 255;

  // Pente
  TerrainCosts[2].Name := 'pente';
  TerrainCosts[2].MovementCost := 2.0;
  TerrainCosts[2].DefenseMultiplier := 1.0;
  TerrainCosts[2].IsPassable := True;
  TerrainCosts[2].TColor.R := 255;
  TerrainCosts[2].TColor.G := 209;
  TerrainCosts[2].TColor.B := 47;

  // Forêt
  TerrainCosts[3].Name := 'foret';
  TerrainCosts[3].MovementCost := 4.0;
  TerrainCosts[3].DefenseMultiplier := 2.0;
  TerrainCosts[3].IsPassable := True;
  TerrainCosts[3].TColor.R := 0;
  TerrainCosts[3].TColor.G := 0;
  TerrainCosts[3].TColor.B := 0;

  // Route
  TerrainCosts[4].Name := 'route';
  TerrainCosts[4].MovementCost := 0.5;
  TerrainCosts[4].DefenseMultiplier := 1.0;
  TerrainCosts[4].IsPassable := True;
  TerrainCosts[4].TColor.R := 204;
  TerrainCosts[4].TColor.G := 204;
  TerrainCosts[4].TColor.B := 204;

  // Ville
  TerrainCosts[5].Name := 'ville';
  TerrainCosts[5].MovementCost := 2.0;
  TerrainCosts[5].DefenseMultiplier := 2.0;
  TerrainCosts[5].IsPassable := True;
  TerrainCosts[5].TColor.R := 207;
  TerrainCosts[5].TColor.G := 9;
  TerrainCosts[5].TColor.B := 255;

  // Rivière (franchissable uniquement sur un pont)
  TerrainCosts[6].Name := 'riviere';
  TerrainCosts[6].MovementCost := 1.0;
  TerrainCosts[6].DefenseMultiplier := 1.0;
  TerrainCosts[6].IsPassable := False;
  TerrainCosts[6].TColor.R := 0;
  TerrainCosts[6].TColor.G := 162;
  TerrainCosts[6].TColor.B := 232;

  // Lac (franchissable uniquement en bateau)
  TerrainCosts[7].Name := 'mer';
  TerrainCosts[7].MovementCost := 1.0;
  TerrainCosts[7].DefenseMultiplier := 1.0;
  TerrainCosts[7].IsPassable := True; // Franchissable uniquement pour les bateaux
  TerrainCosts[7].TColor.R := 153;
  TerrainCosts[7].TColor.G := 217;
  TerrainCosts[7].TColor.B := 234;

  // Muraille
  TerrainCosts[8].Name := 'muraille';
  TerrainCosts[8].MovementCost := 0.0;
  TerrainCosts[8].DefenseMultiplier := 1.0;
  TerrainCosts[8].IsPassable := False;
  TerrainCosts[8].TColor.R := 237;
  TerrainCosts[8].TColor.G := 28;
  TerrainCosts[8].TColor.B := 36;
end;

procedure chargeressource;
begin
  UnloadTexture(texture); // Libérer l'ancienne texture
  image := LoadImage('resources/newlacarte.png');
  if image.data = nil then
  begin
    WriteLn('Erreur : Impossible de charger l''image resources/newlacarte.png');
    Exit;
  end;
  texture := LoadTextureFromImage(image);
  if texture.id = 0 then
  begin
    WriteLn('Erreur : Impossible de charger la texture resources/newlacarte.png');
    Exit;
  end;
  UnloadImage(image); // Libérer l'image après conversion
  Game.Aquitter := False;
  LoadHexagonsFromCSV('resources/hexgridplat.csv');
  DetectWalls(); // Détecter les murs après le chargement des hexagones
  //MarkCastleHexagons; // trouve les cases chateau;
  InitializeTerrainCosts(); // Initialiser les coûts de déplacement
  InitializeUnitTypes(); // Initialiser les types d'unités
  InitializeObjets(); // Initialiser les objets et points
  LoadArmeeFromCSV('resources/armee.csv'); // Charger les données des armées
  InitializePlayerUnits(); // Initialiser les unités des joueurs
  //DetectRiverPairsAndSave(); // Détecter les paires d'hexagones séparés par une rivière et sauvegarder
  // ne pas detruire, permet de trouver les rivieres
  LoadRiverPairsFromCSV(); // Charger les paires depuis rivers.csv
  UpdateHexagonsForRivers(); // Mettre à jour les hexagones pour les rivières
end;

procedure initialisezCamera2D;
begin
  // Initialiser la caméra 2D
  camera.target := Vector2Create(texture.width / 2, texture.height / 2); // Centrer sur l'image

  // Ajuster l'offset pour centrer la carte dans la fenêtre, en tenant compte des bordures
  camera.offset := Vector2Create(
    (screenWidth - rightBorderWidth - leftBorderWidth) / 2,
    (screenHeight - bottomBorderHeight - topBorderHeight) / 2
  );

  camera.rotation := 0;
  camera.zoom := 1.0;

  // Définir les limites de défilement pour éviter le hors zone
  leftLimit := (screenWidth - rightBorderWidth - leftBorderWidth) / 2 / camera.zoom;
  topLimit := (screenHeight - bottomBorderHeight - topBorderHeight) / 2 / camera.zoom;
  rightLimit := texture.width - (screenWidth - rightBorderWidth - leftBorderWidth) / 2 / camera.zoom;
  bottomLimit := texture.height - (screenHeight - bottomBorderHeight - topBorderHeight) / 2 / camera.zoom;
end;

procedure LoadHexagonsFromCSV(const FileName: string);
var
  fileText: TStringList;
  i: Integer;
  line: string;
  values: TStringArray;
begin
  fileText := TStringList.Create;
  try
    fileText.LoadFromFile(FileName);
    HexagonCount := fileText.Count - 1; // Exclure l'en-tête
    if HexagonCount > MAX_HEXAGONS then
      HexagonCount := MAX_HEXAGONS; // Limiter au maximum

    for i := 1 to HexagonCount do
    begin
      line := fileText[i];
      values := line.Split(';');
      if Length(values) >= 35 then // Vérifier que la ligne a assez de colonnes
      begin
        Hexagons[i].ID := StrToIntDef(values[0], -1);
        Hexagons[i].CenterX := StrToIntDef(values[2], 0);
        Hexagons[i].CenterY := StrToIntDef(values[3], 0);
        Hexagons[i].ColorR := StrToIntDef(values[4], 0);
        Hexagons[i].ColorG := StrToIntDef(values[5], 0);
        Hexagons[i].ColorB := StrToIntDef(values[6], 0);
        Hexagons[i].ColorPtR := StrToIntDef(values[7], 0);
        Hexagons[i].ColorPtG := StrToIntDef(values[8], 0);
        Hexagons[i].ColorPtB := StrToIntDef(values[9], 0);
        Hexagons[i].BSelected := StrToBoolDef(values[10], False);
        Hexagons[i].Colonne := StrToIntDef(values[11], 0);
        Hexagons[i].Ligne := StrToIntDef(values[12], 0);
        Hexagons[i].Emplacement := values[13];
        Hexagons[i].PairImpairLigne := StrToBoolDef(values[14], False);
        Hexagons[i].Vertex1X := StrToIntDef(values[15], 0);
        Hexagons[i].Vertex1Y := StrToIntDef(values[16], 0);
        Hexagons[i].Vertex2X := StrToIntDef(values[17], 0);
        Hexagons[i].Vertex2Y := StrToIntDef(values[18], 0);
        Hexagons[i].Vertex3X := StrToIntDef(values[19], 0);
        Hexagons[i].Vertex3Y := StrToIntDef(values[20], 0);
        Hexagons[i].Vertex4X := StrToIntDef(values[21], 0);
        Hexagons[i].Vertex4Y := StrToIntDef(values[22], 0);
        Hexagons[i].Vertex5X := StrToIntDef(values[23], 0);
        Hexagons[i].Vertex5Y := StrToIntDef(values[24], 0);
        Hexagons[i].Vertex6X := StrToIntDef(values[25], 0);
        Hexagons[i].Vertex6Y := StrToIntDef(values[26], 0);
        Hexagons[i].Neighbor1 := StrToIntDef(values[27], 0);
        Hexagons[i].Neighbor2 := StrToIntDef(values[28], 0);
        Hexagons[i].Neighbor3 := StrToIntDef(values[29], 0);
        Hexagons[i].Neighbor4 := StrToIntDef(values[30], 0);
        Hexagons[i].Neighbor5 := StrToIntDef(values[31], 0);
        Hexagons[i].Neighbor6 := StrToIntDef(values[32], 0);
        Hexagons[i].Route := (values[33] = 'oui');
        Hexagons[i].TerrainType := values[34];
        Hexagons[i].Objet := StrToIntDef(values[35], 0);
        Hexagons[i].IsCastle := (values[36] = 'oui'); // Initialiser à False, sera mis à jour après
        Hexagons[i].HasWall := False; // Initialiser à False, sera mis à jour après
        Hexagons[i].HasRiver := False; // Initialiser à False, sera mis à jour après
        Hexagons[i].IsDamaged := False; // Initialiser l’état endommagé à False
        Hexagons[i].IsAttacked := False; // Initialiser l’état attaqué à False
      end;
    end;
  finally
    fileText.Free;
  end;
  WriteLn('Chargé ', HexagonCount, ' hexagones');
end;

end.
