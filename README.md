# JSON parser for Delphi

## Why?
Didn't like the other Delphi JSON parsers out there.
They seemed too complicated for the simple task i had for JSON.

So this is my go at it.

###Be aware!
I made this on a Friday, this is the first version.

## How it works
All values are stored as a variant.
TList is used to keep track of row and field objects. Field names are being stored in a TStringList. 

Field value can be accessed in the following ways:
- ``object.FieldByName('field').AsString``
- ``object.Field[0].AsString``
- ``object['field'].AsString``

``object['field']`` is the prefered way of accessing the value.

## Examples

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
      json: TJSON;
      item: TJSONItem;
    begin
      json := TJSON.parse({JSON_TEXT});
      try
        writeln('Username: '+ json['username'].AsString);
        writeln('Name: '+ json['name'].AsString);
        // Photos
        for item in json['photos'] do
        begin
          writeln('Title: ' + item['title'].AsString);
          writeln('Small url: ' + item['urls']['small'].AsString);
          writeln('Large url: ' + item['urls']['large'].AsString);
        end;
  
        // Int list
        for item in json['int_list'] do
        begin
          writeln(item.AsInteger);
        end;
      finally
        json.free;
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
      user: TJSONItem;
    begin
      users := TJSON.Parse({JSON_TEXT});
      try
        for user in users do
        begin
          writeln(user['username'].AsString);
          writeln(user['name'].AsString);
        end;
      finally
        json.Free;
      end;
    end;
    
