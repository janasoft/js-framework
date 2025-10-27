unit entity_cl;

{$mode ObjFPC}{$H+}
{$IFOPT D+} {$DEFINE DEBUG} {$ENDIF}

interface

uses
  Classes, SysUtils, fgl, sqldb,
  {$IFDEF debug} LazLoggerBase, {$ELSE}  LazLoggerDummy,{$ENDIF}
  fw_typedef, entity_serializers;

type

TEntity = class
private
  fCaption: string;
  fID: integer;
  fState: TEntityState;
  fMetadata: TEntityMetadata;
  fValidationMessages: TValidationMessages;
  fLoadingCount: Integer;  // contador para BeginLoad/EndLoad

  procedure setCaption(aValue: string);
  procedure setID(aValue: integer);
  procedure setState(aValue: TEntityState);
  procedure UpdateModifiedMetadata;

  function GetIsLoading: Boolean;
  function SetFieldString(var aField: string; const aValue: string): Boolean;
  function SetFieldInteger(var aField: Integer; const aValue: Integer): Boolean;
  function SetFieldBoolean(var aField: Boolean; const aValue: Boolean): Boolean;
protected
  procedure DoValidate; virtual;
  
  { Hooks abstractos para serialización JSON - Principio OCP (Open/Closed)
    Las clases derivadas extienden la serialización sin modificar TEntity
    No dependen directamente de JSON - Principio DIP (Dependency Inversion) }
  procedure DoSerializeFields(aSerializer: TEntitySerializer); virtual;
  procedure DoDeserializeFields(aDeserializer: TEntityDeserializer); virtual;
  
  { Hooks abstractos para mapeo directo DB ↔ Entity
    Camino eficiente sin overhead JSON para operaciones de base de datos
    Las entidades definen CÓMO mapear sus campos específicos }
  procedure DoLoadFromQuery(aQuery: TSQLQuery); virtual;
  procedure DoSaveToParams(aQuery: TSQLQuery); virtual;
public
  constructor Create; virtual;
  destructor Destroy; override;

  function Validate: Boolean; virtual;
  function IsValid: Boolean;
  procedure MarkAsModified;
  procedure MarkAsDeleted;
  
  // Gestión de carga
  procedure BeginLoad;
  procedure EndLoad;
  property IsLoading: Boolean read GetIsLoading;

  // Helpers para metadata
  procedure UpdateMetadata(const aCreatedBy: string); overload;
  procedure UpdateMetadata(const aModifiedBy: string; const aVersion: Integer); overload;
  
  { Serialización JSON - Opcional para web/API
    Usa helpers para abstraer JSON de la entidad (Principio DIP)
    Compatible hacia atrás: no afecta acceso a BD }
  function ToJSONString: string;
  procedure FromJSONString(const aStr: string);
  
  { Mapeo directo DB ↔ Entity - Camino eficiente
    Carga/guarda desde/hacia consultas SQL sin overhead JSON
    Usa BeginLoad/EndLoad internamente para evitar side effects }
  procedure LoadFromQuery(aQuery: TSQLQuery);
  procedure SaveToQuery(aQuery: TSQLQuery);

  property ID: integer read fID write setID;
  property Caption: string read fCaption write setCaption;
  property State: TEntityState read fState write setState;
  property Metadata: TEntityMetadata read fMetadata;
  property ValidationMessages: TValidationMessages read fValidationMessages;
end;

// TEntity es la clase de la que derivan todas las Entidades
TEntityList = specialize TFPGObjectlist<TEntity>;

implementation
{ TEntity }

procedure TEntity.setCaption(aValue: string);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  SetFieldString(fCaption, aValue);
  DebugLnExit();
end;

procedure TEntity.setID(aValue: integer);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  SetFieldInteger(fID, aValue);
  DebugLnExit();
end;

constructor TEntity.Create;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  inherited Create;
  fState := esNew;
  fValidationMessages := TValidationMessages.Create;
  fLoadingCount := 0;

  // Inicializar metadata
  fMetadata.CreatedAt := Now;
  fMetadata.ModifiedAt := Now;
  fMetadata.Version := 1;
  DebugLnExit();
end;

destructor TEntity.Destroy;
begin
  FreeAndNil(fValidationMessages);
  inherited Destroy;
end;

procedure TEntity.setState(aValue: TEntityState);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if fState = aValue then Exit;
  fState := aValue;
  if fState in [esModified, esNew] then
    UpdateModifiedMetadata;
  DebugLnExit();
end;

procedure TEntity.UpdateModifiedMetadata;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fMetadata.ModifiedAt := Now;
  Inc(fMetadata.Version);
  DebugLnExit();
end;

procedure TEntity.MarkAsModified;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if IsLoading then Exit;
  if fState = esNew then Exit;
  if fState = esUnchanged then
    State := esModified;
  DebugLnExit();
end;

procedure TEntity.MarkAsDeleted;
begin
  State := esDeleted;
end;

function TEntity.Validate: Boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fValidationMessages.Clear;
  DoValidate;
  Result := IsValid;
  DebugLnExit();
