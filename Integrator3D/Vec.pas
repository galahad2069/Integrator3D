unit Vec;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.ImageList, System.UITypes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ImgList,
  MathPlus64, Vec4D, BSPXFile, CelestialMechanics;

const
  IDX_EPOCH = 7;

type
  TElements = packed record
   case Integer of
    0: (e, q, Peri, Node, Incl, TPP, n, h, Energy, r, v, True, Mean, Ecc, Univ: Double);
    1: (cf: array[0..14] of Double);
  end;

  TButton = class(Vcl.StdCtrls.TButton)
  public
    LinkedPanel: TPanel;
    LinkedIndex: Int64;
  end;

  TVecForm = class(TForm)
    CenterBox: TComboBox;
    FrameBox: TComboBox;
    Panel_Input: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Panel_INames: TPanel;
    Panel_Name_Header: TPanel;
    Name_e: TPanel;
    Name_TPP: TPanel;
    Name_Incl: TPanel;
    Name_Node: TPanel;
    Name_Peri: TPanel;
    Name_q: TPanel;
    Name_Mean: TPanel;
    Name_True: TPanel;
    Name_Epoch: TPanel;
    Name_Period: TPanel;
    name_n: TPanel;
    Name_a: TPanel;
    Panel_IUnits: TPanel;
    Panel_Unit_Header: TPanel;
    Unit_TPP: TButton;
    Unit_Period: TButton;
    Unit_n: TButton;
    Unit_a: TButton;
    Unit_Epoch: TButton;
    Unit_Incl: TButton;
    Unit_Node: TButton;
    Unit_Peri: TButton;
    Unit_q: TButton;
    Unit_e: TButton;
    Unit_True: TButton;
    Unit_Mean: TButton;
    Panel_IValues: TPanel;
    Panel_Value_Header: TPanel;
    TargetEdit: TButtonedEdit;
    ImageList: TImageList;
    CompBtn: TButton;
    Panel_Output: TPanel;
    Splitter3: TSplitter;
    Splitter4: TSplitter;
    Panel_ONames: TPanel;
    Panel3: TPanel;
    Name_SVY: TPanel;
    Name_SVX: TPanel;
    Name_SRZ: TPanel;
    Name_SRY: TPanel;
    Name_SRX: TPanel;
    Name_SVZ: TPanel;
    Panel_OUnits: TPanel;
    Panel23: TPanel;
    Unit_SVZ: TButton;
    Unit_SVY: TButton;
    Unit_SVX: TButton;
    Unit_SRZ: TButton;
    Unit_SRY: TButton;
    Unit_SRX: TButton;
    Panel_OValues: TPanel;
    Panel25: TPanel;
    StartBtn: TButton;
    Value_e: TEdit;
    Value_q: TEdit;
    Value_Peri: TEdit;
    Value_Node: TEdit;
    Value_Incl: TEdit;
    Value_TPP: TEdit;
    Value_a: TEdit;
    Value_n: TEdit;
    Value_Period: TEdit;
    Value_Epoch: TEdit;
    Value_True: TEdit;
    Value_Mean: TEdit;
    OpenDialog: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel4: TPanel;
    Name_RX: TPanel;
    Value_RX: TEdit;
    Unit_RX: TButton;
    Name_RY: TPanel;
    Name_RZ: TPanel;
    Value_RY: TEdit;
    Value_RZ: TEdit;
    Unit_RY: TButton;
    Unit_RZ: TButton;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Name_VX: TPanel;
    Name_VY: TPanel;
    Name_VZ: TPanel;
    Value_VX: TEdit;
    Value_VY: TEdit;
    Value_VZ: TEdit;
    Unit_VX: TButton;
    Unit_VY: TButton;
    Unit_VZ: TButton;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel8: TPanel;
    Value_SVZ: TPanel;
    Value_SRX: TPanel;
    Value_SRY: TPanel;
    Value_SRZ: TPanel;
    Value_SVX: TPanel;
    Value_SVY: TPanel;
    Name_SEpoch: TPanel;
    Value_SEpoch: TPanel;
    Unit_SEpoch: TButton;
    Name_SCenter: TPanel;
    Name_SFrame: TPanel;
    Unit_SCenter: TButton;
    Unit_SFrame: TButton;
    Value_SCenter: TPanel;
    Value_SFrame: TPanel;
    Name_A1: TPanel;
    Panel9: TPanel;
    Name_A2: TPanel;
    Name_A3: TPanel;
    Panel7: TPanel;
    Value_A1: TEdit;
    Value_A2: TEdit;
    Value_A3: TEdit;
    Panel10: TPanel;
    Unit_A3: TButton;
    Unit_A2: TButton;
    Unit_A1: TButton;
    Name_SA1: TPanel;
    Name_SA2: TPanel;
    Name_SA3: TPanel;
    Panel17: TPanel;
    Panel11: TPanel;
    Value_SA1: TPanel;
    Value_SA3: TPanel;
    Value_SA2: TPanel;
    Panel12: TPanel;
    Unit_SA1: TButton;
    Unit_SA2: TButton;
    Unit_SA3: TButton;
    procedure FormCreate(Sender: TObject);
    procedure UnitClick_Dist(Sender: TObject);
    procedure UnitClick_Angle(Sender: TObject);
    procedure UnitClick_Epoch(Sender: TObject);
    procedure UnitClick_AnglePerTime(Sender: TObject);
    procedure UnitClick_Time(Sender: TObject);
    procedure UnitClick_Speed(Sender: TObject);
    procedure TargetEditLeftButtonClick(Sender: TObject);
    procedure ComboDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure WMDrawItem(var Message: TMessage); message WM_DRAWITEM;
    procedure EnableStartBtn(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure NumericOnlyKeyPress(Sender: TObject; var Key: Char);
    procedure CompBtnClick_Geometric(Sender: TObject);
    procedure TargetEditRightButtonClick(Sender: TObject);
    procedure Value_EpochChange(Sender: TObject);
    procedure Unit_EpochClick(Sender: TObject);
    procedure Value_EpochDblClick(Sender: TObject);
    procedure TargetEditChange(Sender: TObject);
  private
    FElements: TElements;
    FState: TState4D;
    FNonGrav: TNonGrav;
    FBaseCaption: string;   // design-time caption, so the Horizons fetch can append/clear a transient status line
    procedure ResetValues;
    procedure DisplayEpoch(Panel: TPanel; ValueIndex, Tag: Int64);
    procedure DisplayDist(Panel: TPanel; ValueIndex, Tag: Int64);
    procedure DisplaySpeed(Panel: TPanel; ValueIndex, Tag: Int64);
    procedure DisplayCenter;
    procedure DisplayFrame;
    procedure DisplayNonGrav;
    procedure DisplayState;
    function LoadHorizonsFile(const FileName: string): Boolean;
    function ParseHorizons(F: TStringList): Boolean;   // parse a Horizons text dump (file or API response) into the UI
  public
    procedure Init;
    procedure ShowBlank;
  end;

var
  VecForm: TVecForm;

implementation

uses Main, Vcl.Themes, Int, System.Net.HttpClient, System.Net.URLClient, System.NetEncoding, RSoftUtils64;

{$R *.dfm}

function GetNum(const S: string): Double;
begin
  try
   Result:=StrToFloat(S);
  except
   Result:=NINF;
  end;
end;

function GetEpoch(const S: string; Tag: Int64): Double;
begin
  try
   case Tag of
    0: Result:=StrToFloat(S);
    1: Result:=(StrToFloat(S)-STANDARD_EPOCH)*DAY2SEC;
    else Result:=StrBSPXTime(S);   // Gregorian '[-]YYYY-MM-DD[.frac]' (CAPS_EPOCH[2]) -> ET; inverse of BSPXTimeStr
   end;
  except
   Result:=NINF;
  end;
end;

function GetDist(const S: string; Tag: Int64): Double;
begin
  try
   case Tag of
    1: Result:=StrToFloat(S)*AU2KM;
    else Result:=StrToFloat(S);
   end;
  except
   Result:=NINF;
  end;
end;

function GetSpeed(const S: string; Tag: Int64): Double;
begin
  try
   case Tag of
    1: Result:=StrToFloat(S)*AUPDAY2KMPS;
    2: Result:=StrToFloat(S)*AUPTAU2KMPS;
    else Result:=StrToFloat(S);
   end;
  except
   Result:=NINF;
  end;
end;

function GetAngle(const S: string; Tag: Int64): Double;
begin
  try
   case Tag of
    1: Result:=DegToRad(StrToFloat(S));
    else Result:=StrToFloat(S);
   end;
  except
   Result:=NINF;
  end;
end;

function GetAnglePerTime(const S: string; Tag: Int64): Double;
//rad/s, rad/hr, rad/day, deg/s, deg/hr, deg/day);
begin
  try
   case Tag of
    1: Result:=StrToFloat(S)*HOUR2SEC;
    2: Result:=StrToFloat(S)*DAY2SEC;
    3: Result:=DegToRad(StrToFloat(S));
    4: Result:=DegToRad(StrToFloat(S))*HOUR2SEC;
    5: Result:=DegToRad(StrToFloat(S))*DAY2SEC;
    else Result:=StrToFloat(S);
   end;
  except
   Result:=NINF;
  end;
end;

function GetTime(const S: string; Tag: Int64): Double;
//sec, hr, day, week(s), month, year
begin
  try
   case Tag of
    1: Result:=StrToFloat(S)*HOUR2SEC;
    2: Result:=StrToFloat(S)*DAY2SEC;
    3: Result:=StrToFloat(S)*WEEK2SEC;
    4: Result:=StrToFloat(S)*MONTH2SEC;
    5: Result:=StrToFloat(S)*TAU2SEC;
    6: Result:=StrToFloat(S)*YEAR2SEC;
    else Result:=StrToFloat(S);
   end;
  except
   Result:=NINF;
  end;
end;

procedure TVecForm.FormCreate(Sender: TObject);
begin
  FBaseCaption := Caption;   // captured once; the Horizons fetch appends a status suffix to this and clears back to it
  Unit_SRX.LinkedPanel   :=Value_SRX;    Unit_SRX.LinkedIndex   :=0;
  Unit_SRY.LinkedPanel   :=Value_SRY;    Unit_SRY.LinkedIndex   :=1;
  Unit_SRZ.LinkedPanel   :=Value_SRZ;    Unit_SRZ.LinkedIndex   :=2;
  Unit_SVX.LinkedPanel   :=Value_SVX;    Unit_SVX.LinkedIndex   :=4;
  Unit_SVY.LinkedPanel   :=Value_SVY;    Unit_SVY.LinkedIndex   :=5;
  Unit_SVZ.LinkedPanel   :=Value_SVZ;    Unit_SVZ.LinkedIndex   :=6;
  Unit_SEpoch.LinkedPanel:=Value_SEpoch; Unit_SEpoch.LinkedIndex:=8;

  Unit_SEpoch.Caption := CAPS_EPOCH[Unit_SEpoch.Tag]; Unit_SEpoch.Hint := HINTS_EPOCH[Unit_SEpoch.Tag];
  Unit_SRX.Caption    := CAPS_DIST[Unit_SRX.Tag    ]; Unit_SRX.Hint    := HINTS_DIST[Unit_SRX.Tag    ];
  Unit_SRY.Caption    := CAPS_DIST[Unit_SRY.Tag    ]; Unit_SRY.Hint    := HINTS_DIST[Unit_SRY.Tag    ];
  Unit_SRZ.Caption    := CAPS_DIST[Unit_SRZ.Tag    ]; Unit_SRZ.Hint    := HINTS_DIST[Unit_SRZ.Tag    ];
  Unit_SVX.Caption    := CAPS_SPEED[Unit_SVX.Tag   ]; Unit_SVX.Hint    := HINTS_SPEED[Unit_SVX.Tag   ];
  Unit_SVY.Caption    := CAPS_SPEED[Unit_SVY.Tag   ]; Unit_SVY.Hint    := HINTS_SPEED[Unit_SVY.Tag   ];
  Unit_SVZ.Caption    := CAPS_SPEED[Unit_SVZ.Tag   ]; Unit_SVZ.Hint    := HINTS_SPEED[Unit_SVZ.Tag   ];
  Unit_RX.Caption     := CAPS_DIST[Unit_RX.Tag     ]; Unit_RX.Hint     := HINTS_DIST[Unit_RX.Tag     ];
  Unit_RY.Caption     := CAPS_DIST[Unit_RY.Tag     ]; Unit_RY.Hint     := HINTS_DIST[Unit_RY.Tag     ];
  Unit_RZ.Caption     := CAPS_DIST[Unit_RZ.Tag     ]; Unit_RZ.Hint     := HINTS_DIST[Unit_RZ.Tag     ];
  Unit_VX.Caption     := CAPS_SPEED[Unit_VX.Tag    ]; Unit_VX.Hint     := HINTS_SPEED[Unit_VX.Tag    ];
  Unit_VY.Caption     := CAPS_SPEED[Unit_VY.Tag    ]; Unit_VY.Hint     := HINTS_SPEED[Unit_VY.Tag    ];
  Unit_VZ.Caption     := CAPS_SPEED[Unit_VZ.Tag    ]; Unit_VZ.Hint     := HINTS_SPEED[Unit_VZ.Tag    ];
  Unit_q.Caption      := CAPS_DIST[Unit_q.Tag      ]; Unit_q.Hint      := HINTS_DIST[Unit_q.Tag      ];
  Unit_a.Caption      := CAPS_DIST[Unit_a.Tag      ]; Unit_a.Hint      := HINTS_DIST[Unit_a.Tag      ];
  Unit_n.Caption      := CAPS_ANGLEPT[Unit_n.Tag   ]; Unit_n.Hint      := HINTS_ANGLEPT[Unit_n.Tag   ];
  Unit_Peri.Caption   := CAPS_ANGLE[Unit_Peri.Tag  ]; Unit_Peri.Hint   := HINTS_ANGLE[Unit_Peri.Tag  ];
  Unit_Node.Caption   := CAPS_ANGLE[Unit_Node.Tag  ]; Unit_Node.Hint   := HINTS_ANGLE[Unit_Node.Tag  ];
  Unit_Incl.Caption   := CAPS_ANGLE[Unit_Incl.Tag  ]; Unit_Incl.Hint   := HINTS_ANGLE[Unit_Incl.Tag  ];
  Unit_True.Caption   := CAPS_ANGLE[Unit_True.Tag  ]; Unit_True.Hint   := HINTS_ANGLE[Unit_True.Tag  ];
  Unit_Mean.Caption   := CAPS_ANGLE[Unit_Mean.Tag  ]; Unit_Mean.Hint   := HINTS_ANGLE[Unit_Mean.Tag  ];
  Unit_Period.Caption := CAPS_TIME[Unit_Period.Tag ]; Unit_Period.Hint := HINTS_TIME[Unit_Period.Tag ];
  Unit_TPP.Caption    := CAPS_EPOCH[Unit_TPP.Tag   ]; Unit_TPP.Hint    := HINTS_EPOCH[Unit_TPP.Tag   ];
  Unit_Epoch.Caption  := CAPS_EPOCH[Unit_Epoch.Tag ]; Unit_Epoch.Hint  := HINTS_EPOCH[Unit_Epoch.Tag ];
end;

procedure TVecForm.ShowBlank;
begin
  ResetValues;
  Value_SCenter.Tag:=0;   // integrands are always stored SSB-relative (the inertial frame); FBarycenter
                          // is a render-time view only. CompBtnClick_Geometric translates output to 0.
  Value_SFrame.Tag:=SPICE_J2000;   // output is always ICRF; Tag is a SPICE frame code, like everywhere else
  DisplayState;
  Show;
end;

procedure TVecForm.StartBtnClick(Sender: TObject);
var
  NG: TNonGrav;
begin
  NG := FNonGrav;   // blank TEdits arrive as Infinity (GetNum sentinel)
  if (not IsInfinite(NG.A1)) or (not IsInfinite(NG.A2)) or (not IsInfinite(NG.A3)) then
   begin
    // At least one coefficient was entered -> a valid nongrav model. Zero the blanks, apply the standard
    // asteroid g(r) (r0 = 1 au, m = 2), enable it, and attach it to the integration.
    if IsInfinite(NG.A1) then NG.A1 := 0.0;
    if IsInfinite(NG.A2) then NG.A2 := 0.0;
    if IsInfinite(NG.A3) then NG.A3 := 0.0;
    NG.r0 := 1.0;  NG.m := 2.0;  NG.Active := True;
    // FState is SSB (Value_SCenter.Tag=0 drove the translation); the center recorded for the integrand
    // is the *authoring view* (FBarycenter at add time), which anchors its osculating-orbit display.
    IntForm.AddIntegration(TargetEdit.Text, FState, MainForm.Barycenter, NG);
   end
  else
   IntForm.AddIntegration(TargetEdit.Text, FState, MainForm.Barycenter);   // no coefficients -> plain add
end;

procedure TVecForm.Init;
var
  i: Int64;
begin
  CenterBox.Clear;
  CenterBox.Items.AddObject('Solar System BC', TObject(Pointer(Int64(0))));
  with MainForm.BSPXFile do
   for i := 0 to DescCount - 1 do
    if (Desc[i].NumComp = 3) and (Desc[i].GM > 0.0) then
     CenterBox.Items.AddObject(
      BSPXStr(Desc[i].TargetName, SizeOf(Desc[i].TargetName)),
      TObject(Pointer(Desc[i].TargetID)));
  CenterBox.ItemIndex := -1;
  CenterBox.Tag:=-1;
end;

procedure TVecForm.ResetValues;
var
  i: Int64;
begin
  StartBtn.Enabled:=False;
  TargetEdit.Text:='';
  CenterBox.ItemIndex:=-1;
  FrameBox.ItemIndex:=-1;
  for i:=0 to Panel_IValues.ControlCount-1 do if Panel_IValues.Controls[i] is TEdit then TEdit(Panel_IValues.Controls[i]).Text:='';
  // only the Value_S* output fields -- the column headers (Panel25 'Value:') and separators are panels too
  for i:=0 to Panel_OValues.ControlCount-1 do if (Panel_OValues.Controls[i] is TPanel) and (Copy(Panel_OValues.Controls[i].Name, 1, 6)='Value_') then TPanel(Panel_OValues.Controls[i]).Caption:='N/A';
  FillChar(FElements, SizeOF(TElements), 0);
  FillChar(FState, SizeOf(TState4D), 0);
  for i:=0 to 2 do begin FState.R.cf[i]:=PINF; FState.V.cf[i]:=PINF; end; FState.Epoch:=PINF;
  FState.R.W:=1.0; FState.Epoch:=PINF;
  for i:=Low(FElements.cf) to High(FElements.cf) do FElements.cf[i]:=PINF;
end;

procedure TVecForm.DisplayEpoch(Panel: TPanel; ValueIndex, Tag: Int64);
var
  Value: Double;
begin
  Value:=FState.Num[ValueIndex];
  if IsInfinite(Value) then Panel.Caption:='N/A' else
  case Tag of
   1: Panel.Caption:=Format('%17.9f', [Value*SEC2DAY + STANDARD_EPOCH]);
   2: Panel.Caption:=Format('%s', [BSPXTimeStr(Value, 5)]);
   else Panel.Caption:=Format('%20.3f', [Value]);
  end;
end;

procedure TVecForm.DisplayDist(Panel: TPanel; ValueIndex, Tag: Int64);
var
  Value: Double;
begin
  Value:=FState.Num[ValueIndex];
  if IsInfinite(Value) then Panel.Caption:='N/A' else
  case Tag of
   1: Panel.Caption:=Format('%17.9f', [Value * KM2AU]);
   else Panel.Caption:=Format('%17.9f', [Value]);
  end;
end;

procedure TVecForm.DisplaySpeed(Panel: TPanel; ValueIndex, Tag: Int64);
var
  Value: Double;
begin
  Value:=FState.Num[ValueIndex];
  if IsInfinite(Value) then Panel.Caption:='N/A' else
  case Tag of
   1: Panel.Caption:=Format('%17.9f', [Value*KMPS2AUPDAY]);
   2: Panel.Caption:=Format('%17.9f', [Value*KMPS2AUPTAU]);
   else Panel.Caption:=Format('%17.9f', [Value]);
  end;
end;

procedure TVecForm.DisplayNonGrav;
  // Signed fixed-width scientific ('+'/'-'/' ' sign slot + 7-digit mantissa + 3-digit exponent) so
  // A1..A3 stay column-aligned whatever their signs. e.g. ' 0.0000000E+000', '-2.9017667E-014'.
  function FmtA(x: Double): string;
  begin
    if IsInfinite(x) then begin Result := 'N/A'; Exit; end;
    if x > 0 then Result := '+' else if x < 0 then Result := '-' else Result := ' ';
    Result := Result + FormatFloat('0.0000000E+000', Abs(x));
  end;
begin
  Value_SA1.Caption := FmtA(FNonGrav.A1);
  Value_SA2.Caption := FmtA(FNonGrav.A2);
  Value_SA3.Caption := FmtA(FNonGrav.A3);
end;

procedure TVecForm.DisplayState;
begin
  DisplayEpoch(Value_SEpoch, Unit_SEpoch.LinkedIndex, Unit_SEpoch.Tag);
  DisplayCenter;
  DisplayFrame;
  DisplayDist(Value_SRX, Unit_SRX.LinkedIndex, Unit_SRX.Tag);
  DisplayDist(Value_SRY, Unit_SRY.LinkedIndex, Unit_SRY.Tag);
  DisplayDist(Value_SRZ, Unit_SRZ.LinkedIndex, Unit_SRZ.Tag);
  DisplaySpeed(Value_SVX, Unit_SVX.LinkedIndex, Unit_SVX.Tag);
  DisplaySpeed(Value_SVY, Unit_SVY.LinkedIndex, Unit_SVY.Tag);
  DisplaySpeed(Value_SVZ, Unit_SVZ.LinkedIndex, Unit_SVZ.Tag);
  DisplayNonGrav;
end;

procedure TVecForm.DisplayCenter;
var
  i: Int64;
  s: string;
begin
  if Value_SCenter.Tag=0 then s:='SSB' else
   begin
    i:=MainForm.BSPXFile.FindDesc(Value_SCenter.Tag);
    if i<0 then s:='Unknown' else s:=BSPXStr(MainForm.BSPXFile.Desc[i].TargetName, SizeOf(MainForm.BSPXFile.Desc[i].TargetName));
   end;
  Value_SCenter.Caption:=Format('%d (%s)', [Value_SCenter.Tag, s]);
end;

procedure TVecForm.DisplayFrame;
begin
  case Value_SFrame.Tag of
   SPICE_J2000:      Value_SFrame.Caption:=Format('%d (ICRF)', [SPICE_J2000]);
   SPICE_ECLIPJ2000: Value_SFrame.Caption:=Format('%d (J2000 Ecliptical)', [SPICE_ECLIPJ2000]);
   else Value_SFrame.Caption:=Format('%d (<unknown>)', [Value_SFrame.Tag]);
  end;
end;

procedure TVecForm.CompBtnClick_Geometric(Sender: TObject);
// Same as CompBtnClick but builds the state vector directly from the true anomaly
// in the perifocal frame, then rotates into the inertial frame via Peri/Incl/Node.
// No universal Kepler propagator is called; the conic-specific Kepler equation
// (elliptic / parabolic Barker / hyperbolic) is solved for the intermediate anomaly.
var
  i, centerID: Int64;
  St, Sc: TState4D;
  M: TMat4D;
  El: TElements;
  a, P, GM, slr, nu, r, EA, MM, dt, S_disc, sGMp: Double;
  b: Boolean;
begin
  try
   if CenterBox.ItemIndex<0 then raise Exception.Create('Invalid value: Center');
   centerID:=Int64(Pointer(CenterBox.Items.Objects[CenterBox.ItemIndex]));

   if (centerID >= 0) and (centerID <= High(MainForm.BSPXFile.Hdr.GM)) then GM:=MainForm.BSPXFile.Hdr.GM[centerID]   // 0..10 (barycentre/Sun): direct header-array read
   else GM:=MainForm.BSPXFile.GetPerturberGM(centerID);
   St.Epoch:=GetEpoch(Value_Epoch.Text, Unit_Epoch.Tag);
   if IsInfinite(St.Epoch) then raise Exception.Create('Invalid value: Epoch');
   if (St.Epoch<MainForm.BSPXFile.Hdr.Epoch0) or (St.Epoch>MainForm.BSPXFile.Hdr.Epoch1) then
    raise Exception.Create(Format('Epoch out of the time coverage of the active .bspx file.%sValid interval = [ %s - %s ]', [BSPXTimeStr(MainForm.BSPXFile.Hdr.Epoch0, 3), BSPXTimeStr(MainForm.BSPXFile.Hdr.Epoch1, 3)]));

   St.R.X:=GetDist(Value_RX.Text, Unit_RX.Tag);
   St.R.Y:=GetDist(Value_RY.Text, Unit_RY.Tag);
   St.R.Z:=GetDist(Value_RZ.Text, Unit_RZ.Tag);
   St.R.W:=1.0;

   St.V.X:=GetSpeed(Value_VX.Text, Unit_VX.Tag);
   St.V.Y:=GetSpeed(Value_VY.Text, Unit_VY.Tag);
   St.V.Z:=GetSpeed(Value_VZ.Text, Unit_VZ.Tag);
   St.V.W:=0.0;

   FNonGrav.A1:=GetNum(Value_A1.Text);
   FNonGrav.A2:=GetNum(Value_A2.Text);
   FNonGrav.A3:=GetNum(Value_A3.Text);
   FNonGrav.r0:=PINF;
   FNonGrav.m:=PINF;
   FNonGrav.Active:=False;

   b:=False; i:=8;
   while (i>0) and not b do
    begin
     i:=i-1;
     b:=IsInfinite(St.Num[i]);
    end;
   if b then
    begin
     // try and compute vectors from geometric elements
     El.e:=GetNum(Value_e.Text);
     if IsInfinite(El.e) or (El.e<0.0) then raise Exception.Create('Invalid value: e');
     El.Peri:=GetAngle(Value_Peri.Text, Unit_Peri.Tag);
     if IsInfinite(El.Peri) then raise Exception.Create('Invalid value: Peri');
     El.Node:=GetAngle(Value_Node.Text, Unit_Node.Tag);
     if IsInfinite(El.Node) then raise Exception.Create('Invalid value: Node');
     El.Incl:=GetAngle(Value_Incl.Text, Unit_Incl.Tag);
     if IsInfinite(El.Incl) then raise Exception.Create('Invalid value: Incl');

     El.q:=GetDist(Value_q.Text, Unit_q.Tag);
     El.n:=GetAnglePerTime(Value_n.Text, Unit_n.Tag);
     a:=GetDist(Value_a.Text, Unit_a.Tag);
     P:=GetTime(Value_Period.Text, Unit_Period.Tag);

     if IsInfinite(El.q) then
      begin
       if El.e = 1.0 then
        begin
         if IsInfinite(El.n) then raise Exception.Create('Invalid value: n');
         El.q:=Power(0.5*GM/(El.n*El.n), 1/3);     // from the parabolic mean motion formula n = Sqrt(GM/(2*q^3))
        end
        else
        begin
         if IsInfinite(a) then
          begin
           if IsInfinite(El.n) then
            begin
             if El.e > 1.0 then
             if not IsInfinite(P) then raise Exception.Create('Invalid value: Period') else raise Exception.Create('Invalid value: n');
             if IsInfinite(P) or (P<0.0) then raise Exception.Create('Invalid value: Period');
             El.n:=TWOPI/P;
            end;
           if El.n <= 0.0 then raise Exception.Create('Invalid value: n');
           a:=Power(GM/(El.n*El.n), 1/3);
           if El.e > 1.0 then a:=-a;
          end;
         if ((El.e < 1.0) and (a <= 0.0)) or ((El.e > 1.0) and (a >= 0.0)) then raise Exception.Create('Invalid value: a');
         El.q:=a*(1-El.e);
        end;
      end;
     if El.q <= 0.0 then raise Exception.Create('Invalid value: q');

     El.TPP :=GetEpoch(Value_TPP.Text,  Unit_TPP.Tag);
     El.True:=GetAngle(Value_True.Text, Unit_True.Tag);
     El.Mean:=GetAngle(Value_Mean.Text, Unit_Mean.Tag);

     // --- determine true anomaly (nu) at St.Epoch ---
     if not IsInfinite(El.True) then
      nu:=El.True
     else
      begin
       // compute the generalised mean anomaly first
       if not IsInfinite(El.TPP) then
        begin
         dt:=St.Epoch-El.TPP;        // seconds since periapsis
         if El.e = 1.0 then
          // parabolic W (Barker parameter), dimensionless
          MM:=Sqrt(GM/(2.0*El.q*El.q*El.q))*dt
         else
          begin
           if IsInfinite(a) then a:=El.q/(1.0-El.e);   // a<0 for hyperbolic
           MM:=Sqrt(GM/Abs(a*a*a))*dt;
          end;
        end
       else if not IsInfinite(El.Mean) then
        MM:=El.Mean             // mean anomaly given directly at St.Epoch
       else
        raise Exception.Create('Need TPP, True or Mean anomaly');

       // solve the conic-specific Kepler equation for the intermediate anomaly EA
       if El.e < 1.0 then
        begin
         // elliptic: M = EA − e·sin(EA)
         EA:=MM;
         repeat
          EA:=EA+(MM-EA+El.e*Sin(EA))/(1.0-El.e*Cos(EA));
         until Abs(MM-EA+El.e*Sin(EA))<TOLERANCE_LEVEL_NEWTON_RAPHSON;
         nu:=2.0*ArcTan2(Sqrt(1.0+El.e)*Sin(EA/2.0), Sqrt(1.0-El.e)*Cos(EA/2.0));
        end
       else if El.e = 1.0 then
        begin
         // parabolic: Barker's equation  D + D³/3 = MM  (tan(nu/2) = D)
         // exact Cardano root; both cube-root arguments are always positive
         S_disc:=Sqrt(9.0*MM*MM/4.0+1.0);
         EA:=Power(3.0*MM/2.0+S_disc, 1.0/3.0)-Power(S_disc-3.0*MM/2.0, 1.0/3.0);
         nu:=2.0*ArcTan(EA);
        end
       else
        begin
         // hyperbolic: M = e·sinh(EA) − EA
         EA:=MM;
         repeat
          EA:=EA+(MM-El.e*Sinh(EA)+EA)/(El.e*Cosh(EA)-1.0);
         until Abs(MM-El.e*Sinh(EA)+EA)<TOLERANCE_LEVEL_NEWTON_RAPHSON;
         nu:=2.0*ArcTan2(Sqrt(El.e+1.0)*Sinh(EA/2.0), Sqrt(El.e-1.0)*Cosh(EA/2.0));
        end;
      end;

     // --- build state vector in the perifocal (PQW) frame ---
     slr:=El.q*(1.0+El.e);                   // semi-latus rectum
     r:=slr/(1.0+El.e*Cos(nu));
     sGMp:=Sqrt(GM/slr);
     St.R.X:=r*Cos(nu);          St.R.Y:=r*Sin(nu);            St.R.Z:=0.0; St.R.W:=1.0;
     St.V.X:=-sGMp*Sin(nu);      St.V.Y:=sGMp*(El.e+Cos(nu));  St.V.Z:=0.0; St.V.W:=0.0;
     St.GM:=0.0; // massless particle

     // --- rotate perifocal → inertial (same sequence as CompBtnClick) ---
     M:=GetRotMat4D(El.Peri, 0.0, 0.0, 1.0);
     if not (El.Incl=0.0) then
      begin
       M:=M*GetRotMat4D(El.Incl, 1.0, 0.0, 0.0);
       M:=M*GetRotMat4D(El.Node, 0.0, 0.0, 1.0);
      end;
     St.R:=St.R*M;
     St.V:=St.V*M;
    end;
   if FrameBox.ItemIndex>0 then
    begin
     M:=GetRotMat4D(CEPS, 1.0, 0.0, 0.0);
     St.R:=St.R*M;
     St.V:=St.V*M;
    end;
   if Value_SCenter.Tag<>centerID then
    begin
     // get position and velocity of TargetID=SCenter.Tag at St.Epoch
     // translate St vectors to center
     // SPICE_J2000 (not FrameBox's index): St has been rotated to ICRF above, and the output is ICRF too
     if not MainForm.BSPXFile.RelativeInterpolate2(centerID, Value_SCenter.Tag, SPICE_J2000, St.Epoch, @Sc) then raise Exception.Create(MainForm.BSPXFile.Error);
     St.R:=St.R+Sc.R;
     St.V:=St.V+Sc.V;
    end;

   FState.Epoch:=St.Epoch;
   FState.R:=St.R;
   FState.V:=St.V;
   FState.GM:=0.0; // massless particle
   DisplayState;
   StartBtn.Enabled:=True;
  except on E: Exception do begin
   StartBtn.Enabled:=False;
   MessageDlg(E.Message, mtError, [mbOK], 0);
  end; end;
end;

procedure TVecForm.EnableStartBtn(Sender: TObject);
var
  i: Int64;
  b: Boolean;
begin
  b:=(TargetEdit.Text<>'') and (CenterBox.ItemIndex>=0) and (FrameBox.ItemIndex>=0) and not IsInfinite(FState.Epoch);
  i:=7;
  while b and (i>0) do
   begin
    i:=i-1;
    b:=not IsInfinite(FState.Num[i]);
   end;
  StartBtn.Enabled:=b;
end;

procedure TVecForm.NumericOnlyKeyPress(Sender: TObject; var Key: Char);
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

procedure TVecForm.TargetEditChange(Sender: TObject);
begin
  Value_EpochChange(Value_Epoch);
  EnableStartBtn(TargetEdit);
end;

procedure TVecForm.TargetEditLeftButtonClick(Sender: TObject);
begin
  if OpenDialog.Execute and not LoadHorizonsFile(OpenDialog.FileName) then MessageDlg('Invalid file type.', mtError, [mbOK], 0);
end;

procedure TVecForm.TargetEditRightButtonClick(Sender: TObject);
// Pull an ICRF/SSB state vector (km, km/s) + nongrav A1/A2/A3 for the TargetEdit search string at Value_Epoch,
// live from the JPL Horizons API, and feed it through the same parser as a saved file. Runs synchronously on the
// VCL thread (the request blocks ~1-3 s); the button is only enabled with a non-empty target + a valid epoch.
var
  ET, JD: Double;
  fs: TFormatSettings;
  target, url, resp, savedEpoch, pxHost: string;
  pxPort: Integer;
  HC: THTTPClient;
  F: TStringList;
begin
  target := Trim(TargetEdit.Text);
  ET := GetEpoch(Value_Epoch.Text, Unit_Epoch.Tag);
  if (target = '') or IsNan(ET) or IsInfinite(ET) then Exit;   // guard (matches the button's enable condition)
  fs := TFormatSettings.Invariant;                             // '.' decimal separator for the URL
  JD := STANDARD_EPOCH + ET*SEC2DAY;                           // TDB Julian Date for TLIST
  // ICRF (REF_PLANE=FRAME), SSB (CENTER=@0), position+velocity (VEC_TABLE=2), km & km/s (OUT_UNITS=KM-S),
  // CSV rows + OBJ_DATA so ParseHorizons finds the same layout + the 'A1= A2= A3=' nongrav line it does in files.
  url := 'https://ssd.jpl.nasa.gov/api/horizons.api?format=text'
       + '&MAKE_EPHEM=YES&EPHEM_TYPE=VECTORS&OBJ_DATA=YES'
       + '&CENTER=' + TNetEncoding.URL.Encode('@0')
       + '&REF_PLANE=FRAME&VEC_TABLE=2&CSV_FORMAT=YES&OUT_UNITS=KM-S'
       + '&COMMAND=' + TNetEncoding.URL.Encode(target)
       + '&TLIST=' + Format('%.9f', [JD], fs);
  HC := THTTPClient.Create;
  F  := TStringList.Create;
  // The fetch always asks Horizons for SSB-centred (@0) ICRF (REF_PLANE=FRAME) vectors, so snap both boxes to
  // match now -- otherwise the user could leave them on e.g. Jupiter/Ecliptic and think the returned vectors are
  // wrong or that the boxes were ignored. (ParseHorizons re-affirms these from the response on success; doing it
  // up front also covers the "contacting..." wait and the failure path.)
  CenterBox.ItemIndex := 0;                     // 'Solar System BC' (centerID 0)
  FrameBox.ItemIndex  := 0;                     // ICRF (J2000 Equatorial)
  Caption := FBaseCaption + '   -   contacting Horizons...';   // busy status (also overwrites any leftover suffix)
  TargetEdit.RightButton.Enabled := False;     // don't let the (synchronous) request be re-fired from under itself
  Screen.Cursor := crHourGlass;
  Update;                                       // flush the box reset + busy caption + greyed button now -- the Get below blocks the VCL thread
  try
    HC.ConnectionTimeout := 10000;             // fail fast on a dead link (10 s to connect, 15 s for the response)
    HC.ResponseTimeout   := 15000;             //   rather than freezing the VCL thread on the OS default
    // Pin the user's Windows proxy: left to itself the RTL can fail its own proxy discovery and then go direct,
    // which behind a firewall hangs to the timeout above instead of failing (see GetSystemProxy). No credentials
    // here on purpose -- WinHTTP answers an NTLM/Negotiate challenge with the Windows logon by itself, and a
    // Basic/Digest proxy would need a prompt this synchronous fetch has no room for (it would just time out).
    if GetSystemProxy(pxHost, pxPort) then HC.ProxySettings := TProxySettings.Create(pxHost, pxPort);
    try
     resp := HC.Get(url).ContentAsString;
    except on E: Exception do
     // Transient network trouble (timeout / no route): a non-intrusive caption status, not a modal, so a bad
     // connection can't trap the user behind a dialog. It clears on the next fetch (busy caption set above).
     begin Caption := FBaseCaption + '   -   Horizons unreachable (timed out?)'; Exit; end;
    end;
    Caption := FBaseCaption;                    // response in hand -- drop the busy status
    F.Text := resp;
    savedEpoch := Value_Epoch.Text;             // ParseHorizons -> ResetValues blanks the input edits before it can fail
    if not ParseHorizons(F) then   // a genuine "bad request" (ambiguous/unknown target): actionable, so keep the modal
     begin
      Value_Epoch.Text := savedEpoch;           // the epoch was valid (it drove the request), so don't make the user retype it
      TargetEdit.Text  := target;                // and keep the search string visible so they can fix it (e.g. add the trailing ';') rather than retype
      MessageDlg('Could not read a state vector for "' + target + '" from Horizons.'#13#10 +
                 'Small-body designations need a trailing '';'' (e.g. ''101955;''); an ambiguous name returns a list, not a vector.',
                 mtError, [mbOK], 0);
     end;
  finally
    F.Free;
    HC.Free;
    Screen.Cursor := crDefault;
    TargetEdit.RightButton.Enabled := not IsInfinite(GetEpoch(Value_Epoch.Text, Unit_Epoch.Tag));   // re-sync (matches Value_EpochChange)
  end;
end;

function TVecForm.ParseHorizons(F: TStringList): Boolean;

  function FindVal(const Line, Key: string; out Value: string): Boolean;
  var
    p, q: Integer;
  begin
    Result := False;
    p := Pos(Key, Line);
    if p = 0 then Exit;
    p := p + Length(Key);
    while (p <= Length(Line)) and (Line[p] = ' ') do Inc(p);
    if (p > Length(Line)) or (Line[p] <> '=') then Exit;
    Inc(p);
    while (p <= Length(Line)) and (Line[p] = ' ') do Inc(p);
    q := p;
    while (q <= Length(Line)) and not CharInSet(Line[q], [' ', ',', #9]) do Inc(q);
    Value := Copy(Line, p, q - p);
    Result := Value <> '';
  end;

  procedure SetBtn(Btn: TButton; ATag: Integer; const ACap, AHint: string);
  begin
    Btn.Tag := ATag; Btn.Caption := ACap; Btn.Hint := AHint;
  end;

var
  i, j, p, q: Integer;
  Line: string;
  isVector, typeFound: Boolean;
  centerID: Int64;
  frameIdx, distTag, speedTag, angleTag, nTag, periodTag: Integer;
  soeIdx: Integer;
  sTarget: string;
  sA1, sA2, sA3: string;
  sEpoch, sX, sY, sZ, sVX, sVY, sVZ: string;
  sEC, sQR, sIN, sOM, sW, sTp, sN, sMA, sTA, sA, sPR: string;
  parts: TArray<string>;
  // Value string that follows `key` (e.g. 'A2=') on a Horizons header line (up to space or ';').
  function GrabStr(const s, key: string): string;
  var a, b: Integer;
  begin
    Result := '';
    a := Pos(key, s);  if a = 0 then Exit;
    Inc(a, Length(key));
    while (a <= Length(s)) and (s[a] = ' ') do Inc(a);
    b := a;
    while (b <= Length(s)) and (s[b] <> ' ') and (s[b] <> ';') do Inc(b);
    Result := Copy(s, a, b - a);
  end;
begin
  try
    ResetValues;
    DisplayState;

    isVector := False; typeFound := False;
      centerID := -1;    frameIdx  := -1;
      distTag  := 0;     speedTag  := 0;
      angleTag := 0;     nTag      := 4;     periodTag := 0;
      soeIdx   := -1;    sTarget   := '';
      sA1 := '';  sA2 := '';  sA3 := '';

      for i := 0 to F.Count - 1 do
      begin
        Line := F[i];
        if Pos('Output type', Line) > 0 then
        begin
          typeFound := True;
          if      Pos('cartesian states',    Line) > 0 then isVector := True
          else if Pos('osculating elements', Line) > 0 then isVector := False
          else raise Exception.Create('Unrecognised output type');
        end
        else if Pos('Output units', Line) > 0 then
        begin
          if      Pos('AU-D', Line) > 0 then begin distTag := 1; speedTag := 1; end
          else if Pos('KM-S', Line) > 0 then begin distTag := 0; speedTag := 0; end
          else raise Exception.Create('Unrecognised output units');
          if Pos('deg', Line) > 0 then angleTag := 1 else angleTag := 0;
          if distTag = 1 then begin nTag := 6; periodTag := 2; end  // deg/day, days
          else               begin nTag := 4; periodTag := 0; end;  // deg/s, seconds
        end
        else if Pos('Reference frame', Line) > 0 then
        begin
          if      Pos('ICRF',     Line) > 0 then frameIdx := 0
          else if Pos('Ecliptic', Line) > 0 then frameIdx := 1
          else raise Exception.Create('Unrecognised reference frame');
        end
        else if Pos('Target body name:', Line) > 0 then
        begin
          p := Pos(':', Line) + 1;
          q := Pos('{', Line);
          if q <= 0 then q := Length(Line) + 1;
          sTarget := Trim(Copy(Line, p, q - p));
        end
        else if Pos('Center body name:', Line) > 0 then
        begin
          p := Pos('(', Line); q := Pos(')', Line);
          if (p > 0) and (q > p) then
            centerID := StrToInt64(Trim(Copy(Line, p + 1, q - p - 1)));
        end
        else if (Pos('A1=', Line) > 0) and (Pos('A2=', Line) > 0) then
        begin
          // Asteroid nongrav coefficients ("A1= .. A2= .. A3= .."); the units-legend line has 'A1,' not
          // 'A1=', so it is skipped. Grab the value strings for the Value_A* edits (applied below).
          sA1 := GrabStr(Line, 'A1=');
          sA2 := GrabStr(Line, 'A2=');
          sA3 := GrabStr(Line, 'A3=');
        end
        else if Trim(Line) = '$$SOE' then
        begin
          soeIdx := i;
          Break;
        end;
      end;

      if not typeFound then raise Exception.Create('Output type not found');
      if soeIdx < 0    then raise Exception.Create('$$SOE marker not found');
      if frameIdx < 0  then raise Exception.Create('Reference frame not found');

      if isVector then
      begin
        if soeIdx + 1 >= F.Count then raise Exception.Create('No data after $$SOE');
        Line := F[soeIdx + 1];
        if Trim(Line) = '$$EOE' then raise Exception.Create('No data records found');
        parts := Line.Split([',']);
        if Length(parts) < 8 then raise Exception.Create('Malformed vector record');
        sEpoch := Trim(parts[0]);
        sX     := Trim(parts[2]);
        sY     := Trim(parts[3]);
        sZ     := Trim(parts[4]);
        sVX    := Trim(parts[5]);
        sVY    := Trim(parts[6]);
        sVZ    := Trim(parts[7]);
      end
      else
      begin
        if soeIdx + 5 >= F.Count then raise Exception.Create('Truncated element block');
        Line := F[soeIdx + 1];
        if Trim(Line) = '$$EOE' then raise Exception.Create('No data records found');
        p := Pos(' = ', Line);
        if p <= 0 then raise Exception.Create('Malformed epoch line');
        sEpoch := Trim(Copy(Line, 1, p - 1));
        if not FindVal(F[soeIdx + 2], 'EC', sEC) then raise Exception.Create('EC not found');
        if not FindVal(F[soeIdx + 2], 'QR', sQR) then raise Exception.Create('QR not found');
        if not FindVal(F[soeIdx + 2], 'IN', sIN) then raise Exception.Create('IN not found');
        if not FindVal(F[soeIdx + 3], 'OM', sOM) then raise Exception.Create('OM not found');
        if not FindVal(F[soeIdx + 3], 'W',  sW)  then raise Exception.Create('W not found');
        if not FindVal(F[soeIdx + 3], 'Tp', sTp) then raise Exception.Create('Tp not found');
        if not FindVal(F[soeIdx + 4], 'N',  sN)  then raise Exception.Create('N not found');
        if not FindVal(F[soeIdx + 4], 'MA', sMA) then raise Exception.Create('MA not found');
        if not FindVal(F[soeIdx + 4], 'TA', sTA) then raise Exception.Create('TA not found');
        if not FindVal(F[soeIdx + 5], 'A',  sA)  then raise Exception.Create('A not found');
        sPR := '';
        FindVal(F[soeIdx + 5], 'PR', sPR);
      end;

      // === Populate UI ===
      FrameBox.ItemIndex := frameIdx;
      CenterBox.ItemIndex := -1;
      if centerID >= 0 then
        for j := 0 to CenterBox.Items.Count - 1 do
          if Int64(Pointer(CenterBox.Items.Objects[j])) = centerID then
          begin
            CenterBox.ItemIndex := j;
            Break;
          end;

      TargetEdit.Text := sTarget;
      Value_A1.Text := sA1;  Value_A2.Text := sA2;  Value_A3.Text := sA3;   // '' when the file has no nongrav
      SetBtn(Unit_Epoch, 1, CAPS_EPOCH[1], HINTS_EPOCH[1]);
      Value_Epoch.Text := sEpoch;

      if isVector then
      begin
        SetBtn(Unit_RX, distTag,  CAPS_DIST[distTag],   HINTS_DIST[distTag]);
        SetBtn(Unit_RY, distTag,  CAPS_DIST[distTag],   HINTS_DIST[distTag]);
        SetBtn(Unit_RZ, distTag,  CAPS_DIST[distTag],   HINTS_DIST[distTag]);
        SetBtn(Unit_VX, speedTag, CAPS_SPEED[speedTag], HINTS_SPEED[speedTag]);
        SetBtn(Unit_VY, speedTag, CAPS_SPEED[speedTag], HINTS_SPEED[speedTag]);
        SetBtn(Unit_VZ, speedTag, CAPS_SPEED[speedTag], HINTS_SPEED[speedTag]);
        Value_RX.Text := sX;   Value_RY.Text := sY;   Value_RZ.Text := sZ;
        Value_VX.Text := sVX;  Value_VY.Text := sVY;  Value_VZ.Text := sVZ;
        Value_e.Text := ''; Value_q.Text := ''; Value_Peri.Text := ''; Value_Node.Text := '';
        Value_Incl.Text := ''; Value_TPP.Text := ''; Value_a.Text := ''; Value_n.Text := '';
        Value_Period.Text := ''; Value_True.Text := ''; Value_Mean.Text := '';
      end
      else
      begin
        SetBtn(Unit_q,      distTag,   CAPS_DIST[distTag],     HINTS_DIST[distTag]);
        SetBtn(Unit_a,      distTag,   CAPS_DIST[distTag],     HINTS_DIST[distTag]);
        SetBtn(Unit_Peri,   angleTag,  CAPS_ANGLE[angleTag],   HINTS_ANGLE[angleTag]);
        SetBtn(Unit_Node,   angleTag,  CAPS_ANGLE[angleTag],   HINTS_ANGLE[angleTag]);
        SetBtn(Unit_Incl,   angleTag,  CAPS_ANGLE[angleTag],   HINTS_ANGLE[angleTag]);
        SetBtn(Unit_True,   angleTag,  CAPS_ANGLE[angleTag],   HINTS_ANGLE[angleTag]);
        SetBtn(Unit_Mean,   angleTag,  CAPS_ANGLE[angleTag],   HINTS_ANGLE[angleTag]);
        SetBtn(Unit_TPP,    1,         CAPS_EPOCH[1],          HINTS_EPOCH[1]);
        SetBtn(Unit_n,      nTag,      CAPS_ANGLEPT[nTag],     HINTS_ANGLEPT[nTag]);
        SetBtn(Unit_Period, periodTag, CAPS_TIME[periodTag],   HINTS_TIME[periodTag]);
        Value_e.Text    := sEC;  Value_q.Text    := sQR;  Value_Incl.Text := sIN;
        Value_Node.Text := sOM;  Value_Peri.Text := sW;   Value_TPP.Text  := sTp;
        Value_n.Text    := sN;   Value_Mean.Text := sMA;  Value_True.Text := sTA;
        Value_a.Text    := sA;   Value_Period.Text := sPR;
        Value_RX.Text := ''; Value_RY.Text := ''; Value_RZ.Text := '';
        Value_VX.Text := ''; Value_VY.Text := ''; Value_VZ.Text := '';
      end;
      CompBtn.OnClick(CompBtn);
      Result := True;
  except on E: Exception do
    Result := False;
  end;
end;

function TVecForm.LoadHorizonsFile(const FileName: string): Boolean;
var
  F: TStringList;
begin
  Result := False;
  F := TStringList.Create;
  try
    try F.LoadFromFile(FileName); except Exit; end;   // Result stays False on a read error
    Result := ParseHorizons(F);
  finally
    F.Free;
  end;
end;

procedure TVecForm.UnitClick_Dist(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod 2;
  Btn.Caption := CAPS_DIST[Btn.Tag];
  Btn.Hint    := HINTS_DIST[Btn.Tag];
  if Btn.LinkedPanel<>nil then DisplayDist(Btn.LinkedPanel, Btn.LinkedIndex, Btn.Tag);
end;

procedure TVecForm.UnitClick_Speed(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_SPEED);
  Btn.Caption := CAPS_SPEED[Btn.Tag];
  Btn.Hint    := HINTS_SPEED[Btn.Tag];
  if Btn.LinkedPanel<>nil then DisplaySpeed(Btn.LinkedPanel, Btn.LinkedIndex, Btn.Tag);
end;

procedure TVecForm.UnitClick_Angle(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_ANGLE);
  Btn.Caption := CAPS_ANGLE[Btn.Tag];
  Btn.Hint    := HINTS_ANGLE[Btn.Tag];
end;

procedure TVecForm.UnitClick_AnglePerTime(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_ANGLEPT);
  Btn.Caption := CAPS_ANGLEPT[Btn.Tag];
  Btn.Hint    := HINTS_ANGLEPT[Btn.Tag];
end;

procedure TVecForm.UnitClick_Time(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_TIME);
  Btn.Caption := CAPS_TIME[Btn.Tag];
  Btn.Hint    := HINTS_TIME[Btn.Tag];
end;

procedure TVecForm.Unit_EpochClick(Sender: TObject);
begin
  UnitClick_Epoch(Sender);
  Value_EpochChange(Value_Epoch);
end;

procedure TVecForm.Value_EpochChange(Sender: TObject);
begin
  TargetEdit.RightButton.Enabled:=(TargetEdit.Text<>'') and not IsInfinite(GetEpoch(Value_Epoch.Text, Unit_Epoch.Tag));
end;

procedure TVecForm.Value_EpochDblClick(Sender: TObject);
var
  ST: TSystemTime;
begin
  GetSystemTime(ST);
  Value_Epoch.Text:=Format('%.4d-%.2d-%.2d.000', [ST.wYear, ST.wMonth, ST.wDay]);
  Unit_Epoch.Tag:=2;
  Unit_Epoch.Caption:=CAPS_EPOCH[2];
  Unit_Epoch.Hint:=HINTS_EPOCH[2];
  Value_EpochChange(Value_Epoch);
end;

procedure TVecForm.UnitClick_Epoch(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_EPOCH);
  Btn.Caption := CAPS_EPOCH[Btn.Tag];
  Btn.Hint    := HINTS_EPOCH[Btn.Tag];
  if Btn.LinkedPanel<>nil then DisplayEpoch(Btn.LinkedPanel, Btn.LinkedIndex, Btn.Tag);
end;

procedure TVecForm.WMDrawItem(var Message: TMessage);
var
  DIS: PDrawItemStruct;
  Combo: TComboBox;
begin
  DIS := PDrawItemStruct(Message.LParam);
  if (DIS <> nil) and (Integer(DIS^.itemID) < 0) then
   begin
    Combo := nil;
    if DIS^.hwndItem = CenterBox.Handle then Combo := CenterBox
    else if DIS^.hwndItem = FrameBox.Handle then Combo := FrameBox;
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

procedure TVecForm.ComboDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
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

end.
