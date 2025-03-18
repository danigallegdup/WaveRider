using System.Collections.Generic;
using Godot;

public class GameplayController : Node
{
    private MusicManager musicManager;
    private Player player;
    private ObstacleSpawner obstacleSpawner;
    private VisualEffectsController effectsController;
    
    public override void _Ready()
    {
        musicManager = GetNode<MusicManager>("/root/MusicManager");
        player = GetNode<Player>("/root/Player");
        obstacleSpawner = GetNode<ObstacleSpawner>("/root/ObstacleSpawner");
        effectsController = GetNode<VisualEffectsController>("/root/VisualEffectsController");
    }
    
    public void StartGame(string trackId, string featureDirectory)
    {
        musicManager.LoadMusicData(trackId, featureDirectory);
        AdjustDifficultyCurve();
        SyncObstacleGeneration();
        UpdateVisuals();
    }
    
    private void AdjustDifficultyCurve()
    {
        float tempo = musicManager.GetTempo();
        player.SetSpeed(tempo / 60.0f * 5.0f); // Example scaling factor
        GD.Print($"Player speed adjusted for tempo: {tempo}");
    }
    
    private void SyncObstacleGeneration()
    {
        List<float> onsets = musicManager.GetOnsets();
        foreach (float onset in onsets)
        {
            obstacleSpawner.QueueObstacleSpawn(onset);
        }
        GD.Print("Obstacle generation synchronized with music.");
    }
    
    private void UpdateVisuals()
    {
        List<float> spectralData = musicManager.GetSpectralData();
        effectsController.AdjustEffects(spectralData);
        GD.Print("Game visuals updated with spectral analysis.");
    }
}
