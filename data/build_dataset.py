#! /usr/bin/env python

# Output file format is a series of MATLAB matrices in CSV format.
# D_*_r.csv: Column vector of length N
#   Each element is the value of Result for that particular observation -- either 0, 1, 2, or 3
#   The name of the output file will depend on the name of the teams on offense and defense.
#   For example, Detroit's offensive possessions against Cleveland would be D_r_DETCLE.csv
#
# D_C_*_offense.csv: N×12 matrix
#   Each row corresponds to an observation from D_r (in the same row).
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
#   For example,
#     names_offsense{3} in matlab would be the name of the player in the third column on offense.
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
MAX_THREE_POINTS = True # Assume plays scoring 4 or more points are just for 3 in the model. There wouldn't be enough w_4^1 datapoints to warrant modelling them.

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

def get_unique_player_names(team_names, cleaned_dictionaries):
    """Return the list of unique players on each team
    
    :param team_names: A tuple of the form (string1, string2) describing the order of teams
    :param cleaned_dictionaries: A list of dictionaries output by remove_irrelevant_data()
    
    :rtype: a dictionary of the form {TEAMNAME: set([player_name, player_name, ...]), TEAMNAME: set([player_name, player_name, ...])}
    
    """
    names = {}
    
    # Columns 0 through 4 are for the first team (away)
    names{team_names[0]} = reduce(set.union, for d['away players'] in cleaned_dictionaries)
    names{team_names[1]} = reduce(set.union, for d['home players'] in cleaned_dictionaries)

    return names

def remove_irrelevant_data(d):
    """Filter for relevant data only
    
    We should be left with 'etype' of:
        turnover
        free throw (result: made/missed, num, outof)
        shot (result: made(points)/missed)
    
    :rtype: None if the data is irrelevant, otherwise the relevant portion of the data
    
    """

    if d['etype'] == 'rebound':
        return None
        
    if d['etype'] == 'sub':
        return None
    
    if d['etype'] == 'violation':
        return None
    
    if d['etype'] == 'timeout':
        return None
        
    if d['etype'] == 'jump ball':
        return None
    
    if d['etype'] == 'foul':
        return None
        
    if d['etype'] == 'free throw' and d['type'] == 'technical':
        return None
        
    # Configurable filters
    assert(d['period'] in ['1', '2', '3', '4'])
    if SKIP_SECOND_HALF and (d['period'] in ['3', '4'])
        # Ignore garbage time, configure this in the Configuration section of this script
        return None

    return {'away players', frozenset([d['a1'], d['a2'], d['a3'], d['a4'], d['a5']])
            'home players', frozenset([d['h1'], d['h2'], d['h3'], d['h4'], d['h5']])
            'whose possession', d['team'], #This doesn't apply on fouls but we got rid of them.
            'etype',  d['etype'],
            'result', d['result'],
            'points', d['points'],
            'time',   d['time'],
            'num',    d['num'],
            'outof',  d['outof']}
    
    
def get_free_throw_outcome(d):
    """
    
    :rtype: 
    
    """
    if d['etype'[] == free throw 

def get_possession_outcome(d, d_next):
    """Return a dictionary with only the data relevant to the outcome of the possession

    :rtype: a dictionary of the form {'offensive team': string, 'points scored': integer, 'fouled': boolean}
          e.g. {'offensive team': 'CLE', 'points scored': 0, 'fouled': False}
               Cleveland turns over the ball
               
          e.g. {'offensive team': 'CLE', 'points scored': 0, 'fouled': True}
               Cleveland is fouled during a shot, goes to the free throw line
               
          e.g. {'offensive team': 'CLE', 'points scored': 2, 'fouled': False}
               Cleveland scored 2 points, end of possession (no foul shots)
          
          e.g. {'offensive team': 'CLE', 'points scored': 2, 'fouled': False}
               Cleveland scored 2 points, end of possession (no foul shots)
          (team, score, True) --> start with `score` points, add more for subsequent foul shots
           
          we also return None if this row of the data is irrelevant, e.g. it's not an end-of-possession event
          
    
    """

    #==========================
    #   Scoring and attempts
    #==========================

    if d['etype'] == 'turnover':
        # Turnover
        return (d['team'], 0, False)

    elif d['etype'] == 'shot' and d['result'] == 'missed':
        # Shot missed
        if d_next['etype'] == 'rebound' and d_next['team'] != d['team']:
            # Shot missed, End-of-possession on defensive rebound
            return (d['team'], 0, False)
        else:
            # Shot missed, but nothing to indicate that the "possession" has ended so ignore this entry
            return None

    elif d['etype'] == 'shot' and d['result'] == 'made':
        # Shot made
        scored = int(d['points'])
        
        if d_next['etype'] == 'foul' && d_next['time'] == d['time']:
            # Shot made, bonus free-throw
            return (d['team'],scored, True)
        else:
            # Shot made, no fouls
            return (d['team'],scored, False)

    elif d['etype'] == 'foul':
        # Fouled on the play
        if d['type'] == 'defense 3 second' or d['type'] == 'technical':
            return None # Don't care about silly fouls
        else:
            return (d['team'], 0, True)
    else:
        return None
        
def get_possession_outcomes(raw_dictionaries):
    """Call get_possession_outcome() on a loop
    
    :param raw_dictionaries: a list of event dictionaries
    :rtype: a dictionary of the form {'TEAM1': list_of_event_dictionaries, 'TEAM2': list_of_event_dictionaries}
    
    """
    result_outcome_dicts = []
    looking_for_free_throws = False
    
    for indx, curr in enumerate(raw_dictionaries):
        if looking_for_free_throws:
            # FREE THROWS MODE
            looking_for_free_throws, bonus_points = get_free_throw_outcome(curr, next)

            
        else:
            # REGULAR MODE
        
            # Peek ahead to iterate over the dictionary in pairs
            try:
                next = raw_dictionaries[indx + 1]
            except IndexError as last_event_error: 
                next = None

            outcome =  = get_possession_outcome(curr, next)
            looking_for_free_throws
            offensive_team, result,
        
            if result is None:
                pass
            else:
                result_outcome_dicts.append(result)

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
    
    # Read data
    with open(rawfile, "rb") as f:
        reader = csv.reader(f)
        raw_dictionaries = parse_raw_data_from_rows(reader)

    # Remove irrelevant data
    cleaned_dictionaries = [d for d in remove_irrelevant_data(raw_dictionaries) if not (d is None)]

    # Get player names
    unique_player_names = get_unique_player_names(teamnames, cleaned_dictionaries)
    
            if MAX_THREE_POINTS:
                pass