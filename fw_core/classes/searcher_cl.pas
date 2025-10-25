unit Searcher_cl;

{$mode ObjFPC}{$H+}
{$IFOPT D+} {$DEFINE DEBUG} {$ENDIF}

interface

uses
  Classes, SysUtils, forms, DB, sqldb, Dialogs, Menus,
  {$IFDEF debug} LazLoggerBase, {$ELSE}  LazLoggerDummy,{$ENDIF}
  fw_typedef, searcher_f;

const
  // Códigos devueltos por CheckRecordCount
  crcCreateNewQuery = 1;
  crcLeaveSearcher = 2;
  crcQueryOK = 3;

type
  { TSearcher }

  TSearcher = class
  private
    fPredefQuery     : TPredefQuery;      // Consulta predefinida
    fSearcherMode    : integer;           // MOdo de ejecución del Buscador
    fStartQry        : string;            // Query auxiliar para uso del Searcher
    fLastQry         : string;            // Última búsqueda generada
    fFinalQry        : string;            // Query final con la que se ejecuta la búsqueda
    fPredicate       : String;            // Variable auxiliar para crear fFinalQry
    fSearchResult    : PSearchResult;
    fStatementIsOK   : Boolean;           // Determina si la query generada es correcta
    fTableName       : string;            // Nombre de la tabla sobre la que se ejecuta la Query
    fFqryRecordCount : TSQLQuery;         // SQLQuery de uso interno
    fTransaction     : TSQLTransaction;
    fFieldsSearch    : TFieldInfoList;    // Lista de campos que intervienen en la búsqueda         //<--
    fSearchValuesList: PSearchValuesList; // Datos seleccionados por el usuario en frmSearcher
    fMaxRowsReturn   : integer;           // Nº máximo de registros que puede devolver una consulta
    fNumberOfRecords : integer;           // Nº de registros que devuelve una consulta
    fItemsSearch     : TStringList;       // items de cmbSearchField
    fItemsSort       : TStringList;       // items de cmbSortBy
    fItemsString     : TStringList;       // items de cmbCriteria para campos de string
    fItemsNumeric    : TStringList;       // items de cmbCriteria para campos numéricos
    fParam0          : string;            // Parámetros con los que
    fParam1          : string;            // se va a ejecutar la consulta
    fQryHasChanged   : Boolean;           // Determina si la consulta obtenida modifica la anterior
    fSearchForm      : TfrmSearcher;      // Diálogo del buscador
    fQryHasParams    : Boolean;           // Determina si la consulta en curso tiene parámetros     //<--
    procedure setNumberOfRecords(aValue: integer);                                                  
    procedure setPredefQuery(aValue: TPredefQuery);                                                 //<--
    procedure setSearcherMode(aValue: integer);                                                     //<--
    procedure setSearchResult(aValue: PSearchResult);                                               
    procedure setSearchValuesList(aValue: PSearchValuesList);                                       
    procedure setStartQry(aValue: string);                                                          
    procedure SetTableName(AValue: string);                                                         
  //  procedure FillSearchValuesList;
    procedure GenerateSQL;               // Genera la consulta a partir de los datos devueltos por frmSearcher   //<--
    function  CheckRecordCount: integer; // Verifica el número de registros devueltos por la consulta            //<--
    function  SQLParser(aSQL: string): string;                                                      //<--
  protected
    procedure CheckQueryAdvanced;                                                                   //<--
    procedure CheckQueryPredef;                                                                     //<--
    procedure CheckQuerySearcher(var QueryOK: Boolean);                                             //<--
    procedure GetStatusInfo;                                                                        //<--
    procedure Execute;                                                                              //<--
    procedure CheckQuery(var QueryOK: Boolean);                                                     //<--

  public
    menPredefQueries : TPopupMenu;

    constructor Create;                                                                             //<--
    destructor  Destroy; override;                                                                  

    property  StatementIsOK: Boolean read fStatementIsOK;
    property  StartQry     : string read fStartQry write setStartQry;
    property  TableName    : string read fTableName write SetTableName;
    property  FinalQry     : string read fFinalQry;
    property  Param0       : string read fParam0;
    property  Param1       : string read fParam1;
    property  PredefQuery  : TPredefQuery read fPredefQuery write setPredefQuery;
    property  SearchValuesList: PSearchValuesList read fSearchValuesList write setSearchValuesList; //<--
    property  SearcherMode : integer read fSearcherMode write setSearcherMode;
    property  SearchResult : PSearchResult  read fSearchResult write setSearchResult;
    property  NumberOfRecords: integer read fNumberOfRecords write setNumberOfRecords;

    procedure StartSearcher;                                                                        
    procedure ItemSearchChange(const index: Integer);                                               
    procedure AdvancedMode(const aAdvancedMode: Boolean);                                           
    procedure SetFieldsForSearch(FieldList: TFieldInfoList);                                        

  end;

