#! /usr/bin/env python

# Output file format is a series of MATLAB matrices in CSV format.
# D_r.csv: Column vector
#   Each element is the value of Result for that particular observation -- either 0, 1, 2, or 3
#
# D_C_*_offense.csv: N×12 matrix
#   Each row corresponds to an observation from D_r.
#   Each row has 12 boolean values (1 or 0), and exactly five of them are set to "1". These five ones correspond to the five offensive players on the court during this possession.
#   TODO: When we support multiple games, and mixed rosters, you'll need more than 12 here, but for now it's fine.
#   The name of the output file will depend on the name of the team.
#   For example, Detroit will be D_C_DET_offense.csv
#
#
# D_C_*_defense.csv: N×12 matrix
#   Same as D_C_*_offense but for the defensive team.
#
# names.m: script
#   This is a script that will populate a cell array named names_offense.
#   This cell array will have one entry for each column of D_C_offense, and contains the name of the player corresponding to that column.
#
#   This is a script will also populate a cell array named names_defense.


import glob
import sys
import itertools
import csv

#===================
#   Configuration
#===================

OFFENSIVE_TEAM = 'DET'
DEFENSIVE_TEAM = 'CLE'
SKIP_SECOND_HALF = True # Simple way to avoid garbage time

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

def get_free_throw_outcome(d):
    
def get_possession_outcome(d_prev, d):
    """Return a dictionary with only the data relevant to the outcome of the possession

    :param d_prev: can be none, but then d['team'] would be 'OFF' and it's probably the jump-ball
    
    #first you only care about 1st or 2nd period (#10)
    

    #now I would check type (#13)
      if turnover
        result = 0
        
      if shot then you have to check result (#27). 
        if result == made, take points (#24)
          if "and 1", switch to foul mode

      if foul, 
        read until d['num'] == d['outof']
        # IGNORE ANYTHING ELSE DURING THIS TIME BECAUSE sometimes rebounds happen between foul shots
        
      #if d['etype'] == 'rebound' and d['type'] != 'off':
      if d['result'] == missed:
           team = d['team']
              next line
              if d['etype'] == rebound:
                      if d['team'] != team:
                              result = 0
                              break
       
       if d['etype'] == 'turnover': 
         result = 0
       if d['etype'] == 'foul' 
       if d['type'] == 'defense 3 second' || d['type'] == 'technical':
         continue (since ignore the subsequent etype == free throw *&&&ype == technical
       else read until d['num'] == 'd['outof']:
         if d['result'] == 'made':
           result++
      
    :rtype: either a (integer, boolean) tuple, or None
          None --> Ignore this line, e.g. it's not an end-of-possession event
          (score, False) --> scored `score` points, end of possession.
          (score, True) --> start with `score` points, add more for subsequent foul shots
          
          score can take on various sentinel values as well:
          `score == -1` means "missed shot" 
    
    """
    assert(d['period'] in ['1', '2', '3', '4'])
    
    if SKIP_SECOND_HALF and (d['period'] in ['3', '4'])
        # Ignore garbage time, configure this in the Configuration section of this script
        return None
    
    if d['team'] == 'OFF':
        # Probably a jump-ball or something, but d_prev may not be valid here either
        return None

    if d['etype'] == 'turnover':
        return (0, False)
    elif d['etype'] == 'rebound' and d['type'] != 'off':
        return (0, False)
    elif d['etype'] == 'shot' and d['result'] == 'made':
        scored = int(d['points'])
        #AND1?
        return (scored, fouled)
    elif d['type'] == 'foul':
        return (0, True)
    else:
        return None
        
    
def get_possession_outcomes(raw_dictionaries):
    result_outcome_dicts = []
    prev = None
    for possession_dictionary in raw_dictionaries:
        result, start_free_throws = get_possession_outcome(prev, possession_dictionary)
        
        if result is None:
            pass
        elif result == {}:
            result_outcome_dicts.pop()
        else:
            result_outcome_dicts.append(result)
        
        prev = possession_dictionary
    return result_outcome_dicts
    
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

assert len(input_files) == 1, "Multi-games not yet implemented. That's an extension. Specifically, we assume only 12 players from each team can ever play during a game."

for rawfile in input_files:
    print("Reading " + rawfile + " ...")
    
    # Get team names
    teamnames = get_teams_from_filename(rawfile)
    
    # Get player names
    with open(rawfile, "rb") as f:
        reader = csv.reader(f)
        raw_dictionaries = parse_raw_data_from_rows(reader)
    
    
    #unique_player_names = reduce(set.union, raw_dictionaries)