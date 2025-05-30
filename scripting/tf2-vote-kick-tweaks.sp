#include <sourcemod>
#include <nativevotes>

bool g_bVoteKickRegistered;

ConVar g_cvVoteKickTargetAdmin, g_cvVoteKickSelf, g_cvServerVoteKickAllowed;

public Plugin myinfo = {
    name = "TF2 Vote Kick Tweaks",
    author = "Eric Zhang",
    description = "Tweaks to the TF2 vote kick system.",
    version = "1.0",
    url = "https://ericaftereric.top/"
};

public void OnPluginStart() {
    g_cvVoteKickTargetAdmin = CreateConVar("sm_vote_kick_target_admin", "1", "Do vote kicks follow SourceMod Admin target rules?");
    g_cvVoteKickSelf = CreateConVar("sm_vote_kick_target_admin", "0", "Can vote kicks target clients themselves?");

    g_cvServerVoteKickAllowed = FindConVar("sv_vote_issue_kick_allowed");

    AutoExecConfig(true);
}

public void OnLibraryAdded(const char[] name) {
    if (g_cvServerVoteKickAllowed.BoolValue && StrEqual(name, "nativevotes", false) &&
        NativeVotes_IsVoteTypeSupported(NativeVotesType_Kick)) {
        NativeVotes_RegisterVoteCommand(NativeVotesOverride_Kick, OnKickVote);
        g_bVoteKickRegistered = true;
    }
}

public void OnLibraryRemoved(const char[] name) {
    if (g_cvServerVoteKickAllowed.BoolValue && StrEqual(name, "nativevotes", false) &&
        NativeVotes_IsVoteTypeSupported(NativeVotesType_Kick)) {
        NativeVotes_UnregisterVoteCommand(NativeVotesOverride_Kick, OnKickVote);
        g_bVoteKickRegistered = false;
    }
}

public void OnAllPluginsLoaded() {
    if (g_cvServerVoteKickAllowed.BoolValue && !g_bVoteKickRegistered &&
        LibraryExists("nativevotes") && NativeVotes_IsVoteTypeSupported(NativeVotesType_Kick)) {
        NativeVotes_RegisterVoteCommand(NativeVotesOverride_Kick, OnKickVote);
        g_bVoteKickRegistered = true;
    }
}

public Action OnKickVote(int client, NativeVotesOverride overrideType, const char[] voteArgument,
                         NativeVotesKickType kickType, int target) {
    if (!g_cvVoteKickSelf.BoolValue && client == target) {
        NativeVotes_DisplayCallVoteFail(GetClientOfUserId(client), NativeVotesCallFail_WrongTeam);
        return Plugin_Handled;
    }

    AdminId initiatorAdminId = GetUserAdmin(GetClientOfUserId(client));
    AdminId targetAdminId = GetUserAdmin(GetClientOfUserId(target));

    if (g_cvVoteKickTargetAdmin.BoolValue && !initiatorAdminId.CanTarget(targetAdminId)) {
        NativeVotes_DisplayCallVoteFail(GetClientOfUserId(client), NativeVotesCallFail_CantKickAdmin);
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}
