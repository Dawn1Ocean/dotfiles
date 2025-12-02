if status is-interactive
	fish_vi_key_bindings
	alias ch-wallpaper="~/bin/chwallpaper.sh"
	alias vim="nvim"
	export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1

    function proxy_on
        set -Ux http_proxy http://127.0.0.1:10808
        set -Ux https_proxy $http_proxy
        set -Ux HTTP_PROXY $http_proxy
        set -Ux HTTPS_PROXY $http_proxy
        set -Ux all_proxy socks5://127.0.0.1:10808
        set -Ux ALL_PROXY all_proxy
        echo -e "Proxy on."
    end

    function proxy_off
        set -e http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
        echo -e "Proxy off."
    end
    
    set -gx EDITOR nvim
    set -gx VISUAL nvim

    function sudo
        if test "$argv[1]" = "vim" || test "$argv[1]" = "nvim"
            command sudo -e $argv[2..-1]
        else
            command sudo $argv
        end
    end
end

