define-command table-select %{
    # check if the cursor is on a table
    try %{
        execute-keys "gi<a-k>\|<ret>"
    } catch %{
        fail "not a table"
    }
    evaluate-commands -save-regs '/' %{
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

define-command -hidden table-adjust-number-of-bars %{
    table-select
    # the last character of every line should be a bar
    try %{
        execute-keys -draft "s[^|]\n<ret>ha|"
    }
    # align bars and \n
    # indent is specified by the first line
    execute-keys -draft "s\|<ret>1<a-&>&<a-x>s\n<ret>&"
    # select the longest line
    execute-keys "<a-x>s\|\n<ret>&<space>"
    # select all bars except the first one
    execute-keys "<a-x>s\|<ret>)<a-space>"
    # add missing bars
    evaluate-commands -itersel -draft -save-regs 'c' %{
        execute-keys "h<a-h>"
        set-register c %val{selection_length}
        table-select
        execute-keys "<a-s>gh" %val{reg_c} "lr|"
    }
}

define-command table-align %{
    # make sure that all the rows have the same number of bars
    table-adjust-number-of-bars
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
    execute-keys -draft "O|<esc>2X<a-s><a-&>"
    evaluate-commands -draft table-align
    execute-keys "kgi2l"
}

# move columns and rows

define-command table-select-column %{
    evaluate-commands -draft table-align
    try %{
        execute-keys "<a-k>\|<ret>h"
    }
    try %{
        execute-keys -draft "<a-K>\n<ret>"
        execute-keys -draft "<a-h><a-k>\|<ret>"
    } catch %{
        fail "not in a table cell"
    }
    evaluate-commands -save-regs 'c' %{
        set-register c %val{cursor_char_column}
        table-select
        execute-keys "<a-s>gh" %val{reg_c} "l2h<a-i>|L"
    }
}

define-command table-move-column-right %{
    try %{
        # check if the cursor is inside the table
        execute-keys -draft "h<a-h><a-k>\|<ret>"
        # check if in the last column
        execute-keys -draft "h2F|<a-K>\n<ret>"
        evaluate-commands -draft %{
            execute-keys "hf|l"
            table-select-column
            execute-keys "d2<a-f>|;p"
        }
    }
}

define-command table-move-column-left %{
    try %{
        # check if in the first column
        execute-keys -draft "2<a-F>|<a-K>\n<ret>"
        evaluate-commands -draft %{
            execute-keys "<a-f>|"
            table-select-column
            execute-keys "df|p"
        }
    }
}

define-command table-move-row-up %{
    try %{
        execute-keys -draft "<a-C><a-space>"
        execute-keys -draft "kgi<a-k>\|<ret>"
        execute-keys -draft "kxdp"
    }
}

define-command table-move-row-down %{
    try %{
        execute-keys -draft "C<a-space>"
        execute-keys -draft "jgi<a-k>\|<ret>"
        execute-keys -draft "jxdkP"
    }
}

# interactive editing

define-command table-enable %{
    hook -group table global NormalIdle .* %{
        remove-hooks global table-replace
        try %{
            execute-keys -draft "gi<a-k>\|<ret>"
            # replace mode inside table cells
            hook -group table-replace global InsertChar .* %{
                try %{
                    execute-keys -draft "<esc>L<a-K>\|<ret>"
                    execute-keys -draft "<esc>t|;H<a-K>[^\s]<ret>;d"
                }
            }
            # normal mode mappings
            map window normal <tab> ": table-next-cell<ret>"
            map window normal <s-tab> ": table-previous-cell<ret>"
            map window normal o ": table-add-row-below<ret>i"
            map window normal O ": table-add-row-above<ret>i"
            map window normal <a-h> ": table-move-column-left<ret>"
            map window normal <a-l> ": table-move-column-right<ret>"
            map window normal <a-k> ": table-move-row-up<ret>"
            map window normal <a-j> ": table-move-row-down<ret>"
            # insert mode mappings
            map window insert <esc> "<esc>: evaluate-commands -draft table-align<ret>"
            map window insert <tab> "<esc>: table-next-cell<ret>i"
            map window insert <s-tab> "<esc>: table-previous-cell<ret>i"
            map window insert <a-h> ": table-move-column-left<ret>"
            map window insert <a-l> ": table-move-column-right<ret>"
            map window insert <a-k> ": table-move-row-up<ret>"
            map window insert <a-j> ": table-move-row-down<ret>"
        } catch %{
            table-remove-mappings
        }
    }
    set-option global table_enabled yes
}

define-command table-disable %{
    remove-hooks global table
    remove-hooks global table-replace
    table-remove-mappings
    set-option global table_enabled no
}

define-command table-toggle %{
    evaluate-commands %sh{
        if $kak_opt_table_enabled
        then
            printf "table-disable"
        else
            printf "table-enable"
        fi
    }
}

define-command -hidden table-remove-mappings %{
    # normal mode mappings
    unmap window normal <tab> ": table-next-cell<ret>"
    unmap window normal <s-tab> ": table-previous-cell<ret>"
    unmap window normal o ": table-add-row-below<ret>i"
    unmap window normal O ": table-add-row-above<ret>i"
    unmap window normal <a-h> ": table-move-column-left<ret>"
    unmap window normal <a-l> ": table-move-column-right<ret>"
    unmap window normal <a-k> ": table-move-row-up<ret>"
    unmap window normal <a-j> ": table-move-row-down<ret>"
    # insert mode mappings
    unmap window insert <esc> "<esc>: evaluate-commands -draft table-align<ret>"
    unmap window insert <tab> "<esc>: table-next-cell<ret>i"
    unmap window insert <s-tab> "<esc>: table-previous-cell<ret>i"
    unmap window insert <a-h> ": table-move-column-left<ret>"
    unmap window insert <a-l> ": table-move-column-right<ret>"
    unmap window insert <a-k> ": table-move-row-up<ret>"
    unmap window insert <a-j> ": table-move-row-down<ret>"
}

# User mode

declare-user-mode table

map global table a ": evaluate-commands -draft table-align<ret>" -docstring "align table"
map global table e ": table-enable<ret>" -docstring "enable table mode"
map global table d ": table-disable<ret>" -docstring "disable table mode"
map global table t ": table-toggle<ret>" -docstring "toggle table mode"

map global table l ": table-next-cell<ret>" -docstring "jump to next cell"
map global table h ": table-previous-cell<ret>" -docstring "jump to previous cell"

map global table <a-k> ": table-move-row-up<ret>" -docstring "move row up"
map global table <a-j> ": table-move-row-down<ret>" -docstring "move row down"
map global table <a-l> ": table-move-column-right<ret>" -docstring "move column to the right"
map global table <a-h> ": table-move-column-left<ret>" -docstring "move column to the left"

map global table s ": table-select<ret>" -docstring "select table"
map global table c ": table-select-column<ret>" -docstring "select column"

# Options

declare-option -hidden bool table_enabled no
