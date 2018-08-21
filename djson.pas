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

unit djson;

interface

uses System.SysUtils, System.Classes, System.Variants, generics.collections;

type
  TdJSON = class;

  TdJSONItems = class(TDictionary<string,TdJSON>)
    public
      destructor Destroy; override;
  end;

  TdJSONListItems = class(TList<TdJSON>)
    public
      destructor Destroy; override;
  end;

  TdJSON = class(TObject)
    private
      FParent: TdJSON;
      FIsList: boolean;
      FValue: Variant;
      FItems: TdJSONItems;
      FListItems: TdJSONListItems;
      FLastField: string;
      function GetJSONByNameOrIndex(const AData: variant): TdJSON;
      function GetString: string;
      function GetInteger: integer;
      function GetBoolean: boolean;
      function GetInt64: int64;
      function GetDateTime: TDateTime;
    public
      constructor Create(AParent: TdJSON = nil);
      destructor Destroy; override;
      function GetEnumerator: TList<TdJSON>.TEnumerator;
      class function Parse(const AJSON: string): TdJSON;

      property Parent: TdJSON read FParent;
      property IsList: boolean read FIsList;
      property Items: TdJSONItems read FItems;
      property ListItems: TdJSONListItems read FListItems;
      property Value: Variant read FValue;
      property AsString: string read GetString;
      property AsInteger: integer read GetInteger;
      property AsBoolean: boolean read GetBoolean;
      property AsInt64: int64 read GetInt64;
      property AsDateTime: TDateTime read GetDateTime;
      property JSONByNameOrIndex[const AData: variant]: TdJSON read GetJSONByNameOrIndex; default;
      property _[const AData: variant]: TdJSON read GetJSONByNameOrIndex;
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

constructor TdJSON.Create(AParent: TdJSON);
begin
  FParent := AParent;
  FIsList := false;
end;

destructor TdJSON.Destroy;
begin
  if assigned(FListItems) then
    FListItems.free;
  if assigned(FItems) then
    FItems.Free;
  inherited;
end;

function TdJSON.GetBoolean: boolean;
begin
  result := VarAsType(FValue, varBoolean);
end;

function TdJSON.GetDateTime: TDateTime;
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

function TdJSON.GetEnumerator: TList<TdJSON>.TEnumerator;
begin
  result := FListItems.GetEnumerator;
end;

function TdJSON.GetInt64: int64;
begin
  result := VarAsType(FValue, varInt64);
end;

function TdJSON.GetInteger: integer;
begin
  result := VarAsType(FValue, varInteger);
end;

function TdJSON.GetJSONByNameOrIndex(const AData: variant): TdJSON;
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
  raise EJSONUnknownFieldOrIndex.Create(format('Unknown field variant type: %s.', [VarTypeAsText(AData)]));
end;

function TdJSON.GetString: string;
begin
  if VarIsType(FValue, varNull) then
    result := ''
  else
    result := VarToStr(FValue);
end;

