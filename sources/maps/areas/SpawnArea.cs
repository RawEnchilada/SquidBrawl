using Godot;
using System;
using System.Collections.Generic;

[Tool]
public partial class SpawnArea : Node3D
{

    private readonly PackedScene[] WEAPON_SCENES =
    {
        GD.Load<PackedScene>("res://sources/interactables/weapons/bazooka.tscn"),
        GD.Load<PackedScene>("res://sources/interactables/weapons/mortar.tscn"),
        GD.Load<PackedScene>("res://sources/interactables/weapons/grenade.tscn")
    };

}