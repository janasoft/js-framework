unit basedf_f;

{$mode ObjFPC}{$H+}
{$IFOPT D+} {$DEFINE DEBUG} {$ENDIF}
{$WARN 5024 off : Parameter "$1" not used}
interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  ActnList, StdCtrls,
 {$IFDEF debug} LazLoggerBase, {$ELSE}  LazLoggerDummy,{$ENDIF}
  baseform_f;

type
  DFActions = (daPrior, daNext, daSave, daSaveNew, pnlCaption);
  TDFActions = set of DFActions;

  { TBaseDF }

  TBaseDF = class(TBaseForm)
    aclDF: TActionList;
    actSaveAndNew: TAction;
    actSave: TAction;
    actClose: TAction;
    actPrior: TAction;
    actNext: TAction;
    btnPrior: TBitBtn;
    BtnNext: TBitBtn;
    btnClose: TBitBtn;
    btnSave: TBitBtn;
    btnSaveAndNew: TBitBtn;
    Button1: TButton;
    imlDF48: TImageList;
    pnlCaption: TPanel;
    pnlDatosDF: TPanel;
    pnlBotonesDF: TPanel;
    procedure actCloseExecute({%H-}Sender: TObject);
    procedure actNextExecute(Sender: TObject);
    procedure actNextUpdate(Sender: TObject);
    procedure actPriorExecute({%H-}Sender: TObject);
    procedure actPriorUpdate(Sender: TObject);
    procedure actSaveAndNewExecute({%H-}Sender: TObject);
    procedure actSaveAndNewUpdate(Sender: TObject);
    procedure actSaveExecute({%H-}Sender: TObject);
    procedure actSaveUpdate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FActionsState: TDFActions;
    procedure SetActionsState(AValue: TDFActions);
    procedure SetManager(AValue: TObject); // Eliminar si se utiliza classhelper_cl
  protected
    // No se puede utilizar TBaseManager porque se crea una referencia circular en basebrowser_f
    FManager: TObject;
  public
    property ActionsState: TDFActions read FActionsState write SetActionsState;
    property Manager: TObject read FManager write SetManager;    // Eliminar si se utiliza classhelper_cl
    procedure DoConfigDetailBrowser; virtual; abstract;
    procedure DoAddMediators; virtual; abstract;
  end;

  TDFClass = class of TbaseDF;

var
  BaseDF: TbaseDF;

implementation

// Si se utiliza classhelper_cl, eliminar las lineas donde aparece TBaseManager(FManager) y
// descomentar las anteriores
uses fw_typedef, basemanager_cl;  //classhelper_cl,

{$R *.lfm}

{ TBaseDF }
{-------------------------------------------------------------------------------
 Acciones realizadas sobre los controles
-------------------------------------------------------------------------------}
procedure TBaseDF.actPriorExecute(Sender: TObject);
begin
  TBaseManager(FManager).SetMgrAction(maMovetoEntity, mtePrior);
end;

procedure TBaseDF.actNextExecute(Sender: TObject);
begin
  TBaseManager(FManager).SetMgrAction(maMovetoEntity, mteNext);
end;

procedure TBaseDF.actCloseExecute(Sender: TObject);
begin
  TBaseManager(FManager).SetMgrAction(maDFCLose);
end;

procedure TBaseDF.actSaveAndNewExecute(Sender: TObject);
begin
  TBaseManager(FManager).SetMgrAction(maSaveEntity, smSaveAndNew);
end;

procedure TBaseDF.actSaveExecute(Sender: TObject);
begin
  TBaseManager(FManager).SetMgrAction(maSaveEntity, smSave);
  Close;
end;

procedure TBaseDF.actNextUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := daNext in FActionsState;
end;

procedure TBaseDF.actPriorUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := daPrior in FActionsState;
end;

procedure TBaseDF.actSaveAndNewUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := daSaveNew in FActionsState;
end;

procedure TBaseDF.actSaveUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := daSave in FActionsState;
end;

procedure TBaseDF.Button1Click(Sender: TObject);
var
  i: Integer;
begin
  DebugLnEnter('Nivel indentado %d', [DebugLogger.CurrentIndentLevel]);
  for i := 0 to Pred(DebugLogger.CurrentIndentLevel) do
  begin
     DebugLnExit('<-');
  end;
end;

procedure TBaseDF.FormCreate(Sender: TObject);
begin
  Constraints.MaxWidth:= Width;
  Constraints.MaxHeight:= Height;
end;

{---------------------------------------------------------------------------------------------------
 Métodos get/Set
---------------------------------------------------------------------------------------------------}

// Eliminar si se utiliza classhelper_cl
procedure TBaseDF.SetManager(AValue: TObject);
begin
  if FManager=AValue then Exit;
  FManager:=AValue;
end;

procedure TBaseDF.SetActionsState(AValue: TDFActions);
begin
  if FActionsState=AValue then Exit;
  FActionsState:=AValue;
end;

end.

