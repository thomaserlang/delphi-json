{
The MIT License (MIT)

Copyright (c) 2014 Thomas Erlang

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
}

unit json;

interface

uses System.SysUtils, System.Classes, System.Variants, generics.collections, dialogs;

type
  TJSON = class;

  TJSONItems = class(TDictionary<string,TJSON>)
    public
      destructor Destroy; override;
  end;

  TJSONListItems = class(TList<TJSON>)
    public
      destructor Destroy; override;
  end;

  TJSON = class(TObject)
    private
      FParent: TJSON;
      FIsList: boolean;
      FValue: Variant;
      FItems: TJSONItems;
      FListItems: TJSONListItems;
      FLastField: string;
      function GetJSONByNameOrIndex(const AData: variant): TJSON;
      function GetString: string;
      function GetInteger: integer;
      function GetBoolean: boolean;
      function GetInt64: int64;
      function GetDateTime: TDateTime;
    public
      constructor Create(AParent: TJSON = nil);
      destructor Destroy; override;
      function GetEnumerator: TList<TJSON>.TEnumerator;
      class function Parse(const AJSON: string): TJSON;

      property Parent: TJSON read FParent;
      property IsList: boolean read FIsList;
      property Items: TJSONItems read FItems;
      property ListItems: TJSONListItems read FListItems;
      property Value: Variant read FValue;
      property AsString: string read GetString;
      property AsInteger: integer read GetInteger;
      property AsBoolean: boolean read GetBoolean;
      property AsInt64: int64 read GetInt64;
      property AsDateTime: TDateTime read GetDateTime;
      property JSONByNameOrIndex[const AData: variant]: TJSON read GetJSONByNameOrIndex; default;
      property _[const AData: variant]: TJSON read GetJSONByNameOrIndex;
  end;

  EJSONUnknownFieldOrIndex = class(Exception);
  EJSONParseError = class(Exception);

var
  DJSONFormatSettings: TFormatSettings;

implementation

uses
  XSBuiltIns;

{$M+}
{$TYPEINFO ON}

{ TJSON }

constructor TJSON.Create(AParent: TJSON);
begin
  FParent := AParent;
  FIsList := false;
end;

destructor TJSON.Destroy;
begin
  if assigned(FListItems) then
    FListItems.free;
  if assigned(FItems) then
    FItems.Free;
  inherited;
end;

function TJSON.GetBoolean: boolean;
begin
  result := VarAsType(FValue, varBoolean);
end;

function TJSON.GetDateTime: TDateTime;
// TODO: Make a better date/time parser
var
  d: string;
begin
  d := VarToStr(FValue);
  if length(d) = 10 then // date
    result := StrToDate(d, DJSONFormatSettings)
  else if length(d) = 8 then // time
    result := StrToTime(d, DJSONFormatSettings)
  else
    with TXSDateTime.Create() do
    try
      XSToNative(d);
      Result := AsDateTime;
    finally
      Free();
    end;
end;

function TJSON.GetEnumerator: TList<TJSON>.TEnumerator;
begin
  result := FListItems.GetEnumerator;
end;

function TJSON.GetInt64: int64;
begin
  result := VarAsType(FValue, varInt64);
end;

function TJSON.GetInteger: integer;
begin
  result := VarAsType(FValue, varInteger);
end;

function TJSON.GetJSONByNameOrIndex(const AData: variant): TJSON;
var
  typestring: string;
begin
  case VarType(AData) and VarTypeMask of
    varString, varUString, varWord, varLongWord:
      if not FItems.TryGetValue(AData, result) then
        raise EJSONUnknownFieldOrIndex.Create(format('Unknown field: %s', [AData]))
      else
        exit;
    varInteger, varInt64, varSmallint, varShortInt, varByte:
    begin
      if (FListItems.Count - 1) >= AData then
      begin
        result := FListItems.items[AData];
        exit;
      end
      else
        raise EJSONUnknownFieldOrIndex.Create(format('Unknown index: %d', [AData]));
    end;
  end;
  case VarType(AData) and VarTypeMask of
    varEmpty     : typeString := 'varEmpty';
    varNull      : typeString := 'varNull';
    varSmallInt  : typeString := 'varSmallInt';
    varInteger   : typeString := 'varInteger';
    varSingle    : typeString := 'varSingle';
    varDouble    : typeString := 'varDouble';
    varCurrency  : typeString := 'varCurrency';
    varDate      : typeString := 'varDate';
    varOleStr    : typeString := 'varOleStr';
    varDispatch  : typeString := 'varDispatch';
    varError     : typeString := 'varError';
    varBoolean   : typeString := 'varBoolean';
    varVariant   : typeString := 'varVariant';
    varUnknown   : typeString := 'varUnknown';
    varByte      : typeString := 'varByte';
    varWord      : typeString := 'varWord';
    varLongWord  : typeString := 'varLongWord';
    varInt64     : typeString := 'varInt64';
    varStrArg    : typeString := 'varStrArg';
    varString    : typeString := 'varString';
    varAny       : typeString := 'varAny';
    varTypeMask  : typeString := 'varTypeMask';
  end;
  raise EJSONUnknownFieldOrIndex.Create(format('Unknown field variant type: %s.', [varString]));
