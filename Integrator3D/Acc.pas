unit Acc;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.WinXCtrls,
  Vec4D, BSPXFile, CelestialMechanics, Vcl.Samples.Spin;

type
  TAccMode = (xaPrograde, xaRadial, xaNormal);
  TAcc = record
   Magnitude: Double;
   CenterIdx, FrameID: Int64;
   Mode: TAccMode;
  end;

  TAccForm = class(TForm)
    Panel_Input: TPanel;
    Splitter3: TSplitter;
    Splitter4: TSplitter;
    Panel_Names: TPanel;
    Name_Hdr: TPanel;
    Name_Mode: TPanel;
    Name_Acc: TPanel;
    Panel5: TPanel;
    Name_Target: TPanel;
    Name_Center: TPanel;
    Name_Frame: TPanel;
    Panel17: TPanel;
    Panel_Units: TPanel;
    Unit_Hdr: TPanel;
    Unit_Acc: TButton;
    Panel8: TPanel;
    Panel_Values: TPanel;
    Value_Hdr: TPanel;
    Panel6: TPanel;
    Value_Target: TPanel;
    Value_Frame: TPanel;
    Panel11: TPanel;
    Value_Center: TComboBox;
    Value_Mode: TRadioGroup;
    ToggleSwitch: TToggleSwitch;
    Value_AccPanel: TPanel;
    Value_Acc: TEdit;
    Value_AccSpin: TSpinButton;
    Unit_Target: TPanel;
    CBRelative: TCheckBox;
    Panel2: TPanel;
    procedure ComboDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure WMDrawItem(var Message: TMessage); message WM_DRAWITEM;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure NumericOnlyKeyPress(Sender: TObject; var Key: Char);
    procedure ToggleSwitchClick(Sender: TObject);
    procedure UnitClick_Acc(Sender: TObject);
    procedure Value_AccSpinUpClick(Sender: TObject);
    procedure Value_AccSpinDownClick(Sender: TObject);
    procedure Value_Change(Sender: TObject);
  private
    procedure DisplayAcc(A: Double);
  public
    Acc: TAcc;
    procedure PopulateCenters;   // (re)fill Value_Center for MainForm's current system (barycentre + its nonzero-GM children)
    procedure SetCenter(const Value: string);
    procedure TurnOff;   // reflect the stopped state in the UI (toggle off + inputs enabled); the caller manages the callback arrays
    class function GetAccel(Index: Int64; const S: TState4D; P: PState4D; nPert: NativeInt): TVec4D; static;
  end;

implementation

uses Main, Int, Vcl.Themes;

{$R *.dfm}

procedure TAccForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  IntForm.UnregisterAccForm(Self);
  Action := caFree;
end;

procedure TAccForm.FormCreate(Sender: TObject);
begin
  PopulateCenters;
  Unit_Acc.Caption := CAPS_ACC[Unit_Acc.Tag]; Unit_Acc.Hint := HINTS_ACC[Unit_Acc.Tag];
  if ToggleSwitch.State=tssOff then Value_Change(nil);
end;

procedure TAccForm.PopulateCenters;
// Fill Value_Center with the acceleration centres worth offering for MainForm's current system: the system
// barycentre itself, then every nonzero-GM body orbiting it DIRECTLY. Object = descriptor index (= Acc.CenterIdx,
// the perturber-array slot GetAccel subtracts; -1 = the SSB, which has no descriptor). Rebuilt on an FBarycenter
// change for idle forms (IntForm.RebuildIdleAccFormCenters). The previous centre is re-selected if it survives.
var
  i, bary, prev: Int64;
begin
  bary := MainForm.Barycenter;
  if Value_Center.ItemIndex >= 0 then prev := Int64(Pointer(Value_Center.Items.Objects[Value_Center.ItemIndex])) else prev := -1;
  Value_Center.Items.BeginUpdate;
  try
   Value_Center.Items.Clear;
   if bary = 0 then
    Value_Center.Items.AddObject('Solar System BC', TObject(Pointer(Int64(-1))))   // SSB has no descriptor; -1 keeps the integrand SSB-relative
   else
    begin
     i := MainForm.BSPXFile.FindDesc(bary);
     if i >= 0 then Value_Center.Items.AddObject(BSPXStr(MainForm.BSPXFile.Desc[i].TargetName, SizeOf(MainForm.BSPXFile.Desc[i].TargetName)), TObject(Pointer(i)));
    end;
   for i := 0 to MainForm.BSPXFile.DescCount-1 do
    if (MainForm.BSPXFile.Desc[i].NumComp = 3) and (MainForm.BSPXFile.Desc[i].CenterID = bary) and (MainForm.BSPXFile.Desc[i].GM > 0.0) then
     Value_Center.Items.AddObject(BSPXStr(MainForm.BSPXFile.Desc[i].TargetName, SizeOf(MainForm.BSPXFile.Desc[i].TargetName)), TObject(Pointer(i)));
  finally
   Value_Center.Items.EndUpdate;
  end;
  Value_Center.ItemIndex := 0;   // default = the barycentre
  for i := 0 to Value_Center.Items.Count-1 do   // re-select the previous centre if it survived the rescope
   if Int64(Pointer(Value_Center.Items.Objects[i])) = prev then begin Value_Center.ItemIndex := i; Break; end;
