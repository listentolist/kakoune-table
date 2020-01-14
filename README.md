# Table editor plugin for Kakoune

This plugin provides commands for simple ascii table formatting. 

## Installation

If you use plug.kak, just put this into your kakrc:

```
plug "listentolist/kakoune-table" domain "gitlab.com"
```

You need to have GNU awk installed.

## Usage

If you want to align the table, just do `table-align`. It is only important
that the columns are separated by a `|` and the first non-whitespace character
of each line of the table is `|`. To get a horizontal line, you just have to
begin the row with `|-`.

Example:

```
| a|  b|c
|-
|
```

When you run the `table-align` you get:

```
| a | b | c |
|---|---|---|
|   |   |   |
```

You can fill in the empty fields, change other fields or add new columns:

```
| a | bb | c | new column
|---|---|---|
| aaa  | bbb  |   |
|new row
```

After running `table-align`, you get:

```
| a       | bb  | c | new column |
|---------|-----|---|------------|
| aaa     | bbb |   |            |
| new row |     |   |            |
```
