unit BCEditor.Editor.PopupWindow;

interface

uses
  Winapi.Messages, System.Classes, System.Types, Vcl.Controls{$IFDEF USE_ALPHASKINS}, sCommonData, acSBUtils,
  sStyleSimply{$ENDIF};

type
  TBCEditorPopupWindow = class(TCustomControl)
  private
{$IFDEF USE_ALPHASKINS}
    FCommonData: TsScrollWndData;
    FScrollWnd: TacScrollWnd;
{$ENDIF}
    procedure WMEraseBkgnd(var AMessage: TMessage); message WM_ERASEBKGND;
    procedure WMMouseActivate(var AMessage: TWMMouseActivate); message WM_MOUSEACTIVATE;
{$IFDEF USE_VCL_STYLES}
    procedure WMNCPaint(var AMessage: TWMNCPaint); message WM_NCPAINT;
{$ENDIF}
  protected
    FActiveControl: TWinControl;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Hide; virtual;
    procedure Show(Origin: TPoint); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CreateWnd; override;
    procedure WndProc(var AMessage: TMessage); override;
    property ActiveControl: TWinControl read FActiveControl;
{$IFDEF USE_ALPHASKINS}
    property SkinData: TsScrollWndData read FCommonData write FCommonData;
{$ENDIF}
  end;

implementation

uses
  Winapi.Windows, System.SysUtils{$IFDEF USE_VCL_STYLES}, Vcl.Themes{$ENDIF}
  {$IFDEF USE_ALPHASKINS}, Winapi.CommCtrl, sVCLUtils, sMessages, sConst, sSkinProps{$ENDIF};

constructor TBCEditorPopupWindow.Create(AOwner: TComponent);
begin
  {$IFDEF USE_ALPHASKINS}
  FCommonData := TsScrollWndData.Create(Self, True);
  FCommonData.COC := COC_TsListBox;
  if FCommonData.SkinSection = '' then
    FCommonData.SkinSection := s_Edit;
{$ENDIF}
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csNoDesignVisible, csReplicatable];

  Ctl3D := False;
  ParentCtl3D := False;
  Parent := AOwner as TWinControl;
  Visible := False;
end;

destructor TBCEditorPopupWindow.Destroy;
begin
  inherited Destroy;

  {$IFDEF USE_ALPHASKINS}
  if Assigned(FScrollWnd) then
    FreeAndNil(FScrollWnd);
  if Assigned(FCommonData) then
    FreeAndNil(FCommonData);
  {$ENDIF}
end;

procedure TBCEditorPopupWindow.CreateWnd;
{$IFDEF USE_ALPHASKINS}
var
  LSkinParams: TacSkinParams;
{$ENDIF}
begin
  inherited;
{$IFDEF USE_ALPHASKINS}
  FCommonData.Loaded(False);
  if (FScrollWnd <> nil) and FScrollWnd.Destroyed then
    FreeAndNil(FScrollWnd);

  if FScrollWnd = nil then
    FScrollWnd := TacEditWnd.Create(Handle, SkinData, SkinData.SkinManager, LSkinParams, False);
{$ENDIF}
end;

procedure TBCEditorPopupWindow.Hide;
begin
  SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOZORDER or SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_HIDEWINDOW);
  Visible := False;
end;

procedure TBCEditorPopupWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);

  Params.Style := WS_POPUP or WS_BORDER;
end;

procedure TBCEditorPopupWindow.Show(Origin: TPoint);
begin
  SetBounds(Origin.X, Origin.Y, Width, Height);

  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOACTIVATE or SWP_SHOWWINDOW or
    SWP_NOSENDCHANGING or SWP_NOOWNERZORDER or SWP_NOMOVE);

  Visible := True;
end;

procedure TBCEditorPopupWindow.WMMouseActivate(var AMessage: TWMMouseActivate);
begin
  AMessage.Result := MA_NOACTIVATE;
end;

procedure TBCEditorPopupWindow.WMEraseBkgnd(var AMessage: TMessage);
begin
  AMessage.Result := -1;
end;

{$IFDEF USE_VCL_STYLES}
procedure TBCEditorPopupWindow.WMNCPaint(var AMessage: TWMNCPaint);
var
  LRect: TRect;
  LExStyle: Integer;
  LTempRgn: HRGN;
  LBorderWidth, LBorderHeight: Integer;
begin
  if StyleServices.Enabled then
  begin
    LExStyle := GetWindowLong(Handle, GWL_EXSTYLE);
    if (LExStyle and WS_EX_CLIENTEDGE) <> 0 then
    begin
      GetWindowRect(Handle, LRect);
      LBorderWidth := GetSystemMetrics(SM_CXEDGE);
      LBorderHeight := GetSystemMetrics(SM_CYEDGE);
      InflateRect(LRect, -LBorderWidth, -LBorderHeight);
      LTempRgn := CreateRectRgnIndirect(LRect);
      DefWindowProc(Handle, AMessage.Msg, wParam(LTempRgn), 0);
      DeleteObject(LTempRgn);
    end
    else
      DefaultHandler(AMessage);
  end
  else
    DefaultHandler(AMessage);

  if StyleServices.Enabled then
    StyleServices.PaintBorder(Self, False);
end;
{$ENDIF}

procedure TBCEditorPopupWindow.WndProc(var AMessage: TMessage);
begin
{$IFDEF USE_ALPHASKINS}
  if AMessage.Msg = SM_ALPHACMD then
    case AMessage.WParamHi of
      AC_CTRLHANDLED:
        begin
          AMessage.Result := 1;
          Exit;
        end;
      AC_GETDEFINDEX:
        begin
          if FCommonData.SkinManager <> nil then
            AMessage.Result := FCommonData.SkinManager.ConstData.Sections[ssEdit] + 1;
          Exit;
        end;
      AC_REFRESH:
        if (ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager)) and Visible then
        begin
          CommonWndProc(AMessage, FCommonData);
          RefreshEditScrolls(SkinData, FScrollWnd);
          SendMessage(Handle, WM_NCPAINT, 0, 0);
          Exit;
        end;
    end;
{$ENDIF}
  inherited;
end;

end.