implementation

uses
  Controls,
  fw_resourcestrings, master_dm, fw_config, params_f;

{ TSearcher }

// TSearcher debería ser independiente de master_dm
constructor TSearcher.Create;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fFqryRecordCount := TSQLQuery.Create(nil);
  if dmMaster.SQLConnector1.ConnectorType <> 'SQLite3' then
  begin
    fTransaction := TSQLTransaction.Create(fFqryRecordCount);
    fTransaction.DataBase := dmMaster.SQLConnector1;
  end;
  fFqryRecordCount.DataBase := dmMaster.SQLConnector1;
  fMaxRowsReturn:= vcfMaxRowsReturned;
  // Los objetos contenidos en fFieldsSearch no se pueden borrar porque, realmente, son objetos que
  // están ubicados en fFieldsInfo. De hacerlo, al intentar borrarlos en fFieldsInfo, se produce una VM
  fFieldsSearch:= TFieldInfoList.Create(False);
  fItemsSearch:= TStringList.Create;
  fItemsSort:= TStringList.Create;
  fItemsString:= TStringList.Create;
  fItemsNumeric:= TStringList.Create;
  DebugLnExit()
end;

destructor TSearcher.Destroy;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fItemsSearch.Free;
  fItemsSort.Free;
  fItemsString.Free;
  fItemsNumeric.Free;;
  fFieldsSearch.Free;
  fFqryRecordCount.Close;
  FreeAndNil(fFqryRecordCount);
  FreeAndNil(fSearchForm);
  inherited Destroy;
  DebugLnExit()
end;

procedure TSearcher.Execute;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if Assigned(fSearchForm) then
    fSearchForm.ShowModal
  else
    begin
      fSearchForm:= TfrmSearcher.Create(Application.MainForm);
      with fSearchForm do
        begin
          Caption:= 'Buscador de registros';
          ItemsSearch:= fItemsSearch;
          ItemsSort:= fItemsSort;
          ItemSearchChange(0);
          OnItemSearchChange:= @ItemSearchChange;
          OnCheckToClose:= @CheckQuery;
          if vcfAllowAdvancedSearch then
            OnAdvancedMode:= @AdvancedMode;
          ShowModal;
          edtSearchFrom.Text:= fSearchValuesList^[0].ValueFrom;
        end;
  DebugLnExit()
  end;
end;

procedure TSearcher.StartSearcher;
var
  check: Boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if Length(fSearchValuesList^) = 0 then
    SetLength(fSearchValuesList^, 1);
//  fQryHasParams:= True;
  case fSearcherMode of
    smSearcher, smAdvanced: Execute;
    smParams, smPredefined: CheckQuery(check);
  end ;
  DebugLnExit()
end;

procedure TSearcher.ItemSearchChange(const index: Integer);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  case fFieldsSearch[index].FieldType of
    ftString: begin
                fSearchForm.cmbCriteria.Items:= fItemsString;
                fSearchForm.FieldType:= ftsString;
              end;
    ftSmallint, ftInteger, ftWord, ftFloat, ftCurrency, ftBCD:
              begin
                fSearchForm.cmbCriteria.Items:= fItemsNumeric;
                fSearchForm.FieldType:= ftsNumeric;
              end;
  end;
  fSearchForm.cmbCriteria.ItemIndex:= 0;
  fSearchForm.ShowSearchTo:= fSearchForm.cmbCriteria.Items.IndexOf(rsIsBetween);  // Ver documentación
  DebugLnExit()
