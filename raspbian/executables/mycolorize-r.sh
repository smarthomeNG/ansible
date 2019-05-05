#!/bin/bash
#
# Simple colorize for bash by means of sed
#
# Copyright 2008-2015 by Andreas Schamanek <andreas@schamanek.net>
# GPL licensed (see end of file) * Use at your own risk!
#
# Usage examples:
#   tail -f somemaillog | mycolorize white '^From: .*' bell
#   tail -f somemaillog | mycolorize white '^From: \/.*' green 'Folder: .*'
#   tail -f somemaillog | mycolorize --unbuffered white '^From: .*'
#
# Notes:
#   Regular expressions need to be suitable for _sed --regexp-extended_
#   Slashes / need no escaping (we use ^A as delimiter).
#   \/ splits the coloring (similar to procmailrc. Matches behind get color.
#   Even "white '(for|to) \/(her|him).*$'" works :) Surprisingly ;)
#   To color the string '\/' use the regular expression '\\()/'.
#   If the 1st argument is -u or --unbuffered, _sed_ will be run so.

# For the colors see tput(1) and terminfo(5), or e.g.
# https://wiki.archlinux.org/index.php/Color_Bash_Prompt
# and http://stackoverflow.com/a/20983251/196133

bold=$(tput bold)                         # make colors bold/bright
#normal=$(tput sgr0)                      # normal text
normal=$'\e[0m'                           # (works better sometimes)

red=$(tput setaf 1)                # bright red text
green=$(tput setaf 2)                     # dim green text
fawn=$(tput setaf 3); beige="$fawn"       # dark yellow text
yellow="$fawn"                       # bright yellow text
darkblue=$(tput setaf 4)                  # dim blue text
blue="$darkblue"                     # bright blue text
purple=$(tput setaf 5); magenta="$purple" # magenta text
pink="$purple"                       # bright magenta text
darkcyan=$(tput setaf 6)                  # dim cyan text
cyan="$darkcyan"                     # bright cyan text
gray=$(tput setaf 7)                      # dim white text
darkgray=$(tput setaf 0)           # bold black = dark gray text
white="$gray"                        # bright white text

bell=$(tput bel)                          # bell/beep

# Make output unbuffered? (Pass argument -u|--unbuffered to _sed_.)
if [ "/$1/" = '/-u/' -o "/$1/" = '/--unbuffered/' ] ; then
   UNBUFFERED='-u'; shift
else
   UNBUFFERED=""
fi

# produce separator character ^A (for _sed_)
A=$(echo | tr '\012' '\001')

# compile all rules given at command line to 1 set of rules for SED
while [ "/$1/" != '//' ] ; do
  c1=''; re='';  beep=''
  c1=$1 ; re="$2" ; shift 2 || break
  # if a beep is requested in the optional 3rd parameter set $beep
  [ "/$1/" != '//' ] && [[ ( "$1" = 'bell' || "$1" = 'beep' ) ]] \
    && beep=$bell && shift
  # if the regular expression includes \/ we split the substitution
  if [ "/${re/*\\\/*/}/" = '//' ] ; then
     # we need to count "("s before the \/ (=$left)
     left="${re%\\/*}"; leftlength=${#left}
     # first we count "\("
     dummy=${left//\\(}; escdgroups=$(( (leftlength-${#dummy})/2 ))
     # now "(" (and we add 2 for the groups used for ($re) in $sedrules)
     dummy=${left//(}; groupcnt=$((leftlength-${#dummy}-escdgroups+2))
     # replace \/ with )( so below we get (left-re)(right-re)
     re="${re/\\\//)(}"
     sedrules="$sedrules;s$A($re)$A\1${!c1}\\$groupcnt$beep$normal${A}g"
  else
     sedrules="$sedrules;s$A($re)$A${!c1}\1$beep$normal${A}g"
  fi
  # limit parsing of arguments
  (( y++ && y>888 )) && { echo "$0: too many arguments" >&2; exit 1; }
done

# call sed to do the main job
sed $UNBUFFERED --regexp-extended -e "$sedrules"

exit

# License
#
# This script is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this script; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA  02111-1307  USA