end;

procedure TAccForm.WMDrawItem(var Message: TMessage);
var
  DIS: PDrawItemStruct;
  Combo: TComboBox;
begin
  DIS := PDrawItemStruct(Message.LParam);
  if (DIS <> nil) and (Integer(DIS^.itemID) < 0) then
   begin
    Combo := nil;
    if DIS^.hwndItem = Value_Center.Handle then Combo := Value_Center;
    if Combo <> nil then
     begin
      Combo.Canvas.Handle := DIS^.hDC;
      Combo.Canvas.Font.Assign(Combo.Font);
      ComboDrawItem(Combo, -1, DIS^.rcItem, []);
      Combo.Canvas.Handle := 0;
      Message.Result := 1;
      Exit;
     end;
   end;
  inherited;
end;

procedure TAccForm.ComboDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  Combo: TComboBox;
  Text: string;
begin
  Combo := TComboBox(Control);
  if Index < 0 then Text := Combo.TextHint
               else Text := Combo.Items[Index];
  with Combo.Canvas do
   begin
    if odSelected in State then
     begin
      Brush.Color := clHighlight;
      Font.Color  := clHighlightText;
     end
    else if StyleServices(Combo).Enabled then
     begin
      Brush.Color := StyleServices(Combo).GetStyleColor(scComboBox);
      Font.Color  := StyleServices(Combo).GetStyleFontColor(sfListItemTextNormal);
     end
    else
     begin
      Brush.Color := Combo.Color;
      Font.Color  := Combo.Font.Color;
     end;
    FillRect(Rect);
    TextOut(Rect.Left + 2, Rect.Top + 2, Text);
   end;
end;

procedure TAccForm.NumericOnlyKeyPress(Sender: TObject; var Key: Char);
var
  s: string;
