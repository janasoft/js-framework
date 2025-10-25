unit entity_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, entity_cl, fw_typedef, entity_serializers;

type
  // Base test case that sets up a TEntity for each test
  TEntityTestCase = class(TTestCase)
  protected
    FEntity: TEntity;
    procedure SetUp; override;
    procedure TearDown; override;
  end;

  // Test classes for different aspects
  TEntityMetadataTests = class(TEntityTestCase)
  published
    procedure TestInitialVersion;
    procedure TestCreatedByMetadata;
    procedure TestModifiedByMetadata;
  end;

  TEntityLoadingTests = class(TEntityTestCase)
  published
    procedure TestStateUnchangedDuringLoad;
  end;

  TEntitySerializationTests = class(TEntityTestCase)
  published
    procedure TestIDSerialization;
    procedure TestCaptionSerialization;
    procedure TestVersionSerialization;
    procedure TestCreatedBySerialization;
    procedure TestModifiedBySerialization;
    procedure TestStateSerialization;
  end;

implementation

{ TEntityTestCase }

procedure TEntityTestCase.SetUp;
begin
  inherited SetUp;
  FEntity := TEntity.Create;
  FEntity.UpdateMetadata('TestUser');
end;

procedure TEntityTestCase.TearDown;
begin
  FreeAndNil(FEntity);
  inherited TearDown;
end;

{ TEntityMetadataTests }

procedure TEntityMetadataTests.TestInitialVersion;
begin
  AssertEquals('Version inicial debe ser 1', 1, FEntity.Metadata.Version);
end;

procedure TEntityMetadataTests.TestCreatedByMetadata;
begin
  AssertEquals('CreatedBy debe estar establecido', 'TestUser', FEntity.Metadata.CreatedBy);
end;

procedure TEntityMetadataTests.TestModifiedByMetadata;
begin
  FEntity.UpdateMetadata('ModifiedUser', 5);
  AssertEquals('ModifiedBy debe estar establecido', 'ModifiedUser', FEntity.Metadata.ModifiedBy);
end;

{ TEntityLoadingTests }

procedure TEntityLoadingTests.TestStateUnchangedDuringLoad;
var
  initialState: TEntityState;
begin
  initialState := FEntity.State;
  FEntity.BeginLoad;
  FEntity.ID := 123;
  FEntity.Caption := 'Prueba';
  FEntity.EndLoad;
  AssertEquals('Estado no debe cambiar durante carga', Ord(initialState), Ord(FEntity.State));
end;

{ TEntitySerializationTests }

procedure TEntitySerializationTests.TestIDSerialization;
var
  e2: TEntity;
  s: string;
begin
  FEntity.BeginLoad;
  FEntity.ID := 123;
  FEntity.EndLoad;
  s := FEntity.ToJSONString;
  e2 := TEntity.Create;
  try
    e2.FromJSONString(s);
    AssertEquals('ID debe coincidir', FEntity.ID, e2.ID);
  finally
    e2.Free;
  end;
end;

procedure TEntitySerializationTests.TestCaptionSerialization;
var
  e2: TEntity;
  s: string;
begin
  FEntity.BeginLoad;
  FEntity.Caption := 'Prueba';
  FEntity.EndLoad;
  s := FEntity.ToJSONString;
  e2 := TEntity.Create;
  try
    e2.FromJSONString(s);
    AssertEquals('Caption debe coincidir', FEntity.Caption, e2.Caption);
  finally
    e2.Free;
  end;
end;

procedure TEntitySerializationTests.TestVersionSerialization;
var
  e2: TEntity;
  s: string;
begin
  FEntity.UpdateMetadata('ModifiedUser', 5);
  s := FEntity.ToJSONString;
  e2 := TEntity.Create;
  try
    e2.FromJSONString(s);
    AssertEquals('Version debe coincidir', FEntity.Metadata.Version, e2.Metadata.Version);
  finally
    e2.Free;
  end;
end;

procedure TEntitySerializationTests.TestCreatedBySerialization;
var
  e2: TEntity;
  s: string;
begin
  s := FEntity.ToJSONString;
  e2 := TEntity.Create;
  try
    e2.FromJSONString(s);
    AssertEquals('CreatedBy debe coincidir', FEntity.Metadata.CreatedBy, e2.Metadata.CreatedBy);
  finally
    e2.Free;
  end;
end;

procedure TEntitySerializationTests.TestModifiedBySerialization;
var
  e2: TEntity;
  s: string;
begin
  FEntity.UpdateMetadata('ModifiedUser', 5);
  s := FEntity.ToJSONString;
  e2 := TEntity.Create;
  try
    e2.FromJSONString(s);
    AssertEquals('ModifiedBy debe coincidir', FEntity.Metadata.ModifiedBy, e2.Metadata.ModifiedBy);
  finally
    e2.Free;
  end;
end;

procedure TEntitySerializationTests.TestStateSerialization;
var
  e2: TEntity;
  s: string;
begin
  s := FEntity.ToJSONString;
  e2 := TEntity.Create;
  try
    e2.FromJSONString(s);
    AssertEquals('Estado debe coincidir', Ord(FEntity.State), Ord(e2.State));
  finally
    e2.Free;
  end;
end;


initialization
  RegisterTest(TEntityMetadataTests);
  RegisterTest(TEntityLoadingTests);
  RegisterTest(TEntitySerializationTests);

end.

