object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object PopupMenu1: TPopupMenu
    Left = 264
    Top = 200
    object TMenuItem
    end
    object a1: TMenuItem
      Caption = 'a1'
      OnClick = a1Click
      object vvv: TMenuItem
        Caption = 'www'
        object TMenuItem
        end
      end
    end
  end
  object TrayIcon1: TTrayIcon
    Left = 376
    Top = 168
  end
end
