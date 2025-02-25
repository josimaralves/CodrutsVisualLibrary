unit Cod.Visual.ColorWheel;

interface

uses
  SysUtils,
  Classes,
  Windows,
  Controls,
  Graphics,
  ExtCtrls,
  Cod.Components,
  Cod.Visual.CPSharedLib,
  System.Math,
  Styles,
  Cod.Visual.ColorBright,
  Forms,
  Themes,
  Types,
  Cod.SysUtils,
  Cod.Graphics,
  Cod.Types,
  Cod.VarHelpers,
  Imaging.pngimage;

type
  CColorWheel = class;

  ColorWheelOverlay = (covNone, covEllipse, covLines);
  ColorWheelChangeColor = procedure(Sender: CColorWheel; Color: TColor; X, Y: integer) of object;
  ColorBrightItem = CColorBright;

  CColorWheel = class(TCustomTransparentControl)
      constructor Create(AOwner : TComponent); override;
      destructor Destroy; override;
    private
      Wheel: TBitMap;
      ColorCoord: TPoint;
      FColor: TColor;
      MouseIsDown,
      FEnableRadiusCoord,
      FEnableLineCoord,
      FTransparent,
      FirstStart,
      FSyncBgColor: boolean;
      Xo, Yo,
      FRadius: integer;
      FOverLay: ColorWheelOverlay;
      FChangeColor: ColorWheelChangeColor;
      FColorBright: ColorBrightItem;
      FTrueTransparent: boolean;

      function HSBtoColor(hue, sat, bri: Double): TColor;
      function ColorWheel(Width, Height: Integer; Background: TColor = clWhite): TBitMap;
      procedure RedrawWheel;
      procedure ChangeColor(color: TColor; x, y: integer);
      procedure SetFormSync(const Value: boolean);
      procedure SetColor(const Value: TColor);
      procedure SetTransparent(const Value: boolean);
      procedure SetTrueTransparent(const Value: boolean);

    protected
      procedure Paint; override;
      procedure KeyPress(var Key: Char); override;
      procedure MouseDown(Button : TMouseButton; Shift: TShiftState; X, Y : integer); override;
      procedure MouseUp(Button : TMouseButton; Shift: TShiftState; X, Y : integer); override;
      procedure MouseMove(Shift: TShiftState; X, Y : integer); override;
      procedure DoEnter; override;
      procedure DoExit; override;

    published
      property OnMouseEnter;
      property OnMouseLeave;
      property OnMouseDown;
      property OnMouseUp;
      property OnMouseMove;
      property OnClick;

      property TabStop;
      property TabOrder;

      property Color;
      property ParentColor;

      property Align;
      property Anchors;
      property Cursor;
      property Visible;
      property Enabled;
      property Constraints;
      property DoubleBuffered;
      property ColorBright: ColorBrightItem read FColorBright write FColorBright;
      property ChangeWheelColor: ColorWheelChangeColor read FChangeColor write FChangeColor;
      property FormSyncedColor : boolean read FSyncBgColor write SetFormSync;

      property TrueTransparency: boolean read FTrueTransparent write SetTrueTransparent;

      property EnableRadiusCoordonation: boolean read FEnableRadiusCoord write FEnableRadiusCoord;
      property EnableLineCoordonation: boolean read FEnableLineCoord write FEnableLineCoord;

      property Transparent: boolean read FTransparent write SetTransparent;
      property CurrentColor: TColor read FColor write SetColor;
  end;

implementation

{ CColorWheel }

function CColorWheel.HSBtoColor(hue, sat, bri: Double): TColor;
var
  f, h: Double;
  u, p, q, t: Byte;
begin
  u := Trunc(bri * 255 + 0.5);
  if sat = 0 then
    Exit(rgb(u, u, u));

  h := (hue - Floor(hue)) * 6;
  f := h - Floor(h);
  p := Trunc(bri * (1 - sat) * 255 + 0.5);
  q := Trunc(bri * (1 - sat * f) * 255 + 0.5);
  t := Trunc(bri * (1 - sat * (1 - f)) * 255 + 0.5);

  case Trunc(h) of
    0:
      result := rgb(u, t, p);
    1:
      result := rgb(q, u, p);
    2:
      result := rgb(p, u, t);
    3:
      result := rgb(p, q, u);
    4:
      result := rgb(t, p, u);
    5:
      result := rgb(u, p, q);
  else
    result := clwhite;
  end;

end;

procedure CColorWheel.KeyPress(var Key: Char);
var
  x, y: integer;
