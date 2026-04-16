#!/bin/bash
# services/atlas_core/entrypoint.sh
set -euo pipefail

DATA_DIR="data/osm"
TEST_DATA="test-data"
mkdir -p "$DATA_DIR"
mkdir -p "$TEST_DATA"

# 1. Fetch Nigerian Map Data if missing
echo "Checking map data inventory..."
./scripts/fetch-nigeria-data.sh

# 2. Build Geocoding and Search indices if missing
if [ ! -d "$TEST_DATA/geocode-index" ]; then
    echo "Geocode index missing. Running atlas-ingest (pass 1: geocoding)..."
    atlas-ingest --osm-dir "$DATA_DIR" --output-dir "$TEST_DATA"
    echo "Geocode index built."
else
    echo "Geocode index found, skipping."
fi

if [ ! -d "$TEST_DATA/search-index" ]; then
    echo "Search index missing. Running atlas-ingest (pass 2: search)..."
    atlas-ingest --osm-dir "$DATA_DIR" --output-dir "$TEST_DATA" --build-search-index
    echo "Search index built."
else
    echo "Search index found, skipping."
fi

# 3. Start the Atlas Server
echo "Launching Atlas Nigeria Engine..."
export ATLAS_TILE_DIR="$TEST_DATA"
export ATLAS_TILE_SOURCE="local"
export ATLAS_OSM_DIR="$DATA_DIR"
export ATLAS_GEOCODE_INDEX_DIR="$TEST_DATA/geocode-index"
export ATLAS_SEARCH_INDEX_DIR="$TEST_DATA/search-index"

exec atlas-server
