unit basemanager_cl;

{$mode ObjFPC}{$H+}
{$IFOPT D+} {$DEFINE DEBUG} {$ENDIF}

interface

uses
  Classes, SysUtils, Dialogs, Controls, Menus,
  {$IFDEF debug} LazLogger, {$ELSE}  LazLoggerDummy,{$ENDIF}
  fw_typedef, browser_fr, basedf_f, baseds_cl, mediator_cl, entity_cl, lookup_cl;

type

  { TBaseManager }

  TBaseManager = class
  private
    fEntityCaption: string;
    // fFieldIDName    : string;
    fIsDetailMgr: boolean;
    fIsNewEntity: boolean;
    fIsSaveAndNew: boolean;
    fDFEditMode: TEditMode;    // Determina si el DF esta en solo lectura o en lectura/escritura
    fMasterMgr: TBaseManager;
    fMgrMode: TManagerMode;
    fMgrAction: TManagerAction;
    fBrowser: TFrameBrowser;   // Browser asociado a la lista de Entidades
    fBrowserTemp: TFrameBrowser;
    fDFClass: TDFClass;         // Clase del DF que se ejecutará al intentar visualizar/editar una Entidad
    fDataForm: TBaseDF;         // Instancia del DF
    fDataSource: TBaseDS;       // DS asociado al Manager
    // Esta variable tendría que estar definida en el DS
    fLookUp: TLookUp;           // Instancia de LookUp
    fDetailMgrList: array of TBaseManager;
    fOriginMgr: TBaseManager;             // Manager que origina la llamada para realizar una búsqueda
    fSearchMgrResult: TEntity;
    fSearchExtern: boolean;
    function getDetailMgr(Index: integer): TBaseManager;
    function getCurrentID: integer;                                  // <-
    procedure setCurrentID(aValue: integer);                         // <-
    procedure SetDetailMgr(Index: integer; aValue: TBaseManager);
    procedure SetBrowser(aValue: TFrameBrowser);                     // <-
    procedure SetDFClass(aValue: TDFClass);
    procedure setEntityCaption(aValue: string);
    procedure SetMasterMgr(aValue: TBaseManager);                    // <-
    procedure SetMediator(aValue: TMediator);
    procedure SetDataSource(aValue: TBaseDS);
    procedure SetLookUp(aValue: TLookUp);
    procedure SetOriginMgr(aValue: TBaseManager);                    // <-
    procedure SetSearchMgrResult(aValue: TEntity);                   // <-

    function ModifiedData: Boolean;
    procedure setMgrMode(aValue: TManagerMode);                      // <-
    procedure DFStart(aMode: byte);
    procedure DFCreate;                                              // <-
    procedure DFCLose;
    procedure DFSaveAndClose(aValue: byte);
    procedure DFUpdateActions;                                       // <-
    procedure UpdateBrowserActions;                                  // <-
    procedure UpdateBrowsers;                                        // <-
    procedure UpdateDetailMode(AMode: TManagerMode);                 // <-
    procedure UpdateMasterFields(const aValue: integer);             // <-
    procedure MoveToEntity(i: integer);                              // <-
    procedure DeleteEntity;                                          // <-
    procedure SaveEntity;                              // <-
    function CanGoNext: boolean;                                     // <-
    function CanGoPrior: boolean;                                    // <-
    procedure freeDetailMgrList;                                     // <-
    procedure SearchFinished;                                        // <-
  protected
    fMediator: TMediator;
    procedure DoGetLookUpKeys; virtual;    // Se utiliza para actualizar los valores de los campos LookUp
    procedure DoSetDefaultValuesToEntity; virtual;                   // <-
    procedure DoSetSearchValues; virtual;                            // <-
    function ValidateData: boolean;
  public
    AppName: string;                                                // Se utiliza solo para el periodo de Desarrollo
    constructor Create;                                             // <-           // P
    destructor Destroy; override;                                   // <-

    property EntityCaption: string read fEntityCaption write setEntityCaption;
    property DFClass: TDFClass read fDFClass write SetDFClass;
    property DataSource: TBaseDS read fDataSource write SetDataSource;
    property Browser: TFrameBrowser read fBrowser write SetBrowser;
    property Mediator: TMediator read fMediator write SetMediator;
    property LookUp: TLookUp read fLookUp write SetLookUp;
    property MgrMode: TManagerMode read fMgrMode write setMgrMode;
    property OriginMgr: TBaseManager read fOriginMgr write SetOriginMgr;
    property MasterMgr: TBaseManager read fMasterMgr write SetMasterMgr;
    property IsDetailMgr: boolean read fIsDetailMgr;
    property DetailMgr[Index: integer]: TBaseManager read GetDetailMgr write SetDetailMgr;
    property SearchMgrResult: TEntity read fSearchMgrResult write SetSearchMgrResult;
    property CurrentID: integer read getCurrentID write setCurrentID;

    procedure StartManager(const aSearcherMode: integer = 1);                  // <-           // P
    procedure AddDetailMgr(DetMgr: TBaseManager);                              // <-
    procedure RestartBrowser;                                                  // <-
