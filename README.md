# Wave Rider - Music-Driven Racing Game

## **Project Overview**
Wave Rider is a **music-driven 2.5D racing game** that integrates **Music Information Retrieval (MIR)** techniques to create a synchronized, immersive gameplay experience. This project leverages **preprocessed audio data** to dynamically influence game elements such as speed, obstacle placement, and visual effects.

### **Core Technologies**
- **MIR (Music Information Retrieval)**: Extracts musical features from audio files.
- **ML (Machine Learning)**: Enhances music feature predictions.
- **Game Engine**: Built with **Godot (C#)** for real-time gameplay adaptation.

---

## **How the System Works**
### **1. MIR Feature Extraction (Python - Librosa)**
Before gameplay begins, audio features are extracted from music files using **Librosa** in Python. The extracted features include:
- **Tempo & Beat Tracking** → Determines game speed and obstacle density.
- **Onset Detection** → Identifies beats to place obstacles dynamically.
- **Chord & Key Recognition** → Adjusts visual and environmental elements.
- **Spectral Analysis** → Drives background visual effects.

Each track’s **MIR data** is saved as a JSON file for later retrieval.

### **2. Feature Management & Storage (Python - Feature Manager)**
Extracted **MIR data** is stored and accessed via structured JSON files. The **Feature Manager** script:
- Loads **precomputed music features** from JSON.
- Retrieves **tempo, onsets, chord progressions, and spectral data**.
- Ensures efficient **data management** for fast game integration.

### **3. Game Integration (Godot - C#)**
Godot reads the **preprocessed MIR data** and synchronizes game elements accordingly:
- **MusicManager.cs** → Loads and processes JSON feature data.
- **GameplayController.cs** → Uses extracted features to adjust difficulty, obstacles, and visuals.
- **ObstacleSpawner.cs** → Places obstacles at onset-detected moments.
- **VisualEffectsController.cs** → Maps spectral data to real-time visual effects.

### **4. Machine Learning Integration (Optional Enhancement)**
ML models can enhance MIR predictions:
- **Genre Classification** → Automatically adjusts difficulty based on genre.
- **Beat Prediction (LSTM/RNNs)** → Improves obstacle timing.
- **Clustering & Pattern Recognition** → Dynamically segments tracks for smarter obstacle generation.

---

## **File Structure**
```
WaveRider/
├── game/                      # Godot Project Files
│   ├── Scripts/               # Game logic scripts
│   │   ├── GameplayController.cs
│   │   ├── MusicManager.cs
│   │   ├── ObstacleSpawner.cs
│   │   ├── Player.cs
│   │   ├── VisualEffectsController.cs
│   ├── Assets/                # Game assets
│   ├── Scenes/                # Godot Scenes (Level Design)
│   └── game.tscn              # Main Scene
├── mir_processing/            # Audio Processing Scripts
│   ├── extract_features.py    # Extracts MIR data
│   ├── feature_manager.py     # Handles data retrieval
│   ├── ml_training.py         # ML models for MIR enhancement (Optional)
│   ├── data/                  # Precomputed feature JSONs
│   │   ├── track1.json
│   │   ├── track2.json
├── docs/                      # Documentation
│   ├── MIR_and_Game_Integration.md
│   ├── Progress_Report.md
├── requirements.txt           # Python dependencies
├── README.md                  # This file
└── LICENSE                    # License Information
```

---

## **Setup Guide**
### **1. Install Dependencies**
For **MIR processing**:
```bash
pip install librosa numpy pandas scikit-learn tensorflow
```

For **Godot (C#)**:
- Ensure **Godot Engine** is installed with C# support.

### **2. Extract Features from an Audio File**
Run the feature extraction script:
```bash
python mir_processing/extract_features.py path/to/audio.mp3 mir_processing/data/
```
This generates a JSON file storing tempo, onsets, spectral data, and chords.

### **3. Load Features in the Game**
Modify `GameplayController.cs` in **Godot** to load features:
```csharp
musicManager.LoadMusicData("track1", "mir_processing/data/");
gameplayController.StartGame("track1", "mir_processing/data/");
```
This syncs the game mechanics with the music data.

### **4. Run the Game in Godot**
- Open **Godot**.
- Load the **game/ folder**.
- Press **Run** to start the game.

### **5. (Optional) Train and Use ML Models**
Run ML training (if applicable):
```bash
python mir_processing/ml_training.py
```
This trains models for advanced MIR prediction.

---

## **Testing & Debugging**
### **Unit Tests (Python - MIR Processing)**
Run tests to validate feature extraction:
```bash
pytest mir_processing/tests/
```

### **Debugging in Godot**
Use `GD.Print()` in C# scripts to verify MIR data integration.
