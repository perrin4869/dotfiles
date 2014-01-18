#enable 256color for terminal multiplexs
alias tmux="tmux -2"

if [ -f ~/.git-completion.bash ]; then
. ~/.git-completion.bash
fi

# enable colors in less
# -R or --RAW-CONTROL-CHARS
export LESS=-R

# project opening shortcuts
alias coddress='gvim -vc "Sauce coddress"'
alias dotcore='gvim -vc "Sauce dotcore"'
alias berale='gvim -vc "Sauce berale"'

#mining software shortcut
alias start_cpuminer='~/litecoin/cpuminer-2.3.2/minerd --url=stratum+tcp://hk2.wemineltc.com:3333 --userpass=perrin4869.home_cpu:conan4869'
alias start_cpuminer_backup='~/litecoin/cpuminer-2.3.2/minerd --url=stratum+tcp://gigahash.wemineltc.com:3334 --userpass=perrin4869.home_cpu:conan4869'
# alias start_cgminer='DISPLAY=:0 GPU_MAX_ALLOC_PERCENT=100 GPU_USE_SYNC_OBJECTS=1 ~/litecoin/cgminer-829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/cgminer -I 19 -g 2 -w 256 --shaders 1564 --scrypt -o stratum+tcp://hk2.wemineltc.com:3333 -u perrin4869.home_gpu -p conan4869'
# alias start_cgminer='DISPLAY=:0 GPU_MAX_ALLOC_PERCENT=100 GPU_USE_SYNC_OBJECTS=1 ~/litecoin/cgminer-829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/cgminer -d 1 -I 8,19  --vectors 2 -g 1 --gpu-engine 500,910 --gpu-memclock 650,1375 --temp-target 80 --auto-fan -w 256 --thread-concurrency 8500 --shaders 1564 --scrypt -o stratum+tcp://gigahash.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://hk2.wemineltc.com:3333 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://usa2.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869'
alias start_cgminer='DISPLAY=:0 GPU_MAX_ALLOC_PERCENT=100 GPU_USE_SYNC_OBJECTS=1 ~/litecoin/cgminer-829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/cgminer -I 10,19  --vectors 2 -g 1 --gpu-engine 750,910 --gpu-memclock 850,1375 --temp-target 80 --auto-fan -w 128,256 --thread-concurrency 6144,8500 --shaders 960,1536 --scrypt -o stratum+tcp://gigahash.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://hk2.wemineltc.com:3333 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://usa2.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://easymining.eu:3333 -u perrin4869.home_gpu -p conan4869'
alias start_cgminer_test='DISPLAY=:0 GPU_MAX_ALLOC_PERCENT=100 GPU_USE_SYNC_OBJECTS=1 ~/litecoin/cgminer-829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/cgminer --scrypt -o stratum+tcp://gigahash.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://hk2.wemineltc.com:3333 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://usa2.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869'
alias start_doge_cgminer='GPU_MAX_ALLOC_PERCENT=100 GPU_USE_SYNC_OBJECTS=1 ~/litecoin/cgminer-829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/cgminer -I 19 -g 2 -w 256 --shaders 1564 --scrypt -o stratum+tcp://doge.poolminers.com:3333 -u perrin4869.home_gpu -p conan4869'

