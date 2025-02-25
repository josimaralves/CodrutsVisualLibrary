unit Cod.Visual.SplashScreen;

interface

uses
  SysUtils,
  Windows,
  Classes,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.ExtCtrls,
  Cod.Graphics,
  Types,
  Consts,
  Forms,
  Winapi.Messages,
  Messaging,
  Winapi.UxTheme,
  Vcl.TitleBarCtrls,
  Cod.Math,
  Cod.Types,
  Cod.Components;

type
  CSplashScreen = class;

  CSplashScreenSizingMode = (szmForm, szmAlign, smzNone);
  CSplashScreenDoneSetup = procedure(Sender: CSplashScreen) of object;
  CSplashScreenFinalise = procedure(Sender: CSplashScreen) of object;

  CSplashScreen = class(TCustomControl)
  private
    FPicture: TPicture;
    FOnFindGraphicClass: TFindGraphicClassEvent;
    FIncrementalDisplay: Boolean;
    FTransparent: Boolean;
    FDrawing: Boolean;
    FMaxSize: integer;
    FExecuted: boolean;
    FDuration: integer;
    FTimer: TTimer;
    FSizeMode: CSplashScreenSizingMode;
    FOnSetupComplete: CSplashScreenDoneSetup;
    FOnFinalise: CSplashScreenFinalise;
    FTitleBar: TTitleBarPanel;

    procedure PictureChanged(Sender: TObject);
    procedure SetPicture(Value: TPicture);
    procedure SetTransparent(Value: Boolean);
    procedure PrepareStart;

    procedure EndViewDuration(Sender: TObject);

  protected
    function DestRect: TRect;
    function DoPaletteChange: Boolean;
    procedure Paint; override;

    procedure FindGraphicClass(Sender: TObject; const Context: TFindGraphicClassContext;
      var GraphicClass: TGraphicClass); dynamic;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure InvalidateControl;

    procedure EndScreen;

  published
    property Enabled;
    property Color;
    property ParentColor;
    property Duration: integer read FDuration write FDuration;
    property IncrementalDisplay: Boolean read FIncrementalDisplay write FIncrementalDisplay default False;
    property Picture: TPicture read FPicture write SetPicture;
    property PopupMenu;
    property ShowHint;
    property SuperiorCustomTitleBar: TTitleBarPanel read FTitleBar write FTitleBar;
    property OnFinalise: CSplashScreenFinalise read FOnFinalise write FOnFinalise;
    property OnCompleteSetup: CSplashScreenDoneSetup read FOnSetupComplete write FOnSetupComplete;
    property Transparent: Boolean read FTransparent write SetTransparent default False;
    property SizingMode: CSplashScreenSizingMode read FSizeMode write FSizeMode;
    property Visible;
    property OnClick;
    property MaximumImageSize: integer read FMaxSize write FMaxSize;
    property OnFindGraphicClass: TFindGraphicClassEvent read FOnFindGraphicClass write FOnFindGraphicClass;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

{ CSplashScreen }

procedure CSplashScreen.CMStyleChanged(var Message: TMessage);
var
  G: TGraphic;
begin
  inherited;
  if Transparent then
  begin
    G := Picture.Graphic;
    if (G <> nil) and not ((G is TMetaFile) or (G is TIcon)) and G.Transparent then
    begin
      G.Transparent := False;
      G.Transparent := True;
    end;
  end;
end;

constructor CSplashScreen.Create(AOwner: TComponent);
begin
  inherited;
  FPicture := TPicture.Create;
  FPicture.OnChange := PictureChanged;
  FPicture.OnFindGraphicClass := FindGraphicClass;

  ParentBackground := false;

  FExecuted := false;

  FDuration := 3000;

  FTimer := TTimer.Create(Self);
  with FTimer do begin
    Interval := FDuration;

    OnTimer := EndViewDuration;

    Enabled := false;
  end;

  FSizeMode := szmForm;

  Width := 75;
  Height := 75;
end;

function CSplashScreen.DestRect: TRect;
var
  MRect: TRect;
begin
  MRect := Rect(0, 0, Width, Height);

  if Picture.Graphic <> nil then
    Result := GetDrawModeRect(MRect, Picture.Graphic, TDrawMode.Center)
  else
    Result := MRect;
end;

destructor CSplashScreen.Destroy;
begin
  FPicture.Free;
  FreeAndNil(FTimer);
  inherited;
end;

function CSplashScreen.DoPaletteChange: Boolean;
var
  ParentForm: TCustomForm;
  Tmp: TGraphic;
begin
  Result := False;
  Tmp := Picture.Graphic;
  if Visible and (not (csLoading in ComponentState)) and (Tmp <> nil) and
    (Tmp.PaletteModified) then
  begin
    if (Tmp.Palette = 0) then
      Tmp.PaletteModified := False
    else
    begin
      ParentForm := GetParentForm(Self);
      if Assigned(ParentForm) and ParentForm.Active and Parentform.HandleAllocated then
      begin
        if FDrawing then
          ParentForm.Perform(wm_QueryNewPalette, 0, 0)
        else
          PostMessage(ParentForm.Handle, wm_QueryNewPalette, 0, 0);
        Result := True;
        Tmp.PaletteModified := False;
      end;
    end;
  end;
end;

procedure CSplashScreen.EndScreen;
begin
  // Finalise
  Self.Visible := false;

  FTimer.Enabled := false;

  if Assigned(FOnFinalise) then
    FOnFinalise(Self);
end;

procedure CSplashScreen.EndViewDuration(Sender: TObject);
begin
  EndScreen;
end;

