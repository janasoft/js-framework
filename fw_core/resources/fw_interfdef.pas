unit fw_interfdef;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, entity_cl;

type

  {$interfaces corba}
  IBaseDS = interface['{E92B8F9F-CA63-434A-9EE0-8C7B2DF786B3}']
    function  GetEntities: TEntityList;
    procedure SetLastID(AValue: integer);
    procedure SetCurrentID(AValue: integer);

    property Entities   : TEntityList read GetEntities;
    property CurrentID  : integer write SetCurrentID;
    property LastID     : integer write SetLastID;
  end;
  {$interfaces com}

implementation

end.

