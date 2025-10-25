unit entity_serializers;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, fw_typedef;

type
  { TEntitySerializer - Helper para serializar entidades a JSON
    Responsabilidades:
    - Abstraer la complejidad de fpjson de las entidades
    - Proporcionar API simple y type-safe para añadir campos
    - Manejar tipos comunes y conversiones
    Principios SOLID aplicados:
    - SRP: Solo se encarga de construir JSON
    - OCP: Extensible vía métodos AddField sobrecargados
    - DIP: Las entidades dependen de esta abstracción, no de fpjson directamente }
  
  TEntitySerializer = class
  private
    fJSON: TJSONObject;
    fMetaObj: TJSONObject;
  public
    constructor Create;
    destructor Destroy; override;
    
    // Métodos para añadir campos de diferentes tipos
    procedure AddField(const AName: string; AValue: Integer); overload;
    procedure AddField(const AName: string; const AValue: string); overload;
    procedure AddField(const AName: string; AValue: Boolean); overload;
    procedure AddField(const AName: string; AValue: Double); overload;
    procedure AddField(const AName: string; AValue: TDateTime); overload;
    
    // Métodos para metadata común
    procedure AddMetadata(const AMetadata: TEntityMetadata);
    procedure AddState(AState: TEntityState);
    
    // Obtener el JSON construido
    function GetJSON: TJSONObject;
    function GetJSONString: string;
  end;

  { TEntityDeserializer - Helper para deserializar JSON a entidades
    Responsabilidades:
    - Abstraer la complejidad de fpjson de las entidades
    - Proporcionar API simple y type-safe para leer campos
    - Manejar campos opcionales con valores por defecto
    Principios SOLID aplicados:
    - SRP: Solo se encarga de leer JSON
    - LSP: Comportamiento predecible con valores por defecto
    - ISP: Interface mínima, solo lo necesario }
  
  TEntityDeserializer = class
  private
    fJSON: TJSONObject;
    fMetaObj: TJSONObject;
    fOwnsJSON: Boolean;
  public
    constructor Create(AObj: TJSONObject; AOwnsJSON: Boolean = False);
    constructor CreateFromString(const AJSONString: string);
    destructor Destroy; override;
    
    // Métodos para leer campos con valores por defecto
    function GetInteger(const AName: string; ADefault: Integer = 0): Integer;
    function GetString(const AName: string; const ADefault: string = ''): string;
    function GetBoolean(const AName: string; ADefault: Boolean = False): Boolean;
    function GetDouble(const AName: string; ADefault: Double = 0.0): Double;
    function GetDateTime(const AName: string; ADefault: TDateTime = 0): TDateTime;
    
    // Verificar existencia de campos
    function HasField(const AName: string): Boolean;
    
    // Métodos para metadata común
    procedure GetMetadata(out AMetadata: TEntityMetadata);
    function GetState(ADefault: TEntityState = esUnchanged): TEntityState;
  end;

implementation

{ TEntitySerializer }

constructor TEntitySerializer.Create;
begin
  inherited Create;
  fJSON := TJSONObject.Create;
  fMetaObj := nil; // Se crea bajo demanda
end;

destructor TEntitySerializer.Destroy;
begin
  FreeAndNil(fJSON);
  // fMetaObj es propiedad de fJSON, se libera automáticamente
  inherited Destroy;
end;

procedure TEntitySerializer.AddField(const AName: string; AValue: Integer);
begin
  fJSON.Add(AName, AValue);
end;

procedure TEntitySerializer.AddField(const AName: string; const AValue: string);
begin
  fJSON.Add(AName, AValue);
end;

procedure TEntitySerializer.AddField(const AName: string; AValue: Boolean);
begin
  fJSON.Add(AName, AValue);
end;

procedure TEntitySerializer.AddField(const AName: string; AValue: Double);
begin
  fJSON.Add(AName, AValue);
end;

procedure TEntitySerializer.AddField(const AName: string; AValue: TDateTime);
begin
  fJSON.Add(AName, DateTimeToStr(AValue));
end;

procedure TEntitySerializer.AddMetadata(const AMetadata: TEntityMetadata);
begin
  if fMetaObj = nil then
  begin
    fMetaObj := TJSONObject.Create;
    fJSON.Add('meta', fMetaObj);
  end;
  
  fMetaObj.Add('version', AMetadata.Version);
  
  if AMetadata.CreatedAt <> 0 then
    fMetaObj.Add('created_at', DateTimeToStr(AMetadata.CreatedAt));
  if AMetadata.ModifiedAt <> 0 then
    fMetaObj.Add('modified_at', DateTimeToStr(AMetadata.ModifiedAt));
  if AMetadata.CreatedBy <> '' then
    fMetaObj.Add('created_by', AMetadata.CreatedBy);
  if AMetadata.ModifiedBy <> '' then
    fMetaObj.Add('modified_by', AMetadata.ModifiedBy);
