# bash completion for qshell                               -*- shell-script -*-

__qshell_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__qshell_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__qshell_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__qshell_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__qshell_handle_reply()
{
    __qshell_debug "${FUNCNAME[0]}"
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            COMPREPLY=( $(compgen -W "${allflags[*]}" -- "$cur") )
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __qshell_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi
            return 0;
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __qshell_index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions=("${must_have_one_noun[@]}")
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    COMPREPLY=( $(compgen -W "${completions[*]}" -- "$cur") )

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        COMPREPLY=( $(compgen -W "${noun_aliases[*]}" -- "$cur") )
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
        declare -F __custom_func >/dev/null && __custom_func
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
       compopt -o nospace
    fi
}

# The arguments should be in the form "ext1|ext2|extn"
__qshell_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__qshell_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1
}

__qshell_handle_flag()
{
    __qshell_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __qshell_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __qshell_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __qshell_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
      commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if __qshell_contains_word "${words[c]}" "${two_word_flags[@]}"; then
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__qshell_handle_noun()
{
    __qshell_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __qshell_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __qshell_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__qshell_handle_command()
{
    __qshell_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_qshell_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __qshell_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__qshell_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __qshell_handle_reply
        return
    fi
    __qshell_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __qshell_handle_flag
    elif __qshell_contains_word "${words[c]}" "${commands[@]}"; then
        __qshell_handle_command
    elif [[ $c -eq 0 ]]; then
        __qshell_handle_command
    elif __qshell_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __qshell_handle_command
        else
            __qshell_handle_noun
        fi
    else
        __qshell_handle_noun
    fi
    __qshell_handle_word
}

__qshell_parse_get()
{
    local qshell_output out
    if qshell_output=$(qshell user ls --name 2>/dev/null); then
        out=($(echo "${qshell_output}"))
        COMPREPLY=( $( compgen -W "${out[*]}" -- "$cur" ) )
    fi
}

__qshell_get_resource()
{
    __qshell_parse_get
    if [[ $? -eq 0 ]]; then
        return 0
    fi
}

__custom_func() {
    case ${last_command} in
        qshell_user_cu)
            __qshell_get_resource
            return
            ;;
        *)
            ;;
    esac
}

