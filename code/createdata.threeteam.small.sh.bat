mkdir threeteam.training
pushd threeteam.training
python ../../data/build_dataset.py ../../data/raw/threeteam/20090311.BOSMIA.csv ../../data/raw/threeteam/20090330.ORLMIA.csv
python -c "import os;os.rename('loaddata.m','loaddata_train.m')"
popd
mkdir threeteam.test
pushd threeteam.test
python ../../data/build_dataset.py ../../data/raw/threeteam/20090325.BOSORL.csv
python -c "import os;os.rename('loaddata.m','loaddata_test.m')"
popd