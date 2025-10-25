program test_entity_serialization;

{$mode ObjFPC}{$H+}

uses
  SysUtils, fw_typedef;

var
  e1, e2: TEntity;
  s: string;
begin
  e1 := TEntity.Create;
  try
    e1.ID := 123;
    e1.Caption := 'Prueba';
    e1.Metadata.CreatedAt := Now - 1;
    e1.Metadata.ModifiedAt := Now;
    e1.Metadata.Version := 5;

    s := e1.ToJSONString;
    Writeln('JSON: ', s);

    e2 := TEntity.Create;
    try
      e2.FromJSONString(s);
      if (e2.ID = e1.ID) and (e2.Caption = e1.Caption) and (e2.Metadata.Version = e1.Metadata.Version) then
        Writeln('OK: serializacion funciona')
      else
        Writeln('FAIL: valores no coinciden');
    finally
      e2.Free;
    end;
  finally
    e1.Free;
  end;
end.
