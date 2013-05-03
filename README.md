# JSON parser for Delphi

## Why?
Didn't like the other Delphi JSON parser out there.
They seemed too complicated, for something as simple as JSON.

So this is my go at it.

###Be aware!
I made this on a Friday, this is the first version.

## How it works
All values are stored as a variant.

It uses TList to keep track of row and field objects. Field names are being stored in a TStringList. 

Enumerator are being used to make the for loop easy to write.
It's possible to use "while" with "eof" and "next". 
But i can't see why, since the for loop is so much cleaner.

Fields in a JSON object, can be accesed with:
- object.FieldByName('field').AsString
- object.Field[0].AsString
- object['field'].AsString

"object['field']" is the prefered way of accessing the field value.
A object in a object can be accessed with "object['field1']['field2']", quite simple.

If the field value is a JSON object, then it can accessed it with:
- for item in object.AsJSON
- for item in object

Both returns a TJSONItem.

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
    
