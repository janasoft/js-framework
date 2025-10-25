{*****************************************************************************
 Unidad original: cldatabase
*****************************************************************************}

unit basedb_cl;

{$mode ObjFPC}{$H+}
{$IFOPT D+} {$DEFINE DEBUG} {$ENDIF}

interface

uses
  Classes, SysUtils, sqlDB, DB, Dialogs,
  {$IFDEF debug} LazLoggerBase, {$ELSE}  LazLoggerDummy,{$ENDIF}
  master_dm, fw_typedef, fw_interfdef;

type


 { TdbBase }

 { TBaseDB }

 TBaseDB = class
   fSQLQuery      : TSQLQuery;
   fSQLTransaction: TSQLTransaction;
   fDBerror       : boolean;
   fRecordCount   : integer;
 private
   fKeyField   : string;
   fMasterField: TNameValue;
   fTable      : string;
   fSelectQry  : String;

   procedure SetDSModuleInt(aValue: IBaseDS);                                                       
   procedure SetKeyField(aValue: string);                                                           
   procedure SetMasterField(aValue: TNameValue);                                                    // <-
   procedure CreateQuery(var aQry:String);                                                          // <-
   procedure SetSelectQry(aValue: string);                                                          

 protected
   fDSModule: IBaseDS;
   procedure {%H-}DoGetEspecificEntity; virtual; abstract;                                          // <-
 public
   Param0: string;
   Param1: string;
   constructor Create;                                                                              // <-
   destructor  Destroy; override;                                                                   // <-

   property DataSet  : tSQLQuery read fSQLQuery;
   property SelectQry: string read fSelectQry write SetSelectQry;
   property Table      : string read fTable;
   property KeyField   : string read fKeyField write SetKeyField;
   property RecordCount : integer read fRecordCount write fRecordCount;
   property dbError     : boolean read fDBerror write fDBerror;
   property DSModuleInt: IBaseDS read fDSModule  write SetDSModuleInt;
   property MasterField: TNameValue read FMasterField write SetMasterField ;

   procedure SetMasterFieldName(const aName: String);                                               // <-
   procedure SetMasterFieldValue(const aValue: Integer);                                            // <-
   procedure GetTable(const aQuery : string);                                                       // <-
   procedure GetValues;                                                                             // <-
   procedure {%H-}GetDetailValues(aValue: integer); virtual; abstract;                              // <-
   procedure SaveRecord({%H-}aValue: TObject; const {%H-}aIsNewEntity : boolean); virtual;          // <-
   procedure DeleteRecord(const {%H-}aEntity: TObject); virtual;                                    // <-
   procedure GetTableInfo(const TableName: string; FIList: TFieldInfoList);                         // <-
end;

implementation

uses app_config;

{ TDatabase }

{-------------------------------------------------------------------------------
 Métodos internos de la clase
 ------------------------------------------------------------------------------}
constructor TBaseDB.Create;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  fSQLQuery := TSQLQuery.Create(nil);
  if dmMaster.SQLConnector1.ConnectorType <> 'SQLite3' then
  begin
    fSQLTransaction := TSQLTransaction.Create(fSQLQuery);
    fSQLTransaction.DataBase := dmMaster.SQLConnector1;
  end else
    fSQLQuery.Transaction := dmMaster.SQLTransaction1;
  fSQLQuery.DataBase := dmMaster.SQLConnector1;
  DebugLnExit();
end;

destructor TBaseDB.Destroy;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  fSQLQuery.free;
  inherited destroy;
  DebugLnExit();
end;

{-------------------------------------------------------------------------------
 Métodos públicos
 ------------------------------------------------------------------------------}
procedure TBaseDB.GetValues;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  GetTable(fSelectQry);
  if not fSQLQuery.Active then                      // GetTable ya lo ha puesto en Activo. ¿Porque es necesario abrirlo otra vez?
    fSQLQuery.Active := true;
  fDSModule.Entities.Clear;
  if fSQLQuery.recordcount > 0 then
  begin
    fDSModule.CurrentID := 0;
    fSQLQuery.first;
    DoGetEspecificEntity;
  end else
    fDSModule.CurrentID := -1;
  fDSModule.LastID := fDSModule.Entities.Count - 1;
  fSQLQuery.Active := false;
  DebugLnExit();
end;

