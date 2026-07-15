object VecForm: TVecForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Add integrand'
  ClientHeight = 740
  ClientWidth = 294
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object CenterBox: TComboBox
    Left = 0
    Top = 23
    Width = 294
    Height = 21
    Hint = 'Center'
    Align = alTop
    Style = csDropDownList
    DropDownCount = 12
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
    TextHint = '<select center>'
    OnChange = EnableStartBtn
    OnDrawItem = ComboDrawItem
  end
  object FrameBox: TComboBox
    Left = 0
    Top = 46
    Width = 294
    Height = 21
    Hint = 'Reference frame'
    Align = alTop
    Style = csDropDownList
    DropDownCount = 6
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    TextHint = '<select reference frame>'
    OnChange = EnableStartBtn
    OnDrawItem = ComboDrawItem
    Items.Strings = (
      'ICRF (J2000 Equatorial)'
      'J2000 Ecliptical')
  end
  object Panel_Input: TPanel
    Left = 0
    Top = 69
    Width = 294
    Height = 386
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitWidth = 288
    ExplicitHeight = 369
    object Splitter1: TSplitter
      Left = 75
      Top = 0
      Height = 386
      ExplicitLeft = 120
      ExplicitTop = 112
      ExplicitHeight = 100
    end
    object Splitter2: TSplitter
      Left = 216
      Top = 0
      Height = 386
      Align = alRight
      ExplicitLeft = 160
      ExplicitTop = 152
      ExplicitHeight = 100
    end
    object Panel_INames: TPanel
      Left = 0
      Top = 0
      Width = 75
      Height = 386
      Align = alLeft
      Constraints.MaxWidth = 100
      Constraints.MinWidth = 50
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      ExplicitHeight = 369
      object Panel_Name_Header: TPanel
        Left = 1
        Top = 1
        Width = 73
        Height = 20
        Align = alTop
        Caption = 'Element:'
        TabOrder = 24
      end
      object Name_e: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 241
        Width = 65
        Height = 16
        Hint = 'Eccentricity'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        BorderWidth = 1
        Caption = 'e:'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 15
        ExplicitTop = 224
      end
      object Name_TPP: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 337
        Width = 65
        Height = 16
        Hint = 'Time of periapsis passage (TDB)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'TPP:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 21
        ExplicitTop = 320
      end
      object Name_Incl: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 321
        Width = 65
        Height = 16
        Hint = 'Inclination'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Incl:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 20
        ExplicitTop = 304
      end
      object Name_Node: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 305
        Width = 65
        Height = 16
        Hint = 'Argument of ascending node'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Node:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 19
        ExplicitTop = 288
      end
      object Name_Peri: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 289
        Width = 65
        Height = 16
        Hint = 'Argument of periapsis'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Peri:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 18
        ExplicitTop = 272
      end
      object Name_q: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 257
        Width = 65
        Height = 16
        Hint = 'Periapsis distance'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'q:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 16
        ExplicitTop = 240
      end
      object Name_Mean: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 225
        Width = 65
        Height = 16
        Hint = 'Mean anomaly'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Mean:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 14
        ExplicitTop = 208
      end
      object Name_True: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 209
        Width = 65
        Height = 16
        Hint = 'True anomaly'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'True:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 13
        ExplicitTop = 192
      end
      object Name_Epoch: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 21
        Width = 65
        Height = 16
        Hint = 'Epoch of osculating elements (TDB)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Epoch:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
      end
      object Name_Period: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 369
        Width = 65
        Height = 16
        Hint = 'Orbital period'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Period:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 23
        ExplicitTop = 352
      end
      object name_n: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 353
        Width = 65
        Height = 16
        Hint = 'Mean motion'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'n:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 22
        ExplicitTop = 336
      end
      object Name_a: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 273
        Width = 65
        Height = 16
        Hint = 'Semi-major axis'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'a:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 17
        ExplicitTop = 256
      end
      object Panel1: TPanel
        Left = 1
        Top = 37
        Width = 73
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
      end
      object Name_RX: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 45
        Width = 65
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'R.X:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
      end
      object Name_RY: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 61
        Width = 65
        Height = 16
        Hint = 'Position vector Y'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'R.Y:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
      end
      object Name_RZ: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 77
        Width = 65
        Height = 16
        Hint = 'Position vector Z'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'R.Z:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 4
      end
      object Panel13: TPanel
        Left = 1
        Top = 93
        Width = 73
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 5
      end
      object Name_VX: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 101
        Width = 65
        Height = 16
        Hint = 'Velocity vector X'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'V.X:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 6
      end
      object Name_VY: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 117
        Width = 65
        Height = 16
        Hint = 'Velocity vector Y'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'V.Y:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 7
      end
      object Name_VZ: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 133
        Width = 65
        Height = 16
        Hint = 'Velocity vector Z'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'V.Z:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 8
      end
      object Name_A1: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 157
        Width = 65
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A1 (radial)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'A1'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 10
      end
      object Panel9: TPanel
        Left = 1
        Top = 149
        Width = 73
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 9
      end
      object Name_A2: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 173
        Width = 65
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A2 (transverse)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'A2'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 11
      end
      object Name_A3: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 189
        Width = 65
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A3 (normal)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'A3'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 12
      end
    end
    object Panel_IUnits: TPanel
      Left = 219
      Top = 0
      Width = 75
      Height = 386
      Align = alRight
      Constraints.MaxWidth = 100
      Constraints.MinWidth = 50
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      ExplicitLeft = 213
      ExplicitHeight = 369
      object Panel_Unit_Header: TPanel
        Left = 1
        Top = 1
        Width = 73
        Height = 20
        Align = alTop
        Caption = 'Unit:'
        TabOrder = 24
      end
      object Unit_TPP: TButton
        Left = 1
        Top = 337
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'Gregorian'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 21
        OnClick = UnitClick_Epoch
        ExplicitTop = 320
      end
      object Unit_Period: TButton
        Left = 1
        Top = 369
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'day(s)'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 23
        OnClick = UnitClick_Time
        ExplicitTop = 352
      end
      object Unit_n: TButton
        Left = 1
        Top = 353
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'deg/day'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 22
        OnClick = UnitClick_AnglePerTime
        ExplicitTop = 336
      end
      object Unit_a: TButton
        Left = 1
        Top = 273
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'AU'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 17
        OnClick = UnitClick_Dist
        ExplicitTop = 256
      end
      object Unit_Epoch: TButton
        Left = 1
        Top = 21
        Width = 73
        Height = 16
        Align = alTop
        Caption = 'Gregorian'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        OnClick = Unit_EpochClick
      end
      object Unit_Incl: TButton
        Left = 1
        Top = 321
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'deg'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 20
        OnClick = UnitClick_Angle
        ExplicitTop = 304
      end
      object Unit_Node: TButton
        Left = 1
        Top = 305
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'deg'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 19
        OnClick = UnitClick_Angle
        ExplicitTop = 288
      end
      object Unit_Peri: TButton
        Left = 1
        Top = 289
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'deg'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 18
        OnClick = UnitClick_Angle
        ExplicitTop = 272
      end
      object Unit_q: TButton
        Left = 1
        Top = 257
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'AU'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 16
        OnClick = UnitClick_Dist
        ExplicitTop = 240
      end
      object Unit_e: TButton
        Left = 1
        Top = 241
        Width = 73
        Height = 16
        Align = alBottom
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 15
        ExplicitTop = 224
      end
      object Unit_True: TButton
        Left = 1
        Top = 209
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'deg'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 13
        OnClick = UnitClick_Angle
        ExplicitTop = 192
      end
      object Unit_Mean: TButton
        Left = 1
        Top = 225
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'deg'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 14
        OnClick = UnitClick_Angle
        ExplicitTop = 208
      end
      object Panel4: TPanel
        Left = 1
        Top = 37
        Width = 73
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
      end
      object Unit_RX: TButton
        Tag = 1
        Left = 1
        Top = 45
        Width = 73
        Height = 16
        Align = alTop
        Caption = 'AU'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        OnClick = UnitClick_Dist
      end
      object Unit_RY: TButton
        Tag = 1
        Left = 1
        Top = 61
        Width = 73
        Height = 16
        Align = alTop
        Caption = 'AU'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
        OnClick = UnitClick_Dist
      end
      object Unit_RZ: TButton
        Tag = 1
        Left = 1
        Top = 77
        Width = 73
        Height = 16
        Align = alTop
        Caption = 'AU'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 4
        OnClick = UnitClick_Dist
      end
      object Panel15: TPanel
        Left = 1
        Top = 93
        Width = 73
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 5
      end
      object Unit_VX: TButton
        Left = 1
        Top = 101
        Width = 73
        Height = 16
        Align = alTop
        Caption = 'AU/day'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 6
        OnClick = UnitClick_Speed
      end
      object Unit_VY: TButton
        Left = 1
        Top = 117
        Width = 73
        Height = 16
        Align = alTop
        Caption = 'AU/day'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 7
        OnClick = UnitClick_Speed
      end
      object Unit_VZ: TButton
        Left = 1
        Top = 133
        Width = 73
        Height = 16
        Align = alTop
        Caption = 'AU/day'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 8
        OnClick = UnitClick_Speed
      end
      object Panel10: TPanel
        Left = 1
        Top = 149
        Width = 73
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 9
      end
      object Unit_A3: TButton
        Tag = 1
        Left = 1
        Top = 189
        Width = 73
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A3 (normal)'
        Align = alTop
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 12
      end
      object Unit_A2: TButton
        Tag = 1
        Left = 1
        Top = 173
        Width = 73
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A2 (transverse)'
        Align = alTop
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 11
      end
      object Unit_A1: TButton
        Tag = 1
        Left = 1
        Top = 157
        Width = 73
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A1 (radial)'
        Align = alTop
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 10
      end
    end
    object Panel_IValues: TPanel
      Left = 78
      Top = 0
      Width = 138
      Height = 386
      Margins.Bottom = 0
      Align = alClient
      Alignment = taLeftJustify
      BevelOuter = bvNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      ExplicitWidth = 132
      ExplicitHeight = 369
      object Panel_Value_Header: TPanel
        Left = 0
        Top = 0
        Width = 138
        Height = 20
        Hint = 'Press to switch between momentary and average values'
        Align = alTop
        Caption = 'Value:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        ExplicitWidth = 132
      end
      object Value_e: TEdit
        Left = 0
        Top = 242
        Width = 138
        Height = 16
        Hint = 'Eccentricity'
        Align = alBottom
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 14
        OnKeyPress = NumericOnlyKeyPress
        ExplicitTop = 225
        ExplicitWidth = 132
      end
      object Value_q: TEdit
        Left = 0
        Top = 258
        Width = 138
        Height = 16
        Hint = 'Periapsis distance'
        Align = alBottom
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 15
        OnKeyPress = NumericOnlyKeyPress
        ExplicitTop = 241
        ExplicitWidth = 132
      end
      object Value_Peri: TEdit
        Left = 0
        Top = 290
        Width = 138
        Height = 16
        Hint = 'Argument of periapsis'
        Align = alBottom
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 16
        OnKeyPress = NumericOnlyKeyPress
        ExplicitTop = 273
        ExplicitWidth = 132
      end
      object Value_Node: TEdit
        Left = 0
        Top = 306
        Width = 138
        Height = 16
        Hint = 'Argument of ascending node'
        Align = alBottom
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 17
        OnKeyPress = NumericOnlyKeyPress
        ExplicitTop = 289
        ExplicitWidth = 132
      end
      object Value_Incl: TEdit
        Left = 0
        Top = 322
        Width = 138
        Height = 16
        Hint = 'Inclination'
        Align = alBottom
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 18
        OnKeyPress = NumericOnlyKeyPress
        ExplicitTop = 305
        ExplicitWidth = 132
      end
      object Value_TPP: TEdit
        Left = 0
        Top = 338
        Width = 138
        Height = 16
        Hint = 'Time of periapsis passage (TDB)'
        Align = alBottom
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 19
        ExplicitTop = 321
        ExplicitWidth = 132
      end
      object Value_a: TEdit
        Left = 0
        Top = 274
        Width = 138
        Height = 16
        Hint = 'Semi-major axis'
        Align = alBottom
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 20
        OnKeyPress = NumericOnlyKeyPress
        ExplicitTop = 257
        ExplicitWidth = 132
      end
      object Value_n: TEdit
        Left = 0
        Top = 354
        Width = 138
        Height = 16
        Hint = 'Mean motion'
        Align = alBottom
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 21
        OnKeyPress = NumericOnlyKeyPress
        ExplicitTop = 337
        ExplicitWidth = 132
      end
      object Value_Period: TEdit
        Left = 0
        Top = 370
        Width = 138
        Height = 16
        Hint = 'Orbital period'
        Align = alBottom
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 22
        OnKeyPress = NumericOnlyKeyPress
        ExplicitTop = 353
        ExplicitWidth = 132
      end
      object Value_Epoch: TEdit
        Left = 0
        Top = 20
        Width = 138
        Height = 16
        Hint = 'Epoch of osculating elements (TDB)'
        Align = alTop
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnChange = Value_EpochChange
        OnDblClick = Value_EpochDblClick
        ExplicitWidth = 132
      end
      object Value_True: TEdit
        Left = 0
        Top = 210
        Width = 138
        Height = 16
        Hint = 'True anomaly'
        Align = alBottom
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 23
        OnKeyPress = NumericOnlyKeyPress
        ExplicitTop = 193
        ExplicitWidth = 132
      end
      object Value_Mean: TEdit
        Left = 0
        Top = 226
        Width = 138
        Height = 16
        Hint = 'Mean anomaly'
        Align = alBottom
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 24
        OnKeyPress = NumericOnlyKeyPress
        ExplicitTop = 209
        ExplicitWidth = 132
      end
      object Panel2: TPanel
        Left = 0
        Top = 36
        Width = 138
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 2
        ExplicitWidth = 132
      end
      object Value_RX: TEdit
        Left = 0
        Top = 44
        Width = 138
        Height = 16
        Hint = 'Position vector X'
        Align = alTop
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
        OnKeyPress = NumericOnlyKeyPress
        ExplicitWidth = 132
      end
      object Value_RY: TEdit
        Tag = 1
        Left = 0
        Top = 60
        Width = 138
        Height = 16
        Hint = 'Position vector Y'
        Align = alTop
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 4
        OnKeyPress = NumericOnlyKeyPress
        ExplicitWidth = 132
      end
      object Value_RZ: TEdit
        Tag = 2
        Left = 0
        Top = 76
        Width = 138
        Height = 16
        Hint = 'Position vector Z'
        Align = alTop
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 5
        OnKeyPress = NumericOnlyKeyPress
        ExplicitWidth = 132
      end
      object Panel14: TPanel
        Left = 0
        Top = 92
        Width = 138
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 6
        ExplicitWidth = 132
      end
      object Value_VX: TEdit
        Tag = 4
        Left = 0
        Top = 100
        Width = 138
        Height = 16
        Hint = 'Velocity vector X'
        Align = alTop
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 7
        OnKeyPress = NumericOnlyKeyPress
        ExplicitWidth = 132
      end
      object Value_VY: TEdit
        Tag = 5
        Left = 0
        Top = 116
        Width = 138
        Height = 16
        Hint = 'Velocity vector Y'
        Align = alTop
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 8
        OnKeyPress = NumericOnlyKeyPress
        ExplicitWidth = 132
      end
      object Value_VZ: TEdit
        Tag = 6
        Left = 0
        Top = 132
        Width = 138
        Height = 16
        Hint = 'Velocity vector Z'
        Align = alTop
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 9
        OnKeyPress = NumericOnlyKeyPress
        ExplicitWidth = 132
      end
      object Panel7: TPanel
        Left = 0
        Top = 148
        Width = 138
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 10
        ExplicitWidth = 132
      end
      object Value_A1: TEdit
        Tag = 6
        Left = 0
        Top = 156
        Width = 138
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A1 (radial)'
        Align = alTop
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 11
        OnKeyPress = NumericOnlyKeyPress
        ExplicitWidth = 132
      end
      object Value_A2: TEdit
        Tag = 6
        Left = 0
        Top = 172
        Width = 138
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A2 (transverse)'
        Align = alTop
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 12
        OnKeyPress = NumericOnlyKeyPress
        ExplicitWidth = 132
      end
      object Value_A3: TEdit
        Tag = 6
        Left = 0
        Top = 188
        Width = 138
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A3 (normal)'
        Align = alTop
        BevelEdges = []
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 13
        OnKeyPress = NumericOnlyKeyPress
        ExplicitWidth = 132
      end
    end
  end
  object TargetEdit: TButtonedEdit
    Left = 0
    Top = 0
    Width = 294
    Height = 23
    Hint = 'Target name (press left button to load from file)'
    Align = alTop
    Images = ImageList
    LeftButton.DisabledImageIndex = 3
    LeftButton.Hint = 
      'Load state vectors or orbital elements from text file downloaded' +
      ' from the Horizons online service (https://ssd.jpl.nasa.gov/hori' +
      'zons)'
    LeftButton.HotImageIndex = 1
    LeftButton.ImageIndex = 0
    LeftButton.PressedImageIndex = 2
    LeftButton.Visible = True
    ParentShowHint = False
    RightButton.DisabledImageIndex = 3
    RightButton.Enabled = False
    RightButton.Hint = 
      'Download ICRF/SSB state vectors from the Horizons online service' +
      ' (https://ssd.jpl.nasa.gov/horizons)'
    RightButton.HotImageIndex = 1
    RightButton.ImageIndex = 0
    RightButton.PressedImageIndex = 2
    RightButton.Visible = True
    ShowHint = True
    TabOrder = 0
    OnChange = TargetEditChange
    OnLeftButtonClick = TargetEditLeftButtonClick
    OnRightButtonClick = TargetEditRightButtonClick
    ExplicitWidth = 288
  end
  object CompBtn: TButton
    Left = 0
    Top = 455
    Width = 294
    Height = 25
    Align = alBottom
    Caption = 'Compute output state:'
    TabOrder = 4
    OnClick = CompBtnClick_Geometric
    ExplicitTop = 438
    ExplicitWidth = 288
  end
  object Panel_Output: TPanel
    Left = 0
    Top = 480
    Width = 294
    Height = 235
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 5
    ExplicitTop = 463
    ExplicitWidth = 288
    object Splitter3: TSplitter
      Left = 75
      Top = 0
      Height = 235
      ExplicitLeft = 120
      ExplicitTop = 112
      ExplicitHeight = 100
    end
    object Splitter4: TSplitter
      Left = 216
      Top = 0
      Height = 235
      Align = alRight
      ExplicitLeft = 160
      ExplicitTop = 152
      ExplicitHeight = 100
    end
    object Panel_ONames: TPanel
      Left = 0
      Top = 0
      Width = 75
      Height = 235
      Align = alLeft
      Constraints.MaxWidth = 100
      Constraints.MinWidth = 50
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      object Panel3: TPanel
        Left = 1
        Top = 1
        Width = 73
        Height = 20
        Align = alTop
        Caption = 'Element:'
        TabOrder = 10
      end
      object Name_SVY: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 146
        Width = 65
        Height = 16
        Hint = 'Velocity vector Y'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'V.Y:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 8
      end
      object Name_SVX: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 130
        Width = 65
        Height = 16
        Hint = 'Velocity vector X'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'V.X:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 7
      end
      object Name_SRZ: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 106
        Width = 65
        Height = 16
        Hint = 'Position vector Z'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'R.Z:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 5
      end
      object Name_SRY: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 90
        Width = 65
        Height = 16
        Hint = 'Position vector Y'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'R.Y:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 4
      end
      object Name_SRX: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 74
        Width = 65
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'R.X:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
      end
      object Name_SVZ: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 162
        Width = 65
        Height = 16
        Hint = 'Velocity vector Z'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'V.Z:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 9
      end
      object Panel5: TPanel
        Left = 1
        Top = 178
        Width = 73
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 6
      end
      object Name_SEpoch: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 21
        Width = 65
        Height = 16
        Hint = 'Epoch of osculating elements (TDB)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Epoch:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
      end
      object Name_SCenter: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 37
        Width = 65
        Height = 16
        Hint = 'Epoch of osculating elements (TDB)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Center:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
      end
      object Name_SFrame: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 53
        Width = 65
        Height = 16
        Hint = 'Epoch of osculating elements (TDB)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Frame:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
      end
      object Name_SA1: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 186
        Width = 65
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A1 (radial)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'A1'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 11
      end
      object Name_SA2: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 202
        Width = 65
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A2 (transverse)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'A2'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 12
      end
      object Name_SA3: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 218
        Width = 65
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A3 (normal)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'A3'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 13
      end
      object Panel17: TPanel
        Left = 1
        Top = 122
        Width = 73
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 14
      end
    end
    object Panel_OUnits: TPanel
      Left = 219
      Top = 0
      Width = 75
      Height = 235
      Align = alRight
      Constraints.MaxWidth = 100
      Constraints.MinWidth = 50
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      ExplicitLeft = 213
      object Panel23: TPanel
        Left = 1
        Top = 1
        Width = 73
        Height = 20
        Align = alTop
        Caption = 'Unit:'
        TabOrder = 10
      end
      object Unit_SVZ: TButton
        Left = 1
        Top = 162
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'AU/day'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 9
        OnClick = UnitClick_Speed
      end
      object Unit_SVY: TButton
        Left = 1
        Top = 146
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'AU/day'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 8
        OnClick = UnitClick_Speed
      end
      object Unit_SVX: TButton
        Left = 1
        Top = 130
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'AU/day'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 7
        OnClick = UnitClick_Speed
      end
      object Unit_SRZ: TButton
        Tag = 1
        Left = 1
        Top = 106
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'AU'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 5
        OnClick = UnitClick_Dist
      end
      object Unit_SRY: TButton
        Tag = 1
        Left = 1
        Top = 90
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'AU'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 4
        OnClick = UnitClick_Dist
      end
      object Unit_SRX: TButton
        Tag = 1
        Left = 1
        Top = 74
        Width = 73
        Height = 16
        Align = alBottom
        Caption = 'AU'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
        OnClick = UnitClick_Dist
      end
      object Panel8: TPanel
        Left = 1
        Top = 122
        Width = 73
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 6
      end
      object Unit_SEpoch: TButton
        Left = 1
        Top = 21
        Width = 73
        Height = 16
        Align = alTop
        Caption = 'Gregorian'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        OnClick = UnitClick_Epoch
      end
      object Unit_SCenter: TButton
        Left = 1
        Top = 37
        Width = 73
        Height = 16
        Align = alTop
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
      end
      object Unit_SFrame: TButton
        Left = 1
        Top = 53
        Width = 73
        Height = 16
        Align = alTop
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
      end
      object Panel12: TPanel
        Left = 1
        Top = 178
        Width = 73
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 11
      end
      object Unit_SA1: TButton
        Tag = 1
        Left = 1
        Top = 186
        Width = 73
        Height = 16
        Align = alBottom
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 12
      end
      object Unit_SA2: TButton
        Tag = 1
        Left = 1
        Top = 202
        Width = 73
        Height = 16
        Align = alBottom
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 13
      end
      object Unit_SA3: TButton
        Tag = 1
        Left = 1
        Top = 218
        Width = 73
        Height = 16
        Align = alBottom
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 14
      end
    end
    object Panel_OValues: TPanel
      Left = 78
      Top = 0
      Width = 138
      Height = 235
      Margins.Bottom = 0
      Align = alClient
      Alignment = taLeftJustify
      BevelOuter = bvNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Courier'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      ExplicitWidth = 132
      object Panel25: TPanel
        Left = 0
        Top = 0
        Width = 138
        Height = 20
        Hint = 'Press to switch between momentary and average values'
        Align = alTop
        Caption = 'Value:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 10
        ExplicitWidth = 132
      end
      object Panel6: TPanel
        Left = 0
        Top = 123
        Width = 138
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 6
        ExplicitWidth = 132
      end
      object Value_SVZ: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 163
        Width = 130
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 9
        ExplicitWidth = 124
      end
      object Value_SRX: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 75
        Width = 130
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
        ExplicitWidth = 124
      end
      object Value_SRY: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 91
        Width = 130
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 4
        ExplicitWidth = 124
      end
      object Value_SRZ: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 107
        Width = 130
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 5
        ExplicitWidth = 124
      end
      object Value_SVX: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 131
        Width = 130
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 7
        ExplicitWidth = 124
      end
      object Value_SVY: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 147
        Width = 130
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 8
        ExplicitWidth = 124
      end
      object Value_SEpoch: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 20
        Width = 130
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alTop
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        ExplicitWidth = 124
      end
      object Value_SCenter: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 36
        Width = 130
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alTop
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        ExplicitWidth = 124
      end
      object Value_SFrame: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 52
        Width = 130
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alTop
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        ExplicitWidth = 124
      end
      object Panel11: TPanel
        Left = 0
        Top = 179
        Width = 138
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 11
        ExplicitWidth = 132
      end
      object Value_SA1: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 187
        Width = 130
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A1 (radial)'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 12
        ExplicitWidth = 124
      end
      object Value_SA3: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 219
        Width = 130
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A3 (normal)'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 13
        ExplicitWidth = 124
      end
      object Value_SA2: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 203
        Width = 130
        Height = 16
        Hint = 'JPL/SBDB small-body nongravitational parameter A2 (transverse)'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 14
        ExplicitWidth = 124
      end
    end
  end
  object StartBtn: TButton
    Left = 0
    Top = 715
    Width = 294
    Height = 25
    Align = alBottom
    Caption = 'Save initial state'
    Enabled = False
    TabOrder = 6
    OnClick = StartBtnClick
    ExplicitTop = 698
    ExplicitWidth = 288
  end
  object ImageList: TImageList
    Left = 152
    Bitmap = {
      494C010104000800040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000002000000001002000000000000020
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000FFFF0000000000000000000000
      000000000000000000000000000000FFFF000000000000000000000000000000
      00000000000000000000000000000000000000FFFF0000000000000000000000
      000000000000000000000000000000FFFF000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000FFFFFF00FFFF
      FF000000000000000000000000000000000080808000FFFFFF00000000000000
      00000000000000000000FFFFFF00808080000000000000FFFF0000FFFF000000
      000080808000808080008080800000FFFF0000FFFF0080808000808080008080
      80008080800000FFFF0000FFFF00000000000000000000FFFF0000FFFF000000
      000080808000808080008080800000FFFF0000FFFF0080808000808080008080
      80008080800000FFFF0000FFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000008080800080808000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF008080800080808000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00808080008080800000000000000000000000000000FFFF000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000FFFF000000000000000000000000000000000000FFFF000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000FFFF0000000000000000000000000000000000000000000000
      0000000000000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000008080800000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000008080800000000000000000000000000000000000000000000000
      0000000000000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00000000000000000000000000000000008080
      8000FFFFFF000000000000000000000000000000000000000000000000000000
      000080808000FFFFFF0000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000008080800000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000008080800000000000000000000000000000000000000000000000
      0000000000000000000000000000FFFFFF000000000000000000FFFFFF000000
      00000000000000000000FFFFFF00000000000000000000000000000000008080
      8000FFFFFF000000000000000000000000000000000000000000000000000000
      000080808000FFFFFF0000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000008080800000000000000000000000000000000000000000000000
      0000FFFFFF000000000000000000FFFFFF00000000000000000000000000FFFF
      FF00000000008080800000000000000000000000000000000000000000000000
      0000000000000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00000000000000000000000000000000008080
      8000FFFFFF000000000000000000000000000000000000000000000000000000
      000080808000FFFFFF0000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000008080800000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000008080800000000000000000000000000000000000000000000000
      FF00000000000000000000000000FFFFFF0000000000C0C0C000000000000000
      0000FFFFFF0000000000FFFFFF000000000000000000FFFFFF00FFFFFF008080
      8000FFFFFF000000000000000000000000000000000000000000000000000000
      000080808000FFFFFF00FFFFFF00FFFFFF0000FFFF0000FFFF0000FFFF000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF000000000000FFFF0000FFFF000000000000FFFF0000FFFF0000FFFF000000
      0000FFFFFF0000000000000000000000000000000000FFFFFF0000000000FFFF
      FF000000000000FFFF0000FFFF00000000000000000000000000000000000000
      FF000000FF000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00000000008080800080808000808080008080
      8000FFFFFF000000000000000000000000000000000000000000000000000000
      0000808080008080800080808000FFFFFF000000000000FFFF0000FFFF000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF000000000000FFFF0000FFFF0000FFFF000000000000FFFF0000FFFF000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF000000000000FFFF0000FFFF0000FFFF00000000000000FF000000FF000000
      FF000000FF000000FF0000000000FFFFFF000000000000000000FFFFFF000000
      0000000000000000000000000000000000000000000080808000808080008080
      8000FFFFFF0000000000000000000000000000000000FFFFFF00FFFFFF00FFFF
      FF00808080008080800080808000808080000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000FFFFFF000000000000000000FFFFFF000000000000000000000000000000
      000000000000000000000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000FF0000000000FFFFFF00FFFFFF00FFFFFF000000
      0000FFFFFF00FFFFFF0000000000000000000000000000000000000000008080
      8000FFFFFF000000000000000000000000008080800080808000808080008080
      8000808080000000000000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000FFFFFF00FFFFFF000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000FFFFFF00FFFFFF000000
      000000000000000000000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000FF000000FF0000000000C0C0C000FFFFFF000000
      0000FFFFFF000000000000000000000000000000000000000000000000008080
      8000FFFFFF0000000000000000000000000080808000FFFFFF00000000008080
      8000FFFFFF000000000000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000FFFFFF000000000000FF
      FF00000000000000000000000000000000000000000000000000000000000000
      0000FFFFFF0000000000C0C0C000FFFFFF0000000000FFFFFF000000000000FF
      FF0000000000000000000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000FF0000000000FFFFFF00FFFFFF00FFFFFF000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000FFFFFF0000000000000000000000000080808000FFFFFF00808080008080
      8000FFFFFF00FFFFFF0000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000000000000000000000FF
      FF0000FFFF000000000000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000000000000000000000FF
      FF0000FFFF00000000000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000FFFFFF00FFFFFF00FFFFFF00FFFFFF008080800080808000000000008080
      800080808000FFFFFF00FFFFFF0000000000000000000000000000FFFF000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000FFFF0000FFFF000000000000000000000000000000000000FFFF000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000FFFF0000FFFF0000000000000000000000000000000000000000000000
      FF000000FF000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000808080008080
      80008080800080808000808080008080800080808000FFFFFF00000000000000
      00008080800080808000FFFFFF00FFFFFF000000000000FFFF0000FFFF000000
      000000000000000000000000000000FFFF0000FFFF0000000000000000000000
      00000000000000FFFF0000FFFF00000000000000000000FFFF0000FFFF000000
      000000000000000000000000000000FFFF0000FFFF0000000000000000000000
      00000000000000FFFF0000FFFF00000000000000000000000000000000000000
      FF00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000808080000000
      0000000000000000000000000000808080008080800000000000000000000000
      00000000000080808000808080000000000000FFFF0000000000000000000000
      000000000000000000000000000000FFFF000000000000000000000000000000
      000000000000000000000000000000FFFF0000FFFF0000000000000000000000
      000000000000000000000000000000FFFF000000000000000000000000000000
      000000000000000000000000000000FFFF000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000008080800000000000000000000000
      0000000000000000000000000000808080000000000000000000000000000000
      000000000000000000000000000080808000424D3E000000000000003E000000
      2800000040000000200000000100010000000000000100000000000000000000
      000000000000000000000000FFFFFF0000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000FF7EFF7EFFFFCF3C90019001FC008001
      C003C003FC00C003E003E003FC00E7F3E003E003FC00E7F3E003E003EC00E7F3
      E003E003E40087F000010001E00007F08000800000008780E007E0070001E707
      E00FE00F0003E727E00FE00F0007E703E027E027000FE021C073C073E3FFC030
      9E799E79E7FF9E797EFE7EFEEFFF7EFE00000000000000000000000000000000
      000000000000}
  end
  object OpenDialog: TOpenDialog
    Filter = 'Text files (*.txt)|*.txt|All files (*.*)|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 80
  end
end
