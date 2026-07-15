object ProgressForm: TProgressForm
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Downloading files'
  ClientHeight = 132
  ClientWidth = 532
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  Position = poScreenCenter
  TextHeight = 15
  object ProgressLabel: TLabel
    Left = 8
    Top = 8
    Width = 513
    Height = 25
    Alignment = taCenter
    AutoSize = False
    Caption = 'Downloading file'
  end
  object ProgressBar: TProgressBar
    Left = 0
    Top = 106
    Width = 532
    Height = 26
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 89
    ExplicitWidth = 526
  end
  object AbortButton: TButton
    Left = 192
    Top = 59
    Width = 137
    Height = 25
    Caption = '&Abort'
    ModalResult = 3
    TabOrder = 1
  end
end
