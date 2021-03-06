#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

rm -rf coverage_reports
mkdir coverage_reports
chmod 777 coverage_reports

python3 ./build/new-jenkins/rspec-combine-coverage-results.py

# build the reports inside the canvas-lms image because it has the required executables
inputs=()
inputs+=("--volume $WORKSPACE/coverage_nodes:/usr/src/app/coverage_nodes")
inputs+=("--volume $WORKSPACE/coverage_reports:/usr/src/app/coverage_reports")
cat <<EOF | docker run --interactive ${inputs[@]} $PATCHSET_TAG /bin/bash -
set -ex

mkdir coverage

# copy the file to where the 'merger' expects it
cp coverage_nodes/.resultset.json coverage/.resultset.json

# this doesnt actually merge things, it just makes the report
bundle exec ruby spec/simple_cov_result_merger.rb

# tar this up in the mounted volume so we can get it later
tar cf coverage_reports/coverage.tar ./coverage
EOF

# extract the reports
rm -rf coverage
tar -xf coverage_reports/coverage.tar

# lets see the result after
find ./coverage_nodes
find ./coverage
rm -rf coverage_reports
