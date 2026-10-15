#!/bin/bash
java "$([[ -f user_jvm_args.txt ]] && printf %s "@user_jvm_args.txt")" -Xms128M -Xmx{{SERVER_MEMORY}}M -Dterminal.jline=false -Dterminal.ansi=true "$([[ ! -f unix_args.txt ]] && printf %s "-jar `cat .serverjar`" || printf %s "@unix_args.txt")"
