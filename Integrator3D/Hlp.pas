unit Hlp;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  CelestialMechanics;

const
  MODE_ASTEROID = 0;

  IDX_AST_GM     = 0;
  IDX_AST_M      = 1;
  IDX_AST_RA     = 2;
  IDX_AST_RB     = 3;
  IDX_AST_RC     = 4;
  IDX_AST_D      = 5;
  IDX_AST_AMRAT  = 6;
  IDX_AST_BC     = 7;
  IDX_AST_H      = 8;
  IDX_AST_ALBEDO = 9;
  IDX_AST_DENSITY= 10;

type
  TAstData = record
  case Integer of
   0: (GM, M, Ra, Rb, Rc, D, AMRAT, BC, H, Albedo, Density: Double);
   1: (Vals: array[0..10] of Double);
  end;

  TEdit = class(Vcl.StdCtrls.TEdit)
  public
   LinkedButton: TButton;
   LinkedIndex: Int64;
  end;

  THlpForm = class(TForm)
    Panel_Ast: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Panel_AstNames: TPanel;
    Panel_Name_Header: TPanel;
    Name_AstRa: TPanel;
    Panel_AstUnits: TPanel;
    Panel_Unit_Header: TPanel;
    Unit_AstGM: TButton;
    Panel_AstValues: TPanel;
    Panel_Value_Header: TPanel;
    Value_AstRa: TEdit;
    Name_AstRc: TPanel;
    Name_AstRb: TPanel;
    Value_AstRb: TEdit;
    Value_AstRc: TEdit;
    Unit_AstM: TButton;
    Unit_AstRa: TButton;
    Name_AstD: TPanel;
    Value_AstD: TEdit;
    Unit_AstD: TButton;
    Name_AstAlbedo: TPanel;
    Value_AstH: TEdit;
    Name_AstH: TPanel;
    Name_AstGM: TPanel;
    Value_AstGM: TEdit;
    Name_AstM: TPanel;
    Value_AstM: TEdit;
    Name_AstAMRAT: TPanel;
    Value_AstAMRAT: TEdit;
    Name_AstBC: TPanel;
    Value_AstBC: TEdit;
    Value_AstAlbedo: TEdit;
    Unit_AstAlbedo: TButton;
    Unit_AstH: TButton;
    Unit_AstBC: TButton;
    Unit_AstAMRAT: TButton;
    Unit_AstRc: TButton;
    Unit_AstRb: TButton;
    CompBtn: TButton;
    AcceptBtn: TButton;
    Name_AstDensity: TPanel;
    Value_AstDensity: TEdit;
    Unit_AstDensity: TButton;
    procedure UnitClick_GM(Sender: TObject);
    procedure UnitClick_Mass(Sender: TObject);
    procedure UnitClick_Dens(Sender: TObject);
    procedure UnitClick_Dist(Sender: TObject);
    procedure UnitClick_IBC(Sender: TObject);
    procedure UnitClick_BC(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure NumericOnlyKeyPress(Sender: TObject; var Key: Char);
    procedure CompBtnClick(Sender: TObject);
    procedure Value_AstDensityDblClick(Sender: TObject);
    procedure Value_AstAlbedoDblClick(Sender: TObject);
  private
    FMode: Int64;
    FAstData: TAstData;
  public
    procedure SetMode(Mode: Int64);
    procedure Reset;
    procedure SetAstField(const Value: string; ValueIdx, UnitTag: Int64);
    property AstData: TAstData read FAstData;
  end;

var
  HlpForm: THlpForm;

implementation

{$R *.dfm}

uses Main;

procedure THlpForm.FormCreate(Sender: TObject);
begin
  Value_AstGM.LinkedButton    :=Unit_AstGM;     Value_AstGM.LinkedIndex    :=IDX_AST_GM;
  Value_AstM.LinkedButton     :=Unit_AstM;      Value_AstM.LinkedIndex     :=IDX_AST_M;
  Value_AstRa.LinkedButton    :=Unit_AstRa;     Value_AstRa.LinkedIndex    :=IDX_AST_RA;
  Value_AstRb.LinkedButton    :=Unit_AstRb;     Value_AstRb.LinkedIndex    :=IDX_AST_RB;
  Value_AstRc.LinkedButton    :=Unit_AstRc;     Value_AstRc.LinkedIndex    :=IDX_AST_RC;
  Value_AstD.LinkedButton     :=Unit_AstD;      Value_AstD.LinkedIndex     :=IDX_AST_D;
  Value_AstAMRAT.LinkedButton :=Unit_AstAMRAT;  Value_AstAMRAT.LinkedIndex :=IDX_AST_AMRAT;
  Value_AstBC.LinkedButton    :=Unit_AstBC;     Value_AstBC.LinkedIndex    :=IDX_AST_BC;
  Value_AstDensity.LinkedButton:=Unit_AstDensity; Value_AstDensity.LinkedIndex:=IDX_AST_DENSITY;
  Value_AstH.LinkedIndex     :=IDX_AST_H;        // dimensionless -> no LinkedButton (SetAstField skips the unit button)
  Value_AstAlbedo.LinkedIndex:=IDX_AST_ALBEDO;

  Unit_AstGM.Caption:=CAPS_GM[Unit_AstGM.Tag];        Unit_AstGM.Hint:=HINTS_GM[Unit_AstGM.Tag];
  Unit_AstM.Caption:=CAPS_M[Unit_AstM.Tag];           Unit_AstM.Hint:=HINTS_M[Unit_AstM.Tag];
  Unit_AstRa.Caption:=CAPS_DIST[Unit_AstRa.Tag];      Unit_AstRa.Hint:=HINTS_DIST[Unit_AstRa.Tag];
  Unit_AstRb.Caption:=CAPS_DIST[Unit_AstRb.Tag];      Unit_AstRb.Hint:=HINTS_DIST[Unit_AstRb.Tag];
  Unit_AstRc.Caption:=CAPS_DIST[Unit_AstRc.Tag];      Unit_AstRc.Hint:=HINTS_DIST[Unit_AstRc.Tag];
  Unit_AstD.Caption:=CAPS_DIST[Unit_AstD.Tag];        Unit_AstD.Hint:=HINTS_DIST[Unit_AstD.Tag];
  Unit_AstAMRAT.Caption:=CAPS_IBC[Unit_AstAMRAT.Tag]; Unit_AstAMRAT.Hint:=HINTS_IBC[Unit_AstAMRAT.Tag];
  Unit_AstBC.Caption:=CAPS_BC[Unit_AstBC.Tag];        Unit_AstBC.Hint:=HINTS_BC[Unit_AstBC.Tag];
  Unit_AstDensity.Caption:=CAPS_DENS[Unit_AstDensity.Tag]; Unit_AstDensity.Hint:=HINTS_DENS[Unit_AstDensity.Tag];
end;

procedure THlpForm.SetMode(Mode: Int64);
var
  i: Int64;
begin
  FMode:=Mode;
  for i:=0 to HlpForm.ControlCount-1 do if HlpForm.Controls[i] is TPanel then TPanel(HlpForm.Controls[i]).Visible:=False;
  case Mode of
   MODE_ASTEROID: Panel_Ast.Visible:=True;
  end;
end;

procedure THlpForm.Reset;
var
  i: Int64;
begin
  case FMode of
   MODE_ASTEROID: begin
                   for i:=0 to Panel_AstValues.ControlCount-1 do if Panel_AstValues.Controls[i] is TEdit then TEdit(Panel_AstValues.Controls[i]).Text:='';
                   for i:=Low(FAstData.Vals) to High(FAstData.Vals) do FAstData.Vals[i]:=NaN;
                  end;
  end;
end;

procedure THlpForm.NumericOnlyKeyPress(Sender: TObject; var Key: Char);
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

procedure THlpForm.SetAstField(const Value: string; ValueIdx, UnitTag: Int64);
var
  i: Int64;
  e: TEdit;
begin
  i:=0; e:=nil;
  while (e=nil) and (i<Panel_AstValues.ControlCount) do
   begin
    if (Panel_AstValues.Controls[i] is TEdit) and (TEdit(Panel_AstValues.Controls[i]).LinkedIndex=ValueIdx) then e:=TEdit(Panel_AstValues.Controls[i]);
    i:=i+1;
   end;
  if e<>nil then
   begin
    e.Text:=Value;
    if e.LinkedButton<>nil then
     begin
      e.LinkedButton.Tag:=UnitTag-1;
      e.LinkedButton.OnClick(e.LinkedButton); // to set hint and caption
     end;
   end;
end;

procedure THlpForm.UnitClick_GM(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_GM);
  Btn.Caption := CAPS_GM[Btn.Tag];
  Btn.Hint    := HINTS_GM[Btn.Tag];
end;

procedure THlpForm.UnitClick_Mass(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_M);
  Btn.Caption := CAPS_M[Btn.Tag];
  Btn.Hint    := HINTS_M[Btn.Tag];
end;

procedure THlpForm.Value_AstAlbedoDblClick(Sender: TObject);
begin
  Value_AstAlbedo.Text := '0.15';
end;

procedure THlpForm.Value_AstDensityDblClick(Sender: TObject);
// Fill a sensible default bulk density (in whatever unit the button currently shows).
const
  DEFAULT_GCC = 2.0;   // g/cm^3 -- generic small-body assumption (rubble-pile / mixed-type average)
begin
  case Unit_AstDensity.Tag of
   0:   Value_AstDensity.Text := Format('%g', [DEFAULT_GCC]);          // g/cm^3
   1:   Value_AstDensity.Text := Format('%g', [DEFAULT_GCC*1.0E3]);    // kg/m^3
   else Value_AstDensity.Text := Format('%g', [DEFAULT_GCC*1.0E12]);   // kg/km^3
  end;
end;

procedure THlpForm.UnitClick_Dens(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_DENS);
  Btn.Caption := CAPS_DENS[Btn.Tag];
  Btn.Hint    := HINTS_DENS[Btn.Tag];
end;

procedure THlpForm.UnitClick_BC(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_BC);
  Btn.Caption := CAPS_BC[Btn.Tag];
  Btn.Hint    := HINTS_BC[Btn.Tag];
end;

procedure THlpForm.UnitClick_IBC(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_IBC);
  Btn.Caption := CAPS_IBC[Btn.Tag];
  Btn.Hint    := HINTS_IBC[Btn.Tag];
end;

procedure THlpForm.UnitClick_Dist(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_DIST);
  Btn.Caption := CAPS_DIST[Btn.Tag];
  Btn.Hint    := HINTS_DIST[Btn.Tag];
end;

function GetNum(const S: string): Double;
begin
  try
   Result:=StrToFloat(S);
   if IsInfinite(Result) then Result:=NaN;
  except
   Result:=NaN;
  end;
end;

function GetDist(const S: string; Tag: Int64): Double;
begin
  try
   case Tag of
    1: Result:=StrToFloat(S)*AU2KM;
    else Result:=StrToFloat(S);
   end;
   if IsInfinite(Result) then Result:=NaN;
  except
   Result:=NaN;
  end;
end;

function GetBC(const S: string; Tag: Int64): Double;
begin
  try
   case Tag of
    0:   Result:=StrToFloat(S)*1e6;
    else Result:=StrToFloat(S);
   end;
   if IsInfinite(Result) then Result:=NaN;
  except
   Result:=NaN;
  end;
end;

function GetIBC(const S: string; Tag: Int64): Double;
begin
  try
   case Tag of
    0:   Result:=StrToFloat(S)*1e-6;
    else Result:=StrToFloat(S);
   end;
   if IsInfinite(Result) then Result:=NaN;
  except
   Result:=NaN;
  end;
end;

function GetGM(const S: string; Tag: Int64): Double;
// -> km^3/s^2.  CAPS_GM = ('m^3/s^2','km^3/s^2','AU^3/day^2','AU^3/tau^2')
begin
  try
   case Tag of
    0:   Result:=StrToFloat(S)*1.0E-9;                             // m^3/s^2  -> km^3/s^2 (1 km^3 = 1e9 m^3)
    2:   Result:=StrToFloat(S)*(AU_KM*AU_KM*AUPD2_TO_KMPS2);       // AU^3/day^2 -> km^3/s^2 (= AU_KM^3 * SEC2DAY^2)
    3:   Result:=StrToFloat(S)*(AU_KM*AU_KM*AUPTAU2_TO_KMPS2);     // AU^3/tau^2 -> km^3/s^2
    else Result:=StrToFloat(S);                                   // km^3/s^2
   end;
   if IsInfinite(Result) then Result:=NaN;
  except
   Result:=NaN;
  end;
end;

function GetM(const S: string; Tag: Int64): Double;
// -> kg.  CAPS_M = ('kg') only, so Tag is unused.
begin
  try
   Result:=StrToFloat(S);
   if IsInfinite(Result) then Result:=NaN;
  except
   Result:=NaN;
  end;
end;

function GetDensity(const S: string; Tag: Int64): Double;
// -> kg/km^3 (so mass = rho * volume with volume in km^3 gives kg).  CAPS_DENS = ('g/cm^3','kg/m^3','kg/km^3')
begin
  try
   case Tag of
    0:   Result:=StrToFloat(S)*1.0E12;   // g/cm^3 -> kg/km^3
    1:   Result:=StrToFloat(S)*1.0E9;    // kg/m^3 -> kg/km^3
    else Result:=StrToFloat(S);          // kg/km^3
   end;
   if IsInfinite(Result) then Result:=NaN;
  except
   Result:=NaN;
  end;
end;

procedure THlpForm.CompBtnClick(Sender: TObject);
// Compute the derived asteroid quantities from whatever the user entered, store them (canonical units) in FAstData,
// and echo them back into the value edits. Canonical: GM km^3/s^2, M kg, distances km, AMRAT km^2/kg, BC kg/km^2.
//   size   Reff = (Ra*Rb*Rc)^(1/3) [triaxial] | D/2 | 1329-relation from H+Albedo;   D = 2*Reff
//   mass   m    = M | GM/G_CONST | Density*(4/3)*pi*Reff^3   (inverse: implied Density = m / volume)
//   area   A    = pi*Reff^2   (equal-volume sphere cross-section)
//   AMRAT  = A/m ;   BC = 1/(Cd*AMRAT) = m/(Cd*A)
//   photom D = 1329*10^(-H/5)/sqrt(Albedo)  <=>  Albedo = (1329*10^(-H/5)/D)^2  <=>  H = -5*log10(D*sqrt(Albedo)/1329)
const
  CD_DRAG  = 2.2;   // assumed free-molecular drag coefficient (matches JPLConv/Check.pas)
  DENS_MIN = 0.3;   // plausible asteroid bulk-density band [g/cm^3]; outside => warn (comet ~0.3, C ~1.3, S ~2.7, M ~5, iron ~8)
  DENS_MAX = 10.0;
var
  d, in0: TAstData;         // d = working cache; in0 = the raw inputs (NaN where the user left a field blank)
  m, Reff, A, densGCC, mFromGM: Double;   // mass [kg], eff. radius [km], cross-section [km^2], implied density, GM-derived mass
  warn: string;
  densForceShow: Boolean;   // implied density implausible -> override & re-show the density field even if the user typed one

  // (c) echo: only touch a field that was BLANK on input (a freshly-computed value); a user-entered field keeps
  // its text AND its unit button. A newly-populated field is shown in a fixed human-friendly unit.
  procedure Put(e: TEdit; b: TButton; const caps, hints: array of string; utag: Integer; dispVal: Double; wasBlank: Boolean);
  begin
    if (not wasBlank) or IsNan(dispVal) then Exit;
    e.Text := Format('%.6g', [dispVal]);
    if (b <> nil) and (utag >= 0) then
     begin
      b.Tag := utag;  b.Caption := caps[utag];  b.Hint := hints[utag];
     end;
  end;

begin
  if FMode <> MODE_ASTEROID then Exit;

  // --- read inputs (-> canonical units; NaN when blank) ---
  d.GM      := GetGM(Value_AstGM.Text, Unit_AstGM.Tag);
  d.M       := GetM (Value_AstM.Text,  Unit_AstM.Tag);
  d.Ra      := GetDist(Value_AstRa.Text, Unit_AstRa.Tag);
  d.Rb      := GetDist(Value_AstRb.Text, Unit_AstRb.Tag);
  d.Rc      := GetDist(Value_AstRc.Text, Unit_AstRc.Tag);
  d.D       := GetDist(Value_AstD.Text,  Unit_AstD.Tag);
  d.H       := GetNum(Value_AstH.Text);
  d.Albedo  := GetNum(Value_AstAlbedo.Text);
  d.Density := GetDensity(Value_AstDensity.Text, Unit_AstDensity.Tag);  // kg/km^3
  in0 := d;   // snapshot of user input (blank = NaN) for the (c) echo + sanity checks
  in0.AMRAT := NaN;  in0.BC := NaN;   // AMRAT/BC are outputs (not read above) -> always (re)shown

  // --- effective radius / diameter / cross-section (triaxial > diameter > photometric); needed before mass ---
  if (not IsNan(d.Ra)) and (not IsNan(d.Rb)) and (not IsNan(d.Rc)) and (d.Ra > 0.0) and (d.Rb > 0.0) and (d.Rc > 0.0) then
    Reff := Power(d.Ra*d.Rb*d.Rc, 1.0/3.0)                             // equal-volume sphere radius
  else if (not IsNan(d.D)) and (d.D > 0.0) then
    Reff := 0.5*d.D
  else if (not IsNan(d.H)) and (not IsNan(d.Albedo)) and (d.Albedo > 0.0) then
    Reff := 0.5 * 1329.0 * Power(10.0, -d.H/5.0) / Sqrt(d.Albedo)      // 1329-km H/albedo relation -> diameter/2
  else
    Reff := NaN;
  if not IsNan(Reff) then begin d.D := 2.0*Reff;  A := Pi*Reff*Reff; end  // A = cross-section [km^2]
  else A := NaN;

  // --- mass: M, else GM/G_CONST, else Density*volume; cross-fill the blanks (incl. implied density) ---
  if      not IsNan(d.M)  then m := d.M
  else if not IsNan(d.GM) then m := d.GM / G_CONST
  else if (not IsNan(d.Density)) and (not IsNan(Reff)) and (d.Density > 0.0) and (Reff > 0.0) then
    m := d.Density * (4.0/3.0)*Pi*Reff*Reff*Reff                       // rho * volume  [kg/km^3 * km^3 = kg]
  else
    m := NaN;
  if not IsNan(m) then
   begin
    if IsNan(d.M)  then d.M  := m;
    if IsNan(d.GM) then d.GM := m * G_CONST;
   end;

  // --- AMRAT + BC (need area and mass) ---
  if (not IsNan(A)) and (not IsNan(m)) and (m > 0.0) then
   begin
    d.AMRAT := A / m;                     // km^2/kg
    d.BC    := 1.0 / (CD_DRAG * d.AMRAT); // kg/km^2  (= m/(Cd*A))
   end
  else begin d.AMRAT := NaN;  d.BC := NaN; end;

  // --- photometry fill (needs D + exactly one of H/Albedo) ---
  if (not IsNan(d.D)) and (d.D > 0.0) then
   begin
    if (not IsNan(d.H)) and IsNan(d.Albedo)                       then d.Albedo := Sqr(1329.0 * Power(10.0, -d.H/5.0) / d.D);
    if (not IsNan(d.Albedo)) and (d.Albedo > 0.0) and IsNan(d.H)  then d.H      := -5.0 * Log10(d.D * Sqrt(d.Albedo) / 1329.0);
   end;

  // --- sanity checks (soft warnings; they never block the compute) ---
  warn := '';  densForceShow := False;
  // Implied bulk density from the mass & size actually used. Density is soft/derived (never canonical Horizons data),
  // so a blank one is cross-filled and an IMPLAUSIBLE one overrides any typed value -- the field then matches the
  // warning instead of showing a stale figure. (A double-click restores the default.)
  if (not IsNan(m)) and (not IsNan(Reff)) and (m > 0.0) and (Reff > 0.0) then
   begin
    densGCC := (m / ((4.0/3.0)*Pi*Reff*Reff*Reff)) * 1.0E-12;   // kg/km^3 -> g/cm^3
    if IsNan(d.Density) then d.Density := densGCC * 1.0E12;     // cross-fill a blank density (normal (c))
    if (densGCC > DENS_MAX) or (densGCC < DENS_MIN) then
     begin
      d.Density := densGCC * 1.0E12;  densForceShow := True;    // override the typed value so field == warning
      if densGCC > DENS_MAX
        then warn := warn + Format('Implied bulk density %.3g g/cm^3 is implausibly HIGH (> %.1f g/cm^3). Check size vs mass.'#13#10#13#10, [densGCC, DENS_MAX])
        else warn := warn + Format('Implied bulk density %.3g g/cm^3 is implausibly LOW (< %.1f g/cm^3). Check size vs mass.'#13#10#13#10, [densGCC, DENS_MIN]);
     end;
   end;
  // Contradictory GM <-> M (both entered): the compute used M; flag if GM implies a very different mass.
  if (not IsNan(in0.GM)) and (not IsNan(in0.M)) and (in0.M > 0.0) then
   begin
    mFromGM := in0.GM / G_CONST;
    if (mFromGM > 0.0) and (Abs(in0.M - mFromGM) / Max(in0.M, mFromGM) > 0.01) then
      warn := warn + Format('GM and M disagree: entered M = %.4g kg, but GM implies %.4g kg (%.0f%% apart). Using M.'#13#10#13#10,
                            [in0.M, mFromGM, 100.0*Abs(in0.M - mFromGM)/Max(in0.M, mFromGM)]);
   end;

  FAstData := d;   // publish all results at once

  // --- echo back (c): only fields that were BLANK on input; user entries keep their text + unit button ---
  Put(Value_AstGM,      Unit_AstGM,      CAPS_GM,   HINTS_GM,   1, d.GM,              IsNan(in0.GM));      // km^3/s^2
  Put(Value_AstM,       Unit_AstM,       CAPS_M,    HINTS_M,    0, d.M,               IsNan(in0.M));       // kg
  Put(Value_AstD,       Unit_AstD,       CAPS_DIST, HINTS_DIST, 0, d.D,               IsNan(in0.D));       // km
  Put(Value_AstDensity, Unit_AstDensity, CAPS_DENS, HINTS_DENS, 0, d.Density*1.0E-12, IsNan(in0.Density) or densForceShow); // kg/km^3 -> g/cm^3 (override if implausible)
  Put(Value_AstAMRAT,   Unit_AstAMRAT,   CAPS_IBC,  HINTS_IBC,  0, d.AMRAT*1.0E6,     IsNan(in0.AMRAT));   // km^2/kg -> m^2/kg (output)
  Put(Value_AstBC,      Unit_AstBC,      CAPS_BC,   HINTS_BC,   0, d.BC*1.0E-6,       IsNan(in0.BC));      // kg/km^2 -> kg/m^2 (output)
  Put(Value_AstH,       nil,             [],        [],        -1, d.H,               IsNan(in0.H));       // dimensionless
  Put(Value_AstAlbedo,  nil,             [],        [],        -1, d.Albedo,          IsNan(in0.Albedo));  // dimensionless

  if warn <> '' then MessageDlg(TrimRight(warn), mtWarning, [mbOK], 0);
end;

end.
