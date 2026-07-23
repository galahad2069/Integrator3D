unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.OpenGL, Winapi.OpenGLExt, Winapi.MMSystem,
  System.SysUtils, System.Variants, System.Classes, System.UITypes, System.Math, System.SyncObjs, System.Actions,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Menus, Vcl.Imaging.Jpeg, Vcl.Imaging.pngimage, Vcl.ComCtrls, Vcl.ActnList,
  AsmUtils64, RSoftUtils64, MathPlus64, Vec4D, BSPXFile, CelestialMechanics, Osc, Vec;

const
  DATA_FOLDER      = 'data\';
  TEXTURE_FOLDER   = 'textures\';
  MAX_MENU_ITEMS   = 15;
  BGSTARS_FILENAME = DATA_FOLDER    + 'stars.dat';
  CONST_FILENAME   = DATA_FOLDER    + 'const.dat';
  BGSKY_FILENAME   = TEXTURE_FOLDER + 'bgtexture.jpg';
  STAR_DIST  = 600.0;
  SKY_DIST   = 605.0;
  DIST_NEAR  = 0.06;
  DIST_FAR   = 700.0;
  TRAIL_SIZE = 20000;
  FROZEN_LIFE = 600;         // frames a collided integrand's captured trail stays on screen before it's dropped
  SPHERE_SLICES     = 32;    // gluSphere longitudinal subdivisions
  SPHERE_STACKS     = 24;    // gluSphere latitudinal subdivisions
  SPHERE_MIN_PIXELS = 5.0;   // a body draws as a textured sphere only when its projected radius exceeds this (else a dot)
  DOT_PIXELS        = 10.0;  // body-dot diameter in px -- as judged on a DOT_REF_VIEWH-tall viewport, scaled to the actual one by BodyDotSize
  DOT_REF_VIEWH     = 1500.0;// the viewport height DOT_PIXELS was judged against (a maximised window on a 2560x1600 screen). Raise it to make dots smaller everywhere, lower it to make them bigger
  DOT_MIN_PIXELS    = 4.0;   // floor: a dot has to stay findable however small the window gets
  FROZEN_DOT_MUL    = 0.8;   // the marker at the head of a collided integrand's fading trail, as a fraction of a body dot (was a flat 8 px against the body's 10)
  STAR_REF_SCREENH  = 1600.0;// the screen height the PS[] magnitude->px table was calibrated against (a 2560x1600 screen, main window maximised). See LoadStarList
  STAR_MIN_PIXELS   = 1.0;   // floor: below a pixel the faintest magnitudes just fade out of existence
  RING_INNER_MUL    = 1.2;   // ring annulus inner/outer radius as a multiple of the planet Req (tuned to the ring texture's radial span)
  RING_OUTER_MUL    = 2.3;
  SPHERE_LON0       = 90.0;  // texture-seam alignment (deg): gluSphere's s=0 seam sits at local +Y, 90 deg from the
                             // body prime meridian (+X). Added to W so a tidally-locked moon's near side faces its
                             // planet. Adjust in 90-deg steps (0/90/180/270) if a map's 0-longitude is elsewhere.
  INI_BSPXFILE      = 'BSPXFile';
  INI_FPSLIMIT      = 'FPSLimit';
  INI_ANIMSPEED     = 'AnimationSpeed';
  INI_DISPLAYAXES   = 'DisplayAxes';
  INI_DISPLAYSTARS  = 'DisplayStars';
  INI_DISPLAYSKY    = 'DisplaySky';
  INI_DISPLAYCONST  = 'DisplayConst';
  INI_DISPLAYLABELS = 'DisplayLabels';
  INI_DISPLAYBODIES = 'DisplayBodies';
  INI_DISPLAYLIGHT  = 'DisplayLight';
  INI_ORBITMODE_GEN = 'OrbitModeGen';
  INI_ORBITMODE_INT = 'OrbitModeInt';
  INI_NOAVX2WARNING = 'DisableAVX2Confirmation';
type
  TColorRec  = record R, G, B, A: Single; end;
  TVertexData = packed record
    X, Y, Z, W, PointSize, ColorR, ColorG, ColorB: Single;
  end;
  TConstVertexData = packed record X, Y, Z: Single; end;
  TSkyVertex = packed record X, Y, Z, U, V: Single; end;
  TTrailRec = record
    Pts: array of TVec4D;
    Head, Count: Integer;
  end;
  // A collided integrand evicted from the active set: its captured trail + colour, drawn (trail + dot)
  // for FROZEN_LIFE frames then dropped. Keeps the integrators zero-overhead -- they never see it again.
  TFrozenRec = record
    Pts: array of TVec4D;   // captured display-frame trail points (same form as FTrails)
    Color: TColorRec;
    Life: Integer;          // frames remaining before removal
  end;
  // A co-rotating-frame axis: the view rotates so the Center->Target direction stays fixed (integration
  // itself stays inertial -- this is display-only). One per PMRot axis item, indexed by the item's Tag.
  TRotAxis = record Center, Target: Int64; end;   // NAIF ids

  TMainForm = class(TForm)
    glPanel: TPanel;
    PopupMenu: TPopupMenu;
    PMStart: TMenuItem;
    N1: TMenuItem;
    PMBarycenter: TMenuItem;
    PMSpeed: TMenuItem;
    PMSpeed0: TMenuItem;
    PMSpeed1: TMenuItem;
    PMSpeed2: TMenuItem;
    PMSpeed3: TMenuItem;
    PMSpeed4: TMenuItem;
    PMSpeed5: TMenuItem;
    PMSpeed6: TMenuItem;
    PMSpeed7: TMenuItem;
    PMSpeed8: TMenuItem;
    PMBarycenter0: TMenuItem;
    N2: TMenuItem;
    PMLoad: TMenuItem;
    OpenDialog: TOpenDialog;
    PMDraw: TMenuItem;
    PMDrawAxes: TMenuItem;
    PMDrawStars: TMenuItem;
    PMDrawSky: TMenuItem;
    PMDrawConst: TMenuItem;
    PMDrawLabels: TMenuItem;
    PMOsc: TMenuItem;
    PMOrbitMode: TMenuItem;
    PMOrbitMode0: TMenuItem;
    PMOrbitMode1: TMenuItem;
    PMBodies: TMenuItem;
    PMCamCenter: TMenuItem;
    PMIntegrator: TMenuItem;
    PMOrbitMode2: TMenuItem;
    StatusBar: TStatusBar;
    PMRot: TMenuItem;
    PMRot0: TMenuItem;
    PMOrbitModeInt: TMenuItem;
    PMOrbitModeInt0: TMenuItem;
    PMOrbitModeInt1: TMenuItem;
    PMOrbitModeInt2: TMenuItem;
    PMLighting: TMenuItem;
    PMSpeed01: TMenuItem;
    PMSpeed02: TMenuItem;
    PMSpeed9: TMenuItem;
    PMAcc: TMenuItem;
    PMOrbitCenter: TMenuItem;
    PMSaveIni: TMenuItem;
    PMLoadIni: TMenuItem;
    N3: TMenuItem;
    ActionList: TActionList;
    ActionStart: TAction;
    ActionSpeed0: TAction;
    ActionSpeed1: TAction;
    ActionSpeed2: TAction;
    ActionSpeed3: TAction;
    ActionSpeed4: TAction;
    ActionSpeed5: TAction;
    ActionSpeed6: TAction;
    ActionSpeed7: TAction;
    ActionSpeed8: TAction;
    ActionSpeed9: TAction;
    ActionSpeed10: TAction;
    ActionSpeed11: TAction;
    ActionBarycenter0: TAction;
    ActionCoRotOff: TAction;
    ActionLoad: TAction;
    ActionNewOsc: TAction;
    ActionIntegrators: TAction;
    ActionLoadIni: TAction;
    ActionSaveIni: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure glPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure glPanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure glPanelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure PMSpeedClick(Sender: TObject);
    procedure PMStartClick(Sender: TObject);
    procedure PMBarycenterClick(Sender: TObject);
    procedure PMDrawClick(Sender: TObject);
    procedure PMLoadClick(Sender: TObject);
    procedure PMRotClick(Sender: TObject);              // co-rotating axis selection handler
    procedure SetFPSLimit(Value: Double);
    procedure PMAccItemClick(Sender: TObject);   // a PMAcc child: start a new AccForm for that active integration
    procedure PMNewOscClick(Sender: TObject);
    procedure PMOrbitModeClick(Sender: TObject);
    procedure PMOrbitModeIntClick(Sender: TObject);   // integrand orbit-display-mode selection (mirrors PMOrbitModeClick)
    procedure PMToggleClick(Sender: TObject);
    procedure PMCamCenterClick(Sender: TObject);
    procedure PMIntegratorClick(Sender: TObject);
    procedure OnHintDo(Sender: TObject);
    procedure SaveIniFile(Sender: TObject);
    procedure LoadIniFile(Sender: TObject);
  private
    FDC: HDC;
    FRC: HGLRC;
    FT, FDT, FSDT, FDist, FAlpha, FDelta, FdAlpha, FdDelta, FLM: Double;
    MouseX, MouseY: Integer;
    FBSPXFile: TBSPXFile;
    FEpsMatrix: TMat4D;
    FBarycenter, FParentBarycenter: Int64;
    FOrbitCenter: Int64;   // body the OSCULATING ORBITS focus on (display-only); default = FBarycenter (barycentric)
    FBaryDescIdx: Int64;   // descriptor index of FBarycenter itself (-1 for SSB); its SSB position is the display re-centre offset
    FDistUnits: array of Double;
    FColors: array of TColorRec;
    FSpeeds: array of Int64;
    FMinorViewItem: TMenuItem;   // the "Minor body view" PMBarycenter item (Tag=MINOR_VIEW_TAG); enable state tracked by UpdateMinorViewEnabled
    FSkyTexture:  GLuint;
    FSkyProgram:  GLuint;
    FSkyVBO:      GLuint;
    FBodyTextures: array of GLuint;   // per-descriptor surface texture (0 = none); built lazily on the render thread
    FRingTextures: array of GLuint;   // per-descriptor ring texture (0 = none), from TEXTURE_FOLDER\<id>_rings.png (RGBA/alpha)
    FSphereQuad:   GLUquadricObj;     // shared GLU quadric used to draw textured body spheres
    FBuildBodyTex: Boolean;           // set on file load (UI thread) -> RenderScene (re)builds FBodyTextures next frame
    FCoronaTexture: GLuint;           // procedurally-generated radial glow, drawn as an additive billboard at the Sun
    FSkyVtxCount: Integer;
    FSkyAttrPos:  GLint;
    FSkyAttrUV:   GLint;
    FWhiteMaterial: array[0..3] of Single;
    FGrayMaterial: array[0..3] of Single;
    FExeStr, FExeDir, FIniFile, FDataFile: string;
    FStarVBO: GLuint;
    FStarProgram: GLuint;
    FStarCount: GLsizei;
    FAttrPosition: GLint;
    FAttrPointSize: GLint;
    FAttrColor: GLint;
    FConstVBO: GLuint;
    FConstProgram: GLuint;
    FConstCount: GLsizei;
    FConstAttrPosition: GLint;
    FTrails: array of TTrailRec;
    FFrozen: array of TFrozenRec;   // collided integrands kept for display only (see FreezeIntegrand/DrawFrozen)
    FClearFrozen: Boolean;          // UI-thread request (barycenter/reset) to drop FFrozen; honoured on the render thread
    FCamOrphaned: Boolean;          // the camera centre was locked on an integrand that has since collided -> the fade-out rebuild drops it back to the barycentre. Cleared when the user picks a centre (PMCamCenterClick) or by any rebuild
    FCamMenuStale: Boolean;         // a collision removed an integrand but PMCamCenter still lists it. Cleared by ANY RebuildCamCenterMenu, so the fade-out rebuild is skipped when one already happened (barycenter switch, IntForm change)
    FRotAxis: array of TRotAxis;    // co-rotating-frame axis table, indexed by the PMRot item's Tag
    FRotCenter, FRotTarget: Int64;  // active co-rotating axis (NAIF ids); FRotTarget < 0 = Off
    FCoRotMatrix: TMat4D;           // display-only co-rotation for the current frame (identity when Off); see UpdateCoRotMatrix
    FRotCenterDisp: TVec4D;         // FRotCenter's position in the co-rotated display frame; subtracted from every absolute position (DispPos) so the rotation centre sits motionless at the origin. Zero when Off.
    FEyePos: TVec4D;                // camera/eye position in display AU (per frame); DrawBodySphere sizes by the true eye->body distance
    FLightingOn: Boolean;           // this frame: light the body spheres from the Sun (PMLighting on AND the Sun is loaded)
    FSunPos: TVec4D;                // Sun position in the display frame (AU), valid when FLightingOn; used for the ring shadow
    FLabelTextures: array of GLuint;
    FLabelWidths: array of Integer;
    FLabelHeights: array of Integer;
    FLabelPts: array of TVec4D;
    FRenderThread: TThread;
    FOscForms: array of TOscForm;
    FStateLock: TCriticalSection;
    FSnapshotBuf: TState4DArray;
    FRunning: Boolean;
    FFPS: Integer;
    FViewW, FViewH: Integer;
    FInvFPSLimit,             // target frame period in seconds (= 1/FPS-limit)
    FEphemDelta,                   // ACTUAL ephemeris step taken this frame (what the title shows);
                                   //   next frame starts from min(FSDT, FDT*FInvFPSLimit).
                                   //   The adaptive suggestion it grows from is just FSDT (no
                                   //   separate carry var — FSDT already holds it across frames).
    FRadauLastDt: Double;          // last accepted IAS15 step (for the predictor); 0 = fresh
    procedure ResetVars;
    procedure LoadStarList;
    procedure LoadLabelTextures;
    procedure LoadConstList;
    procedure LoadSkyTexture;
    function LoadFile(const FileName: string): Boolean;
    procedure InitOpenGL;
    procedure SetupPixelFormat;
    procedure DrawAxes;
    procedure DrawSky;
    procedure DrawStars;
    procedure DrawConst;
    procedure DrawLabels;
    procedure BuildBodyTextures;                      // (re)load per-body surface + ring textures on the render thread
    function  LoadPNGTexture(const fn: string): GLuint; // load a PNG (with alpha) into a GL texture; 0 on failure (ring textures)
    procedure DrawRing(const Center, AxisX, AxisY: TVec4D; innerR, outerR, planetR: Double; texID: GLuint);  // textured annulus in the planet equatorial plane (planet shadow when lit)
    function  DrawBodySphere(i: Int64; const Pt: TVec4D): Boolean;  // draw body i as a textured, axis-oriented sphere if eligible; False -> caller draws a dot
    function  BodyDotSize: Single;                                  // glPointSize for a body dot, scaled to the current viewport height
    procedure DrawCorona(const RotM: array of GLdouble);            // additive camera-facing glow billboard at the Sun (RotM = camera rotation for right/up)
    procedure BuildCoronaTexture;                                   // generate the radial Sun-glow texture once (no external file)
    procedure DrawOrbits(Integrands: Boolean);        // Integrands=False -> BSPX bodies (PMOrbitMode); True -> integrands (PMOrbitModeInt)
    procedure DrawTrajectories(Integrands: Boolean);
    procedure DrawDots(Integrands: Boolean);
    procedure UpdateIntegrationLabels;
    procedure UpdateTitleBar;
    procedure RenderScene;
    procedure AdvanceScene;
    function  PerturberContaining(idx: Int64): Int64;   // descriptor index of a perturber integrand idx is inside, or -1
    procedure CheckNewIntegrationICs;
    procedure FreezeIntegrand(idx: Int64);              // evict a collided integrand to the frozen-display list
    procedure DrawFrozen;                               // draw + age the frozen-display list
    procedure RebuildRotMenu;                           // rebuild the co-rotating-frame axis menu for the current FBarycenter
    procedure RotUncheckAll;                            // clear checks on every PMRot item (Off + centre headers + nested leaves)
    procedure RebuildOrbitCenterMenu;                   // rebuild PMOrbitCenter (the osculating-orbit focus) for the current system
    procedure PMOrbitCenterClick(Sender: TObject);      // osculating-orbit-centre selection handler
    procedure BuildCentreMenu(Root: TMenuItem; Handler: TNotifyEvent; MassiveOnly: Boolean);   // shared body-centre builder (PMOrbitCenter/PMCamCenter): root BC, barycentres, primary, packed others
    procedure UncheckMenuTree(Root: TMenuItem);         // recursive: clear Checked on every descendant of Root
    function  FindMenuLeafByTag(Root: TMenuItem; ATag: Int64): TMenuItem;   // recursive: first leaf (no children) with Tag=ATag, or nil
    function  AxisEndpointSSB(id: Int64; out S: TState4D): Boolean;  // SSB state of a co-rotating-axis endpoint from the current frame's arrays
    procedure UpdateCoRotMatrix;                        // rebuild FCoRotMatrix from the current axis + states (once per frame, before the trail store)
    function  DispPos(const p: TVec4D): TVec4D;         // FBarycenter-relative absolute position -> co-rotated, FRotCenter-re-centred display coords (NOT for velocities/relative vectors)
    function  TrailOrbitOfs: TVec4D;                    // display offset that lands an orbit-centre-relative trail point on the orbit centre's dot (= the conic's GravOfs); 0 when FOrbitCenter=FBarycenter
    function  IntegrandInSystem(idx: Int64): Boolean;   // whether integrand idx currently belongs to FBarycenter's system (Hill-radius test; always True in the full SSB view)
    function  IntegrandShown(idx: Int64): Boolean;      // whether integrand idx is drawn now (hides out-of-view ones while co-rotating)
    procedure CloseAllDynForms;
  public
    States: TState4DArrays;
    PerturberStates: TState4DArrays;
    //FSS: Double;   // scratch scalar shown in the title bar; currently the PN SoA/AoS validation diff (see AdvanceScene / UpdateTitleBar)
    procedure RebuildCamCenterMenu(PreserveTarget: Boolean = False);   // public: IntForm calls it (True) when the active integration set changes
    procedure SelectCamCenter(id: Int64);              // point PMCamCenter at the leaf Tag=id (checks + Tag); root/FBarycenter if absent
    procedure UpdateMinorViewEnabled;                  // refresh FMinorViewItem.Enabled from the current FBarycenter + camera centre
    procedure RebuildAccMenu;          // public: rebuild PMAcc's children from the active integration set (IntForm calls it on any change)
    procedure UnregisterOscForm(Form: TOscForm);
    procedure TakeSnapshot(var Snap: TState4DArray);
    property BSPXFile: TBSPXFile read FBSPXFile;
    property EpsMatrix: TMat4D read FEpsMatrix;
    property Barycenter: Int64 read FBarycenter;
    property TimeAcceleration: Double read FDT;
  end;

var
  MainForm: TMainForm;

const
  CAPS_DIST:      array[0..1] of string = ('km', 'AU');
  HINTS_DIST:     array[0..1] of string = ('kilometer(s)', 'Astronomical Unit(s)');
  CAPS_EPOCH:     array[0..2] of string = ('ET (sec)', 'TJD', 'Gregorian');
  HINTS_EPOCH:    array[0..2] of string = ('Ephemeris time (seconds since J2000)', 'Julian format', 'Gregorian YYYY-MM-DD.fraction of day format');
  CAPS_TIME:      array[0..6] of string = ('sec', 'hr', 'day(s)', 'week(s)', 'month(s)', 'τ', 'year(s)');
  HINTS_TIME:     array[0..6] of string = ('second(s)', 'hour(s)', '1 day = 86400 seconds', '1 week = 7 days', '1 month = 30 days', '1 τ = 58.132441 days', '1 year = 365.25 days');
  CAPS_SPEED:     array[0..2] of string = ('km/s', 'AU/day', 'AU/τ');
  HINTS_SPEED:    array[0..2] of string = ('kilometer(s) per second', 'Astronomical unit(s) per day', 'Astronomical unit(s) per 58.132441 days');
  CAPS_SQRTDIST:  array[0..1] of string = ('√km', '√AU');
  HINTS_SQRTDIST: array[0..1] of string = ('square-root kilometer(s)', 'square-root Astronomical Unit(s)');
  CAPS_DIST2PT2:  array[0..2] of string = ('km²/s²', 'AU²/day²', 'AU²/τ²');
  HINTS_DIST2PT2: array[0..2] of string = ('square kilometer(s) per square second', 'square Astronomical Unit(s) per square day', 'square Astronomical Unit(s) per square 58.132441-days');
  CAPS_DIST2PT:   array[0..2] of string = ('km²/s', 'AU²/day', 'AU²/τ');
  HINTS_DIST2PT:  array[0..2] of string = ('square kilometer(s) per second', 'square Astronomical Unit(s) per day', 'square Astronomical Unit(s) per 58.132441 days');
  CAPS_ANGLEPT:   array[0..7] of string = ('rad/s', 'rad/hr', 'rad/day', 'rad/τ', 'deg/s', 'deg/hr', 'deg/day', 'deg/τ');
  HINTS_ANGLEPT:  array[0..7] of string = ('radian(s) per second', 'radian(s) per hour', 'radian(s) per day', 'radian(s) per 58.132441 days', 'degree(s) per second', 'degree(s) per hour', 'degree(s) per day', 'degree(s) per 58.132441 days');
  CAPS_ANGLE:     array[0..1] of string = ('rad', 'deg');
  HINTS_ANGLE:    array[0..1] of string = ('radian(s)', 'degree(s)');
  CAPS_ACC:       array[0..6] of string = ('μm/s²', 'mm/s²', 'm/s²', 'g', 'km/s²', 'AU/τ²', 'AU/day²');
  HINTS_ACC:      array[0..6] of string = ('micron(s) per square second', 'millimeter(s) per square second', 'meter(s) per square second', '1 g = 9.81 meters per square second', 'kilometer(s) per square seconds', 'Astronomical Unit(s) per square 58.132441-days', 'Astronomical Unit(s) per square day');
  CAPS_BC:        array[0..1] of string = ('kg/m²', 'kg/km²');
  HINTS_BC:       array[0..1] of string = ('kilogram(s) per square meter', 'kilogram(s) per square kilometer');
  CAPS_IBC:       array[0..1] of string = ('m²/kg', 'km²/kg');
  HINTS_IBC:      array[0..1] of string = ('square meter(s) per kilogram', 'square kilometer(s) per kilogram');
  CAPS_GM:        array[0..3] of string = ('m³/s²', 'km³/s²', 'AU³/day²', 'AU³/τ²');
  HINTS_GM:       array[0..3] of string = ('cubic meter(s) per square second', 'cubic kilometer(s) per square second', 'cubic Astronomical Unit(s) per square day', 'cubic Astronomical Unit(s) per square 58.132441-days');
  CAPS_M:         array[0..0] of string = ('kg');
  HINTS_M:        array[0..0] of string = ('kilogram(s)');
  CAPS_DENS:      array[0..2] of string = ('g/cm³', 'kg/m³', 'kg/km³');
  HINTS_DENS:     array[0..2] of string = ('gram(s) per cubic centimeter', 'kilogram(s) per cubic meter', 'kilogram(s) per cubic kilometer');

implementation

{$R *.dfm}

uses Int, CPUTopologyService64;

const
  // Characteristic display radius (km) for each barycenter 0-10 + generic.
  // Used to set the initial camera distance to 4× this value (in AU) when
  // switching barycenter, so the outer satellites fit comfortably in view.
  DistUnits: array[0..11] of Double = (
   AU_KM,      // 0  SSB
   8000.0,     // 1  Mercury
   40000.0,    // 2  Venus
   40000.0,    // 3  Earth-Moon
   8000.0,     // 4  Mars
   500000.0,   // 5  Jupiter
   1000000.0,  // 6  Saturn
   240000.0,   // 7  Uranus
   160000.0,   // 8  Neptune
   8000.0,     // 9  Pluto
   AU_KM,      // 10 Sun
   10000.0);   // 11 generic (also the km-scale for a minor-body view)

  // Sentinel Tag for the "Minor body view" PMBarycenter item: not a valid TargetID (>=0), so it can only mean the
  // special item. PMBarycenterClick detects it and adopts the current camera centre as FBarycenter (see there).
  MINOR_VIEW_TAG = -1000;

  GL_ARRAY_BUFFER              = $8892;
  GL_STATIC_DRAW               = $88E4;
  GL_VERTEX_SHADER             = $8B31;
  GL_FRAGMENT_SHADER           = $8B30;
  GL_VERTEX_PROGRAM_POINT_SIZE = $8642;
  GL_POINT_SPRITE              = $8861;
  GL_COMPILE_STATUS            = $8B81;
  GL_LINK_STATUS               = $8B82;

type
  PGLint = ^GLint;
  TGL2 = record
    GenBuffers:               procedure(n: GLsizei; buffers: PGLuint); stdcall;
    BindBuffer:               procedure(target: GLenum; buffer: GLuint); stdcall;
    BufferData:               procedure(target: GLenum; size: NativeUInt; const data: Pointer; usage: GLenum); stdcall;
    DeleteBuffers:            procedure(n: GLsizei; const buffers: PGLuint); stdcall;
    CreateShader:             function(shaderType: GLenum): GLuint; stdcall;
    ShaderSource:             procedure(shader: GLuint; count: GLsizei; const str: PPAnsiChar; const length: PGLint); stdcall;
    CompileShader:            procedure(shader: GLuint); stdcall;
    CreateProgram:            function: GLuint; stdcall;
    AttachShader:             procedure(prog, shader: GLuint); stdcall;
    LinkProgram:              procedure(prog: GLuint); stdcall;
    UseProgram:               procedure(prog: GLuint); stdcall;
    DeleteShader:             procedure(shader: GLuint); stdcall;
    DeleteProgram:            procedure(prog: GLuint); stdcall;
    GetAttribLocation:        function(prog: GLuint; const name: PAnsiChar): GLint; stdcall;
    VertexAttribPointer:      procedure(index: GLuint; size: GLint; atype: GLenum; normalized: GLboolean; stride: GLsizei; const offset: Pointer); stdcall;
    EnableVertexAttribArray:  procedure(index: GLuint); stdcall;
    DisableVertexAttribArray: procedure(index: GLuint); stdcall;
  end;

