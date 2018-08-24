# JSON parser for Delphi

## Why?
Didn't like the other Delphi JSON parsers out there.
They seemed too complicated for the simple task i had for JSON.

So this is my go at it.

This version is only tested on Delphi XE 3, Delphi XE 6 (Android) and Delphi 10 but should work for all Delphi versions that support generics and TStringHelper.

### New in version 0.2

  - Rewrote the whole thing to use TDictionary.
  - Added support for decoding unicode encoded characters.
  - Added support for datetime (must be specified in ISO 8601 for it to work!).

### What is missing

  - A better way to handle null values.
  - Exception if the JSON text is not valid.
  - Convert to string
  - Serialization and deserialization from/to objects.

## Examples

Just include the djson.pas file in your uses list for this to work.

### Example 1 - User

#### JSON
```json
{
  "username": "thomas",
  "name": "Thomas",
  "photos": [
    {
      "title": "Photo 1",
      "urls": {
        "small": "http://example.com/photo1_small.jpg",
        "large": "http://example.com/photo1_large.jpg"
      }
    },
    {
      "title": "Photo 2",
      "urls": {
        "small": "http://example.com/photo2_small.jpg",
        "large": "http://example.com/photo2_large.jpg"
      }
    }
  ],
  "int_list": [
    1,
    2,
    3
  ]
}
```

#### Delphi 
```delphi
var
  user: TdJSON;
  photo: TdJSON;
  i: TdJSON;
begin
  user := TdJSON.parse({JSON_TEXT});
  try
    writeln('Username: '+ user['username'].AsString);
    writeln('Name: '+ user['name'].AsString);
    // Photos
    for photo in user['photos'] do
    begin
      writeln('Title: ' + photo['title'].AsString);
      writeln('Small url: ' + photo['urls']['small'].AsString);
      writeln('Large url: ' + photo['urls']['large'].AsString);
    end;

    // Int list
    for i in user['int_list'] do
    begin
      writeln(i.AsInteger);
    end;
  finally
    user.free;
  end;
end;
```
    
### Example 2 - User list
#### JSON
```json
[
  {
    "username": "thomas",
    "name": "Thomas"
  },
  {
    "username": "kurt",
    "name": "Kurt"
  },
  {
    "username": "bent",
    "name": "Bent"
  }
]
```
    
#### Delphi
```delphi
var
  users: TdJSON;
  user: TdJSON;
begin
  users := TdJSON.Parse({JSON_TEXT});
  try
    for user in users do
    begin
      writeln(user['username'].AsString);
      writeln(user['name'].AsString);
    end;
  finally
    users.Free;
  end;
end;
```
    
# LICENSE
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
