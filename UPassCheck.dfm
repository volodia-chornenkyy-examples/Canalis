object FPassCheck: TFPassCheck
  Left = 0
  Top = 0
  BorderIcons = [biMinimize, biMaximize]
  BorderStyle = bsToolWindow
  Caption = #1042#1074#1077#1076#1110#1090#1100' '#1087#1072#1088#1086#1083#1100
  ClientHeight = 68
  ClientWidth = 242
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object edtPassword: TEdit
    Left = 8
    Top = 8
    Width = 226
    Height = 21
    TabOrder = 0
    TextHint = #1042#1074#1077#1076#1110#1090#1100' '#1087#1072#1088#1086#1083#1100
    OnKeyDown = edtPasswordKeyDown
    OnKeyPress = edtPasswordKeyPress
  end
  object btnOK: TBitBtn
    Left = 78
    Top = 35
    Width = 75
    Height = 25
    Caption = #1054#1050
    TabOrder = 1
    OnClick = btnOKClick
  end
  object btnClose: TBitBtn
    Left = 159
    Top = 35
    Width = 75
    Height = 25
    Caption = #1047#1072#1082#1088#1080#1090#1080
    ModalResult = 8
    TabOrder = 2
    OnClick = btnCloseClick
  end
end
