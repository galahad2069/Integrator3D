unit Osc;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  MathPlus64, Vec4D, BSPXFile, CelestialMechanics, Vec;

type
  TOscForm = class(TForm)
    TargetBox: TComboBox;
    CenterBox: TComboBox;
    FrameBox: TComboBox;
    Panel_All: TPanel;
    Panel_Names: TPanel;
    Splitter1: TSplitter;
    Panel_Units: TPanel;
    Splitter2: TSplitter;
    Panel_Values: TPanel;
    Panel_Name_Header: TPanel;
    Panel_Value_Header: TPanel;
    Panel_Unit_Header: TPanel;
    Unit_r: TButton;
    Unit_Epoch: TButton;
    Unit_Energy: TButton;
    Unit_h: TButton;
    Unit_Period: TButton;
    Unit_n: TButton;
    Unit_a: TButton;
    Unit_TPP: TButton;
    Unit_Incl: TButton;
    Unit_Node: TButton;
    Unit_Peri: TButton;
    Unit_q: TButton;
    Unit_e: TButton;
    Value_a: TPanel;
    Value_TPP: TPanel;
    Value_Incl: TPanel;
    Value_Node: TPanel;
    Value_Peri: TPanel;
    Value_q: TPanel;
    Value_e: TPanel;
    Name_Ecc: TPanel;
    Name_e: TPanel;
    Name_TPP: TPanel;
    Name_Incl: TPanel;
    Name_Node: TPanel;
    Name_Peri: TPanel;
    Name_q: TPanel;
    Name_Mean: TPanel;
    Name_True: TPanel;
    Name_r: TPanel;
    Name_Epoch: TPanel;
    Name_Energy: TPanel;
    Name_h: TPanel;
    Name_Period: TPanel;
    name_n: TPanel;
    Name_a: TPanel;
    Name_Univ: TPanel;
    Value_n: TPanel;
    Value_Period: TPanel;
    Value_h: TPanel;
    Value_Energy: TPanel;
    Value_Epoch: TPanel;
    Value_r: TPanel;
    Value_True: TPanel;
    Value_Mean: TPanel;
    Value_Ecc: TPanel;
    Value_Univ: TPanel;
    Unit_True: TButton;
    Unit_Mean: TButton;
    Unit_Ecc: TButton;
    Unit_Univ: TButton;
    Name_v: TPanel;
    Value_v: TPanel;
    Unit_v: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ComboDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure WMDrawItem(var Message: TMessage); message WM_DRAWITEM;
    procedure UnitClick_Dist(Sender: TObject);
    procedure UnitClick_Angle(Sender: TObject);
    procedure UnitClick_Epoch(Sender: TObject);
    procedure UnitClick_AnglePerTime(Sender: TObject);
    procedure UnitClick_Time(Sender: TObject);
    procedure UnitClick_Dist2PerTime(Sender: TObject);
    procedure UnitClick_Dist2PerTime2(Sender: TObject);
    procedure UnitClick_SqrtDist(Sender: TObject);
    procedure UnitClick_Speed(Sender: TObject);
    procedure HeaderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure HeaderMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ComboChange(Sender: TObject);
  private
    FSnapshot: TState4DArray;
    FRefreshTimer: TTimer;
    FCount, FIndex: Int64;
    FBSPXCount: Int64;
    FElements: array[0..1] of TElements;
    procedure TimerTick(Sender: TObject);
  public
    procedure Refresh;
  end;

implementation

uses Main, Int, Vcl.Themes, System.Math;

{$R *.dfm}

procedure TOscForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MainForm.UnregisterOscForm(Self);
  Action := caFree;
end;

procedure TOscForm.FormCreate(Sender: TObject);
var
  i: Int64;
  s: string;
