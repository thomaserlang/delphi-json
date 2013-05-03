unit Testjson;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit 
  being tested.

}

interface

uses
  TestFramework, Variants, SysUtils, Classes, Dialogs, json;

type
  // Test methods for class TJSON

  TestTJSON = class(TTestCase)
  strict private
    function loadFile(const AFilename: string): string;
  public

  published
    procedure TestUser;
    procedure TestUserList;
  end;

var
  fmt: TFormatSettings;

implementation

function TestTJSON.loadFile(const AFilename: string): string;
var
  jsonFile: TextFile;
  text: string;
begin
  result := '';

  AssignFile(jsonFile, AFilename);
  try
    Reset(jsonFile);

    while not Eof(jsonFile) do
    begin
      ReadLn(jsonFile, text);
      result := result+text;
    end;
  finally
    CloseFile(jsonFile);
  end;
end;

procedure TestTJSON.TestUser;
var
  photo, item, item_a: TJSONItem;
  i: integer;
begin
  with TJSON.Parse(loadFile('test1.json')) do
  begin
    try
      Check(FieldByName('username').AsString = 'thomas', FieldByName('username').AsString);
      i := 0;
      for photo in FieldByName('photos') do
      begin
        inc(i);
        check(photo.Field[0].AsString = format('Photo %d', [i]), 'title is not '+format('Photo %d', [i]));
        check(assigned(photo.FieldByName('urls')));
        check(photo['urls']['small'].AsString = format('http://example.com/photo%d_small.jpg', [i]), 'url is not '+format('http://example.com/photo%d_small.jpg', [i]));
        check(photo.FieldByName('urls').FieldByName('large').AsString = format('http://example.com/photo%d_large.jpg', [i]), 'url is not '+format('http://example.com/photo%d_large.jpg', [i]));
      end;
      i := 0;
      for item in FieldByName('int_list') do
      begin
        inc(i);
        check(item.AsInteger = i);
      end;

      i := 0;
      for item in FieldByName('str_list') do
      begin
        inc(i);
        check(item.AsString = inttostr(i));
      end;

      check(FieldByName('escape_text').AsString = 'Some "test"');
      check(FieldByName('escape_path').AsString = 'C:\test\test.txt');
    finally
      Free;
    end;
  end;
end;

procedure TestTJSON.TestUserList();
var
  users: TJSON;
  user: TJSONItem;
  i: integer;
begin
  users := TJSON.Parse(loadFile('test2.json'));
  try
    i := 0;
    for user in users do
    begin
      inc(i);
      case i of
        1: check(user['username'].AsString = 'thomas', user['username'].AsString+' is not thomas');
        2: check(user['name'].AsString = 'Kurt', user['name'].AsString+' is not kurt');
        3: check(user['username'].AsString = 'bent', user['username'].AsString+' is not bent');
      end;
    end;
  finally
    users.free;
  end;
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(TestTJSON.Suite);
end.

