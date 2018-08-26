module mar.env;

import mar.sentinel : SentinelPtr, assumeSentinel;
import mar.c : cstring;

cstring getenv(SentinelPtr!cstring envp, const(char)[] name)
{
    if (envp)
    {
      LvarLoop:
        for (;; envp++)
        {
            auto env = envp[0];
            if (!env)
                break;
            size_t i = 0;
            for (; i < name.length; i++)
            {
                if (env[i] != name[i])
                    continue LvarLoop;
            }
            if (env[i] == '=')
                return (&env[i + 1]).assumeSentinel;
        }
    }
    return cstring.nullValue;
}