end;

procedure TSearcher.CheckQuery(var QueryOK: Boolean);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fStatementIsOK:= False;
  case fSearcherMode of
    smPredefined: CheckQueryPredef;
    smAdvanced  : CheckQueryAdvanced;
    smSearcher  : CheckQuerySearcher(QueryOK);
    smParams    : GenerateSQL;
  end;
  if fStatementIsOK then begin
    Case CheckRecordCount of
      crcCreateNewQuery: QueryOK:= False;
      crcLeaveSearcher: begin                      // No formular nueva consulta y salir del buscador
                          fStatementIsOK:= False;
                          QueryOK:= True;
                        end;
      crcQueryOK: QueryOK:= True;                 // La consulta es correcta. Abandonar el buscador
    end;
  end;
  GetStatusInfo;
  DebugLnExit();
end;

procedure TSearcher.AdvancedMode(const aAdvancedMode: Boolean);
begin
  if aAdvancedMode then
  begin
    fSearcherMode:= smAdvanced;
    fSearchForm.memAdvanced.Lines.Text:= fFinalQry;
  end else
    fSearcherMode:= smSearcher;
  fQryHasParams:= (fSearcherMode= smSearcher);
end;

procedure TSearcher.GenerateSQL;
{---------------------------------------------------------------------------------------------------
 Genera la consulta a partir de los datos devueltos por frmSearcher.
 En este momento solo se considera un grupo de datos. Si se amplía, hay que modificar el código
---------------------------------------------------------------------------------------------------}
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fQryHasChanged:= False;
  fStatementIsOK:= True;
  case fFieldsSearch.Data[fSearchValuesList^[0].FieldID].FieldType of
    // Campos de texto
    ftString:
      begin
        case fSearchValuesList^[0].CriteriaID of
//          prStartingWith: fPredicate:= ' starting with :Param0';        // Empieza por ...  Para Firebird
          psStartingWith: begin
                             fPredicate:= ' like :Param0' ;
                             fParam0:= fSearchValuesList^[0].ValueFrom + '%';
                           end;
          psContains: begin
                         fPredicate:= ' like :Param0';
                         fParam0:= '%' + fSearchValuesList^[0].ValueFrom +
                           '%';
                       end;
          psGreaterThan: fPredicate:= ' > :Param0';
          psLowerThan: fPredicate:= ' < :Param0';
          psBetween: begin
                        fPredicate:= ' BETWEEN :Param0 AND :Param1';
                        fParam0:= fSearchValuesList^[0].ValueFrom + '%';
                        fParam1:= fSearchValuesList^[0].ValueTo;
                      end;
        end;
      end;
    // Campos numéricos
    ftSmallint, ftInteger, ftWord, ftFloat, ftCurrency, ftBCD:
      begin
        fParam0:= fSearchValuesList^[0].ValueFrom;
        case fSearchValuesList^[0].CriteriaID of
          pnEqual: fPredicate:= ' = :Param0';
          pnGreaterThan: fPredicate:= ' > :Param0';
          pnLowerThan: fPredicate:= ' < :Param0';
          pnBetween: begin
                        fPredicate:= ' BETWEEN :Param0 AND :Param1';
                        fParam1:= fSearchValuesList^[0].ValueTo;
                      end;
        end;
      end;
    else
      FStatementIsOK:= False;    // La opción False de fStatementIsOK nunca debería darse en este punto. Ver nota en documento
  end;
  if Assigned(fSearchForm) then
    fSearchForm.edtSearchFrom.Text:= fSearchValuesList^[0].ValueFrom;
  // No tiene sentido generar nuevamente la consulta si solo se han modificado los parámetros de ejecución
  if fStatementIsOK and (fSearcherMode <> smParams) then
  begin
    fFinalQry:= '';
    fFinalQry:= format ('%s Where %s %s order by %s limit %s',
                 [fStartQry,
                  fFieldsSearch[fSearchValuesList^[0].FieldID].FieldName,
                  fPredicate,
                  fFieldsSearch[fSearchValuesList^[0].SortByID].FieldName,
                  IntToStr(fMaxRowsReturn)]);
    //  DebugLn('******* FinalQry es: %s; fPredicate es: %s; Param0 es: %s, Param1 es: %s',
    //           [fFinalQry, fPredicate, fParam0, fParam1]);
    // Creo que a esto no le estoy dando ninguna utilidad
    if fFinalQry <> fLastQry then
      begin
        fLastQry:= fFinalQry;
        fQryHasChanged:= True;
        fQryHasParams:= True;
     end;
  end;
  DebugLnExit();
