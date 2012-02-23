################################################################################
# shellfuncs - some useful bash functions
################################################################################

PATH=/usr/bin:/usr/sbin:/bin:/sbin

#
# Activates of deactivates verbosity of some functions in here.
#
: ${LIB_VERBOSE:=0}

################################################################################
# Default return codes as in stdlibc
################################################################################

EXIT_SUCCESS=0
EXIT_FAILURE=1

################################################################################
# The functions
################################################################################

################################################################################
# is_true:		check pseudo-boolean values
# Usage:		is_true [value]
# Arguments:	value: pseudo-boolean value to check
# Returns:		true (rc = 0) if the value equals true
#
is_true()
{
	case "$1" in
		yes|true|YES|TRUE|ja|on|ON|1)
			true
			;;
		*)
			false
			;;
	esac
}

################################################################################
# check_rc:		checks a programs return code for success for failure
# Usage:		check_rc [rc]
# Arguments:	rc: return code of a command
# Returns:		true (rc = 0) for a successful return code.
#
check_rc()
{
	case "$1" in
		0)
			true
			;;
		*)
			false
			;;
	esac
}

################################################################################
# is_decimal:	Determines if a value is decimal
# Usage:		is_decimal [value]
# Arguments:	value: the value to check
# Returns:		true (rc = 0) for a decimal value
#
is_decimal()
{
	case "$1" in
		""|*[!0-9]*)
			false
			;;
		*)
			true
			;;
	esac
}

################################################################################
# is_decimal:	Determines if a value is hex
# Usage:		is_hex [value]
# Arguments:	value: the value to check
# Returns:		true (rc = 0) for a hex value
#
is_hex()
{
	case "$1" in
		""|*[!0-9a-fA-F]*)
			false
			;;
		*)
			true
			;;
	esac
}

################################################################################
# is_octal:	Determines if a value is hex
# Usage:		is_hex [value]
# Arguments:	value: the value to check
# Returns:		true (rc = 0) for a hex value
#
is_octal()
{
	case "$1" in
		""|*[!0-7]*)
			false
			;;
		*)
			true
			;;
	esac
}

################################################################################
# log:			Logs a message to stdout or stderr
# Usage:		log [level] [message]
# Arguments:	level: the log level may be err, info or debug.
#					   err means the message is logged to stder(&2)
#					   info means the message is logged to stdout(&1)
#					   debug means the message if only logged to stdout(&1)
#				       if LIB_VERBOSE is set to a true value.
#				message: the message to log
#
log()
{
	if [ $# -lt 2 ]; then
		log err "log: not enough arguments"
	fi

	local level="$1"
	shift
	local msg="$@"

	case "$level" in
		err)
			echo "$msg" >&2
			;;
		info)
			echo "$msg"
			;;
		debug)
			is_true $LIB_VERBOSE && echo "$msg" >&2
			;;
	esac
}

################################################################################
# log_syslog:	Logs a message to syslog
#				As log tag it takes $0 which means the name of the
#				script executing log_syslog.
# Usage:		log_syslog [message]
# Arguments:	message: The message which should be logged
#
log_syslog()
{
	local msg="$@"
	local tag="${0#./}"

	logger -t "$tag" "$msg"
}

################################################################################
# die:			Logs a message and exits the program with a defined exit code
# Usage:		die [rc] [message]
# Arguments:	rc: the exit code to exit the program with
#				message: the message to log to stderr(&2)
#
die()
{
	if [ $# -lt 2 ]; then
		log err "die: not enough arguments"
	fi

	local rc="$1"
	shift
	local msg="$@"

	log err "$msg"

	exit $rc
}

################################################################################
# exec_or_die:	Executes a command and exits the program if the command failed
# Usage:		exec_or_die [command args ...]
# Arguments:	command args ...: the command with its arguments to execute.
#								  does not have to be quoted.
#
exec_or_die()
{
        local cmd="$@"
        local rc

        log debug "exec_or_die: $cmd"

        ( $cmd )
        rc=$?

        if ! check_rc $rc; then
                die $rc "Command $cmd failed with exit code: $rc"
        else
                return $rc
        fi
}

################################################################################
# array_push:	Pushes a value to an array
# Usage:		array_push [array] [value]
# Arguments:	array: the array where the values should be pushed to
#				value: the value that should be pushed
#
array_push()
{
	local array="$1"
	shift

	for value in "$@"; do
		eval "$array[\${#$array[@]}]=\$value"
	done
}

################################################################################
# array_get:	Gets an value from an array an sets it to a var
# Usage:		array_get [array] [destination] [index]
# Arguments:	array: the array
#				destination: the destination var
#				indext: the index of the var in the array
#
array_get()
{
	local src="$1"
	local dst="$2"
	local idx="$3"

	eval "$dst=\${$src[$idx]}"
}

################################################################################
# array_get_first:	Gets the first element of an array
# Usage:			array_get_first [array] [destination]
# Arguments:		array: the array where to get the value from
#					value: the value that should be pushed
#
array_get_first()
{
	local src="$1"
	local dst="$2"

	array_get $src $dst 0
}

################################################################################
# array_get_last:	Gets the last element of an array
# Usage:			array_get_last [array] [destination]
# Arguments:		array: the array where to get the value from
#					value: the value that should be pushed
#
array_get_last()
{
	local src="$1"
	local dst="$2"

	array_get $src $dst -1
}

################################################################################
# array_copy:	Copies an array to another
# Usage:		array_copy [array] [destination]
# Arguments:	array: the source array
#				destination: the destination array
#
array_copy()
{
	local src="$1"
	local dst="$2"

	eval "$dst=(\"\${$src[@]}\")"
}

################################################################################
# array_set:	Sets the value of an array
# Usage:		array_set [array] [index] [value]
# Arguments:	array: the array
#				index: the index of the element
#				value: the value that should be set

array_set()
{
	local array="$1"
	local idx="$2"
	local value="$3"

	eval "$array[$idx]=\$value"
}

################################################################################
# array_reset:	Resets an array to zero or to the defined elements
# Usage:		array_reset [array] {[values] ...}
# Arguments:	array: the array that sould be resetted
#				values...: optional values with which the array should
#						   be re-initialized
#
array_reset()
{
	local array="$1"
	shift

	eval "$array=(\"\$@\")"
}
