#!/usr/bin/env bash

# urxvt -T 201.nobida.cn -e ssh -t 201.nobida.cn /home/amos/scripts/tstart.sh
# alacritty -t 201.nobida.cn -e ssh -t 201.nobida.cn /home/amos/scripts/tstart.sh
# st -T 201.nobida.cn -e ssh -t 201.nobida.cn /home/amos/scripts/tstart.sh

# need to installterm first
sudo ip r a 172.25.0.201 via 172.26.138.142
termite -t 201.nobida.cn -e "ssh -t 172.25.0.201 /home/amos/scripts/tstart.sh"
# gnome-terminal -t 201.nobida.cn -e "ssh -t 201.nobida.cn /home/amos/scripts/tstart.sh"
# sakura -t 201.nobida.cn -e "ssh -t 201.nobida.cn /home/amos/scripts/tstart.sh"