begin
  TargetBox.Clear; FCount:=0; FIndex:=0;
  FillChar(FElements, SizeOf(FElements), 0);
  with MainForm.BSPXFile do
  for i:=0 to DescCount-1 do if Desc[i].NumComp=3 then
   begin
    s:=BSPXStr(Desc[i].TargetName, Length(Desc[i].TargetName));
    TargetBox.Items.AddObject(s, TObject(Pointer(Desc[i].TargetID)));
    CenterBox.Items.AddObject(s, TObject(Pointer(Desc[i].TargetID)));
   end;
  FBSPXCount := TargetBox.Items.Count;
  for i := 0 to Length(IntForm.IntegrationNames)-1 do
   TargetBox.Items.AddObject(IntForm.IntegrationNames[i], TObject(Pointer(-(i+1))));
  FrameBox.ItemIndex:=1;  // J2000 Ecliptical
  CenterBox.ItemIndex:=0;
  for i:=0 to CenterBox.Items.Count-1 do
   if Int64(Pointer(CenterBox.Items.Objects[i]))=MainForm.Barycenter then
    begin CenterBox.ItemIndex:=i; Break; end;
  // unit button Tags: index of current unit selection
  Unit_q.Tag:=1; Unit_r.Tag:=1; Unit_a.Tag:=1;
  Unit_Peri.Tag:=1; Unit_Node.Tag:=1; Unit_Incl.Tag:=1;
  Unit_True.Tag:=1; Unit_Mean.Tag:=1; Unit_Ecc.Tag:=1;
  Unit_Epoch.Tag:=2; Unit_TPP.Tag:=2;
  Unit_n.Tag:=5; Unit_Period.Tag:=2;
  Unit_h.Tag:=1; Unit_Energy.Tag:=1; Unit_Univ.Tag:=1; Unit_v.Tag:=1;
  if (MainForm.Barycenter <> 0) and (MainForm.Barycenter <> 10) then
   begin
    Unit_q.Tag:=0; Unit_r.Tag:=0; Unit_a.Tag:=0;
    Unit_v.Tag:=0; Unit_h.Tag:=0; Unit_Energy.Tag:=0; Unit_Univ.Tag:=0;
   end;
  Unit_q.Caption      := CAPS_DIST[Unit_q.Tag];          Unit_q.Hint      := HINTS_DIST[Unit_q.Tag];
  Unit_r.Caption      := CAPS_DIST[Unit_r.Tag];          Unit_r.Hint      := HINTS_DIST[Unit_r.Tag];
  Unit_a.Caption      := CAPS_DIST[Unit_a.Tag];          Unit_a.Hint      := HINTS_DIST[Unit_a.Tag];
  Unit_v.Caption      := CAPS_SPEED[Unit_v.Tag];         Unit_v.Hint      := HINTS_SPEED[Unit_v.Tag];
  Unit_h.Caption      := CAPS_DIST2PT[Unit_h.Tag];       Unit_h.Hint      := HINTS_DIST2PT[Unit_h.Tag];
  Unit_Energy.Caption := CAPS_DIST2PT2[Unit_Energy.Tag]; Unit_Energy.Hint := HINTS_DIST2PT2[Unit_Energy.Tag];
  Unit_Univ.Caption   := CAPS_SQRTDIST[Unit_Univ.Tag];   Unit_Univ.Hint   := HINTS_SQRTDIST[Unit_Univ.Tag];
  Unit_Peri.Caption   := CAPS_ANGLE[Unit_Peri.Tag];      Unit_Peri.Hint   := HINTS_ANGLE[Unit_Peri.Tag];
  Unit_Node.Caption   := CAPS_ANGLE[Unit_Node.Tag];      Unit_Node.Hint   := HINTS_ANGLE[Unit_Node.Tag];
  Unit_Incl.Caption   := CAPS_ANGLE[Unit_Incl.Tag];      Unit_Incl.Hint   := HINTS_ANGLE[Unit_Incl.Tag];
  Unit_True.Caption   := CAPS_ANGLE[Unit_True.Tag];      Unit_True.Hint   := HINTS_ANGLE[Unit_True.Tag];
  Unit_Mean.Caption   := CAPS_ANGLE[Unit_Mean.Tag];      Unit_Mean.Hint   := HINTS_ANGLE[Unit_Mean.Tag];
  Unit_Ecc.Caption    := CAPS_ANGLE[Unit_Ecc.Tag];       Unit_Ecc.Hint    := HINTS_ANGLE[Unit_Ecc.Tag];
  Unit_Epoch.Caption  := CAPS_EPOCH[Unit_Epoch.Tag];     Unit_Epoch.Hint  := HINTS_EPOCH[Unit_Epoch.Tag];
  Unit_TPP.Caption    := CAPS_EPOCH[Unit_TPP.Tag];       Unit_TPP.Hint    := HINTS_EPOCH[Unit_TPP.Tag];
  Unit_n.Caption      := CAPS_ANGLEPT[Unit_n.Tag];       Unit_n.Hint      := HINTS_ANGLEPT[Unit_n.Tag];
  Unit_Period.Caption := CAPS_TIME[Unit_Period.Tag];     Unit_Period.Hint := HINTS_TIME[Unit_Period.Tag];
  FRefreshTimer:=TTimer.Create(Self);
  FRefreshTimer.Interval:=200;
  FRefreshTimer.OnTimer:=TimerTick;
  FRefreshTimer.Enabled:=True;
  TargetBox.OnChange:=ComboChange;
  CenterBox.OnChange:=ComboChange;
  FrameBox.OnChange :=ComboChange;
