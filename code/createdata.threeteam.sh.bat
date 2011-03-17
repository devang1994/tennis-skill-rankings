mkdir threeteam.training
pushd threeteam.training
python ../../data/build_dataset.py ../../data/raw/threeteam/*.*MIA*.csv
python -c "import os;os.rename('loaddata.m','loaddata_train.m')"
popd
mkdir threeteam.test
pushd threeteam.test
python ../../data/build_dataset.py ../../data/raw/threeteam/*.ORLBOS.csv ../../data/raw/threeteam/*.BOSORL.csv
python -c "import os;os.rename('loaddata.m','loaddata_test.m')"
popd