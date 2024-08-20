#!/bin/sh

# Starts a tmux session and runs a process in multiple different panes,
# up to 12 panes per window in the session.
#
# The process should alway be provided by a trusted source to avoid
# security vulnerabilities.
#
# Note- processes are non-blocking- if this is called from a script,
# the script will continue while the processes are running.
#
# To detach from tmux session- prefix+d (prefix usually ctrl+b)
# To zoom in/out of a pane- prefix+z
# To choose a pane- prefix+arrow keys or prefix:choose-tree or
#     prefix+s (then arrow keys)
#
# Adapted from https://gist.github.com/mlgill/ad2693f17aaa720ef777
#
# Arguments- process [environment name] [number of threads] [session name]
#     process- process to be run, including arguments
#         each pane will also pass the following to the process:
#             --num_threads       number of threads
#             --thread            thread number for the pane
#                                   (can be used to determine which data
#                                    to process in the pane)
#     conda environment name- optional (default- base)
#     number of threads- optional (default- 40)
#     session name- optional (default- multi)
#
# Example usage:
#     ./multi_tmux.sh "python myscript.py -i infile.csv -o outfilename" my_env 20
# If package is installed with this script under 'scripts' in setup.cfg:
#     multi_tmux.sh "python myscript.py -i infile.csv -o outfilename" my_env 20
#
# Does not have a test in jj_utils package
# TODO- make conda optional, consider using all cores

echo Start time: `date +"%T"`

argc=$#              # number of arguments passed

# Set the process name
if [ "$argc" -ge 1 ]; then
    process=$1
else
    echo "Usage: $0 process [environment name] [number of threads] [session name]"
    exit 0
fi


if [ "$argc" -ge 2 ]; then
    env_name=$2
else
    env_name=base
fi


# Set the number of threads, which corresponds to the number of panes
if [ "$argc" -ge 3 ]; then
    nthread=$3
else
    nthread=40
    # Determine automatically on Mac or Linux
    # if [ `uname` = 'Darwin' ]; then
    #     nthread=`sysctl hw.ncpu | awk '{print $3}'`
    # else
    #     nthread=`nproc`
    # fi
fi

# Set the session name
if [ "$argc" -ge 4 ]; then
    sess_name=$4
else
    sess_name=multi
fi

# Test if the session exists
tmux has-session -t $sess_name 2> /dev/null
exit=$?
if [ "$exit" -eq 0 ]; then
    echo "Session $sess_name already exists. Kill it to proceed? [y/n]"
    read kill_sess
    if [ "$kill_sess" = "y" ]; then
        tmux kill-session -t $sess_name
    else
        echo "Session not created because it already exists. Exiting."
        exit 0
    fi
fi

# Create the session
tmux new-session -d -s $sess_name

windownum=1                         # for iterating
threads=$nthread

while [ "$threads" -gt 0 ]; do
    tmux new-window -t $sess_name
    tmux select-window -t $sess_name:$windownum

    if [ "$threads" -lt 12 ]; then
        windowthreads=$threads      # number of threads for the current window
    else
        windowthreads=12
    fi

    # Set the number of rows
    nrow=0
    if [ "$windowthreads" -eq 2 ]; then
        nrow=2
    elif [ "$windowthreads" -gt 2 ]; then
        # Ceiling function to round up if odd
        nrow=`echo "($windowthreads+1)/2" | bc`
    fi

    # Create the rows
    ct=$nrow
    while [ "$ct" -gt 1 ]; do
        frac=`echo "scale=2;1/$ct" | bc`
        percent=`echo "($frac * 100)/1" | bc`
        tmux select-pane -t $sess_name.0
        tmux split-window -v -p $percent
        ct=`expr $ct - 1`
    done

    # Create the columns
    if [ "$windowthreads" -gt 2 ]; then
        # Floor function to round down if odd
        ct=`echo "$windowthreads/2-1" | bc`
        while [ "$ct" -ge 0 ]; do
        tmux select-pane -t $sess_name.$ct
            tmux split-window -h -p 50
            ct=`expr $ct - 1`
        done
    fi

    windownum=`expr $windownum + 1`
    threads=`expr $threads - 12`

done

tmux kill-window -t $sess_name:0    # kills first window since it wasn't used


# Start the processes
if [ "$process" != "" ]; then
    ct=0
    while [ "$ct" -lt "$nthread" ]; do
        thread_window=`echo "($ct/12)+1" | bc`
        thread_pane=`echo "$ct%12" | bc`
        tmux select-window -t $sess_name:$thread_window
        tmux send-keys -t $sess_name.$thread_pane \
        "conda activate $env_name" Enter \
		"$process --num_threads $nthread --thread $ct" Enter
        ct=`expr $ct + 1`
    done
fi

tmux select-window -t $sess_name:1
tmux select-pane -t $sess_name.0

tmux attach-session -t $sess_name
