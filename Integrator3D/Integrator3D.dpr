program Integrator3D;

uses
  Vcl.Forms,
  Main in 'Main.pas' {MainForm},
  Vcl.Themes,
  Vcl.Styles,
  Osc in 'Osc.pas' {OscForm},
  Vec in 'Vec.pas' {VecForm},
  Int in 'Int.pas' {IntForm},
  Acc in 'Acc.pas' {AccForm},
  Chebyshev in '..\LIB\Chebyshev.pas',
  Hlp in 'Hlp.pas' {HlpForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Carbon');
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TVecForm, VecForm);
  Application.CreateForm(TIntForm, IntForm);
  Application.CreateForm(THlpForm, HlpForm);
  Application.Run;
end.
