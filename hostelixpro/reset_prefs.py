import os
import shutil

def reset_preferences():
    app_name = "hostelixpro"
    
    # Potential locations for shared_preferences on Windows
    # 1. Roaming AppData (Most likely for flutter shared_preferences)
    roaming = os.getenv('APPDATA')
    local = os.getenv('LOCALAPPDATA')
    
    locations = []
    if roaming:
        locations.append(os.path.join(roaming, app_name))
        # Sometimes it's organization_name/app_name, but default is often just app_name
    if local:
        locations.append(os.path.join(local, app_name))
        
    print(f"Searching for preferences in: {locations}")
    
    found = False
    for loc in locations:
        if os.path.exists(loc):
            print(f"Found app directory: {loc}")
            # Look for shared_preferences.json
            prefs_file = os.path.join(loc, "shared_preferences.json")
            if os.path.exists(prefs_file):
                print(f"  Found corrupted preferences file: {prefs_file}")
                try:
                    os.remove(prefs_file)
                    print("  SUCCESS: File deleted. App state reset.")
                    found = True
                except Exception as e:
                    print(f"  ERROR: Could not delete file: {e}")
            else:
                print("  No shared_preferences.json found here.")
        else:
            print(f"Directory not found: {loc}")

    if not found:
        print("\nCould not find the specific preferences file.")
        print("Trying deeper search in AppData...")
        # Check standard plugin location: Roaming\com.example.hostelixpro or similar
        # Or check Roaming\hostelixpro\hostelixpro (sometimes nested)
        
        # Checking for any folder ending with hostelixpro
        if roaming:
            for root, dirs, files in os.walk(roaming):
                if app_name in dirs:
                    path = os.path.join(root, app_name)
                    print(f"Found deep directory: {path}")
                    prefs_file = os.path.join(path, "shared_preferences.json")
                    if os.path.exists(prefs_file):
                        try:
                            os.remove(prefs_file)
                            print(f"  SUCCESS: Deleted {prefs_file}")
                            found = True
                        except:
                            pass
                # Stop if too deep
                if root.count(os.sep) - roaming.count(os.sep) > 2:
                    del dirs[:]

    if not found:
        print("FAILURE: Could not locate shared_preferences.json automatically.")
        print("You may need to manually delete it from %APPDATA%/hostelixpro")

if __name__ == "__main__":
    reset_preferences()
