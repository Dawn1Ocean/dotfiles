function v2rayn
    if command -v v2rayn > /dev/null
        command v2rayn $argv
    else if test -f /opt/v2rayn-bin/v2rayN
        /opt/v2rayn-bin/v2rayN $argv
    end
end
