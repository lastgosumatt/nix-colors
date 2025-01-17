let
  inherit (builtins)
    length tail elemAt filter listToAttrs substring replaceStrings stringLength
    genList;

  # All of these are borrowed from nixpkgs
  mapListToAttrs = f: l: listToAttrs (map f l);
  escapeRegex = escape (stringToCharacters "\\[{()^$?*+|.");
  addContextFrom = a: b: substring 0 0 a + b;
  escape = list: replaceStrings list (map (c: "\\${c}") list);
  range = first: last:
    if first > last then [ ] else genList (n: first + n) (last - first + 1);
  stringToCharacters = s:
    map (p: substring p 1 s) (range 0 (stringLength s - 1));
  splitString = _sep: _s:
    let
      sep = builtins.unsafeDiscardStringContext _sep;
      s = builtins.unsafeDiscardStringContext _s;
      splits = filter builtins.isString (builtins.split (escapeRegex sep) s);
    in map (v: addContextFrom _sep (addContextFrom _s v)) splits;
  nameValuePair = name: value: { inherit name value; };

  # From https://github.com/arcnmx/nixexprs
  fromYAML = yaml:
    let
      stripLine = line: elemAt (builtins.match "(^[^#]*)($|#.*$)" line) 0;
      usefulLine = line: builtins.match "[ \\t]*" line == null;
      parseString = token:
        let match = builtins.match ''([^"]+|"([^"]*)" *)'' token;
        in if match == null then
          throw ''YAML string parse failed: "${token}"''
        else if elemAt match 1 != null then
          elemAt match 1
        else
          elemAt match 0;
      attrLine = line:
        let match = builtins.match "([^ :]+): *(.*)" line;
        in if match == null then
          throw ''YAML parse failed: "${line}"''
        else
          nameValuePair (elemAt match 0) (parseString (elemAt match 1));
      new-lines = splitString "\n" yaml;
      lines = linen: if length linen > 17 then lines (tail linen) else linen;
      lines' = lines new-lines;
      lines-substring = map (substring 4 20) lines';
      lines'' = filter usefulLine lines-substring;
    in mapListToAttrs attrLine lines'';

  convertScheme = slug: set: {
    # name = set.scheme;
    # inherit (set) author;
    inherit slug;
    colors = {
      inherit (set)
        color0 color1 color2 color3 color4 color5 color6 color7 color8 color9
        color10 color11 color12 color13 color14 color15;
    };
  };

  schemeFromYAML = slug: content: convertScheme slug (fromYAML content);
in schemeFromYAML
