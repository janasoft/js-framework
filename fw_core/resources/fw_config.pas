unit fw_config;

{$mode ObjFPC}{$H+}

interface

uses
  Factory;

var
  // Variables específicas del FW
  vcfFactory: TFactory;
  vcfSearcherOnStartManager: Boolean;
  vcfMaxRowsReturned: byte;
  vcfShowIDFieldsInSearch: Boolean;
  vcfAllowAdvancedSearch: Boolean;
  vcfAppName : String;

implementation

end.