end;

procedure TOscForm.ComboChange(Sender: TObject);
begin
  FCount := 0;
  FillChar(FElements[1], SizeOf(TElements), 0);
end;

procedure TOscForm.HeaderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  TPanel(Sender).BevelOuter:=bvLowered;
end;

procedure TOscForm.HeaderMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
const
  C: array[0..1] of string=('Value:', 'Value (avg):');
begin
  TPanel(Sender).BevelOuter:=bvRaised;
  FIndex:=1-FIndex;
  TPanel(Sender).Caption:=C[FIndex];
  if not FRefreshTimer.Enabled then Refresh;
end;

procedure TOscForm.WMDrawItem(var Message: TMessage);
var
  DIS: PDrawItemStruct;
  Combo: TComboBox;
begin
  DIS := PDrawItemStruct(Message.LParam);
  if (DIS <> nil) and (Integer(DIS^.itemID) < 0) then
   begin
    Combo := nil;
    if DIS^.hwndItem = TargetBox.Handle then Combo := TargetBox
    else if DIS^.hwndItem = CenterBox.Handle then Combo := CenterBox
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

procedure TOscForm.ComboDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
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

procedure TOscForm.Refresh;
var
  i, j, ti, ci, TLen, CLen, bodyIdx: Int64;
  TargetID, CenterID: Int64;
  TAnc, CAnc: array[0..7] of Int64;
  TDesc, CDesc: array[0..7] of Int64;
  S: TState4D;
  GM_c, GM_t, a, ttp: Double;
  El: TElements;
  lbl: string;
  fs: TFormatSettings;
  procedure SetNA;
  begin
    Value_e.Caption      := 'N/A'; Value_q.Caption     := 'N/A';
    Value_Peri.Caption   := 'N/A'; Value_Node.Caption  := 'N/A';
    Value_Incl.Caption   := 'N/A'; Value_True.Caption  := 'N/A';
    Value_a.Caption      := 'N/A'; Value_n.Caption     := 'N/A';
    Value_Period.Caption := 'N/A'; Value_h.Caption     := 'N/A';
    Value_Energy.Caption := 'N/A'; Value_Epoch.Caption := 'N/A';
    Value_r.Caption      := 'N/A'; Value_Mean.Caption  := 'N/A';
    Value_Ecc.Caption    := 'N/A'; Value_Univ.Caption  := 'N/A';
    Value_TPP.Caption    := 'N/A'; Value_v.Caption     := 'N/A';
  end;