begin
  if (key = 'a')  then begin
    x := colorcoord.X - 3;
    if (x > 0) and (x < width)then
      MouseDown(mbLeft,[], x, colorcoord.Y);
      MouseUp(mbLeft,[],x,colorcoord.Y);
  end;
  if (key = 'd') then begin
    x := colorcoord.X + 3;
    if (x > 0) and (x < width)then
      MouseDown(mbLeft,[], x, colorcoord.Y);
      MouseUp(mbLeft,[],x,colorcoord.Y);
  end;
  if (key = 'w') then begin
    y := colorcoord.Y - 3;
    if (y > 0) and (y < height)then
      MouseDown(mbLeft,[], colorcoord.X, Y);
      MouseUp(mbLeft,[], colorcoord.X, Y);
  end;
  if (key = 's') then begin
    y := colorcoord.Y + 3;
    if (y > 0) and (y < height)then
      MouseDown(mbLeft,[], colorcoord.X, Y);
      MouseUp(mbLeft,[], colorcoord.X, Y);
  end;
end;

procedure CColorWheel.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: integer);
begin
  inherited;
  MouseIsDown := true;
  MouseMove(Shift, X, Y);
end;

procedure CColorWheel.MouseMove(Shift: TShiftState; X, Y: integer);
var
  r{, ro}: real;
  np: TPoint;
begin
  inherited;

  if NOT (Power((x - Xo), 2) + Power((y - Yo), 2) < Power(Xo, 2)) then
    Exit;

  //ro := sqrt( Power((colorcoord.x - Xo), 2) + Power((colorcoord.y - Yo), 2) );

  r := sqrt( Power((x - Xo), 2) + Power((y - Yo), 2) );

  FRadius := trunc(r);

  FOverLay := covNone;
  if FEnableRadiusCoord and (ssShift in Shift) then
  begin
    FOverLay := covEllipse;

    //Apply radius changes
    {sina := (y - yo) / FRadius;
    cosa := (x - xo) / FRadius;



    X := round(Xo + FRadius * sina);
    Y := round(Yo + FRadius * cosa);   }

    np := RotatePointAroundPoint(Point(X, Y), Point(Xo, Yo), 0, 50);
    X := np.X;
    Y := np.Y;

    {if radiusold <> FRadius then  }
  end;


  if MouseIsDown then begin
    ColorCoord.X := X;
    ColorCoord.Y := Y;

    ChangeColor(Wheel.Canvas.Pixels[trunc(x / width * wheel.Width), trunc(y / height * wheel.Width)], x, y);
    Paint;
  end;
end;

procedure CColorWheel.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: integer);
begin
  inherited;
  MouseIsDown := false;

  MouseIsDown := false;
  try
    Self.SetFocus;
    Paint;
  except
  end;
end;

procedure CColorWheel.ChangeColor(color: TColor; x, y: integer);
begin
  FColor := color;
  if Assigned(FChangeColor) then FChangeColor(Self, color, x, y);
   if Assigned(FColorBright) then FColorBright.PureColor := color;
end;

function CColorWheel.ColorWheel(Width, Height: Integer; Background: TColor): TBitMap;
var
  Center: TPoint;
  Radius: Integer;
  x, y: Integer;
  Hue, dy, dx, dist, theta: Double;
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  Bmp.SetSize(Width, Height);
  with Bmp.Canvas do
  begin
    Brush.Color := Background;
    FillRect(ClipRect);
    Center := ClipRect.CenterPoint;
    Radius := Center.X;
    if Center.Y < Radius then
      Radius := Center.Y;
    for y := 0 to Height - 1 do
    begin
      dy := y - Center.y;
      for x := 0 to Width - 1 do
      begin
        dx := x - Center.x;
        dist := Sqrt(Sqr(dx) + Sqr(dy));
        if dist <= Radius then
        begin
          theta := ArcTan2(dy, dx);
          Hue := (theta + PI) /  (2 * PI);
          Pixels[x, y] := HSBtoColor(Hue, 1, 1);
        end;
      end;
    end;
  end;

  Result := TBitMap.Create;
  Result.Assign(Bmp);
  Bmp.Free;
end;

constructor CColorWheel.Create(AOwner: TComponent);
begin
  inherited;
  interceptmouse:=True;
  TabStop := true;

  FTransparent := false;
  FSyncBgColor := true;

  FEnableRadiusCoord := true;
  FEnableLineCoord := true;

  Width := 100;
  Height := 100;

  Xo := width div 2;
  Yo := height div 2;

  colorcoord := Point(Xo, Yo);
end;

