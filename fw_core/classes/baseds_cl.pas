unit baseds_cl;

{$mode ObjFPC}{$H+} {$modeSwitch arrayOperators+}
{$IFOPT D+} {$DEFINE DEBUG} {$ENDIF}
{$interfaces corba}

interface

uses
  Classes, SysUtils, dialogs, fgl,
  {$IFDEF debug} LazLoggerBase, {$ELSE}  LazLoggerDummy,{$ENDIF}
  basedb_cl, fw_typedef, fw_interfdef, Searcher_cl, entity_cl;

type

  { TBaseDS }

  TBaseDS = class(TObject, IBaseDS)
  private
    fError           : boolean;
    fLastID          : integer;
    fSearchMode      : integer;
    // Esta variable no se utiliza en ningún otro sitio aparte de en TSearcher. Supongo que puede eliminarse
    fSearchResult    : TSearchResult;
    fSearcher        : TSearcher;
    fFieldsInfo      : TFieldInfoList;    // Información relevante de los campos físicos
    fSearchValuesList: TSearchValuesList; // Datos seleccionados por el usuario en frmSearcher
    function GetEntities: TEntityList;                                                              
    function getNumberOfRecords: Integer;                                                           
    function getSearchParam: string;                                                                
    function getSearchValues(Index: integer): TSearchValues;                                        

    procedure SetLastID(AValue: integer);                                                           
    procedure SetCurrentID(AValue: integer);                                                        
    procedure SetDBModule(AValue: TBaseDB);                                                         
    procedure SetEntitiesList(AValue: TEntityList);                                                 
    procedure SetNewEntity(AValue: TEntity);                                                        
    procedure setSearchParam(aValue: string);                                                       
    procedure setSearchValues(Index: integer; aValue: TSearchValues);                               
    procedure UpdateCurrentID(tmpID: LongInt);                                                      
  protected
    fCurrentID    : integer;
    fDBModule     : TBaseDB;
    FManager      : TObject;
    fEntitiesList : TEntityList;
    fNewEntity    : TEntity;
    FPredefQueries: TPredefQueries;
    procedure DoGetLookUpValues; virtual;                                                           
    procedure InitSearcher;                                                                         
    procedure ProcessFieldsInfo;                                                                              
  public
    property NewEntity    : TEntity read FNewEntity write SetNewEntity;
    property Entities     : TEntityList read GetEntities;
    property Error        : boolean read fError write fError default false;
    property CurrentID    : integer read fCurrentID write SetCurrentID;
    property LastID       : integer read fLastID write SetLastID;
    property DBModule     : TBaseDB read FDBModule write SetDBModule;
    property SearchMode   : integer read fSearchMode;
    property SearchParam  : string  read getSearchParam write setSearchParam;
    property SearchValues[Index: integer]: TSearchValues read getSearchValues write setSearchValues;
    property NumberOfRecords: Integer read getNumberOfRecords;
    property SearchResult: TSearchResult read fSearchResult;

    constructor create(aManager: TObject); virtual;                                                 
    destructor  destroy; override;                                                                  
    function  SaveRow(const aIsNewEntity : boolean): boolean;                                       
    function  GetKeyFieldValue:integer; virtual; abstract;                                          
    function  GetNewEntity: TEntity; virtual; abstract;                                             
    function  ExecuteSearcher(const aSearcherMode: integer = 1): Boolean;                           
    procedure FreeNewEntity;                                                                        
    procedure GetEntitiesList(const {%H-}IsDetailMgr: boolean);                                     
    procedure DeleteRow;                                                                            
    procedure AddRow;                                                                               
    procedure SetTable(const TableName: string);                                                    
    procedure AsignPredefQuery(const aValue: byte);                                                 
   end;

implementation

uses
  fw_config, basemanager_cl;

{ TBaseDS }

{--- Métodos públicos -----------------------------------------------------------------------------}

constructor TBaseDS.create(aManager: TObject);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  FManager:= aManager;
  fEntitiesList:= TEntityList.Create;
  fFieldsInfo:= TFieldInfoList.Create(True);
  DebugLnExit();
