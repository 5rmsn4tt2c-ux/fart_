import sys
import json
import urllib.request
import urllib.error

MOJANG_URL = "https://api.mojang.com/users/profiles/minecraft/{}"
HYPIXEL_STATUS_URL = "https://api.hypixel.net/status?uuid={}&key={}"

BEDWARS_GAME_TYPES = {"BEDWARS"}
LOBBY_GAME_TYPES = {"LOBBY", "LIMBO"}


def fetch_json(url):
    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        if e.code == 429:
            print("Rate limited. Try again later.")
        elif e.code == 403:
            print("Invalid or missing API key.")
        else:
            print(f"HTTP error {e.code}")
        return None
    except Exception as e:
        print(f"Request failed: {e}")
        return None


def get_uuid(username):
    data = fetch_json(MOJANG_URL.format(username))
    if not data or "id" not in data:
        return None
    return data["id"]


def check_status(username, api_key):
    uuid = get_uuid(username)
    if not uuid:
        print(f"Player '{username}' not found.")
        return

    data = fetch_json(HYPIXEL_STATUS_URL.format(uuid, api_key))
    if not data:
        return

    if not data.get("success"):
        print("Hypixel API error:", data.get("cause", "unknown"))
        return

    session = data.get("session", {})
    online = session.get("online", False)

    if not online:
        print(f"{username} is offline.")
        return

    game_type = (session.get("gameType") or "").upper()
    game_mode = session.get("mode", "")
    game_map = session.get("map", "")

    if game_type in BEDWARS_GAME_TYPES:
        parts = [f"{username} is in BedWars"]
        if game_mode:
            parts.append(f"mode: {game_mode}")
        if game_map:
            parts.append(f"map: {game_map}")
        print(" | ".join(parts))
    elif game_type in LOBBY_GAME_TYPES or game_type == "":
        print(f"{username} is in the lobby.")
    else:
        print(f"{username} is online playing {game_type}" + (f" ({game_mode})" if game_mode else ""))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python bedwars_status.py <username> <hypixel_api_key>")
        sys.exit(1)

    check_status(sys.argv[1], sys.argv[2])