var
  GL2: TGL2;

// ---------------------------------------------------------------------------
//  Render thread — owns the GL context for its entire lifetime
// ---------------------------------------------------------------------------
type
  TRenderThread = class(TThread)
  private
    FForm: TMainForm;
  public
    constructor Create(AForm: TMainForm);
    procedure Execute; override;
  end;

constructor TRenderThread.Create(AForm: TMainForm);
begin
  inherited Create(False);
  FForm := AForm;
  FreeOnTerminate := False;
end;

procedure TRenderThread.Execute;
var
  Freq, T0, T1, TFPSTimer, TargetTicks: Int64;
  RemainMs: Double;
  FrameCount, LastW, LastH: Integer;
  SwapInterval: procedure(interval: Integer); stdcall;
  PMask: NativeUInt;
begin
  // Pin the render thread (which also runs AdvanceScene, i.e. the integration) to the P-cores. On a hybrid CPU
  // (12th-gen+ Intel) the Thread Director can migrate a long-running thread onto an E-core, whose AVX2 throughput
  // and clock are much lower -- which can drop the AVX2 build toward scalar levels and cause run-to-run FPS
  // variance. Never let this thread run on an E-core.
  PMask := GetPCoreAffinityMask64;
  if PMask <> 0 then SetThreadAffinityMask(GetCurrentThread, PMask);   // 0 = non-hybrid / detection failed -> leave scheduling to the OS
  QueryPerformanceFrequency(Freq);
  QueryPerformanceCounter(T0);
  TFPSTimer := T0;
  FrameCount := 0;
  LastW := 0;
  LastH := 0;
  timeBeginPeriod(1);
  wglMakeCurrent(FForm.FDC, FForm.FRC);
  // Disable driver-enforced VSync for this context; we pace frames ourselves
  SwapInterval := wglGetProcAddress('wglSwapIntervalEXT');
  if Assigned(SwapInterval) then SwapInterval(0);
  while not Terminated do
   begin
    QueryPerformanceCounter(T0);

    // Re-apply viewport/projection whenever the panel is resized
    if (FForm.FViewW <> LastW) or (FForm.FViewH <> LastH) then
     begin
      LastW := FForm.FViewW;
      LastH := FForm.FViewH;
      if (LastW > 0) and (LastH > 0) then
       begin
        glViewport(0, 0, LastW, LastH);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity;
        gluPerspective(45.0, LastW / LastH, DIST_NEAR, DIST_FAR);
        glMatrixMode(GL_MODELVIEW);
       end;
     end;

    // All reads/writes of the shared IntForm public arrays (IntegrationS/A/C/
    // Names/Time/Coef and TmpR/V/A) happen here on the render thread. IntBoxClick
    // and Reset mutate the same arrays (SetLength) under PublicLock, so the render
    // thread must hold it too — otherwise a UI-side reallocation frees a buffer
    // we are iterating and the thread dies on an access violation (the "freeze").
    // Held for the whole frame; IntBoxClick then waits at most one frame.
    IntForm.PublicLock.Acquire;
    try
     if FForm.FRunning then
      FForm.AdvanceScene
     else
      FForm.RenderScene;
    finally
     IntForm.PublicLock.Release;
    end;
    // Title update uses only scalar fields; kept outside the lock (see UpdateTitleBar).
    FForm.UpdateTitleBar;

    // FPS counter — updated once per second
    Inc(FrameCount);
    QueryPerformanceCounter(T1);
    if (T1 - TFPSTimer) >= Freq then
     begin
      FForm.FFPS := FrameCount;
      FrameCount := 0;
      TFPSTimer := T1;
     end;

    // Frame limiter: hold each frame to the target period (FInvFPSLimit = 1/FPS-limit),
    // re-read every frame so a live FPS-limit change takes effect. Coarse Sleep for the bulk
    // (leaving ~1 ms), then a short spin to the exact boundary — far less jitter than Sleep
    // alone, which over/undershoots by its ~1 ms granularity. If the frame's own work already
    // overran the budget we simply don't wait (FPS drops below the limit; that's allowed).
    TargetTicks := Round(FForm.FInvFPSLimit * Freq);
    QueryPerformanceCounter(T1);
    if (T1 - T0) < TargetTicks then
     begin
      RemainMs := (TargetTicks - (T1 - T0)) * 1000.0 / Freq;
      if RemainMs > 1.5 then Sleep(Trunc(RemainMs - 1.0));
      repeat QueryPerformanceCounter(T1) until (T1 - T0) >= TargetTicks;
     end;
   end;
  wglMakeCurrent(FForm.FDC, 0);
  timeEndPeriod(1);
end;

// ---------------------------------------------------------------------------

procedure LoadGL2Procs;
  function P(const Name: AnsiString): Pointer;
  begin Result := wglGetProcAddress(PAnsiChar(Name)); end;
begin
  GL2.GenBuffers               := P('glGenBuffers');
  GL2.BindBuffer               := P('glBindBuffer');
  GL2.BufferData               := P('glBufferData');
  GL2.DeleteBuffers            := P('glDeleteBuffers');
  GL2.CreateShader             := P('glCreateShader');
  GL2.ShaderSource             := P('glShaderSource');
  GL2.CompileShader            := P('glCompileShader');
  GL2.CreateProgram            := P('glCreateProgram');
  GL2.AttachShader             := P('glAttachShader');
  GL2.LinkProgram              := P('glLinkProgram');
  GL2.UseProgram               := P('glUseProgram');
  GL2.DeleteShader             := P('glDeleteShader');
  GL2.DeleteProgram            := P('glDeleteProgram');
  GL2.GetAttribLocation        := P('glGetAttribLocation');
  GL2.VertexAttribPointer      := P('glVertexAttribPointer');
  GL2.EnableVertexAttribArray  := P('glEnableVertexAttribArray');
  GL2.DisableVertexAttribArray := P('glDisableVertexAttribArray');
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // The numeric input fields accept '.' and nothing else, so the app must read and write '.' regardless of the
  // machine's locale -- on a comma-locale system the RTL would otherwise reject '1.5' on input AND display
  // '1,5', a value the input filter will not even let the user retype. This is the successor to the old global
  // DecimalSeparator: SysUtils still keeps a global TFormatSettings, and the parameterless StrToFloat/FloatToStr
  // overloads delegate to it, so this one assignment covers every conversion in the program, both directions.
  // Set here, in the first form created, before anything can parse a number: the RTL warns that the global is
  // not thread-safe, which concerns concurrent MUTATION -- writing it once at startup, before the render thread
  // exists, is safe. Nothing is persisted as a float (the .ini holds only integers and a path), so no old
  // settings file can be misread because of this.
  FormatSettings.DecimalSeparator:='.';
  Application.OnHint:=OnHintDo;
  //DoubleBuffered:=True;
  ResetVars;
  FExeStr:='Integrator3D v'+GetMediumVersion(Application.ExeName);
  MainForm.Caption:=FExeStr;
  FExeDir:=ExeFolder;
  FIniFile:=ChangeFileExt(Application.ExeName, '.ini');
  // Disable standard VCL styling behavior for this specific container to prevent flickering
  glPanel.ControlStyle := glPanel.ControlStyle + [csOpaque] - [csDoubleClicks];
  InitOpenGL;
  FEpsMatrix:=GetRotMat4D(CEPS,-1.0, 0.0, 0.0);
  FCoRotMatrix:=GetIdentityMat4D;   // co-rotating frame starts Off; AdvanceScene rebuilds it each frame
  FStateLock:=TCriticalSection.Create;
  FBSPXFile:=TBSPXFile.Create;
  LoadStarList;
  LoadConstList;
  LoadSkyTexture;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  if MainForm.Tag=0 then
   begin
    MainForm.Tag:=1;
    ResetVars;
    RenderScene;
    MainForm.Update;
    LoadIniFile(nil);
    if not LoadFile(FDataFile) then PMLoadClick(nil);
   end;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i: Int64;
begin
  CloseAllDynForms;
  FreeAndNil(FStateLock);
  // Terminate the render thread and reclaim the GL context on this thread
  if FRenderThread <> nil then
   begin
    FRenderThread.Terminate;
    FRenderThread.WaitFor;
    FreeAndNil(FRenderThread);
    wglMakeCurrent(FDC, FRC);
   end;
  for i:=0 to High(FLabelTextures) do
   if FLabelTextures[i]<>0 then
    begin glDeleteTextures(1, @FLabelTextures[i]); FLabelTextures[i]:=0; end;
  SetLength(FLabelTextures, 0);
  for i:=0 to High(FBodyTextures) do
   if FBodyTextures[i]<>0 then
    begin glDeleteTextures(1, @FBodyTextures[i]); FBodyTextures[i]:=0; end;
  SetLength(FBodyTextures, 0);
  for i:=0 to High(FRingTextures) do
   if FRingTextures[i]<>0 then begin glDeleteTextures(1, @FRingTextures[i]); FRingTextures[i]:=0; end;
  SetLength(FRingTextures, 0);
  if FCoronaTexture <> 0 then begin glDeleteTextures(1, @FCoronaTexture); FCoronaTexture := 0; end;
  if FSphereQuad <> nil then begin gluDeleteQuadric(FSphereQuad); FSphereQuad := nil; end;
  if (FStarVBO <> 0) and Assigned(GL2.DeleteBuffers) then
   begin GL2.DeleteBuffers(1, @FStarVBO); FStarVBO := 0; end;
  if (FStarProgram <> 0) and Assigned(GL2.DeleteProgram) then
   begin GL2.DeleteProgram(FStarProgram); FStarProgram := 0; end;
  if (FConstVBO <> 0) and Assigned(GL2.DeleteBuffers) then
   begin GL2.DeleteBuffers(1, @FConstVBO); FConstVBO := 0; end;
  if (FConstProgram <> 0) and Assigned(GL2.DeleteProgram) then
   begin GL2.DeleteProgram(FConstProgram); FConstProgram := 0; end;
  SetLength(FSpeeds, 0);
  SetLength(FColors, 0);
  SetLength(FDistUnits, 0);
  FBSPXFile.Free;
  if FSkyTexture <> 0 then glDeleteTextures(1, @FSkyTexture);
  FSkyTexture := 0;
  if (FSkyVBO <> 0) and Assigned(GL2.DeleteBuffers) then
   begin GL2.DeleteBuffers(1, @FSkyVBO); FSkyVBO := 0; end;
  if (FSkyProgram <> 0) and Assigned(GL2.DeleteProgram) then
   begin GL2.DeleteProgram(FSkyProgram); FSkyProgram := 0; end;
  IntForm.Reset(True);
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if (FRC = 0) or (FDC = 0) then Exit;
  FViewW := glPanel.ClientWidth;
  FViewH := glPanel.ClientHeight;
  // When the render thread is running it picks up FViewW/FViewH itself;
  // during initialisation (no thread yet) we set up the projection directly.
  if FRenderThread = nil then
   begin
    glViewport(0, 0, FViewW, FViewH);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    if FViewH > 0 then gluPerspective(45.0, FViewW / FViewH, DIST_NEAR, DIST_FAR);
    glMatrixMode(GL_MODELVIEW);
   end;
end;

procedure TMainForm.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  FDist:=FDist*IntPower(1.05, -Sign(WheelDelta));
  Handled:=True;
end;

procedure TMainForm.glPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
   begin
    MouseX:=X;
    MouseY:=Y;
   end;
end;

procedure TMainForm.glPanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
   begin
    FAlpha:=FAlpha+FdAlpha;
    FDelta:=FDelta+FdDelta;
    FdAlpha:=0.0;
    FdDelta:=0.0;
   end;
end;

procedure TMainForm.glPanelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if (ssLeft in Shift) then
   begin
    FdAlpha:=180.0*(X-MouseX)/glPanel.ClientWidth;
    FdDelta:=180.0*(Y-MouseY)/glPanel.ClientHeight;
   end;
end;

procedure TMainForm.PMStartClick(Sender: TObject);
begin
  FRunning := not FRunning;
end;

procedure TMainForm.PMToggleClick(Sender: TObject);
begin
  TMenuItem(Sender).Checked := not TMenuItem(Sender).Checked;
end;

procedure TMainForm.PMCamCenterClick(Sender: TObject);
// Pick the camera centre. The menu nests (name-range submenus), so uncheck the whole tree, check the clicked leaf,
// and flag its ancestor chain. PMCamCenter.Tag mirrors the leaf (read by RenderScene; = FBarycenter means no offset).
var
  mi, p: TMenuItem;
begin
  UncheckMenuTree(PMCamCenter);
  mi := TMenuItem(Sender);
  mi.Checked := True;
  p := mi.Parent;
  while (p <> nil) and (p <> PMCamCenter) do begin p.Checked := True; p := p.Parent; end;
  PMCamCenter.Tag := mi.Tag;
  FCamOrphaned := False;   // the user has chosen a centre: cancel any pending fall-back to the barycentre (see FreezeIntegrand/DrawFrozen)
  UpdateMinorViewEnabled;   // camera centre changed -> the minor-body item may become (un)offerable
end;

procedure TMainForm.PMBarycenterClick(Sender: TObject);
var
  i, newBary: Int64;
begin
  if Sender is TAction then Sender:=PMBarycenter0;
  if not TMenuItem(Sender).Checked then
   begin
    if TMenuItem(Sender).Tag = MINOR_VIEW_TAG then
     begin
      // "Minor body view": adopt the current camera-centre body as the barycentre (a minor body with its own
      // descriptor but no barycentre node). The enable gate keeps this to a valid body, but re-check so a stale state
      // or an integrand camera centre (Tag < 0, no descriptor) is a harmless no-op rather than an invalid FBarycenter.
      if FBSPXFile.FindDesc(PMCamCenter.Tag) < 0 then Exit;
      newBary := PMCamCenter.Tag;
     end
    else newBary := TMenuItem(Sender).Tag;
    PMBarycenter.Items[PMBarycenter.Tag].Checked:=False;
    TMenuItem(Sender).Checked:=True;
    PMBarycenter.Tag:=TMenuItem(Sender).MenuIndex;
    FBarycenter:=newBary;
    // Rescope the camera-target menu to the new system (and reset the target to its coordinate
    // center): a target outside the system is no longer offered, and an old one is cleared.
    RebuildCamCenterMenu;
    RebuildRotMenu;   // rescope the co-rotating-frame axes to the new system (resets co-rotation to Off)
    RebuildOrbitCenterMenu;   // rescope the osculating-orbit centre to the new system (resets to barycentric)
    IntForm.RebuildIdleAccFormCenters;   // rescope each idle AccForm's centre combo to the new system
    FBaryDescIdx:=FBSPXFile.FindDesc(FBarycenter);   // FBarycenter's own descriptor index (-1 = SSB, no descriptor)
    FParentBarycenter:=FBaryDescIdx;
    if FParentBarycenter>0 then FParentBarycenter:=FBSPXFile.Desc[FParentBarycenter].CenterID;
    // Initial camera distance: 4x the system's characteristic radius. A minor body has no DistUnits slot -> use the
    // generic km-scale, which is what actually escapes the AU-scale float32 jitter (the whole point of this view).
    if (FBarycenter >= Low(DistUnits)) and (FBarycenter <= High(DistUnits)) then FDist:=4.0*DistUnits[FBarycenter]*KM2AU
    else FDist:=4.0*DistUnits[High(DistUnits)]*KM2AU;
    FAlpha:=0.0; FDelta:=-90.0; FdAlpha:=0.0; FdDelta:=0.0;
    for i := 0 to High(FTrails) do FTrails[i].Count := 0;  FClearFrozen := True;   // signal the render thread to drop frozen-display entries (stale frame)
    PMSpeedClick(PMSpeed.Items[FSpeeds[PMBarycenter.Tag]]);
   end;
end;

procedure TMainForm.PMSpeedClick(Sender: TObject);
begin
  if Sender is TAction then Sender:=PMSpeed.Items[TAction(Sender).Tag];
  if not TMenuItem(Sender).Checked then
   begin
    PMSpeed.Items[PMSpeed.Tag].Checked:=False;
    TMenuItem(Sender).Checked:=True;
    PMSpeed.Tag:=TMenuItem(Sender).MenuIndex;
    FDT:=TMenuItem(Sender).Tag;
    if Assigned(IntForm) then IntForm.RefreshIdleAccForms;   // shown accel (relative mode) tracks the new speed
   end;
end;

procedure TMainForm.PMDrawClick(Sender: TObject);
begin
  TMenuItem(Sender).Checked:=not TMenuItem(Sender).Checked;
end;

procedure TMainForm.PMIntegratorClick(Sender: TObject);
begin
  IntForm.Show;
end;

procedure TMainForm.PMLoadClick(Sender: TObject);
begin
  if OpenDialog.Execute then
   begin
    ResetVars;
    FDataFile:=OpenDialog.FileName;
    LoadFile(FDataFile);
   end;
end;

procedure TMainForm.PMNewOscClick(Sender: TObject);
var
  F: TOscForm;
begin
  SetLength(FOscForms, Length(FOscForms) + 1);
  F := TOscForm.Create(nil);
  FOscForms[High(FOscForms)] := F;
  F.Show;
end;

procedure TMainForm.PMOrbitModeClick(Sender: TObject);
var
  i: Int64;
begin
  if not TMenuItem(Sender).Checked then
   begin
    TMenuItem(Sender).Checked:=True;
    PMOrbitMode.Items[PMOrbitMode.Tag].Checked:=False;
    PMOrbitMode.Tag:=TMenuItem(Sender).MenuIndex;
    // Entering trajectory mode (Tag=1): discard whatever accumulated during the other modes.
    // Those points may have been recorded at a wildly different (e.g. ludicrous) animation speed
    // that only makes sense for osculating-orbit view, and would show as coarse straight-line
    // tails here. Restart the trails so they reflect only the path watched AS a trajectory.
    if PMOrbitMode.Tag = 1 then
     for i := 0 to FBSPXFile.DescCount-1 do FTrails[i].Count := 0;  FClearFrozen := True;   // restart only the BSPX-body trails (integrands keep theirs); drop stale frozen-display entries
   end;
end;

procedure TMainForm.PMOrbitModeIntClick(Sender: TObject);
// Integrand orbit-display mode (mirrors PMOrbitModeClick, but for PMOrbitModeInt). Selects 0=osculating,
// 1=trajectory, 2=off for integrands independently of the planet/moon bodies. Entering trajectory mode
// restarts only the INTEGRAND trails (slots >= DescCount), leaving the planet/moon trails intact.
var
  i: Int64;
begin
  if not TMenuItem(Sender).Checked then
   begin
    TMenuItem(Sender).Checked := True;
    PMOrbitModeInt.Items[PMOrbitModeInt.Tag].Checked := False;
    PMOrbitModeInt.Tag := TMenuItem(Sender).MenuIndex;
    if PMOrbitModeInt.Tag = 1 then
     for i := FBSPXFile.DescCount to High(FTrails) do FTrails[i].Count := 0;  FClearFrozen := True;   // drop stale frozen-display entries
   end;
end;

procedure TMainForm.CloseAllDynForms;
var
  i: Int64;
begin
  for i := 0 to High(FOscForms) do FOscForms[i].Free;
  SetLength(FOscForms, 0);
end;

procedure TMainForm.UnregisterOscForm(Form: TOscForm);
var
  i, j: Int64;
begin
  for i := 0 to High(FOscForms) do
   if FOscForms[i] = Form then
    begin
     for j := i to High(FOscForms) - 1 do FOscForms[j] := FOscForms[j + 1];
     SetLength(FOscForms, Length(FOscForms) - 1);
     Exit;
    end;
end;

procedure TMainForm.TakeSnapshot(var Snap: TState4DArray);
begin
  FStateLock.Acquire;
  try
   SetLength(Snap, Length(FSnapshotBuf));
   if Length(FSnapshotBuf)>0 then
    Move(FSnapshotBuf[0], Snap[0], Length(FSnapshotBuf)*SizeOf(TState4D));
  finally
   FStateLock.Release;
  end;
end;

procedure TMainForm.ResetVars;
var
  i: Int64;
begin
  if IntForm<>nil then IntForm.Reset(False);
  if FRenderThread <> nil then
   begin
    FRenderThread.Terminate;
    FRenderThread.WaitFor;
    FreeAndNil(FRenderThread);
    wglMakeCurrent(FDC, FRC);
   end;
  FRunning := False;
  for i:=0 to High(FLabelTextures) do
   if FLabelTextures[i]<>0 then
    begin glDeleteTextures(1, @FLabelTextures[i]); FLabelTextures[i]:=0; end;
  SetLength(FLabelTextures, 0);
  SetLength(FLabelWidths, 0);
  SetLength(FLabelHeights, 0);
  FDist:=10.0; FAlpha:=0.0; FDelta:=-90.0; FdAlpha:=0.0; FdDelta:=0.0;
  FRadauLastDt:=0.0;
  FEphemDelta:=0.0; FSDT:=0.0;
  FT:=0.0; FDT:=604800.0; FBarycenter:=0; FParentBarycenter:=-1; FBaryDescIdx:=-1; FOrbitCenter:=0;
  PMBarycenter.Tag:=0;
  PMBarycenter0.Checked:=True;
  PMCamCenter.Tag:=0;
  // Free (not Delete) so dynamic items aren't left orphaned under their owner across reloads;
  // freeing a submenu frees its children too. PMBarycenter keeps its design-time Items[0];
  // PMCamCenter is fully dynamic and repopulated by RebuildCamCenterMenu.
  for i:=PMBarycenter.Count-1 downto 1 do PMBarycenter.Items[i].Free;
  for i:=PMCamCenter.Count-1 downto 0 do PMCamCenter.Items[i].Free;

  SetLength(States, 0);
  SetLength(PerturberStates, 0);
  SetLength(FSpeeds, 1);
  SetLength(FTrails, 0);
  SetLength(FLabelPts, 0);
  PMSpeed.Items[PMSpeed.Tag].Checked:=False;
  PMSpeed.Tag:=6;
  PMSpeed4.Checked:=True;
end;

procedure TMainForm.LoadStarList;
var
  V: TVec4D;
  i, j: Int64;
  L, F: TStringList;
  vm: Double;
  VS, FS: GLuint;
  Src: PAnsiChar;
  Len: GLint;
  VertSrc, FragSrc: AnsiString;
  Stars: array of TVertexData;
  starScale: Single;
const
  z: string = 'Limiting magnitude:';
  PS: array[0..6] of Single = (14.0, 12.0, 10.0, 8.0, 6.0, 4.0, 2.0);
begin
  // PS[] is a magnitude->pixels table, and pixels are a bigger share of a short viewport than a tall one -- the
  // same reason body dots need BodyDotSize. But star sizes are a per-vertex attribute baked into the VBO, so
  // tracking the live viewport would mean re-uploading (or a shader uniform) on every resize, for a window that
  // is maximised by default anyway. So calibrate ONCE, here, against the SCREEN -- i.e. the largest viewport this
  // display can give -- and accept the rest: stars go relatively fatter as the window is shrunk, but they are no
  // longer disproportionately fat on a smaller display, which was the actual complaint.
  // Screen.Height is the primary monitor; on a multi-monitor desktop with mismatched heights the calibration
  // follows the primary rather than whichever screen the window ends up on. Worth knowing, not worth chasing.
  starScale:=Screen.Height/STAR_REF_SCREENH;
  FLM:=6.5;
  L:=TStringList.Create;
  F:=TStringList.Create;
  try
   try
    F.LoadFromFile(FExeDir+BGSTARS_FILENAME);
    for i:=F.Count-1 downto 1 do
     begin
      SplitStr(F[i], ';', L);
      if (L.Count<>3) or not IsNum(L[0]) or not IsNum(L[1]) or not IsNum(L[2]) then F.Delete(i);
     end;
    j:=F[0].IndexOf(z);
    if j>=0 then
     begin
      j:=j+Length(z);
      F[0]:=Copy(F[0], j+1, Length(F[0])-j);
      if IsNum(F[0]) then FLM:=StrToFloat(F[0]);
     end;
    F.Delete(0);
    SetLength(Stars, F.Count);
    for i:=0 to F.Count-1 do
     begin
      SplitStr(F[i], ';', L);
      V:=LoadVec4D(STAR_DIST, TWOPI*StrToFloat(L[0])/24.0, TWOPI*StrToFloat(L[1])/360.0, 1.0).P2V3D*FEpsMatrix;
      Stars[i].X:=V.X;
      Stars[i].Y:=V.Y;
      Stars[i].Z:=V.Z;
      Stars[i].W:=V.W;
      vm:=StrToFloat(L[2]);
      j:=Round(vm); if j<Low(PS) then j:=Low(PS) else if j>High(PS) then j:=High(PS);
      vm:=vm-2.0; if vm<0.0 then vm:=0.0;
      if vm>FLM then vm:=0.25 else vm:=((FLM-vm)/FLM)*0.75+0.25;
      Stars[i].PointSize:=PS[j]*starScale;
      if Stars[i].PointSize<STAR_MIN_PIXELS then Stars[i].PointSize:=STAR_MIN_PIXELS;   // PS[] bottoms out at 2 px, so the faintest bucket would go sub-pixel below ~800 px of screen
      Stars[i].ColorR:=vm;
      Stars[i].ColorG:=vm;
      Stars[i].ColorB:=vm;
     end;

    if not Assigned(GL2.CreateShader) then Exit;

    FStarCount := Length(Stars);
    GL2.GenBuffers(1, @FStarVBO);
    GL2.BindBuffer(GL_ARRAY_BUFFER, FStarVBO);
    GL2.BufferData(GL_ARRAY_BUFFER, NativeUInt(FStarCount) * SizeOf(TVertexData), @Stars[0], GL_STATIC_DRAW);
    GL2.BindBuffer(GL_ARRAY_BUFFER, 0);

    VertSrc :=
      'attribute vec4  aPosition;'  + #10 +
      'attribute float aPointSize;' + #10 +
      'attribute vec3  aColor;'     + #10 +
      'varying vec3 vColor;'        + #10 +
      'void main() {'               + #10 +
      '  gl_Position  = gl_ModelViewProjectionMatrix * aPosition;' + #10 +
      '  gl_PointSize = aPointSize;' + #10 +
      '  vColor = aColor;'          + #10 +
      '}';
    VS := GL2.CreateShader(GL_VERTEX_SHADER);
    Src := PAnsiChar(VertSrc); Len := Length(VertSrc);
    GL2.ShaderSource(VS, 1, @Src, @Len);
    GL2.CompileShader(VS);

    FragSrc :=
      'varying vec3 vColor;'                            + #10 +
      'void main() {'                                   + #10 +
      '  vec2 c = gl_PointCoord - vec2(0.5);'           + #10 +
      '  if (dot(c, c) > 0.25) discard;'                + #10 +
      '  gl_FragColor = vec4(vColor, 1.0);'             + #10 +
      '}';
    FS := GL2.CreateShader(GL_FRAGMENT_SHADER);
    Src := PAnsiChar(FragSrc); Len := Length(FragSrc);
    GL2.ShaderSource(FS, 1, @Src, @Len);
    GL2.CompileShader(FS);

    FStarProgram := GL2.CreateProgram;
    GL2.AttachShader(FStarProgram, VS);
    GL2.AttachShader(FStarProgram, FS);
    GL2.LinkProgram(FStarProgram);
    GL2.DeleteShader(VS);
    GL2.DeleteShader(FS);

    FAttrPosition  := GL2.GetAttribLocation(FStarProgram, 'aPosition');
    FAttrPointSize := GL2.GetAttribLocation(FStarProgram, 'aPointSize');
    FAttrColor     := GL2.GetAttribLocation(FStarProgram, 'aColor');

   except
   end;
  finally
   F.Free;
   L.Free;
   if FStarProgram = 0 then
    begin
     PMDrawStars.Checked:=False;
     PMDrawStars.Enabled:=False;
    end;
  end;