end;

destructor TBaseDS.destroy;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fDBModule.Free;
  FreeAndNil(fSearcher);
  fFieldsInfo.Free;
  fEntitiesList.Free;
  inherited destroy;
  DebugLnExit();
end;

function TBaseDS.SaveRow(const aIsNewEntity: boolean): boolean;
var SaveEntity: TObject;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  Result:= False;
  if aIsNewEntity then
    SaveEntity:= fNewEntity
  else
    SaveEntity:= Entities[fCurrentID];
  try
    DBModule.SaveRecord(SaveEntity, aIsNewEntity);
    if aIsNewEntity then
      AddRow;
    Result:= True;
  except
    if FError then
      showmessage('Se ha producido un error al guardar el registro en la BD')
  end;
  DebugLnExit();
end;

procedure TBaseDS.FreeNewEntity;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  FreeAndNil(fNewEntity);
  DebugLnExit();
end;

procedure TBaseDS.GetEntitiesList(const IsDetailMgr: boolean);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if IsDetailMgr then
    DBModule.Param0:= IntToStr((fDBModule.MasterField).Value);
  DBModule.GetValues;
  DoGetLookUpValues;
  DebugLnExit();
end;

procedure TBaseDS.DeleteRow;
var tmpID: integer;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  try
//    DebugLn('ID en curso: %D', [CurrentID]);
    fError:= False;
    tmpID := fCurrentID;
    DBModule.DeleteRecord(Entities[fCurrentID]);
    fEntitiesList.Delete(tmpID);
    fEntitiesList.Pack;
    UpdateCurrentID(tmpID);
  except
    fError:=  True;
    showmessage('record not deleted');
  end;
  DebugLnExit();
end;

procedure TBaseDS.AddRow;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fLastID   := fLastID + 1;
  fCurrentID:= LastID;
  fEntitiesList.Add(NewEntity);
  fNewEntity:= nil;
  DebugLnExit();
end;

procedure TBaseDS.SetTable(const TableName: string);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  DBModule.GetTableInfo(Tablename, fFieldsInfo);
  ProcessFieldsInfo;
  DebugLnExit();
end;

function TBaseDS.ExecuteSearcher(const aSearcherMode: integer): Boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if Assigned(fSearcher) then
    fSearcher.SearcherMode:= aSearcherMode
  else
    InitSearcher;
  fSearcher.StartSearcher;
  //Hay que verificar si el resultado ha sido correcto
  DBModule.SelectQry:= fSearcher.FinalQry;
  DBModule.Param0:= fSearcher.Param0;
  DBModule.Param1:= fSearcher.Param1;
  Result:= fSearcher.StatementIsOK;
  fSearchMode:= fSearcher.SearcherMode;
  DebugLnExit();
end;

procedure TBaseDS.AsignPredefQuery(const aValue: byte);
begin
  fSearcher.PredefQuery:= FPredefQueries[aValue];
  // Esta instrucción no debe ejecutarse cuando el proceso se invoca desde el Browser
//  ExecuteSearcher(smPredefined);
end;

{--- Métodos internos -----------------------------------------------------------------------------}

procedure TBaseDS.InitSearcher;
var
  i: Integer;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fSearcher:= TSearcher.Create;
  fSearcher.StartQry:= DBModule.SelectQry;
  fSearcher.TableName:= DBModule.Table;
  fSearcher.SetFieldsForSearch(fFieldsInfo);
  fSearcher.SearcherMode:= smSearcher;
  fSearcher.SearchValuesList:= @fSearchValuesList;
  fSearcher.SearchResult:= @fSearchResult;

  for i := 0 to Length(FPredefQueries) -1 do
  begin
    TBaseManager(FManager).AddItemPredefQuery(FPredefQueries[i].Caption, FPredefQueries[i].Isdefault);
    if FPredefQueries[i].Isdefault then begin
      fSearcher.PredefQuery:= FPredefQueries[i];
      fSearcher.SearcherMode:= smPredefined;
    end;
  end;
  DebugLnExit();
