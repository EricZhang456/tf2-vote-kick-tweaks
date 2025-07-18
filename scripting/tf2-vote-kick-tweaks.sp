#include <sourcemod>
#include <nativevotes>

bool g_bVoteKickRegistered;

ConVar g_cvVoteKickTargetAdmin;
ConVar g_cvVoteKickSelf;
ConVar g_cvVoteKickGenericAllowed;
ConVar g_cvVoteKickIdleAllowed;
ConVar g_cvVoteKickScammingAllowed;
ConVar g_cvVoteKickCheatingAllowed;
ConVar g_cvServerVoteKickAllowed;

public Plugin myinfo = {
    name = "TF2 Vote Kick Tweaks",
    author = "Eric Zhang",
    description = "Tweaks to the TF2 vote kick system.",
    version = "1.0",
    url = "https://ericaftereric.top/"
};

public void OnPluginStart() {
    g_cvVoteKickTargetAdmin = CreateConVar("sm_vote_kick_target_admin", "1", "Do vote kicks follow SourceMod Admin target rules?");
    g_cvVoteKickSelf = CreateConVar("sm_vote_kick_self", "0", "Can clients start vote kicks targeting themselves?");
    g_cvVoteKickGenericAllowed = CreateConVar("sm_vote_kick_generic_allowed", "1", "Allow vote kicks with unspecified reason.");
    g_cvVoteKickIdleAllowed = CreateConVar("sm_vote_kick_idle_allowed", "1", "Allow vote kicks with idle as the reason.");
    g_cvVoteKickScammingAllowed = CreateConVar("sm_vote_kick_scamming_allowed", "1", "Allow vote kicks with scamming as the reason.");
    g_cvVoteKickCheatingAllowed = CreateConVar("sm_vote_kick_cheating_allowed", "1", "Allow vote kicks with cheating as the reason");

    g_cvServerVoteKickAllowed = FindConVar("sv_vote_issue_kick_allowed");

    AutoExecConfig(true);
}

public void OnLibraryAdded(const char[] name) {
    if (StrEqual(name, "nativevotes", false) && NativeVotes_IsVoteTypeSupported(NativeVotesType_Kick)) {
        NativeVotes_RegisterVoteCommand(NativeVotesOverride_Kick, OnKickVote, VoteKickVisCheck);
        g_bVoteKickRegistered = true;
    }
}

public void OnLibraryRemoved(const char[] name) {
    if (StrEqual(name, "nativevotes", false) && NativeVotes_IsVoteTypeSupported(NativeVotesType_Kick)) {
        NativeVotes_UnregisterVoteCommand(NativeVotesOverride_Kick, OnKickVote, VoteKickVisCheck);
        g_bVoteKickRegistered = false;
    }
}

public void OnAllPluginsLoaded() {
    if (!g_bVoteKickRegistered && LibraryExists("nativevotes") && NativeVotes_IsVoteTypeSupported(NativeVotesType_Kick)) {
        NativeVotes_RegisterVoteCommand(NativeVotesOverride_Kick, OnKickVote, VoteKickVisCheck);
        g_bVoteKickRegistered = true;
    }
}

public Action VoteKickVisCheck(int client, NativeVotesOverride overrideType) {
    if (g_cvServerVoteKickAllowed.BoolValue) {
        return Plugin_Continue;
    }
    return Plugin_Handled;
}

public Action OnKickVote(int client, NativeVotesOverride overrideType, const char[] voteArgument,
                         NativeVotesKickType kickType, int target) {
    if (client == 0) {
        return Plugin_Continue;
    }

    int targetIndex = GetClientOfUserId(target);

    if (!g_cvVoteKickSelf.BoolValue && client == targetIndex) {
        NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_WrongTeam);
        return Plugin_Handled;
    }

    AdminId initiatorAdminId = GetUserAdmin(client);
    AdminId targetAdminId = GetUserAdmin(targetIndex);

    if (g_cvVoteKickTargetAdmin.BoolValue && targetAdminId != INVALID_ADMIN_ID
        && !initiatorAdminId.CanTarget(targetAdminId)) {
        NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_CantKickAdmin);
        return Plugin_Handled;
    }

    if (!g_cvVoteKickGenericAllowed.BoolValue && kickType == NativeVotesKickType_Generic) {
        NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_Disabled);
        return Plugin_Handled;
    }

    if (!g_cvVoteKickIdleAllowed.BoolValue && kickType == NativeVotesKickType_Idle) {
        NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_Disabled);
        return Plugin_Handled;
    }

    if (!g_cvVoteKickScammingAllowed.BoolValue && kickType == NativeVotesKickType_Scamming) {
        NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_Disabled);
        return Plugin_Handled;
    }

    if (!g_cvVoteKickCheatingAllowed.BoolValue && kickType == NativeVotesKickType_Cheating) {
        NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_Disabled);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}
