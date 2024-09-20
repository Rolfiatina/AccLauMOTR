object fEdit: TfEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1056#1077#1076#1072#1082#1090#1080#1088#1086#1074#1072#1085#1080#1077' '#1079#1072#1087#1080#1089#1080
  ClientHeight = 212
  ClientWidth = 329
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object pButton: TPanel
    Left = 0
    Top = 171
    Width = 329
    Height = 41
    Align = alBottom
    TabOrder = 1
    DesignSize = (
      329
      41)
    object bOK: TButton
      Left = 164
      Top = 9
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
      TabOrder = 0
      OnClick = bOKClick
    end
    object bX: TButton
      Left = 245
      Top = 9
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #1054#1090#1084#1077#1085#1080#1090#1100
      ModalResult = 2
      TabOrder = 1
    end
  end
  object pMain: TPanel
    Left = 0
    Top = 0
    Width = 329
    Height = 171
    Align = alClient
    TabOrder = 0
    object lbMenuName: TLabel
      Left = 5
      Top = 66
      Width = 127
      Height = 15
      Caption = #1053#1072#1080#1084#1077#1085#1086#1074#1072#1085#1080#1077' '#1074' '#1084#1077#1085#1102
    end
    object lbLogin: TLabel
      Left = 5
      Top = 8
      Width = 34
      Height = 15
      Caption = #1051#1086#1075#1080#1085
    end
    object lbPSW: TLabel
      Left = 5
      Top = 37
      Width = 42
      Height = 15
      Caption = #1055#1072#1088#1086#1083#1100
    end
    object lbNote: TLabel
      Left = 5
      Top = 95
      Width = 55
      Height = 15
      Caption = #1054#1087#1080#1089#1072#1085#1080#1077
    end
    object ePSW: TEdit
      Left = 144
      Top = 34
      Width = 176
      Height = 23
      PasswordChar = '*'
      TabOrder = 1
    end
    object eLogin: TEdit
      Left = 144
      Top = 5
      Width = 176
      Height = 23
      TabOrder = 0
      OnExit = eLoginExit
    end
    object eMenuName: TEdit
      Left = 144
      Top = 63
      Width = 176
      Height = 23
      TabOrder = 2
    end
    object eNote: TEdit
      Left = 5
      Top = 116
      Width = 315
      Height = 23
      TabOrder = 3
    end
  end
end
