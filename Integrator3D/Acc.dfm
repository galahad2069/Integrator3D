object AccForm: TAccForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Acceleration'
  ClientHeight = 185
  ClientWidth = 423
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 15
  object Panel_Input: TPanel
    Left = 0
    Top = 0
    Width = 423
    Height = 185
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 417
    ExplicitHeight = 168
    object Splitter3: TSplitter
      Left = 84
      Top = 0
      Height = 185
      ExplicitLeft = 120
      ExplicitTop = 112
      ExplicitHeight = 100
    end
    object Splitter4: TSplitter
      Left = 340
      Top = 0
      Height = 185
      Align = alRight
      ExplicitLeft = 160
      ExplicitTop = 152
      ExplicitHeight = 100
    end
    object Panel_Names: TPanel
      Left = 0
      Top = 0
      Width = 84
      Height = 185
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
      ExplicitHeight = 168
      object Name_Hdr: TPanel
        Left = 1
        Top = 1
        Width = 82
        Height = 20
        Align = alTop
        Caption = 'Element:'
        TabOrder = 0
      end
      object Name_Mode: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 93
        Width = 74
        Height = 83
        Hint = 'Position vector Y'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alClient
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Mode:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 6
        ExplicitHeight = 66
      end
      object Name_Acc: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 77
        Width = 74
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Magnitude:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 5
      end
      object Panel5: TPanel
        Left = 1
        Top = 176
        Width = 82
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 7
        ExplicitTop = 159
      end
      object Name_Target: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 21
        Width = 74
        Height = 16
        Hint = 'Epoch of osculating elements (TDB)'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alTop
        Alignment = taRightJustify
        BevelOuter = bvNone
        Caption = 'Target:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
      end
      object Name_Center: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 37
        Width = 74
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
      object Name_Frame: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 53
        Width = 74
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
      object Panel17: TPanel
        Left = 1
        Top = 69
        Width = 82
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 4
      end
    end
    object Panel_Units: TPanel
      Left = 343
      Top = 0
      Width = 80
      Height = 185
      Align = alRight
      Constraints.MaxWidth = 100
      Constraints.MinWidth = 80
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      ExplicitLeft = 337
      ExplicitHeight = 168
      object Unit_Hdr: TPanel
        Left = 1
        Top = 1
        Width = 78
        Height = 20
        Align = alTop
        Caption = 'Unit:'
        TabOrder = 0
      end
      object Unit_Acc: TButton
        Tag = 2
        Left = 1
        Top = 77
        Width = 78
        Height = 16
        Align = alTop
        Caption = 'g'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        OnClick = UnitClick_Acc
      end
      object Panel8: TPanel
        Left = 1
        Top = 176
        Width = 78
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 6
        ExplicitTop = 159
      end
      object ToggleSwitch: TToggleSwitch
        Left = 1
        Top = 156
        Width = 78
        Height = 20
        Align = alBottom
        BiDiMode = bdLeftToRight
        Enabled = False
        ParentBiDiMode = False
        TabOrder = 5
        OnClick = ToggleSwitchClick
        ExplicitTop = 139
        ExplicitWidth = 77
      end
      object Unit_Target: TPanel
        Left = 1
        Top = 21
        Width = 78
        Height = 56
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
      end
      object CBRelative: TCheckBox
        Left = 1
        Top = 93
        Width = 78
        Height = 17
        Hint = 
          'While checked, values will be relative to the rendering speed, s' +
          'o 1 m/s'#178' would mean 1 m/s deltaV per actual seconds elapsed'
        Align = alTop
        Caption = 'Relative'
        Checked = True
        ParentShowHint = False
        ShowHint = True
        State = cbChecked
        TabOrder = 3
        OnClick = Value_Change
      end
      object Panel2: TPanel
        AlignWithMargins = True
        Left = 1
        Top = 110
        Width = 70
        Height = 46
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alClient
        BevelOuter = bvNone
        Caption = 'Status:'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = False
        TabOrder = 4
        ExplicitHeight = 29
      end
    end
    object Panel_Values: TPanel
      Left = 87
      Top = 0
      Width = 253
      Height = 185
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
      ExplicitWidth = 247
      ExplicitHeight = 168
      object Value_Hdr: TPanel
        Left = 0
        Top = 0
        Width = 253
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
        ExplicitWidth = 247
      end
      object Panel6: TPanel
        Left = 0
        Top = 73
        Width = 253
        Height = 8
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 4
        ExplicitWidth = 247
      end
      object Value_Target: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 20
        Width = 245
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alTop
        BevelOuter = bvNone
        Caption = 'N/A'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        ExplicitWidth = 239
      end
      object Value_Frame: TPanel
        AlignWithMargins = True
        Left = 8
        Top = 57
        Width = 245
        Height = 16
        Hint = 'Position vector X'
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alTop
        BevelOuter = bvNone
        Caption = 'ICRF'
        Padding.Right = 8
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
        ExplicitWidth = 239
      end
      object Panel11: TPanel
        Left = 0
        Top = 177
        Width = 253
        Height = 8
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 7
        ExplicitTop = 160
        ExplicitWidth = 247
      end
      object Value_Center: TComboBox
        Left = 0
        Top = 36
        Width = 253
        Height = 21
        Hint = '<select center>'
        Align = alTop
        Style = csDropDownList
        DropDownCount = 12
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        TextHint = '<select center>'
        OnChange = Value_Change
        OnDrawItem = ComboDrawItem
        ExplicitWidth = 247
      end
      object Value_Mode: TRadioGroup
        Left = 0
        Top = 97
        Width = 253
        Height = 80
        Hint = 'Extra acceleration vector direction'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alClient
        Columns = 2
        ItemIndex = 0
        Items.Strings = (
          'Prograde'
          'Normal'
          'Radial'
          'Retrograde'
          'Antinormal'
          'Antiradial')
        ParentShowHint = False
        ShowHint = True
        TabOrder = 6
        OnClick = Value_Change
        ExplicitWidth = 247
        ExplicitHeight = 63
      end
      object Value_AccPanel: TPanel
        Left = 0
        Top = 81
        Width = 253
        Height = 16
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 5
        ExplicitWidth = 247
        object Value_Acc: TEdit
          Left = 0
          Top = 0
          Width = 229
          Height = 16
          Hint = 'Extra acceleration vector magnitude'
          Align = alClient
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          Text = '1.0'
          OnChange = Value_Change
          OnKeyPress = NumericOnlyKeyPress
          ExplicitWidth = 223
        end
        object Value_AccSpin: TSpinButton
          Left = 229
          Top = 0
          Width = 24
          Height = 16
          Align = alRight
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
          OnDownClick = Value_AccSpinDownClick
          OnUpClick = Value_AccSpinUpClick
          ExplicitLeft = 223
        end
      end
    end
  end
end
