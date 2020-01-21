define-command table-select %{
    # check if the cursor is on a table
    try %{
        execute-keys "gi<a-k>\|<ret>"
    } catch %{
        fail "not a table"
    }
    set-register / (?:\h*\|[^\n]*\n)+
    try %{
        # check if the cursor is at the begin of the buffer
        execute-keys -draft "<a-C><a-space>"
        # check if on the first row of the table
        execute-keys -draft "kgi<a-k>\|<ret>"
        # jump to begin of the table
        execute-keys "<a-n>"
    }
    execute-keys "<a-n>n"
}

define-command -hidden table-strip %{
    table-select
    # strip minuses
    try %{
        execute-keys -draft "s^\h*\|-<ret>l<a-l>s[^|]<ret>d"
    }
    # strip whitespaces
    try %{
        execute-keys -draft "s^\h*\|<ret>2l<a-l>s\h*\|\h*|\A\h*<ret>s\h<ret>d"
    }
}

define-command -hidden table-adjust-number-of-columns %{
    table-select
    # the last character of every line should be a bar
    try %{
        execute-keys -draft "s[^|]\n<ret>ha|"
    }
    execute-keys "|awk -F'|' '{for (i = NF-1; i < count; i++) $0=$0""|""; print;}' count=" %sh[
            echo `echo "$kak_selection" | awk -F'|' '{print NF}' | sort -n | awk '{print $NF - 1}' RS='^$'`
        ] "<ret>"
}

define-command table-align %{
    # make sure that all the rows have the same number of columns
    table-adjust-number-of-columns
    # prepare the table
    table-strip
    execute-keys "<a-s><a-K>^\h*\|-<ret>"
    # bars should be surrounded by whitespaces
    try %{
        execute-keys -draft "s\|(?!\s)<ret>a <esc>"
    }
    try %{
        execute-keys -draft "s(?<!\h)\|" "<ret><a-K>^<ret>i <esc>"
    }
    # there should be at least three characters between two bars
    try %{
        execute-keys -draft "s(?<=\|)\h+(?=\|)" "<ret>c   <esc>"
    }
    table-select
    # align the bars
    execute-keys -draft "s\|<ret>&"
    # replace whitespaces with minuses
    try %{
        execute-keys -draft "<a-x><a-s><a-k>^\h*\|-<ret>s\|[^\n]*<ret>s <ret>r-"
    }
}

# jump from cell to cell
 
define-command table-next-cell %{
    evaluate-commands -draft table-align
    evaluate-commands -save-regs '/' %{
        set-register '/' '\| '
        try %{
            execute-keys -draft "<a-k>\|<ret>"
            execute-keys "<a-n>"
        }
        execute-keys 'nl'
    }
}

define-command table-previous-cell %{
    evaluate-commands -draft table-align
    evaluate-commands -save-regs '/' %{
        set-register '/' '\| '
        try %{
            execute-keys -draft "<a-?><ret><a-K>\n<ret>"
            execute-keys "<a-n>"
        }
        execute-keys '<a-n>l'
    }
}

# add row

define-command table-add-row-below %{
    execute-keys "o|<esc>"
    evaluate-commands -draft table-align
    try %{
        execute-keys "<a-k>^.<ret>k"
    }
    execute-keys "gi2l"
}

define-command table-add-row-above %{
    execute-keys "O|<esc>"
    evaluate-commands -draft table-align
    execute-keys "kgi2l"
}

# interactive editing

define-command table-enable %{
    hook -group table global NormalIdle .* %{
        try %{
            execute-keys -draft "gi<a-k>\|<ret>"
            # normal mode mappings
            map window normal <tab> ": table-next-cell<ret>"
            map window normal <s-tab> ": table-previous-cell<ret>"
            map window normal o ": table-add-row-below<ret>i"
            map window normal O ": table-add-row-above<ret>i"
            # insert mode mappings
            map window insert <esc> "<esc>: evaluate-commands -draft table-align<ret>"
            map window insert <tab> "<esc>: table-next-cell<ret>i"
            map window insert <s-tab> "<esc>: table-previous-cell<ret>i"
        } catch %{
            table-remove-mappings

        }
    }
}

define-command table-disable %{
    remove-hooks global table
    table-remove-mappings
}

define-command -hidden table-remove-mappings %{
    # normal mode mappings
    unmap window normal <tab> ": table-next-cell<ret>"
    unmap window normal <s-tab> ": table-previous-cell<ret>"
    unmap window normal o ": table-add-row-below<ret>i"
    unmap window normal O ": table-add-row-above<ret>i"
    # insert mode mappings
    unmap window insert <esc> "<esc>: evaluate-commands -draft table-align<ret>"
    unmap window insert <tab> "<esc>: table-next-cell<ret>i"
    unmap window insert <s-tab> "<esc>: table-previous-cell<ret>i"
}