//    procedure CanClose(Sender: TObject; var CanClose: boolean);                // <-
    procedure SetMgrAction(aMgrAct: TManagerAction; aValue: integer = 0);      // <-          // P
    procedure AddItemPredefQuery(aMenuCaption: string; aIsDefault: boolean);   // <-          // P
  end;

implementation

{ TBaseManager }

uses
  TypInfo,
  fw_config, fw_resourcestrings, baseform_f, factory;

{---------------------------------------------------------------------------------------------------
 Métodos públicos
 --------------------------------------------------------------------------------------------------}
{---------------------------------------------------------------------------------------------------
 Métodos internos
 --------------------------------------------------------------------------------------------------}
constructor TBaseManager.Create;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fMgrMode := mmIdle;
  fIsDetailMgr := False;
  fIsSaveAndNew := False;
  DebugLnExit();
end;

destructor  TBaseManager.Destroy;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  freeDetailMgrList;
  DataSource.Free;
  inherited Destroy;
  DebugLnExit();
end;

procedure TBaseManager.StartManager(const aSearcherMode: integer);
var
  isQryOK: boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  TBaseForm(fBrowser.Owner).Caption := EntityCaption;
  isQryOK := True;
  // El buscador debe ejecutarse en estas dos circunstancias
  // 1.- Cuando se está iniciando, siempre que no sea un manager de Detalle y que esté activo vcfSearcherOnStartManager
  if vcfSearcherOnStartManager then         // Variable de onfig que determina si debe mostrarse el Buscador al arrancar
  begin
    if (fMgrMode = mmIdle) and (not fIsDetailMgr) then
      isQryOK := fDataSource.ExecuteSearcher(aSearcherMode);
  end
  else
    isQryOK := False;

  // 2.- Cuando se invoque específicamente desde el Browser
  if fMgrMode = mmSearching then
  begin
    if aSearcherMode = smParams then
      fDataSource.SearchParam := fBrowser.edtSearch.Text;
    isQryOK := fDataSource.ExecuteSearcher(aSearcherMode);
  end;

  // No se debe intentar recuperar ningún dato si no se ha establecido una consulta válida
  if isQryOK then
  begin
    fDataSource.GetEntitiesList(fIsDetailMgr);
    fBrowser.PopulateGrid(fDataSource.Entities);
  end;

  // Configuración del Browser y actualización del estado del Manager
  if not fIsDetailMgr then
  begin
    fBrowser.edtSearch.Enabled := fDataSource.SearchResult.QryHasParams;
    if fBrowser.edtSearch.Enabled then
      fBrowser.edtSearch.Text :=
        fDataSource.SearchParam
    // Hay que coger fSearchValuesList^[0].ValueFrom para que no salgan los %
    else
      fBrowser.edtSearch.Text := '';

    fBrowser.UpdateStatus([fDataSource.SearchResult.NumberOfRecords,
      fDataSource.SearchResult.FieldName, fDataSource.SearchResult.Criteria]);
    SetMgrAction(maShowBrowser);
  end;
  DebugLnExit();
