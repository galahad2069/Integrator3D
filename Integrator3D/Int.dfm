object IntForm: TIntForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Numerical integrator'
  ClientHeight = 354
  ClientWidth = 607
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
    Left = 311
    Top = 0
    Height = 354
    Align = alRight
    ExplicitLeft = 328
    ExplicitTop = 272
    ExplicitHeight = 100
  end
  object IntGroup: TGroupBox
    Left = 0
    Top = 0
    Width = 311
    Height = 354
    Align = alClient
    Caption = 'Available integrands:'
    TabOrder = 0
    ExplicitWidth = 305
    ExplicitHeight = 325
    object AddBtn: TButton
      Left = 2
      Top = 42
      Width = 307
      Height = 25
      Align = alTop
      Caption = 'Add...'
      TabOrder = 1
      OnClick = AddBtnClick
      ExplicitWidth = 301
    end
    object IntBox: TListBox
      Left = 2
      Top = 67
      Width = 307
      Height = 235
      Align = alClient
      ExtendedSelect = False
      ItemHeight = 15
      MultiSelect = True
      TabOrder = 2
      OnKeyDown = IntBoxKeyDown
      OnMouseUp = IntBoxMouseUp
      ExplicitWidth = 301
      ExplicitHeight = 206
    end
    object DelBtn: TButton
      Left = 2
      Top = 302
      Width = 307
      Height = 25
      Align = alBottom
      Caption = 'Delete'
      TabOrder = 3
      OnClick = DelBtnClick
      ExplicitTop = 273
      ExplicitWidth = 301
    end
    object LoadBtn: TButton
      Left = 2
      Top = 17
      Width = 307
      Height = 25
      Align = alTop
      Caption = '&Load...'
      TabOrder = 0
      OnClick = LoadBtnClick
      ExplicitWidth = 301
    end
    object SaveBtn: TButton
      Left = 2
      Top = 327
      Width = 307
      Height = 25
      Align = alBottom
      Caption = '&Save...'
      TabOrder = 4
      OnClick = SaveBtnClick
      ExplicitTop = 298
      ExplicitWidth = 301
    end
  end
  object SettingsGroup: TGroupBox
    Left = 314
    Top = 0
    Width = 293
    Height = 354
    Align = alRight
    Caption = 'Settings:'
    TabOrder = 1
    ExplicitLeft = 308
    ExplicitHeight = 325
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
      Top = 302
      Width = 289
      Height = 50
      Align = alBottom
      Alignment = taLeftJustify
      BevelOuter = bvNone
      TabOrder = 6
      OnResize = SpinPanelResize
      ExplicitTop = 273
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
        OnDownClick = FPSSpinDownClick
        OnUpClick = FPSSpinUpClick
      end
      object ToleranceSpin: TSpinButton
        Tag = -10
        Left = 142
        Top = 16
        Width = 20
        Height = 25
        Hint = 'Tolerance level of adaptive Dormand-Prince methods'
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
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
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
        TabOrder = 0
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
        'Second to eighth-degree zonal harmonics of a body'#39's gravitationa' +
        'l field (quantifies the gravitational effect caused by the body'#39 +
        's equatorial bulge)'
      Margins.Left = 6
      Margins.Top = 2
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Oblateness (zonal harmonics J2-8)'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
    end
    object CBprec2: TCheckBox
      AlignWithMargins = True
      Left = 8
      Top = 239
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
    object CBprec3: TCheckBox
      AlignWithMargins = True
      Left = 8
      Top = 258
      Width = 280
      Height = 17
      Hint = 
        'Solar radiation pressure and/or JPL/Marsden radial/transverse/no' +
        'rmal non-gravitational acceleration (Yarkovsky effect, cometary ' +
        'outgassing)'
      Margins.Left = 6
      Margins.Top = 2
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Non-gravitational acceleration'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
    end
    object CBprec4: TCheckBox
      AlignWithMargins = True
      Left = 8
      Top = 277
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
      TabOrder = 5
    end
    object Pprec1: TPanel
      Left = 2
      Top = 220
      Width = 289
      Height = 17
      Hint = 
        'Tesseral harmonics of a body'#39's gravitational field up to the eig' +
        'hth degree (quantifies the gravitational effect caused by the bo' +
        'dy'#39's non-axisymmetric, longitude-dependent mass distribution)'
      Align = alTop
      BevelOuter = bvNone
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      object CBprec1: TCheckBox
        AlignWithMargins = True
        Left = 6
        Top = 2
        Width = 170
        Height = 15
        Hint = 
          'Tesseral harmonics of a body'#39's gravitational field up to the eig' +
          'hth degree (quantifies the gravitational effect caused by the bo' +
          'dy'#39's non-axisymmetric, longitude-dependent mass distribution)'
        Margins.Left = 6
        Margins.Top = 2
        Margins.Bottom = 0
        Align = alLeft
        Caption = 'Gravitational field tesserals:'
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        OnClick = CBprec1Click
      end
      object RBprec1b: TRadioButton
        Left = 219
        Top = 2
        Width = 40
        Height = 20
        Hint = 
          'Gravity field tesserals evaluated to the eighth degree (degrees ' +
          '2-8)'
        Caption = '2-8'
        Checked = True
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        TabStop = True
        OnClick = CBprec1Click
      end
      object RBprec1a: TRadioButton
        Left = 179
        Top = 2
        Width = 40
        Height = 20
        Hint = 
          'Gravity field tesserals evaluated to the fourth degree (degrees ' +
          '2-4)'
        Caption = '2-4'
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnClick = CBprec1Click
      end
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
