names_offense = {'Dale Davis','Will Blalock','Chris Webber','Ronald Murray','Carlos Delfino','Jason Maxiell','Antonio McDyess','Richard Hamilton','Nazr Mohammed','Tayshaun Prince','Lindsey Hunter','Rasheed Wallace','Chauncey Billups'};
names_defense = {'Daniel Gibson','Drew Gooden','Eric Snow','Sasha Pavlovic','Damon Jones','Anderson Varejao','LeBron James','Donyell Marshall','Zydrunas Ilgauskas','Shannon Brown','Larry Hughes'};
% This file came from:
%   ..\data\raw\20070204.DETCLE.csv
%   ..\data\raw\20061221.DETCLE.csv
%   ..\data\raw\20070307.CLEDET.csv
%   ..\data\raw\20070408.CLEDET.csv
D_DETCLE_r = csvread('D_DETCLE_r.csv');
D_C_DET_offense = logical(csvread('D_C_DET_offense.csv'));
D_C_CLE_defense = logical(csvread('D_C_CLE_defense.csv'));
dataset = [D_DETCLE_r D_C_DET_offense D_C_CLE_defense];