end;

procedure TBaseManager.AddDetailMgr(DetMgr: TBaseManager);
{-------------------------------------------------------------------------------
 Añade un mgr de detalle a fDetailMgrList. Además informa al mgr de detalle del
 nombre de su KeyField
-------------------------------------------------------------------------------}
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  SetLength(FDetailMgrList, (Length(FDetailMgrList) + 1));
  fDetailMgrList[Length(FDetailMgrList) - 1] := DetMgr;
  //  Debugln('***************** Se ha añadido ', DetMgr.ClassName, ' como Detail a ', ClassName);
  DebugLnExit();
end;

procedure TBaseManager.RestartBrowser;
begin
  fBrowser := fBrowserTemp;
end;

procedure TBaseManager.freeDetailMgrList;
{---------------------------------------------------------------------------------------------------
 Libera todos los objetos contenidos en fDetailMgrList.
 Tengo dudas sobre el funcionamiento de este proceso en el caso de que haya más de un nivel de
 detalle. VERIFICAR
---------------------------------------------------------------------------------------------------}
var
  mgr: TBaseManager;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  for mgr in fDetailMgrList do
    mgr.Free;
end;

procedure TBaseManager.UpdateMasterFields(const aValue: integer);
{---------------------------------------------------------------------------------------------------
 Ver explicación detallada en el documento
 --------------------------------------------------------------------------------------------------}
var
  mgr: TBaseManager;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  for mgr in fDetailMgrList do
  begin
    mgr.fDataSource.DBModule.SetMasterFieldValue(aValue);
    //      debugln('************ Se ha asignado el valor %D al MasterField del Manager %s', [aValue, mgr.ClassName]);
    mgr.StartManager;
    mgr.UpdateMasterFields(mgr.fDataSource.GetKeyFieldValue);
  end;
  DebugLnExit();
end;

procedure TBaseManager.SetMgrAction(aMgrAct: TManagerAction; aValue: integer);
var
  oldMgrMode: TManagerMode;
begin
  DebugLnEnter('%s - %s - %s',
    [ClassName, {$I %CURRENTROUTINE%}, GetEnumName(TypeInfo(TManagerAction), Ord(aMgrAct))]);
  // debugln('**************** Acción: %s', [GetEnumName(TypeInfo(TManagerAction), Ord(aMgrAct))]);
  fMgrAction := aMgrAct;
  case fMgrAction of
    maShowBrowser: begin
      MgrMode := mmBrowsing;
      UpdateBrowserActions;
    end;
    maRowSelected: begin
      oldMgrMode := fMgrMode;
      MgrMode := mmSelectingRow;
      setCurrentID(aValue);
      MgrMode := oldMgrMode;
    end;
    maMovetoEntity: begin
      MgrMode := mmNavegating;
      MoveToEntity(aValue);
      DFUpdateActions;
      MgrMode := mmShowing;
    end;
    maSaveEntity: begin
      MgrMode := mmSaving;
      DFSaveAndClose(aValue);
    end;
    maDeleteEntity: begin
      MgrMode := mmDeleting;
      DeleteEntity;
      setMgrAction(maShowBrowser);
    end;
    maSearch: begin
      MgrMode := mmSearching;
      StartManager(aValue);
    end;
    maSearchPredef: begin
      MgrMode := mmSearching;
      fDataSource.AsignPredefQuery(aValue);
      StartManager(smPredefined);
    end;
    maSearchExtern: begin
      oldMgrMode := fMgrMode;
      MgrMode := mmSearchExtern;
      vcfFactory.CreateManager(aValue, Self);
      MgrMode := oldMgrMode;
    end;
    maSearchResult: SearchFinished;
    maDFStart: DFStart(aValue);
    maDFUpdate: DFUpdateActions;
    maDFCLose: DFCLose;
  end;
  DebugLnExit();
