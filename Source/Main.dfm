object FormIPFinder: TFormIPFinder
  Left = 0
  Top = 0
  Caption = 'IP '#20108#49649#45308' '#63969#50584#47536
  ClientHeight = 450
  ClientWidth = 700
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object ButtonFindIPs: TButton
    Left = 16
    Top = 16
    Width = 121
    Height = 33
    Caption = 'IP '#20108#49649#45308' '#63969#50584#47536
    TabOrder = 0
    OnClick = ButtonFindIPsClick
  end
  object MemoResults: TMemo
    Left = 16
    Top = 64
    Width = 668
    Height = 369
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 1
  end
end
