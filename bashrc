#enable 256color for terminal multiplexs
alias tmux="tmux -2"

if [ -f ~/.git-completion.bash ]; then
. ~/.git-completion.bash

#  Customize BASH PS1 prompt to show current GIT repository and branch.
#  by Mike Stewart - http://MediaDoneRight.com

#  SETUP CONSTANTS
#  Bunch-o-predefined colors.  Makes reading code easier than escape sequences.
#  I don't remember where I found this.  o_O

# Reset
Color_Off="\[\033[0m\]"       # Text Reset

# Regular Colors
Black="\[\033[0;30m\]"        # Black
Red="\[\033[0;31m\]"          # Red
Green="\[\033[0;32m\]"        # Green
Yellow="\[\033[0;33m\]"       # Yellow
Blue="\[\033[0;34m\]"         # Blue
Purple="\[\033[0;35m\]"       # Purple
Cyan="\[\033[0;36m\]"         # Cyan
White="\[\033[0;37m\]"        # White

# Bold
BBlack="\[\033[1;30m\]"       # Black
BRed="\[\033[1;31m\]"         # Red
BGreen="\[\033[1;32m\]"       # Green
BYellow="\[\033[1;33m\]"      # Yellow
BBlue="\[\033[1;34m\]"        # Blue
BPurple="\[\033[1;35m\]"      # Purple
BCyan="\[\033[1;36m\]"        # Cyan
BWhite="\[\033[1;37m\]"       # White

# Underline
UBlack="\[\033[4;30m\]"       # Black
URed="\[\033[4;31m\]"         # Red
UGreen="\[\033[4;32m\]"       # Green
UYellow="\[\033[4;33m\]"      # Yellow
UBlue="\[\033[4;34m\]"        # Blue
UPurple="\[\033[4;35m\]"      # Purple
UCyan="\[\033[4;36m\]"        # Cyan
UWhite="\[\033[4;37m\]"       # White

# Background
On_Black="\[\033[40m\]"       # Black
On_Red="\[\033[41m\]"         # Red
On_Green="\[\033[42m\]"       # Green
On_Yellow="\[\033[43m\]"      # Yellow
On_Blue="\[\033[44m\]"        # Blue
On_Purple="\[\033[45m\]"      # Purple
On_Cyan="\[\033[46m\]"        # Cyan
On_White="\[\033[47m\]"       # White

# High Intensty
IBlack="\[\033[0;90m\]"       # Black
IRed="\[\033[0;91m\]"         # Red
IGreen="\[\033[0;92m\]"       # Green
IYellow="\[\033[0;93m\]"      # Yellow
IBlue="\[\033[0;94m\]"        # Blue
IPurple="\[\033[0;95m\]"      # Purple
ICyan="\[\033[0;96m\]"        # Cyan
IWhite="\[\033[0;97m\]"       # White

# Bold High Intensty
BIBlack="\[\033[1;90m\]"      # Black
BIRed="\[\033[1;91m\]"        # Red
BIGreen="\[\033[1;92m\]"      # Green
BIYellow="\[\033[1;93m\]"     # Yellow
BIBlue="\[\033[1;94m\]"       # Blue
BIPurple="\[\033[1;95m\]"     # Purple
BICyan="\[\033[1;96m\]"       # Cyan
BIWhite="\[\033[1;97m\]"      # White

# High Intensty backgrounds
On_IBlack="\[\033[0;100m\]"   # Black
On_IRed="\[\033[0;101m\]"     # Red
On_IGreen="\[\033[0;102m\]"   # Green
On_IYellow="\[\033[0;103m\]"  # Yellow
On_IBlue="\[\033[0;104m\]"    # Blue
On_IPurple="\[\033[10;95m\]"  # Purple
On_ICyan="\[\033[0;106m\]"    # Cyan
On_IWhite="\[\033[0;107m\]"   # White

# Various variables you might want for your PS1 prompt instead
Time12h="\T"
Time12a="\@"
PathShort="\w"
PathFull="\W"
NewLine="\n"
Jobs="\j"