end;

procedure TBaseManager.AddItemPredefQuery(aMenuCaption: string; aIsDefault: boolean);
var
  MenuItem: TMenuItem;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  MenuItem := TMenuItem.Create(fBrowser);
  MenuItem.OnClick := @fBrowser.actPredefSearchExecute;
  MenuItem.Caption := aMenuCaption;
  MenuItem.Default := aIsDefault;
  fBrowser.menTblSearch.Items.Add(MenuItem);
  DebugLnExit();
end;

procedure TBaseManager.setMgrMode(aValue: TManagerMode);
begin
  DebugLnEnter('%s - %s - %s',
    [ClassName, {$I %CURRENTROUTINE%}, GetEnumName(TypeInfo(TManagerMode), Ord(aValue))]);
  //  DebugLnEnter( '%s - %s - %s', [ClassName, {$I %CURRENTROUTINE%}, GetEnumName(TypeInfo(TManagerMode), Ord(aValue))]);
  fMgrMode := aValue;

  if length(FDetailMgrList) > 0 then
    case fMgrMode of
      mmBrowsing: UpdateDetailMode(mmIdle);
      mmShowing: UpdateDetailMode(mmBrowsingReadonly);
      mmUpdating: UpdateDetailMode(mmBrowsing);
    end;
  // Solución aplicada al problema de visualización de iconos en un browser de Detalle
  // Es posible que sea necesario añadir alguna otra condición que no he detectado
  if fIsDetailMgr and (fMgrMode = mmBrowsing) and (MasterMgr.MgrMode = mmShowing) then
    fMgrMode := mmBrowsingReadonly;
  DebugLnExit();
end;

procedure TBaseManager.UpdateBrowsers;
var
  mgr: TBaseManager;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  for mgr in fDetailMgrList do
  begin
    mgr.UpdateBrowserActions;
    if Length(mgr.FDetailMgrList) > 0 then
      mgr.UpdateBrowsers;
  end;
  DebugLnExit();
end;

{---------------------------------------------------------------------------------------------------
 Métodos que pueden redefinirse en clases hijas
 --------------------------------------------------------------------------------------------------}
{---------------------------------------------------------------------------------------------------
 Estos métodos pueden definirse o no en las clases heredadas.
 Si los defino como abstract, y no se redefinen en las clases heredadas, se genera un error. Por lo
 tanto, hasta que sepa como hacerlo, los defino en vacío
---------------------------------------------------------------------------------------------------}
procedure TBaseManager.DoGetLookUpKeys;
begin

end;

procedure TBaseManager.DoSetSearchValues;
begin

end;

function TBaseManager.ModifiedData: Boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  Result:= fMediator.Modified;
  DebugLnExit();
end;

function TBaseManager.ValidateData: boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  Result:= QuestionDlg('Validación', '¿Los datos son válidos?',
      mtWarning, [mrYes, 'Yes', mrNo, 'No'], 0) = mrYes;
  DebugLnExit();
end;

procedure TBaseManager.DFStart(aMode: byte);
begin
  fIsNewEntity := False;
  fDFEditMode := emReadWrite;
  case aMode of
    dmShowEntity: begin
      MgrMode := mmShowing;
      fDFEditMode := emReadOnly;
    end;
    dmInsertEntity: begin
      MgrMode := mmInserting;
      fIsNewEntity := True;
    end;
    dmUpdateEntity: begin
      MgrMode := mmUpdating;
    end;
  end;
  DFCreate;
end;

procedure TBaseManager.DFCreate;

procedure DFInit;
begin
  if not Assigned(fDataForm) then
  begin
    fMediator := TMediator.Create;
    fMediator.Manager:= Self;
    fDataForm := TbaseDF(fDFClass.CreateWind);
    fDataForm.Manager := Self;
    fDataForm.DoAddMediators;
    fDataform.DoConfigDetailBrowser;
  end;
end;

begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  DFInit;
  if fMgrMode = mmInserting then
  begin
    fMediator.Entity := fDataSource.GetNewEntity;
    DoSetDefaultValuesToEntity;
  end
  else
  begin
    // Esta asignación no haría falta hacerla en modo Save&New ya que la Entidad que vamos a editar es
    // la misma que acabamos de insertar.
    // A pesar de la sobrecarga de ejecutarla en todos los casos, elimino la verificación para uniformizar
    // todos los procesos
    //  if not fIsSaveAndNew then
    fMediator.Entity := fDataSource.Entities.Items[fDataSource.CurrentID]{%H-};
    // Resto de casos, se toman los datos del registro en curso
    UpdateMasterFields(fDataSource.GetKeyFieldValue);       // Nota 2

  end;
  fMediator.SetAllControlsEditMode(fDFEditMode);
  UpdateBrowsers;
  case fMgrMode of
    mmShowing: fDataForm.pnlCaption.Caption := format('%s - Visualizar registro', [EntityCaption]);
    mmInserting: fDataForm.pnlCaption.Caption := format('%s - Añadir registro', [EntityCaption]);
    mmUpdating: fDataForm.pnlCaption.Caption := format('%s - Modificar registro', [EntityCaption]);
  end;
  fMediator.Modified:= False;

  if fIsSaveAndNew then
    fIsSaveAndNew := False
  else
    fDataForm.ShowWindModal();
  DebugLnExit();
end;

procedure TBaseManager.DFCLose;
var
  CanExit: Boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  CanExit:= True;
  if ((MgrMode = mmInserting) or (MgrMode = mmUpdating)) and ModifiedData  then
    begin
      if QuestionDlg('Aviso', rsDiscardChanges, mtWarning,
                     [mrYes, 'Descartar', mrCancel, 'Volver', 'IsDefault'], 0) = mrCancel then
        begin
          fDataForm.ModalResult:= mrNone;
          CanExit:= False;
        end
    end;

  if MgrMode = mmSaving then
    if fIsSaveAndNew then
    begin
      CanExit:= False;
      if length(FDetailMgrList) = 0 then          // Código para manager Maestro
        setMgrAction(maDFStart, dmInsertEntity)
      else
        setMgrAction(maDFStart, dmUpdateEntity)
    end;

  if CanExit then
  begin
    fMediator.Free;
    fDataForm := nil;
    if fIsNewEntity then
      fDataSource.FreeNewEntity;
//    Esta condición es incorrecta     // Se ha añadido el primer registro o No quedan registros en la lista
    if ((fDataSource.CurrentID = -1) or
       (fDataSource.CurrentID = 0)  or
       (fDataSource.CurrentID = 1))  then
         setMgrAction(maShowBrowser);
  end;
  DebugLnExit();
end;

procedure TBaseManager.DFSaveAndClose(aValue: byte);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fIsSaveAndNew := (aValue = smSaveAndNew);
  if ValidateData then
  begin
    SaveEntity;
    DFClose;
  end else
    fDataForm.ModalResult:= mrNone;
  DebugLnExit();
end;

procedure TBaseManager.DFUpdateActions;
var
  actions: TDFActions;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  actions := [];
  case fMgrMode of
    mmShowing, mmNavegating: begin
      if fDataSource.CurrentID > 0 then
        actions := [daPrior];
      if fDataSource.CurrentID < fDataSource.LastID then
        actions := actions + [daNext];
    end;
    mmInserting: begin
      if fMediator.Modified then
        actions := [daSave, daSaveNew]
    end;
    mmUpdating: begin
      if fMediator.Modified then
        actions := [daSave];
    end;
  end;
  fDataForm.ActionsState := actions;
  DebugLnExit();
end;

{---------------------------------------------------------------------------------------------------
 Acciones sobre los registros
 --------------------------------------------------------------------------------------------------}
function TBaseManager.CanGoNext: boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  Result := False;
  if fDataSource.CurrentID < fDataSource.LastID then
  begin
    fDataSource.CurrentID := fDataSource.CurrentID + 1;
    Result := True;
  end;
  DebugLnExit();