end;

function TEntity.IsValid: Boolean;
var
  i: Integer;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  Result := True;
  for i := 0 to fValidationMessages.Count - 1 do
    if fValidationMessages[i].Severity = vsError then
    begin
      Result := False;
      Break;
    end;
  DebugLnExit();
end;

procedure TEntity.DoValidate;
begin
  // Las clases descendientes implementarán sus propias validaciones
end;

procedure TEntity.DoSerializeFields(aSerializer: TEntitySerializer);
begin
  // Hook para que las entidades hijas añadan sus campos específicos
  // Por defecto no añade nada - las clases derivadas sobrescriben este método
end;

procedure TEntity.DoDeserializeFields(aDeserializer: TEntityDeserializer);
begin
  // Hook para que las entidades hijas lean sus campos específicos
  // Por defecto no hace nada - las clases derivadas sobrescriben este método
end;

function TEntity.ToJSONString: string;
var
  serializer: TEntitySerializer;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  serializer := TEntitySerializer.Create;
  try
    // Campos base de TEntity
    serializer.AddField('id', fID);
    serializer.AddField('caption', fCaption);
    
    // Metadata y estado
    serializer.AddMetadata(fMetadata);
    serializer.AddState(fState);
    
    // Permitir que descendientes añadan sus campos
    DoSerializeFields(serializer);
    
    Result := serializer.GetJSONString;
  finally
    serializer.Free;
  end;
  DebugLnExit();
end;

procedure TEntity.FromJSONString(const aStr: string);
var
  deserializer: TEntityDeserializer;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  
  if aStr = '' then Exit;
  
  deserializer := TEntityDeserializer.CreateFromString(aStr);
  try
    BeginLoad;
    try
      // Campos base de TEntity
      fID := deserializer.GetInteger('id', 0);
      fCaption := deserializer.GetString('caption', '');
      
      // Metadata y estado
      deserializer.GetMetadata(fMetadata);
      fState := deserializer.GetState(esUnchanged);
      
      // Permitir que descendientes lean sus campos
      DoDeserializeFields(deserializer);
    finally
      EndLoad;
    end;
  finally
    deserializer.Free;
  end;
  DebugLnExit();
end;

// Nuevos métodos de carga y helpers
function TEntity.GetIsLoading: Boolean;
begin
  Result := fLoadingCount > 0;
end;

procedure TEntity.BeginLoad;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  Inc(fLoadingCount);
  DebugLnExit();
end;

procedure TEntity.EndLoad;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  Dec(fLoadingCount);
  if fLoadingCount < 0 then
    fLoadingCount := 0;
  DebugLnExit();
end;

function TEntity.SetFieldString(var aField: string; const aValue: string): Boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if aField = aValue then
    Exit(False);
  aField := aValue;
  if not IsLoading then
    MarkAsModified;
  Result := True;
  DebugLnExit();
end;

function TEntity.SetFieldInteger(var aField: Integer; const aValue: Integer): Boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if aField = aValue then
    Exit(False);
  aField := aValue;
  if not IsLoading then
    MarkAsModified;
  Result := True;
  DebugLnExit();
end;

function TEntity.SetFieldBoolean(var aField: Boolean; const aValue: Boolean): Boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if aField = aValue then
    Exit(False);
  aField := aValue;
  if not IsLoading then
    MarkAsModified;
  Result := True;
  DebugLnExit();
end;

procedure TEntity.UpdateMetadata(const aCreatedBy: string);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  BeginLoad;
  try
    fMetadata.CreatedAt := Now;
    fMetadata.CreatedBy := aCreatedBy;
    fMetadata.Version := 1;
  finally
    EndLoad;
  end;
  DebugLnExit();
end;

procedure TEntity.UpdateMetadata(const aModifiedBy: string; const aVersion: Integer);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  BeginLoad;
  try
    fMetadata.ModifiedAt := Now;
    fMetadata.ModifiedBy := aModifiedBy;
    fMetadata.Version := aVersion;
  finally
    EndLoad;
  end;
  DebugLnExit();
end;

{--- Mapeo directo DB ↔ Entity --------------------------------------------------------------------}

procedure TEntity.LoadFromQuery(aQuery: TSQLQuery);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  BeginLoad;
  try
    DoLoadFromQuery(aQuery);
    fState := esUnchanged;  // La entidad viene de la BD, está sincronizada
  finally
    EndLoad;
  end;
  DebugLnExit();
end;

procedure TEntity.SaveToQuery(aQuery: TSQLQuery);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  DoSaveToParams(aQuery);
  DebugLnExit();
end;

procedure TEntity.DoLoadFromQuery(aQuery: TSQLQuery);
begin
  // Implementación por defecto vacía
  // Las clases derivadas deben implementar este método
end;

procedure TEntity.DoSaveToParams(aQuery: TSQLQuery);
begin
  // Implementación por defecto vacía
  // Las clases derivadas deben implementar este método
end;

end.

