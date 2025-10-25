unit baseform_f;

{$mode ObjFPC}{$H+}
{$IFOPT D+} {$DEFINE DEBUG} {$ENDIF}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, windows,
  {$IFDEF debug} LazLoggerBase {$ELSE}  LazLoggerDummy,{$ENDIF};


type

  { TBaseForm }

  TBaseForm = class(TForm)
    procedure FormClose({%H-}Sender: TObject; var CloseAction: TCloseAction);
  private
  public
    AppName: String;
    constructor CreateForm(TheOwner: TComponent);
    {---- Métodos de clase ------------------------------------------------------------------------}
    class function FindWind: TBaseForm;
    // Crea una ventana
    class function CreateWind: TBaseForm;
    // Si ya existe la ventana, la muestra. Si no existe la crea
    class function ShowWind: TBaseForm;
    // Muestra una ventana en forma modal
    class function ShowWindModal({%H-}AOwner: TComponent = nil): TModalResult;
  end;

var
  frmBase: TBaseForm;

implementation

uses fw_Config, basebrowser_f;

{$R *.lfm}

{---------------------------------------------------------------------------------------------------
 Métodos internos
 ---------------------------------------------------------------------------------------------------}

constructor TBaseForm.CreateForm(TheOwner: TComponent);
{---------------------------------------------------------------------------------------------------
 Este método sobreescribe el método original del mismo nombre ubicado en Forms y sólo se utiliza en
 esta clase.
 El CreateForm que aparece en el fichero .lpr utilizado para los formularios de creación automática
 se refiere al método original
 ---------------------------------------------------------------------------------------------------}
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  inherited Create(TheOwner);
  Constraints.MinWidth:= Width;
  if Self is TBaseBrowserform then
    Height:= 77 + (10*19);
  Constraints.MinHeight:= Height;
  DebugLnExit();
end;

procedure TBaseForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
{---------------------------------------------------------------------------------------------------
 Por defecto CloseAction es caHide en todas las ventanas salvo en la MainForm que es caFree. Parece
 que no hay otra posibilidad de modificar este parámetro para que sea caFree por defecto por lo que
 es necesario asignarlo expresamente para que se cierre la ventana
---------------------------------------------------------------------------------------------------}
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  CloseAction := caFree;
  DebugLnExit();
end;

{---------------------------------------------------------------------------------------------------
 Funciones de clase
---------------------------------------------------------------------------------------------------}

class function TBaseForm.ShowWind: TBaseForm;
{---------------------------------------------------------------------------------------------------
 Si existe la ventana la trae al primer plano. Si no existe, se crea y se muestra.
---------------------------------------------------------------------------------------------------}
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  Result := FindWind;
  if Assigned(Result) then
  begin
    if Result.WindowState = wsMinimized then
      ShowWindow(Result.Handle, SW_RESTORE);     // Esto es válido sólo para Windows
    Result.BringToFront;
  end
  else
  begin
    Result := CreateForm(Application.MainForm);
    Result.Show;
  end;
  DebugLnExit();
end;

class function TBaseForm.ShowWindModal(AOwner: TComponent): TModalResult;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  with FindWind do
  try
    Result := ShowModal;
  finally
    Free;
  end;
  DebugLnExit();
end;

class function TBaseForm.FindWind: TBaseForm;
var
  i: Integer;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  for i := Screen.FormCount - 1 downto 0 do
  begin
    TForm(Result) := Screen.Forms[i];
    if Result.ClassType = Self then
    begin
      DebugLnExit();
      Exit;
    end;
  end;
  Result := nil;
  DebugLnExit();
end;

class function TBaseForm.CreateWind(): TBaseForm;
begin
  DebugLnEnter('%s - %s', [ClassName, {$I %CURRENTROUTINE%}]);
  Result := CreateForm(Application.MainForm);          // Se crea la ventana
  DebugLnExit();
end;

end.