end;

function TBaseManager.CanGoPrior: boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  Result := False;
  if fDataSource.CurrentID > 0 then
  begin
    fDataSource.CurrentID := fDataSource.CurrentID - 1;
    Result := True;
  end;
  DebugLnExit();
end;

procedure TBaseManager.DeleteEntity;
var
  tmpID: integer;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  tmpID := fDataSource.CurrentID;
  if QuestionDlg('Borrar Registro', '¿Esta seguro de borrar este registro?',
    mtWarning, [mrYes, 'Yes', mrNo, 'No'], 0) = mrYes then
  begin
    fDataSource.DeleteRow;
    if not fDataSource.Error then
      fBrowser.grdBrowser.DeleteRow(tmpID + 1)
    else
      ShowMessage('Se produjo un error y no se ha podido borrar el registro');
  end;
  DebugLnExit();
end;

procedure TBaseManager.SaveEntity;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
//  fIsSaveAndNew := (aValue = smSaveAndNew);
//  if ValidateData then
//  begin
    fMediator.WriteToEntity;
    DoGetLookUpKeys;
    fDataSource.SaveRow(fIsNewEntity);
    if fIsNewEntity then
    begin
      fBrowser.AddRowToGrid(fMediator.Entity);
      fLookUp.Refresh(fDataSource.DBModule.Table, fMediator.Entity);
    end
    else
      fBrowser.UpdateRowGrid(fDataSource.CurrentID + 1, fMediator.Entity);
//   end
//  else
//    fDataForm.ModalResult:= mrNone;
  DebugLnExit();
end;

procedure TBaseManager.SearchFinished;
var
  ent: TEntity;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  ent := fDataSource.Entities[fDataSource.CurrentID];
  fOriginMgr.SearchMgrResult := ent;
  ;
  TBaseForm(fBrowser.Owner).Close;
  DebugLnExit();
end;

procedure TBaseManager.DoSetDefaultValuesToEntity;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  Mediator.WriteToControls;
  DebugLnExit();
end;

procedure TBaseManager.MoveToEntity(i: integer);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if ((i > 0) and CanGoNext) or ((i < 0) and CanGoPrior) then
  begin
    fBrowser.SkipRowGrid(i);
    fMediator.Entity := fDataSource.Entities.Items[fDataSource.CUrrentID]{%H-};
    UpdateMasterFields(fDataSource.GetKeyFieldValue);
  end;
  DebugLnExit();
end;

procedure TBaseManager.UpdateDetailMode(AMode: TManagerMode);
var
  mgr: TBaseManager;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  for mgr in fDetailMgrList do
  begin
    mgr.MgrMode := AMode;
    if Length(mgr.FDetailMgrList) > 0 then
      mgr.UpdateDetailMode(amode);
  end;
  DebugLnExit();
end;

procedure TBaseManager.UpdateBrowserActions;
{---------------------------------------------------------------------------------------------------
 Actualiza los testigos que determinarán el estado de los botones del frBrowser
 Anteriormente realizaba estas verificaciones, aunque creo que ya no son necesarias. Verificar en
 cuanto tenga posibilidad.
 Estas son las condiciones en las que habría que actualizar el browser:
 tras insertar:  if fDataSource.CurrentID = 0 then     // Se ha añadido el primer registro
 tras actualizar:   if fDataSource.CurrentID < 0 then   // No quedan registros en el browser
 Tal como está el códgio esta actualización se realiza cada vez que se entra en mmBrowsing. Si se
 verifican estas condiciones el código prodría ser más eficiente
---------------------------------------------------------------------------------------------------}
var
  actions: TBrowserActions;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  actions := [];
  if Assigned(fBrowser) then
  begin
    case MgrMode of
      mmBrowsing, mmDeleting: begin
        actions := [baInsert];
        if fDataSource.Entities.Count > 0 then
          actions := actions + [baBrowse, baUpdate, baDelete];
        if not IsDetailMgr then
          // En los browsers de Detalle no deben aparecer los controles del Buscador
          actions := actions + [baSearch];
        if fSearchExtern then
          actions :=
            actions - [baUpdate, baDelete] + [baSearchResult];
      end;
      mmBrowsingReadonly: if fDataSource.Entities.Count > 0 then
          actions := [baBrowse];
    end;
    fBrowser.ActionsState := actions;
    //    fBrowser.stbTabla.Panels[1].Text:= format('Estado: %s ', [GetEnumName(TypeInfo(TManagerMode), Ord(FMgrMode))]);;
  end;
  DebugLnExit();
