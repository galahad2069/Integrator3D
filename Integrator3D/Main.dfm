object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Integrator3D'
  ClientHeight = 784
  ClientWidth = 1048
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  WindowState = wsMaximized
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnMouseWheel = FormMouseWheel
  OnResize = FormResize
  TextHeight = 15
  object glPanel: TPanel
    Left = 0
    Top = 0
    Width = 1048
    Height = 784
    Align = alClient
    BevelOuter = bvNone
    Color = clBlack
    ParentBackground = False
    PopupMenu = PopupMenu
    TabOrder = 0
    OnMouseDown = glPanelMouseDown
    OnMouseMove = glPanelMouseMove
    OnMouseUp = glPanelMouseUp
    ExplicitWidth = 1042
    ExplicitHeight = 767
    object StatusBar: TStatusBar
      Left = 0
      Top = 765
      Width = 1048
      Height = 19
      Panels = <>
      SimplePanel = True
      ExplicitTop = 748
      ExplicitWidth = 1042
    end
  end
  object PopupMenu: TPopupMenu
    Left = 512
    Top = 393
    object PMStart: TMenuItem
      Action = ActionStart
    end
    object PMSpeed: TMenuItem
      Tag = 6
      Caption = 'S&peed'
      object PMSpeed02: TMenuItem
        Tag = 60
        Action = ActionSpeed0
        Caption = '1 minute/sec'
      end
      object PMSpeed01: TMenuItem
        Tag = 1800
        Action = ActionSpeed1
      end
      object PMSpeed0: TMenuItem
        Tag = 3600
        Action = ActionSpeed2
      end
      object PMSpeed1: TMenuItem
        Tag = 21600
        Action = ActionSpeed3
      end
      object PMSpeed2: TMenuItem
        Tag = 43200
        Action = ActionSpeed4
      end
      object PMSpeed3: TMenuItem
        Tag = 86400
        Action = ActionSpeed5
      end
      object PMSpeed4: TMenuItem
        Tag = 604800
        Action = ActionSpeed6
      end
      object PMSpeed5: TMenuItem
        Tag = 2592000
        Action = ActionSpeed7
        RadioItem = True
      end
      object PMSpeed6: TMenuItem
        Tag = 7776000
        Action = ActionSpeed8
      end
      object PMSpeed7: TMenuItem
        Tag = 15552000
        Action = ActionSpeed9
      end
      object PMSpeed8: TMenuItem
        Tag = 31557600
        Action = ActionSpeed10
      end
      object PMSpeed9: TMenuItem
        Tag = 63115200
        Action = ActionSpeed11
      end
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object PMBarycenter: TMenuItem
      Caption = '&Barycenter'
      object PMBarycenter0: TMenuItem
        Action = ActionBarycenter0
      end
    end
    object PMRot: TMenuItem
      Caption = 'Co-&rotating frame'
      object PMRot0: TMenuItem
        Action = ActionCoRotOff
      end
    end
    object PMDraw: TMenuItem
      Caption = '&Display'
      object PMDrawAxes: TMenuItem
        Caption = '&Axes'
        OnClick = PMDrawClick
      end
      object PMDrawStars: TMenuItem
        Caption = '&Stars'
        OnClick = PMDrawClick
      end
      object PMDrawSky: TMenuItem
        Caption = 'Sk&y'
        Checked = True
        OnClick = PMDrawClick
      end
      object PMDrawConst: TMenuItem
        Caption = '&Constellations'
        OnClick = PMDrawClick
      end
      object PMDrawLabels: TMenuItem
        Caption = '&Labels'
        Checked = True
        OnClick = PMDrawClick
      end
      object PMBodies: TMenuItem
        Caption = '&Bodies'
        Checked = True
        OnClick = PMToggleClick
      end
      object PMLighting: TMenuItem
        Caption = 'Li&ghting'
        Checked = True
        OnClick = PMToggleClick
      end
    end
    object PMOrbitMode: TMenuItem
      Caption = 'Orbits'
      object PMOrbitMode0: TMenuItem
        Caption = '&Osculating orbits'
        Checked = True
        OnClick = PMOrbitModeClick
      end
      object PMOrbitMode1: TMenuItem
        Caption = '&Trajectories'
        OnClick = PMOrbitModeClick
      end
      object PMOrbitMode2: TMenuItem
        Caption = 'O&ff'
        OnClick = PMOrbitModeClick
      end
    end
    object PMOrbitModeInt: TMenuItem
      Caption = 'I&ntegrand orbits'
      object PMOrbitModeInt0: TMenuItem
        Caption = '&Osculating orbits'
        Checked = True
        OnClick = PMOrbitModeIntClick
      end
      object PMOrbitModeInt1: TMenuItem
        Caption = '&Trajectories'
        OnClick = PMOrbitModeIntClick
      end
      object PMOrbitModeInt2: TMenuItem
        Caption = 'O&ff'
        OnClick = PMOrbitModeIntClick
      end
    end
    object PMOrbitCenter: TMenuItem
      Caption = 'Center of orbits'
    end
    object PMCamCenter: TMenuItem
      Caption = '&Camera target'
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object PMLoad: TMenuItem
      Action = ActionLoad
    end
    object PMOsc: TMenuItem
      Action = ActionNewOsc
    end
    object PMIntegrator: TMenuItem
      Action = ActionIntegrators
    end
    object PMAcc: TMenuItem
      Caption = 'Acceleration'
      Enabled = False
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object PMLoadIni: TMenuItem
      Action = ActionLoadIni
    end
    object PMSaveIni: TMenuItem
      Action = ActionSaveIni
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 'BSPX files (*.bspx)|*.bspx'
    Options = [ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 840
    Top = 144
  end
  object ActionList: TActionList
    Left = 712
    Top = 304
    object ActionStart: TAction
      Caption = 'Start&/Stop'
      ShortCut = 16472
      OnExecute = PMStartClick
    end
    object ActionSpeed0: TAction
      Caption = '15 minutes/sec'
      ShortCut = 112
      OnExecute = PMSpeedClick
    end
    object ActionSpeed1: TAction
      Tag = 1
      Caption = '30 minutes/sec'
      ShortCut = 113
      OnExecute = PMSpeedClick
    end
    object ActionSpeed2: TAction
      Tag = 2
      Caption = '1 hour/sec'
      ShortCut = 114
      OnExecute = PMSpeedClick
    end
    object ActionSpeed3: TAction
      Tag = 3
      Caption = '6 hours/sec'
      ShortCut = 115
      OnExecute = PMSpeedClick
    end
    object ActionSpeed4: TAction
      Tag = 4
      Caption = '12 hours/sec'
      ShortCut = 116
      OnExecute = PMSpeedClick
    end
    object ActionSpeed5: TAction
      Tag = 5
      Caption = '1 day/sec'
      ShortCut = 117
      OnExecute = PMSpeedClick
    end
    object ActionSpeed6: TAction
      Tag = 6
      Caption = '1 week/sec'
      ShortCut = 118
      OnExecute = PMSpeedClick
    end
    object ActionSpeed7: TAction
      Tag = 7
      Caption = '1 month/sec'
      ShortCut = 119
      OnExecute = PMSpeedClick
    end
    object ActionSpeed8: TAction
      Tag = 8
      Caption = '3 months/sec'
      ShortCut = 120
      OnExecute = PMSpeedClick
    end
    object ActionSpeed9: TAction
      Tag = 9
      Caption = '6 months/sec'
      ShortCut = 121
      OnExecute = PMSpeedClick
    end
    object ActionSpeed10: TAction
      Tag = 10
      Caption = '1 year/sec'
      ShortCut = 122
      OnExecute = PMSpeedClick
    end
    object ActionSpeed11: TAction
      Tag = 11
      Caption = '2 years/sec'
      ShortCut = 123
      OnExecute = PMSpeedClick
    end
    object ActionBarycenter0: TAction
      Caption = 'Solar System BC'
      ShortCut = 16450
      OnExecute = PMBarycenterClick
    end
    object ActionCoRotOff: TAction
      Caption = '&Off'
      ShortCut = 16466
      OnExecute = PMRotClick
    end
    object ActionLoad: TAction
      Caption = 'Load &ephemeris file...'
      ShortCut = 16453
      OnExecute = PMLoadClick
    end
    object ActionNewOsc: TAction
      Caption = '&Osculating elements...'
      ShortCut = 16463
      OnExecute = PMNewOscClick
    end
    object ActionIntegrators: TAction
      Caption = 'Integrators...'
      ShortCut = 16457
      OnExecute = PMIntegratorClick
    end
    object ActionLoadIni: TAction
      Caption = '&Load settings'
      ShortCut = 16460
      OnExecute = LoadIniFile
    end
    object ActionSaveIni: TAction
      Caption = '&Save settings'
      ShortCut = 16467
      OnExecute = SaveIniFile
    end
  end
end
