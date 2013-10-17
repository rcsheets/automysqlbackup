echo "DO NEVER PLUG THIS SCRIPT AS DOWNLOADED INTO AUTOMYSQLBACKUP OR JUST EXECUTE IT! MAKE SURE YOU KNOW WHAT YOU ARE DOING AND HAVE COMMENTED OUT OR REMOVED EVERYTHING YOU DON'T NEED!"
# remove the following line after you have read and understood the line above!
exit 1 # exit with failure to make sure that those just plugging this script in, don't screw up their system ...


# If you just want to try stuff out before you plug it into automysqlbackup, source the config files, so that you have access to the variables.
# Note: The default values don't work if you only source config files, since the default values are in the script itself.
source /etc/automysqlbackup/automysqlbackup.conf
# source /etc/automysqlbackup/myserver.conf


# available variables:

# strings, i.e. character sequences
echo "$CONFIG_mysql_dump_username"
echo "$CONFIG_mysql_dump_password"
echo "$CONFIG_mysql_dump_host"
echo "$CONFIG_backup_dir"
echo "$CONFIG_mysql_dump_port"
echo "$CONFIG_mysql_dump_commcomp"
echo "$CONFIG_mysql_dump_usessl"
echo "$CONFIG_mysql_dump_socket"
echo "$CONFIG_mysql_dump_max_allowed_packet"
echo "$CONFIG_mysql_dump_single_transaction"
echo "$CONFIG_mysql_dump_master_data"
echo "$CONFIG_mysql_dump_full_schema"
echo "$CONFIG_mysql_dump_create_database"
echo "$CONFIG_mysql_dump_use_separate_dirs"
echo "$CONFIG_mysql_dump_compression"
echo "$CONFIG_mysql_dump_latest"
echo "$CONFIG_mailcontent"
echo "$CONFIG_mail_maxattsize"
echo "$CONFIG_mail_address"
echo "$CONFIG_encrypt"
echo "$CONFIG_encrypt_password"
echo "$CONFIG_backup_local_files"
echo "$CONFIG_prebackup"
echo "$CONFIG_postbackup"
echo "$CONFIG_dryrun"

## comparison
if [[ "x$CONFIG_mysql_dump_username" = "xTestuser" ]]; then
  echo "Username is Testuser."
  # if you want it to do nothing but still work for the moment, use can just put in one :
else # the else part is optional, but the first part always has to be non-empty, see note above
  echo "Username is not Testuser."
fi
# you can substitute each newline with a ; and vice versa

# or the short version
[[ "x$CONFIG_mysql_dump_username" = "xTestuser" ]] && echo "Username is Testuser."	# the part after && is executed if the first part is true
[[ "x$CONFIG_mysql_dump_username" = "xTestuser" ]] || echo "Username is not Testuser."	# the part after || is executed if the first part is false
# you can always combine multiple commands with {}, for example
[[ "x$CONFIG_mysql_dump_username" = "xTestuser" ]] && { echo "Username is Testuser."; echo "second command"; }
# Note the space after { and before }, which is necessary for it to work; the same is true for [[ ]], [], ...
# There ALWAYS has to be a command-closing ; before the } if they are not on separate lines!
# The x in "x$something" is necessary, so that if $something is empty, the comparison doesn't return true even if they don't match.
# Of course we have to account for the additional x in the string we want to test against.
# Always put variables inside double quotes, i.e. "$something", so that special characters inside the variable are properly escaped and don't
# create unexpected behavior.
# If you put something inside single quotes, it is taken literally, meaning that echo '$something' will really print $something
# There are a quite a few special characters, that will be interpreted when put inside "", so if you have something like a password, put it
# inside single quotes; note: the only character that can then make trouble is ' itself; for it to work, you have to substitute every occurence of '
# inside your password with '\'', meaning that with the first ', you leave the '' environment, with the second you actually want ', not the starting
# character of the environment, therefore you escape it with \, and then you open the environment again with ' to be able to proceed. Of course, if
# ' appears in your password as first or last character, you have to drop the closing or opening ' in the substitution, respectively.


# arrays
echo "${CONFIG_db_names[@]}"
echo "${CONFIG_db_month_names[@]}"
echo "${CONFIG_db_exclude[@]}"
echo "${CONFIG_table_exclude[@]}"

# You can always write ${something} instead of $something. The former makes sure, that the variables name isn't mixed with anything that comes after
# the variable name, i.e. echo "$somethingtest" would lead to bash searching for a variable $somethingtest, that doesn't exist. The right way to do it
# is to use {}, i.e. echo "${something}test", which now works.

# You always have to put arrays, which look like ${array[@]} inside double quotes, otherwise they loose any and all special meaning.

# Looping through the entries
for i in "${CONFIG_db_names[@]}"; do
  echo "$i"
done

# numbers (bash treats them like strings)
echo "$CONFIG_do_monthly"
echo "$CONFIG_do_weekly"
echo "$CONFIG_rotation_daily"
echo "$CONFIG_rotation_weekly"
echo "$CONFIG_rotation_monthly"

## comparison

if (( "$CONFIG_do_monthly" == 3 )); then
  echo "Create backup on third day of the month."
fi
# inside (( )) you have to use == for comparison!
if (( 4 > 3 )); then
  echo "4 is greather than 3"
fi
if (( 3 < 4 )); then
  echo "3 is smaller than 4"
fi


##############################################################################################

