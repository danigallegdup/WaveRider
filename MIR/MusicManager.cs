using System;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using Godot;

public class MusicManager : Node
{
    private Dictionary<string, object> musicData;
    private string currentTrackId;
    
    public override void _Ready()
    {
        GD.Print("MusicManager initialized.");
    }
    
    public void LoadMusicData(string trackId, string featureDirectory)
    {
        string featureFile = Path.Combine(featureDirectory, trackId + ".json");
        
        if (!File.Exists(featureFile))
        {
            GD.PrintErr($"Feature file not found: {featureFile}");
            return;
        }
        
        string jsonContent = File.ReadAllText(featureFile);
        musicData = JsonConvert.DeserializeObject<Dictionary<string, object>>(jsonContent);
        currentTrackId = trackId;
        GD.Print($"Loaded music data for {trackId}");
    }
    
    public float GetTempo()
    {
        return musicData != null && musicData.ContainsKey("tempo") ? Convert.ToSingle(musicData["tempo"]) : 120.0f;
    }
    
    public List<float> GetOnsets()
    {
        return musicData != null && musicData.ContainsKey("onsets") ? JsonConvert.DeserializeObject<List<float>>(musicData["onsets"].ToString()) : new List<float>();
    }
    
    public List<float> GetSpectralData()
    {
        return musicData != null && musicData.ContainsKey("spectral_data") ? JsonConvert.DeserializeObject<List<float>>(musicData["spectral_data"].ToString()) : new List<float>();
    }
    
    public List<int> GetChordProgression()
    {
        return musicData != null && musicData.ContainsKey("chord_progression") ? JsonConvert.DeserializeObject<List<int>>(musicData["chord_progression"].ToString()) : new List<int>();
    }
    
    public void AdjustGameSpeed(Player player)
    {
        float tempo = GetTempo();
        player.SetSpeed(tempo / 60.0f * 5.0f); // Example scaling factor
        GD.Print($"Set player speed based on tempo: {tempo}");
    }
    
    public void SpawnObstacles(ObstacleSpawner spawner)
    {
        List<float> onsets = GetOnsets();
        foreach (float onset in onsets)
        {
            spawner.QueueObstacleSpawn(onset);
        }
        GD.Print("Obstacles queued based on music onsets.");
    }
    
    public void UpdateVisuals(VisualEffectsController effectsController)
    {
        List<float> spectralData = GetSpectralData();
        effectsController.AdjustEffects(spectralData);
        GD.Print("Visual effects updated based on spectral data.");
    }
}
