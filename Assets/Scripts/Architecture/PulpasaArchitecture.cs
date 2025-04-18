using QFramework;
using UnityEngine;
using System.Collections.Generic;

public class PulpaSAArchitecture : Architecture<PulpaSAArchitecture>
{
    protected override void Init()
    {
        RegisterSystem<IOrderSystem>(new OrderSystem());
    }
}