_qshell_account()
{
    last_command="qshell_account"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--overwrite")
    flags+=("-w")
    local_nonpersistent_flags+=("--overwrite")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_alilistbucket()
{
    last_command="qshell_alilistbucket"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_b64decode()
{
    last_command="qshell_b64decode"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--safe")
    flags+=("-s")
    local_nonpersistent_flags+=("--safe")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_b64encode()
{
    last_command="qshell_b64encode"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--safe")
    flags+=("-s")
    local_nonpersistent_flags+=("--safe")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_batchchgm()
{
    last_command="qshell_batchchgm"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--failure-list=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--failure-list=")
    flags+=("--force")
    flags+=("-y")
    local_nonpersistent_flags+=("--force")
    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--success-list=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--success-list=")
    flags+=("--worker=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--worker=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_batchchtype()
{
    last_command="qshell_batchchtype"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--failure-list=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--failure-list=")
    flags+=("--force")
    flags+=("-y")
    local_nonpersistent_flags+=("--force")
    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--success-list=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--success-list=")
    flags+=("--worker=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--worker=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_batchcopy()
{
    last_command="qshell_batchcopy"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--failure-list=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--failure-list=")
    flags+=("--force")
    flags+=("-y")
    local_nonpersistent_flags+=("--force")
    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--overwrite")
    flags+=("-w")
    local_nonpersistent_flags+=("--overwrite")
    flags+=("--success-list=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--success-list=")
    flags+=("--worker=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--worker=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_batchdelete()
{
    last_command="qshell_batchdelete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--failure-list=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--failure-list=")
    flags+=("--force")
    flags+=("-y")
    local_nonpersistent_flags+=("--force")
    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--success-list=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--success-list=")
    flags+=("--worker=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--worker=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_batchexpire()
{
    last_command="qshell_batchexpire"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-y")
    local_nonpersistent_flags+=("--force")
    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--worker=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--worker=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_batchfetch()
{
    last_command="qshell_batchfetch"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--failure-list=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--failure-list=")
    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--success-list=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--success-list=")
    flags+=("--worker=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--worker=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_batchmove()
{
    last_command="qshell_batchmove"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--failure-list=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--failure-list=")
    flags+=("--force")
    flags+=("-y")
    local_nonpersistent_flags+=("--force")
    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--overwrite")
    flags+=("-w")
    local_nonpersistent_flags+=("--overwrite")
    flags+=("--success-list=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--success-list=")
    flags+=("--worker=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--worker=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_batchrename()
{
    last_command="qshell_batchrename"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--failure-list=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--failure-list=")
    flags+=("--force")
    flags+=("-y")
    local_nonpersistent_flags+=("--force")
    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--overwrite")
    flags+=("-w")
    local_nonpersistent_flags+=("--overwrite")
    flags+=("--success-list=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--success-list=")
    flags+=("--worker=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--worker=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_batchsign()
{
    last_command="qshell_batchsign"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--deadline=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--deadline=")
    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_batchstat()
{
    last_command="qshell_batchstat"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_buckets()
{
    last_command="qshell_buckets"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_cdnprefetch()
{
    last_command="qshell_cdnprefetch"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_cdnrefresh()
{
    last_command="qshell_cdnrefresh"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dirs")
    flags+=("-r")
    local_nonpersistent_flags+=("--dirs")
    flags+=("--input-file=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_chgm()
{
    last_command="qshell_chgm"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_chtype()
{
    last_command="qshell_chtype"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_completion()
{
    last_command="qshell_completion"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--help")
    flags+=("-h")
    local_nonpersistent_flags+=("--help")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_copy()
{
    last_command="qshell_copy"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--key=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--key=")
    flags+=("--overwrite")
    flags+=("-w")
    local_nonpersistent_flags+=("--overwrite")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_d2ts()
{
    last_command="qshell_d2ts"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_delete()
{
    last_command="qshell_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_dircache()
{
    last_command="qshell_dircache"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--outfile=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--outfile=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_domains()
{
    last_command="qshell_domains"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_expire()
{
    last_command="qshell_expire"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_fetch()
{
    last_command="qshell_fetch"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--key=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--key=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_fput()
{
    last_command="qshell_fput"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--callback-host=")
    two_word_flags+=("-T")
    local_nonpersistent_flags+=("--callback-host=")
    flags+=("--callback-urls=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--callback-urls=")
    flags+=("--mimetype=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--mimetype=")
    flags+=("--overwrite")
    flags+=("-w")
    local_nonpersistent_flags+=("--overwrite")
    flags+=("--storage=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--storage=")
    flags+=("--up-host=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--up-host=")
    flags+=("--worker=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--worker=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_get()
{
    last_command="qshell_get"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--outfile=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--outfile=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_ip()
{
    last_command="qshell_ip"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_listbucket()
{
    last_command="qshell_listbucket"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--marker=")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--marker=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--prefix=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--prefix=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_listbucket2()
{
    last_command="qshell_listbucket2"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--append")
    flags+=("-a")
    local_nonpersistent_flags+=("--append")
    flags+=("--end=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--end=")
    flags+=("--marker=")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--marker=")
    flags+=("--max-retry=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--max-retry=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--prefix=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--prefix=")
    flags+=("--readable")
    flags+=("-r")
    local_nonpersistent_flags+=("--readable")
    flags+=("--start=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--start=")
    flags+=("--suffixes=")
    two_word_flags+=("-q")
    local_nonpersistent_flags+=("--suffixes=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_m3u8delete()
{
    last_command="qshell_m3u8delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_m3u8replace()
{
    last_command="qshell_m3u8replace"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_mirrorupdate()
{
    last_command="qshell_mirrorupdate"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_move()
{
    last_command="qshell_move"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--key=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--key=")
    flags+=("--overwrite")
    flags+=("-w")
    local_nonpersistent_flags+=("--overwrite")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_pfop()
{
    last_command="qshell_pfop"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--pipeline=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--pipeline=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_prefop()
{
    last_command="qshell_prefop"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_privateurl()
{
    last_command="qshell_privateurl"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_qdownload()
{
    last_command="qshell_qdownload"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--thread=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--thread=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_qetag()
{
    last_command="qshell_qetag"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_qupload()
{
    last_command="qshell_qupload"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--callback-host=")
    two_word_flags+=("-T")
    local_nonpersistent_flags+=("--callback-host=")
    flags+=("--callback-urls=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--callback-urls=")
    flags+=("--failure-list=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--failure-list=")
    flags+=("--overwrite-list=")
    two_word_flags+=("-w")
    local_nonpersistent_flags+=("--overwrite-list=")
    flags+=("--success-list=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--success-list=")
    flags+=("--worker=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--worker=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_qupload2()
{
    last_command="qshell_qupload2"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--bind-nic-ip=")
    local_nonpersistent_flags+=("--bind-nic-ip=")
    flags+=("--bind-rs-ip=")
    local_nonpersistent_flags+=("--bind-rs-ip=")
    flags+=("--bind-up-ip=")
    local_nonpersistent_flags+=("--bind-up-ip=")
    flags+=("--bucket=")
    local_nonpersistent_flags+=("--bucket=")
    flags+=("--callback-host=")
    two_word_flags+=("-T")
    local_nonpersistent_flags+=("--callback-host=")
    flags+=("--callback-urls=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--callback-urls=")
    flags+=("--check-exists")
    local_nonpersistent_flags+=("--check-exists")
    flags+=("--check-hash")
    local_nonpersistent_flags+=("--check-hash")
    flags+=("--check-size")
    local_nonpersistent_flags+=("--check-size")
    flags+=("--failure-list=")
    local_nonpersistent_flags+=("--failure-list=")
    flags+=("--file-list=")
    local_nonpersistent_flags+=("--file-list=")
    flags+=("--file-type=")
    local_nonpersistent_flags+=("--file-type=")
    flags+=("--ignore-dir")
    local_nonpersistent_flags+=("--ignore-dir")
    flags+=("--key-prefix=")
    local_nonpersistent_flags+=("--key-prefix=")
    flags+=("--log-file=")
    local_nonpersistent_flags+=("--log-file=")
    flags+=("--log-level=")
    local_nonpersistent_flags+=("--log-level=")
    flags+=("--log-rotate=")
    local_nonpersistent_flags+=("--log-rotate=")
    flags+=("--overwrite")
    local_nonpersistent_flags+=("--overwrite")
    flags+=("--overwrite-list=")
    local_nonpersistent_flags+=("--overwrite-list=")
    flags+=("--put-threshold=")
    local_nonpersistent_flags+=("--put-threshold=")
    flags+=("--rescan-local")
    local_nonpersistent_flags+=("--rescan-local")
    flags+=("--skip-file-prefixes=")
    local_nonpersistent_flags+=("--skip-file-prefixes=")
    flags+=("--skip-fixed-strings=")
    local_nonpersistent_flags+=("--skip-fixed-strings=")
    flags+=("--skip-path-prefixes=")
    local_nonpersistent_flags+=("--skip-path-prefixes=")
    flags+=("--skip-suffixes=")
    local_nonpersistent_flags+=("--skip-suffixes=")
    flags+=("--src-dir=")
    local_nonpersistent_flags+=("--src-dir=")
    flags+=("--success-list=")
    local_nonpersistent_flags+=("--success-list=")
    flags+=("--thread-count=")
    local_nonpersistent_flags+=("--thread-count=")
    flags+=("--up-host=")
    local_nonpersistent_flags+=("--up-host=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_reqid()
{
    last_command="qshell_reqid"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_rpcdecode()
{
    last_command="qshell_rpcdecode"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_rpcencode()
{
    last_command="qshell_rpcencode"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_rput()
{
    last_command="qshell_rput"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--callback-host=")
    two_word_flags+=("-T")
    local_nonpersistent_flags+=("--callback-host=")
    flags+=("--callback-urls=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--callback-urls=")
    flags+=("--mimetype=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--mimetype=")
    flags+=("--overwrite")
    flags+=("-w")
    local_nonpersistent_flags+=("--overwrite")
    flags+=("--storage=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--storage=")
    flags+=("--up-host=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--up-host=")
    flags+=("--worker=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--worker=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_saveas()
{
    last_command="qshell_saveas"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_stat()
{
    last_command="qshell_stat"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_sync()
{
    last_command="qshell_sync"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--key=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--key=")
    flags+=("--uphost=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--uphost=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_tms2d()
{
    last_command="qshell_tms2d"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_tns2d()
{
    last_command="qshell_tns2d"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_token_qbox()
{
    last_command="qshell_token_qbox"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-key=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--access-key=")
    flags+=("--content-type=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--content-type=")
    flags+=("--http-body=")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--http-body=")
    flags+=("--secret-key=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--secret-key=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_token_qiniu()
{
    last_command="qshell_token_qiniu"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-key=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--access-key=")
    flags+=("--content-type=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--content-type=")
    flags+=("--http-body=")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--http-body=")
    flags+=("--method=")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--method=")
    flags+=("--secret-key=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--secret-key=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_token_upload()
{
    last_command="qshell_token_upload"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-key=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--access-key=")
    flags+=("--secret-key=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--secret-key=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_token()
{
    last_command="qshell_token"

    command_aliases=()

    commands=()
    commands+=("qbox")
    commands+=("qiniu")
    commands+=("upload")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_ts2d()
{
    last_command="qshell_ts2d"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_unzip()
{
    last_command="qshell_unzip"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dir=")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_urldecode()
{
    last_command="qshell_urldecode"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_urlencode()
{
    last_command="qshell_urlencode"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_user_clean()
{
    last_command="qshell_user_clean"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_user_cu()
{
    last_command="qshell_user_cu"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_user_lookup()
{
    last_command="qshell_user_lookup"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_user_ls()
{
    last_command="qshell_user_ls"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--name")
    flags+=("-n")
    local_nonpersistent_flags+=("--name")
    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_user_remove()
{
    last_command="qshell_user_remove"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_user()
{
    last_command="qshell_user"

    command_aliases=()

    commands=()
    commands+=("clean")
    commands+=("cu")
    commands+=("lookup")
    commands+=("ls")
    commands+=("remove")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_version()
{
    last_command="qshell_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_qshell_root_command()
{
    last_command="qshell"

    command_aliases=()

    commands=()
    commands+=("account")
    commands+=("alilistbucket")
    commands+=("b64decode")
    commands+=("b64encode")
    commands+=("batchchgm")
    commands+=("batchchtype")
    commands+=("batchcopy")
    commands+=("batchdelete")
    commands+=("batchexpire")
    commands+=("batchfetch")
    commands+=("batchmove")
    commands+=("batchrename")
    commands+=("batchsign")
    commands+=("batchstat")
    commands+=("buckets")
    commands+=("cdnprefetch")
    commands+=("cdnrefresh")
    commands+=("chgm")
    commands+=("chtype")
    commands+=("completion")
    commands+=("copy")
    commands+=("d2ts")
    commands+=("delete")
    commands+=("dircache")
    commands+=("domains")
    commands+=("expire")
    commands+=("fetch")
    commands+=("fput")
    commands+=("get")
    commands+=("ip")
    commands+=("listbucket")
    commands+=("listbucket2")
    commands+=("m3u8delete")
    commands+=("m3u8replace")
    commands+=("mirrorupdate")
    commands+=("move")
    commands+=("pfop")
    commands+=("prefop")
    commands+=("privateurl")
    commands+=("qdownload")
    commands+=("qetag")
    commands+=("qupload")
    commands+=("qupload2")
    commands+=("reqid")
    commands+=("rpcdecode")
    commands+=("rpcencode")
    commands+=("rput")
    commands+=("saveas")
    commands+=("stat")
    commands+=("sync")
    commands+=("tms2d")
    commands+=("tns2d")
    commands+=("token")
    commands+=("ts2d")
    commands+=("unzip")
    commands+=("urldecode")
    commands+=("urlencode")
    commands+=("user")
    commands+=("version")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("-C")
    flags+=("--debug")
    flags+=("-d")
    flags+=("--local")
    flags+=("-L")
    flags+=("--version")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_qshell()
{
    local cur prev words cword
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __qshell_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("qshell")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local last_command
    local nouns=()

    __qshell_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_qshell qshell
else
    complete -o default -o nospace -F __start_qshell qshell
fi

# ex: ts=4 sw=4 et filetype=sh