begin
  if TargetBox.DroppedDown or CenterBox.DroppedDown or FrameBox.DroppedDown then Exit;
  fs := TFormatSettings.Create('en-US');
  SetNA;
  if Length(FSnapshot) = 0 then Exit;
  case Unit_Epoch.Tag of
    0: Value_Epoch.Caption := FormatFloat('0.###', FSnapshot[0].Epoch, fs);
    1: Value_Epoch.Caption := Format('%14.6f', [STANDARD_EPOCH + FSnapshot[0].Epoch / DAY2SEC], fs);
    2: Value_Epoch.Caption := BSPXTimeStr(FSnapshot[0].Epoch, 3);
  end;
  if (TargetBox.ItemIndex < 0) or (CenterBox.ItemIndex < 0) then Exit;
  TargetID := Int64(Pointer(TargetBox.Items.Objects[TargetBox.ItemIndex]));
  CenterID := Int64(Pointer(CenterBox.Items.Objects[CenterBox.ItemIndex]));
  if TargetID = CenterID then Exit;

  S := Default(TState4D);
  if TargetID < 0 then
   begin
    // Integration body: state is already barycentric; subtract center's chain.
    // The render thread mutates IntegrationS[].R/.V in place during integration,
    // so grab this body's (R,V) atomically under PublicLock to avoid a torn read.
    bodyIdx := -TargetID - 1;
    IntForm.PublicLock.Acquire;
    try
     if bodyIdx >= Length(IntForm.IntegrationS) then Exit;  // finally still releases
     S.R := IntForm.IntegrationS[bodyIdx].R;
     S.V := IntForm.IntegrationS[bodyIdx].V;
    finally
     IntForm.PublicLock.Release;
    end;
    // Center ancestor chain (BSPXFile.Desc is static — no lock needed).
    CLen := 0; CAnc[0] := CenterID;
    while CLen < 7 do
     begin
      i := -1;
      for j := 0 to MainForm.BSPXFile.DescCount-1 do
       if (MainForm.BSPXFile.Desc[j].TargetID = CAnc[CLen]) and
          (MainForm.BSPXFile.Desc[j].NumComp = 3) then
        begin i := j; Break; end;
      if i < 0 then Break;
      CDesc[CLen] := i; Inc(CLen); CAnc[CLen] := MainForm.BSPXFile.Desc[i].CenterID;
     end;
    for i := 0 to CLen-1 do
     begin S.R := S.R - FSnapshot[CDesc[i]].R; S.V := S.V - FSnapshot[CDesc[i]].V; end;
    if CLen>0 then GM_c := MainForm.BSPXFile.Desc[CDesc[0]].GM   // centre descriptor already located above -> O(1), no table search
    else if (CenterID >= 0) and (CenterID <= High(MainForm.BSPXFile.Hdr.GM)) then GM_c := MainForm.BSPXFile.Hdr.GM[CenterID]   // 0..10 with no descriptor (e.g. SSB)
    else GM_c := MainForm.BSPXFile.GetPerturberGM(CenterID);   // not in the file: authoritative fallback table
    S.GM := GetCorrectedGM(GM_c, 0.0, CenterID <= 9);
   end
  else
   begin
    // BSPX body: walk ancestor chains to find common ancestor
    TLen := 0; TAnc[0] := TargetID;
    while TLen < 7 do
     begin
      i := -1;
      for j := 0 to MainForm.BSPXFile.DescCount - 1 do
       if (MainForm.BSPXFile.Desc[j].TargetID = TAnc[TLen]) and
          (MainForm.BSPXFile.Desc[j].NumComp = 3) then
        begin i := j; Break; end;
      if i < 0 then Break;
      TDesc[TLen] := i; Inc(TLen); TAnc[TLen] := MainForm.BSPXFile.Desc[i].CenterID;
     end;
    CLen := 0; CAnc[0] := CenterID;
    while CLen < 7 do
     begin
      i := -1;
      for j := 0 to MainForm.BSPXFile.DescCount - 1 do
       if (MainForm.BSPXFile.Desc[j].TargetID = CAnc[CLen]) and
          (MainForm.BSPXFile.Desc[j].NumComp = 3) then
        begin i := j; Break; end;
      if i < 0 then Break;
      CDesc[CLen] := i; Inc(CLen); CAnc[CLen] := MainForm.BSPXFile.Desc[i].CenterID;
     end;
    ti := -1; ci := -1; i := 0;
    while (i <= TLen) and (ti < 0) do
     begin
      for j := 0 to CLen do
       if TAnc[i] = CAnc[j] then begin ti := i; ci := j; Break; end;
      Inc(i);
     end;
    if ti < 0 then Exit;
    for i := 0 to ti-1 do
     begin S.R := S.R + FSnapshot[TDesc[i]].R; S.V := S.V + FSnapshot[TDesc[i]].V; end;
    for i := 0 to ci-1 do
     begin S.R := S.R - FSnapshot[CDesc[i]].R; S.V := S.V - FSnapshot[CDesc[i]].V; end;
    if CLen>0 then GM_c := MainForm.BSPXFile.Desc[CDesc[0]].GM   // centre descriptor already located above -> O(1), no table search
    else if (CenterID >= 0) and (CenterID <= High(MainForm.BSPXFile.Hdr.GM)) then GM_c := MainForm.BSPXFile.Hdr.GM[CenterID]   // 0..10 with no descriptor (e.g. SSB)
    else GM_c := MainForm.BSPXFile.GetPerturberGM(CenterID);   // not in the file: authoritative fallback table
    if TLen>0 then GM_t := MainForm.BSPXFile.Desc[TDesc[0]].GM   // target descriptor already located above -> O(1), no table search
    else if (TargetID >= 0) and (TargetID <= High(MainForm.BSPXFile.Hdr.GM)) then GM_t := MainForm.BSPXFile.Hdr.GM[TargetID]
    else GM_t := MainForm.BSPXFile.GetPerturberGM(TargetID);   // not in the file: authoritative fallback table
    S.GM := GetCorrectedGM(GM_c, GM_t, CenterID <= 9);
   end;

  // Reference frame: ICRF (index 0) needs no rotation; Ecliptic (index 1) does
  if FrameBox.ItemIndex = 1 then
   begin
    S.R := S.R * MainForm.EpsMatrix;
    S.V := S.V * MainForm.EpsMatrix;
   end;

  Osculate(@S);

  // ===== Phase 1: fill FElements[0] with instantaneous values =====
  FElements[0].e    := S.e;
  FElements[0].q    := S.q;
  FElements[0].Peri := S.Peri;
  FElements[0].Node := S.Node;
  FElements[0].Incl := S.Incl;
  FElements[0].True := S.Anom;
  FElements[0].r    := S.R.Magnitude3D;
  FElements[0].v    := S.V.Magnitude3D;
  FElements[0].h    := (S.R xor S.V).Magnitude3D;
  a := S.q / (1.0 - S.e);
  if S.e < 1.0 then
   begin
    FElements[0].n    := Sqrt(S.GM / (a * a * a));
    FElements[0].Ecc  := ArcTan2(Sqrt(1.0 - S.e * S.e) * Sin(S.Anom), S.e + Cos(S.Anom));
    if FElements[0].Ecc  < 0.0 then FElements[0].Ecc  := FElements[0].Ecc  + 2.0 * Pi;
    FElements[0].Mean := FElements[0].Ecc - S.e * Sin(FElements[0].Ecc);
    if FElements[0].Mean < 0.0 then FElements[0].Mean := FElements[0].Mean + 2.0 * Pi;
    FElements[0].Energy := -S.GM / (2.0 * a);
    FElements[0].Univ   := Sqrt(a) * FElements[0].Ecc;
   end
  else if S.e > 1.0 then
   begin
    FElements[0].n    := Sqrt(-S.GM / (a * a * a));
    FElements[0].Ecc  := 2.0 * ArcTanh(Sqrt((S.e - 1.0) / (S.e + 1.0)) * Tan(S.Anom / 2.0));
    FElements[0].Mean := S.e * Sinh(FElements[0].Ecc) - FElements[0].Ecc;
    FElements[0].Energy := -S.GM / (2.0 * a);
    FElements[0].Univ   := Sqrt(-a) * FElements[0].Ecc;
   end
  else
   begin
    // Parabolic (e=1): a=+Inf, Energy=0
    FElements[0].n    := Sqrt(S.GM / (2.0 * S.q * S.q * S.q));
    FElements[0].Ecc  := Tan(S.Anom / 2.0);                                                     // D = tan(ν/2), dimensionless
    FElements[0].Mean := FElements[0].Ecc + FElements[0].Ecc * FElements[0].Ecc * FElements[0].Ecc / 3.0;  // D + D³/3
    FElements[0].Energy := 0.0;
    FElements[0].Univ   := Sqrt(2.0 * S.q) * FElements[0].Ecc;
   end;
  // Time-to-periapsis (TPP): seconds to (>0, approaching) or since (<0, passed) periapsis. e<1 wraps the mean
  // anomaly to the nearest periapsis; for e>=1 the mean anomaly is monotonic through periapsis (M=0), so it must
  // NOT be wrapped -- Rad180 would fold a valid |M|>pi and give the wrong sign/time.
  if S.e < 1.0 then ttp := -Rad180(FElements[0].Mean) / FElements[0].n
               else ttp := -FElements[0].Mean / FElements[0].n;
  FElements[0].TPP := FSnapshot[0].Epoch + ttp;                       // periapsis epoch (orbital element; averaged below)
  // Display: e>=1 keeps the SIGNED time to/since periapsis (>0 approaching, <0 passed). A closed orbit (e<1) is
  // shown as a pure COUNTDOWN to the next turning point -- TTA while heading out to apoapsis (M<180 deg), TTP while
  // heading back to periapsis (M>=180 deg) -- so it flips at each apsis and never goes negative.
  if S.e < 1.0 then
   begin
    if FElements[0].Mean < Pi then begin ttp := (Pi - FElements[0].Mean) / FElements[0].n;      lbl := 'TTA'; end
                              else begin ttp := (2.0*Pi - FElements[0].Mean) / FElements[0].n;  lbl := 'TTP'; end;
   end
  else lbl := 'TTP';
  ttp := ttp / MainForm.PMSpeed.Items[MainForm.PMSpeed.Tag].Tag;      // ephemeris seconds -> real-time seconds
  Caption := Format('Osculating elements [%s=%.1f s]', [lbl, ttp]);

  // ===== Phase 2: Welford online update of FElements[1] (running average) =====
  Inc(FCount);
  FElements[1].e      := FElements[1].e      + (FElements[0].e      - FElements[1].e)      / FCount;
  FElements[1].q      := FElements[1].q      + (FElements[0].q      - FElements[1].q)      / FCount;
  FElements[1].Peri   := FElements[1].Peri   + (FElements[0].Peri   - FElements[1].Peri)   / FCount;
  FElements[1].Node   := FElements[1].Node   + (FElements[0].Node   - FElements[1].Node)   / FCount;
  FElements[1].Incl   := FElements[1].Incl   + (FElements[0].Incl   - FElements[1].Incl)   / FCount;
  FElements[1].r      := FElements[1].r      + (FElements[0].r      - FElements[1].r)      / FCount;
  FElements[1].v      := FElements[1].v      + (FElements[0].v      - FElements[1].v)      / FCount;
  FElements[1].h      := FElements[1].h      + (FElements[0].h      - FElements[1].h)      / FCount;
  FElements[1].Energy := FElements[1].Energy + (FElements[0].Energy - FElements[1].Energy) / FCount;
  FElements[1].n      := FElements[1].n      + (FElements[0].n      - FElements[1].n)      / FCount;
  // Anomalies (and the periapsis epoch) are NOT averaged: they sweep 0..2pi every orbit, and TPP jumps by a full
  // period at each periapsis passage, so a running mean is meaningless. The averaged column shows the INSTANTANEOUS
  // value instead -- a "mean anomaly" only has meaning at the current instant.
  FElements[1].True   := FElements[0].True;
  FElements[1].Ecc    := FElements[0].Ecc;
  FElements[1].Mean   := FElements[0].Mean;
  FElements[1].Univ   := FElements[0].Univ;
  FElements[1].TPP    := FElements[0].TPP;

  // ===== Phase 3: display from FElements[FIndex] =====
  El := FElements[FIndex];
  // a and Period are not in TElements; compute on-the-fly from the chosen El
  a := El.q / (1.0 - El.e);

  Value_e.Caption := Format('%14.6f', [El.e], fs);
  case Unit_q.Tag of
    0: Value_q.Caption := Format('%14.6f', [El.q], fs);
    1: Value_q.Caption := Format('%14.6f', [El.q * KM2AU], fs);
  end;
  case Unit_Peri.Tag of
    0: Value_Peri.Caption := Format('%14.6f', [El.Peri], fs);
    1: Value_Peri.Caption := Format('%14.6f', [RadToDeg(El.Peri)], fs);
  end;
  case Unit_Node.Tag of
    0: Value_Node.Caption := Format('%14.6f', [El.Node], fs);
    1: Value_Node.Caption := Format('%14.6f', [RadToDeg(El.Node)], fs);
  end;
  case Unit_Incl.Tag of
    0: Value_Incl.Caption := Format('%14.6f', [El.Incl], fs);
    1: Value_Incl.Caption := Format('%14.6f', [RadToDeg(El.Incl)], fs);
  end;
  case Unit_True.Tag of
    0: Value_True.Caption := Format('%14.6f', [El.True], fs);
    1: Value_True.Caption := Format('%14.6f', [RadToDeg(El.True)], fs);
  end;
  case Unit_r.Tag of
    0: Value_r.Caption := Format('%14.6f', [El.r], fs);
    1: Value_r.Caption := Format('%14.6f', [El.r * KM2AU], fs);
  end;
  case Unit_v.Tag of
    0: Value_v.Caption := Format('%14.6f', [El.v], fs);
    1: Value_v.Caption := Format('%14.6f', [El.v * KMPS2AUPDAY], fs);
    2: Value_v.Caption := Format('%14.6f', [El.v * KMPS2AUPTAU], fs);
  end;
  case Unit_h.Tag of
    0: Value_h.Caption := Format('%14.6f', [El.h], fs);
    1: Value_h.Caption := Format('%14.6f', [El.h * KMPS2AUPDAY * KM2AU], fs);
    2: Value_h.Caption := Format('%14.6f', [El.h * KMPS2AUPTAU * KM2AU], fs);
  end;
  case Unit_a.Tag of
    0: Value_a.Caption := Format('%14.6f', [a], fs);
    1: Value_a.Caption := Format('%14.6f', [a * KM2AU], fs);
  end;
  case Unit_Energy.Tag of
    0: Value_Energy.Caption := Format('%14.6f', [El.Energy], fs);
    1: Value_Energy.Caption := Format('%14.6f', [El.Energy * Sqr(KMPS2AUPDAY)], fs);
    2: Value_Energy.Caption := Format('%14.6f', [El.Energy * Sqr(KMPS2AUPTAU)], fs);
  end;
  case Unit_n.Tag of
    0: Value_n.Caption := Format('%14.6f', [El.n], fs);
    1: Value_n.Caption := Format('%14.6f', [El.n * HOUR2SEC], fs);
    2: Value_n.Caption := Format('%14.6f', [El.n * DAY2SEC], fs);
    3: Value_n.Caption := Format('%14.6f', [El.n * DAY2SEC/GAUSS], fs);
    4: Value_n.Caption := Format('%14.6f', [RadToDeg(El.n)], fs);
    5: Value_n.Caption := Format('%14.6f', [RadToDeg(El.n) * HOUR2SEC], fs);
    6: Value_n.Caption := Format('%14.6f', [RadToDeg(El.n) * DAY2SEC], fs);
    7: Value_n.Caption := Format('%14.6f', [RadToDeg(El.n) * DAY2SEC/GAUSS], fs);
  end;
  if El.e < 1.0 then
   begin
    case Unit_Period.Tag of
     0: Value_Period.Caption := Format('%14.6f', [2.0 * Pi / El.n], fs);
     1: Value_Period.Caption := Format('%14.6f', [2.0 * Pi / El.n / HOUR2SEC], fs);
     2: Value_Period.Caption := Format('%14.6f', [2.0 * Pi / El.n / DAY2SEC], fs);
     3: Value_Period.Caption := Format('%14.6f', [2.0 * Pi / El.n / WEEK2SEC], fs);
     4: Value_Period.Caption := Format('%14.6f', [2.0 * Pi / El.n / MONTH2SEC], fs);
     5: Value_Period.Caption := Format('%14.6f', [2.0 * Pi / El.n / TAU2SEC], fs);
     6: Value_Period.Caption := Format('%14.6f', [2.0 * Pi / El.n / YEAR2SEC], fs);
    end;
   end
  else
    Value_Period.Caption := FormatFloat('0.###', Infinity, fs);
  case Unit_Ecc.Tag of
    0: Value_Ecc.Caption := Format('%14.6f', [El.Ecc], fs);
    1: Value_Ecc.Caption := Format('%14.6f', [RadToDeg(El.Ecc)], fs);
  end;
  case Unit_Mean.Tag of
    0: Value_Mean.Caption := Format('%14.6f', [El.Mean], fs);
    1: Value_Mean.Caption := Format('%14.6f', [RadToDeg(El.Mean)], fs);
  end;
  case Unit_Univ.Tag of
    0: Value_Univ.Caption := Format('%14.6f', [El.Univ], fs);
    1: Value_Univ.Caption := Format('%14.6f', [El.Univ * Sqrt(KM2AU)], fs);
  end;
  case Unit_TPP.Tag of
    0: Value_TPP.Caption := FormatFloat('0.###', El.TPP, fs);
    1: Value_TPP.Caption := Format('%14.6f', [STANDARD_EPOCH + El.TPP / DAY2SEC], fs);
    2: Value_TPP.Caption := BSPXTimeStr(El.TPP, 3);
  end;