# This PS1 snippet was adopted from code for MAC/BSD I saw from: http://allancraig.net/index.php?option=com_content&view=article&id=108:ps1-export-command-for-git&catid=45:general&Itemid=96
# I tweaked it to work on UBUNTU 11.04 & 11.10 plus made it mo' better

export PS1=$BICyan$Time12h$Color_Off'$(git branch &>/dev/null;\
if [ $? -eq 0 ]; then \
  echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; \
  if [ "$?" -eq "0" ]; then \
    # @4 - Clean repository - nothing to commit
    echo "'$Green'"$(__git_ps1 " (%s)"); \
  else \
    # @5 - Changes to working tree
    echo "'$IRed'"$(__git_ps1 " {%s}"); \
  fi) '$BYellow$PathShort$Color_Off'\$ "; \
else \
  # @2 - Prompt when not in GIT repo
  echo " '$BIYellow$PathShort$Color_Off'\$ "; \
fi)'
fi

# enable colors in less
# -R or --RAW-CONTROL-CHARS
export LESS=-R

# project opening shortcuts
alias coddress='gvim -vc "Sauce coddress"'
alias dotcore='gvim -vc "Sauce dotcore"'
alias berale='gvim -vc "Sauce berale"'

#mining software shortcut
alias start_cpuminer='~/crypto/miners/cpuminer-2.3.2/minerd --url=stratum+tcp://hk2.wemineltc.com:3333 --userpass=perrin4869.home_cpu:conan4869'
alias start_cpuminer_backup='~/crypto/miners/cpuminer-2.3.2/minerd --url=stratum+tcp://gigahash.wemineltc.com:3334 --userpass=perrin4869.home_cpu:conan4869'
# alias start_cgminer='DISPLAY=:0 GPU_MAX_ALLOC_PERCENT=100 GPU_USE_SYNC_OBJECTS=1 ~/litecoin/cgminer-829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/cgminer -I 19 -g 2 -w 256 --shaders 1564 --scrypt -o stratum+tcp://hk2.wemineltc.com:3333 -u perrin4869.home_gpu -p conan4869'
# alias start_cgminer='DISPLAY=:0 GPU_MAX_ALLOC_PERCENT=100 GPU_USE_SYNC_OBJECTS=1 ~/litecoin/cgminer-829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/cgminer -d 1 -I 8,19  --vectors 2 -g 1 --gpu-engine 500,910 --gpu-memclock 650,1375 --temp-target 80 --auto-fan -w 256 --thread-concurrency 8500 --shaders 1564 --scrypt -o stratum+tcp://gigahash.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://hk2.wemineltc.com:3333 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://usa2.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869'
alias start_cgminer='DISPLAY=:0 GPU_MAX_ALLOC_PERCENT=100 GPU_USE_SYNC_OBJECTS=1 ~/crypto/miners/cgminer-829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/cgminer -I 10,19  --vectors 2 -g 1 --gpu-engine 750,910 --gpu-memclock 850,1375 --temp-target 80 --auto-fan -w 128,256 --thread-concurrency 6144,8500 --shaders 960,1536 --scrypt -o stratum+tcp://gigahash.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://hk2.wemineltc.com:3333 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://usa2.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://easymining.eu:3333 -u perrin4869.home_gpu -p conan4869'
alias start_cgminer_test='DISPLAY=:0 GPU_MAX_ALLOC_PERCENT=100 GPU_USE_SYNC_OBJECTS=1 ~/crypto/miners/cgminer-829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/cgminer --scrypt -o stratum+tcp://gigahash.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://hk2.wemineltc.com:3333 -u perrin4869.home_gpu -p conan4869 --failover-only -o stratum+tcp://usa2.wemineltc.com:3334 -u perrin4869.home_gpu -p conan4869'
alias start_doge_cgminer='GPU_MAX_ALLOC_PERCENT=100 GPU_USE_SYNC_OBJECTS=1 ~/crypto/miners/cgminer-829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/cgminer -I 19 -g 2 -w 256 --shaders 1564 --scrypt -o stratum+tcp://doge.poolminers.com:3333 -u perrin4869.home_gpu -p conan4869'

