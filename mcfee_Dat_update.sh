#!/bin/sh
# (c) 2008 McAfee, Inc. All Rights Reserved.
# required programs: unzip, ftp, awk, echo, cut, ls, printf
### defaults: do not modify
unset md5checker leave_files debug
#============================================================
### change these variables to match your information
# Set the following to your own e-mail address
EMAIL_ADDRESS="pulishettix.venkatesh@intel.com"
### change these variables to match your environment
# install_dir must be a directory and writable
install_dir=`dirname "/usr/local/uvscan"`
# tmp_dir must be a directory and writable
tmp_dir="/tmp/uvscan"
# optional: this prg is responsible for calculating the md5 for a file
md5checker="md5sum"
### set your preferences
# set to non-empty to leave downloaded files after the update is done
#leave_files="true"
# show debug messages (set to non-empty to enable)
debug=yes
# these variables are normally best left unmodified
UVSCAN_EXE="uvscan"
UVSCAN_SWITCHES=""
#============================================================
Cleanup()
{
 if [ -z "$leave_files" ] ; then
    for f in "$avvdat_ini" "$filename2" ; do
       [ -n "$f" -a -e "$f" ] && rm -f "$f"
    done
 fi
}
exit_error()
{
     [ -n "$1" ] && printf "$prgname: ERROR: $1\n"
      Cleanup ; exit 1
}
print_debug()
{
 [ -n "$debug" ] && printf "$prgname: [debug] $@\n"
}
GetCurrentDATVersion()
{
    dirname=`dirname "$1"`
    uvscan_bin=`basename "$1"`

    output=`(cd "$dirname"; "$uvscan_bin" $2 --version )`
    [ $? -eq 0 ] || return 1

    lversion=`printf "$output\n" | grep "Dat set version:" |cut -d' ' -f4 | cut -c1-`
    printf "${lversion}\n"

    return 0
}
DownloadFile()
{
  [ "$3" = "bin" -o "$3" = "ascii" ] || return 1
  dtype="$3"
  export http_proxy=http://proxy-us.intel.com:911
  cd $4
  rm -f $2
  `wget http://update.nai.com/products/commonupdater/$2`
  chmod +x $2
}
ValidateFile()
{
 # Check the file size matches what we expect...
 size=`ls -l "$1" | awk ' { print $5 } '`
 [ -n "$size" -a "$size" = "$2" ] || return 1

}
Update_ZIP()
{
   unset flist
   for file in $3 ; do
        fname=`printf "$file\n" | awk -F':' ' { print $1 } '`
        flist="$flist $fname"
   done
# Backup any files about to be updated...
    [ ! -d "backup" ] && mkdir backup 2>/dev/null
    [ -d "backup" ] && cp $flist "backup" 2>/dev/null
    #rm -f $flist
 # Update the DAT files.
     print_debug "uncompressing '$2'..."
     unzip -o -d $1 $2 $flist >/dev/null || return 1
     for file in $3 ; do
         fname=`printf "$file\n" | awk -F':' ' { print $1 } '`
         permissions=`printf "$file\n" | awk -F':' ' { print $NF } '`
         chmod "$permissions" "$1/$fname"
     done
     return 0
}
# globals
prgname=`basename "/usr/local/uvscan/"`
unset perform_update avvdat_ini download
# sanity checks
[ -d "$tmp_dir" ] || mkdir -p "$tmp_dir" 2>/dev/null
[ -d "$tmp_dir" ] || exit_error "directory '$tmp_dir' does not exist."
[ -x "$install_dir/$UVSCAN_EXE" ] \
   || exit_error "could not find uvscan executable"
DownloadFile "/products/commonupdater" "avvdat.ini" "ascii" "$tmp_dir" \
    || exit_error "downloading update.ini"
ini_section="avvdat.ini"
file_list="avvscan.dat:444 avvnames.dat:444 avvclean.dat:444"
# Get the version of the installed DATs...
current_version="`GetCurrentDATVersion "$install_dir/$UVSCAN_EXE"`"
ini_DATVersion=`grep DATVersion avvdat.ini -m 1 | awk '{ print $1}' | cut -d "=" -f2`
ini_FileSize=`grep FileSize avvdat.ini -m 1 | awk '{ print $1}' | cut -d "=" -f2`
echo "the current_version": $current_version
echo "the new_version: " $ini_DATVersion
[  "(" "$current_version" -lt "$ini_DATVersion" ")"  ] && perform_update="yes"
if [ -n "$perform_update" ] ; then
  printf "$prgname: Performing an update ($current_version -> $ini_DATVersion)\n"
  # Download the dat files.. 
  filename=`awk -F"=" '$2 ~ /avvdat.*zip/ { print $2 } ' avvdat.ini `
  filename2="$(echo -e "${filename}" | tr -d '[:space:]')"
  echo "File is:" $filename2
  rm -f $filename2
 `wget http://update.nai.com/products/commonupdater/$filename2`
  download="$tmp_dir/$filename2"
  # Did we get the dat update file?
 [ -r "$download" ] || exit_error "unable to get $file_name file"
 ValidateFile "$download" "$ini_FileSize" "$md5" \
  || exit_error "DAT update failed - File validation failed"
 Update_ZIP "$install_dir" "$download" "$file_list" \
  || exit_error "updating DATs from file '$download'"
 if [ "$current_version" == "$ini_DATVersion"]
 then printf "$prgname: DAT update succeeded $current_version -> $ini_DATVersion\n"
 else exit_error "DAT update failed - installed version different than expected\n"
 fi
 else
   printf "$prgname: DAT already up to date ($current_version)\n"
fi
Cleanup ; exit 0




































