end;

function TSearcher.SQLParser(aSQL: string): string;
var i: Integer;
    s: String;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  // Convierte toda la clausula a mayúsculas para facilitar el resto de comprobaciones
  aSQL:= AnsiUpperCase(aSQL);

  // Elimina, si existen, los caracteres de Retorno de Carro (#13#10)
  aSQL:= StringReplace(aSQL,LineEnding, ' ', [rfReplaceAll]);
  s:= aSQL;

  i:= Pos('FROM', aSQL);
  aSQL:= Copy(aSQL, 0, i + 4);
  Result:= Copy(s, Length(aSQL) + 1, Length(s) - Length(aSQL));
  DebugLnExit();
end;

procedure TSearcher.CheckQueryAdvanced;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fQryHasParams:= False;
  fStatementIsOK:= True;
  fSearchValuesList^[0].ValueFrom:= '';
  fSearchValuesList^[0].Field:= '';
  fSearchValuesList^[0].Criteria:= 'Avanzado';
  fFinalQry:= fSearchForm.memAdvanced.Lines.Text;
  fPredefQuery.Query:='';
  DebugLnExit();
end;

procedure TSearcher.CheckQueryPredef;
var
  ExistSecondParam: boolean;
  fParams: TfrmParams;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fStatementIsOK:= True;
  if fQryHasParams then
  begin
    fParams:= TfrmParams.Create(Application.MainForm);
    fParam1:= '';
    with fParams do
      begin
        ExistSecondParam:= length(fPredefQuery.Params) > 1;
        pnlQuery.Caption:= fPredefQuery.Caption;
        pnlParam1.Visible:= ExistSecondParam;
        ShowModal;
        if ModalResult = mrOK then
        begin
          fPredefQuery.Params[0].Value:= edtParam0.Text;
          fParam0:= fPredefQuery.Params[0].Value;
          if ExistSecondParam then
          begin
            fPredefQuery.Params[1].Value:= edtParam1.Text;
            fParam1:= fPredefQuery.Params[1].Value;
          end;
        end;
        FreeAndNil(fParams);
        if (fPredefQuery.FieldType = ftsString) and
        ((fPredefQuery.Criteria = psStartingWith) or (fPredefQuery.Criteria = psContains))
//           ((fPredefQuery.CriteriaStr = 'Empieza por') or (fPredefQuery.CriteriaStr = 'Contiene'))
        then
           fParam0:= fPredefQuery.Params[0].Value + '%';
      end;
  end;
  fFinalQry:= fPredefQuery.Query;
  DebugLnExit();
end;

procedure TSearcher.CheckQuerySearcher(var QueryOK: Boolean);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
 // FillSearchValuesList;   // Ver nota en el método
  fSearchValuesList^[0]:= fSearchForm.SearchValues;
  // No se ha asignado ningún valor a ValueFrom.
  // Se le pregunta al usuario si quiere abandonar el buscador o crear una nueva consulta
  if fSearchValuesList^[0].ValueFrom = '' then
  begin
    QueryOK:= (QuestionDlg('Aviso', rsInfQueryEmpty, mtWarning,
                           [mrYes, 'Si', mrNo, 'No'], 0) = mrNo);
    DebugLnExit();
    exit;
  end;
  GenerateSQL;
  fPredefQuery.Query:='';
  DebugLnExit();
