#!/usr/bin/env python3
#
# Use happybase (https://github.com/python-happybase/happybase) to perform
# a write/read test on a dedicated table for monitoring purposes.
#
# The table gets deleted if it exists, (re-)created and a write is done
# to the newly created table.  Data is written and gets read back.
# Afterwards the table gets deleted again.
#
# On success the script returns 0 otherwise 1
#
# Required environment vars are:
#  HBASE_HOST
#
# Optional environment vars:
#  HBASE_TABLE_NAME

import happybase
import os
import sys

required_env_vars = ["HBASE_HOST"]

default_hbase_table_name = "monitoring_write_test"
row_key = "monitoring_write_test".encode("utf-8")
data = b'This is how a successful write looks like.'

# Check env for required vars,
# exit if not found
def check_required_vars(env_vars):
    for k in env_vars:
        if None == os.getenv(k):
            print("Required environment variable missing: " + k)
            sys.exit(1)


# Get a list of all tables
def tables(conn):
    tables = []
    ts = conn.tables()
    for t in ts:
        tables.append(t.decode("utf-8"))

    return tables

# Print all tables
def list_tables(tables):
    for t in tables:
        print(t)


# Check if given table exists
def table_exists(conn, table_name):
    tablelist = tables(conn)

    try:
        x = tablelist.index(table_name)
    except ValueError:
        print("Table {:s} does not exist" .format(table_name))
        return False
    else:
        print("Table {:s} exists" .format(table_name))
        return True


def create_table(conn, table_name):
    print("Creating table: ", table_name)
    conn.create_table(
        hbase_table_name,
        {'cf0': dict(max_versions=1, block_cache_enabled=False)}
    )


# Delete a table
def delete_table(conn, table_name):
    print("Deleting table: ", table_name)
    conn.delete_table(hbase_table_name, disable=True)


# Read data at row_key from table
def read(conn, table_name, row_key):
    print("Reading from table {:s} " .format(table_name))
    table = conn.table(hbase_table_name)
    row = table.row(row_key)
    print("data: {:s}" .format(row[b'cf0:'].decode("utf-8")))


# Read data from table
def read_all(conn, table_name, row_key):
    print("Reading from table {:s} " .format(table_name))
    table = conn.table(hbase_table_name)

    for key, data in table.rows([row_key]):
        print(key, data)


# Scan table
def scan(conn, table_name):
    print("Reading from table {:s} " .format(table_name))
    table = conn.table(hbase_table_name)

    for key, data in table.scan(row_prefix=b'row'):
        print(key, data)


# Write data at 'row_key' to table
def write(conn, table_name, row_key, data):
    print("Writing to table {:s} " .format(table_name))
    table = conn.table(hbase_table_name)
    table.put(row_key, {b'cf0:': data})


# Delete data at 'row_key'
def delete(conn, table_name, row_key):
    row = table.delete(row_key)


if __name__ == '__main__':

    check_required_vars(required_env_vars)

    hbase_host = os.getenv("HBASE_HOST")
    hbase_table_name = os.getenv("HBASE_TABLE_NAME")

    if not hbase_table_name:
        hbase_table_name = default_hbase_table_name

    try:
        conn = happybase.Connection(hbase_host)
    except:
        print("Failed to connect to: {:s}" .format(hbase_host))
        sys.exit(1)

    if table_exists(conn, hbase_table_name):
        delete_table(conn, hbase_table_name)

    # Run a full test cycle
    create_table(conn, hbase_table_name)
    write(conn, hbase_table_name, row_key, data)
    read(conn, hbase_table_name, row_key)
    delete_table(conn, hbase_table_name)
