function fish_user_key_bindings
    function updir
        cd ..
        commandline -f repaint
        if count $TMUX > /dev/null
            tmux refresh-client -S
            tmux refresh-client -S
        end
        eval (direnv export fish);
    end

    function myprevd
        prevd > /dev/null 2>&1
        commandline -f repaint
        if count $TMUX > /dev/null
            tmux refresh-client -S
            tmux refresh-client -S
        end
        eval (direnv export fish);
    end

    function mynextd
        nextd > /dev/null 2>&1
        commandline -f repaint
        if count $TMUX > /dev/null
            tmux refresh-client -S
            tmux refresh-client -S
        end
        eval (direnv export fish);
    end

    function fzf-jump-cd -d "Change directory"
        set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
        begin
            set -lx FZF_DEFAULT_OPTS "--expect ctrl-space,alt-enter --height $FZF_TMUX_HEIGHT --reverse $FZF_DEFAULT_OPTS"
            set -l result (jump top | fzf +m)
            set -l dir (string trim -- "$result[2]")
            if test -n "$dir"
                if test -z "$result[1]"
                    if not cd "$dir"
                        jump clean
                    end
                else
                    commandline -i -- "$dir/"
                end
            end
        end
        commandline -f repaint
        if count $TMUX > /dev/null
            tmux refresh-client -S
            tmux refresh-client -S
        end
        eval (direnv export fish);
    end

    function fzf-select -d 'fzf commandline job and print unescaped selection back to commandline'
        set -l cmd (commandline -j)
        set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
        [ "$cmd" ]; or return
        set -l result (eval $cmd | fzf -m --height $FZF_TMUX_HEIGHT --reverse --tiebreak=index --select-1 --exit-0 | string join ' ')
        [ "$result" ]; and commandline -j -- $result
        commandline -f repaint
    end

    function fzf-history-widget -d "Show command history"
        set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
        begin
            set -lx FZF_DEFAULT_OPTS "--read0 --reverse --height $FZF_TMUX_HEIGHT $FZF_DEFAULT_OPTS +s --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS +m"
            history -z | fzf -q (commandline) | read -l result
            and commandline -r -- (string trim -r $result)
        end
        commandline -f repaint
    end

    function fzf-history-token-widget -d "Show command history"
        set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
        set str (commandline -jc)
        set tok (commandline -tc)
        begin
            set -lx FZF_DEFAULT_OPTS "--reverse --height $FZF_TMUX_HEIGHT $FZF_DEFAULT_OPTS +s --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS +m"
            if [ $str = $tok ]
                history -z | fzf --read0 -q $str | read -lz result
                and commandline -r -- (string trim -r $result)
            else
                set -l list
                for his in $history
                    echo $his | read --tokenize --array tokens
                    set -a list $tokens[-1..1]
                    if test (count $list) -gt 256
                        break
                    end
                end
                string join0 -- $list | fzf --read0 -q $tok | read -l result
                and commandline -tr -- $result
            end
        end
        commandline -f repaint
    end

    function elvish-nav -d ""
        tput smcup
        elvish | read -l result
        [ "$result" ]; and eval cd "$result"
        tput rmcup
        commandline -f repaint
        if count $TMUX > /dev/null
            tmux refresh-client -S
            tmux refresh-client -S
        end
        eval (direnv export fish);
    end

    function fzf-command-go -d "Execute current command line and filter results by fzf"
        set -q FZF_TMUX; or set FZF_TMUX 0
        set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
        if [ $FZF_TMUX -eq 1 ]
            commandline -aj " 2>&1 | fzf-tmux -d$FZF_TMUX_HEIGHT"
        else
            commandline -aj " 2>&1 | fzf"
        end
        commandline -f execute
    end

    function open-magit -d "Open magit in emacs"
        if git rev-parse --is-inside-work-tree > /dev/null 2>&1
            set -l sn (tmux display-message -p '#S')
            set -l EMACS
            if [ $sn = "gui" ]
                emacspopup "(cd \"$PWD\") (magit-status)"
            else
                set EMACS emacsclient -n -q -u -e
                tmux switch-client -t emacs
                $EMACS "(progn (+amos/workspace-new) (cd \"$PWD\") (magit-status) (setq +amos-tmux-need-switch t))"
            end
        end
    end

    function open-ranger -d "Open ranger in emacs"
        set -l sn (tmux display-message -p '#S')
        set -l EMACS
        if [ $sn = "gui" ]
            emacspopup "(cd \"$PWD\") (+amos/dired-jump)"
        else
            set EMACS emacsclient -n -q -u -e
            tmux switch-client -t emacs
            $EMACS "(progn (+amos/workspace-new) (cd \"$PWD\") (+amos/dired-jump) (setq +amos-tmux-need-switch t))"
        end
    end

    function fish_clipboard_copy
        set esc "\033]52;c;"(printf (commandline) | head -c 100000 | base64 | tr -d '\r\n')"\a"
        if count $TMUX > /dev/null
            set esc "\033Ptmux;\033"$esc"\033\\" # tmux
        end
        printf "$esc"
    end

    function pet-select
        set -l query (commandline)
        pet search --query "$query" $argv | read cmd
        commandline $cmd
    end

    function ls-commandline -d "execute exa"
        if string match -r '^ *$' (commandline) > /dev/null 2>&1
            commandline "exa"
            commandline -f execute
        else
            return
        end
    end

    function proxy-commandline -d "execute commandline using proxychains"
        if string match -r '^ *$' (commandline) > /dev/null 2>&1
            return
        else
            commandline "proxychains "(commandline)
            commandline -f execute
        end
    end

    function sudo-commandline -d "execute commandline using sudo"
        if string match -q -r '^ *$' -- (commandline)
            return
        else if string match -q -r '^sudo ' -- (commandline)
            commandline -f execute
        else if string match -q -r '^e ' -- (commandline)
            set -l cmd (commandline)
            commandline (string replace -r '^e ' 'E ' -- $cmd)
            commandline -f execute
        else
            commandline "sudo "(commandline)
            commandline -f execute
        end
    end

    function gdb-commandline -d "execute commandline using tmuxgdb"
        if string match -r '^ *$' (commandline) > /dev/null 2>&1
            return
        else
            commandline "tmuxgdb "(commandline)
            commandline -f execute
        end
    end

    function my-edit-command -d "edit command buffer or tmux buffer"
        if not string match -r '^ *$' (commandline) > /dev/null 2>&1
            # vim (tmux capture-pane -S - -E - -p | psub -f)
            edit_command_buffer
        end
    end

    function my-edit-tmux -d "edit command buffer or tmux buffer"
        if string match -r '^ *$' (commandline) > /dev/null 2>&1
            vim (tmux capture-pane -S - -E - -p | psub -f)
        end
    end

    function delete-suggestion
        commandline --with-suggestion | read -lz cmd
        builtin history delete --exact --case-sensitive $cmd
        builtin history merge
    end

    function yank-commandline
        commandline | osc52clip
    end

    bind \eD delete-suggestion
    bind \cs sudo-commandline
    bind \e` proxy-commandline # Control-Shift-S
    bind \cq gdb-commandline
    bind \em ls-commandline
    bind \cr fzf-history-token-widget
    bind \ci __fzf_complete
    bind \eG open-magit
    bind \ep updir
    bind \en elvish-nav
    bind \eg fzf-jump-cd
    bind \eo myprevd
    bind \ei mynextd
    # bind \eR pet-select
    # bind \em fzf-command-go
    bind \cv fzf-select
    bind \er open-ranger
    bind \ey open-ranger
    bind \eE my-edit-command
    bind \ey yank-commandline
    function nop
    end
    bind \ee nop
    bind \ev nop

    # bind \eE my-edit-tmux

    bind \e, history-token-search-forward

    function start_bracketed_paste
        set -g __fish_last_bind_mode $fish_bind_mode
        # If the token is currently single-quoted,
        # we escape single-quotes (and backslashes).
        __fish_commandline_is_singlequoted
        and set -g __fish_paste_quoted 1
        set -g __fish_amos_cmd (commandline | string split0)
        set -g __fish_amos_cursor (commandline -C)
        commandline -r ""
    end

    function stop_bracketed_paste
        set fish_bind_mode $__fish_last_bind_mode
        set -e __fish_paste_quoted
        set -l cmdline (string trim -N -- (commandline | string split0) | string split0)
        set -l x (string sub -N -l $__fish_amos_cursor -- $__fish_amos_cmd | string split0)
        if test -z "$x"
            set x ""
        end
        set -l y (string sub -N -s (math $__fish_amos_cursor + 1) -l (math (string length -- $__fish_amos_cmd) - $__fish_amos_cursor - 1) -- $__fish_amos_cmd | string split0)
        if test -z "$y"
            set y ""
        end
        commandline -r -- $x$cmdline$y
        commandline -C (math $__fish_amos_cursor + (string length -- "$cmdline"))
        set -e __fish_amos_cmd
        set -e __fish_amos_cursor
        commandline -f force-repaint
    end

    for mode in (bind --list-modes | string match -v paste)
        bind --preset -M $mode -m paste \e\[200~ 'start_bracketed_paste'
    end
    bind --preset -M paste \e\[201~ 'stop_bracketed_paste'

    function insert-last-arg
        set -l a (commandline -co)[-1]
        test -n "$a"
        and commandline -t -- $a
    end

    function insert-last-line
        set -l a (string escape -n -- (string trim -- (tmux capture-pane -p | rg -v '^$|❯|^\\[' | tail -1)))
        test -n "$a"
        and commandline -t -- $a
    end

    bind \e\> 'insert-last-arg'
    bind \e\< 'insert-last-line'
end
