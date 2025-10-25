unit mediator_cl;

{$mode ObjFPC} {$H+}
{$IFOPT D+} {$DEFINE DEBUG} {$ENDIF}

interface

uses
  Classes, SysUtils, fgl, TypInfo, Variants,
  Controls, stdctrls, editbtn,                  // Unit donde se definen los controles
  {$IFDEF debug} LazLoggerBase, {$ELSE}  LazLoggerDummy,{$ENDIF}
  fw_typedef, entity_cl;

type

TGUIType = (gtString, gtInteger, gtFloat, gtDate);

TMediator = class;

{ TBaseControlMediator }

TBaseControlMediator = class(TControl)
  private
    fMediator          : TMediator;
    fReadOnly          : boolean;
    fGUIControl        : TControl;
    fGUIType           : TGUIType;
    fViewPropertyName  : string;      // Propiedad del control que almacena el valor que se debe asignar a fEntityProperty
    fEntityPropertyName: string;      // Propiedad del Entity relacionada con el control
    procedure SetGUIControl(aValue: TControl);
    procedure SetGUIType(aValue: TGUIType);
    procedure setMediator(aValue: TMediator);
    procedure SetReadOnly(aValue: boolean);
    procedure SetViewPropertyName(aValue: string);
    procedure InternalOnChange(Sender: TObject);
  published
    constructor {%H-}create(TheOwner: TComponent; Ctrl: TControl; const aFieldName: string); virtual;
    property ReadOnly: boolean read fReadOnly write SetReadOnly;
    property GUIControl: TControl read fGUIControl write SetGUIControl ;
    property GUIType: TGUIType read fGUIType write SetGUIType;
    property ViewPropertyName: string read fViewPropertyName write SetViewPropertyName;
    property Mediator: TMediator read fMediator write setMediator;
end;

TControlList = specialize TFPGMap<string, TBaseControlMediator>;

{ TEditMediator }

TEditMediator = class(TBaseControlMediator)
  public
    Constructor {%H-}Create(TheOwner: TComponent; Ctrl: TControl; const aFieldName: string); override;
end;

{ TLabelMediator }

TLabelMediator = class(TBaseControlMediator)
  public
    Constructor {%H-}Create(TheOwner: TComponent; Ctrl: TControl; const aFieldName: string); override;
end;

{ TDateEditMediator }

TDateEditMediator = class(TBaseControlMediator)
  public
    Constructor {%H-}Create(TheOwner: TComponent; Ctrl: TControl; const aFieldName: string); override;
end;

{ TCheckBoxMediator }

TCheckBoxMediator = class(TBaseControlMediator)
  public
    Constructor {%H-}Create(TheOwner: TComponent; Ctrl: TControl; const aFieldName: string); override;
end;

{ TMediator }

TMediator = class
  private
    fControlList : TControlList;
    fEntity      : TEntity;
    fManager     : TObject;
    fModified    : Boolean;
    procedure SetEntity(aValue: TEntity);
    procedure setManager(aValue: TObject);
    procedure setModified(aValue: Boolean);
    procedure WriteToControl(ctrl: TBaseControlMediator);
  protected
  public
    property    Entity: TEntity read fEntity write SetEntity;
    property    Modified: Boolean read fModified write setModified;
    property    Manager: TObject read fManager write setManager;
    constructor Create;
    destructor  Destroy; override;
    procedure   ReadOnly(AFieldName: string);
    procedure   addCtrl(aGUIControl : TBaseControlMediator);
    procedure   SetAllControlsEditMode(Mode: TEditMode);
    procedure   WriteToControls(const EntityPropName: string = '');
    procedure   WriteToEntity;
end;


implementation
uses basemanager_cl;

{ TMediator }

{-------------------------------------------------------------------------------
 Métodos internos de la clase
 ------------------------------------------------------------------------------}
constructor TMediator.Create;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  fControlList:= TControlList.create;
  fModified:= True;
  DebugLnExit();
end;

destructor TMediator.Destroy;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fControlList.Free;
  inherited Destroy;
  DebugLnExit();
end;

procedure TMediator.addCtrl(aGUIControl: TBaseControlMediator);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  fControlList.Add(aGUIControl.FEntityPropertyName, aGUIControl);
  aGUIControl.Mediator:= Self;
  DebugLnExit();
end;

{-------------------------------------------------------------------------------
 Métodos para establecer el modo de edición de los controles
-------------------------------------------------------------------------------}
procedure TMediator.ReadOnly(AFieldName: string);
var
  Ctrl : TBaseControlMediator;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  Ctrl := nil;
  if fControlList{%H-}.TryGetData(AFieldName, Ctrl) then
     ctrl.ReadOnly:= True;
  DebugLnExit();
end;

procedure TMediator.SetAllControlsEditMode(Mode: TEditMode);
{---------------------------------------------------------------------------------------------------
 Muchos controles disponen de la propiedad ReadOnly para que no puedan editarse pero algunos no
 disponen de esa propiedad y la única posibilidad para evitar que se puedan editar es poner en false
 su propiedad Enabled.
 Mezclar ambos métodos da lugar a una visualización no uniforme por lo que he optado por usar Enabled
 en todos los casos.
---------------------------------------------------------------------------------------------------}
var
  i: Integer;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  for i:= 0 to fControlList.count-1 do
    begin
//      if not fControlList.Data[i].ReadOnly then
//        SetPropValue(fControlList.Data[i].GUIControl, 'Enabled', emReadOnly)
//      else
        SetPropValue(fControlList.Data[i].GUIControl, 'Enabled', Mode);
    end;
    DebugLnExit();
end;

