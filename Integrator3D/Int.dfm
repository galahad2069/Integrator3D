object IntForm: TIntForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Numerical integrator'
  ClientHeight = 339
  ClientWidth = 613
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 317
    Top = 0
    Height = 339
    Align = alRight
    ExplicitLeft = 328
    ExplicitTop = 272
    ExplicitHeight = 100
  end
  object IntGroup: TGroupBox
    Left = 0
    Top = 0
    Width = 317
    Height = 339
    Align = alClient
    Caption = 'Available integrands:'
    TabOrder = 0
    ExplicitWidth = 311
    ExplicitHeight = 322
    object AddBtn: TButton
      Left = 2
      Top = 42
      Width = 313
      Height = 25
      Align = alTop
      Caption = 'Add...'
      TabOrder = 1
      OnClick = AddBtnClick
      ExplicitWidth = 307
    end
    object IntBox: TListBox
      Left = 2
      Top = 67
      Width = 313
      Height = 220
      Align = alClient
      ExtendedSelect = False
      ItemHeight = 15
      MultiSelect = True
      TabOrder = 2
      OnKeyDown = IntBoxKeyDown
      OnMouseUp = IntBoxMouseUp
      ExplicitWidth = 307
      ExplicitHeight = 203
    end
    object DelBtn: TButton
      Left = 2
      Top = 287
      Width = 313
      Height = 25
      Align = alBottom
      Caption = 'Delete'
      TabOrder = 3
      OnClick = DelBtnClick
      ExplicitTop = 270
      ExplicitWidth = 307
    end
    object LoadBtn: TButton
      Left = 2
      Top = 17
      Width = 313
      Height = 25
      Align = alTop
      Caption = '&Load...'
      TabOrder = 0
      OnClick = LoadBtnClick
      ExplicitWidth = 307
    end
    object SaveBtn: TButton
      Left = 2
      Top = 312
      Width = 313
      Height = 25
      Align = alBottom
      Caption = '&Save...'
      TabOrder = 4
      OnClick = SaveBtnClick
      ExplicitTop = 295
      ExplicitWidth = 307
    end
  end
  object SettingsGroup: TGroupBox
    Left = 320
    Top = 0
    Width = 293
    Height = 339
    Align = alRight
    Caption = 'Settings:'
    TabOrder = 1
    ExplicitLeft = 314
    ExplicitHeight = 322
    object ModeBox: TRadioGroup
      Tag = 1
      Left = 2
      Top = 17
      Width = 289
      Height = 184
      Align = alTop
      Caption = 'Integrator:'
      ItemIndex = 0
      Items.Strings = (
        '2nd-order St'#248'rmer'#8211'Verlet (leapfrog)'
        '4th-order McLachlan (symplectic)'
        '5(4)th-order Dormand-Prince (adaptive)'
        '6th-order Blanes-Moan-McLachlan (symplectic)'
        '8(7)th-order Dormand-Prince (adaptive)'
        '15th-order Gauss-Radau (adaptive, implicit)')
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = ModeBoxClick
    end
    object SpinPanel: TPanel
      Left = 2
      Top = 287
      Width = 289
      Height = 50
      Align = alBottom
      Alignment = taLeftJustify
      BevelOuter = bvNone
      TabOrder = 1
      OnResize = SpinPanelResize
      ExplicitTop = 270
      object FPSLbl: TLabel
        Left = 188
        Top = 20
        Width = 80
        Height = 15
        Hint = 'Renderer thread FPS limiter (affects integration step size)'
        AutoSize = False
        Caption = 'FPS limit: 240'
        ParentShowHint = False
        ShowHint = True
      end
      object ToleranceLbl: TLabel
        Left = 16
        Top = 20
        Width = 129
        Height = 15
        Hint = 'Tolerance level of adaptive Dormand-Prince methods'
        AutoSize = False
        Caption = 'Error tolerance: 10^-10'
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        Visible = False
      end
      object FPSSpin: TSpinButton
        Tag = 240
        Left = 272
        Top = 16
        Width = 20
        Height = 25
        Hint = 'Renderer thread FPS limiter (affects integration step size)'
        DownGlyph.Data = {
          0E010000424D0E01000000000000360000002800000009000000060000000100
          200000000000D800000000000000000000000000000000000000008080000080
          8000008080000080800000808000008080000080800000808000008080000080
          8000008080000080800000808000000000000080800000808000008080000080
          8000008080000080800000808000000000000000000000000000008080000080
          8000008080000080800000808000000000000000000000000000000000000000
          0000008080000080800000808000000000000000000000000000000000000000
          0000000000000000000000808000008080000080800000808000008080000080
          800000808000008080000080800000808000}
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        UpGlyph.Data = {
          0E010000424D0E01000000000000360000002800000009000000060000000100
          200000000000D800000000000000000000000000000000000000008080000080
          8000008080000080800000808000008080000080800000808000008080000080
          8000000000000000000000000000000000000000000000000000000000000080
          8000008080000080800000000000000000000000000000000000000000000080
          8000008080000080800000808000008080000000000000000000000000000080
          8000008080000080800000808000008080000080800000808000000000000080
          8000008080000080800000808000008080000080800000808000008080000080
          800000808000008080000080800000808000}
        OnDownClick = FPSSpinDownClick
        OnUpClick = FPSSpinUpClick
      end
      object ToleranceSpin: TSpinButton
        Tag = -10
        Left = 142
        Top = 16
        Width = 20
        Height = 25
        DownGlyph.Data = {
          0E010000424D0E01000000000000360000002800000009000000060000000100
          200000000000D800000000000000000000000000000000000000008080000080
          8000008080000080800000808000008080000080800000808000008080000080
          8000008080000080800000808000000000000080800000808000008080000080
          8000008080000080800000808000000000000000000000000000008080000080
          8000008080000080800000808000000000000000000000000000000000000000
          0000008080000080800000808000000000000000000000000000000000000000
          0000000000000000000000808000008080000080800000808000008080000080
          800000808000008080000080800000808000}
        Enabled = False
        TabOrder = 1
        UpGlyph.Data = {
          0E010000424D0E01000000000000360000002800000009000000060000000100
          200000000000D800000000000000000000000000000000000000008080000080
          8000008080000080800000808000008080000080800000808000008080000080
          8000000000000000000000000000000000000000000000000000000000000080
          8000008080000080800000000000000000000000000000000000000000000080
          8000008080000080800000808000008080000000000000000000000000000080
          8000008080000080800000808000008080000080800000808000000000000080
          8000008080000080800000808000008080000080800000808000008080000080
          800000808000008080000080800000808000}
        Visible = False
        OnDownClick = ToleranceSpinDownClick
        OnUpClick = ToleranceSpinUpClick
      end
      object SaveIntBtn: TButton
        Left = 16
        Top = 16
        Width = 137
        Height = 25
        Hint = 'Save current states of ongoing integrations'
        Caption = 'Save current states...'
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        OnClick = SaveIntBtnClick
      end
    end
    object CBprec0: TCheckBox
      AlignWithMargins = True
      Left = 8
      Top = 203
      Width = 280
      Height = 17
      Hint = 
        'Second-degree zonal harmonic coefficient of a planet'#39's gravity f' +
        'ield (quantifies the gravitational effect caused by the planet'#39's' +
        ' equatorial bulge)'
      Margins.Left = 6
      Margins.Top = 2
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Planetary dynamic oblateness (J2)'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
    end
    object CBprec2: TCheckBox
      AlignWithMargins = True
      Left = 8
      Top = 241
      Width = 280
      Height = 17
      Hint = 
        'First post-Newtonian acceleration (first-order deviation from cl' +
        'assical mechanics under General Relativity)'
      Margins.Left = 6
      Margins.Top = 2
      Margins.Bottom = 0
      Align = alTop
      Caption = '1PN relativistic acceleration term'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
    end
    object CBprec1: TCheckBox
      AlignWithMargins = True
      Left = 8
      Top = 222
      Width = 280
      Height = 17
      Hint = 
        'Third and higher-order zonal harmonic coefficients of a planet'#39's' +
        ' gravity field (quantifies the gravitational effect caused by th' +
        'e planet'#39's equatorial bulge)'
      Margins.Left = 6
      Margins.Top = 2
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Planetary dynamic oblateness (J3/4)'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
    end
    object CBprec3: TCheckBox
      AlignWithMargins = True
      Left = 8
      Top = 260
      Width = 280
      Height = 17
      Hint = 
        'JPL/Marsden nongravitational acceleration (Yarkovsky effect, tra' +
        'nsversal+radial)'
      Margins.Left = 6
      Margins.Top = 2
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Non-gravitational acceleration (Yarkovsky)'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
    end
    object CBprec4: TCheckBox
      AlignWithMargins = True
      Left = 8
      Top = 279
      Width = 280
      Height = 17
      Hint = 'Orbital decay due to atmospheric drag'
      Margins.Left = 6
      Margins.Top = 2
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Atmospheric drag'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      ExplicitLeft = 9
      ExplicitTop = 283
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 'Integrator3D Initial Conditions file (*.icf)|*.icf'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 64
    Top = 112
  end
  object SaveDialog: TSaveDialog
    DefaultExt = '.icf'
    Filter = 'Integrator3D Initial Conditions file (*.icf)|*.icf'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 152
    Top = 104
  end
end
