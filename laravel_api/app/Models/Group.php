<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Group extends Model
{
    protected $fillable = [
        'name',
        'type',
    ];


    public function class()
{
    return $this->belongsTo(Classes::class);
}

}
