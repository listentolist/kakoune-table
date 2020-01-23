# Table editor plugin for Kakoune

This plugin provides commands for simple table formatting. 

## Installation

If you use plug.kak, just put this into your kakrc:

```
plug "listentolist/kakoune-table" domain "gitlab.com" config %{
    # suggested mapping
    # map global user t ": evaluate-commands -draft table-align<ret>" -docstring "align table"
}
```

You need to have GNU awk installed.

## Commands

- `table-align`
- `table-select`
- `table-add-row-below`
- `table-add-row-above`
- `table-enable`
- `table-disable`
- `table-next-cell`
- `table-previous-cell`

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

## Interactive table editing

There is also an interactive table editing mode, that defines some convenient
mappings. You can enable and disable it by running `table-enable` and
`table-disable`. Whenever you leave insert mode by pressing `<esc>` the table
will be re-aligned. By pressing `<tab>` and `<s-tab>` you can jump from cell to
cell in insert and normal mode. With `o` and `O` in normal mode you add a row.