end;

procedure TMainForm.LoadConstList;
var
  i, j: Int64;
  F, L: TStringList;
  Verts: array of TConstVertexData;
  V: TVec4D;
  VS, FS: GLuint;
  Src: PAnsiChar;
  Len: GLint;
  VertSrc, FragSrc: AnsiString;
begin
  F := TStringList.Create;
  L := TStringList.Create;
  try
   try
    F.LoadFromFile(ExeFolder + CONST_FILENAME);
    for i := F.Count-1 downto 0 do
     begin
      SplitStr(F[i], '|', L);
      if (L.Count <> 4) or not IsNum(L[0]) or not IsNum(L[1]) or not IsNum(L[2]) or not IsNum(L[3]) then F.Delete(i);
     end;

    if not Assigned(GL2.CreateShader) or (F.Count = 0) then Exit;

    SetLength(Verts, F.Count shl 1);
    j := 0;
    for i := 0 to F.Count-1 do
     begin
      SplitStr(F[i], '|', L);
      V := LoadVec4D(STAR_DIST, StrToFloat(L[0]), StrToFloat(L[1]), 1.0).P2V3D * FEpsMatrix;
      Verts[j].X := V.X; Verts[j].Y := V.Y; Verts[j].Z := V.Z; j := j + 1;
      V := LoadVec4D(STAR_DIST, StrToFloat(L[2]), StrToFloat(L[3]), 1.0).P2V3D * FEpsMatrix;
      Verts[j].X := V.X; Verts[j].Y := V.Y; Verts[j].Z := V.Z; j := j + 1;
     end;

    FConstCount := Length(Verts);
    GL2.GenBuffers(1, @FConstVBO);
    GL2.BindBuffer(GL_ARRAY_BUFFER, FConstVBO);
    GL2.BufferData(GL_ARRAY_BUFFER, NativeUInt(FConstCount) * SizeOf(TConstVertexData), @Verts[0], GL_STATIC_DRAW);
    GL2.BindBuffer(GL_ARRAY_BUFFER, 0);

    VertSrc :=
      'attribute vec3 aPosition;'                                             + #10 +
      'void main() {'                                                          + #10 +
      '  gl_Position = gl_ModelViewProjectionMatrix * vec4(aPosition, 1.0);' + #10 +
      '}';
    VS := GL2.CreateShader(GL_VERTEX_SHADER);
    Src := PAnsiChar(VertSrc); Len := Length(VertSrc);
    GL2.ShaderSource(VS, 1, @Src, @Len);
    GL2.CompileShader(VS);

    FragSrc :=
      'void main() {'                                  + #10 +
      '  gl_FragColor = vec4(0.5, 0.5, 0.5, 1.0);'   + #10 +
      '}';
    FS := GL2.CreateShader(GL_FRAGMENT_SHADER);
    Src := PAnsiChar(FragSrc); Len := Length(FragSrc);
    GL2.ShaderSource(FS, 1, @Src, @Len);
    GL2.CompileShader(FS);

    FConstProgram := GL2.CreateProgram;
    GL2.AttachShader(FConstProgram, VS);
    GL2.AttachShader(FConstProgram, FS);
    GL2.LinkProgram(FConstProgram);
    GL2.DeleteShader(VS);
    GL2.DeleteShader(FS);

    FConstAttrPosition := GL2.GetAttribLocation(FConstProgram, 'aPosition');

   except
   end;
  finally
   L.Free;
   F.Free;
   if FConstProgram = 0 then
    begin PMDrawConst.Checked := False; PMDrawConst.Enabled := False; end;
  end;
end;

procedure TMainForm.LoadSkyTexture;
const
  GL_BGRA_EXT      = $80E1;
  GL_CLAMP_TO_EDGE = $812F;
  N_LON = 90;
  N_LAT = 36;
var
  Jpeg: TJpegImage;
  Bmp: TBitmap;
  Verts: array of TSkyVertex;
  n, i, j: Integer;
  VS, FS: GLuint;
  Src: PAnsiChar;
  Len: GLint;
  VertSrc, FragSrc: AnsiString;

  procedure AddVert(lat_i, lon_j: Integer);
  var phi, theta, vx, vy, vz: Double; Vt, Vb: TVec4D;
  begin
    phi   := -Pi/2 + Pi * lat_i / N_LAT;
    theta :=  2.0  * Pi * lon_j / N_LON;
    vx := SKY_DIST * Cos(phi) * Cos(theta);
    vy := SKY_DIST * Cos(phi) * Sin(theta);
    vz := SKY_DIST * Sin(phi);
    Vt.X := -vy; Vt.Y := vx; Vt.Z := vz; Vt.W := 0.0;  // R_z90
    Vb := Vt * FEpsMatrix;
    Verts[n].X := Vb.X; Verts[n].Y := Vb.Y; Verts[n].Z := Vb.Z;
    Verts[n].U := Single(lon_j) / N_LON + 0.75;
    Verts[n].V := lat_i / N_LAT;
    Inc(n);
  end;

begin
  FSkyTexture := 0;
  if not FileExists(FExeDir + BGSKY_FILENAME) then Exit;
  Jpeg := TJpegImage.Create;
  Bmp  := TBitmap.Create;
  try
    Jpeg.LoadFromFile(FExeDir + BGSKY_FILENAME);
    Bmp.Assign(Jpeg);
    Bmp.PixelFormat := pf32bit;
    glGenTextures(1, @FSkyTexture);
    glBindTexture(GL_TEXTURE_2D, FSkyTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Bmp.Width, Bmp.Height, 0, GL_BGRA_EXT, GL_UNSIGNED_BYTE, Bmp.ScanLine[Bmp.Height - 1]);
  finally
    Jpeg.Free;
    Bmp.Free;
  end;
  if not Assigned(GL2.CreateShader) then Exit;
  SetLength(Verts, N_LON * N_LAT * 6);
  n := 0;
  for i := 0 to N_LAT-1 do
   for j := 0 to N_LON-1 do
    begin
     AddVert(i,   j);   AddVert(i+1, j);   AddVert(i+1, j+1);
     AddVert(i,   j);   AddVert(i+1, j+1); AddVert(i,   j+1);
    end;
  FSkyVtxCount := n;
  GL2.GenBuffers(1, @FSkyVBO);
  GL2.BindBuffer(GL_ARRAY_BUFFER, FSkyVBO);
  GL2.BufferData(GL_ARRAY_BUFFER, NativeUInt(n) * SizeOf(TSkyVertex), @Verts[0], GL_STATIC_DRAW);
  GL2.BindBuffer(GL_ARRAY_BUFFER, 0);
  VertSrc :=
    'attribute vec3 aPosition;'                                              + #10 +
    'attribute vec2 aTexCoord;'                                              + #10 +
    'varying vec2 vTexCoord;'                                                + #10 +
    'void main() {'                                                          + #10 +
    '  gl_Position = gl_ModelViewProjectionMatrix * vec4(aPosition, 1.0);'  + #10 +
    '  vTexCoord = aTexCoord;'                                               + #10 +
    '}';
  VS := GL2.CreateShader(GL_VERTEX_SHADER);
  Src := PAnsiChar(VertSrc); Len := Length(VertSrc);
  GL2.ShaderSource(VS, 1, @Src, @Len);
  GL2.CompileShader(VS);
  FragSrc :=
    'uniform sampler2D uTex;'                                              + #10 +
    'varying vec2 vTexCoord;'                                              + #10 +
    'void main() {'                                                        + #10 +
    '  gl_FragColor = vec4(texture2D(uTex, vTexCoord).rgb * 0.8, 1.0);'   + #10 +
    '}';
  FS := GL2.CreateShader(GL_FRAGMENT_SHADER);
  Src := PAnsiChar(FragSrc); Len := Length(FragSrc);
  GL2.ShaderSource(FS, 1, @Src, @Len);
  GL2.CompileShader(FS);
  FSkyProgram := GL2.CreateProgram;
  GL2.AttachShader(FSkyProgram, VS);
  GL2.AttachShader(FSkyProgram, FS);
  GL2.LinkProgram(FSkyProgram);
  GL2.DeleteShader(VS);
  GL2.DeleteShader(FS);
  FSkyAttrPos := GL2.GetAttribLocation(FSkyProgram, 'aPosition');
  FSkyAttrUV  := GL2.GetAttribLocation(FSkyProgram, 'aTexCoord');
end;

function TMainForm.LoadFile(const FileName: string): Boolean;
var
  i, j: Int64;
  Item: TMenuItem;
const
  Colors: array[0..11] of TColorRec = (
   (R:1.000; G:1.000; B:1.000; A:1.000),
   (R:0.502; G:0.502; B:0.000; A:1.000),
   (R:1.000; G:1.000; B:0.502; A:1.000),
   (R:0.000; G:0.502; B:1.000; A:1.000),
   (R:0.627; G:0.000; B:0.000; A:1.000),
   (R:1.000; G:0.816; B:0.251; A:1.000),
   (R:1.000; G:0.816; B:0.376; A:1.000),
   (R:0.753; G:1.000; B:1.000; A:1.000),
   (R:0.000; G:0.000; B:1.000; A:1.000),
   (R:0.627; G:0.627; B:0.627; A:1.000),
   (R:1.000; G:1.000; B:1.000; A:1.000),
   (R:0.498; G:0.498; B:0.498; A:1.000));
  Speeds: array[0..11] of Int64 = (4, 0, 0, 2, 0, 1, 1, 1, 0, 2, 4, 0);
begin
  CloseAllDynForms;
  try
   FT:=NINF;
   if not FBSPXFile.Init(FileName) then raise Exception.Create(FBSPXFile.Error);
   if not FBSPXFile.Open then raise Exception.Create(FBSPXFile.Error);
   FStateLock.Acquire;
   try
    SetLength(FSnapshotBuf, FBSPXFile.DescCount);
    if FBSPXFile.DescCount>0 then
     FillChar(FSnapshotBuf[0], FBSPXFile.DescCount*SizeOf(TState4D), 0);
   finally
    FStateLock.Release;
   end;
   SetLength(States, IntForm.ModeBox.Tag);
   for j := 0 to IntForm.ModeBox.Tag-1 do
    begin
     SetLength(States[j], FBSPXFile.DescCount);
     if FBSPXFile.DescCount>0 then FillChar(States[j][0], FBSPXFile.DescCount*SizeOf(TState4D), 0);
    end;
   SetLength(PerturberStates, IntForm.ModeBox.Tag);
   for j := 0 to IntForm.ModeBox.Tag-1 do
    begin
     SetLength(PerturberStates[j], FBSPXFile.DescCount);
     if FBSPXFile.DescCount>0 then FillChar(PerturberStates[j][0], FBSPXFile.DescCount*SizeOf(TState4D), 0);
    end;
   SetLength(FDistUnits, FBSPXFile.DescCount);
   SetLength(FColors, FBSPXFile.DescCount);
   SetLength(FTrails, FBSPXFile.DescCount);
   SetLength(FLabelPts, FBSPXFile.DescCount);
   FillChar(FLabelPts[0], FBSPXFile.DescCount * SizeOf(TVec4D), 0);
   for i := 0 to FBSPXFile.DescCount-1 do
    begin
     SetLength(FTrails[i].Pts, TRAIL_SIZE);
     FTrails[i].Head := 0;
     FTrails[i].Count := 0;
    end;
   FBuildBodyTex := True;   // render thread (re)loads FBodyTextures next frame -- GL calls must run on the context owner

   for i:=0 to FBSPXFile.DescCount-1 do
    begin
     j:=FBSPXFile.Desc[i].TargetID;
     if j<11 then FColors[i]:=Colors[j] else
     if (j > 100) and (j < 1000) and (j mod 100 = 99) then FColors[i]:=Colors[j div 100] else
     FColors[i]:=Colors[11];
    end;

   for i:=0 to FBSPXFile.DescCount-1 do
    begin
     j:=FBSPXFile.Desc[i].TargetID;
     if j<11 then FDistUnits[i]:=1.0/DistUnits[i] else
     if (j > 100) and (j < 1000) and (j mod 100 = 99) then FDistUnits[i]:=1.0/DistUnits[j div 100] else
     FDistUnits[i]:=1.0/DistUnits[11];
    end;

   // PMBarycenter lists ALL barycenters (the user can switch to any system); it is built once
   // here. PMCamCenter, by contrast, is scoped to the current system and is (re)built by
   // RebuildCamCenterMenu — here on load, and again whenever the barycenter changes.
   for i:=0 to FBSPXFile.DescCount-1 do if FBSPXFile.Desc[i].TargetID<10 then
    begin
     Item:=TMenuItem.Create(PMBarycenter);
     Item.Tag:=FBSPXFile.Desc[i].TargetID;
     Item.Caption:=BSPXStr(FBSPXFile.Desc[i].TargetName, SizeOf(FBSPXFile.Desc[i].TargetName));
     Item.OnClick:=PMBarycenterClick;
     PMBarycenter.Add(Item);
    end;
   // "Minor body view": a special item that re-centres the display on the current camera-centre body (an asteroid/dwarf
   // planet with its own descriptor but no barycentre node), at km-scale, to escape the AU-scale float32 jitter. Its
   // sentinel Tag is handled by PMBarycenterClick; UpdateMinorViewEnabled gates when it is offered.
   FMinorViewItem:=TMenuItem.Create(PMBarycenter);
   FMinorViewItem.Tag:=MINOR_VIEW_TAG;
   FMinorViewItem.Caption:='Minor body BC';
   FMinorViewItem.OnClick:=PMBarycenterClick;
   PMBarycenter.Add(FMinorViewItem);
   RebuildCamCenterMenu;
   RebuildRotMenu;   // build the co-rotating-frame axis menu for the initial (SSB) view
   RebuildOrbitCenterMenu;   // build the osculating-orbit-centre menu for the initial (SSB) view
   FBSPXFile.PerturberStateCenterID:=0;
   // Gravity-figure close-encounter terms. GJzonal (m=0) gets EVERY oblate body's zonals (position-only, shared with the
   // DP integrators); GJtesseral (m>=1) additionally gets the bodies with sectoral/tesseral harmonics (Earth, solids --
   // the longitude-aware Pines path, IAS15 only). The two are disjoint in order m, so a body in both never double-counts.
   // Assembled from CelestialMechanics' GOblateness/const tables (seeded DE440, overwritten by FBSPXFile.Open). Also
   // locate the Sun (TargetID 10) for GSunIdx so the nongrav term (CBprec3) is correctly centred when enabled.
   ClearGJzonal;
   ClearGJtesseral;          // tesseral (m>=1) working set: one entry per body carrying sectoral/tesseral harmonics (Earth, solids)
   ClearGAtmosphere;         // drag working set: one entry per body with an atmosphere (AtmRho0>0), assembled below
   SetLength(GNonGrav, 0);   // per-body non-grav: Yarkovsky + drag (array of TNonGrav); AdvanceScene sizes/populates it
   for i := 0 to FBSPXFile.DescCount-1 do
    begin
     if FBSPXFile.Desc[i].TargetID = 10 then GSunIdx := i;
     AddGJzonal(FBSPXFile.Desc[i].TargetID, i);   // zonal (m=0) for every oblate body; entry added iff it has a figure in GOblateness
     with FBSPXFile.BodyConst[i]^ do
      begin
       // A body with sectoral/tesseral terms ALSO gets a GJtesseral entry (its m>=1 Pines part); its zonal m=0 stays in
       // GJzonal above, so no double-count. Gas giants (zonal-only Chi) get no tesseral entry.
       if (GravDeg >= 2) and GravIsTesseral(Chi, Round(GravDeg)) then
        AddGJtesseral(i, Round(GravDeg), GravRefR, PoleRA, PoleRARate, PoleDec, PoleDecRate, PoleW, PoleWRate, Chi);
       AddGAtmosphere(i, Req, AtmRho0, AtmAlt0, AtmScaleH, PoleRA, PoleDec, PoleWRate);   // drag entry iff atmosphere (params km-converted inside)
      end;
    end;
   SetLength(FSpeeds, PMBarycenter.Count);
   for i:=0 to PMBarycenter.Count-1 do
    if PMBarycenter.Items[i].Tag = MINOR_VIEW_TAG then FSpeeds[i]:=1   // minor-body item: PMSpeed item 1 = 1 min/sec (SSB's 12 h/sec spins these small, fast bodies far too fast); its Tag is not a Speeds index
    else FSpeeds[i]:=Speeds[PMBarycenter.Items[i].Tag];
   VecForm.Init;
   LoadLabelTextures;
   // Hand the GL context to the render thread
   wglMakeCurrent(FDC, 0);
   FRunning := True;
   //SetFPSLimit(240.0);
   FRenderThread := TRenderThread.Create(Self);
   Result:=True;
  except on E: Exception do begin
   wglMakeCurrent(FDC, FRC);  // reclaim RC if thread was never started
   ResetVars;
//   MessageDlg(E.Message, mtError, [mbOK], 0);
   Result:=False;
  end; end;
end;

procedure TMainForm.InitOpenGL;
begin
  FWhiteMaterial[0]:=1.0; FWhiteMaterial[1]:=1.0; FWhiteMaterial[2]:=1.0; FWhiteMaterial[3]:=0.0;
  FGrayMaterial[0]:=0.5; FGrayMaterial[1]:=0.5; FGrayMaterial[2]:=0.5; FGrayMaterial[3]:=0.0;
  // Grab the direct Win32 device handle from the underlying TPanel control surface
  FDC := GetDC(glPanel.Handle);
  if FDC = 0 then raise Exception.Create('Unable to fetch Panel Device Context handle.');
  SetupPixelFormat;

  // Initialize the native standard context loop
  FRC := wglCreateContext(FDC);
  if FRC = 0 then raise Exception.Create('Failed to instantiate an OpenGL rendering environment.');

  if not wglMakeCurrent(FDC, FRC) then raise Exception.Create('Failed to pass thread ownership over to the OpenGL context.');

  LoadGL2Procs;

  // Set the standard baseline states
  glEnable(GL_DEPTH_TEST);
  glClearColor(0.0, 0.0, 0.0, 1.0);
  if FSphereQuad = nil then
   begin
    FSphereQuad := gluNewQuadric;
    gluQuadricNormals(FSphereQuad, GLU_SMOOTH);     // normals needed for optional per-sphere lighting (PMLighting)
    gluQuadricTexture(FSphereQuad, GL_TRUE);
   end;
  if FCoronaTexture = 0 then BuildCoronaTexture;
  FormResize(Self);
end;

procedure TMainForm.SetupPixelFormat;
var
  pfd: TPixelFormatDescriptor;
  PixelFormat: Integer;
begin
  FillChar(pfd, SizeOf(pfd), 0);
  pfd.nSize      := SizeOf(pfd);
  pfd.nVersion   := 1;
  pfd.dwFlags    := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
  pfd.iPixelType := PFD_TYPE_RGBA;
  pfd.cColorBits := 32;
  pfd.cDepthBits := 24; // Standard depth tracking layer for 3D
  pfd.iLayerType := PFD_MAIN_PLANE;

  PixelFormat := ChoosePixelFormat(FDC, @pfd);
  if PixelFormat = 0 then
    raise Exception.Create('Failed to choose a suitable hardware pixel format.');

  if not SetPixelFormat(FDC, PixelFormat, @pfd) then
    raise Exception.Create('Failed to bind pixel format to panel device context.');
end;

procedure TMainForm.DrawAxes;
// Drawn as plain literals (no FCoRotMatrix): in a co-rotating frame the fixed screen axes ARE the frame
// axes -- +X is the Centre->Target line the bodies are pinned to, +Z the orbital pole -- so leaving them
// un-transformed shows the co-rotating frame. With the frame Off they show the inertial/ICRF axes as before.
begin
  glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, @FWhiteMaterial);
  glBegin(GL_LINES);
//--------------
  glColor3f(0.0, 0.0, 0.0); glVertex3f(-5.00,  0.00,  0.00);
  glColor3f(0.5, 0.0, 0.0); glVertex3f(-0.01,  0.00,  0.00);
                            glVertex3f( 0.01,  0.00,  0.00);
  glColor3f(1.0, 0.0, 0.0); glVertex3f( 5.00,  0.00,  0.00);
//--------------
  glColor3f(0.0, 0.0, 0.0); glVertex3f( 0.00, -5.00,  0.00);
  glColor3f(0.0, 0.5, 0.0); glVertex3f( 0.00, -0.01,  0.00);
                            glVertex3f( 0.00,  0.01,  0.00);
  glColor3f(0.0, 1.0, 0.0); glVertex3f( 0.00,  5.00,  0.00);
//--------------
  glColor3f(0.0, 0.0, 0.0); glVertex3f( 0.00,  0.00, -5.00);
  glColor3f(0.0, 0.0, 0.5); glVertex3f( 0.00,  0.00, -0.01);
                            glVertex3f( 0.00,  0.00,  0.01);
  glColor3f(0.0, 0.0, 1.0); glVertex3f( 0.00,  0.00,  5.00);
//--------------
  glEnd;
end;

procedure TMainForm.DrawSky;
var
  Stride: GLsizei;
begin
  if (FSkyProgram = 0) or (FSkyVBO = 0) then Exit;
  Stride := SizeOf(TSkyVertex);
  GL2.UseProgram(FSkyProgram);
  glBindTexture(GL_TEXTURE_2D, FSkyTexture);
  GL2.BindBuffer(GL_ARRAY_BUFFER, FSkyVBO);
  if FSkyAttrPos >= 0 then
   begin
    GL2.VertexAttribPointer(FSkyAttrPos, 3, GL_FLOAT, GL_FALSE, Stride, nil);
    GL2.EnableVertexAttribArray(FSkyAttrPos);
   end;
  if FSkyAttrUV >= 0 then
   begin
    GL2.VertexAttribPointer(FSkyAttrUV, 2, GL_FLOAT, GL_FALSE, Stride, Pointer(12));
    GL2.EnableVertexAttribArray(FSkyAttrUV);
   end;
  glDrawArrays(GL_TRIANGLES, 0, FSkyVtxCount);
  if FSkyAttrUV  >= 0 then GL2.DisableVertexAttribArray(FSkyAttrUV);
  if FSkyAttrPos >= 0 then GL2.DisableVertexAttribArray(FSkyAttrPos);
  GL2.BindBuffer(GL_ARRAY_BUFFER, 0);
  GL2.UseProgram(0);
  glBindTexture(GL_TEXTURE_2D, 0);
end;

procedure TMainForm.DrawStars;
var
  Stride: GLsizei;
begin
  if (FStarProgram = 0) or (FStarVBO = 0) then Exit;
  Stride := SizeOf(TVertexData);
  glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
  glEnable(GL_POINT_SPRITE);
  GL2.UseProgram(FStarProgram);
  GL2.BindBuffer(GL_ARRAY_BUFFER, FStarVBO);
  if FAttrPosition >= 0 then
   begin
    GL2.VertexAttribPointer(FAttrPosition, 4, GL_FLOAT, GL_FALSE, Stride, nil);
    GL2.EnableVertexAttribArray(FAttrPosition);
   end;
  if FAttrPointSize >= 0 then
   begin
    GL2.VertexAttribPointer(FAttrPointSize, 1, GL_FLOAT, GL_FALSE, Stride, Pointer(16));
    GL2.EnableVertexAttribArray(FAttrPointSize);
   end;
  if FAttrColor >= 0 then
   begin
    GL2.VertexAttribPointer(FAttrColor, 3, GL_FLOAT, GL_FALSE, Stride, Pointer(20));
    GL2.EnableVertexAttribArray(FAttrColor);
   end;
  glDrawArrays(GL_POINTS, 0, FStarCount);
  if FAttrColor >= 0 then GL2.DisableVertexAttribArray(FAttrColor);
  if FAttrPointSize >= 0 then GL2.DisableVertexAttribArray(FAttrPointSize);
  if FAttrPosition >= 0 then GL2.DisableVertexAttribArray(FAttrPosition);
  GL2.BindBuffer(GL_ARRAY_BUFFER, 0);
  GL2.UseProgram(0);
  glDisable(GL_POINT_SPRITE);
  glDisable(GL_VERTEX_PROGRAM_POINT_SIZE);
end;

