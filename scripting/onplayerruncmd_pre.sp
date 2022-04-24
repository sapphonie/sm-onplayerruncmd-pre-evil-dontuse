#include <sdktools>
#include <dhooks>
#include <memory>
#include <MemoryEx>

/*
    ; Attributes: bp-based frame

    ; CHookManager::PlayerRunCmd(CUserCmd *, IMoveHelper *)
    _ZN12CHookManager12PlayerRunCmdEP8CUserCmdP11IMoveHelper proc near
    Signature for _ZN12CHookManager12PlayerRunCmdEP8CUserCmdP11IMoveHelper:
    55 89 E5 57 56 83 EC 30
    \x55\x89\xE5\x57\x56\x83\xEC\x30
*/

int CHookMgr_PlayerRunCmd_LINUX[] =
{
    0x55, 0x89, 0xE5, 0x57, 0x56, 0x83, 0xEC, 0x30
};

Handle DHook_CHookMgr_PlayerRunCmd;

// This is fucked up man. I'm sorry.
public void OnPluginStart()
{
    MemoryEx mem;
    Address HookManager_PlayerRunCmd = mem.lib.FindPattern("sdktools.ext.2.tf2.so", CHookMgr_PlayerRunCmd_LINUX, sizeof(CHookMgr_PlayerRunCmd_LINUX));

    LogMessage("Found CHookMgr::PlayerRunCmd in SDKTools = %X", HookManager_PlayerRunCmd);

    if (!DHook_CHookMgr_PlayerRunCmd)
    {
        DHook_CHookMgr_PlayerRunCmd = DHookCreateDetour(HookManager_PlayerRunCmd, CallConv_THISCALL, ReturnType_Void, ThisPointer_Address);
        DHookAddParam(DHook_CHookMgr_PlayerRunCmd, HookParamType_ObjectPtr);
        DHookAddParam(DHook_CHookMgr_PlayerRunCmd, HookParamType_ObjectPtr);
        if (DHook_CHookMgr_PlayerRunCmd)
        {
            DHookEnableDetour(DHook_CHookMgr_PlayerRunCmd, false, Detour_PlayerRunCmd);
            LogMessage("enabled SDKTools HookManager::PlayerRunCmd detour");
        }
    }
}

public MRESReturn Detour_PlayerRunCmd(int pThis, DHookParam hParams)
{
    Address ucmd_ptr    = DHookGetParamAddress(hParams, 1);
    float angles[3];
    int cmdnum          =                        dref( ucmd_ptr+view_as<Address>( 0x04 ) );
    int tickcount       =                        dref( ucmd_ptr+view_as<Address>( 0x08 ) );
    angles[0]           =                        dref( ucmd_ptr+view_as<Address>( 0x0c ) );
    angles[1]           =                        dref( ucmd_ptr+view_as<Address>( 0x10 ) );
    angles[2]           =                        dref( ucmd_ptr+view_as<Address>( 0x14 ) );
    int buttons         =                        dref( ucmd_ptr+view_as<Address>( 0x24 ) );
    int impulse         =              sign_ext( dref( ucmd_ptr+view_as<Address>( 0x28 ), NumberType_Int8));
    Address weaponidx   =                        dref( ucmd_ptr+view_as<Address>( 0x2c ) );
    Address subtype     =                        dref( ucmd_ptr+view_as<Address>( 0x30 ) );
    int randomseed      =                        dref( ucmd_ptr+view_as<Address>( 0x34 ) );
    Address server_seed =                        dref( ucmd_ptr+view_as<Address>( 0x38 ) );
    int mousex          = unsigned_short_to_int( dref( ucmd_ptr+view_as<Address>( 0x3C ), NumberType_Int16));
    int mousey          = unsigned_short_to_int( dref( ucmd_ptr+view_as<Address>( 0x3E ), NumberType_Int16));

    PrintToServer("\
        cmdnum      %i\n\
        tickcount   %i\n\
        ang0        %f\n\
        ang1        %f\n\
        ang2        %f\n\
        buttons     %i\n\
        impulse     %x\n\
        weaponidx   %x\n\
        subtype     %x\n\
        randseed    %i\n\
        server_seed %f\n\
        mousex      %i\n\
        mousey      %i\n",
        cmdnum,
        tickcount,
        angles[0],
        angles[1],
        angles[2],
        buttons,
        impulse,
        weaponidx,
        subtype,
        randomseed,
        server_seed,
        mousex,
        mousey);

    return MRES_Ignored;
}

any dref(any ptr, NumberType size = NumberType_Int32)
{
    return view_as<any>(LoadFromAddress(ptr, size));
}

int unsigned_short_to_int(int uShort)
{
    return (uShort | ((uShort & 0x00008000) ? 0xFFFF0000 : 0x00000000));
}

int sign_ext(int byte)
{
    return (byte | ((byte & 0x00000080) ? 0xFFFFFF00 : 0x00000000));
}


public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    buttons = 0;
    PrintToServer("OPRC buttons %i", buttons);
    return Plugin_Changed;
}