procedure CSplashScreen.FindGraphicClass(Sender: TObject;
  const Context: TFindGraphicClassContext; var GraphicClass: TGraphicClass);
begin
    if Assigned(FOnFindGraphicClass) then FOnFindGraphicClass(Sender, Context, GraphicClass);
end;

procedure CSplashScreen.InvalidateControl;
begin
  Self.Invalidate;

  Paint;
end;

procedure CSplashScreen.Paint;
  procedure DoBufferedPaint(Canvas: TCanvas);
  var
    MemDC: HDC;
    Rect: TRect;
    PaintBuffer: HPAINTBUFFER;
  begin
    Rect := DestRect;
    PaintBuffer := BeginBufferedPaint(Canvas.Handle, Rect, BPBF_TOPDOWNDIB, nil, MemDC);
    try
      Canvas.Handle := MemDC;
      Canvas.StretchDraw(DestRect, Picture.Graphic);
      BufferedPaintMakeOpaque(PaintBuffer, Rect);
    finally
      EndBufferedPaint(PaintBuffer, True);
    end;
  end;

  function GetParentClientSize(Control: TControl): TPoint; {inline;}
  var
    LParent: TWinControl;
  begin
    LParent := Control.Parent;
    Result := Point(LParent.Width, LParent.Height);
    Dec(Result.X, LParent.Padding.Left + LParent.Padding.Right);
    Dec(Result.Y, LParent.Padding.Top + LParent.Padding.Bottom);
  end;

var
  Save: Boolean;
  s: string;
  FRect: TRect;
  sz: TPoint;
begin
  if csDesigning in ComponentState then
    with inherited Canvas do
    begin
      Pen.Style := psDash;
      Brush.Style := bsClear;
      Rectangle(0, 0, Width, Height);

      s := 'Splash Screen';

      TextOut(Width div 2- TextWidth(s) div 2, Height div 2 - TextHeight(s) div 2, s);
    end;
      // 1st Setup
      if NOT (csDesigning in ComponentState) and Enabled then
      begin
        PrepareStart;

        // Sizing
        if FSizeMode = szmForm then
        begin
          Left := 0;
          Top := 0;

          sz := GetParentClientSize(Self);
          Width := sz.X;
          Height := sz.Y;
        end;
      end;



      // Draw
      Save := FDrawing;
      FDrawing := True;
      try
        if (csGlassPaint in ControlState) and (Picture.Graphic <> nil) and
           not Picture.Graphic.SupportsPartialTransparency then
          DoBufferedPaint(inherited Canvas)
        else
          with inherited Canvas do
            begin
              // Begin Draw
              if NOT Transparent then
                begin
                  Brush.Color := Color;
                  FillRect(ClipRect);
                end;

              FRect := DestRect;

                if (FRect.Height > FMaxSize) and (FRect.Width > FMaxSize) and (FMaxSize > 0) then
                begin
                  FRect.Height := FMaxSize;
                  FRect.Width := trunc(FMaxSize / Picture.Graphic.Height * Picture.Graphic.Width);

                  CenterRectInRect(FRect, Rect(0, 0, Width, Height) );
                end;

              StretchDraw(FRect, Picture.Graphic);
            end;
      finally
        FDrawing := Save;
      end;
end;

procedure CSplashScreen.PictureChanged(Sender: TObject);
var
  G: TGraphic;
  D : TRect;
begin
  if Observers.IsObserving(TObserverMapping.EditLinkID) then
    if TLinkObservers.EditLinkEdit(Observers) then
      TLinkObservers.EditLinkModified(Observers);

  if AutoSize and (Picture.Width > 0) and (Picture.Height > 0) then
	SetBounds(Left, Top, Picture.Width, Picture.Height);
  G := Picture.Graphic;
  if G <> nil then
  begin
    if not ((G is TMetaFile) or (G is TIcon)) then
      G.Transparent := FTransparent;
    D := DestRect;
    if (not G.Transparent) and (D.Left <= 0) and (D.Top <= 0) and
       (D.Right >= Width) and (D.Bottom >= Height) then
      ControlStyle := ControlStyle + [csOpaque]
    else  // picture might not cover entire clientrect
      ControlStyle := ControlStyle - [csOpaque];
    if DoPaletteChange and FDrawing then Update;
  end
  else ControlStyle := ControlStyle - [csOpaque];
  if not FDrawing then Invalidate;

  if Observers.IsObserving(TObserverMapping.EditLinkID) then
    if TLinkObservers.EditLinkIsEditing(Observers) then
      TLinkObservers.EditLinkUpdate(Observers);
end;

procedure CSplashScreen.PrepareStart;
begin
  if FExecuted then
    Exit;
  //Align := alClient;

  FExecuted := true;

  FTimer.Enabled := FDuration > 0;
  FTimer.Interval := FDuration;

  Visible := true;

  if FSizeMode = szmAlign then
    Align := alClient
  else
    if FSizeMode = szmForm then
      begin
      Top := 0;
      Left := 0;
      Width := GetParentForm(Self).ExplicitWidth;
      Height := GetParentForm(Self).ExplicitHeight - GetSystemMetrics(SM_CYCAPTION);
    end;

  BringToFront;

  if Assigned(FTitleBar) then
    FTitleBar.BringToFront;

  if Assigned(FOnSetupComplete) then
    FOnSetupComplete(Self);
end;

procedure CSplashScreen.SetPicture(Value: TPicture);
begin
  Picture.Assign(Value);
end;

procedure CSplashScreen.SetTransparent(Value: Boolean);
begin
    if Value <> FTransparent then
  begin
    FTransparent := Value;
    PictureChanged(Self);
  end;
end;

end.
