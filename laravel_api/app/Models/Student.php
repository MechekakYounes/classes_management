<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    protected $fillable = [
        'fname',
        'name',
        'group_id'
    ];


    public function group()
{
    return $this->belongsTo(Group::class);
}

}