procedure TMainForm.DrawConst;
begin
  if (FConstProgram = 0) or (FConstVBO = 0) then Exit;
  GL2.UseProgram(FConstProgram);
  GL2.BindBuffer(GL_ARRAY_BUFFER, FConstVBO);
  if FConstAttrPosition >= 0 then
   begin
    GL2.VertexAttribPointer(FConstAttrPosition, 3, GL_FLOAT, GL_FALSE, SizeOf(TConstVertexData), nil);
    GL2.EnableVertexAttribArray(FConstAttrPosition);
   end;
  glDrawArrays(GL_LINES, 0, FConstCount);
  if FConstAttrPosition >= 0 then GL2.DisableVertexAttribArray(FConstAttrPosition);
  GL2.BindBuffer(GL_ARRAY_BUFFER, 0);
  GL2.UseProgram(0);
end;

procedure TMainForm.DrawLabels;
var
  i, nInt: Int64;
  winX, winY, winZ: GLdouble;
  sx, sy, sw, sh: Integer;
  LabelModelView, LabelProj: array[0..15] of GLdouble;
  LabelViewport: array[0..3] of GLint;
begin
  if Length(FLabelPts) = 0 then Exit;
  nInt := Length(IntForm.IntegrationS);
  glGetDoublev(GL_MODELVIEW_MATRIX,  @LabelModelView[0]);
  glGetDoublev(GL_PROJECTION_MATRIX, @LabelProj[0]);
  glGetIntegerv(GL_VIEWPORT,         @LabelViewport[0]);
  glMatrixMode(GL_PROJECTION);
  glPushMatrix;
  glLoadIdentity;
  glOrtho(0, FViewW, 0, FViewH, -1, 1);
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  glLoadIdentity;
  glDisable(GL_DEPTH_TEST);
  glEnable(GL_TEXTURE_2D);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  for i:=0 to Length(FLabelPts)-1 do
   if (i < FBSPXFile.DescCount + nInt) and (i < Length(FLabelTextures)) and (FLabelTextures[i]<>0) then
    begin
     // Skip non-finite points. A NaN slips past IsInfinite AND the winZ test below (every NaN
     // comparison is False), reaching Round(NaN)->Int64 min, whose narrowing to the Integer
     // sx/sy raises ERangeError. Root cause is fixed in InvCubeScale3D; this is belt-and-braces.
     if IsNan(FLabelPts[i].X) or IsInfinite(FLabelPts[i].X) then Continue;
     if gluProject(FLabelPts[i].X, FLabelPts[i].Y, FLabelPts[i].Z,
                   @LabelModelView[0], @LabelProj[0], @LabelViewport[0],
                   winX, winY, winZ) = 0 then Continue;
     if (winZ < 0.0) or (winZ > 1.0) then Continue;
     sx:=Round(winX)+8; sy:=Round(winY);
     sw:=FLabelWidths[i]; sh:=FLabelHeights[i];
     if i < Length(FColors) then glColor3fv(@FColors[i])
     else glColor3f(1.0, 1.0, 1.0);
     glBindTexture(GL_TEXTURE_2D, FLabelTextures[i]);
     glBegin(GL_QUADS);
      glTexCoord2f(0,0); glVertex2i(sx,    sy+sh);
      glTexCoord2f(1,0); glVertex2i(sx+sw, sy+sh);
      glTexCoord2f(1,1); glVertex2i(sx+sw, sy);
      glTexCoord2f(0,1); glVertex2i(sx,    sy);
     glEnd;
    end;
  glDisable(GL_BLEND);
  glDisable(GL_TEXTURE_2D);
  glEnable(GL_DEPTH_TEST);
  glBindTexture(GL_TEXTURE_2D, 0);
  glMatrixMode(GL_PROJECTION);
  glPopMatrix;
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix;
end;

procedure TMainForm.BuildBodyTextures;
// Render-thread only (owns the GL context). (Re)loads a surface texture for every BSPX body with a positive
// Req and a TEXTURE_FOLDER\<TargetID>.jpg beside the exe. Any previously loaded textures are deleted first,
// so this is safe to call again after switching ephemeris files.
var
  i: Int64;
  fn: string;
  Jpeg: TJpegImage;
  Bmp: TBitmap;
  tex: GLuint;
begin
  FBuildBodyTex := False;
  for i := 0 to High(FBodyTextures) do
   if FBodyTextures[i] <> 0 then begin glDeleteTextures(1, @FBodyTextures[i]); FBodyTextures[i] := 0; end;
  for i := 0 to High(FRingTextures) do
   if FRingTextures[i] <> 0 then begin glDeleteTextures(1, @FRingTextures[i]); FRingTextures[i] := 0; end;
  SetLength(FBodyTextures, FBSPXFile.DescCount);
  SetLength(FRingTextures, FBSPXFile.DescCount);
  for i := 0 to FBSPXFile.DescCount-1 do
   begin
    FBodyTextures[i] := 0;
    FRingTextures[i] := 0;
    if FBSPXFile.BodyConst[i].Req <= 0.0 then Continue;
    // surface texture (JPG)
    fn := FExeDir + TEXTURE_FOLDER + IntToStr(FBSPXFile.Desc[i].TargetID) + '.jpg';
    if FileExists(fn) then
     begin
      Jpeg := TJpegImage.Create;
      Bmp  := TBitmap.Create;
      try
        try
          Jpeg.LoadFromFile(fn);
          Bmp.Assign(Jpeg);
          Bmp.PixelFormat := pf32bit;
          glGenTextures(1, @tex);
          glBindTexture(GL_TEXTURE_2D, tex);
          glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
          glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
          glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
          glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
          glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Bmp.Width, Bmp.Height, 0, GL_BGRA_EXT, GL_UNSIGNED_BYTE, Bmp.ScanLine[Bmp.Height-1]);
          FBodyTextures[i] := tex;
        except
          FBodyTextures[i] := 0;   // unreadable image -> this body just stays a dot
        end;
      finally
        Jpeg.Free;
        Bmp.Free;
      end;
     end;
    // ring texture (PNG with alpha), e.g. 699_rings.png for Saturn -- 0 if none
    FRingTextures[i] := LoadPNGTexture(FExeDir + TEXTURE_FOLDER + IntToStr(FBSPXFile.Desc[i].TargetID) + '_rings.png');
   end;
  glBindTexture(GL_TEXTURE_2D, 0);
end;

function TMainForm.LoadPNGTexture(const fn: string): GLuint;
// Load a PNG (with its alpha channel) into a GL_RGBA texture; returns 0 if the file is missing/unreadable.
// TPngImage keeps RGB in a 24-bit DIB scanline (BGR order) and alpha in a separate AlphaScanline, so build a
// BGRA buffer and upload it as GL_BGRA_EXT (matching the JPG path). Runs where the GL context is current.
var
  png: TPngImage;
  buf: TBytes;
  x, y, o, w, h: Integer;
  line, aline: PByteArray;
begin
  Result := 0;
  if not FileExists(fn) then Exit;
  png := TPngImage.Create;
  try
    try
      png.LoadFromFile(fn);
      w := png.Width; h := png.Height;
      if (w <= 0) or (h <= 0) then Exit;
      SetLength(buf, w*h*4);
      for y := 0 to h-1 do
       begin
        line := PByteArray(png.Scanline[y]);
        if png.Header.ColorType in [COLOR_RGBALPHA, COLOR_GRAYSCALEALPHA] then aline := PByteArray(png.AlphaScanline[y]) else aline := nil;
        for x := 0 to w-1 do
         begin
          o := (y*w + x)*4;
          buf[o+0] := line[x*3+0];   // B
          buf[o+1] := line[x*3+1];   // G
          buf[o+2] := line[x*3+2];   // R
          if aline <> nil then buf[o+3] := aline[x] else buf[o+3] := 255;
         end;
       end;
      glGenTextures(1, @Result);
      glBindTexture(GL_TEXTURE_2D, Result);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_BGRA_EXT, GL_UNSIGNED_BYTE, @buf[0]);
      glBindTexture(GL_TEXTURE_2D, 0);
    except
      if Result <> 0 then begin glDeleteTextures(1, @Result); Result := 0; end;
    end;
  finally
    png.Free;
  end;
end;

procedure TMainForm.DrawRing(const Center, AxisX, AxisY: TVec4D; innerR, outerR, planetR: Double; texID: GLuint);
// Textured annulus in the planet's equatorial plane (spanned by AxisX/AxisY, i.e. perpendicular to the pole),
// centred at Center (display AU). U maps radially inner(0)->outer(1); the strip is radially symmetric so V is
// fixed. Alpha-blended (transparent gaps show through), depth-TESTED so the planet occludes the far half, but
// no depth write. Two-sided (no face cull). When lit (FLightingOn) the planet's shadow is cast on the ring:
// a ring point is shadowed if it is behind the planet from the Sun (t<0) AND within planetR of the shadow
// axis -- a per-vertex darkening (SinCos the parallel-ray cylinder), interpolated across the RING_SEGS.
const
  RING_SEGS   = 128;    // angular subdivisions
  RING_RADIAL = 16;     // radial subdivisions -- WITHOUT these the shadow edge is forced radial (looks like it
                        // radiates from the planet centre); with them the per-vertex shade follows the true edge
  RING_SHADOW = 0.12;   // brightness inside the planet's shadow (some ambient, not pure black)
  RING_PENUMBRA = 0.22; // soft-edge half-width as a fraction of planetR -- ramps the shade across the umbra edge
                        // so the boundary is a smooth gradient (no jagged/flickering per-vertex threshold),
                        // which is also physically right: the Sun is not a point source.
var
  k, jr: Int64;
  ang, ca, sa, dx, dy, dz, r0, r1, u0, u1, Lx, Ly, Lz, Lm, pen, inR: Double;
  s: Single;
  shadowOn: Boolean;

  function ShadeAt(rx, ry, rz: Double): Single;   // rel = point - Center; 1 = lit, RING_SHADOW = in shadow
  var t, pd, e: Double;
  begin
    Result := 1.0;
    if not shadowOn then Exit;
    t := rx*Lx + ry*Ly + rz*Lz;              // projection onto the planet->Sun axis
    if t >= 0.0 then Exit;                    // on the Sun side of the planet -> lit
    pd := Sqrt(Sqr(rx - t*Lx) + Sqr(ry - t*Ly) + Sqr(rz - t*Lz));   // perpendicular distance from the shadow axis
    e := (pd - inR) / (2.0*pen);             // 0 at the inner (umbra) edge, 1 at the outer (fully-lit) edge
    if e <= 0.0 then Result := RING_SHADOW
    else if e >= 1.0 then Result := 1.0
    else Result := RING_SHADOW + (1.0-RING_SHADOW) * (e*e*(3.0-2.0*e));   // smoothstep across the penumbra
  end;

begin
  shadowOn := FLightingOn;
  if shadowOn then
   begin
    Lx := FSunPos.X - Center.X; Ly := FSunPos.Y - Center.Y; Lz := FSunPos.Z - Center.Z;   // planet -> Sun
    Lm := Sqrt(Lx*Lx + Ly*Ly + Lz*Lz);
    if Lm > 0.0 then begin Lx := Lx/Lm; Ly := Ly/Lm; Lz := Lz/Lm; end else shadowOn := False;
   end;
  pen := RING_PENUMBRA * planetR;            // penumbra half-width (display AU); umbra edge = planetR - pen
  inR := planetR - pen;
  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, texID);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glDepthMask(GL_FALSE);
  for jr := 0 to RING_RADIAL-1 do   // concentric bands; U maps radially inner(0)->outer(1)
   begin
    r0 := innerR + (outerR-innerR)*jr/RING_RADIAL;       u0 := jr/RING_RADIAL;
    r1 := innerR + (outerR-innerR)*(jr+1)/RING_RADIAL;   u1 := (jr+1)/RING_RADIAL;
    glBegin(GL_TRIANGLE_STRIP);
     for k := 0 to RING_SEGS do
      begin
       ang := 2.0*Pi*k/RING_SEGS;
       SinCos(ang, sa, ca);
       dx := ca*AxisX.X + sa*AxisY.X;   // unit radial direction in the equatorial plane
       dy := ca*AxisX.Y + sa*AxisY.Y;
       dz := ca*AxisX.Z + sa*AxisY.Z;
       s := ShadeAt(dx*r0, dy*r0, dz*r0); glColor4f(s, s, s, 1.0);
       glTexCoord2f(u0, 0.5); glVertex3d(Center.X + dx*r0, Center.Y + dy*r0, Center.Z + dz*r0);
       s := ShadeAt(dx*r1, dy*r1, dz*r1); glColor4f(s, s, s, 1.0);
       glTexCoord2f(u1, 0.5); glVertex3d(Center.X + dx*r1, Center.Y + dy*r1, Center.Z + dz*r1);
      end;
    glEnd;
   end;
  glDepthMask(GL_TRUE);
  glDisable(GL_BLEND);
  glBindTexture(GL_TEXTURE_2D, 0);
  glDisable(GL_TEXTURE_2D);
  glColor4f(1.0, 1.0, 1.0, 1.0);
end;

function TMainForm.BodyDotSize: Single;
// A dot is a fixed number of PIXELS, so it covers a bigger share of a short viewport than of a tall one: the
// 10 px judged on a 2560x1600 screen looks fat on FHD and would look mean on 4K. Scaling with the viewport
// height keeps the dot the same fraction of the image, so the picture merely scales between screens (and as the
// window is resized). FViewH is exactly what glViewport is given, so this is real pixels on a high-DPI display
// too. No upper clamp on purpose -- growing with the viewport IS the point; the driver's own GL_POINT_SIZE_RANGE
// is the only ceiling that should apply.
begin
  Result := DOT_PIXELS * FViewH / DOT_REF_VIEWH;
  if Result < DOT_MIN_PIXELS then Result := DOT_MIN_PIXELS;
end;

function TMainForm.DrawBodySphere(i: Int64; const Pt: TVec4D): Boolean;
// If body i qualifies -- PMBodies on, has a radius (Req>0), and is big enough on screen -- draw it as a sphere
// oriented to its spin axis and return True; else return False so the caller draws a dot. A body with a loaded
// texture is textured; one without is drawn as a flat grey sphere, which the lighting still shades into a 3D
// form -- so every body with a size shows up, not just the textured ones. Centred at Pt (display-frame AU, the
// would-be dot). Shape is a triaxial ellipsoid where the body has Rb/Rc radii (squashed along its own b and pole
// axes), else a plain sphere; the axis is the IAU pole (RA/Dec, plus W/rates if present) at epoch FT, carried
// into the display frame like every vertex.
var
  pc: PBSPXBodyConst;
  rAU, dEye, projPx, dDay, T, raR, decR, cw, sw: Double;
  NP, Nd, Zd, Xd, Yd, Tn: TVec4D;
  M: array[0..15] of GLdouble;
  lit, hasTex, triax: Boolean;
begin
  Result := False;
  if not PMBodies.Checked then Exit;
  if (i < 0) or (i >= FBSPXFile.DescCount) then Exit;   // BSPX bodies only, never integrands
  pc  := FBSPXFile.BodyConst[i];
  if pc.Req <= 0.0 then Exit;   // no radius -> caller draws a dot (asteroids/KBOs: GM-only, no shape)
  hasTex := (i < Length(FBodyTextures)) and (FBodyTextures[i] <> 0);
  rAU := pc.Req * KM2AU;
  dEye := Sqrt(Sqr(FEyePos.X - Pt.X) + Sqr(FEyePos.Y - Pt.Y) + Sqr(FEyePos.Z - Pt.Z));   // true eye->body distance (AU)
  if dEye <= 0.0 then Exit;
  projPx := rAU / dEye * FViewH * 1.207;   // ~projected radius in px (perspective, 45 deg vFOV: 1/(2 tan 22.5) ~ 1.207)
  if projPx < SPHERE_MIN_PIXELS then Exit;   // sub-dot on screen -> keep the dot (fixes far-body vanishing)
  // Spin axis (+Z) and prime-meridian node (+X at W=0) in ICRF at FT, then rotated into the display frame.
  dDay := FT * SEC2DAY;         // FT is TDB seconds past J2000 (see BSPXTimeStr); PCK pole/PM are referenced to J2000
  T    := dDay * DAY2CENTURY;   // Julian centuries past J2000 (POLE_RA/DEC rates are deg/century)
  raR  := DegToRad(pc.PoleRA  + pc.PoleRARate  * T);
  decR := DegToRad(pc.PoleDec + pc.PoleDecRate * T);
  NP.X := Cos(decR)*Cos(raR); NP.Y := Cos(decR)*Sin(raR); NP.Z := Sin(decR); NP.W := 0.0;
  Nd.X := -Sin(raR);          Nd.Y := Cos(raR);           Nd.Z := 0.0;       Nd.W := 0.0;   // node of body equator on the ICRF equator
  Zd := NP * FEpsMatrix * FCoRotMatrix;
  Tn := Nd * FEpsMatrix * FCoRotMatrix;
  SinCos(DegToRad(pc.PoleW + pc.PoleWRate * dDay + SPHERE_LON0), sw, cw);   // W: PM rate deg/DAY; +SPHERE_LON0 aligns the gluSphere seam
  Xd.X := Tn.X*cw + (Zd.Y*Tn.Z - Zd.Z*Tn.Y)*sw;           // Rodrigues about Zd (Tn _|_ Zd -> no parallel term)
  Xd.Y := Tn.Y*cw + (Zd.Z*Tn.X - Zd.X*Tn.Z)*sw;
  Xd.Z := Tn.Z*cw + (Zd.X*Tn.Y - Zd.Y*Tn.X)*sw;
  Yd.X := Zd.Y*Xd.Z - Zd.Z*Xd.Y; Yd.Y := Zd.Z*Xd.X - Zd.X*Xd.Z; Yd.Z := Zd.X*Xd.Y - Zd.Y*Xd.X;   // Y = Z x X
  M[0]:=Xd.X; M[1]:=Xd.Y; M[2]:=Xd.Z; M[3]:=0.0;    // local->display: columns are the body's X,Y,Z axes...
  M[4]:=Yd.X; M[5]:=Yd.Y; M[6]:=Yd.Z; M[7]:=0.0;
  M[8]:=Zd.X; M[9]:=Zd.Y; M[10]:=Zd.Z; M[11]:=0.0;
  M[12]:=Pt.X; M[13]:=Pt.Y; M[14]:=Pt.Z; M[15]:=1.0;  // ...translation = the display-frame body position
  lit := FLightingOn and (i <> GSunIdx);   // the Sun is the light source -> self-luminous, never shaded
  if hasTex then
   begin
    glColor3f(1.0, 1.0, 1.0);   // white material (GL_COLOR_MATERIAL) when lit; plain white modulation when not
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, FBodyTextures[i]);
   end
  else
   glColor3f(0.6, 0.6, 0.6);   // no texture: flat neutral grey; GL_LIGHTING gives it the 3D form
  if lit then glEnable(GL_LIGHTING);   // light ONLY the spheres (except the Sun); dots/orbits/sky stay unlit
  triax := (pc.Rb > 0.0) and (pc.Rc > 0.0);   // triaxial radii present -> render an ellipsoid, else a plain sphere (Req>0 guaranteed above)
  glPushMatrix;
  glMultMatrixd(@M[0]);
  if triax then
   begin
    glEnable(GL_NORMALIZE);   // gluSphere emits unit normals for a sphere; a non-uniform scale needs them renormalised or lighting is wrong
    glScaled(1.0, pc.Rb/pc.Req, pc.Rc/pc.Req);   // squash local Y,Z to b,c (X=Req=a); M already orients these axes to the body's frame
   end;
  gluSphere(FSphereQuad, rAU, SPHERE_SLICES, SPHERE_STACKS);
  glPopMatrix;
  if triax then glDisable(GL_NORMALIZE);
  if lit then glDisable(GL_LIGHTING);
  if hasTex then
   begin
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisable(GL_TEXTURE_2D);
   end;
  // Rings (if this planet has one): a textured annulus in the equatorial plane (Xd/Yd = axes perpendicular to
  // the pole Zd), sized RING_INNER_MUL..RING_OUTER_MUL * the planet radius. Drawn after the sphere so the disk
  // occludes the far half.
  if (i <= High(FRingTextures)) and (FRingTextures[i] <> 0) then
   DrawRing(Pt, Xd, Yd, RING_INNER_MUL*rAU, RING_OUTER_MUL*rAU, rAU, FRingTextures[i]);
  Result := True;
end;

procedure TMainForm.BuildCoronaTexture;
// Procedural radial Sun-glow (tight bright core + soft halo, smoothly faded to 0 at the rim), so no external
// texture file is needed. Grey RGBA ramp; DrawCorona tints it warm under additive blending. Runs where the GL
// context is current (from InitOpenGL).
const
  SIZE = 128;
var
  buf: array of Byte;
  x, y, o: Integer;
  dx, dy, r2, inten: Double;
  b: Byte;
begin
  SetLength(buf, SIZE*SIZE*4);
  for y := 0 to SIZE-1 do
   for x := 0 to SIZE-1 do
    begin
     dx := (x + 0.5)/SIZE*2.0 - 1.0;
     dy := (y + 0.5)/SIZE*2.0 - 1.0;
     r2 := dx*dx + dy*dy;
     if r2 >= 1.0 then inten := 0.0
     else inten := (0.55*Exp(-r2*22.0) + 0.45*Exp(-r2*3.0)) * (1.0 - r2);   // core + halo, smooth to 0 at r=1
     b := Round(inten*255.0);
     o := (y*SIZE + x)*4;
     buf[o]:=b; buf[o+1]:=b; buf[o+2]:=b; buf[o+3]:=b;
    end;
  glGenTextures(1, @FCoronaTexture);
  glBindTexture(GL_TEXTURE_2D, FCoronaTexture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, SIZE, SIZE, 0, GL_RGBA, GL_UNSIGNED_BYTE, @buf[0]);
  glBindTexture(GL_TEXTURE_2D, 0);
end;

procedure TMainForm.DrawCorona(const RotM: array of GLdouble);
// Additive, camera-facing glow billboard (quad) at the Sun, textured with the procedural radial glow. Depth-
// TESTED (bodies in front occlude it) but writes no depth; the Sun sphere's near cap hides the centre, leaving
// a halo around the disk. Sized a few Sun radii in AU so it scales with zoom (sub-pixel/invisible when far).
// Independent of lighting/PMBodies. Tunables: CORONA_SCALE (extent) + the warm glColor tint below.
const
  CORONA_SCALE = 40.0;   // billboard half-size = CORONA_SCALE * Sun Req (the texture's own falloff softens it)
var
  sunD: TVec4D;
  rad, cx, cy, cz, rx, ry, rz, ux, uy, uz: Double;
begin
  if (FCoronaTexture = 0) or (GSunIdx < 0) or (GSunIdx >= FBSPXFile.DescCount) or (GSunIdx > High(PerturberStates[0])) then Exit;
  if FBSPXFile.Desc[GSunIdx].TargetID <> 10 then Exit;
  rad := FBSPXFile.BodyConst[GSunIdx].Req * KM2AU * CORONA_SCALE;
  if rad <= 0.0 then Exit;
  // Sun position in the co-rotated, FRotCenter-re-centred display frame (AU) -- same frame as every drawn body.
  if (FBaryDescIdx >= 0) and (Length(States[0]) > FBaryDescIdx) then
   sunD := DispPos(PerturberStates[0][GSunIdx].R - States[0][FBaryDescIdx].R)
  else
   sunD := DispPos(PerturberStates[0][GSunIdx].R);
  cx := sunD.X*KM2AU; cy := sunD.Y*KM2AU; cz := sunD.Z*KM2AU;
  rx := RotM[0]*rad; ry := RotM[4]*rad; rz := RotM[8]*rad;   // camera right * half-size (display coords)
  ux := RotM[1]*rad; uy := RotM[5]*rad; uz := RotM[9]*rad;   // camera up   * half-size
  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, FCoronaTexture);
  glEnable(GL_BLEND);
  glBlendFunc(GL_ONE, GL_ONE);   // additive
  glDepthMask(GL_FALSE);         // test but don't write -> foreground bodies still occlude it
  glColor3f(1.0, 0.90, 0.62);    // warm tint (additive), modulated by the glow texture
  glBegin(GL_QUADS);
   glTexCoord2f(0.0, 0.0); glVertex3d(cx-rx-ux, cy-ry-uy, cz-rz-uz);
   glTexCoord2f(1.0, 0.0); glVertex3d(cx+rx-ux, cy+ry-uy, cz+rz-uz);
   glTexCoord2f(1.0, 1.0); glVertex3d(cx+rx+ux, cy+ry+uy, cz+rz+uz);
   glTexCoord2f(0.0, 1.0); glVertex3d(cx-rx+ux, cy-ry+uy, cz-rz+uz);
  glEnd;
  glDepthMask(GL_TRUE);
  glDisable(GL_BLEND);
  glBindTexture(GL_TEXTURE_2D, 0);
  glDisable(GL_TEXTURE_2D);
  glColor3f(1.0, 1.0, 1.0);   // restore the default vertex colour for later passes
end;

procedure TMainForm.DrawOrbits(Integrands: Boolean);
var
  S, SO, oS: TState4D;   // S = dot state (FBarycenter-relative); SO = conic state (FOrbitCenter-relative); oS = temp
  i, j, idx, lo, hi: Int64;
  n, v, dv, sina, cosa, sind, cosd: Double;
  P, R, Pt: TVec4D;
  FBaryR, FBaryV, FOrbitR, FOrbitV, GravOfs: TVec4D;
  M: TMat4D;
  DrawDot, DrawOrbit, OrbitBodies: Boolean;
  nBSPX, nInt, nTotal, CentralBody: Int64;
  OrbitCenterGM: Double;   // GM of FOrbitCenter, hoisted out of the body loop (loop-invariant)
