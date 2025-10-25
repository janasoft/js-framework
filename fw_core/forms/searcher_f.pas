unit Searcher_f;

{$mode ObjFPC}{$H+}
{$IFOPT D+} {$DEFINE DEBUG} {$ENDIF}

interface

uses
  Classes, SysUtils, SQLDB, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  {$IFDEF debug} LazLoggerBase, {$ELSE}  LazLoggerDummy,{$ENDIF}
  fw_typedef;


type
  TItemSearchChange = procedure(const index: Integer) of Object;
  TCheckToClose = procedure(var CheckQuery: Boolean) of Object;
  TAdvancedMode = procedure(const mode: Boolean) of Object;

  { TfrmSearcher }

  TfrmSearcher = class(TForm)
    btnClose: TButton;
    btnSearch: TButton;
    chbAdvanced: TCheckBox;
    cmbCriteria: TComboBox;
    cmbSearchField: TComboBox;
    cmbSortBy: TComboBox;
    edtSearchFrom: TEdit;
    edtSearchTo: TEdit;
    lblCampo: TLabel;
    lblDato: TLabel;
    lblDatoExtra: TLabel;
    lblOrdenar: TLabel;
    memAdvanced: TMemo;
    pnlInfo: TPanel;
    pnlAdvanced: TPanel;
    pnlButtons: TPanel;
    pnlSearch: TPanel;
    pnlTitulo: TPanel;
    procedure btnSearchClick(Sender: TObject);                                                      
    procedure chbAdvancedClick(Sender: TObject);                                                    
    procedure cmbCriteriaChange(Sender: TObject);                                                   
    procedure cmbSearchFieldSelect(Sender: TObject);                                                
    procedure edtSearchFromKeyPress(Sender: TObject; var Key: char);                                
    procedure FormCreate(Sender: TObject);                                                          
  protected
    fSearchValuesList: TSearchValuesList;
  private
    fFieldType: integer;
    fItemsSearch: TStringList;
    fItemsSort: TStringList;
    fOnCheckToClose: TCheckToClose;
    fOnItemSearchChange: TItemSearchChange;
    fOnAdvancedMode: TAdvancedMode;
    fShowSearchTo: byte;
    function getSearchValues: TSearchValues;                                                        
    procedure setFieldType(aValue: integer);                                                        
    procedure setItemsSearch(aValue: TStringList);                                                  
    procedure setItemsSort(aValue: TStringList);                                                    
    procedure setOnAdvancedMode(aValue: TAdvancedMode);                                             
    procedure setOnCheckToClose(aValue: TCheckToClose);                                             
    procedure setShowSearchTo(aValue: byte);                                                        
  public
    property SearchValues: TSearchValues read getSearchValues;
    property OnItemSearchChange: TItemSearchChange read fOnItemSearchChange write fOnItemSearchChange;
    property OnCheckToClose: TCheckToClose read fOnCheckToClose write setOnCheckToClose;
    property OnAdvancedMode: TAdvancedMode read fOnAdvancedMode write setOnAdvancedMode;
    property ItemsSearch: TStringList read fItemsSearch write setItemsSearch;
    property ItemsSort: TStringList read fItemsSort write setItemsSort;
    property FieldType: integer read fFieldType write setFieldType;
    property ShowSearchTo: byte read fShowSearchTo write setShowSearchTo ;
  end;

var
  frmSearcher: TfrmSearcher;

implementation

{$R *.lfm}

{ TfrmSearcher }

procedure TfrmSearcher.FormCreate(Sender: TObject);
begin
  chbAdvancedClick(self);
end;

{--- Eventos de los controles ---------------------------------------------------------------------}
procedure TfrmSearcher.btnSearchClick(Sender: TObject);
var
   CheckQuery: Boolean;
begin
  if assigned (fOnCheckToClose) then
    OnCheckToClose(CheckQuery);
  If not CheckQuery then ModalResult:= mrNone;
end;

procedure TfrmSearcher.chbAdvancedClick(Sender: TObject);
begin
  if chbAdvanced.Checked then
    Height:= 280
  else
    Height:= 150;
  pnlAdvanced.Visible:= chbAdvanced.Checked;
  pnlSearch.Enabled:= not chbAdvanced.Checked;
  if assigned (fOnAdvancedMode) then
    OnAdvancedMode(chbAdvanced.Checked);
end;

procedure TfrmSearcher.cmbCriteriaChange(Sender: TObject);
begin
  if cmbCriteria.ItemIndex= fShowSearchTo then
  begin
    edtSearchFrom.Width:= 118;
    edtSearchTo.Enabled:= True;
  end else
  begin
    edtSearchFrom.Width:= 251;
    edtSearchTo.Enabled:= False ;
   end;
end;

procedure TfrmSearcher.cmbSearchFieldSelect(Sender: TObject);
{---------------------------------------------------------------------------------------------------
 Coloca en el combo de predicados los datos que corresponden al tipo del campo seleccionado
---------------------------------------------------------------------------------------------------}
begin
  edtSearchFrom.Text:= '';
  edtSearchTo.Text:='';
  if assigned (fOnItemSearchChange) then
     fOnItemSearchChange(cmbSearchField.ItemIndex);
end;

procedure TfrmSearcher.edtSearchFromKeyPress(Sender: TObject; var Key: char);
{---------------------------------------------------------------------------------------------------
 Está asignado también a edtSearchTo en el IO
---------------------------------------------------------------------------------------------------}
begin
  if fFieldType= ftsNumeric then
    If Not (Key In ['0'..'9', #8, #9, #44])then
    begin
      MessageDlg('Sólo se admiten valores numéricos y la coma (,) para decimales', mtWarning, [mbOK],0);
      Key:= #0;
    end;
end;

{--- Metodos Get/Set complejos --------------------------------------------------------------------}
function TfrmSearcher.getSearchValues: TSearchValues;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  with result do begin
    FieldID:= cmbSearchField.ItemIndex;
    Field:=cmbSearchField.Items[FieldID];
    CriteriaID:= cmbCriteria.ItemIndex;
    Criteria:= cmbCriteria.Items[CriteriaID];
    SortByID:= cmbSortBy.ItemIndex;
    SortBy:= cmbSortBy.Items[SortByID];
    ValueFrom:= edtSearchFrom.Text;
    ValueTo:= edtSearchTo.Text;
  end;
  DebugLnExit();
end;

{--- Métodos get/Set simples ----------------------------------------------------------------------}
procedure TfrmSearcher.setFieldType(aValue: integer);
begin
  if fFieldType=aValue then Exit;
  fFieldType:=aValue;
end;

procedure TfrmSearcher.setItemsSearch(aValue: TStringList);
begin
  cmbSearchField.Items:= aValue;
  cmbSearchField.ItemIndex:= 0;
end;

procedure TfrmSearcher.setItemsSort(aValue: TStringList);
begin
  cmbSortBy.Items:= aValue;
  cmbSortBy.ItemIndex:= 0;
end;

procedure TfrmSearcher.setOnAdvancedMode(aValue: TAdvancedMode);
begin
  if fOnAdvancedMode=aValue then Exit;
  fOnAdvancedMode:=aValue;
  chbAdvanced.Visible:= True;
end;

procedure TfrmSearcher.setOnCheckToClose(aValue: TCheckToClose);
begin
  if fOnCheckToClose=aValue then Exit;
  fOnCheckToClose:=aValue;
end;

procedure TfrmSearcher.setShowSearchTo(aValue: byte);
begin
  if fShowSearchTo=aValue then Exit;
  fShowSearchTo:=aValue;
end;

end.




