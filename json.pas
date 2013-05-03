// JSON Parser by Thomas Erlang - TESoft.dk
// Version 0.1

unit json;

interface

uses Variants, Classes, SysUtils;

type
  TJSON = class;
  TJSONItem = class;
  TJSONEnumerator = class;
  TArrayOfTJSONField = array of TJSONItem;

  TJSONItem = class(TObject)
    private
      FValue: variant;
      FObject: TJSON;
      FIsList: boolean; 
      function readString(): string;
      procedure writeString(AValue: string);
      function readInteger(): integer;
      procedure writeInteger(AValue: integer);
      function readBoolean(): boolean;
      procedure writeBoolean(AValue: boolean);
      function readJSON(): TJSON;
      procedure writeJSON(AValue: TJSON);
      function readCurrency(): Currency;
      procedure writeCurrency(AValue: Currency);
      function readFloat(): Double;
      procedure writeFloat(AValue: Double);
      function GetFieldByIndex(AIndex: integer): TJSONItem;
      function GetFieldByName(AName: string): TJSONItem;
    public
      constructor Create;
      procedure Free;
      function GetEnumerator: TJSONEnumerator;
      function FieldByName(AName: string): TJSONItem;
      property FieldByName_[AName: string]: TJSONItem read GetFieldByName; default;
      property Field[AIndex: integer]: TJSONItem read GetFieldByIndex;
      property AsVariant: variant read FValue write FValue;
      property AsString: string read readString write writeString;
      property AsInteger: integer read readInteger write writeInteger;
      property AsBoolean: boolean read readBoolean write writeBoolean;
      property AsJSON: TJSON read readJSON write writeJSON;
      property AsCurrency: Currency read readCurrency write writeCurrency;
      property AsFloat: Double read readFloat write writeFloat;
  end;     

  TJSONRow = class(TObject)
    private
      FFieldNames: TStringList;
      FFields: TList;
      FLastField: integer;
      FValue: TJSONItem;
      function GetFieldByIndex(AIndex: integer): TJSONItem;
      function GetFieldByName(AName: string): TJSONItem;
      function GetLastField: TJSONItem;
    public
      constructor Create;
      procedure Free;
      function AddField(AField: TJSONItem): integer; overload;
      function AddField(AName: string): integer; overload;
      function AddField(AName: string; AField: TJSONItem): integer; overload;
      function FieldByName(AName: string): TJSONItem;
      property FieldByName_[AName: string]: TJSONItem read GetFieldByName; default;
      property Field[AIndex: integer]: TJSONItem read GetFieldByIndex;
      property FieldNames: TStringList read FFieldNames;
      property LastField: TJSONItem read GetLastField;
      property Value: TJSONItem read FValue write FValue;
    published     
    
  end;

  TJSONEnumerator = class(TObject)
    private
      FIndex: integer;
      FJSON: TJSON;
    public
      constructor Create(AJSON: TJSON);
      function GetCurrent: TJSONItem;
      function MoveNext: boolean;
      property Current: TJSONItem read GetCurrent;
  end;

  TJSON = class(TObject)
    private
      FRows: TList;
      FIndex: integer;
      FEof, FBof: boolean;
      FRowCount: integer;
      FIsList: boolean;

      procedure UpdateIndex(AValue: integer);
      function GetFieldByIndex(AIndex: integer): TJSONItem;
      function GetFieldByName(AName: string): TJSONItem;
      function readRows(AIndex: integer): TJSONRow;
      function GetCurrentRow: TJSONRow;
    protected
    public
      Parent: TJSON;

      constructor Create; overload;
      procedure Free;

      function GetEnumerator: TJSONEnumerator;

      property RowIndex: integer read FIndex write UpdateIndex;
      property Eof: boolean read FEof;
      property Bof: boolean read FBof;

      procedure Next;
      procedure Prev;
      procedure First;
      procedure Last;

      procedure New;
      procedure Remove;

      function AddField(AName: string): integer;
      function FieldByName(AName: string): TJSONItem; overload;
      property FieldByName_[AName: string]: TJSONItem read GetFieldByName; default;
      property Field[AIndex: integer]: TJSONItem read GetFieldByIndex;

      property Row[AIndex: integer]: TJSONRow read readRows;
      property Rows: TList read FRows;
      property RowCount: integer read FRowCount;
      property CurrentRow: TJSONRow read GetCurrentRow;
      property IsList: boolean read FIsList;

    published
      constructor Create(Parent: TJSON); overload;
      class function Parse(AJSON: string): TJSON;

  end;

implementation

{ TJSONField }

constructor TJSONItem.Create;
begin
  inherited;
  FIsList := false;
end;

