unit params_f;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TfrmParams }

 TfrmParams = class(TForm)
    btnAceptar: TButton;
    btnCancel: TButton;
    edtParam0: TEdit;
    edtParam1: TEdit;
    lblParam0: TLabel;
    lblParam1: TLabel;
    pnlParam1: TPanel;
    pnlQuery: TPanel;
    procedure btnCancelClick(Sender: TObject);
    procedure lblParam1Click(Sender: TObject);
  private

  public

  end;

var
  frmParams: TfrmParams;

implementation

{$R *.lfm}

{ TfrmParams }

procedure TfrmParams.lblParam1Click(Sender: TObject);
begin

end;

procedure TfrmParams.btnCancelClick(Sender: TObject);
begin
  edtParam0.Text:= '';
  edtParam1.Text:= '';
end;

end.