end;

procedure TSearcher.GetStatusInfo;
var strCriteria: string;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fSearchResult^.NumberOfRecords:= Format('Registros:  %d', [fNumberOfRecords]);
  fSearchResult^.QryHasParams:= fQryHasParams;

  if fPredefQuery.FieldType = ftsString then
    strCriteria:= fItemsString[fPredefQuery.Criteria]
  else
    strCriteria:= fItemsNumeric[fPredefQuery.Criteria];
  case fSearcherMode of
    smPredefined: begin
                    fSearchResult^.FieldName:= Format('Campo: %s', [fPredefQuery.FieldName]);
                    if fQryHasParams then
                      fSearchResult^.Criteria:= Format('Criterio (Predef): %s %s',
                                         [strCriteria, fPredefQuery.Params[0].Value])
                    else
                      fSearchResult^.Criteria:= Format('Criterio (Predef): %s', [strCriteria]);
                  end;
    smAdvanced  : begin
                    fSearchResult^.FieldName:= 'Campo: N/A';
                    fSearchResult^.Criteria:= 'Criterio: Buscador avanzado';
                  end;
    smSearcher  : begin
                    fSearchResult^.FieldName:= Format('Campo: %s', [fSearchValuesList^[0].Field]);
                    if fSearchValuesList^[0].Criteria = 'Está entre' then
                      fSearchResult^.Criteria:= Format('Criterio: %s %s y %s',
                                                       [fSearchValuesList^[0].Criteria,
                                                        fSearchValuesList^[0].ValueFrom,
                                                        fSearchValuesList^[0].ValueTo])
                    else
                      fSearchResult^.Criteria:= Format('Criterio: %s %s',
                                   [fSearchValuesList^[0].Criteria, fSearchValuesList^[0].ValueFrom])
                  end;
    smParams    : begin
                    if fPredefQuery.Query = ''
                  then
                    fSearchResult^.Criteria:= Format('Criterio: %s %s',
                                     [fSearchValuesList^[0].Criteria, fSearchValuesList^[0].ValueFrom])
                  else
                    fSearchResult^.Criteria:= Format('Criterio (Predef): %s %s',
                                     [strCriteria, fSearchValuesList^[0].ValueFrom]);
                  end;
  end;
  DebugLnExit();
end;

function TSearcher.CheckRecordCount: integer;
{---------------------------------------------------------------------------------------------------
 Determina el número de registros que devolvería la consulta tal como se ha formulado. En función de
 ese número se devuelve un código que determina la acción a tomar
---------------------------------------------------------------------------------------------------}
var
  RecordsCountStatement: string;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if fSearcherMode <> smSearcher then
  Begin
    RecordsCountStatement:= SQLParser(fFinalQry);
    RecordsCountStatement:= format('Select count (*) FROM %s', [RecordsCountStatement]);
  end
  else
    RecordsCountStatement:= format('Select count (*) FROM %s Where %s %s',
                 [fTableName, fFieldsSearch.Data[fSearchValuesList^[0].FieldID].FieldName, fPredicate]);
  with fFqryRecordCount do
  begin
    Close;
    SQL.Text:= RecordsCountStatement;
    if fQryHasParams then
    begin
      params[0].AsString:= FParam0;
      if Params.Count > 1 then
        params[1].AsString:= FParam1;
    end;
    try
      Open;
      fNumberOfRecords:= Fields[0].AsInteger;
    except
      Result:= crcCreateNewQuery;
      fStatementIsOK:= False;
      ShowMessage('La consulta formulada es errónea');
      Exit;
    end;
  end;
