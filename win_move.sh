#!/bin/bash
# win_move.sh

# set -x

#-----------------------------------------------------------------
# Constants
#-----------------------------------------------------------------
# Hotkeys
COMPIZ_PUT_NEXT_OUTPUT_HKEY="alt+u"
MOVE_UP_HKEY="super+alt+Up"
MOVE_DOWN_HKEY="super+alt+Down"

#-----------------------------------------------------------------
# Monitor geometries
# Notes:
# * These assume two monitors stacked vertically with a default 
#   size bar at top and bottom of combined screen area
# * WIN_SZ_ constants format: <width>,<height>
# * wmctrl is very buggy when setting window geometry, thus the 
#   dimensions are tweaked for what generally works, and the size 
#   set may not be the actual result
#-----------------------------------------------------------------

MON_WIDTH=1280
MON_HEIGHT=1024

WIN_SZ_FULL=$MON_WIDTH,$MON_HEIGHT

# wmctrl is too buggy to use one constant here (640,1024)
WIN_SZ_SIDE_BY_SIDE_L=640,1024
WIN_SZ_SIDE_BY_SIDE_R=642,1024

WIN_POS_MT_TL=2,102
WIN_POS_MT_TR=1286,102
WIN_POS_MB_TL=1286,2104
WIN_POS_MB_TR=2,2104

X_POS_LEFT=0
X_POS_MID=640
Y_POS_MT_TOP=0
Y_POS_MB_TOP=1024

#-----------------------------------------------------------------
# Window positions (full geometry)
# Notes:
# * These are of the format "<x>,<y>,<width>,<height>"
# * These are numbered left to right, top to bottom
#-----------------------------------------------------------------
# Full monitor positions (total of 2 positions)
WIN_1_BY_1_POS_1="$X_POS_LEFT $Y_POS_MT_TOP $WIN_SZ_FULL"
WIN_1_BY_1_POS_2="$X_POS_LEFT $Y_POS_MB_TOP $WIN_SZ_FULL"

# Side by side half monitor positions (total of 4 positions)
WIN_1_BY_2_POS_1="$X_POS_LEFT $Y_POS_MT_TOP $WIN_SZ_SIDE_BY_SIDE_L"
WIN_1_BY_2_POS_2="$X_POS_MID  $Y_POS_MT_TOP $WIN_SZ_SIDE_BY_SIDE_R"
WIN_1_BY_2_POS_3="$X_POS_LEFT $Y_POS_MB_TOP $WIN_SZ_SIDE_BY_SIDE_L"
WIN_1_BY_2_POS_4="$X_POS_MID  $Y_POS_MB_TOP $WIN_SZ_SIDE_BY_SIDE_R"

#-----------------------------------------------------------------
# Functions
#-----------------------------------------------------------------
function usage()        {   echo "usage: $0 <up|down|position(number)>"; }

# Generic move function, takes <x>, <y> and "<width>,<height>" arguments (total of 3 args)
# Note: repeated wmctrl command is due to buggy wmctrl behavior where pixel dimensions are not set exactly
function move_win()     {   wmctrl -r ":ACTIVE:" -e 0,$1,$2,$3; wmctrl -r ":ACTIVE:" -e 0,$1,$2,$3; }

# Get active window information (including geometry), ignore leading zeros of window ID
# Note: Begin by getting the active window ID without leading "0x"
function get_active_win_info \
                        {   echo $(wmctrl -lG | grep ^0x0.*$(xprop -root _NET_ACTIVE_WINDOW | awk '{ print $NF }' | sed 's/0x//')); }

function maximize_win() {   wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz; }
function unmaximize_win() \
                        {   wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz; }

# Remap up/down hotkeys to compiz hotkey
# Note: required releasing hotkeys which were pressed in order for system to register the generated compiz hotkey (ie mitigate collision)
function move_up()      {  xdotool keyup "$MOVE_UP_HKEY"; xdotool key "$COMPIZ_PUT_NEXT_OUTPUT_HKEY"; xdotool keydown "$MOVE_UP_HKEY"; }
function move_down()    {  xdotool keyup "$MOVE_DOWN_HKEY"; xdotool key "$COMPIZ_PUT_NEXT_OUTPUT_HKEY"; xdotool keydown "$MOVE_DOWN_HKEY"; }


# Get active window settings
WIN_INFO=`get_active_win_info`
X_CUR=`echo $WIN_INFO | awk 'END{print $3}'`
Y_CUR=`echo $WIN_INFO | awk 'END{print $4}'`
WIDTH_HEIGHT=`echo $WIN_INFO | awk 'END{print $5,$6}' | sed 's/ /,/'`

# echo "WIN_INFO: $WIN_INFO"
echo "X_CUR: $X_CUR"
echo "Y_CUR: $Y_CUR"
echo "WIDTH_HEIGHT: $WIDTH_HEIGHT"

# Exit early if testing
if [[ $1 == '-t' ]]; then
    exit
fi

# Error when no parameter is passed
if [[ -z $1 ]]; then
    usage
    exit
fi

# Unmaximize the window if position number is passed
if [[ $1 =~ [0-9] ]]; then
    unmaximize_win
fi

case "$1" in

'up')
    move_up
    ;;

'down')
    move_down
    ;;

'1')
    # Set window to bottom monitor on left half
    move_win $WIN_1_BY_2_POS_3
    ;;

'2')
    # Set window maximized to bottom monitor 
    move_win $WIN_1_BY_1_POS_2
    maximize_win
    ;;

'3')
    # Set window to bottom monitor on right half
    move_win $WIN_1_BY_2_POS_4
    ;;

'7')
    # Set window to top monitor on left half
    move_win $WIN_1_BY_2_POS_1
    ;;

'8')
    # Set window maximized to top monitor 
    move_win $WIN_1_BY_1_POS_1
    maximize_win
    ;;

'9')
    # Set window to top monitor on right half
    move_win $WIN_1_BY_2_POS_2
    ;;

*)  usage
    ;;
esac


echo "X_NEW: $X_NEW"
echo "Y_NEW: $Y_NEW"