begin
  nBSPX  := FBSPXFile.DescCount;
  nInt := Length(IntForm.IntegrationS);
  nTotal := nBSPX + nInt;
  // SSB-relative storage: re-centre siblings + integrands to FBarycenter for display (see DrawDots).
  // FBaryV (barycenter SSB velocity) also re-centres integrand velocity for the osculating orbit below.
  if (FBaryDescIdx >= 0) and (Length(States[0]) > FBaryDescIdx) then
   begin FBaryR := States[0][FBaryDescIdx].R; FBaryV := States[0][FBaryDescIdx].V; end
  else
   begin FillChar(FBaryR, SizeOf(FBaryR), 0); FillChar(FBaryV, SizeOf(FBaryV), 0); end;
  // Osculating orbits focus on FOrbitCenter (default = FBarycenter). Its SSB state gives the conic's relative
  // state; GravOfs is where that focus sits in the FBarycenter-centred display (0 when FOrbitCenter=FBarycenter,
  // so the default path is unchanged). Dots stay FBarycenter-relative below.
  if AxisEndpointSSB(FOrbitCenter, oS) then begin FOrbitR := oS.R; FOrbitV := oS.V; end
  else begin FOrbitR := FBaryR; FOrbitV := FBaryV; end;
  R := DispPos(FOrbitR - FBaryR);   // conic focus in the re-centred display frame (so orbits sit with their dots)
  GravOfs.X := R.X*KM2AU; GravOfs.Y := R.Y*KM2AU; GravOfs.Z := R.Z*KM2AU; GravOfs.W := 0.0;
  // Draw the BODY (non-integrand) conics only when the focus is the system's primary: the barycentre or the
  // central body (Sun in the SSB view, planet n99 in a planetary view). Focusing on a moon would splatter every
  // other body's meaningless 2-body orbit around it -- there, only integrand conics are kept.
  if FBarycenter = 0 then CentralBody := 10 else CentralBody := FBarycenter*100+99;
  OrbitBodies := (FOrbitCenter = FBarycenter) or (FOrbitCenter = CentralBody);
  // Invariant over the loop below (FOrbitCenter is fixed here). FOrbitCenter is a barycentre/Sun (0..10)
  // or a planet centre (n99): the 0..10 GMs are a direct read from the header array; only >10 codes need
  // GetPerturberGM's table search.
  if (FOrbitCenter >= 0) and (FOrbitCenter <= High(FBSPXFile.Hdr.GM)) then
   OrbitCenterGM := FBSPXFile.Hdr.GM[FOrbitCenter]
  else
   OrbitCenterGM := FBSPXFile.GetPerturberGM(FOrbitCenter);
  if Integrands then begin lo := nBSPX; hi := nTotal-1; end else begin lo := 0; hi := nBSPX-1; end;
  for i:=lo to hi do
   begin
    Pt.X      := PINF;
    DrawDot   := False;
    DrawOrbit := False;
    if i < nBSPX then
     begin
      if (FBSPXFile.Desc[i].CenterID=FBarycenter)
         or ((FBSPXFile.Desc[i].TargetID mod 100 = 99) and ((FRotTarget<0) or (FBarycenter=0) or (FBSPXFile.Desc[i].TargetID=FBarycenter*100+99)))   // planet/dwarf centres: all in SSB view; while co-rotating a planetary view, only this system's primary
         or ((FRotTarget<0) and (FBSPXFile.Desc[i].CenterID=FParentBarycenter) and (PerturberStates[0][i].GM>0.0)) then   // context siblings hidden while co-rotating (they'd just whirl)
       begin
        DrawDot := True;
        if FBSPXFile.Desc[i].CenterID=FBarycenter then
         begin
          S.R := DispPos(States[0][i].R);   // dot, re-centred on the co-rotating frame's centre
          if OrbitBodies and (FBSPXFile.Desc[i].TargetID <> FOrbitCenter) then   // primary focus only, and a body does not orbit itself
           begin                                               // conic: body RELATIVE to FOrbitCenter (a difference -> raw transform, NOT re-centred; placed by GravOfs)
            SO.R := (States[0][i].R + FBaryR - FOrbitR)*FEpsMatrix*FCoRotMatrix;
            SO.V := (States[0][i].V + FBaryV - FOrbitV)*FEpsMatrix*FCoRotMatrix;
            SO.GM := GetCorrectedGM(OrbitCenterGM, FBSPXFile.Desc[i].GM, FOrbitCenter < 10);   // Desc[i].GM == GetPerturberGM(Desc[i].TargetID) after Open (back-filled)
            DrawOrbit := True;
           end;
         end
        else
         S.R := DispPos(PerturberStates[0][i].R - FBaryR);
       end;
     end
    else
     begin
      idx := i - nBSPX;
      if not IntegrandShown(idx) then
       begin
        if i < Length(FLabelPts) then FLabelPts[i] := Pt;   // Pt.X=PINF: dot + label hidden (out-of-view while co-rotating)
        Continue;
       end;
      DrawDot := True;
      S.R := DispPos(IntForm.IntegrationS[idx].R - FBaryR);   // integrand dot, re-centred on the co-rotating frame's centre
      // Draw the osculating orbit only about a centre it is meaningful around: the full SSB view (heliocentric),
      // or a planetary system the integrand is actually inside right now (IntegrandInSystem's Hill test) -- a
      // distant, unrelated integrand would otherwise draw a nonsensical conic. Re-centre the velocity by FBaryV
      // and use that centre's GM so the conic is correct (both zero/SSB when FBarycenter=0).
      if IntegrandInSystem(idx) then
       begin
        SO.R := (IntForm.IntegrationS[idx].R - FOrbitR)*FEpsMatrix*FCoRotMatrix;   // conic: integrand relative to FOrbitCenter
        SO.V := (IntForm.IntegrationS[idx].V - FOrbitV)*FEpsMatrix*FCoRotMatrix;
        SO.GM := OrbitCenterGM;
        DrawOrbit := True;
       end;
     end;
    if DrawDot then
     begin
      glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, @FColors[i]);
      glColor3fv(@FColors[i]);
      if DrawOrbit then
       begin
        Osculate(@SO);
        if not IsNaN(SO.e) then
         begin
          P.pD:=0;
          if SO.e>0.0 then M:=GetRotMat4D(SO.Peri, 0.0, 0.0, 1.0) else M:=GetIdentityMat4D;
          if SO.Incl<>0.0 then M:=M*GetRotMat4D(SO.Incl, 1.0, 0.0, 0.0);
          if SO.Node<>0.0 then M:=M*GetRotMat4D(SO.Node, 0.0, 0.0, 1.0);
          for j:=0 to 1 do
           begin
            glBegin(GL_LINE_STRIP);
            dv:=1 - j shl 1;
            if (SO.e<1.0) and (SO.e>=0.75) then dv:=dv*IntPower(2, 7-Round(10*SO.e));
            v:=360.0*j-dv;
            while v<>180.0 do
             begin
              v:=v+dv;
              P.pA:=DegToRad(v);
              SinCos(P.pA, sina, cosa);
              n:=1+SO.e*cosa;
              if n<>0.0 then
               begin
                P.pL:=SO.q*(1+SO.e)/n*KM2AU;
                if (P.pL>0.0) and (P.pL<1000.0) then
                 begin
                  SinCos(P.pD, sind, cosd);
                  R.X:=cosa*cosd*P.pL;
                  R.Y:=sina*cosd*P.pL;
                  R.Z:=sind*P.pL;
                  R.W:=1.0;
                  if (SO.Incl<>0.0) or (SO.Peri<>0.0) then R:=R*M;
                  glVertex3d(R.X+GravOfs.X, R.Y+GravOfs.Y, R.Z+GravOfs.Z);   // focus offset (0 when FOrbitCenter=FBarycenter)
                 end;
               end;
             end;
            glEnd;
           end;
         end;
       end;
      Pt:=S.R*KM2AU;
      if not DrawBodySphere(i, Pt) then
       begin
        glEnable(GL_POINT_SMOOTH);
        glPointSize(BodyDotSize);
        glBegin(GL_POINTS);
        glVertex3d(Pt.X, Pt.Y, Pt.Z);
        glEnd;
        glPointSize(1.0);
        glDisable(GL_POINT_SMOOTH);
       end;
     end;
    if i < Length(FLabelPts) then FLabelPts[i]:=Pt;
   end;
end;

procedure TMainForm.DrawDots(Integrands: Boolean);
// Same body selection as DrawOrbits but with the orbit-curve phase omitted (mode Tag=2,
// "orbits off"): only the body dots are drawn. FLabelPts is still filled so DrawLabels works.
var
  S: TState4D;
  i, idx, lo, hi: Int64;
  Pt: TVec4D;
  FBaryR: TVec4D;
  DrawDot: Boolean;
  nBSPX, nInt, nTotal: Int64;
begin
  nBSPX  := FBSPXFile.DescCount;
  nInt   := Length(IntForm.IntegrationS);
  nTotal := nBSPX + nInt;
  // Everything is stored SSB-relative now; FBaryR = FBarycenter's SSB position re-centres the
  // sibling (PerturberStates) descriptors and the integrands for display (0 in the full SSB view;
  // direct children use raw States, already FBarycenter-relative).
  if (FBaryDescIdx >= 0) and (Length(States[0]) > FBaryDescIdx) then
   FBaryR := States[0][FBaryDescIdx].R
  else
   FillChar(FBaryR, SizeOf(FBaryR), 0);
  if Integrands then begin lo := nBSPX; hi := nTotal-1; end else begin lo := 0; hi := nBSPX-1; end;
  for i:=lo to hi do
   begin
    Pt.X    := PINF;
    DrawDot := False;
    if i < nBSPX then
     begin
      if (FBSPXFile.Desc[i].CenterID=FBarycenter)
         or ((FBSPXFile.Desc[i].TargetID mod 100 = 99) and ((FRotTarget<0) or (FBarycenter=0) or (FBSPXFile.Desc[i].TargetID=FBarycenter*100+99)))   // planet/dwarf centres: all in SSB view; while co-rotating a planetary view, only this system's primary
         or ((FRotTarget<0) and (FBSPXFile.Desc[i].CenterID=FParentBarycenter) and (PerturberStates[0][i].GM>0.0)) then   // context siblings hidden while co-rotating (they'd just whirl)
       begin
        DrawDot := True;
        if FBSPXFile.Desc[i].CenterID=FBarycenter then
         S.R := DispPos(States[0][i].R)
        else
         S.R := DispPos(PerturberStates[0][i].R - FBaryR);
       end;
     end
    else
     begin
      idx     := i - nBSPX;
      if not IntegrandShown(idx) then
       begin
        if i < Length(FLabelPts) then FLabelPts[i] := Pt;   // Pt.X=PINF: dot + label hidden (out-of-view while co-rotating)
        Continue;
       end;
      DrawDot := True;
      S.R     := DispPos(IntForm.IntegrationS[idx].R - FBaryR);
     end;
    if DrawDot then
     begin
      glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, @FColors[i]);
      glColor3fv(@FColors[i]);
      Pt:=S.R*KM2AU;
      if not DrawBodySphere(i, Pt) then
       begin
        glEnable(GL_POINT_SMOOTH);
        glPointSize(BodyDotSize);
        glBegin(GL_POINTS);
        glVertex3d(Pt.X, Pt.Y, Pt.Z);
        glEnd;
        glPointSize(1.0);
        glDisable(GL_POINT_SMOOTH);
       end;
     end;
    if i < Length(FLabelPts) then FLabelPts[i]:=Pt;
   end;
end;

procedure TMainForm.DrawTrajectories(Integrands: Boolean);
var
  S: TState4D;
  i, idx, lo, hi: Int64;
  j, k: Integer;
  Pt: TVec4D;
  FBaryR, GravOfs: TVec4D;
  nBSPX, nInt, nTotal: Int64;
begin
  nBSPX  := FBSPXFile.DescCount;
  nInt := Length(IntForm.IntegrationS);
  nTotal := nBSPX + nInt;
  GravOfs := TrailOrbitOfs;   // integrand trails are orbit-centre-relative -> shift them onto the orbit centre's dot (0 when centre = barycentre)
  // SSB-relative storage: FBaryR re-centres siblings + integrands to FBarycenter; DispPos then applies obliquity,
  // co-rotation and the FRotCenter re-centre for display. The FTrails line-strips are drawn raw because their
  // points were already baked through DispPos at store time (AdvanceScene), each in its own epoch's frame.
  if (FBaryDescIdx >= 0) and (Length(States[0]) > FBaryDescIdx) then
   FBaryR := States[0][FBaryDescIdx].R
  else
   FillChar(FBaryR, SizeOf(FBaryR), 0);
  if Integrands then begin lo := nBSPX; hi := nTotal-1; end else begin lo := 0; hi := nBSPX-1; end;
  for i:=lo to hi do
   begin
    Pt.X:=PINF;
    if i < nBSPX then
     begin
      if (FBSPXFile.Desc[i].CenterID=FBarycenter)
         or ((FBSPXFile.Desc[i].TargetID mod 100 = 99) and ((FRotTarget<0) or (FBarycenter=0) or (FBSPXFile.Desc[i].TargetID=FBarycenter*100+99)))   // planet/dwarf centres: all in SSB view; while co-rotating a planetary view, only this system's primary
         or ((FRotTarget<0) and (FBSPXFile.Desc[i].CenterID=FParentBarycenter) and (PerturberStates[0][i].GM>0.0)) then   // context siblings hidden while co-rotating (they'd just whirl)
       begin
        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, @FColors[i]);
        glColor3fv(@FColors[i]);
        if FBSPXFile.Desc[i].CenterID=FBarycenter then
         begin
          S.R:=DispPos(States[0][i].R);
          if (Length(FTrails) >= FBSPXFile.DescCount) and (FTrails[i].Count > 1) then
           begin
            glBegin(GL_LINE_STRIP);
            for j := 0 to FTrails[i].Count - 1 do
             begin
              k := (FTrails[i].Head - FTrails[i].Count + j + TRAIL_SIZE) mod TRAIL_SIZE;
              glVertex3d(FTrails[i].Pts[k].X*KM2AU, FTrails[i].Pts[k].Y*KM2AU, FTrails[i].Pts[k].Z*KM2AU);
             end;
            glEnd;
           end;
         end else S.R:=DispPos(PerturberStates[0][i].R - FBaryR);

        Pt:=S.R*KM2AU;
        if not DrawBodySphere(i, Pt) then
         begin
          glEnable(GL_POINT_SMOOTH);
          glPointSize(BodyDotSize);
          glBegin(GL_POINTS);
          glVertex3d(Pt.X, Pt.Y, Pt.Z);
          glEnd;
          glPointSize(1.0);
          glDisable(GL_POINT_SMOOTH);
         end;
        FLabelPts[i] := Pt;
       end
      else if i < Length(FLabelPts) then FLabelPts[i] := Pt;   // hidden sibling while co-rotating: Pt.X=PINF -> no dot/label
     end
    else
     begin
      idx:=i - nBSPX;
      if not IntegrandShown(idx) then
       begin
        if i < Length(FLabelPts) then FLabelPts[i] := Pt;   // Pt.X=PINF: dot + trail + label hidden (out-of-view while co-rotating)
        Continue;
       end;
      glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, @FColors[i]);
      glColor3fv(@FColors[i]);
      S.R:=DispPos(IntForm.IntegrationS[idx].R - FBaryR);
      if (i < Length(FTrails)) and (FTrails[i].Count > 1) then
       begin
        glBegin(GL_LINE_STRIP);
        for j := 0 to FTrails[i].Count - 1 do
         begin
          k := (FTrails[i].Head - FTrails[i].Count + j + TRAIL_SIZE) mod TRAIL_SIZE;
          glVertex3d((FTrails[i].Pts[k].X+GravOfs.X)*KM2AU, (FTrails[i].Pts[k].Y+GravOfs.Y)*KM2AU, (FTrails[i].Pts[k].Z+GravOfs.Z)*KM2AU);   // orbit-centre-relative point + current centre offset
         end;
        glEnd;
       end;
      Pt:=S.R*KM2AU;
      if not DrawBodySphere(i, Pt) then
       begin
        glEnable(GL_POINT_SMOOTH);
        glPointSize(BodyDotSize);
        glBegin(GL_POINTS);
        glVertex3d(Pt.X, Pt.Y, Pt.Z);
        glEnd;
        glPointSize(1.0);
        glDisable(GL_POINT_SMOOTH);
       end;
      if i < Length(FLabelPts) then FLabelPts[i]:=Pt;
     end;
   end;
end;

procedure TMainForm.UpdateIntegrationLabels;
// Runs on the render thread. Label bitmaps are rasterised by the UI thread in
// IntForm.RenderLabelBitmaps (GDI); here we only upload them as GL textures, so no
// VCL/GDI call ever happens on this thread.
var
  i: Int64;
  nBSPX, nInt, nTotal: Int64;
  W, H: Integer;
begin
  nBSPX  := FBSPXFile.DescCount;
  nInt := Length(IntForm.IntegrationS);
  nTotal := nBSPX + nInt;
  for i := nBSPX to High(FLabelTextures) do
   if FLabelTextures[i] <> 0 then
    begin glDeleteTextures(1, @FLabelTextures[i]); FLabelTextures[i] := 0; end;
  SetLength(FLabelTextures, nTotal);
  SetLength(FLabelWidths,   nTotal);
  SetLength(FLabelHeights,  nTotal);
  SetLength(FLabelPts,      nTotal);
  if Length(FColors) < nTotal then SetLength(FColors, nTotal);
  for i := nBSPX to nTotal-1 do
   begin
    FLabelTextures[i] := 0;
    FLabelWidths[i]   := 0;
    FLabelHeights[i]  := 0;
    FLabelPts[i].X    := PINF;
    FColors[i].R := 1.0; FColors[i].G := 1.0; FColors[i].B := 1.0; FColors[i].A := 1.0;
   end;
  // Resize FTrails to cover integration body slots; always reset integration slots
  // on any list mutation so stale trail data from a replaced integration is discarded
  if Length(FTrails) > nTotal then
   begin
    for i := nTotal to High(FTrails) do
     SetLength(FTrails[i].Pts, 0);
    SetLength(FTrails, nTotal);
   end
  else
   begin
    if Length(FTrails) < nTotal then
     SetLength(FTrails, nTotal);
    for i := nBSPX to nTotal-1 do
     begin
      if Length(FTrails[i].Pts) < TRAIL_SIZE then
       SetLength(FTrails[i].Pts, TRAIL_SIZE);
      FTrails[i].Head  := 0;
      FTrails[i].Count := 0;
     end;
   end;
  if nInt = 0 then Exit;
  for i := 0 to nInt-1 do
   begin
    if i >= Length(IntForm.IntegrationLabelRGBA) then Continue;
    W := IntForm.IntegrationLabelW[i];
    H := IntForm.IntegrationLabelH[i];
    if (W <= 0) or (H <= 0) or (Length(IntForm.IntegrationLabelRGBA[i]) < W*H*4) then Continue;  // empty name / not yet rasterised
    glGenTextures(1, @FLabelTextures[nBSPX+i]);
    glBindTexture(GL_TEXTURE_2D, FLabelTextures[nBSPX+i]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, W, H, 0, GL_RGBA, GL_UNSIGNED_BYTE, @IntForm.IntegrationLabelRGBA[i][0]);
    FLabelWidths[nBSPX+i]  := W;
    FLabelHeights[nBSPX+i] := H;
   end;
  glBindTexture(GL_TEXTURE_2D, 0);
end;

procedure TMainForm.LoadLabelTextures;
var
  i: Int64;
  Bmp: TBitmap;
  Name: string;
  W, H, x, y, a: Integer;
  RGBAData: array of Byte;
  SL: PByteArray;
begin
  if (FDC=0) or (FRC=0) or (FBSPXFile.DescCount=0) then Exit;
  wglMakeCurrent(FDC, FRC);
  SetLength(FLabelTextures, FBSPXFile.DescCount);
  SetLength(FLabelWidths,   FBSPXFile.DescCount);
  SetLength(FLabelHeights,  FBSPXFile.DescCount);
  FillChar(FLabelTextures[0], FBSPXFile.DescCount*SizeOf(GLuint), 0);
  FillChar(FLabelWidths[0],   FBSPXFile.DescCount*SizeOf(Integer), 0);
  FillChar(FLabelHeights[0],  FBSPXFile.DescCount*SizeOf(Integer), 0);
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.Width  := 1;
    Bmp.Height := 1;
    for i := 0 to FBSPXFile.DescCount-1 do
     begin
      Name := TrimRight(BSPXStr(FBSPXFile.Desc[i].TargetName, SizeOf(FBSPXFile.Desc[i].TargetName)));
      if Name = '' then Continue;
      W := Bmp.Canvas.TextWidth(Name) + 4;
      H := Bmp.Canvas.TextHeight(Name) + 2;
      Bmp.Width  := W;
      Bmp.Height := H;
      Bmp.Canvas.Font.Color  := clWhite;
      Bmp.Canvas.Brush.Color := clBlack;
      Bmp.Canvas.FillRect(Rect(0, 0, W, H));
      Bmp.Canvas.TextOut(2, 1, Name);
      SetLength(RGBAData, W * H * 4);
      for y := 0 to H-1 do
       begin
        SL := Bmp.ScanLine[y];
        for x := 0 to W-1 do
         begin
          a := SL[x*3+2];  // R channel of BGR (white text → 255, black bg → 0)
          RGBAData[(y*W+x)*4+0] := 255;
          RGBAData[(y*W+x)*4+1] := 255;
          RGBAData[(y*W+x)*4+2] := 255;
          RGBAData[(y*W+x)*4+3] := a;
         end;
       end;
      glGenTextures(1, @FLabelTextures[i]);
      glBindTexture(GL_TEXTURE_2D, FLabelTextures[i]);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, W, H, 0, GL_RGBA, GL_UNSIGNED_BYTE, @RGBAData[0]);
      FLabelWidths[i]  := W;
      FLabelHeights[i] := H;
     end;
  finally
    Bmp.Free;
  end;
  glBindTexture(GL_TEXTURE_2D, 0);
end;

function DeltaStr(dt: Double): string; inline;
var
  adt: Double;
begin
  adt := Abs(dt);
  if adt < HOUR2SEC then Result := Format('%5.0f sec', [dt])
  else if adt < DAY2SEC then Result := Format('%5.2f hr', [dt/HOUR2SEC])
  else Result := Format('%5.2f days', [dt*SEC2DAY]);
end;

procedure TMainForm.UpdateTitleBar;
// Called from the render loop OUTSIDE PublicLock. Reads only scalar fields, so it
// needs no lock; keeping the synchronous SetWindowText out of the locked region
// avoids a deadlock with a UI thread waiting on PublicLock in IntBoxClick/Reset.
begin
  if (FRC = 0) or (FDC = 0) then Exit;
  if (IntForm.IntegrationMode=INT_DORMANDPRINCE54) or (IntForm.IntegrationMode=INT_DORMANDPRINCE87) or (IntForm.IntegrationMode=INT_GAUSSRADAU15) then
    SetWindowText(Handle, PChar(Format('%s --- TDB=%s   dT=%s   sdT=%s   FPS=%d',
    [FExeStr, BSPXTimeStr(FT, 3), DeltaStr(FEphemDelta), DeltaStr(FSDT), FFPS])))
  else
    SetWindowText(Handle, PChar(Format('%s --- TDB=%s   dT=%s   FPS=%d',
    [FExeStr, BSPXTimeStr(FT, 3), DeltaStr(FEphemDelta), FFPS])));
end;

function TMainForm.AxisEndpointSSB(id: Int64; out S: TState4D): Boolean;
// SSB state (R,V) of a co-rotating-axis endpoint, taken from the raw per-descriptor states already interpolated
// this frame (States[0], no extra Chebyshev call). SSB (id 0) is the origin. A descriptor's state is relative to
// its own CenterID, so we reconstruct SSB by walking the centre chain to 0. This works for EVERY body -- crucially
// the MASSLESS moons (Telesto, Calypso, Helene, Polydeuces, ... GM=0), which are absent from PerturberStates[0]:
// resolving those via PerturberStates gave a zero position, so the axis pointed centre->SSB (barycentre drift)
// instead of centre->target and the target never locked (it just kept revolving). Returns False if the id -- or a
// centre up the chain -- has no descriptor or its slot is out of range.
var idx: Int64; cS: TState4D;
begin
  Result := True;
  FillChar(S, SizeOf(S), 0);
  if id = 0 then Exit;                              // Solar System Barycenter = origin
  idx := FBSPXFile.FindDesc(id);
  if (idx < 0) or (idx > High(States[0])) then begin Result := False; Exit; end;
  S := States[0][idx];                              // raw state, relative to this descriptor's CenterID
  if FBSPXFile.Desc[idx].CenterID <> 0 then         // add the centre's own SSB state (recursively) unless already SSB
   begin
    if not AxisEndpointSSB(FBSPXFile.Desc[idx].CenterID, cS) then begin Result := False; Exit; end;
    S.R := S.R + cS.R;
    S.V := S.V + cS.V;
   end;
end;

function TMainForm.TrailOrbitOfs: TVec4D;
// Integrand trails are stored RELATIVE TO the osculating-orbit centre (AdvanceScene, so Earth's ~4671 km reflex
// wobble around the EMB is not baked into the history). This is where that centre sits in the display now -- add
// it to each stored trail point so the whole path rides the centre's current dot. Identical to DrawOrbits'
// GravOfs = DispPos(FOrbitR - FBaryR); zero when the orbit centre IS the barycentre (default), so trails then
// draw exactly as before.
var FBaryR, FOrbitR: TVec4D; oS: TState4D;
begin
  if (FBaryDescIdx >= 0) and (Length(States[0]) > FBaryDescIdx) then FBaryR := States[0][FBaryDescIdx].R
  else FillChar(FBaryR, SizeOf(FBaryR), 0);
  if AxisEndpointSSB(FOrbitCenter, oS) then FOrbitR := oS.R else FOrbitR := FBaryR;
  Result := DispPos(FOrbitR - FBaryR);
end;

function TMainForm.IntegrandInSystem(idx: Int64): Boolean;
// Whether integrand idx belongs, RIGHT NOW, to the system we are looking at. This is the test behind both the
// osculating orbit (DrawOrbits) and the co-rotating visibility (IntegrandShown). It replaces the old IntegrationC
// scheme, which pinned an integrand to whatever FBarycenter happened to be current when its ICs were entered --
// stable, but counter-intuitive once the thing had actually flown somewhere else.
//   FBarycenter = 0 (full SSB view): everything belongs. The strict test ("not on a closed orbit about some
//     planetary barycentre") is far too expensive to run per frame, and a heliocentric conic is meaningful anyway.
//   FBarycenter > 0: it belongs while inside that barycentre's belonging radius -- ApproxSystemRadius, which the
//     file computed once at Open and already scaled by BSPXFile's HILL_FACTOR (tune it there).
// A radius of 0 (unknown -- body absent from the file, no GM, ...) means "do not restrict".
// Called only from the draw path, so it costs one distance per integrand per frame and needs no per-step upkeep.
var
  rH: Double;
  D: TVec4D;
