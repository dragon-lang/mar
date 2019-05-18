module mar.windows.user32.nolink;

enum MessageBoxType : cuint
{
    ok = 0,
    abortRetryIgnore = 0x2,
    cancelTryContinue = 0x6,
    help = 0x4000,
}
