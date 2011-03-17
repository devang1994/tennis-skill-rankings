mkdir threeteam.training
cd threeteam.training
python ../../data/build_dataset.py ../../data/raw/threeteam/*.*MIA*.csv
cd ..
mkdir threeteam.test
cd threeteam.test
python ../../data/build_dataset.py ../../data/raw/threeteam/*.ORLBOS.csv ../../data/raw/threeteam/*.BOSORL.csv
cd ..