end;

procedure TOscForm.TimerTick(Sender: TObject);
var
  TargetID, intCount, i, sel: Int64;
begin
  sel      := TargetBox.ItemIndex;
  intCount := Length(IntForm.IntegrationNames);

  // Close if the selected integration body no longer exists
  if sel >= 0 then
   begin
    TargetID := Int64(Pointer(TargetBox.Items.Objects[sel]));
    if (TargetID < 0) and (-TargetID - 1 >= intCount) then
     begin Close; Exit; end;
   end;

  // Sync integration section: add new bodies, drop stale from end, update names
  while Int64(TargetBox.Items.Count) - FBSPXCount < intCount do
   begin
    i := Int64(TargetBox.Items.Count) - FBSPXCount;
    TargetBox.Items.AddObject(IntForm.IntegrationNames[i], TObject(Pointer(-(i+1))));
   end;
  while Int64(TargetBox.Items.Count) - FBSPXCount > intCount do
   TargetBox.Items.Delete(TargetBox.Items.Count-1);
  for i := 0 to intCount-1 do
   if TargetBox.Items[Integer(FBSPXCount+i)] <> IntForm.IntegrationNames[i] then
    TargetBox.Items[Integer(FBSPXCount+i)] := IntForm.IntegrationNames[i];

  // Any Items mutation can reset ItemIndex — restore unconditionally
  if TargetBox.ItemIndex <> sel then TargetBox.ItemIndex := sel;

  MainForm.TakeSnapshot(FSnapshot);
  Refresh;
