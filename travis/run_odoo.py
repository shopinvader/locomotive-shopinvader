#!/usr/bin/env python
# -*- coding: utf-8 -*-
from ..maintainer_quality_tools.travis.test_server import (
    get_addons_path,
    get_server_path,
    create_server_conf)


def main(argv=None):
    travis_home = os.environ.get("HOME", "~/")
    travis_dependencies_dir = os.path.join(travis_home, 'dependencies')
    travis_build_dir = os.environ.get("TRAVIS_BUILD_DIR", "../..")
    odoo_version = os.environ.get("VERSION")
    odoo_full = os.environ.get("ODOO_REPO", "odoo/odoo")
    travis_home = os.environ.get("HOME", "~/")
    data_dir = os.path.expanduser(os.environ.get("DATA_DIR", '~/data_dir'))
    database = 'odoo'

    server_path = get_server_path(odoo_full, odoo_version, travis_home)
    addons_path = get_addons_path(
        travis_dependencies_dir, travis_build_dir, server_path)
    script_name = 'odoo-bin'
    create_server_conf({
        'addons_path': addons_path,
        'data_dir': data_dir,
    }, odoo_version)

    command_call = [
	"%s/%s" % (server_path, script_name),
        "-d", database,
        "--db-filter=^%s$" % database,
        "--log-level", test_loglevel,
        "-i shopinvader",
    ]
    subprocess.Popen(
        command_call, stderr=subprocess.STDOUT, stdout=subprocess.PIPE)