end;

function TJSON.GetString: string;
begin
  if VarIsType(FValue, varNull) then
    result := ''
  else
    result := VarToStr(FValue);
end;

class function TJSON.Parse(const AJSON: string): TJSON;
var
  a, prev_a: char;
  i, tag: integer;
  field, in_string: boolean;
  temp: string;
  obj, temp_obj: TJSON;
function unescape(const s: string): string;
var
  prev, prev_prev: char;
  ubuf, i, skip: integer;
procedure append;
begin
  result := result + s.chars[i];
end;
begin
  result := '';
  if s = 'null' then
    exit;
  skip := 0;
  for i := 0 to s.Length - 1 do
  begin
    if skip > 0 then
    begin
      dec(skip);
      Continue;
    end;
    try
      if (prev = '\') and (prev_prev <> '\') then
      begin
        case s.chars[i] of
          '\', '"': append;
          'u':
          begin
            if not TryStrToInt('$' + s.Substring(i+1, 4), ubuf) then
              raise EJSONParseError.Create(format('Invalid unicode \u%s', [s.Substring(i+1, 4)]));
            result := result + WideChar(ubuf);
            skip := 4;
            Continue;
          end;
        end;
      end
      else
        case s.chars[i] of
          '\', '"': continue;
        else
          append;
        end;
    finally
      if (prev = '\') and (prev_prev = '\') then
        prev_prev := #0
      else
        prev_prev := prev;
      prev := s.chars[i];
    end;
  end;
end;
function get_value(): string;
begin
  result := unescape(trim(AJSON.Substring(tag-1, i-tag)));
end;
begin
  i := 0;
  tag := 0;
  field := false;
  prev_a := ' ';
  in_string := false;
  obj := nil;
  for a in AJSON do
  begin
    inc(i);
    if tag = 0 then
      tag := i;
    if (a = '"') and (prev_a <> '\') then
      in_string := not in_string;
    prev_a := a;
    if in_string or (CharInSet(a, [#9, #10, #13, ' '])) then
      continue;
    case a of
      '{':
      begin
        if obj = nil then
          obj := TJSON.Create(nil);
        obj.FIsList := false;
        obj.FItems := TJSONItems.Create;
        obj.FValue := '{JSON_OBJECT}';
        tag := 0;
      end;
      '[':
      begin
        if obj = nil then
          obj := TJSON.Create(nil);
        obj.FIsList := true;
        obj.FListItems := TJSONListItems.Create;
        obj.FValue := '{JSON_LIST}';
        temp_obj := TJSON.Create(obj);
        obj.FListItems.add(temp_obj);
        obj := temp_obj;
        obj.FValue := null;
        tag := 0;
      end;
      ':':
      begin
        temp_obj := TJSON.Create(obj);
        obj.FItems.add(get_value, temp_obj);
        obj := temp_obj;
        obj.FValue := null;
        tag := 0;
      end;
      ',':
      begin
        temp := get_value();
        if temp <> '' then
          obj.FValue := temp;
        if (obj.Parent <> nil) then
          obj := obj.Parent;
        if obj.FIsList then
        begin
          temp_obj := TJSON.Create(obj);
          obj.FListItems.add(temp_obj);
          obj := temp_obj;
          obj.FValue := null;
        end;
        tag := 0;
      end;
      '}', ']':
      begin
        temp := get_value();
        if temp <> '' then
          obj.FValue := temp;
        if (obj.Parent <> nil) then
          obj := obj.Parent;
        if a = ']' then
        begin
          if assigned(obj.FListItems) then
            if obj.FListItems.Count = 1 then
            begin
              // When first seeing a list we dont know if it contains anything.
              // When at the end of list we check if the value has been set.
              // If it hasn't, we'll remove the unused object
              if (VarIsType(obj.FListItems[0].FValue, varNull)) and
                 (not assigned(obj.FListItems[0].FItems)) and
                 (not assigned(obj.FListItems[0].FListItems)) then
              begin
                obj.FListItems[0].Free;
                obj.FListItems.Delete(0);
              end;
            end;
        end;
        tag := 0;
      end;
    end;
  end;
  result := obj;
end;

{ TJSONItems }

destructor TJSONItems.Destroy;
var
  item: TJSON;
begin
  for item in self.Values do
    item.Free;
  inherited;
end;

{ TJSONListItem }

destructor TJSONListItems.Destroy;
var
  item: TJSON;
begin
  for item in self do
    item.Free;
  inherited;
end;

initialization

  DJSONFormatSettings := TFormatsettings.Create;
  with DJSONFormatSettings do
  begin
    DateSeparator := '-';
    TimeSeparator := ':';
    ShortDateFormat := 'yyyy-mm-dd';
    LongDateFormat := 'yyyy-mm-dd';
    ShortTimeFormat := 'hh:nn:ss';
    LongTimeFormat := 'hh:nn:ss';
  end;

end.