begin
  if FBarycenter = 0 then Exit(True);
  rH := FBSPXFile.ApproxSystemRadius(FBarycenter);
  if rH <= 0.0 then Exit(True);
  if (idx < 0) or (idx >= Length(IntForm.IntegrationS)) then Exit(False);
  if (FBaryDescIdx < 0) or (FBaryDescIdx >= Length(States[0])) then Exit(True);   // cannot locate the centre -> do not restrict
  // Both are SSB-relative (the integrand by storage, the barycentre because its descriptor is SSB-centred), so
  // the difference is the integrand relative to the local barycentre.
  D := IntForm.IntegrationS[idx].R - States[0][FBaryDescIdx].R;
  Result := LengthVec3D(@D) <= rH;
end;

function TMainForm.IntegrandShown(idx: Int64): Boolean;
// Whether integrand idx should be drawn in the current view. Normally all integrands are shown; in a
// co-rotating frame only those belonging to the current system are -- one that has left may whirl all it likes
// while it still belongs, but a distant, unrelated one would just smear across the view.
begin
  Result := (FRotTarget < 0) or IntegrandInSystem(idx);
end;

procedure TMainForm.UpdateCoRotMatrix;
// Build FCoRotMatrix, the display-only co-rotation for this frame. A display point p maps to p*FCoRotMatrix,
// which de-rotates the scene about FBarycenter so the FRotCenter->FRotTarget axis stays fixed on screen; the
// integration is untouched. The draw procs apply it to their live dots/points/orbits, and it is baked into
// trail points as they are stored -- so a trail point carries the co-rotation of ITS epoch and stays put
// (rather than sweeping around under a single current matrix). Identity when Off (FRotTarget<0) or the axis
// is degenerate. Frame X = axis direction, Z = orbital pole (r x v), Y = Z x X; p*M = (X.p, Y.p, Z.p), so
// M's columns are X,Y,Z (cf is row-major: column c = cf0c,cf1c,cf2c). Built once per frame from the states
// just interpolated (no extra Chebyshev call), before the trail store; RenderScene reuses the field.
var
  tgtS, ctrS: TState4D;
  rr, vv, ax, ay, az: TVec4D;
  nrm: Double;
begin
  FCoRotMatrix := GetIdentityMat4D;
  FillChar(FRotCenterDisp, SizeOf(FRotCenterDisp), 0);   // Off / degenerate -> no re-centre (DispPos == plain p*FEpsMatrix*FCoRotMatrix)
  if FRotTarget < 0 then Exit;
  if not (AxisEndpointSSB(FRotTarget, tgtS) and AxisEndpointSSB(FRotCenter, ctrS)) then Exit;
  rr := (tgtS.R - ctrS.R) * FEpsMatrix; vv := (tgtS.V - ctrS.V) * FEpsMatrix;   // Centre->Target, display frame
  nrm := Sqrt(rr.X*rr.X + rr.Y*rr.Y + rr.Z*rr.Z);
  if nrm <= 0.0 then Exit;
  ax.X := rr.X/nrm; ax.Y := rr.Y/nrm; ax.Z := rr.Z/nrm;                                              // X = r_hat
  az.X := rr.Y*vv.Z - rr.Z*vv.Y; az.Y := rr.Z*vv.X - rr.X*vv.Z; az.Z := rr.X*vv.Y - rr.Y*vv.X;        // Z ~ r x v
  nrm := Sqrt(az.X*az.X + az.Y*az.Y + az.Z*az.Z);
  if nrm <= 0.0 then Exit;
  az.X := az.X/nrm; az.Y := az.Y/nrm; az.Z := az.Z/nrm;
  ay.X := az.Y*ax.Z - az.Z*ax.Y; ay.Y := az.Z*ax.X - az.X*ax.Z; ay.Z := az.X*ax.Y - az.Y*ax.X;         // Y = Z x X
  FCoRotMatrix.cf00 := ax.X; FCoRotMatrix.cf01 := ay.X; FCoRotMatrix.cf02 := az.X; FCoRotMatrix.cf03 := 0.0;
  FCoRotMatrix.cf10 := ax.Y; FCoRotMatrix.cf11 := ay.Y; FCoRotMatrix.cf12 := az.Y; FCoRotMatrix.cf13 := 0.0;
  FCoRotMatrix.cf20 := ax.Z; FCoRotMatrix.cf21 := ay.Z; FCoRotMatrix.cf22 := az.Z; FCoRotMatrix.cf23 := 0.0;
  FCoRotMatrix.cf30 := 0.0;  FCoRotMatrix.cf31 := 0.0;  FCoRotMatrix.cf32 := 0.0;  FCoRotMatrix.cf33 := 1.0;
  // FRotCenter's position in the co-rotated display frame. DispPos subtracts it so the co-rotating frame's CENTRE
  // (not FBarycenter) is the motionless origin -- otherwise, whenever the barycentre is off the FRotCenter->target
  // axis (e.g. Pluto-Hydra), FRotCenter itself sweeps a circle and every trail hula-hoops around it. ctrS.R is the
  // centre's SSB position; subtract the barycentre's SSB position (FBaryR) to get it barycentre-relative like the
  // rest of the display, then apply the same obliquity + co-rotation.
  if (FBaryDescIdx >= 0) and (Length(States[0]) > FBaryDescIdx) then
   FRotCenterDisp := (ctrS.R - States[0][FBaryDescIdx].R) * FEpsMatrix * FCoRotMatrix
  else
   FRotCenterDisp := ctrS.R * FEpsMatrix * FCoRotMatrix;
end;

function TMainForm.DispPos(const p: TVec4D): TVec4D;
// Map a FBarycenter-relative ABSOLUTE position to display coordinates: obliquity + co-rotation, then re-centre
// onto the co-rotating frame's centre (FRotCenterDisp is zero when Off, so this is the plain transform then).
// Do NOT use for velocities or relative vectors (conic states, pole/node directions) -- those must not be shifted.
begin
  Result := p * FEpsMatrix * FCoRotMatrix - FRotCenterDisp;
end;

procedure TMainForm.RotUncheckAll;
// Clear the check mark on every PMRot item: Off, each centre-submenu header, and all nested axis leaves.
  procedure Rec(Item: TMenuItem);
  var k: Integer;
  begin
    Item.Checked := False;
    for k := 0 to Item.Count-1 do Rec(Item.Items[k]);
  end;
var
  i: Integer;
begin
  for i := 0 to PMRot.Count-1 do Rec(PMRot.Items[i]);
end;

procedure TMainForm.RebuildRotMenu;
// Rebuild the co-rotating-frame axis menu (PMRot) for the current FBarycenter. PMRot0 ('Off', a design-time
// item) is never deleted -- it stays as Items[0] so a TAction can remain bound to it across rebuilds. Axes are
// grouped by CENTRE body (one submenu each); within a centre the targets are sorted by name and hung on a
// BALANCED TREE that caps every node at MAX_MENU_ITEMS children, so even a system with hundreds of satellites never
// overflows the screen. Intermediate group headers are labelled by name-range ("First … Last"); leaf caption =
// the target name. Menu-item Tag indexes FRotAxis; PMRot0.Tag = -1 = Off.
//   FBarycenter=0  (SSB view):      'SSB' -> planetary BC (1..8);   'Sun' -> planet centre (n99).
//   FBarycenter=1..9 (planet view): '<BC>' -> each direct child;    '<planet>' -> each child except the centre.
type
  TRotLeaf = record Cap: string; Tag: Int64; end;
var
  i, ci: Int64;
  leaves: array of TRotLeaf;   // targets queued for the current centre, then sorted + tree-built

  function BodyName(id: Int64): string;
  var d: Int64;
  begin
    if id = 0 then Exit('SSB');        // the SSB has no descriptor
    d := FBSPXFile.FindDesc(id);
    if d >= 0 then Result := BSPXStr(FBSPXFile.Desc[d].TargetName, SizeOf(FBSPXFile.Desc[d].TargetName))
    else Result := IntToStr(id);
  end;

  procedure Collect(Centre, Target: Int64);   // register one Centre->Target axis and queue its leaf
  var dt: Int64;
  begin
    dt := FBSPXFile.FindDesc(Target);
    if dt < 0 then Exit;               // target not present in this file -> skip
    SetLength(FRotAxis, Length(FRotAxis)+1);
    FRotAxis[High(FRotAxis)].Center := Centre;
    FRotAxis[High(FRotAxis)].Target := Target;
    SetLength(leaves, Length(leaves)+1);
    leaves[High(leaves)].Cap := BSPXStr(FBSPXFile.Desc[dt].TargetName, SizeOf(FBSPXFile.Desc[dt].TargetName));
    leaves[High(leaves)].Tag := High(FRotAxis);
  end;

  procedure SortLeaves;   // ascending by name so the group name-ranges read alphabetically
  var a, k: Int64; tmp: TRotLeaf;
  begin
    for a := 1 to High(leaves) do
     begin
      tmp := leaves[a]; k := a-1;
      while (k >= 0) and (CompareText(leaves[k].Cap, tmp.Cap) > 0) do begin leaves[k+1] := leaves[k]; Dec(k); end;
      leaves[k+1] := tmp;
     end;
  end;

  function IPow(a, e: Int64): Int64;
  begin Result := 1; while e > 0 do begin Result := Result*a; Dec(e); end; end;

  procedure BuildTree(Parent: TMenuItem; Lo, Hi: Int64);   // balanced subtree over leaves[Lo..Hi], <= MAX_MENU_ITEMS per node
  var n, d, b, base, rem, k, ii, jj, sz: Int64; it, grp: TMenuItem;
  begin
    n := Hi - Lo + 1;
    if n <= 0 then Exit;
    if n <= MAX_MENU_ITEMS then
     begin
      for k := Lo to Hi do
       begin
        it := TMenuItem.Create(Parent);
        it.Tag := leaves[k].Tag;
        it.Caption := leaves[k].Cap;
        it.OnClick := PMRotClick;
        Parent.Add(it);
       end;
      Exit;
     end;
    d := 1; while IPow(MAX_MENU_ITEMS, d) < n do Inc(d);   // min depth with MAX_MENU_ITEMS^d >= n
    b := 1; while IPow(b, d) < n do Inc(b);         // balanced branching (b <= MAX_MENU_ITEMS) with b^d >= n
    base := n div b; rem := n mod b; ii := Lo;
    for k := 0 to b-1 do
     begin
      sz := base + Ord(k < rem);   // spread the remainder over the first groups
      if sz <= 0 then Continue;
      jj := ii + sz - 1;
      grp := TMenuItem.Create(Parent);
      if jj > ii then grp.Caption := leaves[ii].Cap + ' … ' + leaves[jj].Cap
      else            grp.Caption := leaves[ii].Cap;
      Parent.Add(grp);
      BuildTree(grp, ii, jj);
      ii := jj + 1;
     end;
  end;

  procedure FinishCentre(Centre: Int64);   // sort the queued leaves and hang the balanced tree off a centre submenu
  var sub: TMenuItem;
  begin
    if Length(leaves) = 0 then Exit;   // no present targets -> no submenu
    SortLeaves;
    sub := TMenuItem.Create(PMRot);
    sub.Caption := BodyName(Centre);
    PMRot.Add(sub);
    BuildTree(sub, 0, High(leaves));
  end;

begin
  for i := PMRot.Count-1 downto 1 do PMRot.Items[i].Free;   // free the dynamic items only -- PMRot0 (Items[0]) is never deleted, so its TAction stays bound
  SetLength(FRotAxis, 0);
  PMRot0.Tag := -1; PMRot0.OnClick := PMRotClick;   // Tag -1 = Off (read by PMRotClick, whether the click comes direct or via the action's OnExecute)

  if FBarycenter = 0 then
   begin
    SetLength(leaves, 0); for i := 1 to 8 do Collect(0, i);          FinishCentre(0);    // 'SSB' -> planetary BC
    SetLength(leaves, 0); for i := 1 to 8 do Collect(10, i*100+99);  FinishCentre(10);   // 'Sun' -> planet centre
   end
  else
   begin
    ci := FBarycenter*100+99;   // this planet's centre id (e.g. 699 for Saturn BC=6)
    SetLength(leaves, 0);                                            // '<BC>' -> each direct child
    for i := 0 to FBSPXFile.DescCount-1 do
     if (FBSPXFile.Desc[i].NumComp = 3) and (FBSPXFile.Desc[i].CenterID = FBarycenter) then
      Collect(FBarycenter, FBSPXFile.Desc[i].TargetID);
    FinishCentre(FBarycenter);
    SetLength(leaves, 0);                                            // '<planet>' -> each child except the centre itself
    for i := 0 to FBSPXFile.DescCount-1 do
     if (FBSPXFile.Desc[i].NumComp = 3) and (FBSPXFile.Desc[i].CenterID = FBarycenter) and (FBSPXFile.Desc[i].TargetID <> ci) then
      Collect(ci, FBSPXFile.Desc[i].TargetID);
    FinishCentre(ci);
   end;

  // reset to Off
  FRotCenter := 0; FRotTarget := -1;
  RotUncheckAll;
  PMRot0.Checked := True;
end;

procedure TMainForm.PMRotClick(Sender: TObject);
// Select a co-rotating axis (or Off). Stores the chosen axis in FRotCenter/FRotTarget (FRotTarget < 0 = Off)
// for the render frame to consume.
var
  i, tag: Int64;
  mi, p: TMenuItem;
begin
  if Sender is TAction then Sender:=PMRot0;

  RotUncheckAll;
  mi := TMenuItem(Sender);
  mi.Checked := True;
  p := mi.Parent;   // flag every ancestor (name-range group, centre header) up to PMRot, so collapsed menus show the active path
  while (p <> nil) and (p <> PMRot) do begin p.Checked := True; p := p.Parent; end;
  tag := mi.Tag;
  if (tag < 0) or (tag > High(FRotAxis)) then begin FRotCenter := 0; FRotTarget := -1; end   // Off (PMRot0)
  else begin FRotCenter := FRotAxis[tag].Center; FRotTarget := FRotAxis[tag].Target; end;
  // QoL: follow the co-rotating centre with the camera so its motionless origin is what you look at; on Off hand
  // the camera back to the barycentre. Symmetric on purpose -- otherwise PMCamCenter would be moved onto a body
  // and never returned, which looks like a stray menu change.
  if FRotTarget < 0 then SelectCamCenter(FBarycenter) else SelectCamCenter(FRotCenter);
  // Baked trail points are in the OLD co-rotating frame; drop them so the new axis (or Off) starts clean,
  // exactly like a barycenter switch. FClearFrozen also flushes the collided-integrand display list.
  for i := 0 to High(FTrails) do FTrails[i].Count := 0;  FClearFrozen := True;
end;

procedure TMainForm.RebuildOrbitCenterMenu;
// Rebuild PMOrbitCenter (the osculating-orbit focus). The body list comes from BuildCentreMenu (MassiveOnly: only a
// GM>0 body can serve as a 2-body focus); the selection always resets to the barycentre (root) on a rebuild.
begin
  BuildCentreMenu(PMOrbitCenter, PMOrbitCenterClick, True);
  FOrbitCenter := FBarycenter;   // reset to barycentric
  PMOrbitCenter.Tag := FBarycenter;
  PMOrbitCenter.Items[0].Checked := True;   // root (FBarycenter) is Items[0]; every other item starts unchecked
end;

procedure TMainForm.BuildCentreMenu(Root: TMenuItem; Handler: TNotifyEvent; MassiveOnly: Boolean);
// Shared body-centre builder for PMOrbitCenter (MassiveOnly=True: only GM>0 focuses) and PMCamCenter
// (MassiveOnly=False: EVERY direct child, incl. massless minor moons). Clears Root, then adds, in order: the local
// barycentre(s) (SSB + planetary BCs 1..9 in the full view; just the local BC in a planetary view), the local
// primary (Sun 10 / planet n99), then every other qualifying DIRECT child ordered by id and hung on a balanced tree
// capped at MAX_MENU_ITEMS per node (headers = name-range endpoints) so a body-rich system never overflows. Leaves
// get Tag = the centre id, OnClick = Handler; Items[0] is always the root barycentre. Callers add any extra
// sections (e.g. PMCamCenter's integrands) and the selection/check state on top.
type
  TLeaf = record Cap: string; Tag: Int64; end;
var
  i, a, k, idx, CentralBody: Int64;
  tmp: TLeaf;
  barys, others: array of TLeaf;   // direct barycentres (id<10) and everything else (queued, then sorted by id)

  function Qualifies(di: Int64): Boolean;   // di = descriptor index; a direct child of FBarycenter this menu offers
  begin
    Result := (FBSPXFile.Desc[di].NumComp = 3) and (FBSPXFile.Desc[di].CenterID = FBarycenter)
              and ((not MassiveOnly) or (FBSPXFile.Desc[di].GM > 0.0));
  end;

  procedure AddLeaf(Parent: TMenuItem; ATag: Int64; const Cap: string);
  var it: TMenuItem;
  begin
    it := TMenuItem.Create(Parent);
    it.Tag := ATag;
    it.Caption := Cap;
    it.OnClick := Handler;
    Parent.Add(it);
  end;

  function IPow(b, e: Int64): Int64;
  begin Result := 1; while e > 0 do begin Result := Result*b; Dec(e); end; end;

  procedure BuildTree(Parent: TMenuItem; Lo, Hi: Int64);   // subtree over others[Lo..Hi]: fewest nodes, each packed toward MAX_MENU_ITEMS
  var n, d, span, groups, base, rem, kk, ii, jj, sz: Int64; grp: TMenuItem;
  begin
    n := Hi - Lo + 1;
    if n <= 0 then Exit;
    if n <= MAX_MENU_ITEMS then
     begin
      for kk := Lo to Hi do AddLeaf(Parent, others[kk].Tag, others[kk].Cap);
      Exit;
     end;
    d := 1; while IPow(MAX_MENU_ITEMS, d) < n do Inc(d);   // min depth with MAX_MENU_ITEMS^d >= n
    span := IPow(MAX_MENU_ITEMS, d-1);                     // one group's capacity at this level
    groups := (n + span - 1) div span;                     // FEWEST groups that hold n (<= MAX_MENU_ITEMS); keeps leaf nodes full
    base := n div groups; rem := n mod groups; ii := Lo;   // distribute evenly so the groups stay balanced (no stray tiny node)
    for kk := 0 to groups-1 do
     begin
      sz := base + Ord(kk < rem);   // spread the remainder over the first groups
      if sz <= 0 then Continue;
      jj := ii + sz - 1;
      grp := TMenuItem.Create(Parent);
      if jj > ii then grp.Caption := others[ii].Cap + ' … ' + others[jj].Cap
      else            grp.Caption := others[ii].Cap;
      Parent.Add(grp);
      BuildTree(grp, ii, jj);
      ii := jj + 1;
     end;
  end;

begin
  for i := Root.Count-1 downto 0 do Root.Items[i].Free;

  // Root = FBarycenter, always first (the SSB has no descriptor -> hard-coded name).
  idx := FBSPXFile.FindDesc(FBarycenter);
  if idx >= 0 then AddLeaf(Root, FBarycenter, BSPXStr(FBSPXFile.Desc[idx].TargetName, SizeOf(FBSPXFile.Desc[idx].TargetName)))
  else              AddLeaf(Root, FBarycenter, 'Solar System BC');

  if FBarycenter = 0 then CentralBody := 10 else CentralBody := FBarycenter*100+99;

  // Classify the qualifying direct children: barycentres (id<10) / everything else (the primary is added on its own).
  SetLength(barys, 0); SetLength(others, 0);
  for i := 0 to FBSPXFile.DescCount-1 do
   if Qualifies(i) then
    if FBSPXFile.Desc[i].TargetID < 10 then
     begin SetLength(barys, Length(barys)+1); barys[High(barys)].Tag := FBSPXFile.Desc[i].TargetID;
           barys[High(barys)].Cap := BSPXStr(FBSPXFile.Desc[i].TargetName, SizeOf(FBSPXFile.Desc[i].TargetName)); end
    else if FBSPXFile.Desc[i].TargetID <> CentralBody then
     begin SetLength(others, Length(others)+1); others[High(others)].Tag := FBSPXFile.Desc[i].TargetID;
           others[High(others)].Cap := BSPXStr(FBSPXFile.Desc[i].TargetName, SizeOf(FBSPXFile.Desc[i].TargetName)); end;

  // Barycentres, ordered by id (SSB, Mercury BC … Pluto BC).
  for a := 1 to High(barys) do
   begin tmp := barys[a]; k := a-1;
     while (k >= 0) and (barys[k].Tag > tmp.Tag) do begin barys[k+1] := barys[k]; Dec(k); end;
     barys[k+1] := tmp; end;
  for i := 0 to High(barys) do AddLeaf(Root, barys[i].Tag, barys[i].Cap);

  // The local primary (Sun / planet), if present as a qualifying child.
  idx := FBSPXFile.FindDesc(CentralBody);
  if (idx >= 0) and Qualifies(idx) then
   AddLeaf(Root, CentralBody, BSPXStr(FBSPXFile.Desc[idx].TargetName, SizeOf(FBSPXFile.Desc[idx].TargetName)));

  // Everything else: ordered by id (numbered asteroids/moons read naturally; a name sort would jumble "10" before "2"),
  // then flat (<= MAX_MENU_ITEMS) or balanced-tree packed by BuildTree.
  for a := 1 to High(others) do
   begin tmp := others[a]; k := a-1;
     while (k >= 0) and (others[k].Tag > tmp.Tag) do begin others[k+1] := others[k]; Dec(k); end;
     others[k+1] := tmp; end;
  if Length(others) > 0 then BuildTree(Root, 0, High(others));
end;

procedure TMainForm.UncheckMenuTree(Root: TMenuItem);
// Recursively clear Checked on every descendant of Root (the menus nest 2-3 deep after balanced packing).
var k: Integer;
begin
  for k := 0 to Root.Count-1 do begin Root.Items[k].Checked := False; UncheckMenuTree(Root.Items[k]); end;
end;

function TMainForm.FindMenuLeafByTag(Root: TMenuItem; ATag: Int64): TMenuItem;
// Recursively return the first LEAF (no children) under Root whose Tag = ATag, or nil. Group headers are skipped.
var k: Integer;
begin
  Result := nil;
  for k := 0 to Root.Count-1 do
   begin
    if (Root.Items[k].Count = 0) and (Root.Items[k].Tag = ATag) then Exit(Root.Items[k]);
    Result := FindMenuLeafByTag(Root.Items[k], ATag);
    if Result <> nil then Exit;
   end;
end;

procedure TMainForm.PMOrbitCenterClick(Sender: TObject);
// Pick the osculating-orbit focus. The menu can be nested (name-range submenus), so uncheck the whole tree, check
// the clicked leaf, and flag its ancestor chain so a collapsed path still shows the active leaf. FOrbitCenter is
// read by DrawOrbits. Idle AccForms follow the new centre (SetCenter, by name as it appears in their centre combo);
// OscForms deliberately do NOT -- each one keeps whatever centre the user gave it, so several can show osculating
// elements about different centres at the same time.
var
  idx, i: Int64;
  nm: string;
  mi, p: TMenuItem;
begin
  UncheckMenuTree(PMOrbitCenter);
  mi := TMenuItem(Sender);
  mi.Checked := True;
  p := mi.Parent;
  while (p <> nil) and (p <> PMOrbitCenter) do begin p.Checked := True; p := p.Parent; end;
  PMOrbitCenter.Tag := mi.Tag;
  FOrbitCenter := mi.Tag;
  // Integrand trails are stored relative to the orbit centre (see AdvanceScene), so a centre change invalidates
  // the accumulated history -- clear the integrand trails + frozen list. BSPX-body trails are barycentre-relative
  // and stay. (Barycentre and co-rotation switches already clear; this covers the remaining trigger.)
  for i := FBSPXFile.DescCount to High(FTrails) do FTrails[i].Count := 0;
  FClearFrozen := True;
  if FOrbitCenter = 0 then nm := 'Solar System BC'   // the one SSB name used everywhere (combos + menus)
  else
   begin
    idx := FBSPXFile.FindDesc(FOrbitCenter);
    if idx >= 0 then nm := BSPXStr(FBSPXFile.Desc[idx].TargetName, SizeOf(FBSPXFile.Desc[idx].TargetName)) else nm := '';
   end;
  if Assigned(IntForm) then IntForm.SetIdleAccFormsCenter(nm);   // idle AccForms follow the new centre
end;

procedure TMainForm.RebuildAccMenu;
// Rebuild PMAcc's children -- one per ACTIVE integration (IntForm.IntegrationS/Names/X). Clicking a child starts
// a new AccForm for that integration; a child is disabled (greyed) while its integration already has one, and
// re-enabled when that AccForm is destroyed. PMAcc itself is disabled when there are no active integrations.
// IntForm calls this on every active-set / AccForm-lifecycle change. The active arrays can be resized by the
// render thread (collision), so their names + has-form flags are snapshotted under PublicLock first.
var
  i, cnt: Integer;
  names: array of string;
  hasForm: array of Boolean;
  it: TMenuItem;
begin
  IntForm.PublicLock.Acquire;
  try
   cnt := Length(IntForm.IntegrationS);
   SetLength(names, cnt); SetLength(hasForm, cnt);
   for i := 0 to cnt-1 do
    begin
     names[i]   := IntForm.IntegrationNames[i];
     hasForm[i] := IntForm.IntegrationX[i] <> nil;
    end;
  finally
   IntForm.PublicLock.Release;
  end;
  for i := PMAcc.Count-1 downto 0 do PMAcc.Items[i].Free;
  for i := 0 to cnt-1 do
   begin
    it := TMenuItem.Create(PMAcc);
    it.Tag := i;                       // active-integration slot index
    it.Caption := names[i];
    it.Enabled := not hasForm[i];      // grey out integrations that already have an AccForm
    it.OnClick := PMAccItemClick;
    PMAcc.Add(it);
   end;
  PMAcc.Enabled := cnt > 0;            // no active integrations -> the whole menu is greyed