destructor CColorWheel.Destroy;
begin
  FreeAndNil(wheel);
  inherited;
end;


procedure CColorWheel.DoEnter;
begin
  inherited;

end;

procedure CColorWheel.DoExit;
begin
  inherited;
  Paint;
end;

procedure CColorWheel.Paint;
begin
  inherited;

  if NOT FirstStart then begin
    RedrawWheel;
    FirstStart := true;
  end;

  //Set Center
  Xo := width div 2;
  Yo := height div 2;

  if width < height then height := width;
  if height < width then width := height;

  if (FTransparent) and (NOT Wheel.Transparent) then
  begin
    Wheel.Transparent := true;
    Wheel.TransparentColor := clWhite;
    Wheel.TransparentMode := tmAuto;
  end else if Wheel.Transparent then Wheel.Transparent := false;


  with canvas do begin
    Brush.Color := TStyleManager.ActiveStyle.GetSystemColor(Color);

    //Draw Color Wheel
    if FTrueTransparent then
        CopyRoundRect(wheel.Canvas, MakeRoundRect(Rect(0, 0, wheel.Width, wheel.Height), Width, Height), Canvas, canvas.ClipRect, 3)
    else
      StretchDraw(Rect(0, 0, width, height), wheel, 255);

    //Select Pen Color
    if Self.Focused then
      Pen.Color := clWhite
    else
      Pen.Color := clBlack;

    {TextOut(5,20,'Color Sat' + inttostr(CalculateLight(FColor) ) );  }

    //Draw Overlay
    Brush.Style := bsClear;
    case FOverLay of
      covEllipse: begin
        Ellipse( Xo - FRadius - 1, Yo - FRadius - 1, Xo + FRadius + 1, Yo + FRadius + 1);
      end;
    end;

    //Draw Icon
    Pen.Width := 1;
    Brush.Style := bsClear;
      //Rectangle(ColorCoord.X - 2, ColorCoord.Y - 2, ColorCoord.X + 2, ColorCoord.Y + 2);
    Ellipse(ColorCoord.X - 2, ColorCoord.Y - 2, ColorCoord.X + 2, ColorCoord.Y + 2);

    {Pen.Color := clBLack;
    Ellipse(ColorCoord.X - 3, ColorCoord.Y - 3, ColorCoord.X + 3, ColorCoord.Y + 3); }
  end;
end;

procedure CColorWheel.RedrawWheel;
var
  bgc: TColor;
begin
  bgc := Self.Color;

  if FSyncBgColor then
  begin
    if StrInArray(TStyleManager.ActiveStyle.Name, nothemes) then begin
      bgc := GetParentForm(Self).Color;
    end else begin
      bgc := TStyleManager.ActiveStyle.GetSystemColor(clBtnFace);
    end;
  end;

  if wheel = nil then
    wheel := TBitMap.Create;

  wheel := ColorWheel(Self.Width, Self.Height, bgc);
end;

procedure CColorWheel.SetColor(const Value: TColor);
var
  Center: TPoint;
  dist, Hue: real;
  theta: single;
  radius, dx, dy, x, y: integer;
begin
  FColor := Value;

  {if CalculateLight(FColor) > 60 then
    FColor := ChangeColorSat(FColor, -20);   }

    Xo := width div 2;
    Yo := height div 2;

    Center := Point(Xo, Yo);
    Radius := Center.X;
    if Center.Y < Radius then
      Radius := Center.Y;
    for y := 0 to Height - 1 do
    begin
      dy := y - Center.y;
      for x := 0 to Width - 1 do
      begin
        dx := x - Center.x;
        dist := Sqrt(Sqr(dx) + Sqr(dy));
        if dist <= Radius then
        begin
          theta := ArcTan2(dy, dx);
          Hue := (theta + PI) /  (2 * PI);
          if FColor = HSBtoColor(Hue, 1, 1) then
          begin
            ColorCoord.X := X;
            ColorCoord.Y := Y;
            Paint;
            Exit;
          end;
        end;
      end;
    end;

    ColorCoord.X := Xo;
    ColorCoord.Y := Yo;
    Paint;
end;

procedure CColorWheel.SetFormSync(const Value: boolean);
begin
  FSyncBgColor := Value;
  if FirstStart then
    RedrawWheel;
  Paint;
end;

procedure CColorWheel.SetTransparent(const Value: boolean);
begin
  FTransparent := Value;
end;

procedure CColorWheel.SetTrueTransparent(const Value: boolean);
begin
  FTrueTransparent := Value;

  if Value then
    Invalidate;
end;

end.
