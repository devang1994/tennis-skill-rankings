#! /usr/bin/env python

# Output file format
#
#

import glob
import sys
import itertools
import csv

#===================
#   Configuration
#===================

OFFENSIVE_TEAM = 'DET'
DEFENSIVE_TEAM = 'CLE'

#======================
#   Helper Functions
#======================

def get_teams_from_filename(filepath):
    """For any raw file, the order of the columns in the file is specified in the filename
    
    Example
    >>> # `20061221.DETCLE.csv` lists Detroit first, and then Cleveland.
    >>> get_teams_from_filename('./rawdata/20061221.DETCLE.csv')
    ('DET', 'CLE')
    >>>
    
    :rtype: a tuple containing two strings
    
    """
    both_teams_str = filepath.split('.')[-2]
    return (both_teams_str[:3], both_teams_str[3:])

def parse_raw_data_from_rows(rows_iterable):
    """Parse a basic CSV file where the first row is a header and subsequent rows are data values
    
    >> a = [['header a', 'header b', 'header c'],
            ['value 1',  'value 2',  'value 3'],
            ['value 4',  'value 5',  'value 6']]
    >>> read_raw_data_from_file(a)
    [{'header a': 'value 1', 'header b': 'value 2', 'header c': 'value 3'},
     {'header a': 'value 4', 'header b': 'value 5', 'header c': 'value 6'}]
    >>>
    
    :param rows_iterable: an iterable of lists of strings, e.g. the entries of a single row from the CSV file split by comma
    :rtype: a list of dictionaries
    
    """
    header = None
    output = []
    for row in rows_iterable:
        if header is None:
            header = row
        else:
            row_dict = dict(zip(header, row))
            output.append( row_dict )

    return output

    
#===============
#   Debugging
#===============
def self_test():
    test_raw_csv = [["header a", "header b", "header c"], ["value 1", "value 2", "value 3"], ["value 4", "value 5", "value 6"]]
    assert(_parse_raw_data_from_rows(test_raw_csv) == [{'header a': 'value 1', 'header b': 'value 2', 'header c': 'value 3'}, {'header a': 'value 4', 'header b': 'value 5', 'header c': 'value 6'}])
    
#==========
#   Main
#==========

if len(sys.argv) <= 1:
    self_test()
    print( "Usage: python build_dataset.py file1 file2 ... > matlab_output.csv")

# Get all the files specified on the command line
input_files = itertools.chain.from_iterable(glob.glob(a) for a in sys.argv[1:])

for rawfile in input_files:
    sys.stderr.write("Reading " + rawfile + " ...\n")
    
    teamnames = get_teams_from_filename(rawfile)
    
    with open(rawfile, "rb") as f:
        reader = csv.reader(f)
        raw_dictionary = parse_raw_data_from_rows(reader)
    
    print raw_dictionary