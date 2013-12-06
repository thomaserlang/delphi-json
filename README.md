# JSON parser for Delphi

## Why?
Didn't like the other Delphi JSON parsers out there.
They seemed too complicated for the simple task i had for JSON.

So this is my go at it.

This version is only tested on Delphi XE 3 but should work in all Delphi versions that support generics.

### New in version 0.2

  - Rewrote the whole thing to use TDictionary.
  - Added support for decoding unicode encoded characters.
  - Added support for datetime (must be specified in ISO 8601 for it to work!).

### What is missing

  - A better way to handle null values.
  - Exception if the JSON text is not valid.

## Examples

Just include the json.pas file in your uses list for this to work.

### Example 1 - User

#### JSON
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
      ],
    }
  
#### Delphi 
    var
      user: TJSON;
      photo: TJSON;
      i: TJSON;
    begin
      json := TJSON.parse({JSON_TEXT});
      try
        writeln('Username: '+ user['username'].AsString);
        writeln('Name: '+ user['name'].AsString);
        // Photos
        for photo in json['photos'] do
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
    
### Example 2 - User list
#### JSON
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
    
#### Delphi
    var
      users: TJSON;
      user: TJSON;
    begin
      users := TJSON.Parse({JSON_TEXT});
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
    