{---------------------------------------------------------------------------------------------------
 Métodos para traspasar la información entre el Entity y los controles
---------------------------------------------------------------------------------------------------}
{ #todo : Cuando se salven los datos a la BD hay que verificar como se recuperan y se guardan los
 valores nulos.
En firebird, para salvarlos, se utiliza el valor 'NULL'. p. ej.:
insert into MiTabla values (1, 'cadena', NULL, '8/5/2004') }
procedure TMediator.WriteToControls(const EntityPropName: string);
var
  ctrl: TBaseControlMediator;
  i: Integer;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  If EntityPropName = '' then
    for i:= 0 to fControlList.count-1 do
      WriteToControl(fControlList.Data[i])
  else
    if fControlList{%H-}.TryGetData(EntityPropName, Ctrl) then
      WriteToControl(ctrl);
   DebugLnExit();
end;

procedure TMediator.WriteToControl(ctrl: TBaseControlMediator);
var
  value: Variant;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  value:= GetPropValue(FEntity, Ctrl.FEntityPropertyName);
  if ctrl.FGUIType = gtDate then
    if Value = 0 then
       Value := ''
    else
       Value:= VarToDateTime(Value);
  SetPropValue(Ctrl.GUIControl, ctrl.ViewPropertyName, Value);
  DebugLnExit();
end;

procedure TMediator.WriteToEntity;
var
  i: Integer;
  value: Variant;
  d: TDate;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  for i:= 0 to fControlList.count-1 do
  begin
    value:= GetPropValue(fControlList.Data[i].GUIControl, fControlList.Data[i].ViewPropertyName);
    if fControlList.Data[i].fGUIType = gtDate then
      if TryStrToDate(VarToStr(Value), d) then
        Value:= d
      else
        Value:= 0;
    SetPropValue(FEntity,fControlList.Data[i].FEntityPropertyName, Value);
  end;
  DebugLnExit();
end;

{-------------------------------------------------------------------------------
 Metodos Get/Set
 ------------------------------------------------------------------------------}
procedure TMediator.SetEntity(aValue: TEntity);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  if fEntity = aValue then Exit;
  fEntity:= aValue;
  WriteToControls;
  DebugLnExit();
end;

procedure TMediator.setManager(aValue: TObject);
begin
  if fManager= aValue then Exit;
  fManager:= aValue;
end;

procedure TMediator.setModified(aValue: Boolean);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if fModified= aValue then Exit;
  fModified:= aValue;
  TBaseManager(FManager).SetMgrAction(maDFUpdate);
  DebugLnExit();
end;

{-------------------------------------------------------------------------------
 Mediadores
-------------------------------------------------------------------------------}
{ TBaseControlMediator }

constructor TBaseControlMediator.create(TheOwner: TComponent; Ctrl: TControl;
  const aFieldName: string);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  inherited Create(TheOwner);
  fEntityPropertyName:= aFieldName;
  fGUIType:= gtString;
  fGUIControl:= Ctrl;
  fReadOnly:= false;
  DebugLnExit();
end;

 procedure TBaseControlMediator.SetGUIControl(aValue: TControl);
begin
  if fGUIControl = aValue then Exit;
  fGUIControl:= aValue;
end;

procedure TBaseControlMediator.SetGUIType(aValue: TGUIType);
begin
  if fGUIType = aValue then Exit;
  fGUIType:= aValue;
end;

procedure TBaseControlMediator.setMediator(aValue: TMediator);
begin
  if fMediator= aValue then Exit;
  fMediator:= aValue;
end;

procedure TBaseControlMediator.SetReadOnly(aValue: boolean);
begin
  if fReadOnly = aValue then Exit;
  fReadOnly:= aValue;
end;

procedure TBaseControlMediator.SetViewPropertyName(aValue: string);
begin
  if fViewPropertyName = aValue then Exit;
  fViewPropertyName:= aValue;
end;

procedure TBaseControlMediator.InternalOnChange(Sender: TObject);
begin
  if not TMediator(Mediator).Modified then
    TMediator(Mediator).Modified:= True;
end;

{ TEditMediator }

constructor TEditMediator.Create(TheOwner: TComponent; Ctrl: TControl; const aFieldName: string);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  inherited Create(TheOwner, Ctrl, aFieldName);
  fViewPropertyName:='Text';
  if Ctrl is TCustomEdit then
    TCustomEdit(Ctrl).OnChange:= @InternalOnChange;
  if Ctrl is TCustomComboBox then
    TComboBox(Ctrl).OnChange:= @InternalOnChange;
  DebugLnExit();
end;

{ TLabelMediator }

constructor TLabelMediator.Create(TheOwner: TComponent; Ctrl: TControl; const aFieldName: string);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  inherited Create(TheOwner, Ctrl, aFieldName);
  fViewPropertyName:='Caption';
  DebugLnExit();
end;

{ TDateEditMediator }

constructor TDateEditMediator.Create(TheOwner: TComponent; Ctrl: TControl; const aFieldName: string);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  inherited Create(TheOwner, Ctrl, aFieldName);
  fViewPropertyName:='Text';
  fGUIType:= gtDate;
  if Ctrl is TDateEdit then
    TDateEdit(Ctrl).OnChange:= @InternalOnChange;
  DebugLnExit();
end;

{ TCheckBoxMediator }

constructor TCheckBoxMediator.Create(TheOwner: TComponent; Ctrl: TControl; const aFieldName: string);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);  
  inherited Create(TheOwner, Ctrl, aFieldName);
  fViewPropertyName:='Checked';
  fGUIType:= gtInteger;
  if Ctrl is TCheckBox then
    TCheckBox(Ctrl).OnChange:= @InternalOnChange;
  DebugLnExit();
end;
end.



