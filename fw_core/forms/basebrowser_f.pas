unit basebrowser_f;

{$mode ObjFPC}{$H+}
{$IFOPT D+} {$DEFINE DEBUG} {$ENDIF}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  {$IFDEF debug} LazLoggerBase, {$ELSE}  LazLoggerDummy,{$ENDIF}
  baseform_f, browser_fr, BaseManager_cl;

type

  { TBaseBrowserform }

  TBaseBrowserform = class(TBaseform)
    frBrowser: TFrameBrowser;
    pnlFrBrowser: TPanel;
  private
    FManager: TBaseManager;
    procedure SetManager(AValue: TBaseManager);
  public
    property Manager: TBaseManager read FManager write SetManager;
  end;

  TBaseBrowserClass = class of TBaseBrowserform;

var
  BaseBrowserform: TBaseBrowserform;

implementation

{$R *.lfm}

{ TBaseBrowserform }

procedure TBaseBrowserform.SetManager(AValue: TBaseManager);
begin
  if FManager=AValue then Exit;
  FManager:=AValue;
end;

end.