end;

procedure TMainForm.PMAccItemClick(Sender: TObject);
// Start a fresh AccForm for the clicked active integration. On success grey the item directly (don't rebuild the
// menu here -- that would free Sender mid-click); the item is re-enabled by RebuildAccMenu when the form closes.
begin
  if IntForm.StartAccForm(TMenuItem(Sender).Tag) then TMenuItem(Sender).Enabled := False;
end;

procedure TMainForm.SelectCamCenter(id: Int64);
// Point PMCamCenter (the camera-centre menu) at the leaf whose Tag = id: two-level uncheck, check that leaf and
// its submenu header, and set PMCamCenter.Tag (read by RenderScene). Falls back to the root (Items[0] =
// FBarycenter) when id has no leaf. Same select/check logic RebuildCamCenterMenu uses; called to auto-follow the
// co-rotating centre and to restore the barycentre on Off (see PMRotClick). UI-thread only (touches menu state).
var
  keep, p: TMenuItem;
begin
  if PMCamCenter.Count = 0 then Exit;
  keep := FindMenuLeafByTag(PMCamCenter, id);
  if keep = nil then keep := PMCamCenter.Items[0];   // root = FBarycenter (default when id has no leaf)
  UncheckMenuTree(PMCamCenter);
  keep.Checked := True;
  p := keep.Parent;
  while (p <> nil) and (p <> PMCamCenter) do begin p.Checked := True; p := p.Parent; end;
  PMCamCenter.Tag := keep.Tag;
  FCamOrphaned := False;   // the centre has been moved (co-rotation follow), so don't yank it to the barycentre later; the menu itself is untouched, so FCamMenuStale stands
  UpdateMinorViewEnabled;   // camera centre changed -> the minor-body item may become (un)offerable
end;

procedure TMainForm.UpdateMinorViewEnabled;
// Offer "Minor body view" only when it can act: in the full SSB view (FBarycenter=0) with the camera centred on a real
// minor body -- its own descriptor, TargetID > 10, so not SSB / a planetary barycentre / the Sun. It also stays enabled
// while already IN such a view (FBarycenter is itself a minor body, > 10), so it reads as the current selection.
begin
  if (FMinorViewItem = nil) or (FBSPXFile = nil) then Exit;
  FMinorViewItem.Enabled := (FBarycenter > 10) or
                            ((FBarycenter = 0) and (PMCamCenter.Tag > 10) and (FBSPXFile.FindDesc(PMCamCenter.Tag) >= 0));
end;

procedure TMainForm.RebuildCamCenterMenu(PreserveTarget: Boolean);
// Rebuilds PMCamCenter. Camera targets are EVERY body orbiting the current FBarycenter directly (massless minor
// moons included -> BuildCentreMenu with MassiveOnly=False; same ordering + balanced packing as PMOrbitCenter),
// plus the active integrations shown in this view (an 'Integrands' submenu, tags -(idx+1)). Items[0] is the root =
// FBarycenter itself (selectable, "no offset", Tag=FBarycenter). PMCamCenterClick handles the (nested) check state.
//   PreserveTarget=False (LoadFile, PMBarycenterClick): the selection resets to the root, since a barycenter
//     switch puts the old target outside the system anyway.
//   PreserveTarget=True (IntForm, on an integration change): the selection is kept IF its tag still names a live
//     leaf (anywhere in the tree), otherwise it falls back to the root.
var
  i, keepTag: Int64;
  keep, p, IntMenu, it: TMenuItem;
begin
  keepTag := PMCamCenter.Tag;   // current target; may be preserved across the rebuild (see below)

  BuildCentreMenu(PMCamCenter, PMCamCenterClick, False);   // root + barycentres + primary + all other direct bodies (incl. massless)

  // Active integrations shown in this view (authored here, or any in the full SSB view -- same rule as DrawOrbits),
  // under an 'Integrands' submenu. Tagged -(idx+1) to distinguish from BSPX TargetIDs; RenderScene recentres on
  // IntForm.IntegrationS[idx].R for a negative tag. The integration arrays are only ever resized on the UI thread
  // (IntBoxClick/Reset), so reading them here needs no lock.
  IntMenu := nil;
  for i := 0 to Length(IntForm.IntegrationNames)-1 do
   begin
     if IntMenu = nil then
      begin IntMenu := TMenuItem.Create(PMCamCenter); IntMenu.Caption := 'Integrands'; PMCamCenter.Add(IntMenu); end;
     it := TMenuItem.Create(IntMenu); it.Tag := -(i+1); it.Caption := IntForm.IntegrationNames[i];
     it.OnClick := PMCamCenterClick; IntMenu.Add(it);
    end;

  // Selection: default root; if PreserveTarget and keepTag still names a live leaf (anywhere in the tree), keep it.
  // Then uncheck the whole tree and check the kept leaf + its ancestor chain. PMCamCenter.Tag mirrors the kept leaf.
  keep := nil;
  if PreserveTarget then keep := FindMenuLeafByTag(PMCamCenter, keepTag);
  if keep = nil then keep := PMCamCenter.Items[0];   // root = FBarycenter
  UncheckMenuTree(PMCamCenter);
  keep.Checked := True;
  p := keep.Parent;
  while (p <> nil) and (p <> PMCamCenter) do begin p.Checked := True; p := p.Parent; end;
  PMCamCenter.Tag := keep.Tag;
  // The menu now reflects the live set and the centre is a live leaf (or the root), so a collision left pending by
  // FreezeIntegrand is fully resolved here -- whatever triggered this rebuild (barycenter switch, IntForm change,
  // or the fade-out itself). DrawFrozen then finds nothing to do and skips its rebuild.
  FCamMenuStale := False;
  FCamOrphaned  := False;
  UpdateMinorViewEnabled;   // barycentre/camera reset here -> refresh whether the minor-body item is offered
end;

procedure TMainForm.RenderScene;
const
  LIGHT_DIFFUSE:   array[0..3] of GLfloat = (1.0, 1.0, 1.0, 1.0);
  LIGHT_AMBIENT:   array[0..3] of GLfloat = (0.15, 0.15, 0.15, 1.0);   // night side stays faintly visible
  LIGHT_MODEL_AMB: array[0..3] of GLfloat = (0.0, 0.0, 0.0, 1.0);      // no extra global ambient
var
  alpha, delta: Double;
  RotMatrix: array[0..15] of GLdouble;
  i: Int64;
  camCtr, sunD: TVec4D;
  lightPos: array[0..3] of GLfloat;
begin
  if (FRC = 0) or (FDC = 0) then Exit;
  if FBuildBodyTex then BuildBodyTextures;   // one-shot after a file load; runs here because the render thread owns the GL context
  alpha := FAlpha + FdAlpha;
  delta := FDelta + FdDelta;
  // Title bar is updated by the render loop OUTSIDE PublicLock — SetWindowText
  // sends WM_SETTEXT synchronously to the UI thread, which would deadlock against
  // a UI thread blocked in IntBoxClick/Reset on PublicLock. See UpdateTitleBar.

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  // Sky pass: always use the fixed projection so sky/star geometry at
  // STAR_DIST/SKY_DIST is never pushed past the far-clip boundary by
  // floating-point rounding (which happens when near is extremely small).
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  if FViewH > 0 then gluPerspective(45.0, FViewW / FViewH, DIST_NEAR, DIST_FAR);
  glMatrixMode(GL_MODELVIEW);
  // Build the shared rotation matrix once (no trig computed again after this)
  glLoadIdentity;
  glRotated(delta, 1.0, 0.0, 0.0);
  glRotated(alpha, 0.0, 0.0, 1.0);
  glGetDoublev(GL_MODELVIEW_MATRIX, @RotMatrix[0]);
  // Stars/constellations are directional (drawn in the camera frame, not co-rotated), so in a co-rotating
  // frame they'd sit still while everything else spins -- mathematically wrong and dizzying. Suppress them
  // while co-rotating; keep the sky backdrop for aesthetics.
  if (FRotTarget < 0) and PMDrawStars.Checked then DrawStars;
  if (FRotTarget < 0) and PMDrawConst.Checked then DrawConst;
  if PMDrawSky.Checked then DrawSky;
  // Body pass: clear depth so sky is always in the background, then set a
  // dynamic near plane that tracks the camera distance so the user can zoom
  // in arbitrarily close without near-plane clipping.
  glClear(GL_DEPTH_BUFFER_BIT);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  if FViewH > 0 then
    // Near tracks the camera distance so you can zoom in close. The coefficient trades close-up headroom for
    // far-distance depth precision: at 1e-3 the near:far ratio exploded when zoomed in and distant dots (KBOs)
    // z-fought; 1e-2 is ~10x more far precision and still clears any body's near side at normal zoom.
    gluPerspective(45.0, FViewW / FViewH, Max(FDist * 1.0e-2, 1.0e-6), DIST_FAR);
  glMatrixMode(GL_MODELVIEW);
  // Re-use the captured rotation; prepend the camera pull-back via matrix multiply
  glLoadIdentity;
  glTranslated(0.0, 0.0, -FDist);
  glMultMatrixd(@RotMatrix[0]);
  if FBSPXFile.Stream <> nil then
   begin
    // Co-rotating frame: FCoRotMatrix (built in AdvanceScene) is applied in code by the draw procs to their
    // live dots/points/orbits and by camCtr below, and was baked into the trail points as they were stored
    // -- so trails stay put instead of sweeping. Nothing is multiplied into the GL matrix here; it is a
    // display-only re-frame and the integration is untouched.
    // Camera look-at target: when PMCamCenter.Tag names a body (i.e. it differs from the coordinate
    // center FBarycenter), shift the body pass so that body sits at the origin the camera points at.
    // Two kinds of target, both DIRECT children of FBarycenter so their position is already in the
    // barycenter frame: a positive tag = BSPX TargetID (position States[0][i].R, same source
    // DrawOrbits uses); a negative tag -(idx+1) = active integration body idx (position
    // IntForm.IntegrationS[idx].R). Read here under the render thread's PublicLock (held across the
    // whole frame), so the integration arrays are safe.
    // Units: *FEpsMatrix is rotation ONLY (km); the km->AU scale (KM2AU) is applied at the vertex
    // stage in DrawOrbits, so it must be applied here too — without it the offset is ~1.5e8x too
    // large and the whole scene flies off-screen. The translation is prepended AFTER pull-back+
    // rotation (Tpullback*R*Trecenter) so the body lands dead centre; the sky pass above is
    // untouched (stars are directional), so the starfield stays fixed while the scene re-centres.
    // Eye position (display AU) = look-at target + FDist along the view axis (3rd row of the rotation). Base
    // here assumes the barycenter view (target at the origin); the recenter branches below add the target's
    // position. DrawBodySphere sizes spheres by the TRUE eye->body distance, so bodies far outside the system
    // fall back to dots instead of an invisible sub-pixel sphere (their distance >> FDist).
    FEyePos.X := FDist * RotMatrix[2];
    FEyePos.Y := FDist * RotMatrix[6];
    FEyePos.Z := FDist * RotMatrix[10];
    FEyePos.W := 0.0;
    if PMCamCenter.Tag < 0 then
     begin
      i := -PMCamCenter.Tag - 1;   // active integration body index
      if i < Length(IntForm.IntegrationS) then   // every running integrand is targetable, wherever it is (the menu lists them all)
       begin
        // integrand stored SSB-relative; re-centre to FBarycenter, then DispPos re-centres to the co-rotating centre, matching the drawn dot
        if (FBaryDescIdx >= 0) and (Length(States[0]) > FBaryDescIdx) then
         camCtr := DispPos(IntForm.IntegrationS[i].R - States[0][FBaryDescIdx].R)
        else
         camCtr := DispPos(IntForm.IntegrationS[i].R);
        glTranslated(-camCtr.X*KM2AU, -camCtr.Y*KM2AU, -camCtr.Z*KM2AU);
        FEyePos.X := FEyePos.X + camCtr.X*KM2AU; FEyePos.Y := FEyePos.Y + camCtr.Y*KM2AU; FEyePos.Z := FEyePos.Z + camCtr.Z*KM2AU;
       end;
     end
    else if PMCamCenter.Tag = FBarycenter then
     begin
      // Coordinate centre = the barycentre, but while co-rotating the display origin is FRotCenter, so the
      // barycentre now sits at -FRotCenterDisp; shift it back to screen centre to keep the default barycentric
      // view (and Pluto's dot circling as before). FRotCenterDisp is zero when Off, so this is a no-op then.
      glTranslated(FRotCenterDisp.X*KM2AU, FRotCenterDisp.Y*KM2AU, FRotCenterDisp.Z*KM2AU);
      FEyePos.X := FEyePos.X - FRotCenterDisp.X*KM2AU; FEyePos.Y := FEyePos.Y - FRotCenterDisp.Y*KM2AU; FEyePos.Z := FEyePos.Z - FRotCenterDisp.Z*KM2AU;
     end
    else if (PMCamCenter.Tag <> FBarycenter) and (Length(States[0]) >= FBSPXFile.DescCount) then
     for i := 0 to FBSPXFile.DescCount-1 do
      if (FBSPXFile.Desc[i].TargetID = PMCamCenter.Tag) and (FBSPXFile.Desc[i].CenterID = FBarycenter) then
       begin
        camCtr := DispPos(States[0][i].R);
        glTranslated(-camCtr.X*KM2AU, -camCtr.Y*KM2AU, -camCtr.Z*KM2AU);
        FEyePos.X := FEyePos.X + camCtr.X*KM2AU; FEyePos.Y := FEyePos.Y + camCtr.Y*KM2AU; FEyePos.Z := FEyePos.Z + camCtr.Z*KM2AU;
        Break;
       end;
    // Lighting: illuminate ONLY the body spheres, from the Sun. The full camera modelview is active here, so a
    // positional GL_LIGHT0 (w=1) at the Sun's display position lands in the same eye space as the spheres; the
    // per-sphere glMultMatrix does not move it. DrawBodySphere toggles GL_LIGHTING around each gluSphere, so the
    // sky/stars/constellations/orbits/trajectories/dots stay unlit. Needs the Sun (GSunIdx) in the file.
    FLightingOn := PMLighting.Checked and (GSunIdx >= 0) and (GSunIdx < FBSPXFile.DescCount)
                   and (GSunIdx <= High(PerturberStates[0])) and (FBSPXFile.Desc[GSunIdx].TargetID = 10);
    if FLightingOn then
     begin
      if (FBaryDescIdx >= 0) and (Length(States[0]) > FBaryDescIdx) then
       sunD := DispPos(PerturberStates[0][GSunIdx].R - States[0][FBaryDescIdx].R)
      else
       sunD := DispPos(PerturberStates[0][GSunIdx].R);
      lightPos[0] := sunD.X*KM2AU; lightPos[1] := sunD.Y*KM2AU; lightPos[2] := sunD.Z*KM2AU; lightPos[3] := 1.0;
      FSunPos.X := lightPos[0]; FSunPos.Y := lightPos[1]; FSunPos.Z := lightPos[2];   // reused by DrawRing for the ring shadow
      glLightfv(GL_LIGHT0, GL_POSITION, @lightPos[0]);
      glLightfv(GL_LIGHT0, GL_DIFFUSE,  @LIGHT_DIFFUSE[0]);
      glLightfv(GL_LIGHT0, GL_AMBIENT,  @LIGHT_AMBIENT[0]);
      glLightModelfv(GL_LIGHT_MODEL_AMBIENT, @LIGHT_MODEL_AMB[0]);
      glEnable(GL_LIGHT0);
      glEnable(GL_COLOR_MATERIAL);
      glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);   // glColor(1,1,1) drives the sphere material
     end
    else
     begin glDisable(GL_LIGHT0); glDisable(GL_COLOR_MATERIAL); end;
    if PMDrawAxes.Checked then DrawAxes;
    // Planet/moon (BSPX) bodies and integrands have independent display modes: PMOrbitMode vs PMOrbitModeInt.
    case PMOrbitMode.Tag of
     0: DrawOrbits(False);
     1: DrawTrajectories(False);
    else DrawDots(False);          // 2 = orbits off (dots + labels only)
    end;
    case PMOrbitModeInt.Tag of
     0: DrawOrbits(True);
     1: DrawTrajectories(True);
    else DrawDots(True);
    end;
    if Length(FFrozen) > 0 then DrawFrozen;   // collided integrands, display-only (trail + dot, ageing out)
    if PMLighting.Checked then DrawCorona(RotMatrix);   // additive Sun glow, after the opaque bodies (so their depth occludes it) and before labels
    if PMDrawLabels.Checked then DrawLabels;
   end;
  SwapBuffers(FDC);
end;

function TMainForm.PerturberContaining(idx: Int64): Int64;
// Descriptor index of a gravitational perturber that integrand idx sits inside (squared distance < Req^2,
// with a 10 km fallback for bodies with no radius), or -1. Uses the perturber states in PerturberStates[0].
// A body inside a point mass is the singularity that cooks the adaptive integrator. Shared by the IC guard
// (before integration) and the per-step collision check.
const
  COLLIDE_MIN_REQ = 10.0;   // km: assumed radius when a perturber's const record carries no Req (small body)
var
  p, nP: Int64;
  dx, dy, dz, d2, req: Double;
begin
  Result := -1;
  nP := FBSPXFile.DescCount;
  if (idx < 0) or (idx >= Length(IntForm.IntegrationS)) or (Length(PerturberStates[0]) < nP) then Exit;
  for p := 0 to nP-1 do
   begin
    if PerturberStates[0][p].GM <= 0.0 then Continue;   // only gravitational perturbers can trap a body
    dx := IntForm.IntegrationS[idx].R.X - PerturberStates[0][p].R.X;
    dy := IntForm.IntegrationS[idx].R.Y - PerturberStates[0][p].R.Y;
    dz := IntForm.IntegrationS[idx].R.Z - PerturberStates[0][p].R.Z;
    d2 := dx*dx + dy*dy + dz*dz;
    req := FBSPXFile.BodyConst[p].Req;
    if req <= 0.0 then req := COLLIDE_MIN_REQ;
    if d2 < req*req then begin Result := p; Exit; end;
   end;
end;

procedure TMainForm.CheckNewIntegrationICs;
// Collision guard for a fresh integration: reject any IC that starts inside a perturber (see the analysis --
// it's a point-mass singularity that collapses the adaptive step). Called from the NewIntegration block with
// PerturberStates[0] already at the IC epoch. Removes offenders outright (the IC is invalid) and warns.
var
  i, p: Int64;
  msg: string;
begin
  msg := '';
  i := 0;
  while i < Length(IntForm.IntegrationS) do
   begin
    p := PerturberContaining(i);
    if p >= 0 then
     begin
      msg := msg + Format('   %s  —  inside  %s'#13#10,
                          [IntForm.IntegrationNames[i], BSPXStr(FBSPXFile.Desc[p].TargetName, 32)]);
      IntForm.RemoveActiveIntegration(i);   // removes i; the next body shifts into i, so don't advance
     end
    else Inc(i);
   end;
  if msg = '' then Exit;
  TThread.Synchronize(nil,
   procedure
   begin
    MessageDlg('This initial condition starts inside a body and was removed — it would drive the '+
               'integrator into a point-mass singularity:'#13#10#13#10 + msg, mtWarning, [mbOK], 0);
   end);
end;

procedure TMainForm.FreezeIntegrand(idx: Int64);
// Evict a mid-flight collided integrand from the active set into the frozen-display list: capture its trail
// + colour (so the trail lingers), remove it from the active integration arrays, and shift the integrand
// trail slots down to stay aligned with the shrunk IntegrationS. Zero integrator overhead: it is simply gone.
var
  ti, n, j, k, cnt, src, dst: Int64;
begin
  n := Length(IntForm.IntegrationS);
  if (idx < 0) or (idx >= n) then Exit;
  // PMCamCenter still lists this integrand (nothing rebuilds it here) -> mark it stale so DrawFrozen has the menu
  // rebuilt once the trail has faded. If the camera is locked on THIS integrand, note that too, so that rebuild
  // also drops the centre back to the barycentre. Both must be read BEFORE RemoveActiveIntegration shifts the
  // indices (which makes the -(idx+1) tag meaningless). Either flag is cleared if the situation resolves itself
  // first: the user picking a centre (PMCamCenterClick), or any menu rebuild (e.g. a barycenter switch).
  FCamMenuStale := True;
  if PMCamCenter.Tag = -(idx+1) then FCamOrphaned := True;
  ti := FBSPXFile.DescCount + idx;
  SetLength(FFrozen, Length(FFrozen)+1);
  with FFrozen[High(FFrozen)] do
   begin
    if ti < Length(FColors) then Color := FColors[ti]
    else begin Color.R:=1; Color.G:=1; Color.B:=1; Color.A:=1; end;
    Life := FROZEN_LIFE;
    if ti < Length(FTrails) then
     begin
      SetLength(Pts, FTrails[ti].Count);
      for k := 0 to FTrails[ti].Count-1 do
       Pts[k] := FTrails[ti].Pts[(FTrails[ti].Head - FTrails[ti].Count + k + TRAIL_SIZE) mod TRAIL_SIZE];
     end;
   end;
  IntForm.RemoveActiveIntegration(idx);
  // Shift the integrand trail slots down over idx (linearised into each slot's own buffer -- no aliasing of
  // the dynamic Pts arrays), then clear the now-vacated tail slot.
  for j := idx to n-2 do
   begin
    src := FBSPXFile.DescCount+j+1; dst := FBSPXFile.DescCount+j;
    if (src >= Length(FTrails)) or (dst >= Length(FTrails)) then Break;
    cnt := FTrails[src].Count;
    for k := 0 to cnt-1 do
     FTrails[dst].Pts[k] := FTrails[src].Pts[(FTrails[src].Head - cnt + k + TRAIL_SIZE) mod TRAIL_SIZE];
    FTrails[dst].Count := cnt;
    FTrails[dst].Head  := cnt mod TRAIL_SIZE;
   end;
  if FBSPXFile.DescCount+n-1 < Length(FTrails) then
   begin FTrails[FBSPXFile.DescCount+n-1].Count := 0; FTrails[FBSPXFile.DescCount+n-1].Head := 0; end;
end;

procedure TMainForm.DrawFrozen;
// Draw each frozen integrand's captured trail + a dot at its last point, then age it; drop expired ones.
// Runs in the same GL frame as the live trails, so the captured display-frame points render identically.
// When a trail has fully faded its menu entry is stale -- the collision dropped the integrand from the active
// set (RemoveActiveIntegration) but nothing rebuilt PMCamCenter -- so have the UI thread rebuild it then.
var
  i, k, w: Int64;
  a: Single;
  c: TColorRec;
  expired: Boolean;
  GravOfs: TVec4D;
begin
  GravOfs := TrailOrbitOfs;   // frozen trails are orbit-centre-relative (copied from the live trail) -> ride the orbit centre's dot as it moves during the fade
  expired := False;
  i := 0;
  while i <= High(FFrozen) do
   begin
    a := FFrozen[i].Life / FROZEN_LIFE;   // 1 -> 0 fade over the lifetime
    c := FFrozen[i].Color;
    c.R := c.R*a; c.G := c.G*a; c.B := c.B*a;   // dim toward the black background as it ages
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, @c);
    glColor3fv(@c);
    if Length(FFrozen[i].Pts) > 1 then
     begin
      glBegin(GL_LINE_STRIP);
      for k := 0 to High(FFrozen[i].Pts) do
       glVertex3d((FFrozen[i].Pts[k].X+GravOfs.X)*KM2AU, (FFrozen[i].Pts[k].Y+GravOfs.Y)*KM2AU, (FFrozen[i].Pts[k].Z+GravOfs.Z)*KM2AU);
      glEnd;
     end;
    if Length(FFrozen[i].Pts) > 0 then
     begin
      w := High(FFrozen[i].Pts);
      glEnable(GL_POINT_SMOOTH); glPointSize(BodyDotSize*FROZEN_DOT_MUL);   // scales with the viewport like the body dots, keeping it the touch smaller it was tuned to be
      glBegin(GL_POINTS);
      glVertex3d((FFrozen[i].Pts[w].X+GravOfs.X)*KM2AU, (FFrozen[i].Pts[w].Y+GravOfs.Y)*KM2AU, (FFrozen[i].Pts[w].Z+GravOfs.Z)*KM2AU);
      glEnd;
      glPointSize(1.0); glDisable(GL_POINT_SMOOTH);
     end;
    Dec(FFrozen[i].Life);
    if FFrozen[i].Life <= 0 then
     begin
      FFrozen[i] := FFrozen[High(FFrozen)];   // swap-remove
      SetLength(FFrozen, Length(FFrozen)-1);
      expired := True;
     end
    else Inc(i);
   end;
  // A collided integrand has finished fading: rebuild PMCamCenter so its dead entry goes away -- but only if no
  // rebuild has happened since the collision (a barycenter switch or an IntForm change already does the job and
  // clears FCamMenuStale, so there is nothing left to do). Queue, NOT Synchronize -- the render thread holds
  // FPublicLock here and the UI thread may be blocked on it (same reasoning as RemoveActiveIntegration's deferred
  // TAccForm.Free). Both flags are re-read on the UI thread at execution time, so anything that resolves the
  // situation between the queue and the call still wins: PreserveTarget=True keeps a centre the user picked,
  // False drops the selection back to the root = FBarycenter.
  if expired and FCamMenuStale then
   TThread.Queue(nil,
     procedure
     begin
       if FCamMenuStale then RebuildCamCenterMenu(not FCamOrphaned);   // clears both flags
     end);
end;

procedure TMainForm.AdvanceScene;
const
  MAX_STEP_RETRIES = 64;  // hard cap on adaptive-step rejections per frame; prevents
                          // the render thread (which holds PublicLock) from spinning
                          // forever on a pathological close encounter.
var
  i, tries: Int64;
  usedDt, FT0, maxStep: Double;
  adaptive: Boolean;
  FBaryR, FOrbitR: TVec4D;
  oS: TState4D;
