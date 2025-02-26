#!/usr/bin/env bash
# Copyright © 2023 OpenIM. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# OpenIM Server Installation Script
# 
# Description:
#     This script is designed to handle the installation, Is a deployment solution 
#     that uses the Linux systen extension. uninstallation, and
#     status checking of OpenIM components on the server. OpenIM is a presumed
#     communication or messaging platform based on the context.
# 
# Usage:
#     To utilize this script, you need to invoke it with specific commands 
#     and options as detailed below.
# 
# Commands:
#     -i, --install       : Use this command to initiate the installation of all 
#                           OpenIM components.
#     -u, --uninstall     : Use this command to uninstall or remove all 
#                           OpenIM components from the server.
#     -s, --status        : This command can be used to check and report the 
#                           current operational status of the installed OpenIM components.
#     -h, --help          : For any assistance or to view the available commands,
#                           use this command to display the help menu.
# 
# Example Usage:
#     To install all OpenIM components:
#         ./scripts/install/install.sh -i  
#     or 
#         ./scripts/install/install.sh --install  
# 
# Note:
#     Ensure you have the necessary privileges to execute installation or
#     uninstallation operations. It's generally recommended to take a backup 
#     before making major changes.
# 
###############################################################################

OPENIM_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd -P)
[[ -z ${COMMON_SOURCED} ]] && source "${OPENIM_ROOT}"/scripts/install/common.sh

${OPENIM_ROOT}/scripts/install/openim-man.sh
${OPENIM_ROOT}/scripts/install/openim-tools.sh
${OPENIM_ROOT}/scripts/install/test.sh

# Detailed help function
function openim::install::show_help() {
    echo "OpenIM Installer"
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  -i, --install        Install all OpenIM components."
    echo "  -u, --uninstall      Remove all OpenIM components."
    echo "  -s, --status         Check the current status of OpenIM components."
    echo "  -h, --help           Show this help menu."
    echo ""
    echo "Example: "
    echo "  $0 -i     Will install all OpenIM components."
    echo "  $0 --install  Same as above."
}

function openim::install::install_openim() {
    openim::common::sudo "mkdir -p ${OPENIM_DATA_DIR} ${OPENIM_INSTALL_DIR} ${OPENIM_CONFIG_DIR} ${OPENIM_LOG_DIR}"
    openim::log::info "check openim dependency"
    openim::common::sudo "cp -r ${OPENIM_ROOT}/config/* ${OPENIM_CONFIG_DIR}/"

    echo ${LINUX_PASSWORD} | sudo -S bash -c \
        "${OPENIM_ROOT}/scripts/genconfig.sh ${ENV_FILE} deployments/templates/openim.yaml > ${OPENIM_CONFIG_DIR}/config.yaml"

    openim::util::check_ports ${OPENIM_DEPENDENCY_PORT_LISTARIES[@]}

    ${OPENIM_ROOT}/scripts/install/openim-msggateway.sh openim::msggateway::install || return 1
    ${OPENIM_ROOT}/scripts/install/openim-msgtransfer.sh openim::msgtransfer::install || return 1
    ${OPENIM_ROOT}/scripts/install/openim-push.sh openim::push::install || return 1
    ${OPENIM_ROOT}/scripts/install/openim-crontask.sh openim::crontask::install || return 1
    ${OPENIM_ROOT}/scripts/install/openim-rpc.sh openim::rpc::install || return 1
    ${OPENIM_ROOT}/scripts/install/openim-api.sh openim::api::install || return 1

    openim::common::sudo "cp -r ${OPENIM_ROOT}/deployments/templates/openim.target /etc/systemd/system/openim.target"
    openim::common::sudo "systemctl daemon-reload"
    openim::common::sudo "systemctl restart openim.target"
    openim::common::sudo "systemctl enable openim.target"
    openim::log::success "openim install success"
}

function openim::uninstall::uninstall_openim() {
    openim::log::info "uninstall openim"

    ${OPENIM_ROOT}/scripts/install/openim-msggateway.sh openim::msggateway::uninstall || return 1
    ${OPENIM_ROOT}/scripts/install/openim-msgtransfer.sh openim::msgtransfer::uninstall || return 1
    ${OPENIM_ROOT}/scripts/install/openim-push.sh openim::push::uninstall || return 1
    ${OPENIM_ROOT}/scripts/install/openim-crontask.sh openim::crontask::uninstall || return 1
    ${OPENIM_ROOT}/scripts/install/openim-rpc.sh openim::rpc::uninstall || return 1
    ${OPENIM_ROOT}/scripts/install/openim-api.sh openim::api::uninstall || return 1

    set +o errexit
    openim::common::sudo "systemctl stop openim.target"
    openim::common::sudo "systemctl disable openim.target"
    openim::common::sudo "rm -f /etc/systemd/system/openim.target"
    set -o errexit
    openim::log::success "openim uninstall success"
}

function openim::install::status() {
    openim::log::info "check openim status"

    ${OPENIM_ROOT}/scripts/install/openim-msggateway.sh openim::msggateway::status || return 1
    ${OPENIM_ROOT}/scripts/install/openim-msgtransfer.sh openim::msgtransfer::status || return 1
    ${OPENIM_ROOT}/scripts/install/openim-push.sh openim::push::status || return 1
    ${OPENIM_ROOT}/scripts/install/openim-crontask.sh openim::crontask::status || return 1
    ${OPENIM_ROOT}/scripts/install/openim-rpc.sh openim::rpc::status || return 1
    ${OPENIM_ROOT}/scripts/install/openim-api.sh openim::api::status || return 1

    openim::log::success "openim status success"
}

# If no arguments are provided, show help
if [[ $# -eq 0 ]]; then
    openim::install::show_help
    exit 0
fi

# Argument parsing to call functions based on user input
while (( "$#" )); do
    case "$1" in
        -i|--install)
            openim::install::install_openim
            shift
            ;;
        -u|--uninstall)
            openim::uninstall::uninstall_openim
            shift
            ;;
        -s|--status)
            openim::install::status
            shift
            ;;
        -h|--help|*)
            openim::install::show_help
            exit 0
            ;;
    esac
done