class function TdJSON.Parse(const AJSON: string): TdJSON;
var
  a, prevA: char;
  index, tag: integer;
  field, inString, escaped: boolean;
  temp: variant;
  obj, tempObj: TdJSON;

  function getValue: variant;
  var
    prev, prevPrev: char;
    ubuf, i, skip: integer;
    s: string;
    resultS: string;
  begin
    s := trim(AJSON.Substring(tag-1, index-tag));
    result := unassigned;
    if s.ToLower = 'null' then
      exit(null);
    if s = '""' then
      exit('');
    resultS := '';
    skip := 0;
    for i := 0 to s.Length - 1 do
    begin
      if skip > 0 then
      begin
        dec(skip);
        Continue;
      end;
      try
        if (prev = '\') and (prevPrev <> '\') then
        begin
          case s.chars[i] of
            '\', '/', '"': resultS := resultS + s.chars[i];
            'u':
            begin
              if not TryStrToInt('$' + s.Substring(i+1, 4), ubuf) then
                raise EJSONParseError.Create(format('Invalid unicode \u%s', [s.Substring(i+1, 4)]));
              resultS := resultS + WideChar(ubuf);
              skip := 4;
              Continue;
            end;
            'b': resultS := resultS + #8;
            'n': resultS := resultS + #10;
            'r': resultS := resultS + #13;
            't': resultS := resultS + #9;
            'f': resultS := resultS + #12;
          end;
        end
        else
          case s.chars[i] of
            '\', '"': continue;
          else
            resultS := resultS + s.chars[i];
          end;
      finally
        if (prev = '\') and (prevPrev = '\') then
          prevPrev := #0
        else
          prevPrev := prev;
        prev := s.chars[i];
      end;
    end;
    if resultS <> '' then
      result := resultS;
  end;

begin
  index := 0;
  tag := 0;
  field := false;
  prevA := ' ';
  inString := false;
  escaped := false;
  obj := nil;
  for a in AJSON do
  begin
    inc(index);
    if tag = 0 then
      tag := index;
    escaped := (prevA = '\') and (not escaped);
    if (a = '"') and (not escaped) then
      inString := not inString;
    prevA := a;
    if inString or (CharInSet(a, [#9, #10, #13, ' '])) then
      continue;
    case a of
      '{':
      begin
        if obj = nil then
          obj := TdJSON.Create(nil);
        obj.FIsList := false;
        obj.FItems := TdJSONItems.Create;
        obj.FValue := Unassigned;
        tag := 0;
      end;
      '[':
      begin
        if obj = nil then
          obj := TdJSON.Create(nil);
        obj.FIsList := true;
        obj.FListItems := TdJSONListItems.Create;
        obj.FValue := Unassigned;
        tempObj := TdJSON.Create(obj);
        obj.FListItems.add(tempObj);
        obj := tempObj;
        obj.FValue := Unassigned;
        tag := 0;
      end;
      ':':
      begin
        tempObj := TdJSON.Create(obj);
        obj.FItems.add(getValue, tempObj);
        obj := tempObj;
        obj.FValue := null;
        tag := 0;
      end;
      ',':
      begin
        temp := getValue();
        if not VarIsEmpty(temp) then
          obj.FValue := temp;
        if (obj.Parent <> nil) then
          obj := obj.Parent;
        if obj.FIsList then
        begin
          tempObj := TdJSON.Create(obj);
          obj.FListItems.add(tempObj);
          obj := tempObj;
          obj.FValue := Unassigned;
        end;
        tag := 0;
      end;
      '}':
      begin
        temp := getValue();
        if not VarIsEmpty(temp) then
          obj.FValue := temp;
        if (obj.Parent <> nil) and not (assigned(obj.FItems) and (obj.FItems.Count = 0)) then
          obj := obj.Parent;
        tag := 0;
      end;
      ']':
      begin
        temp := getValue();
        if not VarIsEmpty(temp) then
          obj.FValue := temp;
        if (obj.Parent <> nil) then
          obj := obj.Parent;
        if assigned(obj.FListItems) and (obj.FListItems.Count = 1) then
        begin
          // When first seeing a list we dont know if it contains anything.
          // When at the end of list we check if the value has been set.
          // If it hasn't, we'll remove the unused object
          if (VarIsEmpty(obj.FListItems[0].FValue)) and
             (not assigned(obj.FListItems[0].FItems)) and
             (not assigned(obj.FListItems[0].FListItems)) then
          begin
            obj.FListItems[0].Free;
            obj.FListItems.Delete(0);
          end;
        end;
        tag := 0;
      end;
    end;
  end;
  result := obj;
end;

{ TJSONItems }

destructor TdJSONItems.Destroy;
var
  item: TdJSON;
begin
  for item in self.Values do
    item.Free;
  inherited;
end;

{ TJSONListItem }

destructor TdJSONListItems.Destroy;
var
  item: TdJSON;
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
