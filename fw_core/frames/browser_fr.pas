unit browser_fr;

{$mode ObjFPC}{$H+}
{$IFOPT D+} {$DEFINE DEBUG} {$ENDIF}

interface

uses
  Classes, SysUtils, Forms, Controls, Grids, ComCtrls, ActnList, dialogs,
  ExtCtrls, StdCtrls, Buttons, Menus, math, LazUTF8,
  {$IFDEF debug} LazLoggerBase, {$ELSE}  LazLoggerDummy,{$ENDIF}
  fw_typedef, entity_cl;

type
  BrowserActions = (baBrowse, baInsert, baUpdate, baDelete, baSearch, baSearchResult);              // <-
  TBrowserActions = set of BrowserActions;                                                          // <-
  TFillRowGridEvent = procedure(const i: Integer; const Entity: TObject) of Object;


  { TFrameBrowser }

  TFrameBrowser = class(TFrame)
    aclBrowser: TActionList;
    actSelect: TAction;
    actSearch: TAction;
    actPredefSearch: TAction;
    actSearchResult: TAction;
    actShow: TAction;
    actDelete: TAction;
    actInsert: TAction;
    actUpdate: TAction;
    edtSearch: TEdit;
    grdBrowser: TStringGrid;
    imlBrowser: TImageList;
    pnlTlbSearch: TPanel;
    pnlEdtSearch: TPanel;
    pnlGrid: TPanel;
    pnlButtons: TPanel;
    pnlSearch: TPanel;
    menTblSearch: TPopupMenu;
    stbTabla: TStatusBar;
    tlbBrowser: TToolBar;
    btnInsert: TToolButton;
    btnBrowse: TToolButton;
    btnUpdate: TToolButton;
    btnDelete: TToolButton;
    btnSearchResult: TToolButton;
    tlbSearch: TToolBar;
    btnSearch: TToolButton;
    procedure actPredefSearchExecute(Sender: TObject);
    procedure actSearchExecute(Sender: TObject);                                                    // <-
    procedure actSearchUpdate(Sender: TObject);                                                     // <-
    procedure actSearchResultExecute({%H-}Sender: TObject);                                         // <-
    procedure actSearchResultUpdate(Sender: TObject);                                               // <-
    procedure actShowExecute({%H-}Sender: TObject);                                                 // <-
    procedure actShowUpdate(Sender: TObject);                                                       // <-
    procedure actDeleteExecute({%H-}Sender: TObject);                                               // <-
    procedure actDeleteUpdate(Sender: TObject);                                                     // <-
    procedure actInsertExecute({%H-}Sender: TObject);                                               // <-
    procedure actInsertUpdate(Sender: TObject);                                                     // <-
    procedure actUpdateExecute({%H-}Sender: TObject);                                               // <-
    procedure actUpdateUpdate(Sender: TObject);                                                     // <-
    procedure edtSearchKeyPress(Sender: TObject; var Key: char);                                    // <-
    procedure grdBrowserKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure grdBrowserSelection({%H-}Sender: TObject; {%H-}aCol, {%H-}aRow: Integer);             // <-
  private
    FActionsState : TBrowserActions;
    FOnFillRowGrid: TFillRowGridEvent;
    fManager      : TObject;
    procedure SetActionsState(AValue: TBrowserActions);                                             // <-
    procedure SetManager(AValue: TObject);       // Eliminar si se utiliza classhelper_cl
    procedure SGCompareCellsAsDate(Sender: TObject; ACol, ARow, BCol, BRow: Integer; var Result: integer);
    procedure SGCompareCellsAsString(Sender: TObject; ACol, ARow, BCol, BRow: Integer; var Result: integer);
    procedure SGCompareCellsAsTime(Sender: TObject; ACol, ARow, BCol, BRow: Integer; var Result: integer);
    procedure SGCompareCellsAsFloat(Sender: TObject; ACol, ARow, BCol, BRow: Integer; var Result: integer);
  public
    constructor Create(TheOwner: TComponent); override;                                             // <-
    property  Manager: TObject read FManager write SetManager;
    property  ActionsState: TBrowserActions read FActionsState write SetActionsState;               // <-
    property  OnFillRowGrid: TFillRowGridEvent read FOnFillRowGrid write FOnFillRowGrid;            // <-
    procedure AddRowToGrid(Entity: TEntity);                                                        // <-
    procedure UpdateRowGrid(const i: Integer;Entity: TEntity);                                      // <-
    procedure PopulateGrid(Entities: TEntityList);                                                  // <-
    procedure SkipRowGrid(val: integer);                                                            // <-
    procedure UpdateStatus(aValue: array of string);                                                // <-
  end;

implementation

// Si se utiliza classhelper_cl, eliminar las lineas donde aparece TBaseManager(FManager) y
// descomentar las anteriores
uses LCLtype,
  basemanager_cl;  //classhelper_cl,


{$R *.lfm}

{ TFrameBrowser }