//  fNumberOfRecords:= 1;
  if fNumberOfRecords = 0 then     // La consulta no devuelve registros.
  begin
    if QuestionDlg('Aviso', rsInfQueryEmpty, mtWarning, [mrYes, 'Si', mrNo, 'No'], 0) = mrYes then
      Result:= crcCreateNewQuery   // Formular otra
    else
      Result:= crcLeaveSearcher   // No formular otra y salir del buscador
    end
  else
    if (fNumberOfRecords > 0) and (fNumberOfRecords <= fMaxRowsReturn) then      // La consulta devuelve un número de registros permitido
      Result:= crcQueryOK    // Ejecutar la consulta y abandonar el buscador
    else
      if QuestionDlg('Aviso', Format (rsInfTooMuchRecords, [fNumberOfRecords]), mtWarning,
                     [100, 'Reformular', 'IsDefault', 101, 'Ver Consulta'], 0)  = 100 then
        Result:= crcCreateNewQuery      // Formular otra
      else
        Result:= crcQueryOK;     // Ejecutar la consulta y abandonar el buscador

  DebugLnExit();
end;

procedure TSearcher.SetFieldsForSearch(FieldList: TFieldInfoList);
{---------------------------------------------------------------------------------------------------
Genera la lista fFieldsSearch, con los campos seleccionables para búsquedas. En este momento los
criterios que sigo son:
- El tipo de datos puede ser de tipo cadena o numérico
- Los campos que representan FK se incluye si está activado el testigo en la ocnfiguración
---------------------------------------------------------------------------------------------------}
var
  i, j: Integer;
  addField: Boolean;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  j:= 0;
  for i := 0 to Pred(FieldList.Count) do
  begin
    addField:= False;
//    DebugLn('************ Campo: %s', [FieldList.Data[i].FieldName]);
    if (FieldList.Data[i].FieldType in
        [ftString, ftSmallint, ftInteger, ftWord, ftFloat, ftCurrency, ftBCD]) then
    begin
      if vcfShowIDFieldsInSearch then
        addField:= True
      else
        if RightStr(FieldList.Data[i].FieldName,3) <> '_ID' then
          addField:= True;
      if addField then
      begin
//        FieldList.Data[i].UseToSearch:= True;               // Marca el campo como válido para búsquedas
        fItemsSearch.Add(FieldList.Data[i].FieldName);      // Añade el record a la lista de items para cmbSearch
        fFieldsSearch.Add(j, FieldList.Data[i]);            // Añade el record a fFieldsSearch
      end;
      fItemsSort.Add(FieldList.Data[i].FieldName);          // Todos los campos se añaden a la lista de SortBy
      j:= j+1;
    end;
  end;
  fItemsString.CommaText := rsItemsForStringSearch;
  fItemsNumeric.CommaText := rsItemsForIntegerSearch;
  DebugLnExit()
end;

{---------------------------------------------------------------------------------------------------
 Metodos Get/Set
---------------------------------------------------------------------------------------------------}
procedure TSearcher.SetTableName(AValue: string);
begin
  if fTableName=AValue then Exit;
  fTableName:=AValue;
end;

procedure TSearcher.setStartQry(aValue: string);
begin
  if fStartQry=aValue then Exit;
  fStartQry:=aValue;
end;

procedure TSearcher.setSearchValuesList(aValue: PSearchValuesList);
begin
  if fSearchValuesList=aValue then Exit;
  fSearchValuesList:=aValue;
end;

procedure TSearcher.setSearcherMode(aValue: integer);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  if fSearcherMode=aValue then
  begin
    Exit;
    DebugLnExit();
  end;
  if (fSearcherMode=smAdvanced) and (aValue = smSearcher) then Exit;
  fSearcherMode:=aValue;
  DebugLnExit();
end;

procedure TSearcher.setSearchResult(aValue: PSearchResult);
begin
  if fSearchResult=aValue then Exit;
  fSearchResult:=aValue;
end;

procedure TSearcher.setNumberOfRecords(aValue: integer);
begin
  if fNumberOfRecords=aValue then Exit;
  fNumberOfRecords:=aValue;
end;

procedure TSearcher.setPredefQuery(aValue: TPredefQuery);
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  fPredefQuery:=aValue;
  fQryHasParams:= length(fPredefQuery.Params) > 0;
  DebugLnExit();
end;

end.