function TJSONItem.FieldByName(AName: string): TJSONItem;
begin
  result := GetFieldByName(AName);
end;

procedure TJSONItem.Free;
begin
  inherited;
  if assigned(FObject) then
    FObject.Free;
end;

function TJSONItem.GetEnumerator: TJSONEnumerator;
begin
  result :=  TJSONEnumerator.Create(AsJSON);
end;

function TJSONItem.GetFieldByIndex(AIndex: integer): TJSONItem;
begin
  result := AsJSON.Field[AIndex];
end;

function TJSONItem.GetFieldByName(AName: string): TJSONItem;
begin
  result := AsJSON.FieldByName(AName);
end;

function TJSONItem.readBoolean: boolean;
begin
  result := VarAsType(FValue, varBoolean);
end;

function TJSONItem.readCurrency: Currency;
begin
  result := VarAsType(FValue, varCurrency);
end;

function TJSONItem.readFloat: Double;
begin
  result := VarAsType(FValue, varDouble);
end;

procedure TJSONItem.writeBoolean(AValue: boolean);
begin
  FValue := AValue;
end;

procedure TJSONItem.writeCurrency(AValue: Currency);
begin
  FValue := AValue;
end;

procedure TJSONItem.writeFloat(AValue: Double);
begin
  FValue := AValue;
end;

function TJSONItem.readInteger: integer;
begin
  result := VarAsType(FValue, varInteger);
end;

function TJSONItem.readJSON: TJSON;
begin
  result := FObject;
end;

procedure TJSONItem.writeInteger(AValue: integer);
begin
  FValue := AValue;
end;

procedure TJSONItem.writeJSON(AValue: TJSON);
begin
  FObject := AValue;
end;

function TJSONItem.readString: string;
begin
  result := VarAsType(FValue, varString);
end;

procedure TJSONItem.writeString(AValue: string);
begin
  FValue := AValue;
end;

{ TJSON }

function TJSON.AddField(AName: string): integer;
begin
  with TJSONRow(FRows.Items[FIndex]) do
  begin
    result := AddField(AName, TJSONItem.Create);
  end;
end;

constructor TJSON.Create;
begin
  inherited;
  FRows := TList.Create;   
  RowIndex := -1;     
  FIsList := false;
end;

constructor TJSON.Create(Parent: TJSON);
begin
  inherited Create;
  self.Create;
  self.Parent := Parent;
end;

function TJSON.FieldByName(AName: string): TJSONItem;
begin
  result := GetFieldByName(AName);
end;

procedure TJSON.First;
begin
  RowIndex := 0;
end;

procedure TJSON.Free;
var
  i: integer;
begin
  inherited;
  for i := 0 to FRows.Count - 1 do
    TJSONRow(FRows.Items[i]).Free;
  FRows.Free;
end;

function TJSON.GetCurrentRow: TJSONRow;
begin
  result := self.Row[self.RowIndex];
end;

function TJSON.GetEnumerator: TJSONEnumerator;
begin
  result := TJSONEnumerator.Create(self);
end;

function TJSON.GetFieldByIndex(AIndex: integer): TJSONItem;
begin
  with TJSONRow(FRows.Items[FIndex]) do
  begin
    result := Field[AIndex];
  end;
end;

function TJSON.GetFieldByName(AName: string): TJSONItem;
begin
  result := CurrentRow.FieldByName(AName);
end;

procedure TJSON.Last;
begin
  RowIndex := FRows.Count - 1;
end;

procedure TJSON.New;
begin
  inc(FRowCount);
  RowIndex := FRows.Add(TJSONRow.Create);
end;

procedure TJSON.Next;
begin
  RowIndex := FIndex + 1;
end;

class function TJSON.Parse(AJSON: string): TJSON;
var
  a, prev_a: char;
  i, tag: integer;
  field, in_string: boolean;
  s: string;
  obj: TJSON;
function removeQuotation(s: string): string;
var
  _start, _end: string;
  len: integer;
begin
  result := '';
  len := length(s);
  if len < 1 then
    exit;
  _start := s[1];
  _end := s[len];
  result := s;
  if (_start = '"') and (_end = '"') then
  begin
    result := copy(s, 2, len-2);
    result := StringReplace(
      result,
      '\"',
      '"',
      [rfReplaceAll]
    );
    result := StringReplace(
      result,
      '\\',
      '\',
      [rfReplaceAll]
    );
  end;
end;
function get(): string;
begin
  result := removeQuotation(trim(copy(AJSON, tag, i-tag)));