{--- Métodos internos de la clase -----------------------------------------------------------------}
constructor TFrameBrowser.Create(TheOwner: TComponent);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  inherited Create(TheOwner);
  // Configuración del Grid
  with grdBrowser do
  begin
    AltColorStartNormal:=false;   // Hace que sea la primera fila la que se muestre en color alternativo.  Esta propiedad solo puede modificarse por código
    AutoFillColumns:=True;        // The Grid columns fills all the window
    FocusRectVisible:=False;      // Turns off the drawing of focused cell
    ExtendedColSizing:=True;      // The user can resize columns not just at the headers but along the columns height
    {-----------------------------------------------------------------------------------------------
     Cuando se modifican estos valores en tiempo de diseño en un grid determinado, prevalecen sobre
     los especificados aquí.
    -----------------------------------------------------------------------------------------------}
    Options:= Options + [goColSizing, goColMoving, goRowSelect];
    Options:= Options - [goFixedHorzLine, goFixedVertLine, goHorzLine, goVertLine, goRangeSelect];
    OnSelection:= @grdBrowserSelection;       // Ver Documento
    OnKeyDown:= @grdBrowserKeyDown;
    OnDblClick:= @actShowExecute;
  end;
  edtSearch.OnKeyPress:= @edtSearchKeyPress;
  DebugLnExit()
end;

{--- Acciones generadas por los controles del form ------------------------------------------------}

{--- Eventos Update -------------------------------------------------------------------------------}
procedure TFrameBrowser.actDeleteUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := baDelete in FActionsState;
end;

procedure TFrameBrowser.actUpdateUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := baUpdate in FActionsState;
end;

procedure TFrameBrowser.actSearchResultUpdate(Sender: TObject);
begin
  TAction(Sender).Visible := baSearchResult in FActionsState;
end;

procedure TFrameBrowser.actSearchUpdate(Sender: TObject);
begin
  TAction(Sender).Visible:= baSearch in FActionsState;
  pnlSearch.Visible:= TAction(Sender).Visible;
end;

procedure TFrameBrowser.actInsertUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := baInsert in FActionsState;
end;

procedure TFrameBrowser.actShowUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := baBrowse in FActionsState;
end;

procedure TFrameBrowser.UpdateStatus(aValue: array of string);
var
  i: Integer;
begin
  for i:= 0 to High(aValue) do
    if aValue[i] <> '_' then
      stbTabla.Panels[i].Text:= aValue[i];
end;

{--- Eventos que ejecutan acciones del Manager --------------------------------------------}
procedure TFrameBrowser.actInsertExecute(Sender: TObject);
begin;
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
//  TBaseManager(FManager).SetMgrAction(maInsertEntity);
  TBaseManager(FManager).SetMgrAction(maDFStart, dmInsertEntity);
  DebugLnExit();
end;

procedure TFrameBrowser.actUpdateExecute(Sender: TObject);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
//  TBaseManager(FManager).SetMgrAction(maUpdateEntity);
  TBaseManager(FManager).SetMgrAction(maDFStart, dmUpdateEntity);
  DebugLnExit();
end;

procedure TFrameBrowser.actDeleteExecute(Sender: TObject);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  TBaseManager(FManager).SetMgrAction(maDeleteEntity);
  DebugLnExit();
end;

procedure TFrameBrowser.actShowExecute(Sender: TObject);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
//  TBaseManager(FManager).SetMgrAction(maShowEntity);
  TBaseManager(FManager).SetMgrAction(maDFStart, dmShowEntity);
  DebugLnExit();
end;

procedure TFrameBrowser.actSearchResultExecute(Sender: TObject);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  TBaseManager(FManager).SetMgrAction(maSearchResult);
  DebugLnExit();
end;

procedure TFrameBrowser.actSearchExecute(Sender: TObject);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  TBaseManager(FManager).SetMgrAction(maSearch, smSearcher);
  DebugLnExit();
end;

procedure TFrameBrowser.actPredefSearchExecute(Sender: TObject);
var
  i: Integer;
  item: TMenuItem;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  begin
    if Sender is TMenuItem then begin
      for item in menTblSearch.Items do
        if item.Default then
          item.Default:= False;
      TMenuItem(Sender).Default:= True;
      i:= menTblSearch.Items.IndexOf(TMenuItem(Sender));
    end;
  end;
  TBaseManager(FManager).SetMgrAction(maSearchPredef, i);
  DebugLnExit();
end;

procedure TFrameBrowser.grdBrowserSelection(Sender: TObject; aCol, aRow: Integer);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  TBaseManager(FManager).SetMgrAction(maRowSelected, aRow - 1);
  DebugLnExit();
end;

procedure TFrameBrowser.edtSearchKeyPress(Sender: TObject; var Key: char);
begin
  if Key = chr(VK_RETURN) then                    // #13
  begin
    TBaseManager(FManager).SetMgrAction(maSearch, smParams);
    edtSearch.SelectAll;
    Key := chr(VK_UNKNOWN);                       //  #0;
  end;
