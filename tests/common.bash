
SRC_DIR=$(cd ../src && pwd)

setup_context() {
    local root="$1"
    local pass_user="$2"
    local user_directory="$root/$pass_user"
    mkdir -p "$user_directory"
    local gpg_home="$user_directory/gnupg"
    mkdir "$gpg_home"
    chmod 700 "$gpg_home"
    gpg \
        --batch \
        --trust-model always \
        --homedir "$gpg_home" \
        --passphrase "" \
        --pinentry-mode loopback \
        --quick-gen-key  "$pass_user" default default > /dev/null
    echo "$user_directory"
}

setup_repository() {
    local root="$1"
    local name="$2"
    local path="$root/$name"
    git init --bare "$path" > /dev/null
    echo "$path"
}


function out_fmt( ) {
    local format="$1"
    local color="$2"
    local prefix="${3:-}"
    local suffix="${4:-}"
    while read line; do
        echo -en "\e[$format;${color}m${prefix}"
        echo -n "$line"
        echo -e "${suffix}\e[0m"
    done
}

function indent( ) {
    while read line; do
        echo "> $line"
    done

}

RED="31"
GREEN="32"
YELLOW="33"
BLUE="34"
MANGENTA="35"
CYAN="36"

LIGHT_RED="91"
LIGHT_GREEN="92"

NORMAL="0"
BOLD="1"
FAINT="2"
ITALIC="3"
UNDERLINE="4"


context() {
    local user=$1
    shift
    local user_color=$1
    shift
    local user_directory=$1
    shift
    local command=$1
    shift
    local expect_fail="0"
    local expected_output=""
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--fails" ]]; then
            expect_fail="1"
        elif [[ "$1" == "--output" ]]; then
            shift
            expected_output="$1"
        else
            echo "ABORTING TEST DUE TO UNKNOWN ARG: $1" | out_fmt "$BOLD" "$RED"
            exit 1
        fi
        shift
    done
    mapfile -t output < <( \
        PASSWORD_STORE_DIR="$user_directory/store" \
        PASSWORD_STORE_ENABLE_EXTENSIONS=true \
        PASSWORD_STORE_EXTENSIONS_DIR="$SRC_DIR" \
        PASSWORD_STORE_GPG_OPTS=" --trust-model always --homedir $user_directory/gnupg " \
        eval "$command"  \
            1> >( sed 's/^/out: /'  ) \
            2> >( sed 's/^/err: /'  ) \
            && echo "success" || echo "fail"

    )
    echo -e "\e[${BOLD};${user_color}m${user}:~\e[0m \e[${NORMAL};${user_color}m$command\e[0m"
    local had_output=0
    local is_success=0
    for line in "${output[@]}"; do
        if [[ "$line" == "success" ]]; then
            is_success=1
        elif [[ "$line" == "fail" ]]; then
            is_success=0
        else
            if [[ "$line" =~ "out: err: "* ]]; then
                echo "$line" | sed 's/out: err: //' | out_fmt "$FAINT" "$LIGHT_RED" "> "

            elif [[ "$line" =~ "out: "* ]]; then
                if [[ -n "$expected_output" ]]; then
                    if [[ "$line" != "out: $expected_output" ]]; then
                        echo "--- UNEXPECTED OUTPUT ---" | out_fmt "$BOLD" "$RED"
                        echo "OUTPUT WAS:" | out_fmt "$BOLD" "$RED"
                        echo "$line" | sed 's/^out: //' | out_fmt "$NORMAL" "$RED"
                        echo "BUT EXPECTED:" | out_fmt "$BOLD" "$RED"
                        echo "$expected_output" | out_fmt "$NORMAL" "$RED"
                        exit 1
                    else
                        echo "$line" | sed 's/out: //' | out_fmt "$FAINT;$UNDERLINE" "$LIGHT_GREEN" "> "

                    fi
                else
                    echo "$line" | sed 's/out: //' | out_fmt "$FAINT" "$LIGHT_GREEN" "> "
                fi
                had_output="1"
            fi
        fi
    done
    if [[ "$is_success" -ne 0 ]]; then
        if [[ -n "$expected_output" ]] && [[ "$had_output" -eq 0 ]]; then
            echo "--- MISSING EXPECTED OUTPUT ---" | out_fmt "$BOLD" "$RED"
            echo "GOT NO OUTPUT EXPECTED WAS:" | out_fmt "$BOLD" "$RED"
            echo "$expected_output" | out_fmt "$NORMAL" "$RED"
            exit 1
        fi
        if [[ $expect_fail -ne 0 ]]; then
            echo "--- UNEXPECTED SUCCESS ---" | out_fmt "$BOLD" "$RED"
            exit 1
        else
            echo "--- SUCCESS ---" | out_fmt "$BOLD" "$GREEN"
        fi
    else
        if [[ $expect_fail -ne 0 ]]; then
            echo "--- FAILED AS EXPECTED ---" | out_fmt "$BOLD" "$GREEN"
        else
            echo "--- FAILED ---" | out_fmt "$BOLD" "$RED"
            exit 1
        fi
    fi
}