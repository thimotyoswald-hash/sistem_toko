<?php

namespace App\Enums;

enum Role: string
{
    case Kasir = 'kasir';
    case Admin = 'admin';
    case Owner = 'owner';
}