end;

procedure TFrameBrowser.grdBrowserKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_A then actInsertExecute(Self);
  if Key = VK_E then actUpdateExecute(Self);
  if Key = VK_DELETE then actDeleteExecute(Self);
  if key = VK_RETURN then actShowExecute(Self);
end;

{--- Eventos de los controles ---------------------------------------------------------------------}


{--- Operativa de las filas del Grid --------------------------------------------------------------}
procedure TFrameBrowser.PopulateGrid(Entities: TEntityList);
var
  i: Integer;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  If Assigned (FOnFillRowGrid) then
  begin
    grdBrowser.RowCount:= Entities.Count + 1;     // Hace falta una linea más para el título
    for i:=0 to Entities.Count - 1 do
      OnFillRowGrid(i+1, Entities.Items[i]){%H-};
    grdBrowser.Row:= 1;                           // Nota 3
  end else
    ShowMessage('FillRowGrid no está definido');
  DebugLnExit();
end;

procedure TFrameBrowser.AddRowToGrid(Entity: TEntity);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  grdBrowser.RowCount := grdBrowser.RowCount + 1;
  OnFillRowGrid(grdBrowser.RowCount - 1, Entity);
  grdBrowser.Row:= TBaseManager(FManager).CurrentID + 1;
  DebugLnExit();
end;

procedure TFrameBrowser.UpdateRowGrid(const i: Integer; Entity: TEntity);
 begin
   DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
   OnFillRowGrid(i, Entity);
   DebugLnExit();
 end;

procedure TFrameBrowser.SkipRowGrid(val: integer);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  grdBrowser.Row:= grdBrowser.Row + Val;
  DebugLnExit();
end;

{--- Procedimientos de ordenación del grid --------------------------------------------------------}
procedure TFrameBrowser.SGCompareCellsAsDate(Sender: TObject; ACol, ARow,
  BCol, BRow: Integer; var Result: integer);
var
  a, b: TDate;
begin
  a := StrToDateDef(TStringGrid(Sender).Cells[ACol, ARow], 0);
  b := StrToDateDef(TStringGrid(Sender).Cells[BCol, BRow], 0);
  Result := CompareValue(a, b);
  if TStringGrid(Sender).SortOrder = soDescending then Result := -Result
end;

procedure TFrameBrowser.SGCompareCellsAsString(Sender: TObject; ACol, ARow,
  BCol, BRow: Integer; var Result: integer);
var
  a, b: string;
begin
  a := TStringGrid(Sender).Cells[ACol, ARow];
  b := TStringGrid(Sender).Cells[BCol, BRow];
  Result := Utf8CompareText(a, b);
  if TStringGrid(Sender).SortOrder = soDescending then Result := -Result;
end;

procedure TFrameBrowser.SGCompareCellsAsTime(Sender: TObject; ACol, ARow,
  BCol, BRow: Integer; var Result: integer);
var
  a, b: TTime;
begin
  a := StrToTimeDef(TStringGrid(Sender).Cells[ACol, ARow], 0);
  b := StrToTimeDef(TStringGrid(Sender).Cells[BCol, BRow], 0);
  Result := CompareValue(a, b);
  if TStringGrid(Sender).SortOrder = soDescending then Result := -Result;
end;

procedure TFrameBrowser.SGCompareCellsAsFloat(Sender: TObject; ACol, ARow,
  BCol, BRow: Integer; var Result: integer);
var
  a, b: double;
  sa, sb: String;
begin
  sa := TStringGrid(Sender).Cells[ACol, ARow];
  sb := TStringGrid(Sender).Cells[BCol, BRow];
  if (sa = '') and (sb = '') then
    Result := 0
  else if sa = '' then
    Result := -1
  else if sb = '' then
    Result := +1
  else begin
    a := StrToFloatDef(TStringGrid(Sender).Cells[ACol, ARow], -MaxInt);
    b := StrToFloatDef(TStringGrid(Sender).Cells[BCol, BRow], -MaxInt);
    Result := CompareValue(a, b);
  end;
  if TStringGrid(Sender).SortOrder = soDescending then Result := -Result;
end;

{--- Métodos get/Set ------------------------------------------------------------------------------}
procedure TFrameBrowser.SetActionsState(AValue: TBrowserActions);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if FActionsState=AValue then
  begin
    DebugLnExit();
    Exit;
  end;
  FActionsState:=AValue;
  if baSearch in FActionsState then           // Ver explicación en Documento
    actSearchUpdate(actSearch);
  if baSearchResult in FActionsState then
  actSearchResultUpdate(actSearchResult);
  DebugLnExit();
end;

// Eliminar si se utiliza classhelper_cl
procedure TFrameBrowser.SetManager(AValue: TObject);
begin
  if FManager=AValue then Exit;
  FManager:=AValue;
end;

end.





