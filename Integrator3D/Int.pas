unit Int;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math, System.UITypes, System.SyncObjs, System.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Samples.Spin, Vcl.WinXCtrls,
  Vec4D, CelestialMechanics, Main, Acc;

const
  INT_VERLET2 = 0;
  INT_MCLACHLAN4 = 1;
  //INT_RUNGEKUTTA5 = 2;
  INT_DORMANDPRINCE54 = 2;
  INT_BLANESMOANMCLACHLAN6 = 3;
  INT_DORMANDPRINCE87 = 4;
  INT_GAUSSRADAU15 = 5;

  MIN_FPSLIMIT = 10;
  MAX_FPSLIMIT = 1000;
  DEF_FPSLIMIT = 60;

type
  TIntForm = class(TForm)
    IntGroup: TGroupBox;
    AddBtn: TButton;
    IntBox: TListBox;
    DelBtn: TButton;
    Splitter1: TSplitter;
    SettingsGroup: TGroupBox;
    ModeBox: TRadioGroup;
    LoadBtn: TButton;
    SaveBtn: TButton;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    SpinPanel: TPanel;
    FPSLbl: TLabel;
    ToleranceLbl: TLabel;
    FPSSpin: TSpinButton;
    ToleranceSpin: TSpinButton;
    CBprec0: TCheckBox;
    CBprec2: TCheckBox;
    CBprec3: TCheckBox;
    SaveIntBtn: TButton;
    CBprec4: TCheckBox;
    Pprec1: TPanel;
    CBprec1: TCheckBox;
    RBprec1b: TRadioButton;
    RBprec1a: TRadioButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure ModeBoxClick(Sender: TObject);
    procedure StartIntegrationGroup(idx: Int64);   // (re)start the integration group sharing master entry idx's epoch+centre
    procedure IntBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure IntBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure LoadBtnClick(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
    procedure SaveIntBtnClick(Sender: TObject);
    procedure ToleranceSpinUpClick(Sender: TObject);
    procedure ToleranceSpinDownClick(Sender: TObject);
    procedure FPSSpinDownClick(Sender: TObject);
    procedure FPSSpinUpClick(Sender: TObject);
    procedure SpinPanelResize(Sender: TObject);
    procedure SettingsGroupMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure CBprec1Click(Sender: TObject);
  private
    FIntegrationNames: array of string;
    FIntegrationStates: TState4DArray;
    FIntegrationCenters: array of Int64;
    FIntegrationNonGrav: array of TNonGrav;   // per-object Yarkovsky, parallel to FIntegrationStates
    FActiveIndices: array of Int64;
    FPublicLock: TCriticalSection;
    procedure SetTmpArrays(Count, Mode: Int64); inline;
    procedure RenderLabelBitmaps(Count: Int64);   // rasterise name labels (UI thread / GDI)
    procedure ApplyModeHints;                      // per-integrator hint on each ModeBox radio button
  public
    IntegrationMode, IntegrationModeSelected: Int64;
    IntegrationS: TState4DArray;
    IntegrationA: TVec4DArray;
    IntegrationX: array of TAccForm;
    IntegrationCallbacks: TAccelCallbacks;
    IntegrationNames: array of string;
    IntegrationNonGrav: array of TNonGrav;   // per-active-body Yarkovsky (parallel to IntegrationS)
    IntegrationCoef: TDynDoubleArray;
    IntegrationTime: TDynDoubleArray;
    TmpR, TmpV, TmpA: TVec4DArray;
    // IAS15 (GaussRadau15) persistent per-body state. IntegrationB/E/Br/Er are
    // jagged [0..6][body]; IntegrationCSX/CSV are [body]. Same locking rules as the
    // other public arrays: only touched by the render thread or under PublicLock.
    IntegrationB, IntegrationE, IntegrationBr, IntegrationEr: TVec4DArrays;
    IntegrationCSX, IntegrationCSV: TVec4DArray;
    // Name labels are rasterised here on the UI thread (GDI) and uploaded as GL
    // textures by the render thread — keeping GDI off the render thread entirely.
    IntegrationLabelRGBA: array of TBytes;          // one RGBA bitmap per body
    IntegrationLabelW, IntegrationLabelH: array of Integer;
    NewIntegration: Boolean;
    procedure Reset(FreeAll: Boolean = False);
    procedure IntegrationChange;
    procedure UpdateIntBoxSelection;   // drive IntBox.Selected to SHOW the running set (FActiveIndices), not for user selection
    procedure IntegrationModeChange;
    procedure SetRadauArrays(Count: Int64);   // (re)allocate + zero IAS15 state for Count bodies
    procedure ClearRadauState;                 // zero IAS15 state in place (fresh integration)
    procedure RemoveActiveIntegration(idx: Int64);   // drop one body from all active arrays (collision guard)
    procedure AddIntegration(const Name: string; const S: TState4D; CenterID: Int64); overload;
    procedure AddIntegration(const Name: string; const S: TState4D; CenterID: Int64; const NG: TNonGrav); overload;
    procedure UnregisterAccForm(Form: TAccForm);
    function  StartAccForm(slot: Int64): Boolean;   // create+wire a new AccForm for active integration slot; False if slot invalid or already has one
    function  OpenAccForms: TArray<TAccForm>;                   // snapshot of the currently-open AccForms (taken under PublicLock)
    procedure SetIdleAccFormsCenter(const CenterName: string);  // point every IDLE AccForm's centre combo at CenterName
    procedure RefreshIdleAccForms;                              // re-run Value_Change on every IDLE AccForm (after a speed change)
    procedure RebuildIdleAccFormCenters;                        // rebuild every IDLE AccForm's centre combo (after an FBarycenter change)
    procedure SetAccelCallback(Form: TAccForm; Value: TAccelCallback);
    procedure LimitFPS(Value: Int64);
    property PublicLock: TCriticalSection read FPublicLock;
  end;

var
  IntForm: TIntForm;

implementation

{$R *.dfm}

uses Vec, BSPXFile;

procedure TIntForm.FormCreate(Sender: TObject);
begin
  FPublicLock:=TCriticalSection.Create;
  LimitFPS(DEF_FPSLIMIT);
  Reset;
  SetLength(IntegrationTime, 1);
  SetLength(IntegrationCoef, 1);
  IntegrationCoef[0]:=IntegrationCoef_Leapfrog2[0];   // Verlet2 startup default; the literal lives only in CelestialMechanics
  IntegrationModeSelected:=INT_VERLET2;
  IntegrationMode:=INT_VERLET2;
  // Let the CBprec* checkboxes show hints even while Enabled=False: a disabled window is skipped by
  // WindowFromPoint, so the hover lands on SettingsGroup -- proxy the checkbox's hint onto it there.
  SettingsGroup.ShowHint := True;
  SettingsGroup.OnMouseMove := SettingsGroupMouseMove;
  ApplyModeHints;
end;

procedure TIntForm.UnregisterAccForm(Form: TAccForm);
var
  i: Int64;
  b: Boolean;
begin
  if Form<>nil then
   begin
    b:=False;
    FPublicLock.Acquire;
    for i:=0 to Length(IntegrationX)-1 do
     begin
      if IntegrationX[i]<>Form then b:=b or Assigned(IntegrationCallbacks[i]) else
       begin
        IntegrationCallbacks[i]:=nil;
        IntegrationX[i]:=nil;
       end;
     end;
    if b then AccelCallbacks:=@IntegrationCallbacks else AccelCallbacks:=nil;
    FPublicLock.Release;
   end;
  if Assigned(MainForm) then MainForm.RebuildAccMenu;   // the closed form freed its slot -> re-enable its PMAcc item
end;

function TIntForm.StartAccForm(slot: Int64): Boolean;
// Create a new AccForm for active integration slot and wire it into IntegrationX[slot]; its acceleration stays
// off until the user toggles it. Returns False (creating nothing) if slot is out of range or already has a form.
// The form is built outside the lock (VCL work); only the array wiring is under PublicLock.
var
  F: TAccForm;
  nm: string;
begin
  Result := False;
  F := TAccForm.Create(nil);
  FPublicLock.Acquire;
  try
   if (slot >= 0) and (slot < Length(IntegrationX)) and (IntegrationX[slot] = nil) then
    begin
     IntegrationX[slot] := F;
     nm := IntegrationNames[slot];
     Result := True;
    end;
  finally
   FPublicLock.Release;
  end;
  if Result then
   begin
    F.Value_Target.Caption := nm;
    F.Show;
   end
  else
   F.Free;   // slot invalid / already had a form -> discard
end;

function TIntForm.OpenAccForms: TArray<TAccForm>;
// Snapshot the non-nil AccForms under PublicLock (the render thread can shift IntegrationX on a collision), so
// the caller can touch their VCL on the UI thread without holding the lock.
var
  i: Int64;
begin
  Result := nil;
  FPublicLock.Acquire;
  try
   for i := 0 to High(IntegrationX) do
    if IntegrationX[i] <> nil then begin SetLength(Result, Length(Result)+1); Result[High(Result)] := IntegrationX[i]; end;
  finally
   FPublicLock.Release;
  end;
end;

procedure TIntForm.SetIdleAccFormsCenter(const CenterName: string);
// Orbit centre changed: point every open, IDLE AccForm's centre combo at CenterName. Active forms (toggle on)
// are left alone -- their UI is locked and their Acc is being read by the integrator.
var
  F: TAccForm;
begin
  for F in OpenAccForms do
   if F.ToggleSwitch.State = tssOff then F.SetCenter(CenterName);
end;

procedure TIntForm.RefreshIdleAccForms;
// Animation speed changed: re-run Value_Change on every open, IDLE AccForm (its shown acceleration depends on
// MainForm.TimeAcceleration in the "relative" mode). Active forms are left alone (locked, Acc in use).
var
  F: TAccForm;
begin
  for F in OpenAccForms do
   if F.ToggleSwitch.State = tssOff then F.Value_Change(nil);
end;

procedure TIntForm.RebuildIdleAccFormCenters;
// FBarycenter changed: rebuild the centre combo of every open, IDLE AccForm for the new system, then refresh its
// Acc (the selected centre may have defaulted back to the barycentre). Active forms are left alone (locked, Acc in
// use); their chosen centre is a file-global descriptor index that stays valid whatever the view's FBarycenter is.
var
  F: TAccForm;
begin
  for F in OpenAccForms do
   if F.ToggleSwitch.State = tssOff then begin F.PopulateCenters; F.Value_Change(nil); end;
end;

procedure TIntForm.SetAccelCallback(Form: TAccForm; Value: TAccelCallback);
var
  i: Int64;
  b: Boolean;
begin
  if Form<>nil then
   begin
    b:=Assigned(Value);
    FPublicLock.Acquire;
    for i:=0 to Length(IntegrationX)-1 do
     begin
      if IntegrationX[i]=Form
       then IntegrationCallbacks[i]:=Value
        else b:=b or Assigned(IntegrationCallbacks[i]);
     end;
    if b then AccelCallbacks:=@IntegrationCallbacks else AccelCallbacks:=nil;
    FPublicLock.Release;
   end;
end;

procedure TIntForm.ApplyModeHints;
// TRadioGroup builds one real TRadioButton child per item, and each shows its own hint on hover. Give
// each the matching per-integrator hint (mapped by Caption so it's independent of child order).
const
  MODE_HINTS: array[INT_VERLET2..INT_GAUSSRADAU15] of string = (
    'Fast 2nd-order symplectic (kick-drift-kick leapfrog): cheapest and energy-stable, but low accuracy and fixed-step - good for smooth visualisation, weak at close encounters.',
    'Cheap, reliable 4th-order symplectic. Solid general-purpose choice; like all symplectic methods it degrades at close encounters.',
    'Adaptive 5th-order Dormand-Prince (embedded 4th-order error control). Handles close encounters well; less economical on long smooth arcs.',
    'Also known as Runge-Kutta-Nystrom 11B. The same well-optimised 6th-order symplectic method KSP''s Principia mod uses. Small error constant, excellent for accurate fixed-step long runs; weaker at very close encounters but tolerates looser ones well.',
    'Adaptive 8th-order Dormand-Prince (embedded 7th-order error control). Very accurate over one-to-two decades and robust through close encounters.',
    'Adaptive 15th-order implicit Gauss-Radau (IAS15) method based on the ReBOUND package: most accurate everywhere and best at close encounters. Required for the 1PN, J2/3/4 and nongravitational terms.');
var
  i, idx: Integer;
begin
  for i := 0 to ModeBox.ControlCount-1 do
   if ModeBox.Controls[i] is TRadioButton then
    begin
     idx := ModeBox.Items.IndexOf(TRadioButton(ModeBox.Controls[i]).Caption);
     if (idx >= Low(MODE_HINTS)) and (idx <= High(MODE_HINTS)) then
      begin
       TRadioButton(ModeBox.Controls[i]).Hint := MODE_HINTS[idx];
       TRadioButton(ModeBox.Controls[i]).ShowHint := True;
      end;
    end;
end;

procedure TIntForm.SettingsGroupMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  C: TControl;
begin
  C := SettingsGroup.ControlAtPos(Point(X, Y), True, True);   // AllowDisabled, AllowWinControls
  if (C <> nil) and not C.Enabled and (C.Hint <> '') then
   begin
    if SettingsGroup.Hint <> C.Hint then
     begin
      Application.CancelHint;            // drop the current tip so the new text re-shows
      SettingsGroup.Hint := C.Hint;
     end;
   end
  else
   SettingsGroup.Hint := '';             // not over a disabled, hinted control
end;

procedure TIntForm.FormDestroy(Sender: TObject);
begin
  FPublicLock.Free;
end;

procedure TIntForm.Reset(FreeAll: Boolean = False);
var
  i: Int64;
  F: TAccForm;
begin
  // Reset runs on the UI thread (FormCreate, DelBtnClick, ResetVars) and frees the
  // very arrays the render thread iterates, so it must mutate them under the same
  // lock the render thread holds. (FreeAll's VCL clear and IntegrationChange touch
  // only UI/private state and stay outside the lock.)
  FPublicLock.Acquire;
  try
   NewIntegration:=False;
   AccelCallbacks:=nil;
   for i:=0 to Length(IntegrationX)-1 do if IntegrationX[i]<>nil then
    begin
     IntegrationCallbacks[i]:=nil;
     F:=IntegrationX[i];
     IntegrationX[i]:=nil;
     if F<>nil then F.Free;
    end;
   SetLength(IntegrationA, 0);
   SetLength(IntegrationS, 0);
   SetLength(IntegrationX, 0);
   SetLength(IntegrationCallbacks, 0);
   SetLength(IntegrationNames, 0);
   SetLength(IntegrationNonGrav, 0);
   SetLength(FActiveIndices, 0);
   SetLength(TmpR, 0);
   SetLength(TmpV, 0);
   SetLength(TmpA, 0);
   SetLength(IntegrationB, 0);  SetLength(IntegrationE, 0);
   SetLength(IntegrationBr, 0); SetLength(IntegrationEr, 0);
   SetLength(IntegrationCSX, 0); SetLength(IntegrationCSV, 0);
   SetLength(IntegrationLabelRGBA, 0);
   SetLength(IntegrationLabelW, 0); SetLength(IntegrationLabelH, 0);
   if FreeAll then
    begin
     SetLength(FIntegrationNames, 0);
     SetLength(FIntegrationStates, 0);
     SetLength(FIntegrationCenters, 0);
     SetLength(FIntegrationNonGrav, 0);
     SetLength(IntegrationTime, 0);
     SetLength(IntegrationCoef, 0);
    end;
  finally
   FPublicLock.Release;
  end;
  if FreeAll then IntBox.Clear;
  IntegrationChange;
  if Assigned(MainForm) then MainForm.RebuildAccMenu;   // active set cleared -> PMAcc empties (and greys out)
end;

procedure TIntForm.SetTmpArrays(Count, Mode: Int64);
var
  i: Int64;
begin
  if (Mode=INT_DORMANDPRINCE54) or (Mode=INT_DORMANDPRINCE87) then i:=Count else i:=0;
  SetLength(TmpR, i);
  SetLength(TmpV, i);
  SetLength(TmpA, i);
end;

procedure TIntForm.RenderLabelBitmaps(Count: Int64);
// Rasterise each integration body's name into an RGBA buffer using VCL GDI. Runs on
// the UI thread (from IntBoxClick, under PublicLock); the render thread later uploads
// these as GL textures without ever touching GDI. Reads IntegrationNames, so call it
// after that array has been populated. Empty name -> empty buffer (W=H=0 -> skipped).
var
  Bmp: TBitmap;
  i, x, y, a: Int64;
  Name: string;
  W, H: Integer;
  SL: PByteArray;
begin
  SetLength(IntegrationLabelRGBA, Count);
  SetLength(IntegrationLabelW,    Count);
  SetLength(IntegrationLabelH,    Count);
  if Count = 0 then Exit;
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.Width  := 1;
    Bmp.Height := 1;
    for i := 0 to Count-1 do
     begin
      if i < Length(IntegrationNames) then Name := IntegrationNames[i]
      else Name := 'Integration ' + IntToStr(i+1);
      if Name = '' then
       begin
        SetLength(IntegrationLabelRGBA[i], 0);
        IntegrationLabelW[i] := 0;
        IntegrationLabelH[i] := 0;
        Continue;
       end;
      W := Bmp.Canvas.TextWidth(Name) + 4;
      H := Bmp.Canvas.TextHeight(Name) + 2;
      Bmp.Width  := W;
      Bmp.Height := H;
      Bmp.Canvas.Font.Color  := clWhite;
      Bmp.Canvas.Brush.Color := clBlack;
      Bmp.Canvas.FillRect(Rect(0, 0, W, H));
      Bmp.Canvas.TextOut(2, 1, Name);
      SetLength(IntegrationLabelRGBA[i], W * H * 4);
      for y := 0 to H-1 do
       begin
        SL := Bmp.ScanLine[y];
        for x := 0 to W-1 do
         begin
          a := SL[x*3+2];                                   // text drawn white-on-black: any channel = coverage
          IntegrationLabelRGBA[i][(y*W+x)*4+0] := 255;
          IntegrationLabelRGBA[i][(y*W+x)*4+1] := 255;
          IntegrationLabelRGBA[i][(y*W+x)*4+2] := 255;
          IntegrationLabelRGBA[i][(y*W+x)*4+3] := a;        // alpha = glyph coverage
         end;
       end;
      IntegrationLabelW[i] := W;
      IntegrationLabelH[i] := H;
     end;
  finally
    Bmp.Free;
  end;
end;

procedure TIntForm.SpinPanelResize(Sender: TObject);
begin
  FPSSpin.Left:=SpinPanel.ClientWidth-FPSSpin.Width-4;
  FPSLbl.Left:=FPSSpin.Left-FPSLbl.Width-4;
  ToleranceSpin.Left:=FPSLbl.Left-ToleranceSpin.Width-20;
  ToleranceLbl.Left:=ToleranceSpin.Left-ToleranceLbl.Width-4;
end;

procedure TIntForm.ToleranceSpinDownClick(Sender: TObject);
begin
  ToleranceSpin.Tag:=ToleranceSpin.Tag+1; if ToleranceSpin.Tag>-5 then ToleranceSpin.Tag:=-5;
  ERROR_TOLERANCE_DP:=Power(10.0, ToleranceSpin.Tag);
  ToleranceLbl.Caption:=Format('Error tolerance: 10^%d', [ToleranceSpin.Tag]);
end;

procedure TIntForm.ToleranceSpinUpClick(Sender: TObject);
begin
  ToleranceSpin.Tag:=ToleranceSpin.Tag-1; if ToleranceSpin.Tag<-20 then ToleranceSpin.Tag:=-20;
  ERROR_TOLERANCE_DP:=Power(10.0, ToleranceSpin.Tag);
  ToleranceLbl.Caption:=Format('Error tolerance: 10^%d', [ToleranceSpin.Tag]);
end;

procedure TIntForm.LimitFPS(Value: Int64);
begin
  if (Value<>FPSSpin.Tag) and (Value>=MIN_FPSLIMIT) and (Value<=MAX_FPSLIMIT) then
   begin
    FPSSpin.Tag:=Value;
    MainForm.SetFPSLimit(Value);
   end;
  FPSLbl.Caption:=Format('FPS limit: %4d', [FPSSpin.Tag]);
end;

procedure TIntForm.FPSSpinDownClick(Sender: TObject);
begin
  LimitFPS(FPSSpin.Tag-10);
end;

procedure TIntForm.FPSSpinUpClick(Sender: TObject);
begin
  LimitFPS(FPSSpin.Tag+10);
end;

procedure TIntForm.SetRadauArrays(Count: Int64);
// (Re)allocate the IAS15 per-body coefficient/compensation arrays and zero them.
// Call under PublicLock when the active body count changes.
var
  k: Int64;
begin
  SetLength(IntegrationB,  7);
  SetLength(IntegrationE,  7);
  SetLength(IntegrationBr, 7);
  SetLength(IntegrationEr, 7);
  for k := 0 to 6 do
   begin
    SetLength(IntegrationB[k],  Count);
    SetLength(IntegrationE[k],  Count);
    SetLength(IntegrationBr[k], Count);
    SetLength(IntegrationEr[k], Count);
   end;
  SetLength(IntegrationCSX, Count);
  SetLength(IntegrationCSV, Count);
  ClearRadauState;
end;

procedure TIntForm.CBprec1Click(Sender: TObject);
begin
  Pprec1.Tag:=Ord(CBprec1.Checked)*((Ord(RBprec1a.Checked) shl 2) + (Ord(RBprec1b.Checked) shl 3));
end;

procedure TIntForm.ClearRadauState;
// Zero all IAS15 state in place (a fresh integration: discard the predictor history
// and the compensated-summation accumulators). Safe to call when arrays are empty.
var
  k: Int64;
begin
  for k := 0 to High(IntegrationB) do
   begin
    if Length(IntegrationB[k])  > 0 then FillChar(IntegrationB[k][0],  Length(IntegrationB[k]) *SizeOf(TVec4D), 0);
    if Length(IntegrationE[k])  > 0 then FillChar(IntegrationE[k][0],  Length(IntegrationE[k]) *SizeOf(TVec4D), 0);
    if Length(IntegrationBr[k]) > 0 then FillChar(IntegrationBr[k][0], Length(IntegrationBr[k])*SizeOf(TVec4D), 0);
    if Length(IntegrationEr[k]) > 0 then FillChar(IntegrationEr[k][0], Length(IntegrationEr[k])*SizeOf(TVec4D), 0);
   end;
  if Length(IntegrationCSX) > 0 then FillChar(IntegrationCSX[0], Length(IntegrationCSX)*SizeOf(TVec4D), 0);
  if Length(IntegrationCSV) > 0 then FillChar(IntegrationCSV[0], Length(IntegrationCSV)*SizeOf(TVec4D), 0);
end;

procedure TIntForm.RemoveActiveIntegration(idx: Int64);
// Delete body idx from every parallel active array (the 1-D per-body arrays and the jagged [0..6][body]
// IAS15 arrays), shifting the tail down. Caller must hold FPublicLock. Used by the collision guard to drop
// an integrand whose IC starts inside a perturber before it can drive the integrator into a singularity.
var
  i, k, n: Int64;
  F: TAccForm;
begin
  n := Length(IntegrationS);
  if (idx < 0) or (idx >= n) then Exit;
  IntegrationCallbacks[idx]:=nil;
  F:=IntegrationX[idx];
  IntegrationX[idx]:=nil;
  // A TAccForm is a VCL form whose window is owned by the main thread. RemoveActiveIntegration runs on the
  // RENDER thread (the collision guard, via AdvanceScene/FreezeIntegrand), where TForm.Free throws inside the
  // VCL and, with no try/except around AdvanceScene, unwinds out of Execute and kills the render thread -- the
  // "freeze" (and the trail never clears because nothing renders after). Defer the destroy to the main thread.
  // Queue, NOT Synchronize: we hold FPublicLock and the main thread may be blocked on it, so a blocking
  // Synchronize would deadlock; Queue is non-blocking. F is already detached from every array, so it's safe.
  if F<>nil then TThread.Queue(nil, procedure begin F.Free; end);
  for i := idx to n-2 do
   begin
    IntegrationS[i]       := IntegrationS[i+1];
    IntegrationA[i]       := IntegrationA[i+1];
    IntegrationX[i]       := IntegrationX[i+1];
    IntegrationCallbacks[i]:=IntegrationCallbacks[i+1];
    IntegrationNames[i]   := IntegrationNames[i+1];
    IntegrationNonGrav[i] := IntegrationNonGrav[i+1];
   end;
  SetLength(IntegrationS,       n-1);
  SetLength(IntegrationA,       n-1);
  SetLength(IntegrationX,       n-1);
  SetLength(IntegrationCallbacks, n-1);
  SetLength(IntegrationNames,   n-1);
  SetLength(IntegrationNonGrav, n-1);
  if Length(FActiveIndices) = n then begin for i := idx to n-2 do FActiveIndices[i] := FActiveIndices[i+1]; SetLength(FActiveIndices, n-1); end;   // keep the active->master map parallel (StartIntegrationGroup's AccForm-rewire matching relies on it)
  if Length(IntegrationCSX) = n then begin for i := idx to n-2 do IntegrationCSX[i] := IntegrationCSX[i+1]; SetLength(IntegrationCSX, n-1); end;
  if Length(IntegrationCSV) = n then begin for i := idx to n-2 do IntegrationCSV[i] := IntegrationCSV[i+1]; SetLength(IntegrationCSV, n-1); end;
  for k := 0 to High(IntegrationB) do
   if Length(IntegrationB[k]) = n then
    begin
     for i := idx to n-2 do
      begin
       IntegrationB[k][i]  := IntegrationB[k][i+1];
       IntegrationE[k][i]  := IntegrationE[k][i+1];
       IntegrationBr[k][i] := IntegrationBr[k][i+1];
       IntegrationEr[k][i] := IntegrationEr[k][i+1];
      end;
     SetLength(IntegrationB[k],  n-1);
     SetLength(IntegrationE[k],  n-1);
     SetLength(IntegrationBr[k], n-1);
     SetLength(IntegrationEr[k], n-1);
    end;
  // A collision just dropped this body from the running set: refresh the IntBox running-set display and the Acc
  // menu. Deferred to the main thread (we're on the render thread under FPublicLock; both re-take the lock + VCL).
  TThread.Queue(nil, procedure begin UpdateIntBoxSelection; if Assigned(MainForm) then MainForm.RebuildAccMenu; end);
end;

type
  // Stable ON-DISK layout for TNonGrav: the original append-order record (A1,A2,A3,r0,m,Active,InvBC,Alpha,n,k,DT).
  // .icf save/load map to/from this, so the in-memory TNonGrav field order is decoupled from the file format. Used
  // to read legacy v1..v6 files (raw dumps of this exact layout); v7 uses the explicit block I/O below.
  TNonGravDisk = record
    A1, A2, A3, r0, m: Double;
    Active: Boolean;
    InvBC, Alpha, n, k, DT: Double;
  end;
const
  DISK_V4_SIZE    = SizeOf(TNonGravDisk) - 4*SizeOf(Double);   // legacy v4 = through InvBC (byte-prefix)
  DISK_PREV4_SIZE = SizeOf(TNonGravDisk) - 5*SizeOf(Double);   // legacy v2/v3 = through Active (byte-prefix)

// v7 nongrav write: the ten Doubles (A1..InvBC, i.e. Vals) as one block, then Active as a byte. No record padding,
// no dependence on the in-memory field order.
procedure WriteNonGrav(Stream: TStream; const NG: TNonGrav);
begin
  Stream.WriteBuffer(NG.Vals[0], SizeOf(NG.Vals));
  Stream.WriteBuffer(NG.Active,  SizeOf(NG.Active));
end;

// Read one nongrav record. v7 = explicit block (km-native, new order). v1..v6 = legacy raw TNonGravDisk (byte-prefix
// per version) mapped into NG by name; v1..v5 additionally converted from SBDB au/day to the integrator's km/s.
procedure ReadNonGrav(Stream: TStream; Ver: Int32; var NG: TNonGrav);
var
  D: TNonGravDisk;
begin
  FillChar(NG, SizeOf(NG), 0);
  NG.r0 := 1.0; NG.m := 2.0; NG.Alpha := 1.0;      // asteroid-form defaults (r0 gets x AU_KM below for legacy files)
  if Ver >= 7 then
   begin
    Stream.ReadBuffer(NG.Vals[0], SizeOf(NG.Vals));
    Stream.ReadBuffer(NG.Active,  SizeOf(NG.Active));
    Exit;                                          // v7 is already km-native in the new order
   end;
  FillChar(D, SizeOf(D), 0);
  D.r0 := 1.0; D.m := 2.0; D.Alpha := 1.0;
  if      Ver >= 5 then Stream.ReadBuffer(D, SizeOf(D))          // v5/v6: full record
  else if Ver =  4 then Stream.ReadBuffer(D, DISK_V4_SIZE)       // v4: through InvBC
  else if Ver >= 2 then Stream.ReadBuffer(D, DISK_PREV4_SIZE);   // v2/v3: through Active  (v1: nothing stored)
  NG.A1:=D.A1; NG.A2:=D.A2; NG.A3:=D.A3; NG.Alpha:=D.Alpha; NG.r0:=D.r0;
  NG.m:=D.m; NG.n:=D.n; NG.k:=D.k; NG.DT:=D.DT; NG.InvBC:=D.InvBC; NG.Active:=D.Active;
  if Ver <= 5 then
   begin   // v1..v5 stored au/day -> convert to km/s
    NG.A1:=NG.A1*AUPD2_TO_KMPS2; NG.A2:=NG.A2*AUPD2_TO_KMPS2; NG.A3:=NG.A3*AUPD2_TO_KMPS2;
    NG.r0:=NG.r0*AU_KM; NG.DT:=NG.DT*DAY2SEC;
   end;
end;

procedure TIntForm.LoadBtnClick(Sender: TObject);
const
  MAGIC_STR:   UInt32 = $494E5453;   // 'INTS'
  VERSION_STR: Int32  = 7;   // v7 stores TNonGrav via explicit block I/O (Vals[0..10] + Active), field-order-independent.
                             // v1..v6 were raw dumps of the append-order layout (TNonGravDisk); ReadNonGrav maps them.
var
  Stream: TFileStream;
  i, n: Int64;
  Magic: UInt32;
  Ver: Int32;
  NameLen: Int32;
  NameBytes: TBytes;
  TmpStates: TState4DArray;
  TmpCenters: array of Int64;
  TmpNames: array of string;
  TmpNonGrav: array of TNonGrav;
begin
  if not OpenDialog.Execute then Exit;
  Stream:=TFileStream.Create(OpenDialog.FileName, fmOpenRead or fmShareDenyWrite);
  try
   if Stream.Read(Magic, SizeOf(Magic)) <> SizeOf(Magic) then
    raise Exception.Create('Unexpected end of file.');
   if Magic <> MAGIC_STR then
    raise Exception.Create('Not a valid integration file.');
   if Stream.Read(Ver, SizeOf(Ver)) <> SizeOf(Ver) then
    raise Exception.Create('Unexpected end of file.');
   if (Ver < 1) or (Ver > VERSION_STR) then
    raise Exception.Create('Unsupported file version: ' + IntToStr(Ver));
   if Stream.Read(n, SizeOf(n)) <> SizeOf(n) then
    raise Exception.Create('Unexpected end of file.');
   if (n < 0) or (n > 1000000) then
    raise Exception.Create('Invalid entry count.');
   SetLength(TmpStates,   n);
   SetLength(TmpCenters,  n);
   SetLength(TmpNames,    n);
   SetLength(TmpNonGrav,  n);
   for i:=0 to n-1 do
    begin
     if Stream.Read(TmpStates[i], SizeOf(TState4D)) <> SizeOf(TState4D) then
      raise Exception.Create('Unexpected end of file at entry ' + IntToStr(i) + '.');
     if Ver <= 2 then   // v1/v2 stored a per-entry center here; read to consume the bytes, then discard
      if Stream.Read(TmpCenters[i], SizeOf(Int64)) <> SizeOf(Int64) then
       raise Exception.Create('Unexpected end of file at entry ' + IntToStr(i) + '.');
     if Stream.Read(NameLen, SizeOf(NameLen)) <> SizeOf(NameLen) then
      raise Exception.Create('Unexpected end of file at entry ' + IntToStr(i) + '.');
     if (NameLen < 0) or (NameLen > 65535) then
      raise Exception.Create('Invalid name length at entry ' + IntToStr(i) + '.');
     SetLength(NameBytes, NameLen);
     if (NameLen > 0) and (Stream.Read(NameBytes[0], NameLen) <> NameLen) then
      raise Exception.Create('Unexpected end of file at entry ' + IntToStr(i) + '.');
     TmpNames[i]:=TEncoding.UTF8.GetString(NameBytes);
     ReadNonGrav(Stream, Ver, TmpNonGrav[i]);   // v7 explicit block; v1..v6 legacy layout mapped + au/day->km/s
    end;
   for i:=0 to n-1 do
    // Centre = the current view (rule 1: FBarycenter when added to IntBox), NOT the file's stale value.
    AddIntegration(TmpNames[i], TmpStates[i], MainForm.Barycenter, TmpNonGrav[i]);
  except on E: Exception do
   MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
  Stream.Free;
end;

procedure TIntForm.SaveBtnClick(Sender: TObject);
const
  MAGIC_STR:   UInt32 = $494E5453;   // 'INTS'
  VERSION_STR: Int32  = 7;   // v7: TNonGrav written via explicit block I/O (WriteNonGrav) -- Vals[0..10] block + Active byte
var
  Stream: TMemoryStream;
  i, n: Int64;
  NameBytes: TBytes;
  NameLen: Int32;
begin
  if Length(FIntegrationStates) < 1 then Exit;
  if not SaveDialog.Execute then Exit;
  Stream:=TMemoryStream.Create;
  try
   n:=Length(FIntegrationStates);
   Stream.WriteBuffer(MAGIC_STR,   SizeOf(MAGIC_STR));
   Stream.WriteBuffer(VERSION_STR, SizeOf(VERSION_STR));
   Stream.WriteBuffer(n,       SizeOf(n));
   for i:=0 to n-1 do
    begin
     Stream.WriteBuffer(FIntegrationStates[i],  SizeOf(TState4D));   // SSB-relative; no center stored (v3)
     NameBytes:=TEncoding.UTF8.GetBytes(FIntegrationNames[i]);
     NameLen:=Length(NameBytes);
     Stream.WriteBuffer(NameLen, SizeOf(NameLen));
     if NameLen > 0 then Stream.WriteBuffer(NameBytes[0], NameLen);
     WriteNonGrav(Stream, FIntegrationNonGrav[i]);   // per-object nongrav, explicit block I/O (v7)
    end;
   Stream.SaveToFile(SaveDialog.FileName);
  except on E: Exception do
   MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
  Stream.Free;
end;

procedure TIntForm.SaveIntBtnClick(Sender: TObject);
// Save the CURRENT (live) state of the running integrations to a .icf, in the same v3 format as SaveBtnClick.
const
  MAGIC_STR:   UInt32 = $494E5453;   // 'INTS'
  VERSION_STR: Int32  = 7;   // v7: TNonGrav written via explicit block I/O (WriteNonGrav) -- Vals[0..10] block + Active byte
var
  Stream: TMemoryStream;
  i, n: Int64;
  NameBytes: TBytes;
  NameLen: Int32;
  snapStates: TState4DArray;
  snapNames: array of string;
  snapNonGrav: array of TNonGrav;
  curEpoch: Double;
  haveEpoch: Boolean;
begin
  // 1. Snapshot the live integrand state at the instant of the click, under PublicLock. The render thread holds
  // PublicLock for the whole frame (see the render loop), so this copy is coherent -- never a half-advanced step.
  // The states are SSB-relative, exactly like the initial-condition Save. IntegrationS[i].Epoch is NOT advanced by
  // the integrator, so stamp the current integration time (IntegrationTime[0]) into each saved state -- otherwise
  // the file would carry current R/V at the stale initial epoch and would not reload to the right instant.
  FPublicLock.Acquire;
  try
   n := Length(IntegrationS);
   haveEpoch := Length(IntegrationTime) >= 1;
   if haveEpoch then curEpoch := IntegrationTime[0] else curEpoch := 0.0;
   SetLength(snapStates,  n);
   SetLength(snapNames,   n);
   SetLength(snapNonGrav, n);
   for i := 0 to n-1 do
    begin
     snapStates[i] := IntegrationS[i];
     if haveEpoch then snapStates[i].Epoch := curEpoch;   // all active bodies share the current integration time
     snapNames[i]   := IntegrationNames[i];
     snapNonGrav[i] := IntegrationNonGrav[i];
    end;
  finally
   FPublicLock.Release;
  end;
  if n < 1 then Exit;                 // nothing running -> nothing to save
  // 2. Ask for the file OUTSIDE the lock (the modal must never block the render thread).
  if not SaveDialog.Execute then Exit;
  // 3. Write the snapshot in the same .icf (v3) layout as SaveBtnClick.
  Stream:=TMemoryStream.Create;
  try
   Stream.WriteBuffer(MAGIC_STR,   SizeOf(MAGIC_STR));
   Stream.WriteBuffer(VERSION_STR, SizeOf(VERSION_STR));
   Stream.WriteBuffer(n,           SizeOf(n));
   for i:=0 to n-1 do
    begin
     Stream.WriteBuffer(snapStates[i], SizeOf(TState4D));   // SSB-relative current state, current epoch stamped
     NameBytes:=TEncoding.UTF8.GetBytes(snapNames[i]);
     NameLen:=Length(NameBytes);
     Stream.WriteBuffer(NameLen, SizeOf(NameLen));
     if NameLen > 0 then Stream.WriteBuffer(NameBytes[0], NameLen);
     WriteNonGrav(Stream, snapNonGrav[i]);   // per-object nongrav, explicit block I/O (v7)
    end;
   Stream.SaveToFile(SaveDialog.FileName);
  except on E: Exception do
   MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
  Stream.Free;
end;

procedure TIntForm.AddBtnClick(Sender: TObject);
begin
  if not VecForm.Visible then VecForm.ShowBlank;
end;

procedure TIntForm.DelBtnClick(Sender: TObject);
var
  idx, n, j, k, m: Int64;
  IsActive: Boolean;
begin
  idx:=IntBox.ItemIndex;
  if (idx < 0) or (idx >= Length(FIntegrationStates)) then Exit;
  n:=Length(FIntegrationStates);
  for j:=idx to n-2 do
   begin
    FIntegrationStates[j]  :=FIntegrationStates[j+1];
    FIntegrationNames[j]   :=FIntegrationNames[j+1];
    FIntegrationCenters[j] :=FIntegrationCenters[j+1];
    FIntegrationNonGrav[j] :=FIntegrationNonGrav[j+1];
   end;
  SetLength(FIntegrationStates,  n-1);
  SetLength(FIntegrationNames,   n-1);
  SetLength(FIntegrationCenters, n-1);
  SetLength(FIntegrationNonGrav, n-1);
  IsActive := False;
  m := 0;
  for k := 0 to Length(FActiveIndices)-1 do
   if FActiveIndices[k] = idx then
    IsActive := True
   else
    begin
     FActiveIndices[m] := FActiveIndices[k];
     if FActiveIndices[m] > idx then Dec(FActiveIndices[m]);
     Inc(m);
    end;
  SetLength(FActiveIndices, m);
  if IsActive then
   begin
    Reset;                              // deleting an active body clears the integration...
    MainForm.RebuildCamCenterMenu(True);  // ...so its target falls back to the root; BSPX targets stay
   end
  else IntegrationChange;
end;

procedure TIntForm.IntBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// Mouse restart: any left-click on a row (re)starts its group. On MouseUp so the native click has settled;
// ItemAtPos is position-based so it names the clicked row regardless. Left-click off the rows just repaints.
begin
  if Button = mbLeft then StartIntegrationGroup(IntBox.ItemAtPos(Point(X, Y), True));
end;

procedure TIntForm.IntBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
// Keyboard: Enter (re)starts the focused row's group -- same outcome as a click. Arrow keys are left to the
// listbox (in multiple-select mode they move only the caret, so walking the list does NOT restart anything or
// disturb the running-set highlight). Space is swallowed so it can't toggle the selection out of sync.
begin
  case Key of
   VK_RETURN: begin StartIntegrationGroup(IntBox.ItemIndex); Key := 0; end;   // swallow so Enter can't also fire a default button
   VK_SPACE:  Key := 0;
  end;
end;

procedure TIntForm.StartIntegrationGroup(idx: Int64);
// (Re)start the integration group the user picked: every master entry sharing idx's epoch + centre. Shared by
// the mouse (IntBoxMouseUp) and keyboard (IntBoxKeyDown, Enter) paths. Repaints the running-set selection at the
// end. New AccForms are NOT started here (handled elsewhere) -- surviving forms are rewired, orphans are freed.
var
  i, j, n: Int64;
  SelEpoch: Double;
  SelCenter: Int64;
  oldX: array of TAccForm;      // the previously-active AccForms...
  oldActive: array of Int64;    // ...and the master (FIntegration*) index each belongs to -- parallel to oldX
  reused: array of Boolean;     // which oldX entries were carried over to the new active set
  found: TAccForm;
begin
  if (idx < 0) or (idx >= Length(FIntegrationStates)) then begin UpdateIntBoxSelection; Exit; end;   // missed a row: just re-show the running set
  // Snapshot the currently-active AccForms and their master indices BEFORE the arrays are rebuilt. Restart
  // policy: an AccForm is KEPT (rewired to its new slot) if its integration is still in the new active set,
  // and FREED otherwise; either way every running acceleration stops (the rebuilt callbacks are all nil, and
  // reused forms are turned off). New AccForms are NOT started here (handled elsewhere). Integrations are
  // matched by master index, which is stable across a restart (a delete already frees the AccForms, so oldX
  // is empty then).
  SetLength(oldX, Length(IntegrationX));
  for j := 0 to High(IntegrationX) do oldX[j] := IntegrationX[j];
  SetLength(oldActive, Length(FActiveIndices));
  for j := 0 to High(FActiveIndices) do oldActive[j] := FActiveIndices[j];
  SetLength(reused, Length(oldX));
  SelEpoch  := FIntegrationStates[idx].Epoch;
  SelCenter := FIntegrationCenters[idx];
  n := 0;
  for i := 0 to Length(FIntegrationStates)-1 do
   if (FIntegrationStates[i].Epoch = SelEpoch) and (FIntegrationCenters[i] = SelCenter) then
    Inc(n);
  SetLength(FActiveIndices, n);
  n := 0;
  for i := 0 to Length(FIntegrationStates)-1 do
   if (FIntegrationStates[i].Epoch = SelEpoch) and (FIntegrationCenters[i] = SelCenter) then
    begin
     FActiveIndices[n] := i;
     Inc(n);
    end;
  FPublicLock.Acquire;
  try
   SetLength(IntegrationS,       n);
   SetLength(IntegrationA,       n);
   SetLength(IntegrationNames,   n);
   SetLength(IntegrationCallbacks, n);
   SetLength(IntegrationX,       n);
   SetLength(IntegrationNonGrav, n);
   for i := 0 to n-1 do
    begin
     IntegrationS[i]         := FIntegrationStates[FActiveIndices[i]];
     IntegrationNames[i]     := FIntegrationNames[FActiveIndices[i]];
     IntegrationNonGrav[i]   := FIntegrationNonGrav[FActiveIndices[i]];
     IntegrationCallbacks[i] := nil;   // accelerations are stopped across a restart (re-enable via the toggle)
     // Carry over (rewire) the AccForm whose integration is still active, matched by master index; else no
     // AccForm for this slot -- new ones are created elsewhere, not here.
     found := nil;
     for j := 0 to High(oldX) do
      if (oldX[j] <> nil) and (not reused[j]) and (oldActive[j] = FActiveIndices[i]) then
       begin found := oldX[j]; reused[j] := True; Break; end;
     if found <> nil then
      begin
       IntegrationX[i] := found;                                 // rewire the surviving form to its new active slot
       IntegrationX[i].Value_Target.Caption := IntegrationNames[i];
      end
     else IntegrationX[i] := nil;
    end;
   AccelCallbacks := nil;   // no acceleration callbacks active immediately after a restart
   SetTmpArrays(n, ModeBox.ItemIndex);
   SetRadauArrays(n);
   RenderLabelBitmaps(n);   // rasterise labels now (UI thread) so the render thread only uploads
   NewIntegration := True;
  finally
   FPublicLock.Release;
  end;
  // VCL form cleanup outside the lock: reused forms show their stopped state; orphaned ones are destroyed.
  for j := 0 to High(oldX) do
   if oldX[j] <> nil then
    if reused[j] then oldX[j].TurnOff
    else oldX[j].Free;
  MainForm.RebuildCamCenterMenu(True);   // surface the new integration bodies; keep the camera target if its slot is still valid
  UpdateIntBoxSelection;   // paint the running set over the native single-item click selection (OnClick = after native selection)
  MainForm.RebuildAccMenu; // repopulate the Acceleration menu for the new active set (rewired forms show as greyed)
end;

procedure TIntForm.IntegrationChange;
var
  i: Int64;
begin
  IntBox.Clear;
  for i:=0 to Length(FIntegrationStates)-1 do
   IntBox.Items.Add(BSPXTimeStr(FIntegrationStates[i].Epoch, 3) + '  ' + FIntegrationNames[i]);
  UpdateIntBoxSelection;
end;

procedure TIntForm.UpdateIntBoxSelection;
// Drive IntBox's Selected state to SHOW the running set: item i is selected iff its master index is in
// FActiveIndices (IntBox is 1:1 with FIntegrationStates). MultiSelect exists only for this status display, not
// for user selection. Setting Selected[] programmatically does not raise OnClick, so there's no re-entrancy.
// Must run on the UI thread (touches IntBox). FActiveIndices is snapshotted under FPublicLock because the render
// thread can SetLength it mid-collision (RemoveActiveIntegration); we then paint the selection from the copy.
var
  i: Integer;
  k: Int64;
  run: Boolean;
  active: array of Int64;
begin
  FPublicLock.Acquire;
  try
   SetLength(active, Length(FActiveIndices));
   for k := 0 to High(FActiveIndices) do active[k] := FActiveIndices[k];
  finally
   FPublicLock.Release;
  end;
  for i := 0 to IntBox.Count-1 do
   begin
    run := False;
    for k := 0 to High(active) do
     if active[k] = i then begin run := True; Break; end;
    if IntBox.Selected[i] <> run then IntBox.Selected[i] := run;
   end;
  SaveIntBtn.Enabled := Length(active) > 0;   // "Save current states" is usable only while an integration is active
end;

procedure TIntForm.IntegrationModeChange;
// this procedure can only be called from inside the rendering thread.
// The node-time coefficients are COPIED from the IntegrationCoef_* tables in CelestialMechanics (the single
// source of truth) -- no literals live here. FSAL methods store them "backwards" so [0] is the c=1 (last/FSAL)
// node; GaussRadau15 is the exception, [0]=0 (the c=0 node), which makes AdvanceScene's FT:=IntegrationTime[0]
// a no-op and leaves FT at the step start.
var
  i: Int64;
  procedure CopyCoef(const src: array of Double);   // src -> IntegrationCoef (already sized to ModeBox.Tag = Length(src))
  var k: Integer;
  begin
    for k := 0 to High(src) do IntegrationCoef[k] := src[k];
  end;
begin
  SetLength(IntegrationTime, ModeBox.Tag);
  SetLength(IntegrationCoef, ModeBox.Tag);
  SetTmpArrays(Length(IntegrationS), IntegrationModeSelected);
  SetRadauArrays(Length(IntegrationS));
  case IntegrationModeSelected of
   INT_VERLET2:              CopyCoef(IntegrationCoef_Leapfrog2);
   INT_MCLACHLAN4:           CopyCoef(IntegrationCoef_McLachlan4);
   INT_DORMANDPRINCE54:      CopyCoef(IntegrationCoef_DormandPrince54);
   INT_DORMANDPRINCE87:      CopyCoef(IntegrationCoef_DormandPrince87);
   INT_BLANESMOANMCLACHLAN6: CopyCoef(IntegrationCoef_BlanesMoanMcLachlan6);   // P[idx]=c(11-idx): [0]=c11=1.0 .. [10]=c1
   INT_GAUSSRADAU15:         CopyCoef(IntegrationCoef_GaussRadau15);            // [0]=0 (c=0 node) => FT:=IntegrationTime[0] is a no-op
  end;
  SetLength(MainForm.States, IntForm.ModeBox.Tag);
  for i:=0 to IntForm.ModeBox.Tag-1 do if Length(MainForm.States[i])<>MainForm.BSPXFile.DescCount then
   begin
    SetLength(MainForm.States[i], MainForm.BSPXFile.DescCount);
    if MainForm.BSPXFile.DescCount>0 then FillChar(MainForm.States[i][0], MainForm.BSPXFile.DescCount*SizeOf(TState4D), 0);
   end;
  SetLength(MainForm.PerturberStates, IntForm.ModeBox.Tag);
  for i:=0 to IntForm.ModeBox.Tag-1 do if Length(MainForm.PerturberStates[i])<>MainForm.BSPXFile.DescCount then
   begin
    SetLength(MainForm.PerturberStates[i], MainForm.BSPXFile.DescCount);
    if MainForm.BSPXFile.DescCount>0 then FillChar(MainForm.PerturberStates[i][0], MainForm.BSPXFile.DescCount*SizeOf(TState4D), 0);
   end;
  IntegrationMode:=IntegrationModeSelected;
end;

procedure TIntForm.ModeBoxClick(Sender: TObject);
const
  // dimension = the number of PerturberState snapshots (one per node-time coefficient) each mode needs.
  // Taken from the CelestialMechanics IntegrationCoef_* table lengths (Length is a const-expr function),
  // so it can never drift from the coefficient tables.  Order = INT_VERLET2..INT_GAUSSRADAU15.
  Dimension: array[INT_VERLET2..INT_GAUSSRADAU15] of Int64 =
    (Length(IntegrationCoef_Leapfrog2),            Length(IntegrationCoef_McLachlan4),
     Length(IntegrationCoef_DormandPrince54),      Length(IntegrationCoef_BlanesMoanMcLachlan6),
     Length(IntegrationCoef_DormandPrince87),      Length(IntegrationCoef_GaussRadau15));
begin
  // ModeBox.Tag (the perturber-snapshot count) and IntegrationModeSelected (the integrator) are
  // read together by IntegrationModeChange on the render thread to size PerturberStates vs pick
  // the method. If a switch interleaves a frame, a torn read can size for a smaller mode while
  // the larger BlanesMoanMcLachlan6 (11 snapshots) is selected -> P[10] out of bounds -> the
  // render thread dies and the UI freezes. Update the pair under PublicLock (held for the whole
  // frame) so the render thread never observes it half-applied.
  FPublicLock.Acquire;
  try
   ModeBox.Tag:=Dimension[ModeBox.ItemIndex];
   IntegrationModeSelected:=ModeBox.ItemIndex;
   CBprec0.Enabled:=(ModeBox.ItemIndex=INT_DORMANDPRINCE54) or (ModeBox.ItemIndex=INT_DORMANDPRINCE87) or (ModeBox.ItemIndex=INT_GAUSSRADAU15);   // zonal gravity (m=0): DP + IAS15
   CBprec1.Enabled:=(ModeBox.ItemIndex=INT_GAUSSRADAU15);   // tesseral gravity (m>=1): IAS15 only
   RBprec1a.Enabled:=CBprec1.Enabled;
   RBprec1b.Enabled:=CBprec1.Enabled;
   CBprec1Click(CBprec1);
   CBprec2.Enabled:=False;
   CBprec3.Enabled:=(ModeBox.ItemIndex=INT_GAUSSRADAU15);
   CBprec4.Enabled:=(ModeBox.ItemIndex=INT_GAUSSRADAU15);
   CBprec0.Checked:=(ModeBox.ItemIndex=INT_DORMANDPRINCE54) or (ModeBox.ItemIndex=INT_DORMANDPRINCE87) or (ModeBox.ItemIndex=INT_GAUSSRADAU15);
   CBprec1.Checked:=False;
   CBprec2.Checked:=(ModeBox.ItemIndex=INT_GAUSSRADAU15);
   CBprec3.Checked:=False;
   CBprec4.Checked:=False;
  finally
   FPublicLock.Release;
  end;
end;

procedure TIntForm.AddIntegration(const Name: string; const S: TState4D; CenterID: Int64);
var
  NG: TNonGrav;
begin
  FillChar(NG, SizeOf(NG), 0);   // no Yarkovsky by default
  NG.r0 := 1.0; NG.m := 2.0;     // standard asteroid g(r) (harmless while A1=A2=A3=0)
  AddIntegration(Name, S, CenterID, NG);
end;

procedure TIntForm.AddIntegration(const Name: string; const S: TState4D; CenterID: Int64; const NG: TNonGrav);
var
  n, i: Int64;
begin
  // The SSB state is the integrand's physical identity; the center is only a view label now, so match
  // on the state alone. A re-add (reload, or re-authoring the same state in another view) must not
  // duplicate the entry — instead refresh its center to the new view and keep the single IntBox item
  // (no IntegrationChange here, so the list rebuild/selection is left untouched).
  for i := 0 to Length(FIntegrationStates)-1 do
   if CompareMem(@FIntegrationStates[i], @S, SizeOf(TState4D)) then
    begin
     FIntegrationCenters[i] := CenterID;
     Exit;
    end;
  n := Length(FIntegrationStates) + 1;
  SetLength(FIntegrationStates,  n);
  SetLength(FIntegrationNames,   n);
  SetLength(FIntegrationCenters, n);
  SetLength(FIntegrationNonGrav, n);
  FIntegrationStates[n-1]   := S;
  FIntegrationNames[n-1]    := Name;
  FIntegrationCenters[n-1]  := CenterID;
  FIntegrationNonGrav[n-1]  := NG;
  IntegrationChange;
end;

end.
