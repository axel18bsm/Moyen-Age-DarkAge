unit MessageManager;



{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, raylib, raygui, init;

// Procédures pour gérer les messages
procedure InitializeMessageManager;
procedure AddMessage(msg: string);
procedure DrawMessagePanel;

implementation

var
  Messages: array of string; // Liste des messages pour l'historique
  MessageCount: Integer;     // Nombre de messages dans l'historique
  LastStateMessage: string;  // Dernier message d'état ajouté (pour éviter les répétitions)

// Initialise le gestionnaire de messages
procedure InitializeMessageManager;
begin
  SetLength(Messages, 0);
  MessageCount := 0;
  LastStateMessage := '';
end;

// Ajoute un message à l'historique
procedure AddMessage(msg: string);
begin
  // Ajouter le message uniquement s'il est différent du dernier message d'état
  // ou s'il s'agit d'un message d'action (contenant "déplacée" ou "sélectionnée")
  if (msg <> LastStateMessage) or (Pos('déplacée', msg) > 0) or (Pos('sélectionnée', msg) > 0) then
  begin
    Inc(MessageCount);
    SetLength(Messages, MessageCount);
    Messages[MessageCount - 1] := msg;
    // Mettre à jour LastStateMessage uniquement pour les messages d'état
    if (Pos('déplacée', msg) = 0) and (Pos('sélectionnée', msg) = 0) then
      LastStateMessage := msg;
  end;
end;

// Affiche le panneau défilant pour l'historique des messages
procedure DrawMessagePanel;
var
  panelBounds: TRectangle;
  contentBounds: TRectangle;
  scroll: TVector2;
  view: TRectangle;
  contentHeight: Integer;
  firstVisibleMessage: Integer;
  lastVisibleMessage: Integer;
  i: Integer;
  yMsgPos: Integer;
  scrollResult: Integer;
  visibleMessageCount: Integer;
begin
  if MessageCount > 0 then
  begin
    // Définir le rectangle du panneau en bas de l'écran
    panelBounds := RectangleCreate(leftBorderWidth, screenHeight - bottomBorderHeight, screenWidth - leftBorderWidth - rightBorderWidth, bottomBorderHeight);

    // Calculer la hauteur totale de l'historique des messages (20 pixels par message)
    contentHeight := MessageCount * 20;
    contentBounds := RectangleCreate(0, 0, panelBounds.width - 20, contentHeight); // -20 pour laisser de la place au slider

    // Initialiser le défilement
    scroll := Vector2Create(0, 0);

    // Créer le panneau défilant
    scrollResult := GuiScrollPanel(panelBounds, 'Historique', contentBounds, @scroll, @view);
    if scrollResult <> 0 then
    begin
      // Le panneau a été interactif (par exemple, l'utilisateur a fait défiler)
      // Pas d'action spécifique pour l'instant
    end;

    // Ajuster le défilement pour afficher les derniers messages par défaut
    if scroll.y = 0 then
    begin
      scroll.y := -(contentHeight - panelBounds.height); // Positionner le slider en bas
      if scroll.y > 0 then scroll.y := 0; // Ne pas dépasser le début de la liste
    end;

    // Calculer les messages visibles
    firstVisibleMessage := Trunc(Abs(scroll.y)) div 20;
    lastVisibleMessage := firstVisibleMessage + (Trunc(panelBounds.height) div 20);
    if lastVisibleMessage >= MessageCount then
      lastVisibleMessage := MessageCount - 1;

    // Calculer le nombre de messages visibles
    visibleMessageCount := lastVisibleMessage - firstVisibleMessage + 1;

    // Afficher les messages visibles (du plus ancien au plus récent de haut en bas)
    BeginScissorMode(Round(view.x), Round(view.y), Round(view.width), Round(view.height));
    for i := firstVisibleMessage to lastVisibleMessage do
    begin
      if (i >= 0) and (i < MessageCount) then
      begin
        // Calculer la position Y pour que le message le plus récent soit en bas
        yMsgPos := trunc(panelBounds.y) + (lastVisibleMessage - i) * 20;
        if (yMsgPos >= panelBounds.y) and (yMsgPos < panelBounds.y + panelBounds.height) then
        begin
          GuiLabel(RectangleCreate(panelBounds.x + 10, yMsgPos, panelBounds.width - 30, 20), PChar(Messages[i]));
        end;
      end;
    end;
    EndScissorMode();
  end;
end;

end.

