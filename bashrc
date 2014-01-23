# enable colors in less
# -R or --RAW-CONTROL-CHARS
export LESS=-R

#enable 256color for terminal multiplexs
alias tmux="tmux -2"
alias vim="gvim -v"

# project opening shortcuts
alias coddress='gvim -vc "Sauce coddress"'
alias dotcore='gvim -vc "Sauce dotcore"'
alias berale='gvim -vc "Sauce berale"'

# in order to use only one device, pass the -d option, as in -d 0,1 to use devices 0 and 1
cgminer_settings='DISPLAY=:0 GPU_MAX_ALLOC_PERCENT=100 GPU_USE_SYNC_OBJECTS=1 ~/crypto/miners/cgminer-829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/cgminer -I 11,19  --vectors 2 -g 1 --gpu-engine 750,910 --gpu-memclock 850,1375 --temp-target 80 --auto-fan -w 128,256 --thread-concurrency 6144,8500 --shaders 960,1536 --scrypt'

#mining software shortcut
alias ltc_cpu='~/crypto/miners/cpuminer-2.3.2/minerd --url=stratum+tcp://hk2.wemineltc.com:3333 --userpass=perrin4869.home_cpu:conan4869'
alias ltc_cpu_backup='~/crypto/miners/cpuminer-2.3.2/minerd --url=stratum+tcp://gigahash.wemineltc.com:3334 --userpass=perrin4869.home_cpu:conan4869'
alias ltc_gpu=$cgminer_settings' -o stratum+tcp://gigahash.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://hk2.wemineltc.com:3333 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://usa2.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://easymining.eu:3333 -u perrin4869.home_gpu -p conan4869'

alias doge_cpu='~/crypto/miners/cpuminer-2.3.2/minerd --url=stratum+tcp://stratum.netcodepool.org:4093 --userpass=perrin4869.home_cpu:conan4869'
alias doge_gpu=$cgminer_settings' -o stratum+tcp://stratum.netcodepool.org:4093 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://doge.poolerino.com:3333 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://doge.poolminers.com:3333 -u perrin4869.home_gpu -p conan4869'

alias min_cpu='~/crypto/miners/cpuminer-2.3.2/minerd --url=stratum+tcp://mnc.vircurpool.com:3333 --userpass=perrin4869.home_cpu:conan4869'
alias min_gpu=$cgminer_settings' -o stratum+tcp://mnc.vircurpool.com:3333 -u perrin4869.home_gpu -p conan4869'

if [ -f ~/.git-completion.bash ]; then
. ~/.git-completion.bash

if [ -f ~/.git_ps1.bash ]; then
. ~/.git_ps1.bash
fi
fi
