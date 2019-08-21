{
The MIT License (MIT)

Copyright (c) 2018 Thomas Erlang

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
// Version 0.3
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
      FIsKeyValue: boolean;
      FIsDict: boolean;
      FValue: Variant;
      FItems: TdJSONItems;
      FListItems: TdJSONListItems;
      function GetJSONByNameOrIndex(const AData: variant): TdJSON;
      function GetString: string;
      function GetInteger: integer;
      function GetBoolean: boolean;
      function GetInt64: int64;
      function GetDouble: double;
      function GetDateTime: TDateTime;
      function GetIsNull: boolean;
    public
      constructor Create(AParent: TdJSON = nil);
      destructor Destroy; override;
      function GetEnumerator: TList<TdJSON>.TEnumerator;
      class function Parse(const AJSON: string): TdJSON;

      property Parent: TdJSON read FParent;
      property IsList: boolean read FIsList;
      property IsDict: boolean read FIsDict;
      property IsNull: boolean read GetIsNull;
      property Items: TdJSONItems read FItems;
      property ListItems: TdJSONListItems read FListItems;
      property Value: Variant read FValue;
      property AsString: string read GetString;
      property AsInteger: integer read GetInteger;
      property AsBoolean: boolean read GetBoolean;
      property AsInt64: int64 read GetInt64;
      property AsDouble: double read GetDouble;
      property AsDateTime: TDateTime read GetDateTime;
      property JSONByNameOrIndex[const AData: variant]: TdJSON read GetJSONByNameOrIndex; default;
      property _[const AData: variant]: TdJSON read GetJSONByNameOrIndex;
  end;

  EJSONUnknownFieldOrIndex = class(Exception);
  EJSONParseError = class(Exception);
  {$IFDEF MSWINDOWS}
  procedure DebugStr(const msg: variant);
  {$ENDIF}

var
  DJSONFormatSettings: TFormatSettings;

implementation

uses
  XSBuiltIns
  {$IFDEF MSWINDOWS}, Windows{$ENDIF}
  ;

{$M+}
{$TYPEINFO ON}

{$IFDEF MSWINDOWS}
procedure DebugStr(const msg: variant);
begin
  OutputDebugString(PWideChar(format('%s: %s', [FormatDateTime('hh:nn:ss.zzz', now), msg])));
end;
{$ENDIF}

{ TJSON }

constructor TdJSON.Create(AParent: TdJSON);
begin
  FParent := AParent;
  FValue := Unassigned;
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

function TdJSON.GetDouble: double;
begin
  result := VarAsType(FValue, varDouble);
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

function TdJSON.GetIsNull: boolean;
begin
  result := Value = null;
end;

function TdJSON.GetJSONByNameOrIndex(const AData: variant): TdJSON;
var
  p: Integer;
begin
  case VarType(AData) and VarTypeMask of
    varString, varUString, varWord, varLongWord:
      begin
        p := Pos('|', AData);
        if p = 0 then
          if not FItems.TryGetValue(AData, result) then
            raise EJSONUnknownFieldOrIndex.Create(format('Unknown field: %s', [AData]))
          else
            exit;

        if not FItems.TryGetValue(Copy(AData, 1, p - 1), result) then
            raise EJSONUnknownFieldOrIndex.Create(format('Unknown field: %s', [AData]))
          else
          begin
            Result := result.GetJSONByNameOrIndex(Copy(AData, p + 1, Length(aData) - p));
            exit;
          end;
      end;
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
  inString, escaped: boolean;
  temp: variant;
  obj: TdJSON;

  function getValue: variant;
  var
    prev, prevPrev: char;
    ubuf, i, skip: integer;
    s: string;
    resultS: string;
  begin
    s := trim(AJSON.Substring(tag-1, index-tag));
    result := unassigned;
    if s = '' then
      exit;

    if s.Chars[0] <> '"' then
    begin
      if s = 'null' then
        exit(null)
      else if s = 'false' then
        exit(false)
      else if s = 'true' then
        exit(true);
      exit(s);
    end;

    if s = '""' then
      exit('');
    resultS := '';
    prev := #0;
    prevPrev := #0;
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

  procedure SetValue;
  begin
    obj.FValue := getValue;
  end;

  procedure AddSingleValue;
  begin
    temp := getValue();
    if not VarIsEmpty(temp) then
    begin
      obj := TdJSON.Create(obj);
      obj.FValue := temp;
      obj.parent.ListItems.Add(obj);
      obj := obj.Parent;
    end;
  end;

begin
  result := nil;
  index := 0;
  tag := 0;
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
        if not assigned(obj) or not obj.FIsKeyValue then
          obj := TdJSON.Create(obj);
        obj.FIsKeyValue := false;
        obj.FIsDict := true;
        obj.FItems := TdJSONItems.Create;
        if not assigned(result) then
        begin
          result := obj;
        end;
        if assigned(obj.parent) and obj.parent.IsList then
        begin
          obj.Parent.ListItems.Add(obj);
        end;
        tag := 0;
      end;
      '}':
      begin
        if not obj.IsDict then
        begin
          SetValue();
          obj := obj.Parent;
        end;
        obj := obj.Parent;
        tag := 0;
      end;
      '[':
      begin
        if not assigned(obj) or not obj.FIsKeyValue then
          obj := TdJSON.Create(obj);
        obj.FIsKeyValue := false;
        obj.FIsList := true;
        obj.FListItems := TdJSONListItems.Create;
        if not assigned(result) then
        begin
          result := obj;
        end;
        if assigned(obj.parent) and obj.parent.IsList then
        begin
          obj.Parent.ListItems.Add(obj);
        end;
        tag := 0;
      end;
      ']':
      begin
        if not obj.IsList and not obj.IsDict then
        begin
          SetValue();
          obj.Parent.ListItems.Add(obj);
        end
        else if obj.IsList then
        begin
          AddSingleValue();
        end;
        obj := obj.Parent;
        tag := 0;
      end;
      ':':
      begin
        obj := TdJSON.Create(obj);
        obj.FIsKeyValue := true;
        obj.Parent.Items.Add(getValue(), obj);
        tag := 0;
      end;
      ',':
      begin
        if not obj.IsList and not obj.IsDict then
        begin
          SetValue();
          obj := obj.Parent;
        end
        else if obj.IsList then
        begin
          AddSingleValue();
        end;
        tag := 0;
      end;
    end;
  end;
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