begin
  if FClearFrozen then begin SetLength(FFrozen, 0); FClearFrozen := False; end;   // honour UI-thread reset request here (render thread owns FFrozen)
  if FT=NINF then FT:=FBSPXFile.Hdr.Epoch0;
  if IntForm.NewIntegration then begin FT:=IntForm.IntegrationS[0].Epoch; FSDT:=0.0; end;  // fresh: FSDT=0 -> take the max step below
  if IntForm.IntegrationModeSelected<>IntForm.IntegrationMode then IntForm.IntegrationModeChange;  // sync mode first so the test below is current

  // Maximum step this frame = animation speed (FDT = ephemeris-sec per real-sec) * target
  // frame period (FInvFPSLimit = 1/FPS-limit = real-sec per frame). The step never
  // exceeds this, so the animation never runs faster than requested. Two things may slow it
  // below the requested speed, both fine: an adaptive integrator choosing a smaller step
  // (temporary), or the actual FPS dropping under the limit (user can lower the FPS limit).
  maxStep := FDT * FInvFPSLimit;
  adaptive := (IntForm.IntegrationMode=INT_DORMANDPRINCE54) or
              (IntForm.IntegrationMode=INT_DORMANDPRINCE87) or
              (IntForm.IntegrationMode=INT_GAUSSRADAU15);

  // Fixed-step integrators (and the no-bodies ephemeris animation) always take the full max
  // step. Adaptive integrators start each frame from their last suggestion (FSDT, which the
  // integrator left there at the end of the previous frame) — not the base — so they don't waste
  // the whole retry budget re-shrinking from maxStep to hours every frame through a stiff patch;
  // we only clamp it down to maxStep (e.g. the user lowered the speed or raised the FPS limit).
  // Clamping here, at frame start, uses the CURRENT maxStep so a live speed/FPS change applies
  // immediately. FSDT<=0 means "fresh, use the max step". (After the step, FEphemDelta holds what
  // was actually integrated and FSDT the new suggestion — that's what the title bar shows.)
  if adaptive and (Length(IntForm.IntegrationS) > 0) then
   begin
    FEphemDelta := FSDT;        // start from the last adaptive suggestion...
    if (FEphemDelta <= 0.0) or (FEphemDelta > maxStep) then FEphemDelta := maxStep;   // ...but never above the max
   end
  else
   FEphemDelta := maxStep;

  for i:=Low(IntForm.IntegrationTime) to High(IntForm.IntegrationTime) do IntForm.IntegrationTime[i]:=FT+IntForm.IntegrationCoef[i]*FEphemDelta;

  if (FT>=FBSPXFile.Hdr.Epoch0) and (IntForm.IntegrationTime[0]<=FBSPXFile.Hdr.Epoch1) then
   begin

    if IntForm.NewIntegration then
     begin
      IntForm.NewIntegration:=False;
      if Length(IntForm.IntegrationS) > 0 then
       begin
        for i:=0 to High(FTrails) do begin FTrails[i].Head:=0; FTrails[i].Count:=0; end;
        FBSPXFile.BatchInterpolate2(FT, States[0]);
        if FBSPXFile.PerturberStateCenterID<>0 then FBSPXFile.PerturberStateCenterID:=0;   // integrate in SSB (inertial); FBarycenter is a display-only re-centre
        if FBSPXFile.PerturberStateCenterID>=0 then FBSPXFile.GetPerturberStates(States[0], PerturberStates[0]);
        CheckNewIntegrationICs;   // drop any IC that starts inside a perturber (uses PerturberStates[0] at the IC epoch)
        if Length(IntForm.IntegrationS) > 0 then
         Leapfrog2(0.0, IntForm.IntegrationA, IntForm.IntegrationS, PerturberStates[0]); // fill IntegrationA (initial accelerations)
       end;
      if IntForm.IntegrationMode = INT_GAUSSRADAU15 then
       begin
        IntForm.ClearRadauState;  // discard predictor history + compensated-sum accumulators
        FRadauLastDt := 0.0;      // first IAS15 step: no predictor backup to scale from
       end;
      UpdateIntegrationLabels;
     end;

    FT0:=FT;                          // step-start time; adaptive re-sampling must use this,
    FT:=IntForm.IntegrationTime[0];   // not the post-advance FT (a no-op for IAS15 since coef[0]=0)

    if FBSPXFile.PerturberStateCenterID<>0 then FBSPXFile.PerturberStateCenterID:=0;   // integrate in SSB (inertial); FBarycenter is a display-only re-centre

    if Length(IntForm.IntegrationS)>0 then
     begin
      FBSPXFile.MultiBatchInterpolate2(IntForm.IntegrationTime, States);
      if FBSPXFile.PerturberStateCenterID>=0 then FBSPXFile.GetMultiPerturberStates(States, PerturberStates);

      case IntForm.IntegrationMode of
       INT_MCLACHLAN4:
            McLachlan4(FEphemDelta, IntForm.IntegrationA, IntForm.IntegrationS, PerturberStates);
       {INT_RUNGEKUTTA5:
           RungeKutta5(FEphemDelta, IntForm.IntegrationA, IntForm.IntegrationS, PerturberStates);}
       INT_DORMANDPRINCE54:
            begin
             tries:=0;
             repeat
              Inc(tries);
              // Sign convention: FSDT > 0 => accepted (S advanced by FEphemDelta; FSDT is the
              // next-step hint, possibly < FEphemDelta as a boundary back-off). FSDT < 0 =>
              // rejected (S untouched; -FSDT is the shrunk step to retry).
              FSDT:=DormandPrince54(FEphemDelta, IntForm.IntegrationA, IntForm.IntegrationS, PerturberStates, IntForm.TmpR, IntForm.TmpV, IntForm.TmpA);
              if FSDT<0.0 then
               begin
                FEphemDelta:=-FSDT;
                // Re-sample perturbers at the SHRUNK nodes about FT0 (step start), not FT
                // (which was advanced a full base step above). Using FT desyncs the
                // perturbers by a base step on every rejection, which makes DP unable to
                // converge in stiff zones — the body stalls while time races ahead.
                for i:=Low(IntForm.IntegrationTime) to High(IntForm.IntegrationTime) do IntForm.IntegrationTime[i]:=FT0+IntForm.IntegrationCoef[i]*FEphemDelta;
                FBSPXFile.MultiBatchInterpolate2(IntForm.IntegrationTime, States);
                if FBSPXFile.PerturberStateCenterID>=0 then FBSPXFile.GetMultiPerturberStates(States, PerturberStates);
               end;
             until (FSDT>=0.0) or (tries>=MAX_STEP_RETRIES);
             if FSDT>=0.0 then
              FT:=FT0+FEphemDelta        // accepted: clock advances by the step actually taken
             else
              begin
               FT:=FT0;                  // bailed after MAX retries; S was not advanced
               FSDT:=FEphemDelta;        // carry the last (smallest) step as the next hint
              end;
             // FEphemDelta = step actually taken (title dT); FSDT = next-step suggestion (sdT).
            end;
       INT_BLANESMOANMCLACHLAN6:
            BlanesMoanMcLachlan6(FEphemDelta, IntForm.IntegrationA, IntForm.IntegrationS, PerturberStates);
       INT_DORMANDPRINCE87:
            begin
             tries:=0;
             repeat
              Inc(tries);
              // Sign convention (see DP54): FSDT > 0 => accepted (S advanced by FEphemDelta; FSDT
              // is the next-step hint, possibly < FEphemDelta as a boundary back-off). FSDT < 0 =>
              // rejected (S untouched; -FSDT is the shrunk step to retry).
              FSDT:=DormandPrince87(FEphemDelta, IntForm.IntegrationA, IntForm.IntegrationS, PerturberStates, IntForm.TmpR, IntForm.TmpV, IntForm.TmpA);
              if FSDT<0.0 then
               begin
                FEphemDelta:=-FSDT;
                // Re-sample perturbers at the SHRUNK nodes about FT0 (step start), not FT
                // (which was advanced a full base step above). Using FT desyncs the
                // perturbers by a base step on every rejection, which makes DP unable to
                // converge in stiff zones — the body stalls while time races ahead.
                for i:=Low(IntForm.IntegrationTime) to High(IntForm.IntegrationTime) do IntForm.IntegrationTime[i]:=FT0+IntForm.IntegrationCoef[i]*FEphemDelta;
                FBSPXFile.MultiBatchInterpolate2(IntForm.IntegrationTime, States);
                if FBSPXFile.PerturberStateCenterID>=0 then FBSPXFile.GetMultiPerturberStates(States, PerturberStates);
               end;
             until (FSDT>=0.0) or (tries>=MAX_STEP_RETRIES);
             if FSDT>=0.0 then
              FT:=FT0+FEphemDelta        // accepted: clock advances by the step actually taken
             else
              begin
               FT:=FT0;                  // bailed after MAX retries; S was not advanced
               FSDT:=FEphemDelta;        // carry the last (smallest) step as the next hint
              end;
             // FEphemDelta = step actually taken (title dT); FSDT = next-step suggestion (sdT).
            end;
       INT_GAUSSRADAU15:
            begin // GaussRadau15 (IAS15) — adaptive, implicit; one accepted step per frame.
             // Gravity-field degree caps (<2 = off, else max degree, clamped to GRAV_NMAX internally). Zonals (m=0, DP +
             // IAS15): CBprec0 = deg 8 or off. Tesserals (m>=1, IAS15): Pprec1.Tag = 0 (off) / 4 (RBprec1a) / 8 (RBprec1b), gated by CBprec1.
             if IntForm.CBprec0.Checked then GZonalMaxDeg := 8 else GZonalMaxDeg := 0;
             GTesseralMaxDeg := IntForm.Pprec1.Tag;
             GNodeTime  := IntForm.IntegrationTime;          // node times for AccelTesseralAll's body-fixed rotation (the same live array the perturbers are sampled at; in-frame retries update it in place)
             GDragActive := IntForm.CBprec4.Checked;        // atmospheric drag (user opt-in; IAS15 only)
             // Per-body non-grav (Yarkovsky A1/A2/A3 + atmospheric drag InvBC, one TNonGrav): copy each body's
             // record from IntForm, with CBprec3 as the SHARED global enable via .Active -- unchecked disables both.
             // A body still contributes nothing where its own terms are zero (A1=A2=A3=0 and/or InvBC=0).
             if Length(GNonGrav) <> Length(IntForm.IntegrationNonGrav) then SetLength(GNonGrav, Length(IntForm.IntegrationNonGrav));
             for i := 0 to High(GNonGrav) do
              begin
               GNonGrav[i]        := IntForm.IntegrationNonGrav[i];
               GNonGrav[i].Active := IntForm.CBprec3.Checked;
              end;
             tries:=0;
             repeat
              Inc(tries);
              usedDt:=FEphemDelta;   // step actually attempted (var dt is overwritten by the call)
              FBSPXFile.PackPerturbers(PerturberStates);   // compact perturbers into the SoA the PN kernel consumes (pass nil below for the old AoS path)
              if GaussRadau15(FEphemDelta, FRadauLastDt, IntForm.IntegrationA, IntForm.IntegrationS, PerturberStates,
                              IntForm.IntegrationB, IntForm.IntegrationE, IntForm.IntegrationBr, IntForm.IntegrationEr,
                              IntForm.IntegrationCSX, IntForm.IntegrationCSV, FBSPXFile.PerturberSoA) then
               begin
                FT:=FT+usedDt;          // accepted: state advanced by usedDt; advance the clock
                FRadauLastDt:=usedDt;   // remember last accepted step for the predictor ratio
                Break;
               end;
              // rejected: FEphemDelta now holds the smaller retry step; re-sample nodes at FT
              for i:=Low(IntForm.IntegrationTime) to High(IntForm.IntegrationTime) do IntForm.IntegrationTime[i]:=FT+IntForm.IntegrationCoef[i]*FEphemDelta;
              FBSPXFile.MultiBatchInterpolate2(IntForm.IntegrationTime, States);
              if FBSPXFile.PerturberStateCenterID>=0 then FBSPXFile.GetMultiPerturberStates(States, PerturberStates);
             until tries>=MAX_STEP_RETRIES;
             FSDT:=FEphemDelta;     // GaussRadau15 left its suggestion in FEphemDelta; FSDT is
                                    //   both the title's sdT and the carry to next frame
             FEphemDelta:=usedDt;   // FEphemDelta = the step actually taken this frame (title dT)
             // IAS15 lays its nodes c=0..0.9775 (Coef[0]=0), so States[0] was interpolated at the
             // step START while FT has now advanced a full step. Re-sync States[0]/PerturberStates[0]
             // to the new FT so the "index 0 = latest" convention holds for IAS15 too (the FSAL
             // integrators already satisfy it via Coef[0]=1). This end-step state is simultaneously
             // the next step's c=0 node (FSAL). Mirrors the no-integrand path at the end of the routine.
             // TODO(perf): this node-0 state is recomputed next frame by the MultiBatchInterpolate2 at
             //   the top of the routine (it fills all of States[0..7], and IntegrationTime[0]=FT). True
             //   FSAL reuse would carry it: give MultiBatchInterpolate2 an optional start-index so the
             //   next step batches nodes 1..7 and reuses this States[0] as P[0], saving one descriptor
             //   interpolation per frame. Negligible at 240fps; revisit only if the viewer is profiled.
             FBSPXFile.BatchInterpolate2(FT, States[0]);
             if FBSPXFile.PerturberStateCenterID>=0 then FBSPXFile.GetPerturberStates(States[0], PerturberStates[0]);
            end;
       else Leapfrog2(FEphemDelta, IntForm.IntegrationA, IntForm.IntegrationS, PerturberStates[0]);
      end;
     end
     else
     begin
      // No integration bodies — just animate the ephemeris. Modes 0..5 advanced FT
      // via "FT:=IntegrationTime[0]" above (IntegrationCoef[0]=1), but mode 6 keeps
      // IntegrationCoef[0]=0 (P[0] is the c=0 node) and relies on case 6 to advance
      // FT — which is skipped here with zero bodies. Advance the clock explicitly so
      // the ephemeris doesn't freeze in place.
      if IntForm.IntegrationMode = INT_GAUSSRADAU15 then FT := FT + FEphemDelta;
      FBSPXFile.BatchInterpolate2(FT, States[0]);
      if FBSPXFile.PerturberStateCenterID>=0 then FBSPXFile.GetPerturberStates(States[0], PerturberStates[0]);
     end;
    // Co-rotating frame: rebuild FCoRotMatrix from the states just interpolated (before the trail store, so
    // trail points bake in THIS epoch's co-rotation and stay put; RenderScene reuses the same field). Identity
    // when Off. Trails are cleared on a co-rotating-axis change (PMRotClick), like a barycenter switch.
    UpdateCoRotMatrix;
    if Length(FTrails) >= FBSPXFile.DescCount then
     begin
      // Store trail points via DispPos: obliquity + this epoch's co-rotation, re-centred onto the co-rotating
      // frame's centre (FRotCenter) -- so each point is baked in ITS epoch's frame and stays put, and FRotCenter
      // itself (and every trail) no longer sweeps a circle when the barycentre is off the rotation axis. FBaryR
      // (FBarycenter's SSB position) re-centres the SSB-relative integrands; direct children are already
      // FBarycenter-relative. Trails clear on a barycenter/axis switch, so a fixed view stays consistent.
      if (FBaryDescIdx >= 0) and (Length(States[0]) > FBaryDescIdx) then
       FBaryR := States[0][FBaryDescIdx].R
      else
       FillChar(FBaryR, SizeOf(FBaryR), 0);
      // Integrand trails are stored relative to the OSCULATING-ORBIT centre (FOrbitCenter), not the barycentre,
      // so a geocentric orbit's path is not smeared by Earth's reflex wobble around the EMB (FOrbitCenter=FBary
      // -> FOrbitR=FBaryR, unchanged). DrawTrajectories/DrawFrozen add TrailOrbitOfs to land them on the centre's
      // dot. No FRotCenter re-centre here (raw Eps*CoRot) -- that lives in TrailOrbitOfs, as it does for the conic.
      if AxisEndpointSSB(FOrbitCenter, oS) then FOrbitR := oS.R else FOrbitR := FBaryR;

      for i := 0 to FBSPXFile.DescCount-1 do
       if FBSPXFile.Desc[i].CenterID = FBarycenter then
        begin
         FTrails[i].Pts[FTrails[i].Head] := DispPos(States[0][i].R);   // BSPX bodies stay barycentre-relative (their centre IS the barycentre)
         FTrails[i].Head := (FTrails[i].Head + 1) mod TRAIL_SIZE;
         if FTrails[i].Count < TRAIL_SIZE then Inc(FTrails[i].Count);
        end;

      for i := 0 to Length(IntForm.IntegrationS)-1 do
        if FBSPXFile.DescCount + i < Length(FTrails) then
         begin
          FTrails[FBSPXFile.DescCount+i].Pts[FTrails[FBSPXFile.DescCount+i].Head] := (IntForm.IntegrationS[i].R - FOrbitR)*FEpsMatrix*FCoRotMatrix;   // orbit-centre-relative (placed by TrailOrbitOfs at draw)
          FTrails[FBSPXFile.DescCount+i].Head  := (FTrails[FBSPXFile.DescCount+i].Head + 1) mod TRAIL_SIZE;
          if FTrails[FBSPXFile.DescCount+i].Count < TRAIL_SIZE then Inc(FTrails[FBSPXFile.DescCount+i].Count);
         end;
     end;
    // Per-step collision: freeze any integrand now inside a perturber body (eviction -> frozen-display list,
    // so the integrators stay zero-overhead). Runs after the trail store, so the frozen entry keeps the trail
    // up to the collision point; PerturberStates[0] is at the current epoch here (post-step / IAS15 re-sync).
    i := 0;
    while i < Length(IntForm.IntegrationS) do
     if PerturberContaining(i) >= 0 then FreezeIntegrand(i)   // removes i; the next body shifts in -> don't advance
     else Inc(i);
    if Length(FSnapshotBuf)>0 then
     begin
      FStateLock.Acquire;
      try
       Move(States[0][0], FSnapshotBuf[0], Length(FSnapshotBuf)*SizeOf(TState4D));
      finally
       FStateLock.Release;
      end;
     end;
    RenderScene;
   end else if Length(IntForm.IntegrationS) < 1 then FT:=FBSPXFile.Hdr.Epoch0;
end;

procedure TMainForm.SetFPSLimit(Value: Double);
// valid range: 1.0 to 1000.0
begin
  if Value<=1.0 then Value:=1.0 else if Value>1000.0 then Value:=1000.0;
  FInvFPSLimit:=1/Value;
end;

procedure TMainForm.OnHintDo(Sender: TObject);
begin
  StatusBar.SimpleText:=Application.Hint;
end;

procedure TMainForm.SaveIniFile(Sender: TObject);
var
  L: TStringList;
begin
  L:=TStringList.Create;
  try
   L.Append(Format('%s=%s', [INI_BSPXFILE,      FDataFile]));
   L.Append(Format('%s=%d', [INI_FPSLIMIT,      IntForm.FPSSpin.Tag]));
   L.Append(Format('%s=%d', [INI_ANIMSPEED,     PMSpeed.Tag]));
   L.Append(Format('%s=%d', [INI_DISPLAYAXES,   Ord(PMDrawAxes.Checked)]));
   L.Append(Format('%s=%d', [INI_DISPLAYSTARS,  Ord(PMDrawStars.Checked)]));
   L.Append(Format('%s=%d', [INI_DISPLAYSKY,    Ord(PMDrawSky.Checked)]));
   L.Append(Format('%s=%d', [INI_DISPLAYCONST,  Ord(PMDrawConst.Checked)]));
   L.Append(Format('%s=%d', [INI_DISPLAYLABELS, Ord(PMDrawLabels.Checked)]));
   L.Append(Format('%s=%d', [INI_DISPLAYBODIES, Ord(PMBodies.Checked)]));
   L.Append(Format('%s=%d', [INI_DISPLAYLIGHT,  Ord(PMLighting.Checked)]));
   L.Append(Format('%s=%d', [INI_ORBITMODE_GEN, PMOrbitMode.Tag]));
   L.Append(Format('%s=%d', [INI_ORBITMODE_INT, PMOrbitModeInt.Tag]));
   {$IFNDEF AVX2}
   L.Append(Format('%s=%s', [INI_NOAVX2WARNING, LoadStrFromIni(FIniFile, INI_NOAVX2WARNING)]));   // keep the AVX2-warning opt-out across a settings re-save (this build only)
   {$ENDIF}
   L.SaveToFile(FIniFile);
  finally
   L.Free;
  end;
end;

function GetInt(const S: string; var Value: Int64; MinVal, MaxVal, DefVal: Int64): Boolean;
begin
  try
   Value:=StrToInt(S);
   if (Value<MinVal) or (Value>MaxVal) then raise Exception.Create('Invalid value.');
   Result:=(Value<>DefVal);
  except
   Result:=False;
  end;
end;

procedure TMainForm.LoadIniFile(Sender: TObject);
var
  L: TStringList;
  i: Int64;
begin
  L:=TStringList.Create;
  try
   L.LoadFromFile(FIniFile);
   FDataFile:=L.Values[INI_BSPXFILE];
   if not FileExists(FDataFile) then FDataFile:='';
   if GetInt(L.Values[INI_FPSLIMIT], i, MIN_FPSLIMIT, MAX_FPSLIMIT, PMSpeed.Tag) then IntForm.LimitFPS(i);
   if GetInt(L.Values[INI_ANIMSPEED], i, 0, PMSpeed.Count-1, PMSpeed.Tag) then PMSpeed.Items[i].OnClick(PMSpeed.Items[i]);
   if GetInt(L.Values[INI_DISPLAYAXES], i, 0, 1, Ord(PMDrawAxes.Checked)) then PMDrawAxes.Checked:=(i=1);
   if GetInt(L.Values[INI_DISPLAYSTARS], i, 0, 1, Ord(PMDrawStars.Checked)) then PMDrawStars.Checked:=(i=1);
   if GetInt(L.Values[INI_DISPLAYSKY], i, 0, 1, Ord(PMDrawSky.Checked)) then PMDrawSky.Checked:=(i=1);
   if GetInt(L.Values[INI_DISPLAYCONST], i, 0, 1, Ord(PMDrawConst.Checked)) then PMDrawConst.Checked:=(i=1);
   if GetInt(L.Values[INI_DISPLAYLABELS], i, 0, 1, Ord(PMDrawLabels.Checked)) then PMDrawLabels.Checked:=(i=1);
   if GetInt(L.Values[INI_DISPLAYBODIES], i, 0, 1, Ord(PMBodies.Checked)) then PMBodies.Checked:=(i=1);
   if GetInt(L.Values[INI_DISPLAYLIGHT], i, 0, 1, Ord(PMLighting.Checked)) then PMLighting.Checked:=(i=1);
   if GetInt(L.Values[INI_ORBITMODE_GEN], i, 0, PMOrbitMode.Count-1, PMOrbitMode.Tag) then PMOrbitMode.Items[i].OnClick(PMOrbitMode.Items[i]);
   if GetInt(L.Values[INI_ORBITMODE_INT], i, 0, PMOrbitModeInt.Count-1, PMOrbitModeInt.Tag) then PMOrbitModeInt.Items[i].OnClick(PMOrbitModeInt.Items[i]);
  except
  end;
  L.Free;
end;

{$IFNDEF AVX2}
procedure SetIniFlag(const IniName, Tag, Value: string);
// Update one key in the .ini while preserving the rest (RSoftUtils64 has no single-value writer). Errors are
// swallowed: failing to persist the opt-out must never block startup.
var sl: TStringList;
begin
  sl:=TStringList.Create;
  try
   try
    sl.NameValueSeparator:='=';
    if FileExists(IniName) then sl.LoadFromFile(IniName);
    sl.Values[Tag]:=Value;
    sl.SaveToFile(IniName);
   except
   end;
  finally
   sl.Free;
  end;
end;
{$ENDIF}

{$IFDEF AVX2}
initialization
  // This build uses AVX2/FMA3 assembly throughout (integrators, Chebyshev, Vec4D). On a CPU without
  // it the first such instruction would fault (#UD), so refuse to start with a clear message instead.
  if not CPUID_AVX2_FMA3 then
  begin
    MessageBox(0,
      PChar('Integrator3D (AVX2 build) requires a CPU with AVX2 and FMA3'#13#10 +
            'support, which this machine does not provide, so the program'#13#10 +
            'cannot run. Please use the non-AVX2 build.'),
      PChar('Unsupported CPU'),
      MB_ICONERROR or MB_OK);
    Halt(1);
  end;
{$ELSE}
initialization
  // Compatibility (non-AVX2) build: if the CPU actually supports AVX2/FMA3, the dedicated AVX2 build runs much
  // faster, so say so -- once, and dismissably. The guard reads the opt-out straight from disk here (before the
  // form/settings load). The two builds keep SEPARATE .ini files (Integrator3D.ini vs Integrator3D-compat.ini),
  // so the flag is per-build. '1' = suppressed, so the block runs while the flag is NOT '1'.
  if (LoadStrFromIni(ChangeFileExt(Application.ExeName, '.ini'), INI_NOAVX2WARNING) <> '1') and CPUID_AVX2_FMA3 then
   with TTaskDialog.Create(nil) do
    try
     Caption          := 'Integrator3D';
     Title            := 'A faster build is available for your CPU';
     Text             := 'This processor supports AVX2/FMA3, but this is the compatibility (non-AVX2) build. '+
                         'The dedicated AVX2 build runs several times faster on this machine, especially with '+
                         'many bodies and the higher-order integrators.'#13#10#13#10+
                         'Continue with this build anyway?';
     CommonButtons    := [tcbYes, tcbNo];
     DefaultButton    := tcbYes;
     MainIcon         := tdiInformation;
     VerificationText := 'Don''t show this message again';
     Execute;
     if tfVerificationFlagChecked in Flags then
      SetIniFlag(ChangeFileExt(Application.ExeName, '.ini'), INI_NOAVX2WARNING, '1');   // persist the opt-out now
     if ModalResult <> mrYes then Halt(0);                                              // user chose not to continue
    finally
     Free;
    end;
{$ENDIF}

end.
