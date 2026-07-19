<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Wilaya extends Model
{
    use HasFactory;

    protected $fillable = [
        'id',
        'name',
    ];

    public function communes()
    {
        return $this->hasMany(Commune::class);
    }

    public function users()
    {
        return $this->hasMany(User::class);
    }
}
