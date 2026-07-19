object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'BSPMerge'
  ClientHeight = 816
  ClientWidth = 1420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  TextHeight = 15
  object Splitter: TSplitter
    Left = 700
    Top = 0
    Height = 816
    ExplicitLeft = 592
    ExplicitTop = 176
    ExplicitHeight = 100
  end
  object Panel1: TPanel
    Left = 703
    Top = 0
    Width = 717
    Height = 816
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 711
    ExplicitHeight = 799
    object Memo: TMemo
      Left = 1
      Top = 123
      Width = 715
      Height = 692
      Align = alClient
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Cascadia Code'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
      ExplicitWidth = 709
      ExplicitHeight = 675
    end
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 715
      Height = 122
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitWidth = 709
      object Label1: TLabel
        Left = 30
        Top = 31
        Width = 140
        Height = 15
        Alignment = taRightJustify
        AutoSize = False
        Caption = 'Satellite filter: use only the'
      end
      object Label3: TLabel
        Left = 265
        Top = 31
        Width = 258
        Height = 15
        Caption = 'most massive satellites per planet (0 = unlimited)'
      end
      object Label4: TLabel
        Left = 30
        Top = 52
        Width = 140
        Height = 15
        Alignment = taRightJustify
        AutoSize = False
        Caption = 'Asteroid filter: use only the'
      end
      object Label5: TLabel
        Left = 265
        Top = 52
        Width = 204
        Height = 15
        Caption = 'most massive asteroids (0 = unlimited)'
      end
      object Label6: TLabel
        Left = 48
        Top = 73
        Width = 122
        Height = 15
        Alignment = taRightJustify
        Caption = 'TNO filter: use only the'
      end
      object Label7: TLabel
        Left = 265
        Top = 73
        Width = 257
        Height = 15
        Caption = 'most massive Kuiper-belt objects (0 = unlimited)'
      end
      object StartBtn: TButton
        Left = 0
        Top = 97
        Width = 715
        Height = 25
        Align = alBottom
        Caption = 'Start'
        TabOrder = 4
        OnClick = StartBtnClick
        ExplicitWidth = 709
      end
      object NumSat: TSpinEdit
        Left = 178
        Top = 28
        Width = 81
        Height = 24
        MaxValue = 999999
        MinValue = 0
        TabOrder = 1
        Value = 0
      end
      object NumAst: TSpinEdit
        Left = 178
        Top = 49
        Width = 81
        Height = 24
        MaxValue = 343
        MinValue = 0
        TabOrder = 2
        Value = 20
      end
      object NumKBO: TSpinEdit
        Left = 178
        Top = 70
        Width = 81
        Height = 24
        MaxValue = 12
        MinValue = 0
        TabOrder = 3
        Value = 4
      end
      object FilterBtn: TButton
        Left = 0
        Top = 0
        Width = 715
        Height = 25
        Align = alTop
        Caption = 'Apply filter'
        TabOrder = 0
        OnClick = FilterBtnClick
        ExplicitWidth = 709
      end
    end
  end
  object Panel0: TPanel
    Left = 0
    Top = 0
    Width = 700
    Height = 816
    Align = alLeft
    TabOrder = 1
    ExplicitHeight = 799
    object CheckListBox: TCheckListBox
      Left = 1
      Top = 123
      Width = 698
      Height = 692
      Align = alClient
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Cascadia Code'
      Font.Style = []
      ItemHeight = 21
      ParentFont = False
      PopupMenu = PopupMenu
      TabOrder = 1
      OnClick = CheckListBoxClick
      ExplicitHeight = 675
    end
    object Panel2: TPanel
      Left = 1
      Top = 1
      Width = 698
      Height = 122
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      OnResize = Panel2Resize
      object OpenBtn: TButton
        Left = 0
        Top = 97
        Width = 698
        Height = 25
        Align = alBottom
        Caption = '&Open...'
        TabOrder = 2
        OnClick = OpenBtnClick
      end
      object CBtpc: TCheckBox
        Left = 16
        Top = 55
        Width = 361
        Height = 36
        Caption = 
          'Use custom constant (GM, oblateness, equatorial radii).tpc files' +
          ' (if left unchecked, canonical DE440/DE441 values will be used)'
        TabOrder = 1
        WordWrap = True
      end
      object DownloadBtn: TButton
        Left = 0
        Top = 0
        Width = 698
        Height = 25
        Align = alTop
        Caption = '&Download default (DE440) BSP files...'
        TabOrder = 0
        OnClick = DownloadBtnClick
      end
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 'BSP files (*.bsp)|*.bsp'
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 576
    Top = 24
  end
  object SaveDialog: TSaveDialog
    DefaultExt = '.bspx'
    Filter = 'BSPX files (*.bspx)|*.bspx|BSP files (*.bsp)|*.bsp'
    OnTypeChange = SaveDialogTypeChange
    Left = 676
    Top = 24
  end
  object PopupMenu: TPopupMenu
    Left = 528
    Top = 248
    object PMAll: TMenuItem
      Caption = 'Select &all'
      OnClick = PMSelectClick
    end
    object PMNone: TMenuItem
      Caption = 'Select &none'
      OnClick = PMSelectClick
    end
    object PMBig16: TMenuItem
      Caption = 'Select &SB441-N16 asteroids'
      OnClick = PMBig16Click
    end
  end
end
