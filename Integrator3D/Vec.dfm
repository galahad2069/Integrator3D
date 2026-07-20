object VecForm: TVecForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Add integrand'
  ClientHeight = 776
  ClientWidth = 326
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
    Width = 326
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
    OnChange = CenterBoxChange
    OnDrawItem = ComboDrawItem
    ExplicitWidth = 320
  end
  object FrameBox: TComboBox
    Left = 0
    Top = 44
    Width = 326
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
    ExplicitWidth = 320
  end
  object Panel_Input: TPanel
    Left = 0
    Top = 65
    Width = 326
    Height = 42
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitWidth = 320
    object Splitter1: TSplitter
      Left = 82
      Top = 0
      Height = 42
      ExplicitLeft = 120
      ExplicitTop = 112
      ExplicitHeight = 100
    end
    object Splitter2: TSplitter
      Left = 241
      Top = 0
      Height = 42
      Align = alRight
      ExplicitLeft = 160
      ExplicitTop = 152
      ExplicitHeight = 100
    end
    object Panel_INames: TPanel
      Left = 0
      Top = 0
      Width = 82
      Height = 42
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
      object Panel_Name_Header: TPanel
        Left = 1
        Top = 1
        Width = 80
        Height = 20
        Align = alTop
        Caption = 'Element:'
        TabOrder = 1
      end
      object Name_Epoch: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 21
        Width = 72
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
    end
    object Panel_IUnits: TPanel
      Left = 244
      Top = 0
      Width = 82
      Height = 42
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
      ExplicitLeft = 238
      object Panel_Unit_Header: TPanel
        Left = 1
        Top = 1
        Width = 80
        Height = 20
        Align = alTop
        Caption = 'Unit:'
        TabOrder = 1
      end
      object Unit_Epoch: TButton
        Left = 1
        Top = 21
        Width = 80
        Height = 16
        Align = alTop
        Caption = 'Gregorian'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        OnClick = Unit_EpochClick
      end
    end
    object Panel_IValues: TPanel
      Left = 85
      Top = 0
      Width = 156
      Height = 42
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
      ExplicitWidth = 150
      object Panel_Value_Header: TPanel
        Left = 0
        Top = 0
        Width = 156
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
        ExplicitWidth = 150
      end
      object Value_Epoch: TEdit
        Left = 0
        Top = 20
        Width = 156
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
        ExplicitWidth = 150
      end
    end
  end
  object TargetEdit: TButtonedEdit
    Left = 0
    Top = 0
    Width = 326
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
    ExplicitWidth = 320
  end
  object CompBtn: TButton
    Left = 0
    Top = 343
    Width = 326
    Height = 25
    Align = alTop
    Caption = 'Compute output state:'
    TabOrder = 4
    OnClick = CompBtnClick_Geometric
    ExplicitWidth = 320
  end
  object Panel_Output: TPanel
    Left = 0
    Top = 368
    Width = 326
    Height = 383
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 5
    ExplicitWidth = 320
    ExplicitHeight = 366
    object Splitter3: TSplitter
      Left = 82
      Top = 0
      Height = 383
      ExplicitLeft = 120
      ExplicitTop = 112
      ExplicitHeight = 100
    end
    object Splitter4: TSplitter
      Left = 241
      Top = 0
      Height = 383
      Align = alRight
      ExplicitLeft = 160
      ExplicitTop = 152
      ExplicitHeight = 100
    end
    object Panel_ONames: TPanel
      Left = 0
      Top = 0
      Width = 82
      Height = 383
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
      ExplicitHeight = 366
      object Panel3: TPanel
        Left = 1
        Top = 1
        Width = 80
        Height = 20
        Align = alTop
        Caption = 'Element:'
        TabOrder = 0
      end
      object Name_SVY: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 149
        Width = 72
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
        TabOrder = 10
      end
      object Name_SVX: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 133
        Width = 72
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
        TabOrder = 9
      end
      object Name_SRZ: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 109
        Width = 72
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
        TabOrder = 7
      end
      object Name_SRY: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 93
        Width = 72
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
        TabOrder = 6
      end
      object Name_SRX: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 77
        Width = 72
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
        TabOrder = 5
      end
      object Name_SVZ: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 165
        Width = 72
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
        TabOrder = 11
      end
      object Name_SEpoch: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 21
        Width = 72
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
        TabOrder = 1
      end
      object Name_SCenter: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 37
        Width = 72
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
        TabOrder = 2
      end
      object Name_SFrame: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 53
        Width = 72
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
        TabOrder = 3
      end
      object Name_SA1: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 190
        Width = 72
        Height = 16
        Hint = 
          'JPL/SBDB small-body nongravitational parameter A1 (radial) -- it' +
          ' usually already covers solar radiation pressure (SRP), so the A' +
          'lbedo/AMRAT-based model is unnecessary if A1 is nonzero'
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
        TabOrder = 12
        ExplicitTop = 173
      end
      object Name_SA2: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 206
        Width = 72
        Height = 16
        Hint = 
          'JPL/SBDB small-body nongravitational parameter A2 (transverse) -' +
          ' Yarkovsky effect model parameter'
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
        TabOrder = 13
        ExplicitTop = 189
      end
      object Name_SA3: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 222
        Width = 72
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
        TabOrder = 14
        ExplicitTop = 205
      end
      object Panel17: TPanel
        Left = 1
        Top = 125
        Width = 80
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 8
      end
      object Name_SBC: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 366
        Width = 72
        Height = 16
        Hint = 
          'Inverse of the ballistic coefficient (atmospheric drag model par' +
          'ameter)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = '1/BC:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 24
        ExplicitTop = 349
      end
      object Panel1: TPanel
        Left = 1
        Top = 69
        Width = 80
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 4
      end
      object Panel5: TPanel
        Left = 1
        Top = 342
        Width = 80
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 22
        ExplicitTop = 325
      end
      object Panel7: TPanel
        Left = 1
        Top = 238
        Width = 80
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 15
        ExplicitTop = 221
      end
      object Name_SDT: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 326
        Width = 72
        Height = 16
        Hint = 
          'Outgassing time-lag DT (Horizons DT), days. g(r) is evaluated at' +
          ' the heliocentric distance DT days earlier, modelling the therma' +
          'l/rotational delay of the response. >0: outgassing peaks after p' +
          'erihelion; <0: before; 0: no lag.'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'DT'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 21
        ExplicitTop = 309
      end
      object Name_SALN: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 246
        Width = 72
        Height = 16
        Hint = 
          'g(r) scale factor '#945' (Horizons ALN). Normalises the Marsden law g' +
          '(r)='#945#183'(r/r0)^-m'#183'[1+(r/r0)^n]^-k. Dimensionless: 1 for the plain ' +
          '1/r^2 asteroid form, ~0.1113 for the standard water-ice curve.'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = #945
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 16
        ExplicitTop = 229
      end
      object Name_SR0: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 262
        Width = 72
        Height = 16
        Hint = 
          'g(r) scale distance r0 (Horizons R0), au. The reference heliocen' +
          'tric distance in the Marsden law; outgassing rolls off around it' +
          '. 1 au for the 1/r^2 form, 2.808 au for water ice.'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'r'#8320
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 17
        ExplicitTop = 245
      end
      object Name_SMM: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 278
        Width = 72
        Height = 16
        Hint = 
          'g(r) inner exponent m (Horizons NM). The near-Sun power law g ~ ' +
          '(r/r0)^-m. Dimensionless: 2 for the 1/r^2 (asteroid / simple-com' +
          'et) form, 2.15 for water ice.'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'm'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 18
        ExplicitTop = 261
      end
      object Name_SNN: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 294
        Width = 72
        Height = 16
        Hint = 
          'g(r) transition exponent n (Horizons NN). Sets the roll-off stee' +
          'pness through [1+(r/r0)^n]. Dimensionless: 5.093 for water ice. ' +
          'Inert unless k <> 0.'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'n'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 19
        ExplicitTop = 277
      end
      object Name_SKK: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 310
        Width = 72
        Height = 16
        Hint = 
          'g(r) roll-off exponent k (Horizons NK). The outer power on [1+(r' +
          '/r0)^n]^-k that cuts outgassing off beyond r0. Dimensionless: 4.' +
          '6142 for water ice; 0 reduces g(r) to the plain (r/r0)^-m power ' +
          'law.'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'k'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 20
        ExplicitTop = 293
      end
      object Name_SAMRAT: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 350
        Width = 72
        Height = 16
        Hint = 
          'Area-to-mass ratio scaled using the reflectivity parameter (Sola' +
          'r radiation pressure model parameter)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alBottom
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'CR_AMRAT:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 23
        ExplicitTop = 333
      end
    end
    object Panel_OUnits: TPanel
      Left = 244
      Top = 0
      Width = 82
      Height = 383
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
      ExplicitLeft = 238
      ExplicitHeight = 366
      object Panel23: TPanel
        Left = 1
        Top = 1
        Width = 80
        Height = 20
        Align = alTop
        Caption = 'Unit:'
        TabOrder = 0
      end
      object Unit_SVZ: TButton
        Left = 1
        Top = 165
        Width = 80
        Height = 16
        Align = alTop
        Caption = 'km/s'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 11
        OnClick = UnitClick_Speed
      end
      object Unit_SVY: TButton
        Left = 1
        Top = 149
        Width = 80
        Height = 16
        Align = alTop
        Caption = 'km/s'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 10
        OnClick = UnitClick_Speed
      end
      object Unit_SVX: TButton
        Left = 1
        Top = 133
        Width = 80
        Height = 16
        Align = alTop
        Caption = 'km/s'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 9
        OnClick = UnitClick_Speed
      end
      object Unit_SRZ: TButton
        Tag = 1
        Left = 1
        Top = 109
        Width = 80
        Height = 16
        Align = alTop
        Caption = 'km'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 7
        OnClick = UnitClick_Dist
      end
      object Unit_SRY: TButton
        Tag = 1
        Left = 1
        Top = 93
        Width = 80
        Height = 16
        Align = alTop
        Caption = 'km'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 6
        OnClick = UnitClick_Dist
      end
      object Unit_SRX: TButton
        Tag = 1
        Left = 1
        Top = 77
        Width = 80
        Height = 16
        Align = alTop
        Caption = 'km'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 5
        OnClick = UnitClick_Dist
      end
      object Panel8: TPanel
        Left = 1
        Top = 125
        Width = 80
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 8
      end
      object Unit_SEpoch: TButton
        Left = 1
        Top = 21
        Width = 80
        Height = 16
        Align = alTop
        Caption = 'Gregorian'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnClick = UnitClick_Epoch
      end
      object Unit_SCenter: TButton
        Left = 1
        Top = 37
        Width = 80
        Height = 16
        Align = alTop
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
      end
      object Unit_SFrame: TButton
        Left = 1
        Top = 53
        Width = 80
        Height = 16
        Align = alTop
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
      end
      object Panel12: TPanel
        Left = 1
        Top = 342
        Width = 80
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 22
        ExplicitTop = 325
      end
      object Unit_SA1: TButton
        Tag = 4
        Left = 1
        Top = 190
        Width = 80
        Height = 16
        Hint = 'kilometer(s) per square second'
        Align = alBottom
        Caption = 'km/s'#178
        ParentShowHint = False
        ShowHint = True
        TabOrder = 12
        OnClick = UnitClick_Accel
        ExplicitTop = 173
      end
      object Unit_SA2: TButton
        Tag = 4
        Left = 1
        Top = 206
        Width = 80
        Height = 16
        Align = alBottom
        Caption = 'km/s'#178
        ParentShowHint = False
        ShowHint = True
        TabOrder = 13
        OnClick = UnitClick_Accel
        ExplicitTop = 189
      end
      object Unit_SA3: TButton
        Tag = 4
        Left = 1
        Top = 222
        Width = 80
        Height = 16
        Align = alBottom
        Caption = 'km/s'#178
        ParentShowHint = False
        ShowHint = True
        TabOrder = 14
        OnClick = UnitClick_Accel
        ExplicitTop = 205
      end
      object Unit_SBC: TButton
        Tag = 1
        Left = 1
        Top = 366
        Width = 80
        Height = 16
        Hint = 'Square kilometer(s) per kilogram'
        Align = alBottom
        Caption = 'km'#178'/kg'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 24
        OnClick = UnitClick_IBC
        ExplicitTop = 349
      end
      object Panel4: TPanel
        Left = 1
        Top = 69
        Width = 80
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 4
      end
      object Panel10: TPanel
        Left = 1
        Top = 238
        Width = 80
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 15
        ExplicitTop = 221
      end
      object Unit_SDT: TButton
        Left = 1
        Top = 326
        Width = 80
        Height = 16
        Align = alBottom
        Caption = 'sec'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 21
        OnClick = UnitClick_Time
        ExplicitTop = 309
      end
      object Unit_SALN: TButton
        Tag = 1
        Left = 1
        Top = 246
        Width = 80
        Height = 16
        Align = alBottom
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 16
        ExplicitTop = 229
      end
      object Unit_SR0: TButton
        Left = 1
        Top = 262
        Width = 80
        Height = 16
        Align = alBottom
        Caption = 'km'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 17
        OnClick = UnitClick_Dist
        ExplicitTop = 245
      end
      object Unit_SMM: TButton
        Tag = 1
        Left = 1
        Top = 278
        Width = 80
        Height = 16
        Align = alBottom
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 18
        ExplicitTop = 261
      end
      object Unit_SNN: TButton
        Tag = 1
        Left = 1
        Top = 294
        Width = 80
        Height = 16
        Align = alBottom
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 19
        ExplicitTop = 277
      end
      object Unit_SKK: TButton
        Tag = 1
        Left = 1
        Top = 310
        Width = 80
        Height = 16
        Align = alBottom
        Enabled = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 20
        ExplicitTop = 293
      end
      object Unit_SAMRAT: TButton
        Tag = 1
        Left = 1
        Top = 350
        Width = 80
        Height = 16
        Hint = 'Square kilometer(s) per kilogram'
        Align = alBottom
        Caption = 'km'#178'/kg'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 23
        OnClick = UnitClick_IBC
        ExplicitTop = 333
      end
    end
    object Panel_OValues: TPanel
      Left = 85
      Top = 0
      Width = 156
      Height = 383
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
      ExplicitWidth = 150
      ExplicitHeight = 366
      object Panel25: TPanel
        Left = 0
        Top = 0
        Width = 156
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
        ExplicitWidth = 150
      end
      object Panel6: TPanel
        Left = 0
        Top = 124
        Width = 156
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 8
        ExplicitWidth = 150
      end
      object Value_SVZ: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 164
        Width = 148
        Height = 16
        Hint = 'Velocity vector Z'
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
        TabOrder = 11
        ExplicitWidth = 142
      end
      object Value_SRX: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 76
        Width = 148
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
        TabOrder = 5
        ExplicitWidth = 142
      end
      object Value_SRY: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 92
        Width = 148
        Height = 16
        Hint = 'Position vector Y'
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
        TabOrder = 6
        ExplicitWidth = 142
      end
      object Value_SRZ: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 108
        Width = 148
        Height = 16
        Hint = 'Position vector Z'
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
        TabOrder = 7
        ExplicitWidth = 142
      end
      object Value_SVX: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 132
        Width = 148
        Height = 16
        Hint = 'Velocity vector X'
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
        TabOrder = 9
        ExplicitWidth = 142
      end
      object Value_SVY: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 148
        Width = 148
        Height = 16
        Hint = 'Velocity vector Y'
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
        TabOrder = 10
        ExplicitWidth = 142
      end
      object Value_SEpoch: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 20
        Width = 148
        Height = 16
        Hint = 'Epoch'
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
        ExplicitWidth = 142
      end
      object Value_SCenter: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 36
        Width = 148
        Height = 16
        Hint = 'Coordinate center'
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
        ExplicitWidth = 142
      end
      object Value_SFrame: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 52
        Width = 148
        Height = 16
        Hint = 'Coordinate frame'
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
        TabOrder = 3
        ExplicitWidth = 142
      end
      object Panel11: TPanel
        Left = 0
        Top = 343
        Width = 156
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 22
        ExplicitTop = 326
        ExplicitWidth = 150
      end
      object Value_SA1: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 191
        Width = 148
        Height = 16
        Hint = 
          'JPL/SBDB small-body nongravitational parameter A1 (radial) -- it' +
          ' usually already covers solar radiation pressure (SRP), so the A' +
          'lbedo/AMRAT-based model is unnecessary if A1 is nonzero'
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
        ExplicitTop = 174
        ExplicitWidth = 142
      end
      object Value_SA3: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 223
        Width = 148
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
        TabOrder = 14
        ExplicitTop = 206
        ExplicitWidth = 142
      end
      object Value_SA2: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 207
        Width = 148
        Height = 16
        Hint = 
          'JPL/SBDB small-body nongravitational parameter A2 (transverse) -' +
          ' Yarkovsky effect model parameter'
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
        ExplicitTop = 190
        ExplicitWidth = 142
      end
      object Value_SBC: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 367
        Width = 148
        Height = 16
        Hint = 
          'Inverse of the ballistic coefficient (atmospheric drag model par' +
          'ameter)'
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
        TabOrder = 24
        ExplicitTop = 350
        ExplicitWidth = 142
      end
      object Panel2: TPanel
        Left = 0
        Top = 68
        Width = 156
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 4
        ExplicitWidth = 150
      end
      object Panel9: TPanel
        Left = 0
        Top = 239
        Width = 156
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 21
        ExplicitTop = 222
        ExplicitWidth = 150
      end
      object Value_SDT: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 327
        Width = 148
        Height = 16
        Hint = 
          'Outgassing time-lag DT (Horizons DT), days. g(r) is evaluated at' +
          ' the heliocentric distance DT days earlier, modelling the therma' +
          'l/rotational delay of the response. >0: outgassing peaks after p' +
          'erihelion; <0: before; 0: no lag.'
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
        TabOrder = 20
        ExplicitTop = 310
        ExplicitWidth = 142
      end
      object Value_SALN: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 247
        Width = 148
        Height = 16
        Hint = 
          'g(r) scale factor '#945' (Horizons ALN). Normalises the Marsden law g' +
          '(r)='#945#183'(r/r0)^-m'#183'[1+(r/r0)^n]^-k. Dimensionless: 1 for the plain ' +
          '1/r^2 asteroid form, ~0.1113 for the standard water-ice curve.'
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
        TabOrder = 15
        ExplicitTop = 230
        ExplicitWidth = 142
      end
      object Value_SR0: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 263
        Width = 148
        Height = 16
        Hint = 
          'g(r) scale distance r0 (Horizons R0), au. The reference heliocen' +
          'tric distance in the Marsden law; outgassing rolls off around it' +
          '. 1 au for the 1/r^2 form, 2.808 au for water ice.'
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
        TabOrder = 16
        ExplicitTop = 246
        ExplicitWidth = 142
      end
      object Value_SMM: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 279
        Width = 148
        Height = 16
        Hint = 
          'g(r) inner exponent m (Horizons NM). The near-Sun power law g ~ ' +
          '(r/r0)^-m. Dimensionless: 2 for the 1/r^2 (asteroid / simple-com' +
          'et) form, 2.15 for water ice.'
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
        TabOrder = 17
        ExplicitTop = 262
        ExplicitWidth = 142
      end
      object Value_SNN: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 295
        Width = 148
        Height = 16
        Hint = 
          'g(r) transition exponent n (Horizons NN). Sets the roll-off stee' +
          'pness through [1+(r/r0)^n]. Dimensionless: 5.093 for water ice. ' +
          'Inert unless k <> 0.'
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
        TabOrder = 18
        ExplicitTop = 278
        ExplicitWidth = 142
      end
      object Value_SKK: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 311
        Width = 148
        Height = 16
        Hint = 
          'g(r) roll-off exponent k (Horizons NK). The outer power on [1+(r' +
          '/r0)^n]^-k that cuts outgassing off beyond r0. Dimensionless: 4.' +
          '6142 for water ice; 0 reduces g(r) to the plain (r/r0)^-m power ' +
          'law.'
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
        TabOrder = 19
        ExplicitTop = 294
        ExplicitWidth = 142
      end
      object Value_SAMRAT: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 351
        Width = 148
        Height = 16
        Hint = 
          'Area-to-mass ratio scaled using the reflectivity parameter (Sola' +
          'r radiation pressure model parameter)'
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
        TabOrder = 23
        ExplicitTop = 334
        ExplicitWidth = 142
      end
    end
  end
  object StartBtn: TButton
    Left = 0
    Top = 751
    Width = 326
    Height = 25
    Align = alBottom
    Caption = 'Save initial state'
    Enabled = False
    TabOrder = 6
    OnClick = StartBtnClick
    ExplicitTop = 734
    ExplicitWidth = 320
  end
  object PageControl: TPageControl
    Left = 0
    Top = 107
    Width = 326
    Height = 236
    ActivePage = TabSheet3
    Align = alTop
    TabOrder = 7
    OnResize = PageControlResize
    ExplicitWidth = 320
    object TabSheet1: TTabSheet
      Caption = 'Vectorial'
      object Splitter5: TSplitter
        Left = 78
        Top = 0
        Height = 206
        ExplicitLeft = 83
        ExplicitHeight = 340
      end
      object Splitter6: TSplitter
        Left = 237
        Top = 0
        Height = 206
        Align = alRight
        ExplicitLeft = 160
        ExplicitTop = 152
        ExplicitHeight = 100
      end
      object Panel_vINames: TPanel
        Left = 0
        Top = 0
        Width = 78
        Height = 206
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
        object Name_RX: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 1
          Width = 68
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
          TabOrder = 0
        end
        object Name_RY: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 17
          Width = 68
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
          TabOrder = 1
        end
        object Name_RZ: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 33
          Width = 68
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
          TabOrder = 2
        end
        object Panel37: TPanel
          Left = 1
          Top = 49
          Width = 76
          Height = 16
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 3
        end
        object Name_VX: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 65
          Width = 68
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
          TabOrder = 4
        end
        object Name_VY: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 81
          Width = 68
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
          TabOrder = 5
        end
        object Name_VZ: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 97
          Width = 68
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
          TabOrder = 6
        end
      end
      object Panel_vIValues: TPanel
        Left = 81
        Top = 0
        Width = 156
        Height = 206
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
        object Value_RX: TEdit
          Left = 0
          Top = 0
          Width = 156
          Height = 16
          Hint = 'Position vector X'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_RY: TEdit
          Tag = 1
          Left = 0
          Top = 16
          Width = 156
          Height = 16
          Hint = 'Position vector Y'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_RZ: TEdit
          Tag = 2
          Left = 0
          Top = 32
          Width = 156
          Height = 16
          Hint = 'Position vector Z'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
          OnKeyPress = NumericOnlyKeyPress
        end
        object Panel49: TPanel
          Left = 0
          Top = 48
          Width = 156
          Height = 16
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 3
        end
        object Value_VX: TEdit
          Tag = 4
          Left = 0
          Top = 64
          Width = 156
          Height = 16
          Hint = 'Velocity vector X'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 4
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_VY: TEdit
          Tag = 5
          Left = 0
          Top = 80
          Width = 156
          Height = 16
          Hint = 'Velocity vector Y'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 5
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_VZ: TEdit
          Tag = 6
          Left = 0
          Top = 96
          Width = 156
          Height = 16
          Hint = 'Velocity vector Z'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 6
          OnKeyPress = NumericOnlyKeyPress
        end
      end
      object Panel_vIUnits: TPanel
        Left = 240
        Top = 0
        Width = 78
        Height = 206
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
        object Unit_RX: TButton
          Tag = 1
          Left = 1
          Top = 1
          Width = 76
          Height = 16
          Align = alTop
          Caption = 'AU'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnClick = UnitClick_Dist
        end
        object Unit_RY: TButton
          Tag = 1
          Left = 1
          Top = 17
          Width = 76
          Height = 16
          Align = alTop
          Caption = 'AU'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = UnitClick_Dist
        end
        object Unit_RZ: TButton
          Tag = 1
          Left = 1
          Top = 33
          Width = 76
          Height = 16
          Align = alTop
          Caption = 'AU'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
          OnClick = UnitClick_Dist
        end
        object Panel54: TPanel
          Left = 1
          Top = 49
          Width = 76
          Height = 16
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 3
        end
        object Unit_VX: TButton
          Left = 1
          Top = 65
          Width = 76
          Height = 16
          Align = alTop
          Caption = 'AU/day'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 4
          OnClick = UnitClick_Speed
        end
        object Unit_VY: TButton
          Left = 1
          Top = 81
          Width = 76
          Height = 16
          Align = alTop
          Caption = 'AU/day'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 5
          OnClick = UnitClick_Speed
        end
        object Unit_VZ: TButton
          Left = 1
          Top = 97
          Width = 76
          Height = 16
          Align = alTop
          Caption = 'AU/day'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 6
          OnClick = UnitClick_Speed
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Conical'
      ImageIndex = 1
      object Splitter7: TSplitter
        Left = 78
        Top = 0
        Height = 206
        ExplicitLeft = 83
        ExplicitHeight = 340
      end
      object Splitter8: TSplitter
        Left = 237
        Top = 0
        Height = 206
        Align = alRight
        ExplicitLeft = 359
        ExplicitHeight = 340
      end
      object Panel_cINames: TPanel
        Left = 0
        Top = 0
        Width = 78
        Height = 206
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
        object Name_e: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 61
          Width = 68
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
          TabOrder = 2
        end
        object Name_TPP: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 157
          Width = 68
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
          TabOrder = 8
        end
        object Name_Incl: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 141
          Width = 68
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
          TabOrder = 7
        end
        object Name_Node: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 125
          Width = 68
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
          TabOrder = 6
        end
        object Name_Peri: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 109
          Width = 68
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
          TabOrder = 5
        end
        object Name_q: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 77
          Width = 68
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
          TabOrder = 3
        end
        object Name_Mean: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 17
          Width = 68
          Height = 16
          Hint = 'Mean anomaly'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'Mean:'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
        end
        object Name_True: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 1
          Width = 68
          Height = 16
          Hint = 'True anomaly'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'True:'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
        end
        object Name_Period: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 189
          Width = 68
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
          TabOrder = 10
        end
        object Name_n: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 173
          Width = 68
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
          TabOrder = 9
        end
        object Name_a: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 93
          Width = 68
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
          TabOrder = 4
        end
      end
      object Panel_cIUnits: TPanel
        Left = 240
        Top = 0
        Width = 78
        Height = 206
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
        object Unit_TPP: TButton
          Left = 1
          Top = 157
          Width = 76
          Height = 16
          Align = alBottom
          Caption = 'Gregorian'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 8
          OnClick = UnitClick_Epoch
        end
        object Unit_Period: TButton
          Left = 1
          Top = 189
          Width = 76
          Height = 16
          Align = alBottom
          Caption = 'day(s)'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 10
          OnClick = UnitClick_Time
        end
        object Unit_n: TButton
          Tag = 6
          Left = 1
          Top = 173
          Width = 76
          Height = 16
          Align = alBottom
          Caption = 'deg/day'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 9
          OnClick = UnitClick_AnglePerTime
        end
        object Unit_a: TButton
          Left = 1
          Top = 93
          Width = 76
          Height = 16
          Align = alBottom
          Caption = 'AU'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 4
          OnClick = UnitClick_Dist
        end
        object Unit_Incl: TButton
          Tag = 1
          Left = 1
          Top = 141
          Width = 76
          Height = 16
          Align = alBottom
          Caption = 'deg'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 7
          OnClick = UnitClick_Angle
        end
        object Unit_Node: TButton
          Tag = 1
          Left = 1
          Top = 125
          Width = 76
          Height = 16
          Align = alBottom
          Caption = 'deg'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 6
          OnClick = UnitClick_Angle
        end
        object Unit_Peri: TButton
          Tag = 1
          Left = 1
          Top = 109
          Width = 76
          Height = 16
          Align = alBottom
          Caption = 'deg'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 5
          OnClick = UnitClick_Angle
        end
        object Unit_q: TButton
          Left = 1
          Top = 77
          Width = 76
          Height = 16
          Align = alBottom
          Caption = 'AU'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 3
          OnClick = UnitClick_Dist
        end
        object Button31: TButton
          Left = 1
          Top = 61
          Width = 76
          Height = 16
          Align = alBottom
          Enabled = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
        end
        object Unit_True: TButton
          Tag = 1
          Left = 1
          Top = 1
          Width = 76
          Height = 16
          Align = alTop
          Caption = 'deg'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnClick = UnitClick_Angle
        end
        object Unit_Mean: TButton
          Tag = 1
          Left = 1
          Top = 17
          Width = 76
          Height = 16
          Align = alTop
          Caption = 'deg'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = UnitClick_Angle
        end
      end
      object Panel_cIValues: TPanel
        Left = 81
        Top = 0
        Width = 156
        Height = 206
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
        TabOrder = 2
        object Value_e: TEdit
          Left = 0
          Top = 62
          Width = 156
          Height = 16
          Hint = 'Eccentricity'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_q: TEdit
          Left = 0
          Top = 78
          Width = 156
          Height = 16
          Hint = 'Periapsis distance'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 3
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_Peri: TEdit
          Left = 0
          Top = 110
          Width = 156
          Height = 16
          Hint = 'Argument of periapsis'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 5
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_Node: TEdit
          Left = 0
          Top = 126
          Width = 156
          Height = 16
          Hint = 'Argument of ascending node'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 6
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_Incl: TEdit
          Left = 0
          Top = 142
          Width = 156
          Height = 16
          Hint = 'Inclination'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 7
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_TPP: TEdit
          Left = 0
          Top = 158
          Width = 156
          Height = 16
          Hint = 'Time of periapsis passage (TDB)'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 8
        end
        object Value_a: TEdit
          Left = 0
          Top = 94
          Width = 156
          Height = 16
          Hint = 'Semi-major axis'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 4
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_n: TEdit
          Left = 0
          Top = 174
          Width = 156
          Height = 16
          Hint = 'Mean motion'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 9
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_Period: TEdit
          Left = 0
          Top = 190
          Width = 156
          Height = 16
          Hint = 'Orbital period'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 10
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_True: TEdit
          Left = 0
          Top = 0
          Width = 156
          Height = 16
          Hint = 'True anomaly'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnKeyPress = NumericOnlyKeyPress
        end
        object Value_Mean: TEdit
          Left = 0
          Top = 16
          Width = 156
          Height = 16
          Hint = 'Mean anomaly'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnKeyPress = NumericOnlyKeyPress
        end
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Non-gravitational'
      ImageIndex = 2
      object Splitter9: TSplitter
        Left = 78
        Top = 0
        Height = 206
        ExplicitLeft = 83
        ExplicitHeight = 340
      end
      object Splitter10: TSplitter
        Left = 315
        Top = 0
        Height = 206
        Align = alRight
        ExplicitLeft = 359
        ExplicitHeight = 340
      end
      object Splitter11: TSplitter
        Left = 234
        Top = 0
        Height = 206
        Align = alRight
        ExplicitLeft = 160
        ExplicitTop = 152
        ExplicitHeight = 100
      end
      object Panel_nINames: TPanel
        Left = 0
        Top = 0
        Width = 78
        Height = 206
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
        object Name_NN: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 105
          Width = 68
          Height = 16
          Hint = 
            'g(r) transition exponent n (Horizons NN). Sets the roll-off stee' +
            'pness through [1+(r/r0)^n]. Dimensionless: 5.093 for water ice. ' +
            'Inert unless k <> 0.'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'n:'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 7
        end
        object Name_MM: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 89
          Width = 68
          Height = 16
          Hint = 
            'g(r) inner exponent m (Horizons NM). The near-Sun power law g ~ ' +
            '(r/r0)^-m. Dimensionless: 2 for the 1/r^2 (asteroid / simple-com' +
            'et) form, 2.15 for water ice.'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'm:'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 6
        end
        object Name_R0: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 73
          Width = 68
          Height = 16
          Hint = 
            'g(r) scale distance r0 (Horizons R0), au. The reference heliocen' +
            'tric distance in the Marsden law; outgassing rolls off around it' +
            '. 1 au for the 1/r^2 form, 2.808 au for water ice.'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'r'#8320':'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 5
        end
        object Name_ALN: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 57
          Width = 68
          Height = 16
          Hint = 
            'g(r) scale factor '#945' (Horizons ALN). Normalises the Marsden law g' +
            '(r)='#945#183'(r/r0)^-m'#183'[1+(r/r0)^n]^-k. Dimensionless: 1 for the plain ' +
            '1/r^2 asteroid form, ~0.1113 for the standard water-ice curve.'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = #945':'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 4
        end
        object Name_DT: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 137
          Width = 68
          Height = 16
          Hint = 
            'Outgassing time-lag DT (Horizons DT), days. g(r) is evaluated at' +
            ' the heliocentric distance DT days earlier, modelling the therma' +
            'l/rotational delay of the response. >0: outgassing peaks after p' +
            'erihelion; <0: before; 0: no lag.'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'DT:'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 9
        end
        object Name_KK: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 121
          Width = 68
          Height = 16
          Hint = 
            'g(r) roll-off exponent k (Horizons NK). The outer power on [1+(r' +
            '/r0)^n]^-k that cuts outgassing off beyond r0. Dimensionless: 4.' +
            '6142 for water ice; 0 reduces g(r) to the plain (r/r0)^-m power ' +
            'law.'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'k:'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 8
        end
        object Name_A1: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 1
          Width = 68
          Height = 16
          Hint = 
            'JPL/SBDB small-body nongravitational parameter A1 (radial) -- it' +
            ' usually already covers solar radiation pressure (SRP), so the A' +
            'lbedo/AMRAT-based model is unnecessary if A1 is nonzero'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'A1:'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
        end
        object Name_A2: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 17
          Width = 68
          Height = 16
          Hint = 
            'JPL/SBDB small-body nongravitational parameter A2 (transverse) -' +
            ' Yarkovsky effect model parameter'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'A2:'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
        end
        object Name_A3: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 33
          Width = 68
          Height = 16
          Hint = 'JPL/SBDB small-body nongravitational parameter A3 (normal)'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'A3:'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
        end
        object Name_BC: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 189
          Width = 68
          Height = 16
          Hint = 'Ballistic coefficient (atmospheric drag model parameter)'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alBottom
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'BC'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 12
        end
        object Panel21: TPanel
          Left = 1
          Top = 49
          Width = 76
          Height = 8
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 3
        end
        object Name_AMRAT: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 173
          Width = 68
          Height = 16
          Hint = 'Area-to-mass ratio (Solar radiation pressure model parameter)'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alBottom
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'AMRAT:'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 11
        end
        object Name_Albedo: TPanel
          AlignWithMargins = True
          Left = 1
          Top = 157
          Width = 68
          Height = 16
          Hint = 
            'Albedo (the fraction of sunlight reflected by the surface, Solar' +
            ' radiation pressure model parameter)'
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alBottom
          Alignment = taRightJustify
          BevelOuter = bvNone
          Caption = 'Albedo:'
          Padding.Right = 8
          ParentShowHint = False
          ShowHint = True
          TabOrder = 10
        end
      end
      object Panel_nIValues: TPanel
        Left = 81
        Top = 0
        Width = 153
        Height = 206
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
        ExplicitWidth = 147
        object Value_ALN: TEdit
          Left = 0
          Top = 56
          Width = 153
          Height = 16
          Hint = 
            'g(r) scale factor '#945' (Horizons ALN). Normalises the Marsden law g' +
            '(r)='#945#183'(r/r0)^-m'#183'[1+(r/r0)^n]^-k. Dimensionless: 1 for the plain ' +
            '1/r^2 asteroid form, ~0.1113 for the standard water-ice curve.'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 4
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 147
        end
        object Value_R0: TEdit
          Left = 0
          Top = 72
          Width = 153
          Height = 16
          Hint = 
            'g(r) scale distance r0 (Horizons R0), au. The reference heliocen' +
            'tric distance in the Marsden law; outgassing rolls off around it' +
            '. 1 au for the 1/r^2 form, 2.808 au for water ice.'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 5
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 147
        end
        object Value_MM: TEdit
          Left = 0
          Top = 88
          Width = 153
          Height = 16
          Hint = 
            'g(r) inner exponent m (Horizons NM). The near-Sun power law g ~ ' +
            '(r/r0)^-m. Dimensionless: 2 for the 1/r^2 (asteroid / simple-com' +
            'et) form, 2.15 for water ice.'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 6
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 147
        end
        object Value_NN: TEdit
          Left = 0
          Top = 104
          Width = 153
          Height = 16
          Hint = 
            'g(r) transition exponent n (Horizons NN). Sets the roll-off stee' +
            'pness through [1+(r/r0)^n]. Dimensionless: 5.093 for water ice. ' +
            'Inert unless k <> 0.'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 7
          ExplicitWidth = 147
        end
        object Value_KK: TEdit
          Left = 0
          Top = 120
          Width = 153
          Height = 16
          Hint = 
            'g(r) roll-off exponent k (Horizons NK). The outer power on [1+(r' +
            '/r0)^n]^-k that cuts outgassing off beyond r0. Dimensionless: 4.' +
            '6142 for water ice; 0 reduces g(r) to the plain (r/r0)^-m power ' +
            'law.'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 8
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 147
        end
        object Value_DT: TEdit
          Left = 0
          Top = 136
          Width = 153
          Height = 16
          Hint = 
            'Outgassing time-lag DT (Horizons DT), days. g(r) is evaluated at' +
            ' the heliocentric distance DT days earlier, modelling the therma' +
            'l/rotational delay of the response. >0: outgassing peaks after p' +
            'erihelion; <0: before; 0: no lag.'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 9
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 147
        end
        object Value_A1: TEdit
          Tag = 6
          Left = 0
          Top = 0
          Width = 153
          Height = 16
          Hint = 
            'JPL/SBDB small-body nongravitational parameter A1 (radial) -- it' +
            ' usually already covers solar radiation pressure (SRP), so the A' +
            'lbedo/AMRAT-based model is unnecessary if A1 is nonzero'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 147
        end
        object Value_A2: TEdit
          Tag = 6
          Left = 0
          Top = 16
          Width = 153
          Height = 16
          Hint = 
            'JPL/SBDB small-body nongravitational parameter A2 (transverse) -' +
            ' Yarkovsky effect model parameter'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 147
        end
        object Value_A3: TEdit
          Tag = 6
          Left = 0
          Top = 32
          Width = 153
          Height = 16
          Hint = 'JPL/SBDB small-body nongravitational parameter A3 (normal)'
          Align = alTop
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 147
        end
        object Value_BC: TEdit
          Tag = 6
          Left = 0
          Top = 190
          Width = 153
          Height = 16
          Hint = 'Ballistic coefficient (atmospheric drag model parameter)'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 12
          OnDblClick = ShowHlp
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 147
        end
        object Panel22: TPanel
          Left = 0
          Top = 48
          Width = 153
          Height = 8
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 3
          ExplicitWidth = 147
        end
        object Value_AMRAT: TEdit
          Tag = 6
          Left = 0
          Top = 174
          Width = 153
          Height = 16
          Hint = 'Area-to-mass ratio (Solar radiation pressure model parameter)'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 11
          OnDblClick = ShowHlp
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 147
        end
        object Value_Albedo: TEdit
          Tag = 6
          Left = 0
          Top = 158
          Width = 153
          Height = 16
          Hint = 'Albedo (the fraction of sunlight reflected by the surface)'
          Align = alBottom
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 10
          OnDblClick = ShowHlp
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 147
        end
      end
      object Panel_nIUnits: TPanel
        Left = 237
        Top = 0
        Width = 78
        Height = 206
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
        ExplicitLeft = 231
        object Unit_NN: TButton
          Left = 1
          Top = 105
          Width = 76
          Height = 16
          Align = alTop
          Enabled = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 7
        end
        object Unit_DT: TButton
          Tag = 2
          Left = 1
          Top = 137
          Width = 76
          Height = 16
          Align = alTop
          Caption = 'day(s)'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 9
          OnClick = UnitClick_Time
        end
        object Unit_KK: TButton
          Left = 1
          Top = 121
          Width = 76
          Height = 16
          Align = alTop
          Enabled = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 8
        end
        object Unit_MM: TButton
          Tag = 1
          Left = 1
          Top = 89
          Width = 76
          Height = 16
          Align = alTop
          Enabled = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 6
        end
        object Unit_R0: TButton
          Tag = 1
          Left = 1
          Top = 73
          Width = 76
          Height = 16
          Align = alTop
          Caption = 'AU'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 5
          OnClick = UnitClick_Dist
        end
        object Unit_ALN: TButton
          Tag = 1
          Left = 1
          Top = 57
          Width = 76
          Height = 16
          Align = alTop
          Enabled = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 4
        end
        object Unit_A3: TButton
          Tag = 6
          Left = 1
          Top = 33
          Width = 76
          Height = 16
          Hint = 'JPL/SBDB small-body nongravitational parameter A3 (normal)'
          Align = alTop
          Caption = 'AU/day'#178
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
          OnClick = UnitClick_Accel
        end
        object Unit_A2: TButton
          Tag = 6
          Left = 1
          Top = 17
          Width = 76
          Height = 16
          Hint = 'JPL/SBDB small-body nongravitational parameter A2 (transverse)'
          Align = alTop
          Caption = 'AU/day'#178
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = UnitClick_Accel
        end
        object Unit_A1: TButton
          Tag = 6
          Left = 1
          Top = 1
          Width = 76
          Height = 16
          Hint = 'JPL/SBDB small-body nongravitational parameter A1 (radial)'
          Align = alTop
          Caption = 'AU/day'#178
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnClick = UnitClick_Accel
        end
        object Unit_BC: TButton
          Left = 1
          Top = 189
          Width = 76
          Height = 16
          Hint = 'Ballistic coeefficient'
          Align = alBottom
          Caption = 'kg/m'#178
          ParentShowHint = False
          ShowHint = True
          TabOrder = 11
          OnClick = UnitClick_BC
        end
        object Panel29: TPanel
          Left = 1
          Top = 49
          Width = 76
          Height = 8
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 3
        end
        object Unit_AMRAT: TButton
          Tag = 1
          Left = 1
          Top = 173
          Width = 76
          Height = 16
          Hint = 'Ballistic coeefficient'
          Align = alBottom
          Caption = 'km'#178'/kg'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 10
          OnClick = UnitClick_BC
        end
      end
    end
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