end;

{-- Metodos Get/Set  ------------------------------------------------------------------------------}
procedure TBaseManager.SetBrowser(aValue: TFrameBrowser);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if fBrowser = aValue then Exit;
  if Assigned(FBrowser) then
    fBrowserTemp := fBrowser;
  fBrowser := aValue;
  fBrowser.Manager := Self;
  // DebugLn('***************************** Se ha asignado ', Self.ClassName, ' a ', fBrowser.Name);
  DebugLnExit();
end;

function TBaseManager.getDetailMgr(Index: integer): TBaseManager;
begin
  Result := fDetailMgrList[index];
end;

function TBaseManager.getCurrentID: integer;
begin
  Result := fDataSource.CurrentID;
end;

procedure TBaseManager.setCurrentID(aValue: integer);
var
  mgr: TBaseManager;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if DataSource.CurrentID = aValue then
  begin
    DebugLnExit();
    exit;
  end;
  DataSource.CurrentID := aValue;
  // Esto quizá también habría que pasarlo a RowSelected
  if fMgrMode = mmShowing then
    for mgr in fDetailMgrList do
      if mgr.MgrMode <> mmIdle then
        UpdateMasterFields(fDataSource.GetKeyFieldValue);
  DebugLnExit();
end;

procedure TBaseManager.SetDetailMgr(Index: integer; aValue: TBaseManager);
begin
  fDetailMgrList[index] := aValue;
end;

procedure TBaseManager.SetMasterMgr(aValue: TBaseManager);
var
  masterField: TNameValue;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if fMasterMgr = aValue then
  begin
    Exit;
    DebugLnExit();
  end;
  fMasterMgr := aValue;
  fIsDetailMgr := True;
  masterField.Name := fMasterMgr.fDataSource.DBModule.KeyField;
  masterField.Value := -1;
  fDataSource.DBModule.MasterField := masterField;
  //  DebugLn('******************** El Manager ', ClassName, ' se ha marcado como detalle');
  //  DebugLn(' y se le ha asignado ', fMasterMgr.ClassName, ' como Maestro');
  DebugLnExit();
end;

procedure TBaseManager.SetMediator(aValue: TMediator);
begin
  if fMediator = aValue then Exit;
  fMediator := aValue;
end;

procedure TBaseManager.SetDFClass(aValue: TDFClass);
begin
  if fDFClass = aValue then Exit;
  fDFClass := aValue;
end;

procedure TBaseManager.setEntityCaption(aValue: string);
begin
  if fEntityCaption = aValue then Exit;
  fEntityCaption := aValue;
end;

procedure TBaseManager.SetDataSource(aValue: TBaseDS);
begin
  if fDataSource = aValue then Exit;
  fDataSource := aValue;
end;

procedure TBaseManager.SetLookUp(aValue: TLookUp);
begin
  if fLookUp = aValue then Exit;
  fLookUp := aValue;
end;

procedure TBaseManager.SetOriginMgr(aValue: TBaseManager);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if fOriginMgr = aValue then Exit;
  fOriginMgr := aValue;
  fSearchExtern := True;
  UpdateBrowserActions;
  DebugLnExit();
end;

procedure TBaseManager.SetSearchMgrResult(aValue: TEntity);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if fSearchMgrResult = aValue then Exit;
  fSearchMgrResult := aValue;
  DoSetSearchValues;
  DebugLnExit();
end;

end.
