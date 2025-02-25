# Wave Rider
## How to set up your environment
- Download **Godot .NET 3.6** [here](https://godotengine.org/download/3.x/windows/). This is our game engine.
- Download and install .NET SDK  [here](https://dotnet.microsoft.com/en-us/download). This is a dependency for C#.
- Open Godot and import the `project.godot` from the project folder to begin editing.


## How to make a test build
### Pre-requisite: Get the build template for HTML5
- In Godot, go to `Project > Export > HTML5 (Runnable)`
- Find and follow the yellow warning message that says something along the lines of "You are missing the build template." You should have to download and install some package - this lets Godot build the project.

Ask Noah for assistance if needed.

### Export to build/ folder
 - Delete everything in WaveRider/build/ (should be empty)
 - In Godot, go to `Project > Export > HTML5 (Runnable)`
 - Click `Export Project...`

### Test build through a local server
 - Double click **_open_server.bat** (assuming Windows and Python 3)
 - Open a web browser and go to [localhost:8000/WaveRider.html]()

 >**If you aren't running Windows** you can't run the .bat script. Instead, just navigate to /build/ and run `python3 -m http.server`