begin
  if not CharInSet(Key, ['0'..'9', '.', '+', '-', 'e', 'E', #8]) then begin Key := #0; Exit; end;
  s:=LowerCase(TEdit(Sender).Text);
  if ((Key='-') or (Key='+')) and (s<>'') and (s[Length(s)]<>'e') then Key := #0;
  if (Key='.') and (s.CountChar('.')>0) then begin Key := #0; Exit; end;
  if ((Key='e') or (Key='E')) and (s.CountChar('e')>0) then begin Key := #0; Exit; end;
  if ((Key='-') or (Key='+')) and (s.CountChar('-') + s.CountChar('+') > 1) then Key := #0;
end;

procedure TAccForm.ToggleSwitchClick(Sender: TObject);
var
  i: Int64;
  b: Boolean;
begin
  b:=(ToggleSwitch.State=tssOff);
  for i:=0 to Panel_Names.ControlCount-1 do Panel_Names.Controls[i].Enabled:=b;
  for i:=0 to Panel_Values.ControlCount-1 do Panel_Values.Controls[i].Enabled:=b;
  for i:=0 to Panel_Units.ControlCount-1 do if not (Panel_Units.Controls[i] is TToggleSwitch) then Panel_Units.Controls[i].Enabled:=b;
  if ToggleSwitch.State=tssOn then IntForm.SetAccelCallback(Self, @TAccForm.GetAccel) else
   begin
    IntForm.SetAccelCallback(Self, nil);
    Value_Change(nil);
   end;
end;

procedure TAccForm.TurnOff;
// UI only: force the toggle off and re-enable the inputs, so a reused AccForm shows its stopped state after
// an integration restart. Does NOT touch AccelCallbacks/IntegrationCallbacks -- IntBoxMouseDown rebuilds
// those (all nil) under the lock. Idempotent (safe if already off); the Acc settings are preserved.
var
  i: Int64;
begin
  ToggleSwitch.State := tssOff;
  for i:=0 to Panel_Names.ControlCount-1 do Panel_Names.Controls[i].Enabled := True;
  for i:=0 to Panel_Values.ControlCount-1 do Panel_Values.Controls[i].Enabled := True;
  for i:=0 to Panel_Units.ControlCount-1 do if not (Panel_Units.Controls[i] is TToggleSwitch) then Panel_Units.Controls[i].Enabled := True;
end;

procedure TAccForm.UnitClick_Acc(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_ACC);
  Btn.Caption := CAPS_ACC[Btn.Tag];
  Btn.Hint    := HINTS_ACC[Btn.Tag];
  Value_Change(Sender);
end;

procedure TAccForm.Value_AccSpinDownClick(Sender: TObject);
var
  A: Double;
begin
  try
   A:=StrToFloat(Value_Acc.Text)-0.1;
   if A<0.0 then A:=0.0;
   Value_Acc.Text:=Format('%.2f', [A]);
  except
  end;
end;

procedure TAccForm.Value_AccSpinUpClick(Sender: TObject);
var
  A: Double;
begin
  try
   A:=StrToFloat(Value_Acc.Text)+0.1;
   if A>1000.0 then A:=1000.0;
   Value_Acc.Text:=Format('%.2f', [A]);
  except
  end;
end;

procedure TAccForm.DisplayAcc(A: Double);
var
  i: Int64;
  x: Double;
const
  SF: array[0..4] of Double = (1e9, 1e6, 1e3, 1/9.81e-3, 1.0);
begin
  i:=Length(SF);
  repeat
   i:=i-1;
   x:=A*SF[i];
  until (i=Low(SF)) or (Abs(x)>=1.0);
  Caption:=Format('Acceleration: %.3f %s', [x, CAPS_ACC[i]]);
end;

procedure TAccForm.Value_Change(Sender: TObject);
var
  A: Double;
const
  SF: array[0..4] of Double = (1e-9, 1e-6, 1e-3, 9.81e-3, 1.0);
  SS: array[0..5] of Double = (1.0, 1.0, 1.0, -1.0, -1.0, -1.0);
  SM: array[0..5] of TAccMode = (xaPrograde, xaNormal, xaRadial, xaPrograde, xaNormal, xaRadial);
begin
  try
   A:=StrToFloat(Value_Acc.Text)*SF[Unit_Acc.Tag]*SS[Value_Mode.ItemIndex];
   if (A = 0.0) or IsNan(A) or IsInfinite(A) or (Abs(A)>10.0) then raise Exception.Create('Invalid value.');
   if CBRelative.Checked then A:=A/MainForm.TimeAcceleration;
   DisplayAcc(A);
   Acc.Magnitude:=A;
   Acc.CenterIdx:=Int64(Pointer(Value_Center.Items.Objects[Value_Center.ItemIndex]));
   Acc.FrameID:=0;
   Acc.Mode:=SM[Value_Mode.ItemIndex];
   ToggleSwitch.Enabled:=True;
  except
   ToggleSwitch.Enabled:=False;
  end;
end;

procedure TAccForm.SetCenter(const Value: string);
var
  i: Int64;
begin
  i:=Value_Center.Items.IndexOf(Value);
  if i>=0 then Value_Center.ItemIndex:=i;
end;

class function TAccForm.GetAccel(Index: Int64; const S: TState4D; P: PState4D; nPert: NativeInt): TVec4D;
var
  SS: TState4D;
  A: TAcc;
  Pc: PState4D;
begin
  FillChar(Result, SizeOf(TVec4D), 0);
  if (Index<0) or (Index>=Length(IntForm.IntegrationX)) then Exit;
  A:=IntForm.IntegrationX[Index].Acc;
  if A.Magnitude=0.0 then Exit;
  if (A.CenterIdx<0) or (A.CenterIdx>=nPert) then SS:=S else
   begin
    Pc:=PState4D(PByte(P)+A.CenterIdx*SizeOf(TState4D));   // P is a raw ptr + count (see TAccelCallback)
    SS.R:=S.R-Pc^.R;
    SS.V:=S.V-Pc^.V;
   end;
  case A.Mode of
    xaPrograde: Result:=SS.V.Normalize3D * A.Magnitude;   // along velocity
    xaRadial:   Result:=SS.R.Normalize3D * A.Magnitude;   // along the position vector from the centre
    xaNormal:   Result:=(SS.R xor SS.V).Normalize3D * A.Magnitude;   // orbit normal (r x v)
  end;
  Result.W:=0.0;
end;

end.