end;

procedure TEntitySerializer.AddState(AState: TEntityState);
begin
  if fMetaObj = nil then
  begin
    fMetaObj := TJSONObject.Create;
    fJSON.Add('meta', fMetaObj);
  end;
  
  fMetaObj.Add('state', Ord(AState));
end;

function TEntitySerializer.GetJSON: TJSONObject;
begin
  Result := fJSON;
end;

function TEntitySerializer.GetJSONString: string;
begin
  Result := fJSON.AsJSON;
end;

{ TEntityDeserializer }

constructor TEntityDeserializer.Create(AObj: TJSONObject; AOwnsJSON: Boolean);
begin
  inherited Create;
  fJSON := AObj;
  fOwnsJSON := AOwnsJSON;
  
  // Buscar objeto meta si existe
  if fJSON.Find('meta') <> nil then
    fMetaObj := fJSON.Objects['meta']
  else
    fMetaObj := nil;
end;

constructor TEntityDeserializer.CreateFromString(const AJSONString: string);
var
  data: TJSONData;
begin
  if AJSONString = '' then
    raise Exception.Create('JSON string is empty');
    
  data := GetJSON(AJSONString);
  if data.JSONType <> jtObject then
  begin
    data.Free;
    raise Exception.Create('JSON is not an object');
  end;
  
  Create(TJSONObject(data), True); // Toma ownership del JSON
end;

destructor TEntityDeserializer.Destroy;
begin
  if fOwnsJSON then
    FreeAndNil(fJSON);
  inherited Destroy;
end;

function TEntityDeserializer.GetInteger(const AName: string; ADefault: Integer): Integer;
begin
  if fJSON.Find(AName) <> nil then
    Result := fJSON.Integers[AName]
  else
    Result := ADefault;
end;

function TEntityDeserializer.GetString(const AName: string; const ADefault: string): string;
begin
  if fJSON.Find(AName) <> nil then
    Result := fJSON.Strings[AName]
  else
    Result := ADefault;
end;

function TEntityDeserializer.GetBoolean(const AName: string; ADefault: Boolean): Boolean;
begin
  if fJSON.Find(AName) <> nil then
    Result := fJSON.Booleans[AName]
  else
    Result := ADefault;
end;

function TEntityDeserializer.GetDouble(const AName: string; ADefault: Double): Double;
begin
  if fJSON.Find(AName) <> nil then
    Result := fJSON.Floats[AName]
  else
    Result := ADefault;
end;

function TEntityDeserializer.GetDateTime(const AName: string; ADefault: TDateTime): TDateTime;
begin
  if fJSON.Find(AName) <> nil then
    Result := StrToDateTimeDef(fJSON.Strings[AName], ADefault)
  else
    Result := ADefault;
end;

function TEntityDeserializer.HasField(const AName: string): Boolean;
begin
  Result := fJSON.Find(AName) <> nil;
end;

procedure TEntityDeserializer.GetMetadata(out AMetadata: TEntityMetadata);
begin
  if fMetaObj = nil then
  begin
    // Valores por defecto
    AMetadata.Version := 1;
    AMetadata.CreatedAt := Now;
    AMetadata.ModifiedAt := Now;
    AMetadata.CreatedBy := '';
    AMetadata.ModifiedBy := '';
    Exit;
  end;
  
  if fMetaObj.Find('version') <> nil then
    AMetadata.Version := fMetaObj.Integers['version']
  else
    AMetadata.Version := 1;
    
  if fMetaObj.Find('created_at') <> nil then
    AMetadata.CreatedAt := StrToDateTimeDef(fMetaObj.Strings['created_at'], Now)
  else
    AMetadata.CreatedAt := Now;
    
  if fMetaObj.Find('modified_at') <> nil then
    AMetadata.ModifiedAt := StrToDateTimeDef(fMetaObj.Strings['modified_at'], Now)
  else
    AMetadata.ModifiedAt := Now;
    
  if fMetaObj.Find('created_by') <> nil then
    AMetadata.CreatedBy := fMetaObj.Strings['created_by']
  else
    AMetadata.CreatedBy := '';
    
  if fMetaObj.Find('modified_by') <> nil then
    AMetadata.ModifiedBy := fMetaObj.Strings['modified_by']
  else
    AMetadata.ModifiedBy := '';
end;

function TEntityDeserializer.GetState(ADefault: TEntityState): TEntityState;
begin
  if (fMetaObj <> nil) and (fMetaObj.Find('state') <> nil) then
    Result := TEntityState(fMetaObj.Integers['state'])
  else
    Result := ADefault;
end;

end.
