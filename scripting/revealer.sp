#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#include "include/ripext.inc"

#pragma newdecls required
#pragma semicolon 1

#define VERSION			  "1.0.0"
#define API_URL			  "https://alyx.ro/api/v1/revealer"
#define MAX_REQUESTS	  10
#define RATE_LIMIT_WINDOW 10

char g_sApiKey[256];
int g_iRequestTimes[MAX_REQUESTS];
int g_iCurrentRequest = 0;
StringMap g_hCheatCache;

public Plugin myinfo =
{
	name = "[Alyx-Network] Cheat Revealer",
	author = "dragos112",
	description = "Reveal other player's cheats",
	version = VERSION,
	url = "https://github.com/hiraeeth"
};

public void OnPluginStart()
{
	LoadConfig();
	g_hCheatCache = new StringMap();
}

public void OnMapStart()
{
	g_hCheatCache.Clear();
}

public void OnMapEnd()
{
	g_hCheatCache.Clear();
}

void LoadConfig()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/revealer.cfg");

	KeyValues kv = new KeyValues("Revealer");
	if (!kv.ImportFromFile(path))
	{
		kv.SetString("api_key", "YOUR_API_KEY_HERE");
		kv.ExportToFile(path);
		LogMessage("Created new config file: %s", path);
	}

	kv.GetString("api_key", g_sApiKey, sizeof(g_sApiKey));
	if (strlen(g_sApiKey) == 0)
		LogError("API key not found. Please set your API key in: %s", path);

	delete kv;
}

bool IsRateLimited()
{
	int currentTime = GetTime();
	int oldestRequest = g_iRequestTimes[g_iCurrentRequest];

	if (oldestRequest == 0)
		return false;

	if (currentTime - oldestRequest < RATE_LIMIT_WINDOW)
		return true;

	return false;
}

void AddRequest()
{
	g_iRequestTimes[g_iCurrentRequest] = GetTime();
	g_iCurrentRequest = (g_iCurrentRequest + 1) % MAX_REQUESTS;
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsValidClient(client))
		return;

	char steam_id[MAX_AUTHID_LENGTH];
	GetClientAuthId(client, AuthId_SteamID64, steam_id, sizeof(steam_id));

	char cached_cheat[64];
	if (g_hCheatCache.GetString(steam_id, cached_cheat, sizeof(cached_cheat)))
	{
		LogMessage("Skipping the request for %N because we have cached cheat: %s", client, cached_cheat);
		if (!StrEqual(cached_cheat, "none"))
			PrintToChat(client, " \x10CHEAT \x08▪ We have detected that you have used \x10%s", cached_cheat);

		return;
	}

	if (IsRateLimited())
	{
		LogError("Rate limit reached. Skipping check for %N", client);
		return;
	}

	char url[256];
	Format(url, sizeof(url), "%s?steam_id=%s", API_URL, steam_id);

	// request must match this format: https://docs.alyx.ro/authorization
	HTTPRequest request = new HTTPRequest(url);
	request.SetHeader("Authorization", "Bearer %s", g_sApiKey);
	request.SetHeader("Content-Type", "application/json");
	request.SetHeader("Accept", "application/json");

	AddRequest();
	request.Get(OnRevealResponse, client);
}

public void OnRevealResponse(HTTPResponse response, any client)
{
	char client_name[MAX_NAME_LENGTH];
	GetClientName(client, client_name, sizeof(client_name));

	if (response.Status != HTTPStatus_OK)
	{
		JSONObject json = view_as<JSONObject>(response.Data);
		char error[256];
		json.GetString("error", error, sizeof(error));
		LogError("Failed to reveal cheat for %s: %s", client_name, error);
		delete json;
		return;
	}

	JSONObject json = view_as<JSONObject>(response.Data);
	if (!json.GetBool("success"))
	{
		char error[256];
		json.GetString("error", error, sizeof(error));
		LogError("API request failed for %s: %s", client_name, error);
		delete json;
		return;
	}

	// we will use the software name from the response: https://docs.alyx.ro/cs-go-only/cheat-revealer
	JSONObject data = view_as<JSONObject>(json.Get("data"));
	char software[64];
	data.GetString("software", software, sizeof(software));

	char steam_id[MAX_AUTHID_LENGTH];
	GetClientAuthId(client, AuthId_SteamID64, steam_id, sizeof(steam_id));
	g_hCheatCache.SetString(steam_id, software);

	if (!StrEqual(software, "none"))
		PrintToChat(client, " \x10CHEAT \x08▪ We have detected that you have used \x10%s", software);

	delete data;
	delete json;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);
}