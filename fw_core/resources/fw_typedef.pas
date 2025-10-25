unit fw_typedef;

{$mode ObjFPC}{$H+}


interface

uses
  Classes, SysUtils, fgl, DB;  //, entity_cl

const

  // [s]earcher [m]odes of TSearcher
  smIdle      = 0;    // No se utiliza
  smSearcher  = 1;    // Ejecución del buscador estandar
  smParams    = 2;    // Análisis de parámetro tecleado en el Browser
  smPredefined= 3;    // Selección de consulta predefinida en el menú desplegable
  smAdvanced  = 4;    // Ejecución del buscador en modo avanzado

  // [f]ield [t]ype in [s]earcher
  ftsString = 0;      // String type
  ftsNumeric= 1;      // Numeric Type

  // [p]redicates for [s]tring used in TSearcher
  psStartingWith  = 0;
  psContains      = 1;
  psGreaterThan   = 2;
  psLowerThan     = 3;
  psBetween       = 4;

  // [p]redicates for [n]umbers used in TSearcher
  pnEqual       = 0;
  pnGreaterThan = 1;
  pnLowerThan   = 2;
  pnBetween     = 3;

  // [D]F operation [m]odes
  dmShowEntity   = 0;
  dmInsertEntity = 1;
  dmUpdateEntity = 2;

  // [m]ove [t]o [e]ntity
  mtePrior= -1;
  mteNext = 1;

  // [s]ave [m]ode
  smSave      =  0;
  smSaveAndNew= 1;

type
  TManagerMode = (mmIdle, mmBrowsing, mmBrowsingReadonly, mmSelectingRow, mmShowing, mmNavegating,
                  mmInserting, mmSaving, mmUpdating, mmDeleting, mmSearchExtern, mmSearching );

  TManagerAction = (maShowBrowser, maRowSelected, maDeleteEntity, maMovetoEntity, maSaveEntity,
                    maSearch, maSearchPredef, maSearchExtern, maSearchResult, maDFStart, maDFCLose,
                    maDFUpdate);   // <-

  TEditMode = (emReadOnly, emReadWrite);

  // MasterField Data
  TNameValue = record
    Name: string;
    Value: LongInt;
  end;

  // Parameter Data
  TParamData = record
    Caption: String;
    Value: String;
  end;

  TParamList = array of TParamData;

  TPredefQuery = record
    Query: string;
    Caption: string;
    FieldName: string;
    FieldType: byte;
    Criteria: byte;
    Isdefault: Boolean;
    Params: TParamList
  end;

  TPredefQueries = array of TPredefQuery;
  PPredefQueries = ^TPredefQueries;

  // Información básica de los campos físicos de la BD
  TFieldInfo = class
    DisplayLabel: string;
    FieldName   : string;
    FieldType   : TFieldType;
    FieldKind   : TFieldKind;
  end;

  TFieldInfoList = specialize TFPGMapObject <integer,TFieldInfo>;

  // Información con los datos de búsqueda
  TSearchValues = record
     FieldID: Integer;
     Field: string;
     CriteriaID: Integer;
     Criteria: string;
     SortByID: Integer;
     SortBy: string;
     ValueFrom: string;
     ValueTo: string;
  end;
  PSearchValues = ^TSearchValues;

  TSearchValuesList = array of TSearchValues;
  PSearchValuesList = ^TSearchValuesList;

  TSearchResult = record
     NumberOfRecords: string;
     FieldName: string;
     Criteria: string;
     QryHasParams: boolean;
  end;
  PSearchResult = ^TSearchResult;

  // Estado de la Entidad
  TEntityState = (
    esUnchanged,    // Estado inicial/sin cambios
    esNew,          // Entidad nueva
    esModified,     // Entidad modificada
    esDeleted       // Entidad marcada para eliminar
  );

  // Resultado de la validación
  TValidationSeverity = (
    vsInfo,         // Información
    vsWarning,      // Advertencia
    vsError         // Error que impide guardar
  );

  // Esta clase debería ser un Record pero este tipo de datos no se puede almacenar en un TFPGList.
  // Por lo tanto creo una clase lo que conlleva que para TValidationMessages hay que utilizar TFPGObjectList
  TValidationMessage = class
  public
    PropertyName: string;
    Message: string;
    Severity: TValidationSeverity;
    constructor Create(const APropertyName, AMessage: string; ASeverity: TValidationSeverity);
  end;

  TValidationMessages = specialize TFPGObjectList<TValidationMessage>;

  TEntityMetadata = record
    CreatedAt: TDateTime;    // Fecha y hora de creación
    ModifiedAt: TDateTime;   // Fecha y hora de modificación
    CreatedBy: string;       // Usuario que la crea
    ModifiedBy: string;      // Usuario que la modifica
    Version: Integer;        // Número de versión
  end;


  // Clase definida para poder crear el diccionario TLookupList. La información es la misma que la
  // del record TNameValue por lo que quizá podrían fusionarse.
  TLookupItem = class
    id    : integer;
    value : string;
  end;

  TLookupItemList = specialize TFPGObjectlist<TLookupItem>;
  TLookupList     = specialize TFPGMapObject <string,TLookupItemList>;


implementation

{ TValidationMessage }

constructor TValidationMessage.Create(const APropertyName, AMessage: string; ASeverity: TValidationSeverity);
begin
  PropertyName := APropertyName;
  Message := AMessage;
  Severity := ASeverity;
end;

end.