end;
begin
  i := 0;
  tag := 0;
  field := false;
  prev_a := ' ';
  in_string := false;
  obj := nil;
  s := '';
  for a in AJSON do
  begin
    inc(i);
    if tag = 0 then
      tag := i;
    if (a = '"') and (prev_a <> '\') then
      in_string := not in_string;
    prev_a := a;
    if in_string or (a in [#9, #10, #13, ' ']) then
      continue;
    case a of
      '{', '[':
      begin
        if obj = nil then
          obj := TJSON.Create(nil)
        else
        begin
          if not obj.IsList then
          begin
            obj.CurrentRow.LastField.AsJSON := TJSON.Create(obj);
            if a = '[' then
              obj.CurrentRow.LastField.AsString := '{JSON_LIST}'
            else
              obj.CurrentRow.LastField.AsString := '{JSON_OBJECT}';
            obj := obj.CurrentRow.LastField.AsJSON;
          end
          else
          begin
            obj.CurrentRow.FValue := TJSONItem.Create;
            obj.CurrentRow.FValue.AsJSON := TJSON.Create(obj);
            obj.CurrentRow.FValue.AsString := '{JSON_OBJECT}';
            obj := obj.CurrentRow.FValue.AsJSON;
          end;
        end;
        if a = '[' then
          obj.FIsList := true;
        obj.New;
        tag := 0;
      end;
      ':':
      begin
        obj.AddField(get());
        tag := 0;
      end;
      ',', '}', ']':
      begin
        s := get();
        if s <> '' then
        begin
          if not obj.IsList then
            obj.CurrentRow.LastField.AsString := s
          else
          begin
            obj.CurrentRow.Value := TJSONItem.create;
            obj.CurrentRow.Value.AsString := s
          end;
        end;
        if (a = '}') or (a = ']') then
        begin
          if (obj.Parent <> nil) then
          begin
            obj.First;
            obj := obj.Parent;
          end;
        end
        else if (a = ',') and (obj.FIsList) then
        begin
          obj.New;
        end;
        tag := 0;
      end;
    end;
  end;
  obj.First;
  result := obj;
end;

procedure TJSON.Prev;
begin
  RowIndex := FIndex - 1;
end;

function TJSON.readRows(AIndex: integer): TJSONRow;
begin
  result := TJSONRow(FRows[AIndex]);
end;

procedure TJSON.Remove;
begin
  FRows.Delete(RowIndex);
end;

procedure TJSON.UpdateIndex(AValue: integer);
begin
  FIndex := AValue;  
  if FIndex >= FRows.Count then
    FEof := True
  else
    FEof := False;

  if FIndex < 0 then
    FBof := True
  else
    FBof := false;
end;

{ TJSONRows }

function TJSONRow.AddField(AName: string; AField: TJSONItem): integer;
begin
  FFieldNames.Append(AName);
  result := FFields.Add(AField);
  FLastField := result;
end;

function TJSONRow.AddField(AField: TJSONItem): integer;
begin
  result := FFields.Add(AField);
  FLastField := result;
end;

function TJSONRow.AddField(AName: string): integer;
begin
  FFieldNames.Append(AName);
end;

constructor TJSONRow.Create;
begin
  FFields := TList.Create;
  FFieldNames := TStringList.Create;
  FLastField := -1;
end;

function TJSONRow.FieldByName(AName: string): TJSONItem;
begin
  result := GetFieldByName(AName);
end;

procedure TJSONRow.Free;
var
  i: integer;
begin
  inherited; 
  FFieldNames.Free;
  for i := 0 to FFields.Count - 1 do
    TJSONItem(FFields[i]).Free;
  if assigned(FValue) then
    FValue.Free;
  FFields.Free;
end;

function TJSONRow.GetFieldByIndex(AIndex: integer): TJSONItem;
begin
  if (AIndex < FFields.Count) and (AIndex <> -1) then
    result := FFields.Items[AIndex]
  else
    raise Exception.Create('Unknown Field');
end;

function TJSONRow.GetFieldByName(AName: string): TJSONItem;
var
  i: integer;
begin
  i := FFieldNames.IndexOf(AName);
  if i <> -1 then
    result := FFields[i]
  else
    raise Exception.Create(format('Unknown field: %s', [AName]));
end;

function TJSONRow.GetLastField: TJSONItem;
begin
  if self.FLastField > -1 then
    result := self.FFields[self.FLastField];
end;

{ TJSONEnumerate }

constructor TJSONEnumerator.Create(AJSON: TJSON);
begin
  Inherited Create;
  FIndex := -1;
  FJSON := AJSON;
end;

function TJSONEnumerator.GetCurrent: TJSONItem;
begin
  result := FJSON.Row[FIndex].FValue;
end;

function TJSONEnumerator.MoveNext: boolean;
begin
  result := FIndex < (FJSON.RowCount - 1);
  if result then
    inc(FIndex);
end;

initialization

end.