end;

procedure TBaseDS.UpdateCurrentID(tmpID: LongInt);
{---------------------------------------------------------------------------------------------------
 Este método se utiliza únicamente desde DeleteRow por si pudiera utilizar en otro punto.
 Aunque podría llevarlo nuevamente a DeleteRow creo que es mejor dejarlo independiente ya que cumple
 una función muy específica en la gestion de CurrentID.
 Ver lógica de funcionamiento en Documento
---------------------------------------------------------------------------------------------------}
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  // DebugLn('ID inicial: %D', [fCurrentID]);
  if fEntitiesList.Count = 0 then
    fCurrentID := -1
  else
    if tmpID = fLastID then
    begin
      tmpID := tmpID - 1;
      if tmpID = -1 then
        fCurrentID := -1
      else
        fCurrentID := fCurrentID - 1;
    end else
      if tmpID = 0 then
         fCurrentID := 0;
    fLastID:= fLastID - 1;
    DebugLn('ID final: %D', [fCurrentID]);
    DebugLnExit();
end;

procedure TBaseDS.ProcessFieldsInfo;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  // Se obtiene el campo clave. Debe ser el primero de la lista
  DBModule.KeyField:= fFieldsInfo[0].FieldName;
  {$IFDEF debug}
  // En Desarrollo permite detectar posibles errores de asignación.
  // En producción esta situación no puede ocurrir
  if LeftStr(UpperCase(fFieldsInfo[0].FieldName),3) <> 'ID_' then
    showmessage('El campo ' + fFieldsInfo[0].FieldName + ' no cumple la nomenclatura');
  {$endif}
  // DebugLn('************************ El KeyField de ', DBModule.Table, ' es: ', fFieldsInfo[0].FieldName);
  DebugLnExit();
end;

procedure TBaseDS.DoGetLookUpValues;
{---------------------------------------------------------------------------------------------------
 Di el DS no tiene campos LU, no es necesario redefinir este método por lo que lo creo aquí para que
 no se provoque un error al invocarlo
---------------------------------------------------------------------------------------------------}
begin
  //
end;

{--- Metodos Get/Set complejos --------------------------------------------------------------------}
procedure TBaseDS.SetDBModule(AValue: TBaseDB);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if FDBModule = AValue then Exit;
  FDBModule:= AValue;
  fDBModule.DSModuleInt:= self;
  DebugLnExit();
end;

{--- Métodos get/Set simples ----------------------------------------------------------------------}
procedure TBaseDS.SetEntitiesList(AValue: TEntityList);
begin
  if FEntitiesList=AValue then Exit;
  FEntitiesList:=AValue;
end;

procedure TBaseDS.SetLastID(AValue: integer);
begin
  if fLastID=AValue then Exit;
  fLastID:=AValue;
end;

function TBaseDS.GetEntities: TEntityList;
begin
  Result:= fEntitiesList;
end;

function TBaseDS.getNumberOfRecords: Integer;
begin
  Result:= fSearcher.NumberOfRecords;
end;

function TBaseDS.getSearchParam: string;
begin
  Result:= fSearchValuesList[0].ValueFrom
end;

function TBaseDS.getSearchValues(Index: integer): TSearchValues;
begin
  Result:= fSearchValuesList[index];
end;

procedure TBaseDS.SetNewEntity(AValue: TEntity);
begin
  if FNewEntity=AValue then Exit;
  FNewEntity:=AValue;
end;

procedure TBaseDS.setSearchParam(aValue: string);
begin
  fSearchValuesList[0].ValueFrom:=aValue;
end;

procedure TBaseDS.setSearchValues(Index: integer; aValue: TSearchValues);
begin
  fSearchValuesList[index]:= AValue;
end;

procedure TBaseDS.SetCurrentID(AValue: integer);
begin
  if fCurrentID=AValue then Exit;
  fCurrentID:=AValue;
end;


end.