end;

procedure TOscForm.UnitClick_Dist(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod 2;
  Btn.Caption := CAPS_DIST[Btn.Tag];
  Btn.Hint    := HINTS_DIST[Btn.Tag];
  Refresh;
end;

procedure TOscForm.UnitClick_Epoch(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_EPOCH);
  Btn.Caption := CAPS_EPOCH[Btn.Tag];
  Btn.Hint    := HINTS_EPOCH[Btn.Tag];
  Refresh;
end;

procedure TOscForm.UnitClick_Time(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_TIME);
  Btn.Caption := CAPS_TIME[Btn.Tag];
  Btn.Hint    := HINTS_TIME[Btn.Tag];
  Refresh;
end;

procedure TOscForm.UnitClick_Speed(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_SPEED);
  Btn.Caption := CAPS_SPEED[Btn.Tag];
  Btn.Hint    := HINTS_SPEED[Btn.Tag];
  Refresh;
end;

procedure TOscForm.UnitClick_SqrtDist(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_SQRTDIST);
  Btn.Caption := CAPS_SQRTDIST[Btn.Tag];
  Btn.Hint    := HINTS_SQRTDIST[Btn.Tag];
  Refresh;
end;

procedure TOscForm.UnitClick_Dist2PerTime2(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_DIST2PT2);
  Btn.Caption := CAPS_DIST2PT2[Btn.Tag];
  Btn.Hint    := HINTS_DIST2PT2[Btn.Tag];
  Refresh;
end;

procedure TOscForm.UnitClick_Dist2PerTime(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_DIST2PT);
  Btn.Caption := CAPS_DIST2PT[Btn.Tag];
  Btn.Hint    := HINTS_DIST2PT[Btn.Tag];
  Refresh;
end;

procedure TOscForm.UnitClick_AnglePerTime(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_ANGLEPT);
  Btn.Caption := CAPS_ANGLEPT[Btn.Tag];
  Btn.Hint    := HINTS_ANGLEPT[Btn.Tag];
  Refresh;
end;

procedure TOscForm.UnitClick_Angle(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := TButton(Sender);
  Btn.Tag := (Btn.Tag + 1) mod Length(CAPS_ANGLE);
  Btn.Caption := CAPS_ANGLE[Btn.Tag];
  Btn.Hint    := HINTS_ANGLE[Btn.Tag];
  Refresh;
end;

end.
