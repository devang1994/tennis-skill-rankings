names_offense = {'Tayshaun Prince','Lindsey Hunter','Chris Webber','Richard Hamilton','Carlos Delfino','Jason Maxiell','Rasheed Wallace','Antonio McDyess','Dale Davis','Chauncey Billups'};
names_defense = {'Daniel Gibson','Drew Gooden','Eric Snow','Damon Jones','Anderson Varejao','LeBron James','Donyell Marshall','Zydrunas Ilgauskas','Sasha Pavlovic','Larry Hughes'};
% This file came from raw\20070204.DETCLE.csv
D_DETCLE_r = csvread('D_DETCLE_r.csv');
D_C_DET_offense = csvread('D_C_DET_offense.csv');
D_C_CLE_defense = csvread('D_C_CLE_defense.csv');
dataset = [D_DETCLE_r D_C_DET_offense D_C_CLE_defense];
