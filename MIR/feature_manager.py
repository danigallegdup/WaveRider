"""
How It Works
Loads extracted feature data from JSON files.
Provides functions to retrieve:
Tempo (for controlling game speed)
Onset timings (for obstacle placement)
Spectral data (for visual effects)
Chord progression (for environment adaptation)
CLI interface allows retrieval of specific features.

python feature_manager.py track_id path/to/features/ --feature tempo

"""

import json
import os

def load_feature_data(track_id, feature_directory):
    """
    Loads extracted features for a given track from the JSON file.
    """
    feature_file = os.path.join(feature_directory, f"{track_id}.json")
    if not os.path.exists(feature_file):
        print(f"Feature file not found: {feature_file}")
        return None
    
    with open(feature_file, 'r') as f:
        return json.load(f)

def get_tempo(track_id, feature_directory):
    """
    Retrieves the tempo value of the given track.
    """
    data = load_feature_data(track_id, feature_directory)
    return data.get('tempo', None) if data else None

def get_obstacle_timing(track_id, feature_directory):
    """
    Returns onset timestamps for obstacle placement.
    """
    data = load_feature_data(track_id, feature_directory)
    return data.get('onsets', []) if data else []

def get_spectral_data(track_id, feature_directory):
    """
    Retrieves spectral data for visual effects.
    """
    data = load_feature_data(track_id, feature_directory)
    return data.get('spectral_data', []) if data else []

def get_chord_progression(track_id, feature_directory):
    """
    Retrieves chord progression data for dynamic environment adaptation.
    """
    data = load_feature_data(track_id, feature_directory)
    return data.get('chord_progression', []) if data else []

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Retrieve stored MIR features for a track.")
    parser.add_argument("track_id", type=str, help="Unique ID (filename without extension) of the track.")
    parser.add_argument("feature_directory", type=str, help="Directory containing feature JSON files.")
    parser.add_argument("--feature", type=str, choices=["tempo", "onsets", "spectral", "chords"], default="tempo", help="Feature to retrieve.")
    
    args = parser.parse_args()
    
    feature_map = {
        "tempo": get_tempo,
        "onsets": get_obstacle_timing,
        "spectral": get_spectral_data,
        "chords": get_chord_progression
    }
    
    result = feature_map[args.feature](args.track_id, args.feature_directory)
    print(f"{args.feature.capitalize()} for {args.track_id}: {result}")
