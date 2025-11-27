function uxplay --description 'Start avahi-daemon and run uxplay'
    sudo systemctl start avahi-daemon.service; and command uxplay $argv
end