procedure TBaseDB.GetTable(const aQuery: string);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  

  if fSQLQuery <> nil then
  begin
    fSQLQuery.Active   := false;
    fSQLQuery.SQL.Text := aQuery;
//    debugln('****************** Query: %s', [fSQLQuery.SQL.Text]);
//    DebugLn('******* Param0 es: %s, Param1 es: %s',[Param0, Param1]);
    if fSQLQuery.Params.Count = 1 then
       fSQLQuery.Params[0].AsString:= Param0;
    if fSQLQuery.Params.Count = 2 then
    begin
       fSQLQuery.Params[0].AsString:= Param0;
       fSQLQuery.Params[1].AsString:= Param1;
    end;
    fSQLQuery.Active   := true;
//    debugln('****************** Se ha buscado en la tabla %s valores con código %D',[Table, MasterField.Value]);
//    debugln('y se han recuperado %D registros', [fSQLQuery.RecordCount]);
  end;
  DebugLnExit();
end;

procedure TBaseDB.CreateQuery(var aQry: String);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  aqry:= '';
  aQry:= format('select * from %s',[fTable]);
  if fMasterField.Name <> '' then
    aQry:= aQry + format(' where %s = :0', [FMasterField.Name]);
//  Debugln('****************** Se ha creado la query: ', aQry);
  DebugLnExit();
end;

procedure TBaseDB.GetTableInfo(const TableName: string; FIList: TFieldInfoList);
var
  qry: string;
  i: integer;
  FI: TFieldInfo;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  if fTable <> TableName then
  begin
    FTable:= TableName;
    CreateQuery(fSelectQry);
    qry:= fSelectQry + ' limit 1';

    fSQLQuery.Active   := false;
    fSQLQuery.SQL.Text := qry;
    fSQLQuery.Active   := true;
    for i:= 0 to Pred(fSQLQuery.Fields.Count) do
    begin
      FI:= TFieldInfo.Create;
      FI.FieldName:= fSQLQuery.Fields[i].FieldName;
      FI.FieldType:= fSQLQuery.Fields[i].DataType;
      FI.FieldKind:= fSQLQuery.Fields[i].FieldKind;
      FIList.Add(i, FI);
    // Para que funcione la siguiente linea hay que pasar fFieldsInfo de private a public
    //   for i:= 0 to Pred(fSQLQuery.Fields.Count) do
    //     debugln ('**** Se ha almacenado en fFieldsInfo %S', [TFieldData(TBaseDS(DSModule).fFieldsInfo[i]).FieldName]);
    end;
  end;
  DebugLnExit();
end;

procedure TBaseDB.SaveRecord(aValue: TObject; const aIsNewEntity: boolean);
{---------------------------------------------------------------------------------------------------
 No puede declararse como abstract ya que se invoca desde BaseDS
---------------------------------------------------------------------------------------------------}
begin
  //
end;

procedure TBaseDB.DeleteRecord(const aEntity: TObject);
{---------------------------------------------------------------------------------------------------
 No puede declararse como abstract ya que se invoca desde BaseDS
---------------------------------------------------------------------------------------------------}
begin
  //
end;

{-------------------------------------------------------------------------------
 Metodos Get/Set
 ------------------------------------------------------------------------------}
procedure TBaseDB.SetDSModuleInt(AValue: IBaseDS);
begin
  if fDSModule=aValue then Exit;
  fDSModule:=aValue;
end;

procedure TBaseDB.SetKeyField(AValue: string);
begin
  if FKeyField=aValue then Exit;
  FKeyField:=aValue;
end;

procedure TBaseDB.SetMasterFieldName(const aName: String);
begin
  fMasterField.Name:= aName;
end;

procedure TBaseDB.SetMasterFieldValue(const aValue: Integer);
begin
  fMasterField.Value:= aValue;
end;

procedure TBaseDB.SetMasterField(aValue: TNameValue);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  delete(aValue.Name,1,3);
  aValue.Name:= aValue.Name + '_ID';
  FMasterField:=aValue;
  CreateQuery(fSelectQry);
//  debugln('Se han asignado el valor %s al MasterField de %s', [FMasterField.Name, ClassName]);
end;

procedure TBaseDB.SetSelectQry(aValue: string);
begin
  if FSelectQry=aValue then Exit;
  FSelectQry:=aValue;
end;

end.




