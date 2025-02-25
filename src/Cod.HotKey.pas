{***********************************************************}
{                       Codrut HotHey                       }
{                                                           }
{                        version 0.1                        }
{                           ALPHA                           }
{                                                           }
{                                                           }
{                                                           }
{                                                           }
{                                                           }
{                   -- WORK IN PROGRESS --                  }
{***********************************************************}

unit Cod.HotKey;

interface
  uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Dialogs, ExtCtrls, Menus, Cod.SysUtils, Forms;

  type
    CHotKey = class;

    CHKeyFocusMode = (chfFormFocused, chfControlFocused, chfApplicationFocused, chfGlobal);

    CHOnExecute = procedure(Sender: CHotKey; Mode: CHKeyFocusMode; Shortcut: string) of object;

    CHotKey = class(TComponent)
    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;

    private
      FAuthor, FSite, FVersion: string;
      FShortCut: string;
      FEnable,
      FRepeatUntilNot,
      FExecOnce: boolean;
      FFocusMode: CHKeyFocusMode;
      FOnExecute: CHOnExecute;
      FCheckTimer: TTimer;
      FLegShortCut: TShortCut;
      FInterval: integer;
      LastValue: boolean;
      Componen: TComponent;

    procedure FTimerAct(Sender: TObject);
    procedure SetEnable(const Value: boolean);
    function GetKeyCode(text: string): integer;
    procedure SetShortLegCut(const Value: TShortCut);
    function GetTNext(text: string): string;
    procedure SetInterval(const Value: integer);
    procedure SetNotExecMode(const Value: boolean);
    function GetOwningForm(Control: TComponent): TForm;

    published
      property ShortCut: string read FShortCut write FShortCut;
      property Mode: CHKeyFocusMode read FFocusMode write FFocusMode;
      property Enabled: boolean read FEnable write SetEnable;

      property RepeatUntilNot: boolean read FRepeatUntilNot write SetNotExecMode;

      property ParentComponent: TComponent read Componen write Componen;

      property VerifyInterval: integer read FInterval write SetInterval;
      property ExecuteOnce: boolean read FExecOnce write FExecOnce;
      property OnExecute: CHOnExecute read FOnExecute write FOnExecute;

      property LegacyShortCut: TShortCut read FLegShortCut write SetShortLegCut;

      property Author: string Read FAuthor;
      property Site: string Read FSite;
      property Version: string Read FVersion;
  end;

implementation

{ CodHotKey }

constructor CHotKey.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAuthor                       := 'Petculescu Codrut';
  FSite                         := 'https://www.codrutsoftware.cf';
  FVersion                      := '1.0';

  FCheckTimer := TTImer.Create(Self);
  with FCheckTimer do begin
    Enabled := false;
    Interval := 1;
    OnTimer := FTimerAct;
  end;

  FInterval := 1;

  FRepeatUntilNot := false;
  FExecOnce := true;

  FFocusMode := chfFormFocused;

  FEnable := false;
end;

destructor CHotKey.Destroy;
begin
  FCheckTimer.Enabled := false;
  FreeAndNil( FCheckTimer );

  inherited Destroy;
end;

function CHotKey.GetOwningForm(Control: TComponent): TForm;
var
  LOwner: TComponent;
begin
  LOwner:= Control.Owner;
  while Assigned(LOwner) and not(LOwner is TCustomForm) do begin
    LOwner:= LOwner.Owner;
  end; {while}
  Result:= TForm(LOwner);
end;

procedure CHotKey.FTimerAct(Sender: TObject);
var
  ps, tx: string;
  arepressed,
  focusmode: boolean;
  value: integer;
begin
  if (FShortCut = '') or (IsInIDE) then Exit;
  //ps := ShortCutToText(FShortCut);
  focusmode := false;

  case FFocusMode of
    chfFormFocused: try focusmode := GetOwningForm(Self).Active; except end;
    chfControlFocused: if Assigned(Componen) then try focusmode := TWinControl(Componen).Focused; except end else focusmode := false;
    chfApplicationFocused: focusmode := Application.Active;
    chfGlobal: focusmode := true;
  end;

  if NOT focusmode then Exit;


  arepressed := true;

  tx := FShortCut;
  tx := tx.Replace(' ', '');

  repeat
    ps := GetTNext(tx);
    tx := Copy(tx, Length(ps) + 2, tx.Length );

    value := GetKeyCode(ps);

    if (NOT GetKeyState(value) < 0) and (value <> 0) then arepressed := false;
  until (value = 0);

  if FRepeatUntilNot then arepressed := NOT arepressed;
  

  if arepressed then
    if Assigned(OnExecute) and NOT (ExecuteOnce and lastvalue) then OnExecute(Self, FFocusMode, FShortCut);

  lastvalue := arepressed;
end;

function CHotKey.GetKeyCode(text: string): integer;
begin
  Result := 0;
  if Length (text) > 1 then begin
    if (ANSILowerCase(text) = 'ctrl') or (ANSILowerCase(text) = 'control') then Result := 17;
    if (ANSILowerCase(text) = 'esc') or (ANSILowerCase(text) = 'escape') then Result := 27;
    if ANSILowerCase(text) = 'shift' then Result := 16;
    if ANSILowerCase(text) = 'alt' then Result := 18;

    if ANSILowerCase(text) = 'home' then Result := 36;
    if ANSILowerCase(text) = 'menu' then Result := 93;
    if (ANSILowerCase(text) = 'del') or (ANSILowerCase(text) = 'delete') then Result := 46;

    if ANSILowerCase(text) = 'enter' then Result := 13;
    if ANSILowerCase(text) = 'tab' then Result := VK_TAB;

    if ANSILowerCase(text) = 'left' then Result := 37;
    if ANSILowerCase(text) = 'up' then Result := 38;
    if ANSILowerCase(text) = 'right' then Result := 39;
    if ANSILowerCase(text) = 'down' then Result := 40;

    if ANSILowerCase(text) = '/' then Result := 191;
  end;

  if (Result = 0) and (text <> '') then
    Result := integer(text[1]);
end;

function CHotKey.GetTNext(text: string): string;
begin
  Result := Copy(text, 1, pos('+',text) - 1);

  if Result = '' then
    Result := text;
end;

procedure CHotKey.SetEnable(const Value: boolean);
begin
  FEnable := Value;
  FCheckTimer.Enabled := Value;
end;

procedure CHotKey.SetInterval(const Value: integer);
begin
  FInterval := Value;
  if FInterval < 1 then FInterval := 1;

  FCheckTimer.Interval := Value;
end;

procedure CHotKey.SetNotExecMode(const Value: boolean);
begin
  FRepeatUntilNot := Value;

  if Value then
    FExecOnce := false;
end;

procedure CHotKey.SetShortLegCut(const Value: TShortCut);
begin
  if Value <> 0 then
    FShortCut := ShortCutToText(Value);
end;

end.
