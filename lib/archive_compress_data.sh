# Copyright (C) 2020 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the “License”);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################
# Archive and compress files and directories.
# Globals:
#   OPERATING_SYSTEM
#   TEMP_DATA_DIR
#   UAC_DIR
# Requires:
#   None
# Arguments:
#   $1: file containing the list of files to be archived and compressed
#   $2: destination file
# Outputs:
#   None
# Exit Status:
#   Exit with status 0 on success.
#   Exit with status greater than 0 if errors occur.
###############################################################################
archive_compress_data()
{
  ac_source_file="${1:-}"
  ac_destination_file="${2:-}"

  # exit if source file does not exist
  if [ ! -f "${ac_source_file}" ]; then
    printf %b "archive compress data: No such file or directory: \
'${ac_source_file}'\n" >&2
    return 2
  fi

  case "${OPERATING_SYSTEM}" in
    "aix")
      tar -L "${ac_source_file}" -cf - | gzip >"${ac_destination_file}"
      ;;
    "freebsd"|"netbsd"|"netscaler"|"openbsd")
      tar -I "${ac_source_file}" -cf - | gzip >"${ac_destination_file}"
      ;;
    "android"|"linux")
      # some old tar/busybox versions do not support -T, so a different
      # solution is required to package and compress data
      # checking if tar can create package getting names from file
      printf %b "${UAC_DIR}/uac" >"${TEMP_DATA_DIR}/.tar_check.tmp" 2>/dev/null
                
      if tar -T "${TEMP_DATA_DIR}/.tar_check.tmp" \
        -cf "${TEMP_DATA_DIR}/.tar_check.tar" 2>/dev/null; then
        tar -T "${ac_source_file}" -cf - | gzip >"${ac_destination_file}"
      else
        # use file list as tar parameter
        ac_file_list=`awk '{ printf "\"%s\" ", $0; }' <"${ac_source_file}"`
        # eval is required here
        eval "tar -cf - ${ac_file_list} | gzip >\"${ac_destination_file}\""
      fi
      ;;
    "macos")
      tar -T "${ac_source_file}" -cf - | gzip >"${ac_destination_file}"
      ;;
    "solaris")
      tar -cf - -I "${ac_source_file}" | gzip >"${ac_destination_file}"
      ;;
  esac
  
}