# Now let's take a look at some bash programs, that can help you achieve your goal

# find all files in $CONFIG_backup_dir/daily that are older than 60 minutes:
find "${CONFIG_backup_dir}/daily" -type f -mmin 60
# -type f: only search for files, not directories, symlinks, etc.
# -mmin #: the content of the file was changed # minutes ago

# alternatively, you can also use days, i.e. find all files in $CONFIG_backup_dir/daily that are older than 2 days
find "${CONFIG_backup_dir}/daily" -type f -mtime 2

# WARNING: Don't use xargs or some stuff like that to parse the found results! It will lead to disaster! Use -exec instead:
find "${CONFIG_backup_dir}/daily" -type f -mtime 2 -exec ls {} \;
# this will execute the command ls on all files ... {} can be put anywhere inside the command that follows exec
# the command has to be closed with space and \;

# remove all files older than two days
find "${CONFIG_backup_dir}/daily" -type f -mtime 2 -exec rm {} \;

# move all files older than two days to another folder
find "${CONFIG_backup_dir}/daily" -type f -mtime 2 -exec mv {} /home/user/some/folder/ \;
# WARNING: Don't forget the final /, otherwise it will overwrite the directory folder with the file, which on most systems,
# will leave a mess behind and data loss.

# copy all files older than two days to another folder
find "${CONFIG_backup_dir}/daily" -type f -mtime 2 -exec cp {} /home/user/some/folder/ \;

# copy all files older than two days to another folder, but only create a hardlink, i.e. create a file that points to the
# physical address of the file that shall be copied; now both files are the really the same one, just that they have two
# different locations in the filesystem and perhaps different names - the content always IS the same!

# create a temporary directory in folder /tmp with the name tmp.XXXXXX, where the X are replaced by random characters
tmpname=$(mktemp -d /tmp/tmp.XXXXXX)
find "${CONFIG_backup_dir}/daily" -type f -mtime 2 -exec cp -l {} "${tmpname}"/ \;
# Now let's tar them - we are using bzip2 compression, i.e. the parameter -j.
# We are using mktemp again, to ensure, that we get a filename (this time just a file, i.e. without the option -d), that
# doesn't already exist.
tarname=$(mktemp /tmp/tmp.XXXXXX)
tar -cjf "${tarname}" "${tmpname}"
# let's ftp upload it
host='www.*.com'
user='********'
passwd='*******'

ftp -n -v "$host" << EOT
ascii
user "$user" "$passwd"
prompt
cd foo/bar
put "${tarname}"
mkdir linux
cd linux
put "${tarname}"
bye
EOT
sleep 12

# this will connect to host $HOST, login as user $USER with password $PASSWD
# cd into the remote foo/bar directory
# upload our archive file "${tarname}"
# create the directory linux on the remote server in the directory foo/bar
# cd into this directory
# upload our archive file "${tarname}"
# quit the remote session


# rsync the stuff
rsync -a --delete "${CONFIG_backup_dir}"/ /mnt/backup
# The slash / at the end of the source directory (first of the directory arguments) is important. If it is omitted, the source directory
# is created in the remote directory, otherwise only it's subdirectories and files are copied directly into the remote directory.
# If you specify MODULES, this differentiation is not necessary, since then only the subdirectories and files are copied directly to the target MODULE.
# -a: archive mode; equals -rlptgoD (no -H,-A,-X)
# -p: preserve permissions
# -t: preserve modification times
# -g: preserve group
# -o: preserve owner
# -l: copy symlinks as symlinks
# -D: same as --devices --specials
# --devices: preserve device files (super-user only)
# --specials: preserve special files
# -H: preserve hard links
# -A: preserve ACLs (implies -p)
# -X: preserve extended attributes
# --delete: delete extraneous files from dest dirs
# -z: compress file data during the transfer
# -v: increase verbosity
# -b: make backups (see --suffix & --backup-dir)
# --backup-dir=DIR	make backups into hierarchy based in DIR
# --suffix=SUFFIX	backup suffix (default ~ w/o --backup-dir)
# -u, --update		skip files that are newer on the receiver
# -e, --rsh=COMMAND	specify the remote shell to use

rsync -av -e "ssh -l ssh-user" rsync-user@host::module /dest
# The "ssh-user" will be used at the ssh level; the "rsync-user" will be used to log-in to the "module".
# A MODULE is like a smb share. It's entry in the rsyncd.conf looks like:
# [MODULE_NAME]
# path = /volume1/PATH/FOLDER
# read only = no
# hosts allow = 192.168.35.32
# hosts deny = *

# For example all these work:
rsync -av host:file1 :file2 host:file{3,4} /dest/
rsync -av host::modname/file{1,2} host::modname/file3 /dest/
rsync -av host::modname/file1 ::modname/file{3,4}


# Removing of date time information from files - copied from the script.
remove_datetimeinfo () {
  mv "$1" "$(echo $1 | sed -re 's/_(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|[0-9]{1,2})_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}h[0-9]{2}m(\.sql(\.gz|\.gzip2){0,1})/\2/g')"
}
export -f remove_datetimeinfo
[[ "${CONFIG_mysql_dump_latest_clean_filenames}" = 'yes' ]] && find "${CONFIG_backup_dir}"/latest/ -type f -exec bash -c 'remove_datetimeinfo "$@"' -- {} \;



# If something doesn't work: man script; then record what you want to do; you can get out of the running of script with exit.