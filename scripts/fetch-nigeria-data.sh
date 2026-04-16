#!/bin/bash
# services/atlas_core/scripts/fetch-nigeria-data.sh
set -euo pipefail

DEST="test-data"
OSM_DEST="data/osm"
mkdir -p "$DEST"
mkdir -p "$OSM_DEST"

# 1. Download Nigeria OSM PBF for Routing & Geocoding
if [ -f "$OSM_DEST/nigeria-latest.osm.pbf" ]; then
    echo "Nigeria OSM data already exists, skipping."
else
    echo "Downloading Nigeria OSM PBF from Geofabrik..."
    curl -L -o "$OSM_DEST/nigeria-latest.osm.pbf" \
        "https://download.geofabrik.de/africa/nigeria-latest.osm.pbf"
    echo "Successfully downloaded Nigeria OSM data."
fi

# 2. Extract Nigeria PMTiles for Tile Serving
# Nigeria BBox: [West, South, East, North]
NIGERIA_BBOX="2.6,4.2,14.7,13.9"

if [ -f "$DEST/nigeria.pmtiles" ]; then
    echo "Nigeria PMTiles already exists, skipping."
else
    echo "Extracting Nigeria PMTiles from global Protomaps build..."
    # Using a recent global pmtiles build (fallback to a specific date if latest isn't predictable)
    PLANET_URL="https://build.protomaps.com/20260315.pmtiles"
    
    if command -v pmtiles &> /dev/null; then
        pmtiles extract "$PLANET_URL" "$DEST/nigeria.pmtiles" \
            --bbox="$NIGERIA_BBOX" \
            --maxzoom=14
        echo "Done: $DEST/nigeria.pmtiles ($(du -h "$DEST/nigeria.pmtiles" | cut -f1))"
    else
        echo "Error: pmtiles CLI not found. Please ensure it is installed in the container environment."
        exit 1
    fi
fi

echo "Nigerian Map Data Pipeline Complete."
