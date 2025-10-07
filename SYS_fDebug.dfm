object fDebug: TfDebug
  Left = 0
  Top = 0
  Caption = 'fDebug'
  ClientHeight = 209
  ClientWidth = 398
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object p1: TPanel
    Left = 0
    Top = 0
    Width = 398
    Height = 209
    Align = alClient
    Caption = 'p1'
    TabOrder = 0
    object mDebug: TMemo
      Left = 1
      Top = 1
      Width = 396
      Height = 207
      Align = alClient
      Lines.Strings = (
        'mDebug')
      ScrollBars = ssBoth
      TabOrder = 0
    end
  end
end
