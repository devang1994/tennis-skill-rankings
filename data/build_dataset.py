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
# loaddata.m: script
#   This script will populate a cell array named names_offense.
#   This cell array will have one entry for each column of D_C_offense, and contains the name of the player corresponding to that column.
#   For example,
#     names_offense{3} in matlab would be the name of the player in the third column on offense.
#
#   This script will also populate a cell array named names_defense.
#
#   This script will also load your data.


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
    
    :rtype: a dictionary of the form {TEAMNAME: [player_name, player_name, ...], ...}
        where TEAMNAME can be the name of an actual team, or "home" or "away".
    
    """
    names = {}
    
    names['away'] = list(reduce(frozenset.union, (d['away players'] for d in cleaned_dictionaries)))
    names['home'] = list(reduce(frozenset.union, (d['home players'] for d in cleaned_dictionaries)))
    
    names[team_names[0]] = names['away']
    names[team_names[1]] = names['home']

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
    if SKIP_SECOND_HALF and (d['period'] in ['3', '4']):
        # Ignore garbage time, configure this in the Configuration section of this script
        return None

    return {'away players': frozenset([d['a1'], d['a2'], d['a3'], d['a4'], d['a5']]),
            'home players': frozenset([d['h1'], d['h2'], d['h3'], d['h4'], d['h5']]),
            'whose possession': d['team'], #This doesn't apply on fouls but we got rid of them.
            'etype':  d['etype'],
            'result': d['result'],
            'points': d['points'],
            'time':   d['time'],
            'num':    d['num'],
            'outof':  d['outof']}

def combine_free_throws(raw_dictionaries):
    """Merge freethrows into one row"""
    output = []
    
    free_throw_counter = None
    for d in raw_dictionaries:
        # Is this a free throw?
        if d['etype'] == 'free throw':
            
            # Should we assert that the d['time'] is the same the whole time?
            #   "I don't think it matters" --Leland Chen
            
            # Start a new count?
            if free_throw_counter is None:
                free_throw_counter = 0

            if d['result'] == 'made':
                free_throw_counter += 1
                
            if d['num'] == d['outof']:
                aggregate_d = d.copy()
                aggregate_d['etype'] = 'all free throws'
                aggregate_d['free throws made'] = free_throw_counter
                output.append(aggregate_d) # APPEND HERE! CAUTION! Don't forget to read this line! It's important.
                # Done, reset the counter
                free_throw_counter = None
                
        else:
            output.append(d) # Keep it the same
    
    return output


def get_possession_outcome(d, d_next):
    """Return a dictionary with only the data relevant to the outcome of the possession

    :rtype: tuple with two elements.
    
        First element is a dictionary of the form {'who': string, 'R': integer}
          e.g. {'who': 'CLE', 'R': 0}
               Cleveland turns over the ball
               
          e.g. {'who': 'CLE', 'R': 2}
               Cleveland scored 2 points, end of possession
           
          we also return None if this row of the data is irrelevant, e.g. it's not an end-of-possession event
          
        Second element of the tuple is a boolean indicating whether we need to skip d_next (e.g. if it's a bonus free-throw and we already counted it)
    
    """
    outcome = {'who': d['whose possession']}
    #==========================
    #   Scoring and attempts
    #==========================

    if d['etype'] == 'turnover':
        # Turnover
        outcome['R'] = 0
        return (outcome, False)

    elif d['etype'] == 'shot' and d['result'] == 'missed':
        # Shot missed
        if d_next is None:
            # Shot missed, not enough time for a full possession
            return (None, False)
        elif d_next['whose possession'] != d['whose possession']:
            # Shot missed, End-of-possession on defensive rebound
            outcome['R'] = 0
            return (outcome, False)
        else:
            # Shot missed, but nothing to indicate that the "possession" has ended so ignore this entry
            return (None, False)

    elif d['etype'] == 'shot' and d['result'] == 'made':
        # Shot made
        outcome['R'] = int(d['points'])
        
        if d_next['etype'] == 'all free throws' and d_next['time'] == d['time']:
            # Shot made, bonus free-throw(s)
            outcome['R'] += d_next['free throws made']
            return (outcome, True)
        else:
            return (outcome, False)

    elif d['etype'] == 'all free throws':
        # Fouled on the play
        outcome['R'] = d['free throws made']
        return (outcome, False)
    else:
        assert False, "How come we didn't remove this? Why didn't you write code to handle this case? " + repr(d)
        
def get_possession_outcomes(raw_dictionaries):
    """Call get_possession_outcome() on a loop
    
    :param raw_dictionaries: a list of event dictionaries
    :rtype: a dictionary of the form {'away': set_of_players, 'home': set_of_players, 'R': integer, 'who': team_name}
    
    """
    result_outcome_dicts = []
    
    please_skip = False
    for indx, curr in enumerate(raw_dictionaries):
        # Sometimes we want to skip a row...
        if please_skip:
            please_skip = False
            continue
    
        # Peek ahead to iterate over the dictionary in pairs
        try:
            next = raw_dictionaries[indx + 1]
        except IndexError as last_event_error: 
            next = None

        # Process the row
        outcome, please_skip = get_possession_outcome(curr, next)
    
        # Append the result
        if outcome is None:
            pass
        else:
            outcome['away'] = curr['away players']
            outcome['home'] = curr['home players']
            result_outcome_dicts.append(outcome)

    return result_outcome_dicts
    
#===============
#   Debugging
#===============
def self_test():
    test_raw_csv = [["header a", "header b", "header c"], ["value 1", "value 2", "value 3"], ["value 4", "value 5", "value 6"]]
    assert(parse_raw_data_from_rows(test_raw_csv) == [{'header a': 'value 1', 'header b': 'value 2', 'header c': 'value 3'}, {'header a': 'value 4', 'header b': 'value 5', 'header c': 'value 6'}])
    
#==========
#   Main
#==========

if len(sys.argv) <= 1:
    self_test()
    print( "Usage: python build_dataset.py <inputfile>")
    sys.exit(0)

rawfile = sys.argv[1]
print("Reading " + rawfile + " ...")

# Get team names
input_teamnames = get_teams_from_filename(rawfile)

# Read data
with open(rawfile, "rb") as f:
    reader = csv.reader(f)
    raw_dictionaries = parse_raw_data_from_rows(reader)

# Remove irrelevant data
cleaned_dictionaries = [remove_irrelevant_data(d) for d in raw_dictionaries]
filtered_dictionaries = [d for d in cleaned_dictionaries if not (d is None)]

# Combine free throws into single rows
events = combine_free_throws(filtered_dictionaries)

# Extract player names. The order of these names will determine the organization of the output CSV files.
unique_player_lists = get_unique_player_names(input_teamnames,filtered_dictionaries)

# Data has been collected into the form of Bayesian network observations.
# {'away': set_of_players, 'home': set_of_players, 'R': integer, 'who': team_name}
almost_bayesian_network_observations = get_possession_outcomes(events)

# Now we just need to write it out.
# For each row/Bayesian-observation, we must output the following:
#   1. Result (integer)
#   2. Players on the court if OFFENSIVE_TEAM is attacking and DEFENSIVE_TEAM is defending
#   3. Player names

assert frozenset(input_teamnames) == frozenset([OFFENSIVE_TEAM, DEFENSIVE_TEAM]), "We only support one game at a time right now."

offensive_players = unique_player_lists[OFFENSIVE_TEAM]
defensive_players = unique_player_lists[DEFENSIVE_TEAM]

# We only output possessions where OFFENSIVE_TEAM is the attacking team
relevant_observations = [row for row in almost_bayesian_network_observations if row['who'] == OFFENSIVE_TEAM]

# Write #1
R_fname = 'D_' + OFFENSIVE_TEAM + DEFENSIVE_TEAM + "_r"
print("Writing {0} ...".format(R_fname))
with open(R_fname + ".csv", "w") as f:
    # But only write rows where OFFENSIVE_TEAM is attacking.
    for row in relevant_observations:
        if MAX_THREE_POINTS and row['R'] > 3:
            f.write('3')
        else:
            f.write(str(row['R']))
        f.write("\n")
            
# Write #2a (offense)
C_offense_fname = "D_C_" + OFFENSIVE_TEAM + "_offense"
print("Writing {0} ...".format(C_offense_fname))
with open(C_offense_fname + ".csv", "w") as f:
    for row in relevant_observations:
        players_on_court = row['home'] | row['away']
        offensive_logicals = [str(int(p in players_on_court)) for p in offensive_players]
        f.write(','.join(offensive_logicals))
        f.write("\n")
            
# Write #2b (defense)
C_defense_fname = "D_C_" + DEFENSIVE_TEAM + "_defense"
print("Writing {0} ...".format(C_defense_fname))
with open(C_defense_fname + ".csv", "w") as f:
    for row in relevant_observations:
        players_on_court = row['home'] | row['away']
        defensive_logicals = [str(int(p in players_on_court)) for p in defensive_players]
        f.write(','.join(defensive_logicals))
        f.write("\n")

# Write #3
print("Writing loaddata.m ...")
with open('loaddata.m', "w") as f:
    f.write("names_offense = {" + ','.join("'" + p + "'" for p in offensive_players) + "};\n")
    f.write("names_defense = {" + ','.join("'" + p + "'" for p in defensive_players) + "};\n")
    f.write("% This file came from {0}\n".format(rawfile))
    f.write("{0} = csvread('{0}.csv');\n".format(R_fname))
    f.write("{0} = logical(csvread('{0}.csv'));\n".format(C_offense_fname))
    f.write("{0} = logical(csvread('{0}.csv'));\n".format(C_defense_fname))
    f.write("dataset = [{0} {1} {2}];\n".format(R_fname,C_offense_fname,C_defense_fname))
